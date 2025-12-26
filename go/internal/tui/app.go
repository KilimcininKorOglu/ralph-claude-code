package tui

import (
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
	"hermes/internal/circuit"
	"hermes/internal/config"
	"hermes/internal/task"
)

// tickMsg is sent on each tick for auto-refresh
type tickMsg time.Time

// Auto-refresh interval
const refreshInterval = 2 * time.Second

func tickCmd() tea.Cmd {
	return tea.Tick(refreshInterval, func(t time.Time) tea.Msg {
		return tickMsg(t)
	})
}

// Screen represents the current screen
type Screen int

const (
	ScreenDashboard Screen = iota
	ScreenTasks
	ScreenLogs
	ScreenHelp
)

// App is the main TUI model
type App struct {
	screen     Screen
	width      int
	height     int
	ready      bool
	basePath   string
	config     *config.Config
	taskReader *task.Reader
	breaker    *circuit.Breaker
	running    bool // Is run loop active?
	runStatus  string

	// Sub-models
	dashboard *DashboardModel
	tasks     *TasksModel
}

// NewApp creates a new TUI application
func NewApp(basePath string) (*App, error) {
	cfg, err := config.Load(basePath)
	if err != nil {
		cfg = config.DefaultConfig()
	}

	return &App{
		screen:     ScreenDashboard,
		basePath:   basePath,
		config:     cfg,
		taskReader: task.NewReader(basePath),
		breaker:    circuit.New(basePath),
		dashboard:  NewDashboardModel(basePath),
		tasks:      NewTasksModel(basePath),
	}, nil
}

// Init initializes the TUI
func (a App) Init() tea.Cmd {
	return tea.Batch(
		tea.EnterAltScreen,
		a.dashboard.Init(),
		tickCmd(), // Start auto-refresh
	)
}

// Update handles messages
func (a App) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tickMsg:
		// Auto-refresh data
		a.dashboard.Refresh()
		a.tasks.Refresh()
		return a, tickCmd() // Schedule next tick

	case tea.WindowSizeMsg:
		a.width = msg.Width
		a.height = msg.Height
		a.ready = true
		a.dashboard.SetSize(msg.Width, msg.Height-4)
		a.tasks.SetSize(msg.Width, msg.Height-4)

	case tea.KeyMsg:
		switch msg.String() {
		case "q", "ctrl+c":
			return a, tea.Quit
		case "1":
			a.screen = ScreenDashboard
		case "2":
			a.screen = ScreenTasks
		case "3":
			a.screen = ScreenLogs
		case "?":
			a.screen = ScreenHelp
		case "R":
			// Start run (capital R)
			if !a.running {
				a.running = true
				a.runStatus = "Starting..."
			}
		case "r":
			// Manual refresh
			a.dashboard.Refresh()
			a.tasks.Refresh()
		}
	}

	// Update active screen
	var cmd tea.Cmd
	switch a.screen {
	case ScreenDashboard:
		var model tea.Model
		model, cmd = a.dashboard.Update(msg)
		a.dashboard = model.(*DashboardModel)
	case ScreenTasks:
		var model tea.Model
		model, cmd = a.tasks.Update(msg)
		a.tasks = model.(*TasksModel)
	}

	return a, cmd
}

// View renders the TUI
func (a App) View() string {
	if !a.ready {
		return "Initializing..."
	}

	var content string
	switch a.screen {
	case ScreenDashboard:
		content = a.dashboard.View()
	case ScreenTasks:
		content = a.tasks.View()
	case ScreenLogs:
		content = a.logsView()
	case ScreenHelp:
		content = a.helpView()
	}

	return lipgloss.JoinVertical(
		lipgloss.Left,
		a.headerView(),
		content,
		a.footerView(),
	)
}

func (a App) headerView() string {
	style := lipgloss.NewStyle().
		Bold(true).
		Foreground(lipgloss.Color("86")).
		BorderStyle(lipgloss.NormalBorder()).
		BorderBottom(true).
		Width(a.width)

	title := "HERMES AUTONOMOUS AGENT"
	return style.Render(title)
}

func (a App) footerView() string {
	style := lipgloss.NewStyle().
		Foreground(lipgloss.Color("241")).
		Width(a.width)

	help := "[1]Dashboard [2]Tasks [3]Logs [?]Help [r]Refresh [R]Run [q]Quit"
	if a.running {
		help = "[RUNNING] " + a.runStatus + " | [q]Stop"
	}
	return style.Render(help)
}

func (a App) helpView() string {
	style := lipgloss.NewStyle().
		Padding(1, 2)

	help := `
HERMES TUI HELP

Navigation:
  1         Dashboard screen
  2         Tasks screen
  3         Logs screen
  ?         This help screen

Actions:
  R         Start task execution (Shift+R)
  r         Manual refresh
  j/k       Move up/down (in lists)
  q         Quit / Stop running

Dashboard:
  Shows progress, circuit breaker status, and current task
  Auto-refreshes every 2 seconds

Tasks:
  a/c/p/n/b  Filter: All/Completed/InProgress/NotStarted/Blocked

Press any key to return...
`
	return style.Render(help)
}

func (a App) logsView() string {
	style := lipgloss.NewStyle().
		Padding(1, 2)

	return style.Render("Logs viewer - Coming soon\n\nPress 1-4 to switch screens")
}
