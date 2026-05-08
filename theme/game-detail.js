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
    if (!dlcInfo || dlcInfo.hasDlc !== true) {
      return `<p class="game-detail__muted">Sin DLC registrado en la ficha local.</p>`;
    }
    const rows = asArray(dlcInfo.dlcs).map(dlc => `<tr>
      <td>${boolIcon(dlc.owned)}</td>
      <td>${htmlEscape(dlc.title || "DLC sin nombre")}</td>
      <td><code>${htmlEscape(dlc.type || "unknown")}</code></td>
      <td>${boolIcon(dlc.important)}</td>
      <td>${htmlEscape(dlc.status || "")}</td>
    </tr>`).join("");
    return `<p><strong>${dlcInfo.ownedDlcCount ?? 0}</strong> de <strong>${dlcInfo.totalDlcCount ?? 0}</strong> DLC marcados como propios.</p>
      <table class="game-detail__mini-table"><thead><tr><th>Propio</th><th>DLC</th><th>Tipo</th><th>Importa</th><th>Estado</th></tr></thead><tbody>${rows || `<tr><td colspan="5">DLC pendiente de clasificar.</td></tr>`}</tbody></table>`;
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
