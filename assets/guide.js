/* Folder READMEs are the only maintained explanations; source is never executed. */
(() => {
  const params = new URL(location.href).searchParams;
  const file = params.get('file');
  const $ = id => document.getElementById(id);
  const repo = 'https://github.com/afrank84/DevOps-AutomationToolingV2/blob/main/';
  const encoded = path => path.split('/').map(encodeURIComponent).join('/');
  let selectedView = 'guide';
  let sourcePromise;
  let walkthrough;
  async function text(path) {
    const response = await fetch(encoded(path));
    if (!response.ok) throw new Error(`Could not load ${path} (${response.status}).`);
    return response.text();
  }
  function explainSource(source) {
    // Show verifiable code structure when an authored folder guide is absent.
    // Never turn a filename into a claimed behavioral explanation.
    const article = document.createElement('article');
    const heading = document.createElement('h2');
    heading.textContent = 'Source walkthrough'; article.append(heading);
    const note = document.createElement('p');
    note.textContent = 'This outline comes from the file’s comments and declarations. It helps you inspect the implementation; it is not a tested usage guide.';
    article.append(note);
    const lines = source.split('\n');
    const groups = [
      ['Author’s notes and usage examples', /^\s*(?:#(?![!])|\/\/|\.SYNOPSIS|\.DESCRIPTION|\.EXAMPLE|\.PARAMETER|\* )/i],
      ['Dependencies and imported modules', /^\s*(?:import |from \S+ import |use [A-Z]|require\b|Import-Module\b|Add-Type\b|<script[^>]+src=)/i],
      ['Functions and entry points', /^\s*(?:(?:async )?def |class |(?:async )?function |sub |[\w-]+\s*\(\)\s*\{|[A-Za-z0-9-]+\.)/],
    ];
    for (const [title, pattern] of groups) {
      const matches = lines.map((line, index) => ({line, index})).filter(({line}) => pattern.test(line));
      if (!matches.length) continue;
      const h3 = document.createElement('h3'); h3.textContent = title; article.append(h3);
      const pre = document.createElement('pre');
      pre.textContent = matches.slice(0, 30).map(({line, index}) => `${index + 1}: ${line.trim()}`).join('\n');
      article.append(pre);
    }
    const settings = lines.map((line, index) => ({line,index})).filter(({line}) => /^\s*(?:\$[A-Za-z_]\w*|[A-Z][A-Z_0-9]*)\s*=/.test(line));
    if (settings.length) {
      const h3 = document.createElement('h3'); h3.textContent = 'Settings assigned in the file'; article.append(h3);
      const p = document.createElement('p');
      p.textContent = settings.slice(0, 30).map(({line,index}) => `${line.split('=')[0].trim()} (line ${index + 1})`).join(', ');
      article.append(p);
      const detail = document.createElement('p'); detail.textContent = 'Inspect these assignments in Source code. Assignments inside a script are not automatically overridden by environment variables or command-line arguments.';
      article.append(detail);
    }
    const button = document.createElement('button'); button.type = 'button'; button.textContent = 'Read full source code';
    button.addEventListener('click', () => document.querySelector('[data-view="source"]').click()); article.append(button);
    return article;
  }
  function renderState() {
    selectedView = new URL(location.href).searchParams.get('view') || 'guide';
    if (!['guide', 'markdown', 'source'].includes(selectedView)) selectedView = 'guide';
    for (const button of document.querySelectorAll('[data-view]')) {
      button.setAttribute('aria-pressed', String(button.dataset.view === selectedView));
    }
    for (const id of ['guide', 'markdown', 'source']) $(id).hidden = id !== selectedView;
    if (selectedView === 'source' && !sourcePromise) {
      $('source-text').textContent = 'Loading source…';
      sourcePromise = text(file).then(value => { $('source-text').textContent = value; })
        .catch(error => { $('source-text').textContent = error.message; sourcePromise = null; });
    }
  }
  async function initialize() {
    const response = await fetch('assets/folders.json');
    if (!response.ok) throw new Error('The folder index could not be loaded.');
    const folders = await response.json();
    const folder = Object.keys(folders).find(key => folders[key].files.includes(file));
    if (folder === undefined) throw new Error('Choose a file from the tool catalog. This file is not in the documentation index.');
    const entry = folders[folder];
    $('file-title').textContent = file.split('/').pop();
    document.title = `${file.split('/').pop()} · File guide`;
    $('breadcrumb').textContent = folder || 'Repository root';
    const readme = entry.readme;
    if (readme) {
      const markdown = await text(readme);
      $('markdown-text').textContent = markdown;
      $('guide').innerHTML = DOMPurify.sanitize(marked.parse(markdown), { USE_PROFILES: { html: true } });
      const headingIds = new Map();
      for (const heading of $('guide').querySelectorAll('h1,h2,h3,h4,h5,h6')) {
        const base = heading.textContent.toLowerCase().replace(/[^\p{L}\p{N}_\s-]/gu, '').replace(/\s/g, '-');
        const count = headingIds.get(base) || 0;
        heading.id = base + (count ? `-${count}` : '');
        headingIds.set(base, count + 1);
      }
      // Route relative tool links back into this reader, never directly to a download.
      for (const link of $('guide').querySelectorAll('a[href]')) {
        const href = link.getAttribute('href');
        if (href.startsWith('#') || /^[a-z][a-z0-9+.-]*:/i.test(href) || href.startsWith('//')) continue;
        const resolved = new URL(href, new URL(encoded(readme), location.href));
        if (resolved.origin !== location.origin) continue;
        const target = decodeURIComponent(resolved.pathname).replace(/^\//, '');
        const targetFolder = Object.keys(folders).find(key => folders[key].files.includes(target));
        if (targetFolder !== undefined) {
          link.href = `guide.html?file=${encodeURIComponent(target)}`;
          if (target === file) {
            // A source paragraph or filename heading identifies the explanation section.
            let node = link.closest('p,h2,h3,h4');
            if (node && (node.tagName !== 'P' || /^Source:/i.test(node.textContent))) {
              while (node && !/^H[234]$/.test(node.tagName)) node = node.previousElementSibling;
              if (node && !$('guide').querySelector('.selected-section')) {
                node.classList.add('selected-section');
              }
            }
          }
        } else if (target === readme) link.href = repo + encoded(readme);
        else link.href = repo + encoded(target) + resolved.hash;
      }
      // Relative images must resolve beside the README, not beside this reader.
      for (const image of $('guide').querySelectorAll('img[src]')) {
        const src = image.getAttribute('src');
        if (!/^(?:[a-z][a-z0-9+.-]*:|\/)/i.test(src)) {
          image.src = new URL(src, new URL(encoded(readme), location.href)).href;
        }
      }
      $('readme-link').href = repo + encoded(readme);
      const selected = $('guide').querySelector('.selected-section');
      if (selected) {
        const explanation = document.createElement('article');
        explanation.className = 'file-explanation';
        let node = selected;
        do {
          const clone = node.cloneNode(true);
          clone.removeAttribute('id');
          clone.querySelectorAll('[id]').forEach(element => element.removeAttribute('id'));
          explanation.append(clone);
          node = node.nextElementSibling;
        } while (node && !/^H[12]$/.test(node.tagName));
        const folderGuide = document.createElement('details');
        const summary = document.createElement('summary'); summary.textContent = 'Read the complete folder guide';
        folderGuide.append(summary);
        while ($('guide').firstChild) folderGuide.append($('guide').firstChild);
        $('guide').append(explanation, folderGuide);
      }
      const openHeading = hash => {
        let id;
        try { id = decodeURIComponent(hash.slice(1)); } catch { return; }
        const heading = document.getElementById(id);
        if (heading && $('guide').contains(heading)) {
          const details = heading.closest('details');
          if (details) details.open = true;
          heading.scrollIntoView();
        }
      };
      $('guide').addEventListener('click', event => {
        const link = event.target.closest('a[href^="#"]');
        if (link) openHeading(link.getAttribute('href'));
      });
      if (location.hash) requestAnimationFrame(() => openHeading(location.hash));
    } else {
      $('guide').textContent = 'An authored folder guide is not available yet. The source walkthrough below shows the file’s own notes, dependencies, and entry points.';
      document.querySelector('[data-view="markdown"]').disabled = true;
      $('readme-link').hidden = true;
      if (params.get('view') === 'markdown') {
        $('markdown-text').textContent = 'No folder README exists yet.';
      }
    }
    if (!readme || !$('guide').querySelector('.file-explanation')) {
      const source = await text(file);
      walkthrough = explainSource(source);
      $('guide').append(walkthrough);
      $('source-text').textContent = source;
      sourcePromise = Promise.resolve();
    }
    for (const path of entry.files) {
      const li = document.createElement('li');
      const link = document.createElement('a');
      link.href = `guide.html?file=${encodeURIComponent(path)}`;
      link.textContent = path.split('/').pop();
      if (path === file) link.setAttribute('aria-current', 'page');
      li.append(link); $('folder-files').append(li);
    }
    $('github-link').href = repo + encoded(file);
    $('download-link').href = encoded(file);
    if (file.endsWith('.html')) {
      $('interactive-link').href = encoded(file);
      $('interactive-link').hidden = false;
    }
    $('views').hidden = false;
    $('related').hidden = false;
    $('source-links').hidden = false;
    $('status').textContent = readme ? 'Folder guide · Read the explanation, then inspect the source when needed.' : 'Folder documentation is incomplete.';
    document.querySelectorAll('[data-view]').forEach(button => button.addEventListener('click', () => {
      const url = new URL(location.href);
      if (button.dataset.view === 'guide') url.searchParams.delete('view');
      else url.searchParams.set('view', button.dataset.view);
      history.pushState(null, '', url); renderState();
    }));
    window.addEventListener('popstate', renderState);
    renderState();
  }
  initialize().catch(error => { $('status').textContent = error.message; });
})();
