package handlers

import (
	"log"
	"net/http"
	"time"

	"github.com/gorilla/websocket"
	"hermes/internal/auth"
	"hermes/internal/events"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for development
	},
}

// WebSocketHandler handles WebSocket connections
type WebSocketHandler struct {
	broker      *events.Broker
	authService *auth.AuthService
}

// NewWebSocketHandler creates a new WebSocket handler
func NewWebSocketHandler(broker *events.Broker, authService *auth.AuthService) *WebSocketHandler {
	return &WebSocketHandler{
		broker:      broker,
		authService: authService,
	}
}

// HandleConnection handles a WebSocket connection
func (h *WebSocketHandler) HandleConnection(w http.ResponseWriter, r *http.Request) {
	// Upgrade HTTP connection to WebSocket
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Printf("WebSocket upgrade error: %v", err)
		return
	}
	defer conn.Close()

	// Get user from token (optional for WebSocket)
	token := r.URL.Query().Get("token")
	var user *auth.User
	if token != "" {
		user, _ = h.authService.ValidateSession(token)
	}

	// Create subscriber
	subscriber := h.broker.Subscribe([]events.Channel{
		events.ChannelExecution,
		events.ChannelTasks,
		events.ChannelSystem,
	})
	defer h.broker.Unsubscribe(subscriber)

	log.Printf("WebSocket connected: %s (user: %v)", subscriber.ID, user != nil)

	// Start goroutines for reading and writing
	done := make(chan struct{})

	// Writer goroutine - sends events to client
	go func() {
		for {
			select {
			case event, ok := <-subscriber.Send:
				if !ok {
					return
				}
				msg := events.ServerMessage{
					Type:      "event",
					Channel:   string(event.Channel),
					Event:     string(event.Type),
					Data:      event.Data,
					Timestamp: event.Timestamp.Format(time.RFC3339),
				}
				if err := conn.WriteJSON(msg); err != nil {
					log.Printf("WebSocket write error: %v", err)
					return
				}
			case <-done:
				return
			}
		}
	}()

	// Reader goroutine - handles client messages
	for {
		var msg events.ClientMessage
		if err := conn.ReadJSON(&msg); err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseNormalClosure) {
				log.Printf("WebSocket read error: %v", err)
			}
			close(done)
			break
		}

		h.handleClientMessage(conn, subscriber, msg)
	}

	log.Printf("WebSocket disconnected: %s", subscriber.ID)
}

// handleClientMessage processes messages from the client
func (h *WebSocketHandler) handleClientMessage(conn *websocket.Conn, sub *events.Subscriber, msg events.ClientMessage) {
	switch msg.Type {
	case "subscribe":
		channel := events.Channel(msg.Channel)
		sub.AddChannel(channel)
		h.sendAck(conn, "subscribed", msg.Channel)

	case "unsubscribe":
		channel := events.Channel(msg.Channel)
		sub.RemoveChannel(channel)
		h.sendAck(conn, "unsubscribed", msg.Channel)

	case "ping":
		h.sendAck(conn, "pong", "")

	default:
		h.sendError(conn, "unknown message type: "+msg.Type)
	}
}

func (h *WebSocketHandler) sendAck(conn *websocket.Conn, event, channel string) {
	msg := events.ServerMessage{
		Type:      "ack",
		Event:     event,
		Channel:   channel,
		Timestamp: time.Now().Format(time.RFC3339),
	}
	conn.WriteJSON(msg)
}

func (h *WebSocketHandler) sendError(conn *websocket.Conn, errMsg string) {
	msg := events.ServerMessage{
		Type:      "error",
		Error:     errMsg,
		Timestamp: time.Now().Format(time.RFC3339),
	}
	conn.WriteJSON(msg)
}

// BroadcastJSON sends a JSON message to all subscribers of a channel
func (h *WebSocketHandler) BroadcastEvent(channel events.Channel, eventType events.EventType, data interface{}) {
	h.broker.Publish(channel, eventType, data)
}
