package handlers

import (
	"encoding/json"
	"net/http"
	"sync"

	"hermes/internal/events"
	"hermes/internal/project"
)

// ExecutionState represents the current execution state
type ExecutionState struct {
	Running    bool   `json:"running"`
	TaskID     string `json:"taskId,omitempty"`
	TaskName   string `json:"taskName,omitempty"`
	Loop       int    `json:"loop"`
	MaxLoops   int    `json:"maxLoops"`
	Progress   int    `json:"progress"`
	StartedAt  string `json:"startedAt,omitempty"`
	Output     string `json:"output,omitempty"`
}

// ExecutionHandler handles execution-related API endpoints
type ExecutionHandler struct {
	projectManager *project.Manager
	broker         *events.Broker
	state          ExecutionState
	mu             sync.RWMutex
}

// NewExecutionHandler creates a new execution handler
func NewExecutionHandler(pm *project.Manager, broker *events.Broker) *ExecutionHandler {
	return &ExecutionHandler{
		projectManager: pm,
		broker:         broker,
	}
}

// GetStatus handles GET /api/execution/status
func (h *ExecutionHandler) GetStatus(w http.ResponseWriter, r *http.Request) {
	h.mu.RLock()
	state := h.state
	h.mu.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(state)
}

// Start handles POST /api/execution/start
func (h *ExecutionHandler) Start(w http.ResponseWriter, r *http.Request) {
	var req struct {
		TaskID string `json:"taskId"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	h.mu.Lock()
	if h.state.Running {
		h.mu.Unlock()
		http.Error(w, "Execution already running", http.StatusConflict)
		return
	}

	h.state = ExecutionState{
		Running:  true,
		TaskID:   req.TaskID,
		Loop:     1,
		MaxLoops: 10,
		Progress: 0,
	}
	h.mu.Unlock()

	// Publish event
	h.broker.Publish(events.ChannelExecution, events.EventExecutionStarted, events.ExecutionData{
		TaskID: req.TaskID,
	})

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Execution started",
		"taskId":  req.TaskID,
	})
}

// Stop handles POST /api/execution/stop
func (h *ExecutionHandler) Stop(w http.ResponseWriter, r *http.Request) {
	h.mu.Lock()
	if !h.state.Running {
		h.mu.Unlock()
		http.Error(w, "No execution running", http.StatusBadRequest)
		return
	}

	taskID := h.state.TaskID
	h.state = ExecutionState{}
	h.mu.Unlock()

	// Publish event
	h.broker.Publish(events.ChannelExecution, events.EventExecutionCompleted, events.ExecutionData{
		TaskID:  taskID,
		Success: false,
		Error:   "Stopped by user",
	})

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"message": "Execution stopped",
	})
}

// UpdateProgress updates the execution progress (called internally)
func (h *ExecutionHandler) UpdateProgress(taskID string, loop, progress int, output string) {
	h.mu.Lock()
	h.state.Loop = loop
	h.state.Progress = progress
	h.state.Output = output
	h.mu.Unlock()

	h.broker.Publish(events.ChannelExecution, events.EventExecutionProgress, events.ExecutionData{
		TaskID:   taskID,
		Loop:     loop,
		Progress: progress,
		Output:   output,
	})
}

// SendOutput sends execution output (called internally)
func (h *ExecutionHandler) SendOutput(taskID, output string) {
	h.broker.Publish(events.ChannelExecution, events.EventExecutionOutput, events.ExecutionData{
		TaskID: taskID,
		Output: output,
	})
}

// Complete marks execution as complete (called internally)
func (h *ExecutionHandler) Complete(taskID string, success bool, err string) {
	h.mu.Lock()
	h.state = ExecutionState{}
	h.mu.Unlock()

	h.broker.Publish(events.ChannelExecution, events.EventExecutionCompleted, events.ExecutionData{
		TaskID:  taskID,
		Success: success,
		Error:   err,
	})
}
