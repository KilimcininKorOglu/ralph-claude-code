package events

import (
	"sync"
	"time"

	"hermes/internal/auth"
)

// Broker manages event distribution to subscribers
type Broker struct {
	subscribers map[Channel]map[*Subscriber]bool
	broadcast   chan Event
	subscribe   chan subscribeRequest
	unsubscribe chan *Subscriber
	mu          sync.RWMutex
	running     bool
}

type subscribeRequest struct {
	subscriber *Subscriber
	channels   []Channel
}

// NewBroker creates a new event broker
func NewBroker() *Broker {
	return &Broker{
		subscribers: make(map[Channel]map[*Subscriber]bool),
		broadcast:   make(chan Event, 256),
		subscribe:   make(chan subscribeRequest, 16),
		unsubscribe: make(chan *Subscriber, 16),
	}
}

// Start starts the broker's event loop
func (b *Broker) Start() {
	b.running = true
	go b.run()
}

// Stop stops the broker
func (b *Broker) Stop() {
	b.running = false
	close(b.broadcast)
}

// run is the main event loop
func (b *Broker) run() {
	for b.running {
		select {
		case req := <-b.subscribe:
			b.handleSubscribe(req)
		case sub := <-b.unsubscribe:
			b.handleUnsubscribe(sub)
		case event, ok := <-b.broadcast:
			if !ok {
				return
			}
			b.handleBroadcast(event)
		}
	}
}

func (b *Broker) handleSubscribe(req subscribeRequest) {
	b.mu.Lock()
	defer b.mu.Unlock()

	for _, channel := range req.channels {
		if b.subscribers[channel] == nil {
			b.subscribers[channel] = make(map[*Subscriber]bool)
		}
		b.subscribers[channel][req.subscriber] = true
	}
}

func (b *Broker) handleUnsubscribe(sub *Subscriber) {
	b.mu.Lock()
	defer b.mu.Unlock()

	for channel := range b.subscribers {
		delete(b.subscribers[channel], sub)
	}
	close(sub.Send)
}

func (b *Broker) handleBroadcast(event Event) {
	b.mu.RLock()
	defer b.mu.RUnlock()

	if subs, ok := b.subscribers[event.Channel]; ok {
		for sub := range subs {
			select {
			case sub.Send <- event:
			default:
				// Skip slow subscriber
			}
		}
	}
}

// Publish sends an event to all subscribers of the channel
func (b *Broker) Publish(channel Channel, eventType EventType, data interface{}) {
	event := Event{
		ID:        auth.GenerateID(),
		Channel:   channel,
		Type:      eventType,
		Data:      data,
		Timestamp: time.Now(),
	}

	select {
	case b.broadcast <- event:
	default:
		// Channel full, skip
	}
}

// Subscribe creates a new subscriber for the given channels
func (b *Broker) Subscribe(channels []Channel) *Subscriber {
	sub := &Subscriber{
		ID:       auth.GenerateID(),
		Channels: channels,
		Send:     make(chan Event, 64),
	}

	b.subscribe <- subscribeRequest{
		subscriber: sub,
		channels:   channels,
	}

	return sub
}

// Unsubscribe removes a subscriber
func (b *Broker) Unsubscribe(sub *Subscriber) {
	b.unsubscribe <- sub
}

// SubscriberCount returns the number of subscribers for a channel
func (b *Broker) SubscriberCount(channel Channel) int {
	b.mu.RLock()
	defer b.mu.RUnlock()

	if subs, ok := b.subscribers[channel]; ok {
		return len(subs)
	}
	return 0
}
