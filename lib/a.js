/* ==============================================================
   utils.js – Funções utilitárias
   ============================================================== */

function showToast(msg, type = 'success', duration = 3000) {
  const toast = document.getElementById('toast');
  if (!toast) return;

  toast.textContent = msg;
  toast.className = 'toast';

  const colors = { success: '#27AE60', danger: '#E74C3C', warning: '#F39C12', info: '#3498DB' };
  toast.style.background = colors[type] || colors.success;

  requestAnimationFrame(() => toast.classList.add('show'));

  if (toast._timeout) clearTimeout(toast._timeout);
  toast._timeout = setTimeout(() => toast.classList.remove('show'), duration);
}

function debounce(func, wait) {
  let timeout;
  return function (...args) {
    clearTimeout(timeout);
    timeout = setTimeout(() => func.apply(this, args), wait);
  };
}

function showLoading(id, msg = 'Carregando...') {
  const el = document.getElementById(id);
  if (el) {
    el.innerHTML = `
      <div style="text-align:center;padding:60px;color:var(--text-light);">
        <div style="width:40px;height:40px;border:4px solid #f0f0f0;border-top:4px solid var(--primary);border-radius:50%;animation:spin 1s linear infinite;margin:0 auto 16px;"></div>
        <div>${msg}</div>
      </div>`;
  }
}

console.log('utils.js carregado');