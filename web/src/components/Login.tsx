import { useState } from 'react';
import { authAPI, setToken, type AuthResponse } from '../services/api';

interface LoginProps {
    onLogin: (user: AuthResponse['user']) => void;
    needsSetup: boolean;
}

export function Login({ onLogin, needsSetup }: LoginProps) {
    const [mode, setMode] = useState<'login' | 'register'>(needsSetup ? 'register' : 'login');
    const [username, setUsername] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState<string | null>(null);
    const [loading, setLoading] = useState(false);

    async function handleSubmit(e: React.FormEvent) {
        e.preventDefault();
        setError(null);
        setLoading(true);

        try {
            const response = mode === 'login'
                ? await authAPI.login(username, password)
                : await authAPI.register(username, password);

            if (response.success && response.token) {
                setToken(response.token);
                onLogin(response.user);
            } else {
                setError(response.message || 'Authentication failed');
            }
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Authentication failed');
        } finally {
            setLoading(false);
        }
    }

    return (
        <div className="login-container">
            <div className="login-card">
                <h1>Hermes</h1>
                <p className="subtitle">AI-Powered Application Development</p>

                {needsSetup && (
                    <div className="setup-notice">
                        <p>Welcome! Create your admin account to get started.</p>
                    </div>
                )}

                <form onSubmit={handleSubmit}>
                    <div className="form-group">
                        <label htmlFor="username">Username</label>
                        <input
                            type="text"
                            id="username"
                            value={username}
                            onChange={(e) => setUsername(e.target.value)}
                            required
                            minLength={3}
                            autoComplete="username"
                        />
                    </div>

                    <div className="form-group">
                        <label htmlFor="password">Password</label>
                        <input
                            type="password"
                            id="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            required
                            minLength={6}
                            autoComplete={mode === 'login' ? 'current-password' : 'new-password'}
                        />
                    </div>

                    {error && <div className="error-message">{error}</div>}

                    <button type="submit" disabled={loading}>
                        {loading ? 'Please wait...' : mode === 'login' ? 'Login' : 'Create Account'}
                    </button>
                </form>

                {!needsSetup && (
                    <p className="toggle-mode">
                        {mode === 'login' ? (
                            <>
                                Don't have an account?{' '}
                                <button type="button" onClick={() => setMode('register')}>
                                    Register
                                </button>
                            </>
                        ) : (
                            <>
                                Already have an account?{' '}
                                <button type="button" onClick={() => setMode('login')}>
                                    Login
                                </button>
                            </>
                        )}
                    </p>
                )}
            </div>
        </div>
    );
}

export default Login;
