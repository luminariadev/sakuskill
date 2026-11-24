const API_BASE = import.meta.env.VITE_API_BASE_URL || '/api/v1';

const unauthorizedListeners = new Set();

export function onUnauthorized(listener) {
  unauthorizedListeners.add(listener);
  return () => unauthorizedListeners.delete(listener);
}

export function getAuthToken() {
  return localStorage.getItem('sakuskill_admin_token') || '';
}

export function setAuthToken(token) {
  if (token) {
    localStorage.setItem('sakuskill_admin_token', token);
  } else {
    localStorage.removeItem('sakuskill_admin_token');
  }
}

export function getAdminUser() {
  const raw = localStorage.getItem('sakuskill_admin_user');
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch (_) {
    return null;
  }
}

export function setAdminUser(user) {
  if (user) {
    localStorage.setItem('sakuskill_admin_user', JSON.stringify(user));
  } else {
    localStorage.removeItem('sakuskill_admin_user');
  }
}

async function request(endpoint, options = {}) {
  const token = getAuthToken();
  const headers = {
    'Content-Type': 'application/json',
    ...(token ? { Authorization: `Bearer ${token}` } : {}),
    ...options.headers,
  };

  const response = await fetch(`${API_BASE}${endpoint}`, {
    ...options,
    headers,
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok || data.success === false) {
    if (response.status === 401 && endpoint !== '/auth/login') {
      setAuthToken(null);
      setAdminUser(null);
      unauthorizedListeners.forEach((cb) => cb());
    }
    const errorMsg = data?.error?.message || data?.message || 'Permintaan gagal diproses';
    throw new Error(errorMsg);
  }

  return data;
}

export const adminApi = {
  async login(email, kata_sandi) {
    const res = await request('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email: email.trim(), kata_sandi }),
    });
    const user = res.data?.user;
    if (!user || user.peran !== 'Administrator') {
      setAuthToken(null);
      setAdminUser(null);
      throw new Error('Akses ditolak: akun ini tidak memiliki peran Administrator.');
    }
    if (res.data?.token) {
      setAuthToken(res.data.token);
      setAdminUser(user);
    }
    return res.data;
  },

  logout() {
    setAuthToken(null);
    setAdminUser(null);
  },

  async getDashboard() {
    const res = await request('/admin/dashboard');
    return res.data;
  },

  async getUsers() {
    const res = await request('/admin/users');
    return res.data;
  },

  async verifyUser(userId, status, notes) {
    const res = await request(`/admin/users/${userId}/verification`, {
      method: 'PATCH',
      body: JSON.stringify({ status, notes }),
    });
    return res.data;
  },

  async sanctionUser(userId, action, notes) {
    const res = await request(`/admin/users/${userId}/sanction`, {
      method: 'PATCH',
      body: JSON.stringify({ action, notes }),
    });
    return res.data;
  },

  async getListings() {
    const res = await request('/admin/listings');
    return res.data;
  },

  async moderateListing(listingId, action, notes) {
    const res = await request(`/admin/listings/${listingId}/moderation`, {
      method: 'PATCH',
      body: JSON.stringify({ action, notes }),
    });
    return res.data;
  },

  async getDisputes() {
    const res = await request('/admin/disputes');
    return res.data;
  },

  async resolveDispute(caseId, verdict, notes) {
    const res = await request(`/admin/disputes/${caseId}/verdict`, {
      method: 'POST',
      body: JSON.stringify({ verdict, notes }),
    });
    return res.data;
  },

  async getReports() {
    const res = await request('/admin/reports');
    return res.data;
  },

  async resolveReport(reportId, action, notes) {
    const res = await request(`/admin/reports/${reportId}/action`, {
      method: 'PATCH',
      body: JSON.stringify({ action, notes }),
    });
    return res.data;
  },

  async getEscrow() {
    const res = await request('/admin/escrow');
    return res.data;
  },
};
