package trae

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"github.com/router-for-me/CLIProxyAPI/v8/sdk/pluginabi"
	"github.com/router-for-me/CLIProxyAPI/v8/sdk/pluginapi"
)

type StreamChunkSender func(streamID string, payload []byte, err error, done bool) error

type registration struct {
	SchemaVersion uint32                 `json:"schema_version"`
	Metadata      pluginapi.Metadata     `json:"metadata"`
	Capabilities  registrationCapability `json:"capabilities"`
}

type registrationCapability struct {
	ModelRegistrar           bool                         `json:"model_registrar"`
	ModelProvider            bool                         `json:"model_provider"`
	AuthProvider             bool                         `json:"auth_provider"`
	Executor                 bool                         `json:"executor"`
	ExecutorModelScope       pluginapi.ExecutorModelScope `json:"executor_model_scope"`
	ExecutorInputFormats     []string                     `json:"executor_input_formats,omitempty"`
	ExecutorOutputFormats    []string                     `json:"executor_output_formats,omitempty"`
	ResponseBeforeTranslator bool                         `json:"response_before_translator"`
}

type identifierResponse struct {
	Identifier string `json:"identifier"`
}

type streamResponse struct {
	Headers http.Header                     `json:"headers,omitempty"`
	Chunks  []pluginapi.ExecutorStreamChunk `json:"chunks,omitempty"`
}

func (p *Provider) HandleRPC(ctx context.Context, method string, rawReq []byte, sendChunk StreamChunkSender) []byte {
	switch method {
	case pluginabi.MethodPluginRegister, pluginabi.MethodPluginReconfigure:
		return okEnvelope(registration{
			SchemaVersion: pluginabi.SchemaVersion,
			Metadata: pluginapi.Metadata{
				Name:             "TraeX Provider",
				Version:          "0.1.0",
				Author:           "vegerot",
				GitHubRepository: "https://github.com/vegerot/ai-conversations",
			},
			Capabilities: registrationCapability{
				ModelRegistrar:           true,
				ModelProvider:            true,
				AuthProvider:             true,
				Executor:                 true,
				ExecutorModelScope:       pluginapi.ExecutorModelScopeBoth,
				ExecutorInputFormats:     []string{"chat-completions"},
				ExecutorOutputFormats:    []string{"chat-completions"},
				ResponseBeforeTranslator: true,
			},
		})
	case pluginabi.MethodPluginQuiesce, pluginabi.MethodPluginShutdown:
		return okEnvelope(map[string]any{})
	case pluginabi.MethodAuthIdentifier, pluginabi.MethodExecutorIdentifier:
		return okEnvelope(identifierResponse{Identifier: ProviderID})
	case pluginabi.MethodAuthParse:
		var req pluginapi.AuthParseRequest
		if err := json.Unmarshal(rawReq, &req); err != nil {
			return errEnvelope("invalid_request", err.Error(), http.StatusBadRequest)
		}
		provider := strings.TrimSpace(req.Provider)
		var meta map[string]any
		_ = json.Unmarshal(req.RawJSON, &meta)
		if provider == "" && meta != nil {
			if t, ok := meta["type"].(string); ok {
				provider = strings.TrimSpace(t)
			}
		}
		if !strings.EqualFold(provider, ProviderID) {
			return okEnvelope(pluginapi.AuthParseResponse{Handled: false})
		}
		if meta == nil {
			meta = map[string]any{}
		}
		meta["type"] = ProviderID
		fileName := strings.TrimSpace(req.FileName)
		if fileName == "" {
			fileName = "trae.json"
		}
		authData := pluginapi.AuthData{
			Provider:    ProviderID,
			ID:          fileName,
			FileName:    fileName,
			Label:       "TraeX",
			StorageJSON: append([]byte(nil), req.RawJSON...),
			Metadata:    meta,
		}
		return okEnvelope(pluginapi.AuthParseResponse{
			Handled: true,
			Auth:    authData,
			Auths:   []pluginapi.AuthData{authData},
		})
	case pluginabi.MethodAuthRefresh:
		var req pluginapi.AuthRefreshRequest
		_ = json.Unmarshal(rawReq, &req)
		if _, err := p.RefreshToken(ctx); err != nil {
			return errEnvelopeFromErr("refresh_failed", err)
		}
		return okEnvelope(pluginapi.AuthRefreshResponse{
			Auth: pluginapi.AuthData{
				Provider:    ProviderID,
				ID:          req.AuthID,
				FileName:    req.AuthID,
				Label:       "TraeX",
				StorageJSON: req.StorageJSON,
				Metadata:    req.Metadata,
				Attributes:  req.Attributes,
			},
		})
	case pluginabi.MethodModelRegister:
		routes, err := p.LoadCatalog(ctx)
		if err != nil {
			return errEnvelopeFromErr("catalog_failed", err)
		}
		models := make([]pluginapi.ModelInfo, 0, len(routes))
		for _, r := range routes {
			models = append(models, r.Info)
		}
		return okEnvelope(pluginapi.ModelRegistrationResponse{
			Provider: ProviderID,
			Models:   models,
		})
	case pluginabi.MethodModelStatic:
		routes, err := p.LoadCatalog(ctx)
		if err != nil {
			return errEnvelopeFromErr("catalog_failed", err)
		}
		models := make([]pluginapi.ModelInfo, 0, len(routes))
		for _, r := range routes {
			models = append(models, r.Info)
		}
		return okEnvelope(pluginapi.ModelResponse{
			Provider: ProviderID,
			Models:   models,
		})
	case pluginabi.MethodModelForAuth:
		var req pluginapi.AuthModelRequest
		if err := json.Unmarshal(rawReq, &req); err != nil {
			return errEnvelope("invalid_request", err.Error(), http.StatusBadRequest)
		}
		if req.AuthProvider != "" && !strings.EqualFold(strings.TrimSpace(req.AuthProvider), ProviderID) {
			return okEnvelope(pluginapi.ModelResponse{})
		}
		routes, err := p.LoadCatalog(ctx)
		if err != nil {
			return errEnvelopeFromErr("catalog_failed", err)
		}
		models := make([]pluginapi.ModelInfo, 0, len(routes))
		for _, r := range routes {
			models = append(models, r.Info)
		}
		return okEnvelope(pluginapi.ModelResponse{
			Provider: ProviderID,
			Models:   models,
		})
	case pluginabi.MethodExecutorExecute:
		var req pluginapi.ExecutorRequest
		if err := json.Unmarshal(rawReq, &req); err != nil {
			return errEnvelope("invalid_request", err.Error(), http.StatusBadRequest)
		}
		payload, headers, err := p.DoNonStream(ctx, req.Model, req.Payload)
		if err != nil {
			return errEnvelopeFromErr("execute_failed", err)
		}
		return okEnvelope(pluginapi.ExecutorResponse{
			Payload: payload,
			Headers: headers,
		})
	case pluginabi.MethodExecutorExecuteStream:
		var req struct {
			pluginapi.ExecutorRequest
			StreamID string `json:"stream_id"`
		}
		if err := json.Unmarshal(rawReq, &req); err != nil {
			return errEnvelope("invalid_request", err.Error(), http.StatusBadRequest)
		}
		if sendChunk != nil && strings.TrimSpace(req.StreamID) != "" {
			headers, err := p.StartAsyncStream(ctx, req.Model, req.Payload, req.StreamID, sendChunk)
			if err != nil {
				return errEnvelopeFromErr("execute_stream_failed", err)
			}
			return okEnvelope(streamResponse{
				Headers: headers,
			})
		}
		var chunks []pluginapi.ExecutorStreamChunk
		headers, err := p.DoStream(ctx, req.Model, req.Payload, func(chunk []byte) error {
			chunks = append(chunks, pluginapi.ExecutorStreamChunk{Payload: append([]byte(nil), chunk...)})
			return nil
		})
		if err != nil {
			return errEnvelopeFromErr("execute_stream_failed", err)
		}
		return okEnvelope(streamResponse{
			Headers: headers,
			Chunks:  chunks,
		})
	case pluginabi.MethodExecutorCountTokens:
		return okEnvelope(pluginapi.ExecutorResponse{
			Payload: []byte(`{"total_tokens":0}`),
		})
	case pluginabi.MethodResponseNormalizeBefore:
		var req pluginapi.ResponseTransformRequest
		if err := json.Unmarshal(rawReq, &req); err != nil {
			return okEnvelope(pluginapi.PayloadResponse{})
		}
		if req.Stream && strings.EqualFold(req.FromFormat, "openai") && strings.EqualFold(req.ToFormat, "claude") {
			trimmed := bytes.TrimSpace(req.Body)
			if bytes.HasPrefix(trimmed, []byte("{")) {
				return okEnvelope(pluginapi.PayloadResponse{
					Body: append([]byte("data: "), trimmed...),
				})
			}
		}
		return okEnvelope(pluginapi.PayloadResponse{Body: req.Body})
	default:
		return errEnvelope("unknown_method", "unknown method: "+method, http.StatusNotImplemented)
	}
}

func okEnvelope(v any) []byte {
	res, err := json.Marshal(v)
	if err != nil {
		return errEnvelope("marshal_error", err.Error(), http.StatusInternalServerError)
	}
	out, _ := json.Marshal(pluginabi.Envelope{OK: true, Result: res})
	return out
}

func errEnvelopeFromErr(code string, err error) []byte {
	status := http.StatusBadGateway
	var se *StatusError
	if errors.As(err, &se) && se.StatusCode > 0 {
		status = se.StatusCode
	}
	return errEnvelope(code, err.Error(), status)
}

func errEnvelope(code, message string, status int) []byte {
	out, _ := pluginabi.NewErrorEnvelope(code, message, status)
	return out
}
