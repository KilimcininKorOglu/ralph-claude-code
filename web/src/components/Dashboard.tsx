import { useState, useEffect } from 'react';
import { dashboardAPI, type DashboardData, type Stats } from '../services/api';

interface DashboardProps {
    onNoProject?: () => void;
}

export function Dashboard({ onNoProject }: DashboardProps) {
    const [data, setData] = useState<DashboardData | null>(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        loadDashboard();
    }, []);

    async function loadDashboard() {
        try {
            setLoading(true);
            const result = await dashboardAPI.get();
            setData(result);
            if (!result.hasProject && onNoProject) {
                onNoProject();
            }
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to load dashboard');
        } finally {
            setLoading(false);
        }
    }

    if (loading) {
        return <div className="loading">Loading dashboard...</div>;
    }

    if (error) {
        return <div className="error">{error}</div>;
    }

    if (!data?.hasProject) {
        return (
            <div className="no-project">
                <h2>No Active Project</h2>
                <p>Please add a project to get started.</p>
            </div>
        );
    }

    const stats = data.stats as Stats;

    return (
        <div className="dashboard">
            <header className="dashboard-header">
                <h1>Dashboard</h1>
                <p className="project-name">{data.project?.name}</p>
            </header>

            <div className="stats-grid">
                <StatCard title="Total Tasks" value={stats.totalTasks} color="blue" />
                <StatCard title="Completed" value={stats.completed} color="green" />
                <StatCard title="In Progress" value={stats.inProgress} color="yellow" />
                <StatCard title="Blocked" value={stats.blocked} color="red" />
            </div>

            <div className="progress-section">
                <h2>Progress</h2>
                <div className="progress-bar">
                    <div
                        className="progress-fill"
                        style={{ width: `${stats.totalTasks > 0 ? (stats.completed / stats.totalTasks) * 100 : 0}%` }}
                    />
                </div>
                <p className="progress-text">
                    {stats.completed} / {stats.totalTasks} tasks completed
                    ({stats.totalTasks > 0 ? Math.round((stats.completed / stats.totalTasks) * 100) : 0}%)
                </p>
            </div>

            <div className="info-section">
                <h2>Features</h2>
                <p>{data.totalFeatures} features in project</p>
            </div>
        </div>
    );
}

interface StatCardProps {
    title: string;
    value: number;
    color: 'blue' | 'green' | 'yellow' | 'red';
}

function StatCard({ title, value, color }: StatCardProps) {
    return (
        <div className={`stat-card stat-${color}`}>
            <span className="stat-value">{value}</span>
            <span className="stat-title">{title}</span>
        </div>
    );
}

export default Dashboard;
