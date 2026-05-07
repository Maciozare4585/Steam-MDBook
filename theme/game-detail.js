(function () {
  const root = document.getElementById("game-detail-root");
  if (!root) return;
  const params = new URLSearchParams(window.location.search);
  const targetId = params.get("id") || (window.location.hash || "").replace(/^#/, "");
  const htmlEscape = (value) => String(value ?? "").replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#039;");
  const renderList = (label, values) => Array.isArray(values) && values.length ? `<div class="game-detail__chips"><strong>${label}:</strong> ${values.map(v => `<span>${htmlEscape(v)}</span>`).join(" ")}</div>` : "";
  fetch("../assets/data/games-index.json")
    .then(r => { if (!r.ok) throw new Error(`No se pudo leer games-index.json (${r.status})`); return r.json(); })
    .then(games => {
      if (!targetId) { root.innerHTML = `<div class="game-detail game-detail--empty"><h2>Selecciona un juego</h2><p>Abre esta página desde un tooltip o usa <code>detalle.html?id=STEAM_APP_ID</code>.</p></div>`; return; }
      const game = games.find(g => String(g.steamAppId) === String(targetId));
      if (!game) { root.innerHTML = `<div class="game-detail game-detail--missing"><h2>No encontrado</h2><p>No existe App ID <code>${htmlEscape(targetId)}</code> en <code>games-index.json</code>.</p></div>`; return; }
      const appId = htmlEscape(game.steamAppId), title = htmlEscape(game.title || game.officialName || `App ${appId}`), officialName = htmlEscape(game.officialName || ""), metadata = game.metadata || {};
      root.innerHTML = `<article class="game-detail"><header class="game-detail__hero"><img src="../assets/games/${appId}/steam-header.jpg" alt="${title}" loading="lazy" /><div><p class="game-detail__eyebrow">Steam App ID <code>${appId}</code></p><h2>${title}</h2><p>${officialName}</p><div class="steam-actions"><a class="steam-action steam-play" href="steam://run/${appId}">▶ Jugar</a><a class="steam-action steam-install" href="steam://install/${appId}">⬇ Instalar</a><a class="steam-action steam-store" href="https://store.steampowered.com/app/${appId}">Tienda</a></div></div></header><section class="game-detail__grid"><div class="game-detail__panel"><h3>Metadatos base</h3><table><tbody><tr><th>Tipo Steam</th><td><code>${htmlEscape(game.steamType || "")}</code></td></tr><tr><th>Match</th><td><code>${htmlEscape(game.matchType || "")}</code></td></tr><tr><th>Imagen</th><td><code>${htmlEscape(game.preferredImageSource || "steam")}</code></td></tr><tr><th>Alias</th><td>${(game.aliases || []).map(htmlEscape).join(", ")}</td></tr></tbody></table></div><div class="game-detail__panel"><h3>Metadata extendida</h3>${renderList("Géneros", metadata.genres)}${renderList("Categorías", metadata.categories)}${renderList("Developers", metadata.developers)}${renderList("Publishers", metadata.publishers)}${metadata.releaseDate ? `<p><strong>Fecha:</strong> ${htmlEscape(metadata.releaseDate)}</p>` : ""}${metadata.shortDescription ? `<p>${htmlEscape(metadata.shortDescription)}</p>` : ""}${(!metadata || Object.keys(metadata).length === 0) ? `<p class="game-detail__muted">Metadata extendida pendiente.</p>` : ""}</div></section></article>`;
    }).catch(e => { root.innerHTML = `<div class="game-detail game-detail--missing"><h2>Error</h2><p>${htmlEscape(e.message)}</p></div>`; });
})();
