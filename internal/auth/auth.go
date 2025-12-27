package auth

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"sync"
	"time"

	"golang.org/x/crypto/bcrypt"
)

var (
	ErrUserNotFound      = errors.New("user not found")
	ErrUserExists        = errors.New("user already exists")
	ErrInvalidPassword   = errors.New("invalid password")
	ErrSessionNotFound   = errors.New("session not found")
	ErrSessionExpired    = errors.New("session expired")
	ErrUnauthorized      = errors.New("unauthorized")
)

// AuthService manages user authentication
type AuthService struct {
	store        *AuthStore
	dataFile     string
	sessionHours int
	mu           sync.RWMutex
}

// NewAuthService creates a new auth service
func NewAuthService(dataFile string, sessionHours int) (*AuthService, error) {
	service := &AuthService{
		store:        &AuthStore{Users: []User{}, Sessions: []Session{}},
		dataFile:     dataFile,
		sessionHours: sessionHours,
	}

	// Create directory if not exists
	dir := filepath.Dir(dataFile)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, err
	}

	// Load existing data
	if _, err := os.Stat(dataFile); err == nil {
		if err := service.load(); err != nil {
			return nil, err
		}
	}

	return service, nil
}

// load reads auth data from file
func (s *AuthService) load() error {
	data, err := os.ReadFile(s.dataFile)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, s.store)
}

// save writes auth data to file
func (s *AuthService) save() error {
	data, err := json.MarshalIndent(s.store, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(s.dataFile, data, 0600)
}

// Register creates a new user
func (s *AuthService) Register(username, password string, isAdmin bool) (*User, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Check if user exists
	for _, u := range s.store.Users {
		if u.Username == username {
			return nil, ErrUserExists
		}
	}

	// Hash password
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	role := "user"
	if isAdmin || len(s.store.Users) == 0 {
		// First user is always admin
		role = "admin"
	}

	user := User{
		ID:           GenerateID(),
		Username:     username,
		PasswordHash: string(hash),
		Role:         role,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	s.store.Users = append(s.store.Users, user)

	if err := s.save(); err != nil {
		return nil, err
	}

	return &user, nil
}

// Login authenticates a user and creates a session
func (s *AuthService) Login(username, password string) (*Session, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Find user
	var user *User
	for i := range s.store.Users {
		if s.store.Users[i].Username == username {
			user = &s.store.Users[i]
			break
		}
	}

	if user == nil {
		return nil, ErrUserNotFound
	}

	// Check password
	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return nil, ErrInvalidPassword
	}

	// Create session
	session := Session{
		ID:        GenerateID(),
		UserID:    user.ID,
		Token:     GenerateToken(),
		ExpiresAt: time.Now().Add(time.Duration(s.sessionHours) * time.Hour),
		CreatedAt: time.Now(),
	}

	s.store.Sessions = append(s.store.Sessions, session)

	if err := s.save(); err != nil {
		return nil, err
	}

	return &session, nil
}

// Logout invalidates a session
func (s *AuthService) Logout(token string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	for i, sess := range s.store.Sessions {
		if sess.Token == token {
			s.store.Sessions = append(s.store.Sessions[:i], s.store.Sessions[i+1:]...)
			return s.save()
		}
	}

	return ErrSessionNotFound
}

// ValidateSession checks if a session is valid and returns the user
func (s *AuthService) ValidateSession(token string) (*User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for _, sess := range s.store.Sessions {
		if sess.Token == token {
			if sess.IsExpired() {
				return nil, ErrSessionExpired
			}

			// Find user
			for i := range s.store.Users {
				if s.store.Users[i].ID == sess.UserID {
					return &s.store.Users[i], nil
				}
			}
		}
	}

	return nil, ErrSessionNotFound
}

// GetUser returns a user by ID
func (s *AuthService) GetUser(id string) (*User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	for i := range s.store.Users {
		if s.store.Users[i].ID == id {
			return &s.store.Users[i], nil
		}
	}

	return nil, ErrUserNotFound
}

// ListUsers returns all users (without passwords)
func (s *AuthService) ListUsers() []User {
	s.mu.RLock()
	defer s.mu.RUnlock()

	users := make([]User, len(s.store.Users))
	for i, u := range s.store.Users {
		users[i] = User{
			ID:        u.ID,
			Username:  u.Username,
			Role:      u.Role,
			CreatedAt: u.CreatedAt,
			UpdatedAt: u.UpdatedAt,
		}
	}
	return users
}

// HasUsers returns true if there are any registered users
func (s *AuthService) HasUsers() bool {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return len(s.store.Users) > 0
}

// CleanupExpiredSessions removes expired sessions
func (s *AuthService) CleanupExpiredSessions() error {
	s.mu.Lock()
	defer s.mu.Unlock()

	validSessions := []Session{}
	for _, sess := range s.store.Sessions {
		if !sess.IsExpired() {
			validSessions = append(validSessions, sess)
		}
	}

	s.store.Sessions = validSessions
	return s.save()
}
