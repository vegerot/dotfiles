package trae

import (
	"bufio"
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/router-for-me/CLIProxyAPI/v8/sdk/pluginapi"
)

const (
	DefaultEndpoint = "https://copilot-cn.bytedance.net/api/ide/v2/llm_raw_chat"
	TraeAppID       = "6eefa01c-1036-4c7e-9ca5-d891f63bfcd8"
	TraeIDEFunction = "traecli_next"
	ProviderID      = "trae"
	cliTimeout      = 15 * time.Second
)

type ModelRoute struct {
	ID      string
	Config  string
	Backend string
	Context int
	Output  int
	Info    pluginapi.ModelInfo
}

type StatusError struct {
	StatusCode int
	Message    string
}

func (e *StatusError) Error() string {
	return fmt.Sprintf("HTTP %d: %s", e.StatusCode, e.Message)
}

type Options struct {
	CLIDir       string
	Endpoint     string
	HTTPClient   *http.Client
	RunCommand   func(ctx context.Context, name string, args ...string) error
	NowUnix      func() int64
	VersionCode  func() string
	NewRequestID func() string
}

type Provider struct {
	opts      Options
	refreshMu sync.Mutex
}

func NewProvider(opts Options) *Provider {
	if strings.TrimSpace(opts.Endpoint) == "" {
		if envEndpoint := strings.TrimSpace(os.Getenv("TRAE_ENDPOINT")); envEndpoint != "" {
			opts.Endpoint = envEndpoint
		} else {
			opts.Endpoint = DefaultEndpoint
		}
	}
	if opts.HTTPClient == nil {
		opts.HTTPClient = &http.Client{Timeout: 10 * time.Minute}
	}
	if opts.RunCommand == nil {
		opts.RunCommand = defaultRunCommand
	}
	if opts.NowUnix == nil {
		opts.NowUnix = func() int64 { return time.Now().Unix() }
	}
	if opts.VersionCode == nil {
		opts.VersionCode = func() string { return time.Now().UTC().Format("20060102") }
	}
	if opts.NewRequestID == nil {
		opts.NewRequestID = newUUID
	}
	return &Provider{opts: opts}
}

func (p *Provider) cliDir() string {
	if dir := strings.TrimSpace(p.opts.CLIDir); dir != "" {
		return dir
	}
	if dir := strings.TrimSpace(os.Getenv("TRAECLI_HOME")); dir != "" {
		return dir
	}
	if traeHome := strings.TrimSpace(os.Getenv("TRAE_HOME")); traeHome != "" {
		return filepath.Join(traeHome, "cli")
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return ".trae/cli"
	}
	return filepath.Join(home, ".trae", "cli")
}

func (p *Provider) authPath() string {
	return filepath.Join(p.cliDir(), "auth.json")
}

func (p *Provider) modelsCachePath() string {
	return filepath.Join(p.cliDir(), "models_cache.json")
}

func defaultRunCommand(ctx context.Context, name string, args ...string) error {
	callCtx, cancel := context.WithTimeout(ctx, cliTimeout)
	defer cancel()
	cmd := exec.CommandContext(callCtx, name, args...)
	cmd.Stdout = io.Discard
	cmd.Stderr = io.Discard
	return cmd.Run()
}

func (p *Provider) ReadToken() (string, error) {
	raw, err := os.ReadFile(p.authPath())
	if err != nil {
		return "", fmt.Errorf("read %s: %w", p.authPath(), err)
	}
	var parsed struct {
		Trae struct {
			AccessToken string `json:"access_token"`
		} `json:"trae"`
	}
	if err := json.Unmarshal(raw, &parsed); err != nil {
		return "", fmt.Errorf("parse %s: %w", p.authPath(), err)
	}
	token := strings.TrimSpace(parsed.Trae.AccessToken)
	if token == "" {
		return "", fmt.Errorf("Missing Trae token in %s; run `traex login`", p.authPath())
	}
	return token, nil
}

func (p *Provider) RefreshToken(ctx context.Context) (string, error) {
	p.refreshMu.Lock()
	defer p.refreshMu.Unlock()
	_ = p.opts.RunCommand(ctx, "traex", "models")
	return p.ReadToken()
}

type rawModelsCache struct {
	Models []rawModelEntry `json:"models"`
}

type rawModelVariants struct {
	StandardKey           string `json:"standard_key"`
	StandardContextWindow int    `json:"standard_context_window"`
	MaxKey                string `json:"max_key"`
	MaxContextWindow      int    `json:"max_context_window"`
	BackendTokenLimits    map[string]struct {
		OutputTokens int `json:"output_tokens"`
	} `json:"backend_token_limits"`
}

type rawModelEntry struct {
	Slug                     string   `json:"slug"`
	ConfigName               string   `json:"config_name"`
	Visibility               string   `json:"visibility"`
	SupportedInAPI           *bool    `json:"supported_in_api"`
	InputModalities          []string `json:"input_modalities"`
	OutputTokensHardLimit    int      `json:"output_tokens_hard_limit"`
	SupportedReasoningLevels []struct {
		Effort string `json:"effort"`
	} `json:"supported_reasoning_levels"`
	BusinessMetadata struct {
		Variants rawModelVariants `json:"variants"`
	} `json:"business_metadata"`
	Variants rawModelVariants `json:"variants"`
}

func (p *Provider) LoadCatalog(ctx context.Context) ([]ModelRoute, error) {
	routes, err := p.readCatalogFromFile()
	if err == nil && len(routes) > 0 {
		return routes, nil
	}
	_ = p.opts.RunCommand(ctx, "traex", "debug", "models", "--remote")
	return p.readCatalogFromFile()
}

func (p *Provider) readCatalogFromFile() ([]ModelRoute, error) {
	raw, err := os.ReadFile(p.modelsCachePath())
	if err != nil {
		return nil, fmt.Errorf("read %s: %w", p.modelsCachePath(), err)
	}
	var cache rawModelsCache
	if err := json.Unmarshal(raw, &cache); err != nil {
		return nil, fmt.Errorf("parse %s: %w", p.modelsCachePath(), err)
	}

	now := p.opts.NowUnix()
	routes := make([]ModelRoute, 0, len(cache.Models))
	for _, m := range cache.Models {
		if m.Visibility != "list" {
			continue
		}
		if m.SupportedInAPI != nil && !*m.SupportedInAPI {
			continue
		}
		slug := strings.TrimSpace(m.Slug)
		if slug == "" {
			continue
		}

		inputModalities := []string{"text"}
		for _, mod := range m.InputModalities {
			if strings.EqualFold(strings.TrimSpace(mod), "image") {
				inputModalities = []string{"text", "image"}
				break
			}
		}

		var levels []string
		for _, rl := range m.SupportedReasoningLevels {
			if effort := strings.TrimSpace(rl.Effort); effort != "" {
				levels = append(levels, effort)
			}
		}
		var thinking *pluginapi.ThinkingSupport
		if len(levels) > 0 {
			thinking = &pluginapi.ThinkingSupport{Levels: levels}
		}

		variants := m.BusinessMetadata.Variants
		if strings.TrimSpace(variants.StandardKey) == "" {
			variants = m.Variants
		}

		stdBackend := strings.TrimSpace(variants.StandardKey)
		stdContext := variants.StandardContextWindow
		if stdContext <= 0 {
			stdContext = 200000
		}
		stdOutput := variants.BackendTokenLimits[stdBackend].OutputTokens
		if stdOutput <= 0 {
			stdOutput = m.OutputTokensHardLimit
		}
		if stdOutput <= 0 {
			stdOutput = 32768
		}

		routes = append(routes, ModelRoute{
			ID:      slug,
			Config:  m.ConfigName,
			Backend: stdBackend,
			Context: stdContext,
			Output:  stdOutput,
			Info: pluginapi.ModelInfo{
				ID:                         slug,
				Object:                     "model",
				Created:                    now,
				OwnedBy:                    ProviderID,
				Type:                       ProviderID,
				Name:                       slug,
				DisplayName:                slug,
				SupportedGenerationMethods: []string{"chat"},
				InputTokenLimit:            int64(stdContext),
				OutputTokenLimit:           int64(stdOutput),
				ContextLength:              int64(stdContext),
				MaxCompletionTokens:        int64(stdOutput),
				Thinking:                   thinking,
				SupportedInputModalities:   inputModalities,
				SupportedOutputModalities:  []string{"text"},
				UserDefined:                true,
			},
		})

		maxBackend := strings.TrimSpace(variants.MaxKey)
		maxContext := variants.MaxContextWindow
		if maxBackend != "" && maxContext > 0 {
			maxID := slug + "-Max"
			maxOutput := variants.BackendTokenLimits[maxBackend].OutputTokens
			if maxOutput <= 0 {
				maxOutput = m.OutputTokensHardLimit
			}
			if maxOutput <= 0 {
				maxOutput = 32768
			}
			routes = append(routes, ModelRoute{
				ID:      maxID,
				Config:  m.ConfigName,
				Backend: maxBackend,
				Context: maxContext,
				Output:  maxOutput,
				Info: pluginapi.ModelInfo{
					ID:                         maxID,
					Object:                     "model",
					Created:                    now,
					OwnedBy:                    ProviderID,
					Type:                       ProviderID,
					Name:                       maxID,
					DisplayName:                slug + " / Max",
					SupportedGenerationMethods: []string{"chat"},
					InputTokenLimit:            int64(maxContext),
					OutputTokenLimit:           int64(maxOutput),
					ContextLength:              int64(maxContext),
					MaxCompletionTokens:        int64(maxOutput),
					Thinking:                   thinking,
					SupportedInputModalities:   inputModalities,
					SupportedOutputModalities:  []string{"text"},
					UserDefined:                true,
				},
			})
		}
	}
	return routes, nil
}

func (p *Provider) ResolveRoute(ctx context.Context, modelID string) (ModelRoute, string, error) {
	baseID, effort := splitModelAndEffort(modelID)
	routes, err := p.LoadCatalog(ctx)
	if err != nil {
		return ModelRoute{}, "", err
	}
	if route, ok := matchRoute(routes, baseID); ok {
		return route, effort, nil
	}
	_ = p.opts.RunCommand(ctx, "traex", "debug", "models", "--remote")
	routes, err = p.readCatalogFromFile()
	if err != nil {
		return ModelRoute{}, "", err
	}
	if route, ok := matchRoute(routes, baseID); ok {
		return route, effort, nil
	}
	return ModelRoute{}, "", fmt.Errorf("unknown Trae model %q", modelID)
}

func splitModelAndEffort(modelID string) (string, string) {
	cleaned := strings.TrimSpace(modelID)
	if strings.HasPrefix(strings.ToLower(cleaned), "trae/") {
		cleaned = strings.TrimSpace(cleaned[len("trae/"):])
	}
	var effort string
	if openIdx := strings.LastIndexByte(cleaned, '('); openIdx > 0 && strings.HasSuffix(cleaned, ")") {
		effort = strings.TrimSpace(cleaned[openIdx+1 : len(cleaned)-1])
		cleaned = strings.TrimSpace(cleaned[:openIdx])
	}
	return cleaned, effort
}

func matchRoute(routes []ModelRoute, id string) (ModelRoute, bool) {
	for _, r := range routes {
		if r.ID == id {
			return r, true
		}
	}
	for _, r := range routes {
		if strings.EqualFold(r.ID, id) {
			return r, true
		}
	}
	return ModelRoute{}, false
}

func BuildTraePayload(body []byte, route ModelRoute, effortOverride string, newID func() string) ([]byte, error) {
	if newID == nil {
		newID = newUUID
	}
	var req map[string]any
	if err := json.Unmarshal(body, &req); err != nil {
		return nil, fmt.Errorf("unmarshal chat request: %w", err)
	}

	rawMessages, _ := req["messages"].([]any)
	rawTools, _ := req["tools"].([]any)

	maxTokens := route.Output
	if v, ok := asInt(req["max_tokens"]); ok && v > 0 {
		maxTokens = v
	} else if v, ok := asInt(req["max_completion_tokens"]); ok && v > 0 {
		maxTokens = v
	}

	parallelToolCalls := true
	if v, ok := req["parallel_tool_calls"].(bool); ok {
		parallelToolCalls = v
	}

	effort := strings.TrimSpace(effortOverride)
	if bodyEffort, ok := req["reasoning_effort"].(string); ok && strings.TrimSpace(bodyEffort) != "" {
		effort = strings.TrimSpace(bodyEffort)
	}

	payload := map[string]any{
		"access_type":         4,
		"config_name":         route.Config,
		"conversation_id":     newID(),
		"extra_info":          "",
		"is_preset":           true,
		"max_tokens":          maxTokens,
		"messages":            translateMessages(rawMessages),
		"model_name":          route.Backend,
		"parallel_tool_calls": parallelToolCalls,
		"session_id":          newID(),
		"tools":               translateTools(rawTools),
		"user_input":          latestUserInput(rawMessages),
	}
	if effort != "" {
		payload["reasoning_effort"] = effort
	}
	return json.Marshal(payload)
}

func translateMessages(messages []any) []map[string]any {
	out := make([]map[string]any, 0, len(messages))
	for _, item := range messages {
		msg, ok := item.(map[string]any)
		if !ok {
			continue
		}
		role, _ := msg["role"].(string)
		var content any
		switch c := msg["content"].(type) {
		case []any:
			content = c
		case string:
			content = []map[string]any{{"type": "text", "text": c}}
		default:
			content = []map[string]any{{"type": "text", "text": ""}}
		}

		translated := map[string]any{
			"role":    role,
			"content": content,
		}
		if rc, ok := msg["reasoning_content"].(string); ok && rc != "" {
			translated["reasoning_content"] = rc
		}
		if tcid, ok := msg["tool_call_id"].(string); ok && tcid != "" {
			translated["tool_call_id"] = tcid
		}
		if rawCalls, ok := msg["tool_calls"].([]any); ok && len(rawCalls) > 0 {
			calls := make([]map[string]any, 0, len(rawCalls))
			for idx, rawCall := range rawCalls {
				callMap, ok := rawCall.(map[string]any)
				if !ok {
					continue
				}
				callIdx := idx
				if explicitIdx, ok := asInt(callMap["index"]); ok {
					callIdx = explicitIdx
				}
				callType, _ := callMap["type"].(string)
				if callType == "" {
					callType = "function"
				}
				fn := callMap["function"]
				if fn == nil {
					fn = callMap["function_call"]
				}
				calls = append(calls, map[string]any{
					"id":            callMap["id"],
					"index":         callIdx,
					"type":          callType,
					"function_call": fn,
				})
			}
			translated["tool_calls"] = calls
		}
		out = append(out, translated)
	}
	return out
}

func translateTools(tools []any) []map[string]any {
	out := make([]map[string]any, 0, len(tools))
	for _, item := range tools {
		tool, ok := item.(map[string]any)
		if !ok {
			continue
		}
		fn, ok := tool["function"].(map[string]any)
		if !ok {
			out = append(out, tool)
			continue
		}
		cleanFn := make(map[string]any, len(fn))
		for k, v := range fn {
			if k == "strict" {
				continue
			}
			cleanFn[k] = v
		}
		switch params := fn["parameters"].(type) {
		case string:
			cleanFn["parameters"] = params
		case nil:
			cleanFn["parameters"] = "{}"
		default:
			if encoded, err := json.Marshal(params); err == nil {
				cleanFn["parameters"] = string(encoded)
			} else {
				cleanFn["parameters"] = "{}"
			}
		}
		copiedTool := make(map[string]any, len(tool))
		for k, v := range tool {
			copiedTool[k] = v
		}
		copiedTool["function"] = cleanFn
		out = append(out, copiedTool)
	}
	return out
}

func latestUserInput(messages []any) string {
	for i := len(messages) - 1; i >= 0; i-- {
		msg, ok := messages[i].(map[string]any)
		if !ok || msg["role"] != "user" {
			continue
		}
		switch c := msg["content"].(type) {
		case string:
			return c
		case []any:
			var parts []string
			for _, part := range c {
				pMap, ok := part.(map[string]any)
				if !ok {
					continue
				}
				if pMap["type"] == "text" {
					if txt, ok := pMap["text"].(string); ok {
						parts = append(parts, txt)
					}
				}
			}
			return strings.Join(parts, "\n")
		}
	}
	return ""
}

type traeOutputEvent struct {
	Response         string          `json:"response"`
	ReasoningContent string          `json:"reasoning_content"`
	ToolCalls        []traeToolCall  `json:"tool_calls"`
}

type traeToolCall struct {
	ID           string           `json:"id"`
	Index        *int             `json:"index"`
	Type         string           `json:"type"`
	FunctionCall *traeFuncCall    `json:"function_call"`
	Function     *traeFuncCall    `json:"function"`
}

type traeFuncCall struct {
	Name      string `json:"name"`
	Arguments string `json:"arguments"`
}

type traeUsageEvent struct {
	PromptTokens             int `json:"prompt_tokens"`
	CompletionTokens         int `json:"completion_tokens"`
	TotalTokens              int `json:"total_tokens"`
	CacheReadInputTokens     int `json:"cache_read_input_tokens"`
	CacheCreationInputTokens int `json:"cache_creation_input_tokens"`
	ReasoningTokens          int `json:"reasoning_tokens"`
}

func buildOpenAIUsage(u traeUsageEvent) map[string]any {
	return map[string]any{
		"prompt_tokens":               u.PromptTokens,
		"completion_tokens":           u.CompletionTokens,
		"total_tokens":                u.TotalTokens,
		"cache_read_input_tokens":     u.CacheReadInputTokens,
		"cache_creation_input_tokens": u.CacheCreationInputTokens,
		"prompt_tokens_details": map[string]any{
			"cached_tokens":         u.CacheReadInputTokens,
			"cache_creation_tokens": u.CacheCreationInputTokens,
		},
		"completion_tokens_details": map[string]any{
			"reasoning_tokens": u.ReasoningTokens,
		},
	}
}

func mapFinishReason(raw string, sawToolCalls bool) string {
	switch raw {
	case "tool_use", "function_call", "tool_calls":
		return "tool_calls"
	case "max_tokens", "length":
		return "length"
	default:
		if sawToolCalls && (raw == "" || raw == "stop") {
			return "tool_calls"
		}
		if raw != "" {
			return raw
		}
		return "stop"
	}
}

func parseSSEFrames(r io.Reader, handle func(event, data string) error) error {
	scanner := bufio.NewScanner(r)
	scanner.Buffer(make([]byte, 64*1024), 8*1024*1024)
	var eventName string
	var dataLines []string

	flush := func() error {
		if eventName == "" && len(dataLines) == 0 {
			return nil
		}
		ev := eventName
		data := strings.Join(dataLines, "\n")
		eventName = ""
		dataLines = dataLines[:0]
		if data == "" {
			return nil
		}
		return handle(ev, data)
	}

	for scanner.Scan() {
		line := strings.TrimSuffix(scanner.Text(), "\r")
		if line == "" {
			if err := flush(); err != nil {
				return err
			}
			continue
		}
		if strings.HasPrefix(line, "event:") {
			eventName = strings.TrimSpace(line[len("event:"):])
		} else if strings.HasPrefix(line, "data:") {
			dataLines = append(dataLines, strings.TrimSpace(line[len("data:"):]))
		}
	}
	if err := scanner.Err(); err != nil {
		return err
	}
	return flush()
}

func TranslateSSEStream(r io.Reader, modelID string, chunkID string, created int64, emit func(chunk []byte) error) error {
	sentRole := false
	sawFinish := false
	sawToolCalls := false

	emitJSON := func(choices []any, usage map[string]any) error {
		obj := map[string]any{
			"id":      chunkID,
			"object":  "chat.completion.chunk",
			"created": created,
			"model":   modelID,
			"choices": choices,
		}
		if usage != nil {
			obj["usage"] = usage
		}
		raw, err := json.Marshal(obj)
		if err != nil {
			return err
		}
		return emit(raw)
	}

	err := parseSSEFrames(r, func(event, data string) error {
		switch event {
		case "progress_notice":
			return nil
		case "output":
			var out traeOutputEvent
			if err := json.Unmarshal([]byte(data), &out); err != nil {
				return nil
			}
			delta := map[string]any{}
			if !sentRole {
				delta["role"] = "assistant"
			}
			if out.Response != "" {
				delta["content"] = out.Response
			}
			if out.ReasoningContent != "" {
				delta["reasoning_content"] = out.ReasoningContent
			}
			if len(out.ToolCalls) > 0 {
				sawToolCalls = true
				calls := make([]map[string]any, 0, len(out.ToolCalls))
				for idx, tc := range out.ToolCalls {
					callIdx := idx
					if tc.Index != nil {
						callIdx = *tc.Index
					}
					callType := tc.Type
					if callType == "" {
						callType = "function"
					}
					fn := tc.FunctionCall
					if fn == nil {
						fn = tc.Function
					}
					fnMap := map[string]any{}
					if fn != nil {
						if fn.Name != "" {
							fnMap["name"] = fn.Name
						}
						fnMap["arguments"] = fn.Arguments
					}
					item := map[string]any{
						"index":    callIdx,
						"type":     callType,
						"function": fnMap,
					}
					if tc.ID != "" {
						item["id"] = tc.ID
					}
					calls = append(calls, item)
				}
				delta["tool_calls"] = calls
			}
			if out.Response != "" || out.ReasoningContent != "" || len(out.ToolCalls) > 0 {
				sentRole = true
				return emitJSON([]any{
					map[string]any{
						"index":         0,
						"delta":         delta,
						"finish_reason": nil,
					},
				}, nil)
			}
			return nil
		case "token_usage":
			var u traeUsageEvent
			if err := json.Unmarshal([]byte(data), &u); err != nil {
				return nil
			}
			return emitJSON([]any{}, buildOpenAIUsage(u))
		case "done":
			var d struct {
				FinishReason string `json:"finish_reason"`
			}
			_ = json.Unmarshal([]byte(data), &d)
			sawFinish = true
			return emitJSON([]any{
				map[string]any{
					"index":         0,
					"delta":         map[string]any{},
					"finish_reason": mapFinishReason(d.FinishReason, sawToolCalls),
				},
			}, nil)
		case "error":
			var e struct {
				Message string `json:"message"`
			}
			if err := json.Unmarshal([]byte(data), &e); err == nil && e.Message != "" {
				return fmt.Errorf("trae stream error: %s", e.Message)
			}
			return fmt.Errorf("trae stream error: %s", data)
		default:
			return nil
		}
	})
	if err != nil {
		return err
	}
	if !sawFinish {
		return emitJSON([]any{
			map[string]any{
				"index":         0,
				"delta":         map[string]any{},
				"finish_reason": mapFinishReason("", sawToolCalls),
			},
		}, nil)
	}
	return nil
}

func AssembleNonStreamResponse(r io.Reader, modelID string, respID string, created int64) ([]byte, error) {
	var contentBuf strings.Builder
	var reasoningBuf strings.Builder
	type toolAcc struct {
		ID   string
		Type string
		Name string
		Args strings.Builder
	}
	toolCallsByIdx := make(map[int]*toolAcc)
	var usage map[string]any
	finishReason := "stop"
	sawToolCalls := false

	err := parseSSEFrames(r, func(event, data string) error {
		switch event {
		case "progress_notice":
			return nil
		case "output":
			var out traeOutputEvent
			if err := json.Unmarshal([]byte(data), &out); err != nil {
				return nil
			}
			contentBuf.WriteString(out.Response)
			reasoningBuf.WriteString(out.ReasoningContent)
			for idx, tc := range out.ToolCalls {
				sawToolCalls = true
				callIdx := idx
				if tc.Index != nil {
					callIdx = *tc.Index
				}
				acc := toolCallsByIdx[callIdx]
				if acc == nil {
					acc = &toolAcc{Type: "function"}
					toolCallsByIdx[callIdx] = acc
				}
				if tc.ID != "" {
					acc.ID = tc.ID
				}
				if tc.Type != "" {
					acc.Type = tc.Type
				}
				fn := tc.FunctionCall
				if fn == nil {
					fn = tc.Function
				}
				if fn != nil {
					if fn.Name != "" {
						acc.Name = fn.Name
					}
					acc.Args.WriteString(fn.Arguments)
				}
			}
			return nil
		case "token_usage":
			var u traeUsageEvent
			if err := json.Unmarshal([]byte(data), &u); err == nil {
				usage = buildOpenAIUsage(u)
			}
			return nil
		case "done":
			var d struct {
				FinishReason string `json:"finish_reason"`
			}
			_ = json.Unmarshal([]byte(data), &d)
			finishReason = mapFinishReason(d.FinishReason, sawToolCalls)
			return nil
		case "error":
			var e struct {
				Message string `json:"message"`
			}
			if err := json.Unmarshal([]byte(data), &e); err == nil && e.Message != "" {
				return fmt.Errorf("trae error: %s", e.Message)
			}
			return fmt.Errorf("trae error: %s", data)
		default:
			return nil
		}
	})
	if err != nil {
		return nil, err
	}
	if sawToolCalls && finishReason == "stop" {
		finishReason = "tool_calls"
	}

	msg := map[string]any{
		"role":    "assistant",
		"content": contentBuf.String(),
	}
	if reasoningBuf.Len() > 0 {
		msg["reasoning_content"] = reasoningBuf.String()
	}
	if len(toolCallsByIdx) > 0 {
		indices := make([]int, 0, len(toolCallsByIdx))
		for idx := range toolCallsByIdx {
			indices = append(indices, idx)
		}
		sort.Ints(indices)
		tcs := make([]map[string]any, 0, len(indices))
		for _, idx := range indices {
			acc := toolCallsByIdx[idx]
			id := acc.ID
			if id == "" {
				id = fmt.Sprintf("call_%d", idx)
			}
			tcs = append(tcs, map[string]any{
				"id":   id,
				"type": acc.Type,
				"function": map[string]any{
					"name":      acc.Name,
					"arguments": acc.Args.String(),
				},
			})
		}
		msg["tool_calls"] = tcs
	}

	resp := map[string]any{
		"id":      respID,
		"object":  "chat.completion",
		"created": created,
		"model":   modelID,
		"choices": []any{
			map[string]any{
				"index":         0,
				"message":       msg,
				"finish_reason": finishReason,
			},
		},
	}
	if usage != nil {
		resp["usage"] = usage
	}
	return json.Marshal(resp)
}

func (p *Provider) openUpstreamResponse(ctx context.Context, traePayload []byte) (*http.Response, error) {
	token, err := p.ReadToken()
	if err != nil {
		return nil, err
	}
	resp, err := p.sendRequest(ctx, token, traePayload)
	if err != nil {
		return nil, err
	}
	if resp.StatusCode == http.StatusUnauthorized || resp.StatusCode == http.StatusForbidden {
		_ = resp.Body.Close()
		freshToken, errRefresh := p.RefreshToken(ctx)
		if errRefresh != nil {
			return nil, errRefresh
		}
		resp, err = p.sendRequest(ctx, freshToken, traePayload)
		if err != nil {
			return nil, err
		}
	}
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		defer resp.Body.Close()
		body, _ := io.ReadAll(resp.Body)
		return nil, &StatusError{
			StatusCode: resp.StatusCode,
			Message:    strings.TrimSpace(string(body)),
		}
	}
	return resp, nil
}

func (p *Provider) sendRequest(ctx context.Context, token string, traePayload []byte) (*http.Response, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, p.opts.Endpoint, bytes.NewReader(traePayload))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Accept", "text/event-stream")
	req.Header.Set("Authorization", "Cloud-CLI-JWT "+token)
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("x-app-id", TraeAppID)
	req.Header.Set("x-ide-function", TraeIDEFunction)
	req.Header.Set("x-ide-version-code", p.opts.VersionCode())
	return p.opts.HTTPClient.Do(req)
}

func (p *Provider) DoStream(ctx context.Context, modelID string, openAIBody []byte, emit func(chunk []byte) error) (http.Header, error) {
	route, effort, err := p.ResolveRoute(ctx, modelID)
	if err != nil {
		return nil, err
	}
	traePayload, err := BuildTraePayload(openAIBody, route, effort, p.opts.NewRequestID)
	if err != nil {
		return nil, err
	}
	resp, err := p.openUpstreamResponse(ctx, traePayload)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	chunkID := "chatcmpl-" + p.opts.NewRequestID()
	if err := TranslateSSEStream(resp.Body, route.ID, chunkID, p.opts.NowUnix(), emit); err != nil {
		return resp.Header.Clone(), err
	}
	return resp.Header.Clone(), nil
}

func (p *Provider) StartAsyncStream(ctx context.Context, modelID string, openAIBody []byte, streamID string, sendChunk StreamChunkSender) (http.Header, error) {
	route, effort, err := p.ResolveRoute(ctx, modelID)
	if err != nil {
		return nil, err
	}
	traePayload, err := BuildTraePayload(openAIBody, route, effort, p.opts.NewRequestID)
	if err != nil {
		return nil, err
	}
	resp, err := p.openUpstreamResponse(context.Background(), traePayload)
	if err != nil {
		return nil, err
	}
	headers := resp.Header.Clone()
	chunkID := "chatcmpl-" + p.opts.NewRequestID()
	created := p.opts.NowUnix()

	go func() {
		defer resp.Body.Close()
		streamErr := TranslateSSEStream(resp.Body, route.ID, chunkID, created, func(chunk []byte) error {
			return sendChunk(streamID, chunk, nil, false)
		})
		_ = sendChunk(streamID, nil, streamErr, true)
	}()

	return headers, nil
}

func (p *Provider) DoNonStream(ctx context.Context, modelID string, openAIBody []byte) ([]byte, http.Header, error) {
	route, effort, err := p.ResolveRoute(ctx, modelID)
	if err != nil {
		return nil, nil, err
	}
	traePayload, err := BuildTraePayload(openAIBody, route, effort, p.opts.NewRequestID)
	if err != nil {
		return nil, nil, err
	}
	resp, err := p.openUpstreamResponse(ctx, traePayload)
	if err != nil {
		return nil, nil, err
	}
	defer resp.Body.Close()

	respID := "chatcmpl-" + p.opts.NewRequestID()
	out, err := AssembleNonStreamResponse(resp.Body, route.ID, respID, p.opts.NowUnix())
	if err != nil {
		return nil, nil, err
	}
	return out, resp.Header.Clone(), nil
}

func asInt(v any) (int, bool) {
	switch n := v.(type) {
	case float64:
		return int(n), true
	case int:
		return n, true
	case int64:
		return int(n), true
	default:
		return 0, false
	}
}

func newUUID() string {
	var b [16]byte
	_, _ = rand.Read(b[:])
	b[6] = (b[6] & 0x0f) | 0x40
	b[8] = (b[8] & 0x3f) | 0x80
	return fmt.Sprintf("%s-%s-%s-%s-%s",
		hex.EncodeToString(b[0:4]),
		hex.EncodeToString(b[4:6]),
		hex.EncodeToString(b[6:8]),
		hex.EncodeToString(b[8:10]),
		hex.EncodeToString(b[10:16]),
	)
}
