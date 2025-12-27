package web

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"time"

	"hermes/internal/auth"
	"hermes/internal/config"
	"hermes/internal/events"
	"hermes/internal/project"
)

// Server represents the HTTP server
type Server struct {
	config         *config.WebConfig
	httpServer     *http.Server
	authService    *auth.AuthService
	projectManager *project.Manager
	broker         *events.Broker
	router         http.Handler
}

// NewServer creates a new web server
func NewServer(cfg *config.WebConfig, globalDataDir string) (*Server, error) {
	// Initialize auth service
	authDataFile := globalDataDir + "/auth.json"
	authService, err := auth.NewAuthService(authDataFile, cfg.Auth.SessionHours)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize auth service: %w", err)
	}

	// Initialize project manager
	projectDataFile := globalDataDir + "/projects.json"
	projectManager, err := project.NewManager(projectDataFile)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize project manager: %w", err)
	}

	server := &Server{
		config:         cfg,
		authService:    authService,
		projectManager: projectManager,
	}

	// Setup routes
	server.router = server.setupRoutes()

	return server, nil
}

// Start starts the HTTP server
func (s *Server) Start() error {
	addr := fmt.Sprintf("%s:%d", s.config.Host, s.config.Port)

	s.httpServer = &http.Server{
		Addr:         addr,
		Handler:      s.router,
		ReadTimeout:  15 * time.Second,
		WriteTimeout: 15 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	log.Printf("Starting web server on http://%s", addr)

	if s.config.TLS.Enabled {
		return s.httpServer.ListenAndServeTLS(s.config.TLS.CertFile, s.config.TLS.KeyFile)
	}

	return s.httpServer.ListenAndServe()
}

// Stop gracefully stops the server
func (s *Server) Stop(ctx context.Context) error {
	log.Println("Stopping web server...")
	return s.httpServer.Shutdown(ctx)
}

// AuthService returns the auth service
func (s *Server) AuthService() *auth.AuthService {
	return s.authService
}

// ProjectManager returns the project manager
func (s *Server) ProjectManager() *project.Manager {
	return s.projectManager
}
