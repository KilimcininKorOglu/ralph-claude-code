package project

import (
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"sync"
	"time"

	"hermes/internal/auth"
)

var (
	ErrProjectNotFound = errors.New("project not found")
	ErrProjectExists   = errors.New("project already exists")
	ErrNoActiveProject = errors.New("no active project")
)

// Manager manages multiple Hermes projects
type Manager struct {
	registry    *ProjectRegistry
	dataFile    string
	mu          sync.RWMutex
}

// NewManager creates a new project manager
func NewManager(dataFile string) (*Manager, error) {
	manager := &Manager{
		registry: &ProjectRegistry{Projects: []Project{}},
		dataFile: dataFile,
	}

	// Create directory if not exists
	dir := filepath.Dir(dataFile)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, err
	}

	// Load existing data
	if _, err := os.Stat(dataFile); err == nil {
		if err := manager.load(); err != nil {
			return nil, err
		}
	}

	return manager, nil
}

// load reads registry from file
func (m *Manager) load() error {
	data, err := os.ReadFile(m.dataFile)
	if err != nil {
		return err
	}
	return json.Unmarshal(data, m.registry)
}

// save writes registry to file
func (m *Manager) save() error {
	data, err := json.MarshalIndent(m.registry, "", "  ")
	if err != nil {
		return err
	}
	return os.WriteFile(m.dataFile, data, 0644)
}

// Add registers a new project
func (m *Manager) Add(name, path string) (*Project, error) {
	m.mu.Lock()
	defer m.mu.Unlock()

	// Normalize path
	absPath, err := filepath.Abs(path)
	if err != nil {
		return nil, err
	}

	// Check if exists
	for _, p := range m.registry.Projects {
		if p.Path == absPath {
			return nil, ErrProjectExists
		}
	}

	// Verify it's a valid Hermes project
	hermesDir := filepath.Join(absPath, ".hermes")
	if _, err := os.Stat(hermesDir); os.IsNotExist(err) {
		return nil, errors.New("not a valid Hermes project (missing .hermes directory)")
	}

	project := Project{
		ID:        auth.GenerateID(),
		Name:      name,
		Path:      absPath,
		Active:    len(m.registry.Projects) == 0, // First project is active
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	m.registry.Projects = append(m.registry.Projects, project)

	if err := m.save(); err != nil {
		return nil, err
	}

	return &project, nil
}

// Remove unregisters a project
func (m *Manager) Remove(id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	for i, p := range m.registry.Projects {
		if p.ID == id {
			m.registry.Projects = append(m.registry.Projects[:i], m.registry.Projects[i+1:]...)
			return m.save()
		}
	}

	return ErrProjectNotFound
}

// SetActive sets the active project
func (m *Manager) SetActive(id string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	found := false
	for i := range m.registry.Projects {
		if m.registry.Projects[i].ID == id {
			m.registry.Projects[i].Active = true
			m.registry.Projects[i].UpdatedAt = time.Now()
			found = true
		} else {
			m.registry.Projects[i].Active = false
		}
	}

	if !found {
		return ErrProjectNotFound
	}

	return m.save()
}

// GetActive returns the currently active project
func (m *Manager) GetActive() (*Project, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	for i := range m.registry.Projects {
		if m.registry.Projects[i].Active {
			return &m.registry.Projects[i], nil
		}
	}

	return nil, ErrNoActiveProject
}

// Get returns a project by ID
func (m *Manager) Get(id string) (*Project, error) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	for i := range m.registry.Projects {
		if m.registry.Projects[i].ID == id {
			return &m.registry.Projects[i], nil
		}
	}

	return nil, ErrProjectNotFound
}

// List returns all registered projects
func (m *Manager) List() []Project {
	m.mu.RLock()
	defer m.mu.RUnlock()

	projects := make([]Project, len(m.registry.Projects))
	copy(projects, m.registry.Projects)
	return projects
}

// GetActivePath returns the path of the active project
func (m *Manager) GetActivePath() (string, error) {
	project, err := m.GetActive()
	if err != nil {
		return "", err
	}
	return project.Path, nil
}
