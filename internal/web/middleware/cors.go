package middleware

import (
	"net/http"
	"strings"
)

// CORS returns a middleware that handles CORS
func CORS(allowedOrigins []string, allowCredentials bool) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			origin := r.Header.Get("Origin")
			
			// Check if origin is allowed
			allowed := false
			for _, o := range allowedOrigins {
				if o == "*" || o == origin {
					allowed = true
					break
				}
			}

			if allowed {
				w.Header().Set("Access-Control-Allow-Origin", origin)
			}

			if allowCredentials {
				w.Header().Set("Access-Control-Allow-Credentials", "true")
			}

			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
			w.Header().Set("Access-Control-Max-Age", "86400")

			// Handle preflight
			if r.Method == "OPTIONS" {
				w.WriteHeader(http.StatusOK)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

// IsAllowedOrigin checks if an origin is in the allowed list
func IsAllowedOrigin(origin string, allowedOrigins []string) bool {
	for _, o := range allowedOrigins {
		if o == "*" {
			return true
		}
		if strings.EqualFold(o, origin) {
			return true
		}
	}
	return false
}
