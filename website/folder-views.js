/* A URL state belongs to a folder; Markdown stays the canonical source. */
(() => {
  function initialize() {
    const root = document.querySelector('[data-folder-views]');
    if (!root || root.dataset.initialized) return;
    root.dataset.initialized = 'true';
    const buttons = root.querySelectorAll('[data-folder-view]');
    const panels = root.querySelectorAll('[data-folder-panel]');
    function render() {
      const mode = new URL(location.href).searchParams.get('view') === 'markdown'
        ? 'markdown' : 'rendered';
      buttons.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.folderView === mode)));
      panels.forEach(panel => { panel.hidden = panel.dataset.folderPanel !== mode; });
    }
    buttons.forEach(button => button.addEventListener('click', () => {
      const url = new URL(location.href);
      if (button.dataset.folderView === 'markdown') url.searchParams.set('view', 'markdown');
      else url.searchParams.delete('view');
      history.pushState(null, '', url);
      render();
    }));
    window.addEventListener('popstate', render);
    const source = () => root.querySelector('.folder-source code').textContent;
    root.querySelector('[data-copy-readme]').addEventListener('click', async () => {
      const status = root.querySelector('[data-copy-status]');
      try {
        await navigator.clipboard.writeText(source());
        status.textContent = 'Copied';
      } catch {
        status.textContent = 'Copy unavailable. Select the Markdown below to copy it.';
      }
    });
    root.querySelector('[data-download-readme]').addEventListener('click', () => {
      const url = URL.createObjectURL(new Blob([source()], { type: 'text/markdown;charset=utf-8' }));
      const link = document.createElement('a');
      link.href = url;
      link.download = 'README.md';
      link.click();
      setTimeout(() => URL.revokeObjectURL(url), 1000);
    });
    render();
  }
  if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', initialize);
  else initialize();
})();
