package web

import (
	"net/http"

	"hermes/internal/auth"
	"hermes/internal/events"
	"hermes/internal/web/handlers"
	"hermes/internal/web/middleware"
)

// setupRoutes configures all HTTP routes
func (s *Server) setupRoutes() http.Handler {
	mux := http.NewServeMux()

	// Auth handlers
	authHandlers := auth.NewHandlers(s.authService)

	// API handlers
	apiHandlers := handlers.NewAPIHandlers(s.projectManager)

	// Event broker
	s.broker = events.NewBroker()
	s.broker.Start()

	// WebSocket handler
	wsHandler := handlers.NewWebSocketHandler(s.broker, s.authService)

	// Execution handler
	execHandler := handlers.NewExecutionHandler(s.projectManager, s.broker)

	// Apply middleware stack
	var handler http.Handler = mux

	// Public routes (no auth required)
	mux.HandleFunc("GET /api/auth/setup", authHandlers.NeedsSetup)
	mux.HandleFunc("POST /api/auth/login", authHandlers.Login)
	mux.HandleFunc("POST /api/auth/register", s.wrapOptionalAuth(authHandlers.Register))

	// Protected routes (auth required)
	mux.HandleFunc("POST /api/auth/logout", s.wrapAuth(authHandlers.Logout))
	mux.HandleFunc("GET /api/auth/me", s.wrapAuth(authHandlers.Me))

	// Project routes
	mux.HandleFunc("GET /api/projects", s.wrapAuth(apiHandlers.ListProjects))
	mux.HandleFunc("POST /api/projects", s.wrapAuth(apiHandlers.AddProject))
	mux.HandleFunc("DELETE /api/projects/{id}", s.wrapAuth(apiHandlers.RemoveProject))
	mux.HandleFunc("PUT /api/projects/{id}/active", s.wrapAuth(apiHandlers.SetActiveProject))

	// Dashboard
	mux.HandleFunc("GET /api/dashboard", s.wrapAuth(apiHandlers.Dashboard))

	// Tasks
	mux.HandleFunc("GET /api/tasks", s.wrapAuth(apiHandlers.ListTasks))
	mux.HandleFunc("GET /api/tasks/{id}", s.wrapAuth(apiHandlers.GetTask))
	mux.HandleFunc("PUT /api/tasks/{id}/status", s.wrapAuth(apiHandlers.UpdateTaskStatus))

	// Features
	mux.HandleFunc("GET /api/features", s.wrapAuth(apiHandlers.ListFeatures))
	mux.HandleFunc("GET /api/features/{id}", s.wrapAuth(apiHandlers.GetFeature))

	// Config
	mux.HandleFunc("GET /api/config", s.wrapAuth(apiHandlers.GetConfig))
	mux.HandleFunc("PUT /api/config", s.wrapAuth(apiHandlers.UpdateConfig))

	// Execution routes
	mux.HandleFunc("GET /api/execution/status", s.wrapAuth(execHandler.GetStatus))
	mux.HandleFunc("POST /api/execution/start", s.wrapAuth(execHandler.Start))
	mux.HandleFunc("POST /api/execution/stop", s.wrapAuth(execHandler.Stop))

	// WebSocket (token passed as query param)
	mux.HandleFunc("GET /ws", wsHandler.HandleConnection)

	// Static files (frontend)
	mux.Handle("GET /", http.FileServer(http.Dir("web/dist")))

	// Apply global middleware
	handler = middleware.Logger(handler)
	handler = middleware.CORS(s.config.CORS.AllowedOrigins, s.config.CORS.AllowCredentials)(handler)
	handler = middleware.Recovery(handler)

	return handler
}

// wrapAuth wraps a handler with auth middleware
func (s *Server) wrapAuth(h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authMiddleware := auth.Middleware(s.authService)
		authMiddleware(h).ServeHTTP(w, r)
	}
}

// wrapOptionalAuth wraps with optional auth (user may or may not be authenticated)
func (s *Server) wrapOptionalAuth(h http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authMiddleware := auth.OptionalMiddleware(s.authService)
		authMiddleware(h).ServeHTTP(w, r)
	}
}

