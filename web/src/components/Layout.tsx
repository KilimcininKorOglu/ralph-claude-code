import type { ReactNode } from 'react';
import { clearToken, type User } from '../services/api';

interface LayoutProps {
    user: User | null;
    currentPage: string;
    onNavigate: (page: string) => void;
    onLogout: () => void;
    children: ReactNode;
}

export function Layout({ user, currentPage, onNavigate, onLogout, children }: LayoutProps) {
    const navItems = [
        { id: 'dashboard', label: 'Dashboard', icon: '📊' },
        { id: 'tasks', label: 'Tasks', icon: '📋' },
        { id: 'features', label: 'Features', icon: '🎯' },
        { id: 'execution', label: 'Execution', icon: '▶️' },
        { id: 'config', label: 'Settings', icon: '⚙️' },
    ];

    function handleLogout() {
        clearToken();
        onLogout();
    }

    return (
        <div className="layout">
            <aside className="sidebar">
                <div className="sidebar-header">
                    <h1>HERMES</h1>
                    <span className="version">v3.0</span>
                </div>

                <nav className="sidebar-nav">
                    {navItems.map((item) => (
                        <button
                            key={item.id}
                            className={`nav-item ${currentPage === item.id ? 'active' : ''}`}
                            onClick={() => onNavigate(item.id)}
                        >
                            <span className="nav-icon">{item.icon}</span>
                            <span className="nav-label">{item.label}</span>
                        </button>
                    ))}
                </nav>

                <div className="sidebar-footer">
                    {user && (
                        <div className="user-info">
                            <span className="user-name">{user.username}</span>
                            <span className="user-role">{user.role}</span>
                        </div>
                    )}
                    <button className="logout-btn" onClick={handleLogout}>
                        Logout
                    </button>
                </div>
            </aside>

            <main className="main-content">
                {children}
            </main>
        </div>
    );
}

export default Layout;
