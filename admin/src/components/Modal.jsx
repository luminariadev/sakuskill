import React, { useEffect } from 'react';
import { X } from 'lucide-react';

export function Modal({ isOpen, onClose, title, children, maxWidth = 'max-w-xl' }) {
  useEffect(() => {
    const handleEsc = (e) => {
      if (e.key === 'Escape') onClose();
    };
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      window.addEventListener('keydown', handleEsc);
    }
    return () => {
      document.body.style.overflow = 'unset';
      window.removeEventListener('keydown', handleEsc);
    };
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
      <div
        className="fixed inset-0 bg-[#0B1512]/45 backdrop-blur-md transition-opacity"
        onClick={onClose}
      ></div>

      <div
        className={`relative w-full ${maxWidth} clay-card overflow-hidden z-10 flex flex-col max-h-[90vh]`}
      >
        <div className="px-6 py-4 border-b border-[#E6EFEA] bg-white/90 backdrop-blur-md flex items-center justify-between shrink-0">
          <h3 className="text-base font-extrabold text-[#0F172A] tracking-tight">{title}</h3>
          <button
            onClick={onClose}
            aria-label="Tutup modal"
            className="w-8 h-8 rounded-xl bg-[#F0F4F2] hover:bg-[#E2EBE6] text-[#64748B] hover:text-[#0F172A] flex items-center justify-center transition"
          >
            <X className="w-4 h-4" />
          </button>
        </div>

        <div className="p-6 overflow-y-auto">{children}</div>
      </div>
    </div>
  );
}
