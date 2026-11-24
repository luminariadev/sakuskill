import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Lock, Mail, ArrowRight, Sparkles, AlertCircle, ShieldCheck } from 'lucide-react';

export function LoginPage() {
  const { login } = useAuth();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(email, password);
    } catch (err) {
      setError(err.message || 'Login gagal. Periksa kembali email dan kata sandi administrator.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col items-center justify-center p-6 relative overflow-hidden">
      <div className="w-full max-w-md glass-panel rounded-[30px] p-8 relative z-10">
        <div className="text-center mb-7">
          <div className="w-14 h-14 rounded-2xl bg-gradient-to-br from-[#10B981] to-[#047857] shadow-clay-emerald flex items-center justify-center mx-auto mb-4">
            <Sparkles className="w-7 h-7 text-white" />
          </div>
          <h1 className="text-2xl font-extrabold text-[#0F172A] tracking-tight">
            Portal Admin sakuskill.
          </h1>
          <p className="text-xs text-[#64748B] mt-1.5 leading-relaxed">
            Kendali operasional real-time, moderasi anti-joki, dan arbitrase kampus
          </p>
        </div>

        {error && (
          <div className="mb-5 p-3.5 rounded-2xl bg-[#FEF2F2] border border-[#FECACA] flex items-start gap-2.5 text-xs text-[#DC2626] font-medium">
            <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
            <span>{error}</span>
          </div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-[11px] font-bold text-[#475569] uppercase tracking-wider mb-1.5">
              Email Administrator
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#64748B]">
                <Mail className="w-4 h-4" />
              </div>
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="admin@sakuskill.ac.id"
                className="w-full pl-10 pr-4 py-3 rounded-2xl bg-white border border-[#DCE5E0] text-sm text-[#0F172A] placeholder-[#94A3B8] focus:outline-none focus:border-[#059669] shadow-clay-sm transition"
              />
            </div>
          </div>

          <div>
            <label className="block text-[11px] font-bold text-[#475569] uppercase tracking-wider mb-1.5">
              Kata Sandi
            </label>
            <div className="relative">
              <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none text-[#64748B]">
                <Lock className="w-4 h-4" />
              </div>
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Masukkan kata sandi"
                className="w-full pl-10 pr-4 py-3 rounded-2xl bg-white border border-[#DCE5E0] text-sm text-[#0F172A] placeholder-[#94A3B8] focus:outline-none focus:border-[#059669] shadow-clay-sm transition"
              />
            </div>
          </div>

          <div className="p-3 rounded-2xl bg-[#ECFDF5] border border-[#A7F3D0] flex items-center gap-2.5 text-xs text-[#047857] font-medium">
            <ShieldCheck className="w-4 h-4 text-[#059669] shrink-0" />
            <span>Hanya akun berizin Administrator yang dapat mengakses panel ini.</span>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="clay-btn-primary w-full py-3.5 px-4 text-sm flex items-center justify-center gap-2 mt-2"
          >
            {loading ? (
              <span className="inline-block w-4 h-4 border-2 border-white border-t-transparent rounded-full animate-spin"></span>
            ) : (
              <>
                <span>Masuk ke Portal Admin</span>
                <ArrowRight className="w-4 h-4" />
              </>
            )}
          </button>
        </form>

        <div className="mt-7 pt-4 border-t border-[#E6EFEA] text-center">
          <p className="text-[11px] font-semibold text-[#475569]">
            UIN Sunan Gunung Djati Bandung · Kampus Cibiru
          </p>
          <p className="text-[10.5px] text-[#64748B] mt-0.5">
            Tersambung langsung dengan API & Database Aplikasi Mobile
          </p>
        </div>
      </div>
    </div>
  );
}
