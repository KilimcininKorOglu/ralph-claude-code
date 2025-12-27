package auth

import (
	"crypto/rand"
	"encoding/hex"
	"time"
)

// User represents a registered user
type User struct {
	ID           string    `json:"id"`
	Username     string    `json:"username"`
	PasswordHash string    `json:"passwordHash"`
	Role         string    `json:"role"` // "admin" or "user"
	CreatedAt    time.Time `json:"createdAt"`
	UpdatedAt    time.Time `json:"updatedAt"`
}

// Session represents an active user session
type Session struct {
	ID        string    `json:"id"`
	UserID    string    `json:"userId"`
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expiresAt"`
	CreatedAt time.Time `json:"createdAt"`
}

// AuthStore holds users and sessions
type AuthStore struct {
	Users    []User    `json:"users"`
	Sessions []Session `json:"sessions"`
}

// GenerateID generates a random ID
func GenerateID() string {
	b := make([]byte, 16)
	rand.Read(b)
	return hex.EncodeToString(b)
}

// GenerateToken generates a random session token
func GenerateToken() string {
	b := make([]byte, 32)
	rand.Read(b)
	return hex.EncodeToString(b)
}

// IsExpired checks if session has expired
func (s *Session) IsExpired() bool {
	return time.Now().After(s.ExpiresAt)
}

// IsAdmin checks if user is an admin
func (u *User) IsAdmin() bool {
	return u.Role == "admin"
}
