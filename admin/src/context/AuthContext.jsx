import React, { createContext, useContext, useState, useEffect } from 'react';
import { adminApi, getAdminUser, getAuthToken, onUnauthorized } from '../api/adminApi';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [token, setToken] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const savedToken = getAuthToken();
    const savedUser = getAdminUser();
    if (savedToken && savedUser && savedUser.peran === 'Administrator') {
      setToken(savedToken);
      setUser(savedUser);
    } else {
      adminApi.logout();
    }
    setLoading(false);

    return onUnauthorized(() => {
      setUser(null);
      setToken(null);
    });
  }, []);

  const login = async (email, password) => {
    const data = await adminApi.login(email, password);
    setUser(data.user);
    setToken(data.token);
    return data;
  };

  const logout = () => {
    adminApi.logout();
    setUser(null);
    setToken(null);
  };

  return (
    <AuthContext.Provider value={{ user, token, loading, login, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}
