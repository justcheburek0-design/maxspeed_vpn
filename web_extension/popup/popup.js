// MaxSpeedVPN Web Extension — Popup Script
// Парсит подписки и отображает серверы

(function () {
  'use strict';

  // ─── DOM refs ───
  const els = {
    subUrl: document.getElementById('subUrl'),
    loadBtn: document.getElementById('loadBtn'),
    errorMsg: document.getElementById('errorMsg'),
    serverList: document.getElementById('serverList'),
    emptyState: document.getElementById('emptyState'),
    serverCount: document.getElementById('serverCount'),
    statusBadge: document.getElementById('statusBadge'),
    toast: document.getElementById('toast'),
  };

  // ─── State ───
  let links = [];

  // ─── Init ───
  init();

  async function init() {
    // Restore saved subscription
    const stored = await getStorage('subscription');
    if (stored) {
      els.subUrl.value = stored;
      await loadSubscription(stored, false);
    }

    els.loadBtn.addEventListener('click', async () => {
      const url = els.subUrl.value.trim();
      if (!url) {
        showError('Введите URL подписки');
        return;
      }
      await setStorage('subscription', url);
      await loadSubscription(url, true);
    });
  }

  // ─── Load subscription ───
  async function loadSubscription(url, showToastOnSuccess) {
    hideError();
    els.loadBtn.textContent = '⏳ Загрузка...';
    els.loadBtn.disabled = true;

    try {
      const response = await fetch(url, {
        signal: AbortSignal.timeout(15000),
      });

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}: ${response.statusText}`);
      }

      const text = await response.text();
      links = parseSubscription(text);

      if (links.length === 0) {
        throw new Error('Не найдено валидных ссылок в подписке');
      }

      setStorage('subLinks', links).catch(() => {});
      renderServers();

      if (showToastOnSuccess) {
        showToast(`✅ Загружено ${links.length} серверов`);
      }
    } catch (err) {
      showError(`Ошибка: ${err.message}`);
    } finally {
      els.loadBtn.textContent = 'Загрузить';
      els.loadBtn.disabled = false;
    }
  }

  // ─── Parse subscription ───
  function parseSubscription(text) {
    const lines = text
      .split(/\r?\n/)
      .map((l) => l.trim())
      .filter((l) => l.length > 0);

    // Check if base64-encoded (common subscription format)
    const joined = lines.join('');
    let decodedLines = lines;

    // Try base64 decode if no direct protocol links found
    if (!joined.includes('://')) {
      try {
        const decoded = decodeURIComponent(escape(atob(joined)));
        decodedLines = decoded
          .split(/\r?\n/)
          .map((l) => l.trim())
          .filter((l) => l.length > 0);
      } catch {
        // Not base64, use as-is
      }
    }

    const results = [];
    for (const line of decodedLines) {
      const parsed = parseLink(line);
      if (parsed) results.push(parsed);
    }
    return results;
  }

  // ─── Parse individual link ───
  function parseLink(raw) {
    const trimmed = raw.trim();

    // VLESS
    if (trimmed.startsWith('vless://')) {
      return parseVless(trimmed);
    }
    // VMess
    if (trimmed.startsWith('vmess://')) {
      return parseVmess(trimmed);
    }
    // Trojan
    if (trimmed.startsWith('trojan://')) {
      return parseTrojan(trimmed);
    }
    // Shadowsocks
    if (trimmed.startsWith('ss://')) {
      return parseShadowsocks(trimmed);
    }
    // Hysteria2
    if (trimmed.startsWith('hysteria2://') || trimmed.startsWith('hy2://')) {
      return parseHysteria2(trimmed);
    }
    // TUIC
    if (trimmed.startsWith('tuic://')) {
      return parseTuic(trimmed);
    }

    return null;
  }

  function parseVless(raw) {
    try {
      const url = new URL(raw);
      const params = url.searchParams;
      const name = decodeURIComponent(url.hash.slice(1)) || 'VLESS';
      const protocol = 'VLESS';

      let security = 'none';
      if (params.get('security') === 'tls') security = 'TLS';
      else if (params.get('security') === 'reality') security = 'Reality';
      else if (params.get('security') === 'xtls') security = 'XTLS';

      const transport = params.get('type') || 'tcp';
      const transportMap = { grpc: 'gRPC', ws: 'WebSocket', xhttp: 'XHTTP', http: 'HTTP', tcp: 'TCP' };
      const transportName = transportMap[transport] || transport.toUpperCase();

      return {
        name,
        protocol,
        security,
        transport: transportName,
        address: `${url.hostname}:${url.port || 443}`,
        raw,
      };
    } catch {
      return null;
    }
  }

  function parseVmess(raw) {
    try {
      const b64 = raw.slice(8);
      const json = JSON.parse(atob(b64));
      const name = json.ps || 'VMess';
      return {
        name,
        protocol: 'VMess',
        security: json.tls || 'none',
        transport: json.net || 'tcp',
        address: `${json.add}:${json.port}`,
        raw,
      };
    } catch {
      return null;
    }
  }

  function parseTrojan(raw) {
    try {
      const url = new URL(raw);
      const name = decodeURIComponent(url.hash.slice(1)) || 'Trojan';
      return {
        name,
        protocol: 'Trojan',
        security: 'TLS',
        transport: 'TCP',
        address: `${url.hostname}:${url.port || 443}`,
        raw,
      };
    } catch {
      return null;
    }
  }

  function parseShadowsocks(raw) {
    try {
      // ss://base64(method:password)@host:port#name
      const url = new URL(raw);
      const name = decodeURIComponent(url.hash.slice(1)) || 'Shadowsocks';

      let method = 'unknown';
      let password = '';
      const userInfo = url.username || '';
      try {
        const decoded = atob(userInfo);
        const colonIdx = decoded.indexOf(':');
        if (colonIdx >= 0) {
          method = decoded.slice(0, colonIdx);
          password = decoded.slice(colonIdx + 1);
        }
      } catch {
        // ignore
      }

      return {
        name,
        protocol: 'Shadowsocks',
        security: method,
        transport: 'TCP',
        address: `${url.hostname}:${url.port || 8388}`,
        raw,
      };
    } catch {
      return null;
    }
  }

  function parseHysteria2(raw) {
    try {
      const url = new URL(raw);
      const name = decodeURIComponent(url.hash.slice(1)) || 'Hysteria2';
      return {
        name,
        protocol: 'Hysteria2',
        security: 'QUIC',
        transport: 'UDP',
        address: `${url.hostname}:${url.port || 443}`,
        raw,
      };
    } catch {
      return null;
    }
  }

  function parseTuic(raw) {
    try {
      const url = new URL(raw);
      const name = decodeURIComponent(url.hash.slice(1)) || 'TUIC';
      return {
        name,
        protocol: 'TUIC',
        security: 'QUIC',
        transport: 'UDP',
        address: `${url.hostname}:${url.port || 443}`,
        raw,
      };
    } catch {
      return null;
    }
  }

  // ─── Render servers ───
  function renderServers() {
    els.serverCount.textContent = `(${links.length})`;

    if (links.length === 0) {
      els.emptyState.style.display = 'block';
      els.serverList.innerHTML = '';
      els.serverList.appendChild(els.emptyState);
      return;
    }

    els.emptyState.style.display = 'none';
    els.serverList.innerHTML = '';

    for (const link of links) {
      const item = document.createElement('div');
      item.className = 'server-item';

      const info = document.createElement('div');
      info.className = 'server-info';

      const name = document.createElement('div');
      name.className = 'server-name';
      name.textContent = link.name;
      info.appendChild(name);

      const meta = document.createElement('div');
      meta.className = 'server-meta';
      meta.textContent = `${link.address}`;
      info.appendChild(meta);

      const tags = document.createElement('div');
      tags.className = 'server-tags';

      const protoTag = document.createElement('span');
      protoTag.className = 'tag';
      protoTag.textContent = link.protocol;
      tags.appendChild(protoTag);

      if (link.security && link.security !== 'none') {
        const secTag = document.createElement('span');
        secTag.className = 'tag';
        secTag.textContent = link.security;
        tags.appendChild(secTag);
      }

      info.appendChild(tags);

      const copyBtn = document.createElement('button');
      copyBtn.className = 'server-copy';
      copyBtn.textContent = '📋';
      copyBtn.title = 'Копировать ссылку';
      copyBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        navigator.clipboard.writeText(link.raw).then(() => {
          showToast('✅ Ссылка скопирована');
        });
      });

      item.appendChild(info);
      item.appendChild(copyBtn);

      // Click to also copy
      item.addEventListener('click', () => {
        navigator.clipboard.writeText(link.raw).then(() => {
          showToast('✅ Ссылка скопирована');
        });
      });

      els.serverList.appendChild(item);
    }
  }

  // ─── Helpers ───
  function showError(msg) {
    els.errorMsg.textContent = msg;
    els.errorMsg.classList.add('show');
  }

  function hideError() {
    els.errorMsg.classList.remove('show');
  }

  function showToast(msg) {
    els.toast.textContent = msg;
    els.toast.classList.add('show');
    setTimeout(() => els.toast.classList.remove('show'), 2500);
  }

  // Storage API (works in both Chrome and Firefox)
  function getStorage(key) {
    const api = typeof browser !== 'undefined' ? browser.storage : chrome.storage;
    return new Promise((resolve) => {
      api.local.get([key], (result) => {
        resolve(result[key] || null);
      });
    });
  }

  function setStorage(key, value) {
    const api = typeof browser !== 'undefined' ? browser.storage : chrome.storage;
    return new Promise((resolve) => {
      api.local.set({ [key]: value }, resolve);
    });
  }
})();
