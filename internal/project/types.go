package project

import "time"

// Project represents a Hermes project
type Project struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Path      string    `json:"path"`
	Active    bool      `json:"active"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// ProjectRegistry holds all registered projects
type ProjectRegistry struct {
	Projects []Project `json:"projects"`
}

// Stats represents project statistics
type Stats struct {
	TotalTasks   int `json:"totalTasks"`
	Completed    int `json:"completed"`
	InProgress   int `json:"inProgress"`
	NotStarted   int `json:"notStarted"`
	Blocked      int `json:"blocked"`
	TotalFeatures int `json:"totalFeatures"`
}
