import { useState, useEffect } from 'react';
import { authAPI, type User } from './services/api';
import { Login } from './components/Login';
import { Layout } from './components/Layout';
import { Dashboard } from './components/Dashboard';
import { TaskList } from './components/TaskList';
import './App.css';

function App() {
  const [user, setUser] = useState<User | null>(null);
  const [needsSetup, setNeedsSetup] = useState(false);
  const [loading, setLoading] = useState(true);
  const [currentPage, setCurrentPage] = useState('dashboard');

  useEffect(() => {
    checkAuth();
  }, []);

  async function checkAuth() {
    try {
      // Check if setup is needed
      const setupResult = await authAPI.needsSetup();
      setNeedsSetup(setupResult.needsSetup);

      if (!setupResult.needsSetup) {
        // Try to get current user
        try {
          const meResult = await authAPI.me();
          if (meResult.success && meResult.user) {
            setUser(meResult.user);
          }
        } catch {
          // Not logged in
        }
      }
    } catch (err) {
      console.error('Auth check failed:', err);
    } finally {
      setLoading(false);
    }
  }

  function handleLogin(loggedInUser: User | undefined) {
    if (loggedInUser) {
      setUser(loggedInUser);
      setNeedsSetup(false);
    }
  }

  function handleLogout() {
    setUser(null);
    setCurrentPage('dashboard');
  }

  if (loading) {
    return (
      <div className="loading-screen">
        <h1>HERMES</h1>
        <p>Loading...</p>
      </div>
    );
  }

  if (!user) {
    return <Login onLogin={handleLogin} needsSetup={needsSetup} />;
  }

  return (
    <Layout
      user={user}
      currentPage={currentPage}
      onNavigate={setCurrentPage}
      onLogout={handleLogout}
    >
      {currentPage === 'dashboard' && <Dashboard />}
      {currentPage === 'tasks' && <TaskList />}
      {currentPage === 'features' && <TaskList />}
      {currentPage === 'execution' && <div className="page">Execution view coming soon...</div>}
      {currentPage === 'config' && <div className="page">Settings coming soon...</div>}
    </Layout>
  );
}

export default App;
