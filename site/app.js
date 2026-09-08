const dialog = document.querySelector('#install-dialog');
for (const button of document.querySelectorAll('[data-install]')) {
  button.addEventListener('click', () => dialog.showModal());
}
for (const link of document.querySelectorAll('[data-download]')) {
  link.addEventListener('click', event => {
    if (!event.metaKey && !event.ctrlKey && !event.shiftKey && !event.altKey) {
      // Keep the direct GitHub attachment download working without JavaScript.
      setTimeout(() => { if (!dialog.open) dialog.showModal(); }, 150);
    }
  });
}
document.querySelector('.dialog-close').addEventListener('click', () => dialog.close());
dialog.addEventListener('click', event => {
  const rect = dialog.getBoundingClientRect();
  if (event.target === dialog && (event.clientX < rect.left || event.clientX > rect.right || event.clientY < rect.top || event.clientY > rect.bottom)) dialog.close();
});
const preview = document.querySelector('.widget-preview');
preview.addEventListener('click', () => {
  const collapsed = preview.classList.toggle('is-collapsed');
  preview.setAttribute('aria-expanded', String(!collapsed));
  preview.setAttribute('aria-label', collapsed ? 'Expand the Vista preview' : 'Try collapsing the Vista preview');
  document.querySelector('.preview-hint').textContent = collapsed ? 'Quietly here. Click to open.' : 'Click to try the tiny version';
});
