package auth

import (
	"encoding/json"
	"net/http"
	"time"
)

// LoginRequest represents login form data
type LoginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

// RegisterRequest represents registration form data
type RegisterRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

// AuthResponse represents auth API response
type AuthResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message,omitempty"`
	Token   string `json:"token,omitempty"`
	User    *User  `json:"user,omitempty"`
}

// Handlers holds auth HTTP handlers
type Handlers struct {
	authService *AuthService
}

// NewHandlers creates new auth handlers
func NewHandlers(authService *AuthService) *Handlers {
	return &Handlers{authService: authService}
}

// Login handles POST /api/auth/login
func (h *Handlers) Login(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondJSON(w, http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "Invalid request body",
		})
		return
	}

	session, err := h.authService.Login(req.Username, req.Password)
	if err != nil {
		status := http.StatusUnauthorized
		if err == ErrUserNotFound {
			status = http.StatusNotFound
		}
		respondJSON(w, status, AuthResponse{
			Success: false,
			Message: err.Error(),
		})
		return
	}

	// Set session cookie
	http.SetCookie(w, &http.Cookie{
		Name:     "hermes_session",
		Value:    session.Token,
		Expires:  session.ExpiresAt,
		HttpOnly: true,
		Path:     "/",
		SameSite: http.SameSiteLaxMode,
	})

	user, _ := h.authService.GetUser(session.UserID)

	respondJSON(w, http.StatusOK, AuthResponse{
		Success: true,
		Token:   session.Token,
		User: &User{
			ID:       user.ID,
			Username: user.Username,
			Role:     user.Role,
		},
	})
}

// Logout handles POST /api/auth/logout
func (h *Handlers) Logout(w http.ResponseWriter, r *http.Request) {
	cookie, err := r.Cookie("hermes_session")
	if err == nil {
		h.authService.Logout(cookie.Value)
	}

	// Clear cookie
	http.SetCookie(w, &http.Cookie{
		Name:     "hermes_session",
		Value:    "",
		Expires:  time.Unix(0, 0),
		HttpOnly: true,
		Path:     "/",
	})

	respondJSON(w, http.StatusOK, AuthResponse{
		Success: true,
		Message: "Logged out successfully",
	})
}

// Register handles POST /api/auth/register
func (h *Handlers) Register(w http.ResponseWriter, r *http.Request) {
	// Only allow registration if no users exist or if current user is admin
	currentUser := GetUserFromContext(r.Context())
	if h.authService.HasUsers() && (currentUser == nil || !currentUser.IsAdmin()) {
		respondJSON(w, http.StatusForbidden, AuthResponse{
			Success: false,
			Message: "Registration not allowed",
		})
		return
	}

	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondJSON(w, http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "Invalid request body",
		})
		return
	}

	if len(req.Username) < 3 || len(req.Password) < 6 {
		respondJSON(w, http.StatusBadRequest, AuthResponse{
			Success: false,
			Message: "Username must be at least 3 chars, password at least 6 chars",
		})
		return
	}

	user, err := h.authService.Register(req.Username, req.Password, false)
	if err != nil {
		status := http.StatusInternalServerError
		if err == ErrUserExists {
			status = http.StatusConflict
		}
		respondJSON(w, status, AuthResponse{
			Success: false,
			Message: err.Error(),
		})
		return
	}

	respondJSON(w, http.StatusCreated, AuthResponse{
		Success: true,
		User: &User{
			ID:       user.ID,
			Username: user.Username,
			Role:     user.Role,
		},
	})
}

// Me handles GET /api/auth/me
func (h *Handlers) Me(w http.ResponseWriter, r *http.Request) {
	user := GetUserFromContext(r.Context())
	if user == nil {
		respondJSON(w, http.StatusUnauthorized, AuthResponse{
			Success: false,
			Message: "Not authenticated",
		})
		return
	}

	respondJSON(w, http.StatusOK, AuthResponse{
		Success: true,
		User: &User{
			ID:       user.ID,
			Username: user.Username,
			Role:     user.Role,
		},
	})
}

// NeedsSetup handles GET /api/auth/setup
func (h *Handlers) NeedsSetup(w http.ResponseWriter, r *http.Request) {
	respondJSON(w, http.StatusOK, map[string]bool{
		"needsSetup": !h.authService.HasUsers(),
	})
}

func respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}
