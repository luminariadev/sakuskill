import React from 'react';
import { Modal } from './Modal';
import { ExternalLink, Link2 } from 'lucide-react';

export function EvidenceModal({ isOpen, onClose, title, urls = [], description = '' }) {
  if (!isOpen) return null;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={title || 'Detail Lampiran & Tautan Bukti'}
      maxWidth="max-w-xl"
    >
      <div className="space-y-4">
        {description && (
          <div className="clay-tile p-4 text-xs text-[#0F172A] leading-relaxed">
            <p className="text-[11px] font-bold uppercase tracking-wider text-[#64748B] mb-1">
              Keterangan Tercatat
            </p>
            <p className="whitespace-pre-wrap">{description}</p>
          </div>
        )}

        <div className="space-y-2">
          <p className="text-[11px] font-bold uppercase tracking-wider text-[#64748B]">
            Tautan Bukti Pendukung ({urls.length})
          </p>
          {urls.length === 0 ? (
            <div className="clay-tile p-5 text-center text-xs text-[#64748B]">
              Tidak ada tautan URL bukti eksternal yang dilampirkan pada laporan ini.
            </div>
          ) : (
            urls.map((url) => (
              <a
                key={url}
                href={url}
                target="_blank"
                rel="noopener noreferrer"
                className="clay-tile p-3.5 flex items-center justify-between gap-3 hover:border-[#059669] transition group"
              >
                <div className="flex items-center gap-2.5 min-w-0">
                  <div className="w-8 h-8 rounded-xl bg-[#ECFDF5] text-[#059669] flex items-center justify-center shrink-0">
                    <Link2 className="w-4 h-4" />
                  </div>
                  <span className="text-xs font-mono text-[#0F172A] truncate group-hover:text-[#059669]">
                    {url}
                  </span>
                </div>
                <ExternalLink className="w-4 h-4 text-[#64748B] group-hover:text-[#059669] shrink-0" />
              </a>
            ))
          )}
        </div>

        <div className="flex justify-end pt-2 border-t border-[#E6EFEA]">
          <button
            type="button"
            onClick={onClose}
            className="px-5 py-2 rounded-2xl text-xs font-bold text-[#0F172A] bg-[#F0F4F2] hover:bg-[#E2EBE6] transition"
          >
            Tutup
          </button>
        </div>
      </div>
    </Modal>
  );
}
