import React from 'react';
import { Modal } from './Modal';
import { FileText, Download, ExternalLink, Image as ImageIcon } from 'lucide-react';

export function EvidenceModal({ isOpen, onClose, title, fileName, fileType = 'image' }) {
  if (!isOpen) return null;

  const isPdf = fileName?.endsWith('.pdf');

  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title || `Bukti Lampiran: ${fileName}`} maxWidth="max-w-2xl">
      <div className="space-y-4">
        <div className="p-3 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-between text-xs">
          <div className="flex items-center gap-2">
            {isPdf ? (
              <FileText className="w-4 h-4 text-rose-400" />
            ) : (
              <ImageIcon className="w-4 h-4 text-emerald-400" />
            )}
            <span className="font-mono text-slate-200">{fileName}</span>
          </div>
          <span className="text-[11px] text-slate-400">Terverifikasi diunggah via sistem</span>
        </div>

        {/* Visual Preview Box */}
        <div className="rounded-xl overflow-hidden border border-slate-700 bg-slate-950 p-6 flex flex-col items-center justify-center min-h-[300px]">
          {isPdf ? (
            <div className="text-center space-y-3">
              <div className="w-16 h-16 rounded-2xl bg-rose-950/60 border border-rose-600/50 flex items-center justify-center mx-auto text-rose-400">
                <FileText className="w-8 h-8" />
              </div>
              <div>
                <p className="font-bold text-white text-sm">Dokumen Draft Desain Spanduk (80%)</p>
                <p className="text-xs text-slate-400 mt-1">Ukuran: 4.8 MB • Format: PDF Vector</p>
                <p className="text-[11px] text-emerald-400 mt-0.5">Memuat 2 variasi spanduk Dies Natalis UPI Cibiru</p>
              </div>
              <div className="p-3 bg-slate-900 rounded-lg border border-slate-800 text-[11px] text-slate-300 max-w-md text-left">
                <strong>Catatan Metadata:</strong> Berkas terakhir diunggah pada 15 Nov 2026 23:45 WIB sebelum batas deadline revisi.
              </div>
            </div>
          ) : (
            <div className="w-full max-w-md rounded-lg overflow-hidden border border-slate-800 bg-[#0d1424] p-4 text-xs font-sans space-y-3">
              <div className="flex items-center justify-between border-b border-slate-800 pb-2">
                <span className="font-bold text-emerald-400">WhatsApp Chat Log Screenshot</span>
                <span className="text-[10px] text-slate-400 font-mono">15 Nov 2026, 16:30</span>
              </div>
              <div className="space-y-2">
                <div className="bg-slate-800/80 p-2.5 rounded-lg rounded-tl-none max-w-[85%] text-slate-200">
                  <p className="text-[10px] text-slate-400 font-semibold mb-0.5">Pemesan:</p>
                  <p>"Kak, mohon maaf bisa tambahin 3 sponsor baru di pojok bawah sama ubah ukurannya jadi 4x1.5 meter ya?"</p>
                </div>
                <div className="bg-emerald-950/80 border border-emerald-800/40 p-2.5 rounded-lg rounded-tr-none max-w-[85%] ml-auto text-emerald-100">
                  <p className="text-[10px] text-emerald-400 font-semibold mb-0.5">Penyedia:</p>
                  <p>"Baik kak, tapi saya butuh perpanjangan waktu 1 hari ya karena layout sponsor harus ditata ulang dari nol."</p>
                </div>
                <div className="bg-slate-800/80 p-2.5 rounded-lg rounded-tl-none max-w-[85%] text-slate-200">
                  <p className="text-[10px] text-slate-400 font-semibold mb-0.5">Pemesan:</p>
                  <p>"Waduh ga bisa kak, acaranya lusa pagi harus udah cetak spanduknya..."</p>
                </div>
              </div>
            </div>
          )}
        </div>

        <div className="flex justify-end pt-2">
          <button
            onClick={onClose}
            className="px-5 py-2 rounded-xl text-xs font-semibold text-white bg-slate-800 hover:bg-slate-700 transition"
          >
            Tutup Pratinjau
          </button>
        </div>
      </div>
    </Modal>
  );
}
