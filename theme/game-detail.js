(function () {
  const root = document.getElementById("game-detail-root");
  if (!root) return;

  const params = new URLSearchParams(window.location.search);
  const targetId = params.get("id") || (window.location.hash || "").replace(/^#/, "");

  const htmlEscape = (value) => String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");

  const boolIcon = (value) => value === true ? "✅" : value === false ? "❌" : "—";
  const textOrDash = (value) => value === null || value === undefined || value === "" ? "—" : htmlEscape(value);
  const asArray = (value) => Array.isArray(value) ? value : [];
  const renderChips = (label, values) => {
    const list = asArray(values).filter(Boolean);
    if (!list.length) return "";
    return `<div class="game-detail__chips"><strong>${htmlEscape(label)}:</strong> ${list.map(v => `<span>${htmlEscape(v)}</span>`).join(" ")}</div>`;
  };
  const renderBoolRow = (label, value) => `<tr><th>${htmlEscape(label)}</th><td>${boolIcon(value)}</td></tr>`;
  const renderTextRow = (label, value) => `<tr><th>${htmlEscape(label)}</th><td>${textOrDash(value)}</td></tr>`;

  function renderDlc(dlcInfo) {
    if (!dlcInfo) {
      return `<p class="game-detail__muted">Sin DLC registrado en la ficha local.</p>`;
    }

    if (dlcInfo.hasDlc !== true) {
      if (dlcInfo.ownershipStatus === "no_dlc_detected" || dlcInfo.catalogSource) {
        return `<p class="game-detail__muted">Steam no reportó DLC para este juego${dlcInfo.lastCatalogSyncAt ? ` · ${htmlEscape(dlcInfo.lastCatalogSyncAt)}` : ""}.</p>`;
      }
      return `<p class="game-detail__muted">Sin DLC registrado en la ficha local.</p>`;
    }

    const statusLabel = {
      full: "Full DLC",
      almost_full: "Casi full DLC",
      owned_major: "DLC principal propio",
      owned_unspecified: "DLC propio sin detalle",
      excluded_exception: "Excepción / no full",
      partial: "Parcial",
      catalog_only: "Catálogo detectado / pendiente manual",
      no_dlc_detected: "Sin DLC detectado",
      unknown: "Sin confirmar"
    }[dlcInfo.ownershipStatus || "unknown"] || htmlEscape(dlcInfo.ownershipStatus || "Sin confirmar");

    const summary = dlcInfo.ownershipSummary
      ? `<p><strong>Resumen:</strong> ${htmlEscape(dlcInfo.ownershipSummary)}</p>`
      : "";

    const catalogMeta = dlcInfo.catalogSource || dlcInfo.lastCatalogSyncAt
      ? `<p class="game-detail__muted"><strong>Catálogo:</strong> ${textOrDash(dlcInfo.catalogSource)}${dlcInfo.lastCatalogSyncAt ? ` · ${htmlEscape(dlcInfo.lastCatalogSyncAt)}` : ""}</p>`
      : "";

    const missingNotes = asArray(dlcInfo.missingNotes).filter(Boolean);
    const missingBlock = missingNotes.length
      ? `<div class="game-detail__note"><strong>Pendiente:</strong><ul>${missingNotes.map(n => `<li>${htmlEscape(n)}</li>`).join("")}</ul></div>`
      : "";

    const checkbox = (value, label) => `<label class="game-detail__dlc-checkbox" title="Campo manual en games-metadata.json">
      <input type="checkbox" disabled ${value === true ? "checked" : ""} />
      <span>${htmlEscape(label || (value === true ? "Sí" : "No"))}</span>
    </label>`;

    const rows = asArray(dlcInfo.dlcs).map(dlc => {
      const dlcTitle = dlc.title || dlc.name || "DLC sin nombre";
      const storeLink = dlc.storeUrl || (dlc.appId ? `https://store.steampowered.com/app/${dlc.appId}` : null);
      const titleCell = storeLink
        ? `<a href="${htmlEscape(storeLink)}" target="_blank" rel="noreferrer">${htmlEscape(dlcTitle)}</a>`
        : htmlEscape(dlcTitle);
      const price = dlc.price ? `<span class="game-detail__dlc-muted">${htmlEscape(dlc.price)}</span>` : "";
      const freeBadge = dlc.isFree === true ? `<span class="game-detail__dlc-badge">gratis</span>` : "";
      return `<tr>
        <td>${checkbox(dlc.owned)}</td>
        <td>${titleCell}<div class="game-detail__dlc-subline">${dlc.appId ? `AppID ${htmlEscape(dlc.appId)}` : ""} ${price} ${freeBadge}</div></td>
        <td><code>${htmlEscape(dlc.type || "dlc")}</code></td>
        <td>${checkbox(dlc.important, dlc.important === true ? "Sí" : "")}</td>
        <td>${htmlEscape(dlc.status || "pendiente_manual")}</td>
      </tr>`;
    }).join("");

    return `<p><strong>Estado:</strong> <code>${htmlEscape(statusLabel)}</code></p>
      ${summary}
      ${catalogMeta}
      <p><strong>${dlcInfo.ownedDlcCount ?? 0}</strong> de <strong>${dlcInfo.totalDlcCount ?? 0}</strong> DLC marcados como propios.</p>
      ${missingBlock}
      <table class="game-detail__mini-table game-detail__dlc-table"><thead><tr><th>Lo tenemos</th><th>DLC</th><th>Tipo</th><th>Importa</th><th>Estado</th></tr></thead><tbody>${rows || `<tr><td colspan="5">DLC pendiente de clasificar.</td></tr>`}</tbody></table>
      <p class="game-detail__muted">Los checkboxes son de lectura en el mdBook. Para cambiarlos, edita <code>data/games-metadata.json</code> en <code>dlcInfo.dlcs[].owned</code> y regenera <code>games-index.json</code>.</p>`;
  }

  function renderProfile(profileMetadata) {
    const people = profileMetadata || {};
    const cards = Object.entries(people).filter(([, p]) => p && (p.visibility !== "normal" || p.importanceLevel !== "normal" || p.personalSummary)).map(([person, p]) => `
      <div class="game-detail__profile-card">
        <h4>${htmlEscape(person)}</h4>
        <p><strong>Importancia:</strong> <code>${htmlEscape(p.importanceLevel || "normal")}</code></p>
        ${p.personalSummary ? `<p>${htmlEscape(p.personalSummary)}</p>` : ""}
        ${p.whyItMatters ? `<p><strong>Por qué importa:</strong> ${htmlEscape(p.whyItMatters)}</p>` : ""}
        ${renderChips("Tags personales", p.profileTags)}
        ${renderChips("Tipo de significado", p.meaningType)}
      </div>`).join("");
    return cards || `<p class="game-detail__muted">Sin significado personal destacado todavía.</p>`;
  }

  // Mostrar estado de carga
  root.innerHTML = `<div class="game-detail game-detail--loading">Cargando ficha…</div>`;

  // Intentar varias rutas relativas para games-index.json (el nivel de anidamiento varía)
  const possiblePaths = [
    "../assets/data/games-index.json",
    "../../assets/data/games-index.json",
    "assets/data/games-index.json"
  ];

  function tryFetch(paths) {
    if (!paths.length) return Promise.reject(new Error("No se pudo leer games-index.json desde ninguna ruta conocida."));
    return fetch(paths[0])
      .then(r => r.ok ? r.json() : Promise.reject())
      .catch(() => tryFetch(paths.slice(1)));
  }

  tryFetch(possiblePaths)
    .then(games => {
      if (!targetId) {
        root.innerHTML = `<div class="game-detail game-detail--empty"><h2>Selecciona un juego</h2><p>Abre esta página desde un tooltip o usa <code>detalle.html?id=STEAM_APP_ID</code>.</p></div>`;
        return;
      }
      const game = games.find(g => String(g.steamAppId) === String(targetId));
      if (!game) {
        root.innerHTML = `<div class="game-detail game-detail--missing"><h2>No encontrado</h2><p>No existe App ID <code>${htmlEscape(targetId)}</code> en <code>games-index.json</code>.</p></div>`;
        return;
      }

      const appId = game.steamAppId;
      const title = game.title || game.officialName || `App ${appId}`;
      const steamMetadata = game.steamMetadata || game.metadata || {};
      const playerState = game.playerState || {};
      const checkboxes = playerState.checkboxes || {};
      const playModes = game.playModes || {};
      const steamFeatures = game.steamFeatures || {};
      const reco = game.recommendationMetadata || {};
      const placement = game.libraryPlacement || {};
      const dataQuality = game.dataQuality || {};

      root.innerHTML = `<article class="game-detail">
        <header class="game-detail__hero">
          <img src="../assets/games/${appId}/steam-header.jpg" alt="${htmlEscape(title)}" loading="lazy"
               onerror="this.classList.add('img-error');this.alt='Sin imagen';this.removeAttribute('src');this.insertAdjacentHTML('afterend','<span style=\\"display:block;text-align:center;padding:2rem;opacity:.5;font-size:2rem\\">🎮</span>');this.remove();" />
          <div>
            <p class="game-detail__eyebrow">Steam App ID <code>${appId}</code></p>
            <h2>${htmlEscape(title)}</h2>
            <p>${htmlEscape(game.officialName || "")}</p>
            <div class="steam-actions">
              <a class="steam-action steam-play" href="steam://run/${appId}">▶ Jugar</a>
              <a class="steam-action steam-install" href="steam://install/${appId}">⬇ Instalar</a>
              <a class="steam-action steam-store" href="https://store.steampowered.com/app/${appId}">Tienda</a>
            </div>
          </div>
        </header>

        <section class="game-detail__grid">
          <div class="game-detail__panel">
            <h3>Resumen Steam</h3>
            <table><tbody>
              ${renderTextRow("Tipo Steam", game.steamType)}
              ${renderTextRow("Match", game.matchType)}
              ${renderTextRow("Fecha", steamMetadata.releaseDate)}
              ${renderTextRow("Metadata", dataQuality.metadataStatus)}
            </tbody></table>
            ${steamMetadata.shortDescription ? `<p>${htmlEscape(steamMetadata.shortDescription)}</p>` : `<p class="game-detail__muted">Descripción pendiente.</p>`}
            ${renderChips("Géneros", steamMetadata.genres)}
            ${renderChips("Categorías", steamMetadata.categories)}
            ${renderChips("Tags", steamMetadata.tags)}
            ${renderChips("Developers", steamMetadata.developers)}
            ${renderChips("Publishers", steamMetadata.publishers)}
          </div>

          <div class="game-detail__panel">
            <h3>Estado personal</h3>
            <table><tbody>
              ${renderTextRow("Estado principal", playerState.mainStatus)}
              ${renderBoolRow("Ya lo probé", checkboxes.tried)}
              ${renderBoolRow("Ya lo empecé", checkboxes.started)}
              ${renderBoolRow("Historia terminada", checkboxes.finishedMainStory)}
              ${renderBoolRow("Postgame/extras", checkboxes.finishedPostGame)}
              ${renderBoolRow("100% / platinado", checkboxes.completed100Percent)}
              ${renderBoolRow("Abandonado", checkboxes.abandoned)}
              ${renderBoolRow("Favorito", checkboxes.favorite)}
              ${renderBoolRow("Quiero jugarlo", checkboxes.wantsToPlay)}
              ${renderBoolRow("Quiero terminarlo", checkboxes.wantsToFinish)}
              ${renderBoolRow("Quiero rejugarlo", checkboxes.wantsToReplay)}
              ${renderBoolRow("Quiero platinarlo", checkboxes.wantsToPlatinum)}
              ${renderBoolRow("Necesita reinicio", checkboxes.needsRestart)}
              ${renderBoolRow("Primero juego anterior", checkboxes.needsPreviousGame)}
              ${renderBoolRow("Bueno con alguien", checkboxes.goodForCoop)}
            </tbody></table>
          </div>

          <div class="game-detail__panel">
            <h3>Modos de juego</h3>
            <table><tbody>
              ${renderBoolRow("Single-player", playModes.singlePlayer)}
              ${renderBoolRow("Multiplayer local", playModes.localMultiplayer)}
              ${renderBoolRow("Multiplayer online", playModes.onlineMultiplayer)}
              ${renderBoolRow("Co-op local", playModes.localCoop)}
              ${renderBoolRow("Co-op online", playModes.onlineCoop)}
              ${renderBoolRow("PvP", playModes.pvp)}
              ${renderBoolRow("PvE", playModes.pve)}
              ${renderBoolRow("MMO", playModes.mmo)}
            </tbody></table>
          </div>

          <div class="game-detail__panel">
            <h3>Features Steam</h3>
            <table><tbody>
              ${renderBoolRow("Logros", steamFeatures.achievements)}
              ${renderBoolRow("Steam Cloud", steamFeatures.cloudSaves)}
              ${renderBoolRow("Mando completo", steamFeatures.fullControllerSupport)}
              ${renderBoolRow("Mando parcial", steamFeatures.partialControllerSupport)}
              ${renderBoolRow("Remote Play Together", steamFeatures.remotePlayTogether)}
              ${renderBoolRow("Workshop", steamFeatures.workshop)}
              ${renderBoolRow("Trading cards", steamFeatures.tradingCards)}
              ${renderBoolRow("VR", steamFeatures.vrSupported)}
            </tbody></table>
          </div>

          <div class="game-detail__panel game-detail__panel--wide">
            <h3>DLC / contenido adicional</h3>
            ${renderDlc(game.dlcInfo)}
          </div>

          <div class="game-detail__panel">
            <h3>Recomendación</h3>
            <table><tbody>
              ${renderTextRow("Rol", reco.playRole)}
              ${renderTextRow("Energía", reco.energyRequired)}
              ${renderTextRow("Sesión", reco.sessionLength)}
              ${renderTextRow("Fricción", reco.friction)}
              ${renderTextRow("Reenganche", reco.reentryCost)}
              ${renderTextRow("Historia", reco.storyDependency)}
              ${renderTextRow("Foco", reco.focusRequired)}
              ${renderTextRow("Dificultad", reco.difficulty)}
            </tbody></table>
            ${renderChips("Mood", reco.moodTags)}
            ${renderChips("Ideal para", reco.goodFor)}
            ${renderChips("Evitar cuando", reco.avoidWhen)}
          </div>

          <div class="game-detail__panel">
            <h3>Ubicación</h3>
            ${renderChips("Colecciones", placement.collections)}
            ${renderChips("Estados", placement.states)}
            ${renderChips("Perfiles", placement.profiles)}
            ${placement.quarantineSource ? `<p><strong>Cuarentena:</strong> <code>${htmlEscape(placement.quarantineSource)}</code></p>` : ""}
          </div>

          <div class="game-detail__panel game-detail__panel--wide">
            <h3>Significado por perfil</h3>
            ${renderProfile(game.profileMetadata)}
          </div>
        </section>
      </article>`;
    }).catch(e => {
      root.innerHTML = `<div class="game-detail game-detail--missing"><h2>Error</h2><p>${htmlEscape(e.message)}</p></div>`;
    });
})();
