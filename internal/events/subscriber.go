package events

// Subscriber represents a client subscribed to events
type Subscriber struct {
	ID       string
	Channels []Channel
	Send     chan Event
}

// IsSubscribedTo checks if subscriber is subscribed to a channel
func (s *Subscriber) IsSubscribedTo(channel Channel) bool {
	for _, ch := range s.Channels {
		if ch == channel {
			return true
		}
	}
	return false
}

// AddChannel adds a channel subscription
func (s *Subscriber) AddChannel(channel Channel) {
	if !s.IsSubscribedTo(channel) {
		s.Channels = append(s.Channels, channel)
	}
}

// RemoveChannel removes a channel subscription
func (s *Subscriber) RemoveChannel(channel Channel) {
	for i, ch := range s.Channels {
		if ch == channel {
			s.Channels = append(s.Channels[:i], s.Channels[i+1:]...)
			return
		}
	}
}
