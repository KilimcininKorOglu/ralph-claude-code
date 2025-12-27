package handlers

import (
	"encoding/json"
	"net/http"

	"hermes/internal/config"
	"hermes/internal/project"
	"hermes/internal/task"
)

// APIHandlers contains all API handlers
type APIHandlers struct {
	projectManager *project.Manager
}

// NewAPIHandlers creates new API handlers
func NewAPIHandlers(pm *project.Manager) *APIHandlers {
	return &APIHandlers{
		projectManager: pm,
	}
}

// ============ Project Handlers ============

// ListProjects handles GET /api/projects
func (h *APIHandlers) ListProjects(w http.ResponseWriter, r *http.Request) {
	projects := h.projectManager.List()
	respondJSON(w, http.StatusOK, projects)
}

// AddProject handles POST /api/projects
func (h *APIHandlers) AddProject(w http.ResponseWriter, r *http.Request) {
	var req struct {
		Name string `json:"name"`
		Path string `json:"path"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	proj, err := h.projectManager.Add(req.Name, req.Path)
	if err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	respondJSON(w, http.StatusCreated, proj)
}

// RemoveProject handles DELETE /api/projects/{id}
func (h *APIHandlers) RemoveProject(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if err := h.projectManager.Remove(id); err != nil {
		respondError(w, http.StatusNotFound, err.Error())
		return
	}
	respondJSON(w, http.StatusOK, map[string]bool{"success": true})
}

// SetActiveProject handles PUT /api/projects/{id}/active
func (h *APIHandlers) SetActiveProject(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	if err := h.projectManager.SetActive(id); err != nil {
		respondError(w, http.StatusNotFound, err.Error())
		return
	}
	respondJSON(w, http.StatusOK, map[string]bool{"success": true})
}

// ============ Dashboard Handler ============

// Dashboard handles GET /api/dashboard
func (h *APIHandlers) Dashboard(w http.ResponseWriter, r *http.Request) {
	activeProject, err := h.projectManager.GetActive()
	if err != nil {
		respondJSON(w, http.StatusOK, map[string]interface{}{
			"hasProject": false,
			"message":    "No active project",
		})
		return
	}

	// Load tasks from active project
	reader := task.NewReader(activeProject.Path)
	features, _ := reader.GetAllFeatures()

	stats := project.Stats{}
	for _, f := range features {
		stats.TotalFeatures++
		for _, t := range f.Tasks {
			stats.TotalTasks++
			switch t.Status {
			case task.StatusCompleted:
				stats.Completed++
			case task.StatusInProgress:
				stats.InProgress++
			case task.StatusBlocked:
				stats.Blocked++
			default:
				stats.NotStarted++
			}
		}
	}

	respondJSON(w, http.StatusOK, map[string]interface{}{
		"hasProject":    true,
		"project":       activeProject,
		"stats":         stats,
		"totalFeatures": len(features),
	})
}

// ============ Task Handlers ============

// ListTasks handles GET /api/tasks
func (h *APIHandlers) ListTasks(w http.ResponseWriter, r *http.Request) {
	activeProject, err := h.projectManager.GetActive()
	if err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	reader := task.NewReader(activeProject.Path)
	tasks, err := reader.GetAllTasks()
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	respondJSON(w, http.StatusOK, tasks)
}

// GetTask handles GET /api/tasks/{id}
func (h *APIHandlers) GetTask(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	
	activeProject, err := h.projectManager.GetActive()
	if err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	reader := task.NewReader(activeProject.Path)
	t, err := reader.GetTaskByID(id)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}
	if t == nil {
		respondError(w, http.StatusNotFound, "Task not found")
		return
	}

	respondJSON(w, http.StatusOK, t)
}

// UpdateTaskStatus handles PUT /api/tasks/{id}/status
func (h *APIHandlers) UpdateTaskStatus(w http.ResponseWriter, r *http.Request) {
	// TODO: Implement task status update via task.Writer
	respondError(w, http.StatusNotImplemented, "Task status update not yet implemented")
}

// ============ Feature Handlers ============

// ListFeatures handles GET /api/features
func (h *APIHandlers) ListFeatures(w http.ResponseWriter, r *http.Request) {
	activeProject, err := h.projectManager.GetActive()
	if err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	reader := task.NewReader(activeProject.Path)
	features, err := reader.GetAllFeatures()
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	respondJSON(w, http.StatusOK, features)
}

// GetFeature handles GET /api/features/{id}
func (h *APIHandlers) GetFeature(w http.ResponseWriter, r *http.Request) {
	id := r.PathValue("id")
	
	activeProject, err := h.projectManager.GetActive()
	if err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	reader := task.NewReader(activeProject.Path)
	f, err := reader.GetFeatureByID(id)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}
	if f == nil {
		respondError(w, http.StatusNotFound, "Feature not found")
		return
	}

	respondJSON(w, http.StatusOK, f)
}

// ============ Config Handlers ============

// GetConfig handles GET /api/config
func (h *APIHandlers) GetConfig(w http.ResponseWriter, r *http.Request) {
	activeProject, err := h.projectManager.GetActive()
	if err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	cfg, err := config.Load(activeProject.Path)
	if err != nil {
		cfg = config.DefaultConfig()
	}

	respondJSON(w, http.StatusOK, cfg)
}

// UpdateConfig handles PUT /api/config
func (h *APIHandlers) UpdateConfig(w http.ResponseWriter, r *http.Request) {
	activeProject, err := h.projectManager.GetActive()
	if err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	var cfg config.Config
	if err := json.NewDecoder(r.Body).Decode(&cfg); err != nil {
		respondError(w, http.StatusBadRequest, "Invalid config")
		return
	}

	if err := config.Save(activeProject.Path, &cfg); err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	respondJSON(w, http.StatusOK, map[string]bool{"success": true})
}

// ============ Helpers ============

func respondJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

func respondError(w http.ResponseWriter, status int, message string) {
	respondJSON(w, status, map[string]string{"error": message})
}

