package ai

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"time"
)

// GeminiProvider implements Provider using Google Gemini CLI
type GeminiProvider struct{}

// NewGeminiProvider creates a new Gemini provider
func NewGeminiProvider() *GeminiProvider {
	return &GeminiProvider{}
}

// Name returns the provider name
func (p *GeminiProvider) Name() string {
	return "gemini"
}

// IsAvailable checks if Gemini CLI is installed
func (p *GeminiProvider) IsAvailable() bool {
	_, err := exec.LookPath("gemini")
	return err == nil
}

// geminiJSONResponse represents the JSON response from gemini CLI
type geminiJSONResponse struct {
	Response struct {
		Text string `json:"text"`
	} `json:"response"`
	Usage struct {
		InputTokens  int `json:"inputTokens"`
		OutputTokens int `json:"outputTokens"`
	} `json:"usage"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

// geminiStreamEvent represents a streaming event from gemini
type geminiStreamEvent struct {
	Type      string  `json:"type"`
	Text      string  `json:"text,omitempty"`
	ToolName  string  `json:"toolName,omitempty"`
	ToolID    string  `json:"toolId,omitempty"`
	Cost      float64 `json:"cost,omitempty"`
	Duration  float64 `json:"duration,omitempty"`
	Model     string  `json:"model,omitempty"`
	IsPartial bool    `json:"isPartial,omitempty"`
}

// Execute runs a prompt and returns the result
func (p *GeminiProvider) Execute(ctx context.Context, opts *ExecuteOptions) (*ExecuteResult, error) {
	start := time.Now()

	// Write prompt to temp file for large prompts
	tmpFile, err := os.CreateTemp("", "hermes-gemini-*.md")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp file: %w", err)
	}
	defer os.Remove(tmpFile.Name())

	if _, err := tmpFile.WriteString(opts.Prompt); err != nil {
		tmpFile.Close()
		return nil, fmt.Errorf("failed to write prompt: %w", err)
	}
	tmpFile.Close()

	// Build command - use headless mode with JSON output
	// gemini -p "prompt" --output-format json --sandbox none
	args := []string{
		"-p", fmt.Sprintf("Read %s and follow the instructions.", tmpFile.Name()),
		"--output-format", "json",
		"--sandbox", "none", // Disable sandbox for file operations
	}

	cmd := exec.CommandContext(ctx, "gemini", args...)

	if opts.WorkDir != "" {
		cmd.Dir = opts.WorkDir
	}

	output, err := cmd.Output()
	if err != nil {
		// Try to parse error from stderr
		if exitErr, ok := err.(*exec.ExitError); ok {
			return &ExecuteResult{
				Success:  false,
				Error:    string(exitErr.Stderr),
				Duration: time.Since(start).Seconds(),
			}, nil
		}
		return nil, fmt.Errorf("failed to run gemini: %w", err)
	}

	// Parse JSON response
	var resp geminiJSONResponse
	if err := json.Unmarshal(output, &resp); err != nil {
		// If not JSON, treat as plain text
		return &ExecuteResult{
			Output:   string(output),
			Success:  true,
			Duration: time.Since(start).Seconds(),
		}, nil
	}

	if resp.Error != nil {
		return &ExecuteResult{
			Success:  false,
			Error:    resp.Error.Message,
			Duration: time.Since(start).Seconds(),
		}, nil
	}

	return &ExecuteResult{
		Output:    resp.Response.Text,
		TokensIn:  resp.Usage.InputTokens,
		TokensOut: resp.Usage.OutputTokens,
		Success:   true,
		Duration:  time.Since(start).Seconds(),
	}, nil
}

// ExecuteStream runs a prompt with streaming output
func (p *GeminiProvider) ExecuteStream(ctx context.Context, opts *ExecuteOptions) (<-chan StreamEvent, error) {
	events := make(chan StreamEvent, 100)

	go func() {
		defer close(events)

		// Write prompt to temp file
		tmpFile, err := os.CreateTemp("", "hermes-gemini-*.md")
		if err != nil {
			events <- StreamEvent{Type: "error", Text: err.Error()}
			return
		}
		defer os.Remove(tmpFile.Name())

		if _, err := tmpFile.WriteString(opts.Prompt); err != nil {
			tmpFile.Close()
			events <- StreamEvent{Type: "error", Text: err.Error()}
			return
		}
		tmpFile.Close()

		// Use streaming output format
		args := []string{
			"-p", fmt.Sprintf("Read %s and follow the instructions.", tmpFile.Name()),
			"--output-format", "stream-json",
			"--sandbox", "none",
		}

		cmd := exec.CommandContext(ctx, "gemini", args...)

		if opts.WorkDir != "" {
			cmd.Dir = opts.WorkDir
		}

		stdout, err := cmd.StdoutPipe()
		if err != nil {
			events <- StreamEvent{Type: "error", Text: err.Error()}
			return
		}

		if err := cmd.Start(); err != nil {
			events <- StreamEvent{Type: "error", Text: err.Error()}
			return
		}

		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			line := scanner.Text()
			var gEvent geminiStreamEvent
			if err := json.Unmarshal([]byte(line), &gEvent); err != nil {
				// Plain text output
				events <- StreamEvent{
					Type: "assistant",
					Text: line,
				}
				continue
			}

			switch gEvent.Type {
			case "system":
				events <- StreamEvent{
					Type:  "system",
					Model: gEvent.Model,
				}
			case "text", "content":
				events <- StreamEvent{
					Type: "assistant",
					Text: gEvent.Text,
				}
			case "tool_use", "toolCall":
				events <- StreamEvent{
					Type:     "tool_use",
					ToolName: gEvent.ToolName,
					ToolID:   gEvent.ToolID,
				}
			case "tool_result", "toolResult":
				events <- StreamEvent{
					Type:     "tool_result",
					ToolName: gEvent.ToolName,
				}
			case "result", "done", "complete":
				events <- StreamEvent{
					Type:     "result",
					Text:     gEvent.Text,
					Cost:     gEvent.Cost,
					Duration: gEvent.Duration,
				}
			case "error":
				events <- StreamEvent{
					Type: "error",
					Text: gEvent.Text,
				}
			}
		}

		if err := cmd.Wait(); err != nil {
			events <- StreamEvent{Type: "error", Text: err.Error()}
		}
	}()

	return events, nil
}
