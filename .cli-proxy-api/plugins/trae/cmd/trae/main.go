package main

/*
#include <dlfcn.h>
#include <stdint.h>
#include <stdlib.h>

__attribute__((constructor))
static void pin_go_runtime_library(void) {
	Dl_info info;
	if (dladdr((const void*)pin_go_runtime_library, &info) != 0 && info.dli_fname != NULL) {
		dlopen(info.dli_fname, RTLD_LAZY | RTLD_NOLOAD | RTLD_NODELETE);
	}
}

typedef struct {
	void* ptr;
	size_t len;
} cliproxy_buffer;

typedef int (*cliproxy_host_call_fn)(void*, const char*, const uint8_t*, size_t, cliproxy_buffer*);
typedef void (*cliproxy_host_free_fn)(void*, size_t);

typedef struct {
	uint32_t abi_version;
	void* host_ctx;
	cliproxy_host_call_fn call;
	cliproxy_host_free_fn free_buffer;
} cliproxy_host_api;

typedef int (*cliproxy_plugin_call_fn)(char*, uint8_t*, size_t, cliproxy_buffer*);
typedef void (*cliproxy_plugin_free_fn)(void*, size_t);
typedef void (*cliproxy_plugin_shutdown_fn)(void);

typedef struct {
	uint32_t abi_version;
	cliproxy_plugin_call_fn call;
	cliproxy_plugin_free_fn free_buffer;
	cliproxy_plugin_shutdown_fn shutdown;
} cliproxy_plugin_api;

extern int cliproxyPluginCall(char*, uint8_t*, size_t, cliproxy_buffer*);
extern void cliproxyPluginFree(void*, size_t);
extern void cliproxyPluginShutdown(void);

static int call_host(const cliproxy_host_api* host, const char* method, const uint8_t* req, size_t req_len, cliproxy_buffer* resp) {
	if (host == NULL || host->call == NULL) {
		return 1;
	}
	return host->call(host->host_ctx, method, req, req_len, resp);
}

static void free_host_buffer(const cliproxy_host_api* host, void* ptr, size_t len) {
	if (host != NULL && host->free_buffer != NULL && ptr != NULL) {
		host->free_buffer(ptr, len);
	}
}
*/
import "C"

import (
	"context"
	"encoding/json"
	"fmt"
	"sync"
	"unsafe"

	"github.com/router-for-me/CLIProxyAPI/v8/sdk/pluginabi"
	"traeplugin"
)

var (
	stateMu  sync.RWMutex
	hostAPI  *C.cliproxy_host_api
	provider = trae.NewProvider(trae.Options{})
)

func main() {}

//export cliproxy_plugin_init
func cliproxy_plugin_init(host *C.cliproxy_host_api, plugin *C.cliproxy_plugin_api) C.int {
	if plugin == nil {
		return 1
	}
	stateMu.Lock()
	hostAPI = host
	stateMu.Unlock()

	plugin.abi_version = C.uint32_t(pluginabi.ABIVersion)
	plugin.call = C.cliproxy_plugin_call_fn(C.cliproxyPluginCall)
	plugin.free_buffer = C.cliproxy_plugin_free_fn(C.cliproxyPluginFree)
	plugin.shutdown = C.cliproxy_plugin_shutdown_fn(C.cliproxyPluginShutdown)
	return 0
}

//export cliproxyPluginCall
func cliproxyPluginCall(method *C.char, request *C.uint8_t, requestLen C.size_t, response *C.cliproxy_buffer) C.int {
	if response != nil {
		response.ptr = nil
		response.len = 0
	}
	if method == nil {
		raw, _ := pluginabi.NewErrorEnvelope("invalid_method", "method is required")
		writeResponse(response, raw)
		return 1
	}
	var requestBytes []byte
	if request != nil && requestLen > 0 {
		requestBytes = C.GoBytes(unsafe.Pointer(request), C.int(requestLen))
	}
	raw := provider.HandleRPC(context.Background(), C.GoString(method), requestBytes, sendStreamChunk)
	writeResponse(response, raw)
	return 0
}

//export cliproxyPluginFree
func cliproxyPluginFree(ptr unsafe.Pointer, len C.size_t) {
	if ptr != nil {
		C.free(ptr)
	}
}

//export cliproxyPluginShutdown
func cliproxyPluginShutdown() {
	stateMu.Lock()
	hostAPI = nil
	stateMu.Unlock()
}

func sendStreamChunk(streamID string, payload []byte, err error, done bool) error {
	stateMu.RLock()
	host := hostAPI
	stateMu.RUnlock()
	if host == nil {
		return fmt.Errorf("host callback unavailable")
	}

	if done {
		reqObj := map[string]any{
			"stream_id": streamID,
		}
		if err != nil {
			reqObj["error"] = err.Error()
		}
		return invokeHost(host, pluginabi.MethodHostStreamClose, reqObj)
	}

	reqObj := map[string]any{
		"stream_id": streamID,
		"payload":   payload,
	}
	if err != nil {
		reqObj["error"] = err.Error()
	}
	return invokeHost(host, pluginabi.MethodHostStreamEmit, reqObj)
}

func invokeHost(host *C.cliproxy_host_api, method string, payload any) error {
	rawReq, errMarshal := json.Marshal(payload)
	if errMarshal != nil {
		return errMarshal
	}
	cMethod := C.CString(method)
	defer C.free(unsafe.Pointer(cMethod))

	var cReq unsafe.Pointer
	if len(rawReq) > 0 {
		cReq = C.CBytes(rawReq)
		defer C.free(cReq)
	}
	var resp C.cliproxy_buffer
	rc := C.call_host(host, cMethod, (*C.uint8_t)(cReq), C.size_t(len(rawReq)), &resp)
	if resp.ptr != nil {
		C.free_host_buffer(host, resp.ptr, resp.len)
	}
	if rc != 0 {
		return fmt.Errorf("host call %s returned %d", method, int(rc))
	}
	return nil
}

func writeResponse(response *C.cliproxy_buffer, raw []byte) {
	if response == nil || len(raw) == 0 {
		return
	}
	ptr := C.CBytes(raw)
	if ptr == nil {
		return
	}
	response.ptr = ptr
	response.len = C.size_t(len(raw))
}
