import { useState, useEffect } from 'react';
import { tasksAPI, featuresAPI, type Task, type Feature } from '../services/api';

export function TaskList() {
    const [features, setFeatures] = useState<Feature[]>([]);
    const [tasks, setTasks] = useState<Task[]>([]);
    const [view, setView] = useState<'list' | 'board'>('list');
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState<string | null>(null);

    useEffect(() => {
        loadData();
    }, []);

    async function loadData() {
        try {
            setLoading(true);
            const [featuresData, tasksData] = await Promise.all([
                featuresAPI.list(),
                tasksAPI.list(),
            ]);
            setFeatures(featuresData);
            setTasks(tasksData);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to load tasks');
        } finally {
            setLoading(false);
        }
    }

    if (loading) return <div className="loading">Loading tasks...</div>;
    if (error) return <div className="error">{error}</div>;

    return (
        <div className="task-list">
            <header className="task-header">
                <h1>Tasks</h1>
                <div className="view-toggle">
                    <button
                        className={view === 'list' ? 'active' : ''}
                        onClick={() => setView('list')}
                    >
                        List
                    </button>
                    <button
                        className={view === 'board' ? 'active' : ''}
                        onClick={() => setView('board')}
                    >
                        Board
                    </button>
                </div>
            </header>

            {view === 'list' ? (
                <TaskListView features={features} tasks={tasks} />
            ) : (
                <TaskBoardView tasks={tasks} />
            )}
        </div>
    );
}

function TaskListView({ features, tasks }: { features: Feature[]; tasks: Task[] }) {
    return (
        <div className="task-list-view">
            {features.map((feature) => (
                <div key={feature.id} className="feature-group">
                    <h2 className="feature-title">{feature.title}</h2>
                    <div className="feature-tasks">
                        {tasks
                            .filter((t) => t.featureId === feature.featureId)
                            .map((task) => (
                                <TaskCard key={task.id} task={task} />
                            ))}
                    </div>
                </div>
            ))}
        </div>
    );
}

function TaskBoardView({ tasks }: { tasks: Task[] }) {
    const columns = [
        { status: 'not_started', title: 'Not Started' },
        { status: 'in_progress', title: 'In Progress' },
        { status: 'completed', title: 'Completed' },
        { status: 'blocked', title: 'Blocked' },
    ];

    return (
        <div className="task-board">
            {columns.map((col) => (
                <div key={col.status} className={`board-column column-${col.status}`}>
                    <h3>{col.title}</h3>
                    <div className="column-tasks">
                        {tasks
                            .filter((t) => t.status === col.status)
                            .map((task) => (
                                <TaskCard key={task.id} task={task} />
                            ))}
                    </div>
                </div>
            ))}
        </div>
    );
}

function TaskCard({ task }: { task: Task }) {
    const statusIcon = {
        not_started: '○',
        in_progress: '🔄',
        completed: '✓',
        blocked: '⚠️',
    }[task.status] || '○';

    const priorityClass = `priority-${task.priority}`;

    return (
        <div className={`task-card ${priorityClass}`}>
            <div className="task-status">{statusIcon}</div>
            <div className="task-content">
                <span className="task-id">{task.id}</span>
                <span className="task-title">{task.title}</span>
            </div>
            <div className="task-priority">P{task.priority}</div>
        </div>
    );
}

export default TaskList;
