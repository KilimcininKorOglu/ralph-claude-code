package events

import "time"

// EventType represents the type of event
type EventType string

const (
	// Execution events
	EventExecutionStarted   EventType = "execution.started"
	EventExecutionOutput    EventType = "execution.output"
	EventExecutionProgress  EventType = "execution.progress"
	EventExecutionCompleted EventType = "execution.completed"
	EventExecutionError     EventType = "execution.error"

	// Task events
	EventTaskCreated       EventType = "task.created"
	EventTaskUpdated       EventType = "task.updated"
	EventTaskStatusChanged EventType = "task.status_changed"

	// Log events
	EventLogEntry EventType = "log.entry"

	// System events
	EventSystemStatus EventType = "system.status"
)

// Channel represents a subscription channel
type Channel string

const (
	ChannelExecution Channel = "execution"
	ChannelTasks     Channel = "tasks"
	ChannelLogs      Channel = "logs"
	ChannelSystem    Channel = "system"
)

// Event represents a real-time event
type Event struct {
	ID        string      `json:"id"`
	Channel   Channel     `json:"channel"`
	Type      EventType   `json:"type"`
	Data      interface{} `json:"data"`
	Timestamp time.Time   `json:"timestamp"`
}

// ExecutionData contains execution event data
type ExecutionData struct {
	TaskID   string `json:"taskId"`
	TaskName string `json:"taskName,omitempty"`
	Output   string `json:"output,omitempty"`
	Progress int    `json:"progress,omitempty"`
	Success  bool   `json:"success,omitempty"`
	Error    string `json:"error,omitempty"`
	Loop     int    `json:"loop,omitempty"`
	MaxLoops int    `json:"maxLoops,omitempty"`
}

// TaskData contains task event data
type TaskData struct {
	TaskID    string `json:"taskId"`
	FeatureID string `json:"featureId,omitempty"`
	Status    string `json:"status,omitempty"`
	Title     string `json:"title,omitempty"`
}

// LogData contains log event data
type LogData struct {
	Level   string `json:"level"`
	Message string `json:"message"`
	TaskID  string `json:"taskId,omitempty"`
}

// ClientMessage represents a message from a WebSocket client
type ClientMessage struct {
	Type    string `json:"type"` // subscribe, unsubscribe, command
	Channel string `json:"channel,omitempty"`
	Command string `json:"command,omitempty"`
	Payload interface{} `json:"payload,omitempty"`
}

// ServerMessage represents a message to a WebSocket client
type ServerMessage struct {
	Type      string      `json:"type"` // event, error, ack
	Channel   string      `json:"channel,omitempty"`
	Event     string      `json:"event,omitempty"`
	Data      interface{} `json:"data,omitempty"`
	Timestamp string      `json:"timestamp,omitempty"`
	Error     string      `json:"error,omitempty"`
}
