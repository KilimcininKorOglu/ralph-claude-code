package auth

import (
	"context"
	"net/http"
	"strings"
)

type contextKey string

const UserContextKey contextKey = "user"

// Middleware creates an HTTP middleware for authentication
func Middleware(authService *AuthService) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Get token from header or cookie
			token := extractToken(r)
			if token == "" {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			// Validate session
			user, err := authService.ValidateSession(token)
			if err != nil {
				http.Error(w, "Unauthorized", http.StatusUnauthorized)
				return
			}

			// Add user to context
			ctx := context.WithValue(r.Context(), UserContextKey, user)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// OptionalMiddleware adds user to context if authenticated, but doesn't require it
func OptionalMiddleware(authService *AuthService) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token := extractToken(r)
			if token != "" {
				user, err := authService.ValidateSession(token)
				if err == nil {
					ctx := context.WithValue(r.Context(), UserContextKey, user)
					r = r.WithContext(ctx)
				}
			}
			next.ServeHTTP(w, r)
		})
	}
}

// AdminMiddleware requires the user to be an admin
func AdminMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		user := GetUserFromContext(r.Context())
		if user == nil || !user.IsAdmin() {
			http.Error(w, "Forbidden", http.StatusForbidden)
			return
		}
		next.ServeHTTP(w, r)
	})
}

// GetUserFromContext extracts user from request context
func GetUserFromContext(ctx context.Context) *User {
	user, ok := ctx.Value(UserContextKey).(*User)
	if !ok {
		return nil
	}
	return user
}

// extractToken gets the auth token from request
func extractToken(r *http.Request) string {
	// Try Authorization header first
	auth := r.Header.Get("Authorization")
	if strings.HasPrefix(auth, "Bearer ") {
		return strings.TrimPrefix(auth, "Bearer ")
	}

	// Try cookie
	cookie, err := r.Cookie("hermes_session")
	if err == nil {
		return cookie.Value
	}

	return ""
}
