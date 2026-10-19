package trae_test

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"

	"github.com/router-for-me/CLIProxyAPI/v8/sdk/pluginabi"
	"github.com/router-for-me/CLIProxyAPI/v8/sdk/pluginapi"
	"traeplugin"
)

const sampleModelsCacheJSON = `{
  "models": [
    {
      "slug": "openrouter-4o",
      "config_name": "trae_claude_opus_55",
      "visibility": "list",
      "supported_in_api": true,
      "input_modalities": ["text", "image"],
      "output_tokens_hard_limit": 64000,
      "supported_reasoning_levels": [
        {"effort": "low"},
        {"effort": "medium"},
        {"effort": "high"},
        {"effort": "max"}
      ],
      "business_metadata": {
        "variants": {
          "standard_key": "openrouter-4o-std",
          "standard_context_window": 200000,
          "max_key": "openrouter-4o-max",
          "max_context_window": 1000000,
          "backend_token_limits": {
            "openrouter-4o-std": {"output_tokens": 32000},
            "openrouter-4o-max": {"output_tokens": 64000}
          }
        }
      }
    },
    {
      "slug": "Seed-Code",
      "config_name": "seed_code_cfg",
      "visibility": "list",
      "supported_in_api": true,
      "input_modalities": ["text"],
      "output_tokens_hard_limit": 16384,
      "variants": {
        "standard_key": "seed-code-backend",
        "standard_context_window": 128000
      }
    },
    {
      "slug": "hidden-model",
      "config_name": "hidden_cfg",
      "visibility": "hidden",
      "supported_in_api": true,
      "variants": {
        "standard_key": "hidden-backend",
        "standard_context_window": 128000
      }
    }
  ]
}`

func TestLoadCatalogAndResolveRoute(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "models_cache.json"), []byte(sampleModelsCacheJSON), 0o600); err != nil {
		t.Fatalf("write models_cache.json: %v", err)
	}

	p := trae.NewProvider(trae.Options{CLIDir: dir})
	routes, err := p.LoadCatalog(context.Background())
	if err != nil {
		t.Fatalf("LoadCatalog() error = %v", err)
	}
	if len(routes) != 3 {
		t.Fatalf("LoadCatalog() count = %d, want 3 (openrouter-4o, openrouter-4o-Max, Seed-Code)", len(routes))
	}

	stdRoute, effort, err := p.ResolveRoute(context.Background(), "trae/openrouter-4o(high)")
	if err != nil {
		t.Fatalf("ResolveRoute() error = %v", err)
	}
	if stdRoute.ID != "openrouter-4o" || stdRoute.Config != "trae_claude_opus_55" || stdRoute.Backend != "openrouter-4o-std" {
		t.Fatalf("stdRoute = %+v", stdRoute)
	}
	if effort != "high" {
		t.Fatalf("effort = %q, want high", effort)
	}
	if stdRoute.Context != 200000 || stdRoute.Output != 32000 {
		t.Fatalf("stdRoute limits = %d/%d, want 200000/32000", stdRoute.Context, stdRoute.Output)
	}
	if stdRoute.Info.Thinking == nil || len(stdRoute.Info.Thinking.Levels) != 4 {
		t.Fatalf("stdRoute thinking = %+v, want 4 levels", stdRoute.Info.Thinking)
	}
	if len(stdRoute.Info.SupportedInputModalities) != 2 || stdRoute.Info.SupportedInputModalities[1] != "image" {
		t.Fatalf("stdRoute input modalities = %v, want [text image]", stdRoute.Info.SupportedInputModalities)
	}

	maxRoute, _, err := p.ResolveRoute(context.Background(), "openrouter-4o-Max")
	if err != nil {
		t.Fatalf("ResolveRoute(Max) error = %v", err)
	}
	if maxRoute.Backend != "openrouter-4o-max" || maxRoute.Context != 1000000 || maxRoute.Output != 64000 {
		t.Fatalf("maxRoute = %+v, want max backend and 1000000/64000 limits", maxRoute)
	}
}

func TestBuildTraePayload(t *testing.T) {
	route := trae.ModelRoute{
		ID:      "openrouter-4o",
		Config:  "trae_claude_opus_55",
		Backend: "openrouter-4o-std",
		Context: 200000,
		Output:  32000,
	}
	reqBody := []byte(`{
		"model": "openrouter-4o",
		"messages": [
			{"role": "system", "content": "You are helpful."},
			{"role": "user", "content": "Check weather"},
			{
				"role": "assistant",
				"content": "",
				"reasoning_content": "Need weather tool",
				"tool_calls": [
					{
						"id": "call_1",
						"type": "function",
						"function": {"name": "get_weather", "arguments": "{\"city\":\"SF\"}"}
					}
				]
			},
			{"role": "tool", "tool_call_id": "call_1", "content": "72F"},
			{"role": "user", "content": [{"type": "text", "text": "Thanks!"}, {"type": "image_url", "image_url": {"url": "data:image/png;base64,AAA"}}]}
		],
		"tools": [
			{
				"type": "function",
				"function": {
					"name": "get_weather",
					"description": "Get weather",
					"strict": true,
					"parameters": {"type": "object", "properties": {"city": {"type": "string"}}}
				}
			}
		]
	}`)

	payloadBytes, err := trae.BuildTraePayload(reqBody, route, "high", func() string { return "uuid-1" })
	if err != nil {
		t.Fatalf("BuildTraePayload() error = %v", err)
	}

	var got map[string]any
	if err := json.Unmarshal(payloadBytes, &got); err != nil {
		t.Fatalf("unmarshal payload: %v", err)
	}

	if got["access_type"] != float64(4) || got["config_name"] != "trae_claude_opus_55" || got["model_name"] != "openrouter-4o-std" {
		t.Fatalf("header fields = %#v", got)
	}
	if got["reasoning_effort"] != "high" {
		t.Fatalf("reasoning_effort = %v, want high", got["reasoning_effort"])
	}
	if got["user_input"] != "Thanks!" {
		t.Fatalf("user_input = %v, want Thanks!", got["user_input"])
	}
	if got["max_tokens"] != float64(32000) {
		t.Fatalf("max_tokens = %v, want 32000", got["max_tokens"])
	}

	tools, _ := got["tools"].([]any)
	if len(tools) != 1 {
		t.Fatalf("tools len = %d, want 1", len(tools))
	}
	fn := tools[0].(map[string]any)["function"].(map[string]any)
	if _, hasStrict := fn["strict"]; hasStrict {
		t.Fatalf("tool.function.strict was not stripped: %#v", fn)
	}
	if _, ok := fn["parameters"].(string); !ok {
		t.Fatalf("tool.function.parameters = %T (%v), want stringified JSON", fn["parameters"], fn["parameters"])
	}

	msgs := got["messages"].([]any)
	assistantMsg := msgs[2].(map[string]any)
	if assistantMsg["reasoning_content"] != "Need weather tool" {
		t.Fatalf("assistant reasoning_content = %v", assistantMsg["reasoning_content"])
	}
	toolCalls := assistantMsg["tool_calls"].([]any)
	tc0 := toolCalls[0].(map[string]any)
	if tc0["function_call"] == nil {
		t.Fatalf("assistant tool_call missing function_call: %#v", tc0)
	}
}

func TestTranslateSSEStreamAndAssembleNonStream(t *testing.T) {
	sseInput := strings.Join([]string{
		"event: progress_notice",
		"data: ;Processing_abc123",
		"",
		"event: output",
		`data: {"response":"","reasoning_content":"Thinking step 1. ","tool_calls":[]}`,
		"",
		"event: output",
		`data: {"response":"Hello ","reasoning_content":"","tool_calls":[]}`,
		"",
		"event: output",
		`data: {"response":"world!","reasoning_content":"","tool_calls":[{"id":"call_99","index":0,"type":"function","function_call":{"name":"lookup","arguments":"{\"q\":\"trae\"}"}}]}`,
		"",
		"event: token_usage",
		`data: {"prompt_tokens":100,"completion_tokens":25,"total_tokens":125,"cache_read_input_tokens":80,"cache_creation_input_tokens":10,"reasoning_tokens":12}`,
		"",
		"event: done",
		`data: {"finish_reason":"tool_use"}`,
		"",
	}, "\n")

	var chunks [][]byte
	err := trae.TranslateSSEStream(strings.NewReader(sseInput), "openrouter-4o", "chatcmpl-test", 1700000000, func(chunk []byte) error {
		chunks = append(chunks, append([]byte(nil), chunk...))
		return nil
	})
	if err != nil {
		t.Fatalf("TranslateSSEStream() error = %v", err)
	}
	if len(chunks) != 5 {
		t.Fatalf("chunks count = %d, want 5 (3 output + 1 usage + 1 finish); got %s", len(chunks), strings.Join(func() []string {
			out := make([]string, len(chunks))
			for i, c := range chunks {
				out[i] = string(c)
			}
			return out
		}(), "\n"))
	}

	// Verify non-streaming assembly on the same SSE stream
	nonStreamBytes, err := trae.AssembleNonStreamResponse(strings.NewReader(sseInput), "openrouter-4o", "chatcmpl-test", 1700000000)
	if err != nil {
		t.Fatalf("AssembleNonStreamResponse() error = %v", err)
	}
	var nonStream map[string]any
	if err := json.Unmarshal(nonStreamBytes, &nonStream); err != nil {
		t.Fatalf("unmarshal non-stream response: %v", err)
	}
	choices := nonStream["choices"].([]any)
	choice0 := choices[0].(map[string]any)
	if choice0["finish_reason"] != "tool_calls" {
		t.Fatalf("finish_reason = %v, want tool_calls", choice0["finish_reason"])
	}
	msg := choice0["message"].(map[string]any)
	if msg["content"] != "Hello world!" || msg["reasoning_content"] != "Thinking step 1. " {
		t.Fatalf("message = %#v", msg)
	}
	tcs := msg["tool_calls"].([]any)
	if len(tcs) != 1 || tcs[0].(map[string]any)["id"] != "call_99" {
		t.Fatalf("tool_calls = %#v", tcs)
	}
}

func TestDoNonStreamRefreshesTokenOn401(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "models_cache.json"), []byte(sampleModelsCacheJSON), 0o600); err != nil {
		t.Fatalf("write models_cache.json: %v", err)
	}
	if err := os.WriteFile(filepath.Join(dir, "auth.json"), []byte(`{"trae":{"access_token":"expired-token"}}`), 0o600); err != nil {
		t.Fatalf("write auth.json: %v", err)
	}

	var calls atomic.Int32
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		n := calls.Add(1)
		authHeader := r.Header.Get("Authorization")
		if n == 1 {
			if authHeader != "Cloud-CLI-JWT expired-token" {
				t.Errorf("first call Authorization = %q, want expired-token", authHeader)
			}
			w.WriteHeader(http.StatusUnauthorized)
			_, _ = w.Write([]byte(`{"error":"expired"}`))
			return
		}
		if authHeader != "Cloud-CLI-JWT fresh-token" {
			t.Errorf("second call Authorization = %q, want fresh-token", authHeader)
			w.WriteHeader(http.StatusUnauthorized)
			return
		}
		w.Header().Set("Content-Type", "text/event-stream")
		_, _ = w.Write([]byte("event: output\ndata: {\"response\":\"Pong!\"}\n\nevent: done\ndata: {\"finish_reason\":\"stop\"}\n\n"))
	}))
	defer srv.Close()

	refreshCalls := 0
	p := trae.NewProvider(trae.Options{
		CLIDir:     dir,
		Endpoint:   srv.URL,
		HTTPClient: srv.Client(),
		RunCommand: func(ctx context.Context, name string, args ...string) error {
			refreshCalls++
			return os.WriteFile(filepath.Join(dir, "auth.json"), []byte(`{"trae":{"access_token":"fresh-token"}}`), 0o600)
		},
	})

	respBytes, _, err := p.DoNonStream(context.Background(), "openrouter-4o", []byte(`{"model":"openrouter-4o","messages":[{"role":"user","content":"Ping"}]}`))
	if err != nil {
		t.Fatalf("DoNonStream() error = %v", err)
	}
	if refreshCalls != 1 || calls.Load() != 2 {
		t.Fatalf("refreshCalls=%d upstreamCalls=%d, want 1 and 2", refreshCalls, calls.Load())
	}
	if !strings.Contains(string(respBytes), "Pong!") {
		t.Fatalf("response = %s, want Pong!", respBytes)
	}
}

func TestHandleRPC(t *testing.T) {
	dir := t.TempDir()
	if err := os.WriteFile(filepath.Join(dir, "models_cache.json"), []byte(sampleModelsCacheJSON), 0o600); err != nil {
		t.Fatalf("write models_cache.json: %v", err)
	}

	p := trae.NewProvider(trae.Options{CLIDir: dir})

	regRaw := p.HandleRPC(context.Background(), pluginabi.MethodPluginRegister, nil, nil)
	var regEnv pluginabi.Envelope
	if err := json.Unmarshal(regRaw, &regEnv); err != nil || !regEnv.OK {
		t.Fatalf("plugin.register failed: %s (%v)", regRaw, err)
	}
	var regResult struct {
		SchemaVersion uint32             `json:"schema_version"`
		Metadata      pluginapi.Metadata `json:"metadata"`
	}
	if err := json.Unmarshal(regEnv.Result, &regResult); err != nil {
		t.Fatalf("unmarshal registration result: %v", err)
	}
	if regResult.Metadata.Name == "" || regResult.Metadata.Version == "" || regResult.Metadata.Author == "" || regResult.Metadata.GitHubRepository == "" {
		t.Fatalf("registration metadata missing required fields for host validation: %+v", regResult.Metadata)
	}

	authReqBytes, _ := json.Marshal(pluginapi.AuthParseRequest{
		Provider: "trae",
		FileName: "trae.json",
		RawJSON:  []byte(`{"type":"trae"}`),
	})
	authRaw := p.HandleRPC(context.Background(), pluginabi.MethodAuthParse, authReqBytes, nil)
	var authEnv pluginabi.Envelope
	if err := json.Unmarshal(authRaw, &authEnv); err != nil || !authEnv.OK {
		t.Fatalf("auth.parse failed: %s (%v)", authRaw, err)
	}
	var authResp pluginapi.AuthParseResponse
	if err := json.Unmarshal(authEnv.Result, &authResp); err != nil {
		t.Fatalf("unmarshal AuthParseResponse: %v", err)
	}
	if !authResp.Handled || authResp.Auth.Provider != "trae" {
		t.Fatalf("authResp = %+v, want Handled=true and Auth.Provider=trae", authResp)
	}

	modelReqBytes, _ := json.Marshal(pluginapi.AuthModelRequest{
		AuthProvider: "trae",
	})
	modelsRaw := p.HandleRPC(context.Background(), pluginabi.MethodModelForAuth, modelReqBytes, nil)
	var modelsEnv pluginabi.Envelope
	if err := json.Unmarshal(modelsRaw, &modelsEnv); err != nil || !modelsEnv.OK {
		t.Fatalf("model.for_auth failed: %s (%v)", modelsRaw, err)
	}
	var modelsResp pluginapi.ModelResponse
	if err := json.Unmarshal(modelsEnv.Result, &modelsResp); err != nil {
		t.Fatalf("unmarshal ModelResponse: %v", err)
	}
	if modelsResp.Provider != "trae" || len(modelsResp.Models) != 3 {
		t.Fatalf("modelsResp = %+v, want provider=trae and 3 models", modelsResp)
	}
	if modelsResp.Models[0].ContextLength != 200000 || modelsResp.Models[0].MaxCompletionTokens != 32000 {
		t.Fatalf("modelsResp.Models[0] limits = %+v, want 200000/32000", modelsResp.Models[0])
	}
}

