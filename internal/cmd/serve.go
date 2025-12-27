package cmd

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/spf13/cobra"
	"hermes/internal/config"
	"hermes/internal/ui"
	"hermes/internal/web"
)

var (
	servePort int
	serveHost string
)

// NewServeCmd creates the serve subcommand
func NewServeCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "serve",
		Short: "Start web interface server",
		Long:  "Start the Hermes web interface server for browser-based management",
		Example: `  hermes serve
  hermes serve --port 8080
  hermes serve --host 0.0.0.0 --port 3000`,
		RunE: func(cmd *cobra.Command, args []string) error {
			return serveExecute()
		},
	}

	cmd.Flags().IntVar(&servePort, "port", 8080, "HTTP server port")
	cmd.Flags().StringVar(&serveHost, "host", "127.0.0.1", "HTTP server host")

	return cmd
}

func serveExecute() error {
	ui.PrintBanner()
	ui.PrintHeader("Web Interface Server")

	// Load config
	cfg, err := config.Load(".")
	if err != nil {
		cfg = config.DefaultConfig()
	}

	// Override with flags
	if servePort != 0 {
		cfg.Web.Port = servePort
	}
	if serveHost != "" {
		cfg.Web.Host = serveHost
	}

	// Get global data directory for auth and projects
	homeDir, err := os.UserHomeDir()
	if err != nil {
		return fmt.Errorf("failed to get home directory: %w", err)
	}
	globalDataDir := homeDir + "/.hermes"

	// Create and start server
	server, err := web.NewServer(&cfg.Web, globalDataDir)
	if err != nil {
		return fmt.Errorf("failed to create server: %w", err)
	}

	// Handle graceful shutdown
	stop := make(chan os.Signal, 1)
	signal.Notify(stop, os.Interrupt, syscall.SIGTERM)

	errChan := make(chan error, 1)
	go func() {
		errChan <- server.Start()
	}()

	fmt.Printf("\n✅ Server started on http://%s:%d\n", cfg.Web.Host, cfg.Web.Port)
	fmt.Println("Press Ctrl+C to stop")

	// Wait for signal or error
	select {
	case err := <-errChan:
		if err != nil {
			return fmt.Errorf("server error: %w", err)
		}
	case <-stop:
		fmt.Println("\nShutting down...")
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := server.Stop(ctx); err != nil {
			return fmt.Errorf("shutdown error: %w", err)
		}
	}

	return nil
}
