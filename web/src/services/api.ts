const API_BASE = '/api';

export interface User {
    id: string;
    username: string;
    role: string;
}

export interface AuthResponse {
    success: boolean;
    message?: string;
    token?: string;
    user?: User;
}

export interface Project {
    id: string;
    name: string;
    path: string;
    active: boolean;
    createdAt: string;
    updatedAt: string;
}

export interface Stats {
    totalTasks: number;
    completed: number;
    inProgress: number;
    notStarted: number;
    blocked: number;
    totalFeatures: number;
}

export interface DashboardData {
    hasProject: boolean;
    message?: string;
    project?: Project;
    stats?: Stats;
    totalFeatures?: number;
}

export interface Task {
    id: string;
    title: string;
    status: string;
    priority: number;
    featureId: string;
    description?: string;
    successCriteria?: string[];
}

export interface Feature {
    id: string;
    featureId: string;
    title: string;
    tasks: Task[];
}

export interface ExecutionState {
    running: boolean;
    taskId?: string;
    taskName?: string;
    loop: number;
    maxLoops: number;
    progress: number;
    startedAt?: string;
    output?: string;
}

// Get stored token
function getToken(): string | null {
    return localStorage.getItem('hermes_token');
}

// Set stored token
export function setToken(token: string): void {
    localStorage.setItem('hermes_token', token);
}

// Clear stored token
export function clearToken(): void {
    localStorage.removeItem('hermes_token');
}

// Fetch wrapper with auth
async function fetchAPI<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
    const token = getToken();
    const headers: HeadersInit = {
        'Content-Type': 'application/json',
        ...(token ? { Authorization: `Bearer ${token}` } : {}),
        ...options.headers,
    };

    const response = await fetch(`${API_BASE}${endpoint}`, {
        ...options,
        headers,
    });

    if (!response.ok) {
        const error = await response.json().catch(() => ({ error: 'Unknown error' }));
        throw new Error(error.error || `HTTP ${response.status}`);
    }

    return response.json();
}

// Auth API
export const authAPI = {
    needsSetup: () => fetchAPI<{ needsSetup: boolean }>('/auth/setup'),
    login: (username: string, password: string) =>
        fetchAPI<AuthResponse>('/auth/login', {
            method: 'POST',
            body: JSON.stringify({ username, password }),
        }),
    register: (username: string, password: string) =>
        fetchAPI<AuthResponse>('/auth/register', {
            method: 'POST',
            body: JSON.stringify({ username, password }),
        }),
    logout: () => fetchAPI<AuthResponse>('/auth/logout', { method: 'POST' }),
    me: () => fetchAPI<AuthResponse>('/auth/me'),
};

// Dashboard API
export const dashboardAPI = {
    get: () => fetchAPI<DashboardData>('/dashboard'),
};

// Projects API
export const projectsAPI = {
    list: () => fetchAPI<Project[]>('/projects'),
    add: (name: string, path: string) =>
        fetchAPI<Project>('/projects', {
            method: 'POST',
            body: JSON.stringify({ name, path }),
        }),
    remove: (id: string) =>
        fetchAPI<{ success: boolean }>(`/projects/${id}`, { method: 'DELETE' }),
    setActive: (id: string) =>
        fetchAPI<{ success: boolean }>(`/projects/${id}/active`, { method: 'PUT' }),
};

// Tasks API
export const tasksAPI = {
    list: () => fetchAPI<Task[]>('/tasks'),
    get: (id: string) => fetchAPI<Task>(`/tasks/${id}`),
};

// Features API
export const featuresAPI = {
    list: () => fetchAPI<Feature[]>('/features'),
    get: (id: string) => fetchAPI<Feature>(`/features/${id}`),
};

// Execution API
export const executionAPI = {
    status: () => fetchAPI<ExecutionState>('/execution/status'),
    start: (taskId: string) =>
        fetchAPI<{ success: boolean }>('/execution/start', {
            method: 'POST',
            body: JSON.stringify({ taskId }),
        }),
    stop: () =>
        fetchAPI<{ success: boolean }>('/execution/stop', { method: 'POST' }),
};
