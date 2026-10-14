/**
 * Steam High Family mdBook — ficha dinámica de juego.
 *
 * Responsabilidades:
 * - Cargar `src/assets/data/games-index.json` desde rutas relativas posibles.
 * - Renderizar una ficha única por `steamAppId` usando `detalle.html?id=<APPID>`.
 * - Mostrar metadata Steam, estado personal, modos, features, ubicación y perfil.
 * - Mostrar DLC con sistema de iconos múltiples (`dlcInfo.dlcs[].markers`), no checkboxes.
 * - Aplicar fallback seguro de imagen sin inyectar JavaScript roto en el HTML.
 */
(function () {
  const root = document.getElementById("game-detail-root");
  if (!root) return;

  const params = new URLSearchParams(window.location.search);
  const targetId = params.get("id") || (window.location.hash || "").replace(/^#/, "");

  /**
   * Escapa texto para insertarlo dentro de HTML generado por template strings.
   * @param {unknown} value Valor a escapar.
   * @returns {string} Texto seguro para HTML.
   */
  const htmlEscape = (value) => String(value ?? "")
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");

  /** @param {unknown} value */
  const boolIcon = (value) => value === true ? "✅" : value === false ? "❌" : "—";
  /** @param {unknown} value */
  const textOrDash = (value) => value === null || value === undefined || value === "" ? "—" : htmlEscape(value);
  /** @param {unknown} value */
  const asArray = (value) => Array.isArray(value) ? value : [];

  /**
   * Fallback global usado por el atributo `onerror` de la imagen hero.
   * Se expone en `window` para evitar handlers largos con comillas rotas dentro de `innerHTML`.
   * @param {HTMLImageElement} img Imagen que falló al cargar.
   */
  window.__steamDetailImgFallback = function __steamDetailImgFallback(img) {
    if (!img || !img.parentElement) return;
    const fallback = document.createElement("span");
    fallback.className = "game-detail__image-fallback";
    fallback.setAttribute("aria-label", "Sin imagen");
    fallback.textContent = "🎮";
    img.classList.add("img-error");
    img.alt = "Sin imagen";
    img.replaceWith(fallback);
  };

  /**
   * Renderiza chips compactos para listas cortas.
   * @param {string} label Etiqueta visible.
   * @param {unknown[]} values Valores a renderizar.
   * @returns {string}
   */
  const renderChips = (label, values) => {
    const list = asArray(values).filter(Boolean);
    if (!list.length) return "";
    return `<div class="game-detail__chips"><strong>${htmlEscape(label)}:</strong> ${list.map(v => `<span>${htmlEscape(v)}</span>`).join(" ")}</div>`;
  };

  /** @param {string} label @param {unknown} value */
  const renderBoolRow = (label, value) => `<tr><th>${htmlEscape(label)}</th><td>${boolIcon(value)}</td></tr>`;
  /** @param {string} label @param {unknown} value */
  const renderTextRow = (label, value) => `<tr><th>${htmlEscape(label)}</th><td>${textOrDash(value)}</td></tr>`;

  /**
   * Normaliza estado textual para mapearlo a un icono legible.
   * @param {unknown} value Estado crudo.
   * @returns {string}
   */
  function normalizeStatus(value) {
    return String(value || "")
      .trim()
      .toLowerCase()
      .replace(/[\s-]+/g, "_");
  }


  /**
   * Normaliza aliases de marker escritos manualmente.
   * @param {unknown} value Marker crudo.
   * @returns {string}
   */
  function normalizeDlcMarker(value) {
    const marker = String(value || "").trim().toLowerCase().replace(/[\s-]+/g, "_");
    if (!marker) return "";
    return ({
      yes: "owned",
      owned: "owned",
      propio: "owned",
      adquirido: "owned",
      lo_tenemos: "owned",
      no: "missing",
      missing: "missing",
      faltante: "missing",
      pendiente: "missing",
      pendiente_manual: "missing",
      not_owned: "missing",
      skip: "skip",
      no_comprar: "skip",
      descartado: "skip",
      not_buying: "skip",
      soundtrack: "soundtrack",
      ost: "soundtrack",
      banda_sonora: "soundtrack",
      artbook: "artbook",
      bookart: "artbook",
      book_art: "artbook",
      digital_artbook: "artbook",
      cosmetic: "cosmetic",
      skin: "cosmetic",
      outfit: "cosmetic",
      currency: "currency",
      moneda: "currency",
      coins: "currency",
      gems: "currency",
      pass: "pass",
      season_pass: "pass",
      expansion_pass: "pass",
      pack: "pass",
      free: "free",
      gratis: "free"
    }[marker] || marker);
  }

  /**
   * Obtiene metadata visual para `dlcInfo.dlcs[].markers[]`.
   * @param {string} marker Marker normalizado.
   * @returns {{icon: string, label: string, tone: string}}
   */
  function dlcMarkerMeta(marker) {
    return ({
      owned: { icon: "✅", label: "Lo tenemos", tone: "is-owned" },
      missing: { icon: "⬜", label: "No lo tenemos / pendiente", tone: "is-missing" },
      skip: { icon: "🚫", label: "No comprar", tone: "is-skip" },
      soundtrack: { icon: "🎵", label: "Banda sonora", tone: "is-soundtrack" },
      artbook: { icon: "📘", label: "Artbook / libro digital", tone: "is-artbook" },
      cosmetic: { icon: "🎨", label: "Cosmético / skin", tone: "is-cosmetic" },
      currency: { icon: "💰", label: "Moneda / consumible", tone: "is-currency" },
      pass: { icon: "🧩", label: "Pack / expansión / season pass", tone: "is-pass" },
      free: { icon: "🆓", label: "Contenido gratuito", tone: "is-free" },
      unknown: { icon: "❔", label: "Sin clasificar", tone: "is-unknown" }
    }[marker] || { icon: "❔", label: marker || "Sin clasificar", tone: "is-unknown" });
  }

  /**
   * Agrega un marker normalizado conservando orden y evitando duplicados.
   * @param {string[]} markers Acumulador mutable.
   * @param {unknown} value Marker crudo.
   */
  function pushDlcMarker(markers, value) {
    const marker = normalizeDlcMarker(value);
    if (!marker || markers.includes(marker)) return;
    markers.push(marker);
  }

  /**
   * Convierte cualquier forma manual de markers a arreglo.
   * Acepta `markers: ["owned", "pass"]`, `markers: "owned, pass"` o el legado `marker`.
   * @param {unknown} value Valor de markers.
   * @returns {string[]}
   */
  function normalizeDlcMarkers(value) {
    const markers = [];
    if (Array.isArray(value)) {
      value.forEach(v => pushDlcMarker(markers, v));
      return markers;
    }
    if (typeof value === "string" && value.includes(",")) {
      value.split(",").forEach(v => pushDlcMarker(markers, v));
      return markers;
    }
    pushDlcMarker(markers, value);
    return markers;
  }

  /**
   * Obtiene el marker principal de estado de ownership.
   * @param {Record<string, unknown>} dlc Registro DLC.
   * @returns {string}
   */
  function inferDlcOwnershipMarker(dlc) {
    const status = normalizeStatus(dlc.status);

    if (["skip", "no_comprar", "not_buying", "descartado"].includes(status)) return "skip";
    if (["propio", "owned", "lo_tenemos", "adquirido"].includes(status) || dlc.owned === true) return "owned";
    if (["gratis", "free"].includes(status) || dlc.isFree === true) return "free";
    if (["faltante", "missing", "not_owned", "no_lo_tenemos", "pendiente", "pendiente_manual", "manual_pending", "unknown", ""].includes(status)) return "missing";

    return "missing";
  }

  /**
   * Infiere markers de tipo de contenido desde nombre/tipo.
   * @param {Record<string, unknown>} dlc Registro DLC.
   * @returns {string[]}
   */
  function inferDlcContentMarkers(dlc) {
    const title = String(dlc.title || dlc.name || "").toLowerCase();
    const type = String(dlc.type || "").toLowerCase();
    const text = `${title} ${type}`;
    const markers = [];

    if (/soundtrack|ost|original soundtrack|banda sonora|music pack/.test(text)) pushDlcMarker(markers, "soundtrack");
    if (/artbook|art book|digital artbook|booklet|art collection/.test(text)) pushDlcMarker(markers, "artbook");
    if (/skin|costume|cosmetic|outfit|wardrobe|character pack/.test(text)) pushDlcMarker(markers, "cosmetic");
    if (/coin|coins|gem|gems|point|points|credit|credits|currency/.test(text)) pushDlcMarker(markers, "currency");
    if (/season pass|expansion pass|upgrade pack|supporter pack|dlc pack|collection/.test(text)) pushDlcMarker(markers, "pass");

    return markers;
  }

  /**
   * Obtiene todos los iconos/markers de un DLC.
   * Preferencia:
   * 1. `markers` nuevo, porque permite más de un icono.
   * 2. Campos legados `marker`, `iconMarker`, `icon`.
   * 3. Inferencia desde `owned`, `status`, `isFree` y nombre.
   * @param {Record<string, unknown>} dlc Registro DLC.
   * @returns {string[]}
   */
  function getDlcMarkers(dlc) {
    const explicitMarkers = normalizeDlcMarkers(dlc.markers);
    if (explicitMarkers.length) return explicitMarkers;

    const legacyMarkers = [];
    [dlc.marker, dlc.iconMarker, dlc.icon].forEach(v => normalizeDlcMarkers(v).forEach(m => pushDlcMarker(legacyMarkers, m)));

    if (legacyMarkers.length) {
      const hasOwnershipMarker = legacyMarkers.some(m => ["owned", "missing", "skip", "free"].includes(m));
      const markers = [...legacyMarkers];
      if (!hasOwnershipMarker) markers.unshift(inferDlcOwnershipMarker(dlc));
      inferDlcContentMarkers(dlc).forEach(m => pushDlcMarker(markers, m));
      return markers;
    }

    const markers = [];
    pushDlcMarker(markers, inferDlcOwnershipMarker(dlc));
    inferDlcContentMarkers(dlc).forEach(m => pushDlcMarker(markers, m));
    return markers.length ? markers : ["unknown"];
  }

  /**
   * Renderiza solo iconos de estado DLC. El texto queda únicamente como tooltip/accesibilidad.
   * @param {Record<string, unknown>} dlc Registro DLC.
   * @returns {string}
   */
  function renderDlcMarkers(dlc) {
    const markers = getDlcMarkers(dlc);
    return `<span class="game-detail__dlc-markers" aria-label="${htmlEscape(markers.map(m => dlcMarkerMeta(m).label).join(", "))}">${markers.map(marker => {
      const meta = dlcMarkerMeta(marker);
      return `<span class="game-detail__dlc-marker ${meta.tone}" title="${htmlEscape(meta.label)}" aria-label="${htmlEscape(meta.label)}"><span class="game-detail__dlc-marker-icon">${meta.icon}</span></span>`;
    }).join("")}</span>`;
  }

  /**
   * Renderiza la tabla de DLC con sistema de iconos.
   * @param {Record<string, unknown>|undefined} dlcInfo Información DLC del juego.
   * @returns {string}
   */
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

    const legendItems = [
      "owned", "missing", "skip", "soundtrack", "artbook", "cosmetic", "currency", "pass", "free"
    ].map(key => {
      const meta = dlcMarkerMeta(key);
      return `<span class="game-detail__dlc-legend-item ${meta.tone}" title="${htmlEscape(meta.label)}"><span class="game-detail__dlc-marker-icon">${meta.icon}</span><span>${htmlEscape(meta.label)}</span></span>`;
    }).join("");

    const dlcs = asArray(dlcInfo.dlcs);
    const inferredOwnedCount = dlcs.filter(dlc => getDlcMarkers(dlc).includes("owned") || dlc.owned === true).length;
    const visibleOwnedCount = dlcs.length ? inferredOwnedCount : (dlcInfo.ownedDlcCount || 0);
    const totalDlcCount = dlcInfo.totalDlcCount ?? dlcs.length ?? 0;

    const rows = dlcs.map(dlc => {
      const dlcTitle = dlc.title || dlc.name || "DLC sin nombre";
      const storeLink = dlc.storeUrl || (dlc.appId ? `https://store.steampowered.com/app/${dlc.appId}` : null);
      const titleCell = storeLink
        ? `<a href="${htmlEscape(storeLink)}" target="_blank" rel="noreferrer">${htmlEscape(dlcTitle)}</a>`
        : htmlEscape(dlcTitle);
      const price = dlc.price ? `<span class="game-detail__dlc-muted">${htmlEscape(dlc.price)}</span>` : "";
      const freeBadge = dlc.isFree === true ? `<span class="game-detail__dlc-badge">gratis</span>` : "";
      const importantBadge = dlc.important === true ? `<span class="game-detail__dlc-badge">importante</span>` : "";
      return `<tr>
        <td>${renderDlcMarkers(dlc)}</td>
        <td>${titleCell}<div class="game-detail__dlc-subline">${dlc.appId ? `AppID ${htmlEscape(dlc.appId)}` : ""} ${price} ${freeBadge} ${importantBadge}</div></td>
        <td><code>${htmlEscape(dlc.type || "dlc")}</code></td>
      </tr>`;
    }).join("");

    return `<p><strong>Estado:</strong> <code>${htmlEscape(statusLabel)}</code></p>
      ${summary}
      ${catalogMeta}
      <p><strong>${visibleOwnedCount}</strong> de <strong>${totalDlcCount}</strong> DLC marcados como propios.</p>
      ${missingBlock}
      <div class="game-detail__dlc-legend"><strong>Leyenda:</strong> ${legendItems}</div>
      <table class="game-detail__mini-table game-detail__dlc-table"><thead><tr><th>Iconos</th><th>DLC</th><th>Tipo</th></tr></thead><tbody>${rows || `<tr><td colspan="3">DLC pendiente de clasificar.</td></tr>`}</tbody></table>
      <p class="game-detail__muted">La vista usa solo iconos, no checkboxes ni texto de estado por fila. Para cambiar una fila, edita <code>data/games-metadata.json</code> en <code>dlcInfo.dlcs[].markers</code>. Puede llevar más de un valor, por ejemplo <code>["owned", "pass"]</code>. Valores sugeridos: <code>owned</code>, <code>missing</code>, <code>skip</code>, <code>soundtrack</code>, <code>artbook</code>, <code>cosmetic</code>, <code>currency</code>, <code>pass</code>, <code>free</code>.</p>`;
  }

  /**
   * Renderiza significado personal por perfil.
   * @param {Record<string, unknown>} profileMetadata Metadata de perfiles.
   * @returns {string}
   */
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

  root.innerHTML = `<div class="game-detail game-detail--loading">Cargando ficha…</div>`;

  const possiblePaths = [
    "../assets/data/games-index.json",
    "../../assets/data/games-index.json",
    "assets/data/games-index.json"
  ];

  /**
   * Intenta leer `games-index.json` desde varias rutas porque el nivel de anidamiento cambia.
   * @param {string[]} paths Rutas candidatas.
   * @returns {Promise<unknown[]>}
   */
  function tryFetch(paths) {
    if (!paths.length) return Promise.reject(new Error("No se pudo leer games-index.json desde ninguna ruta conocida."));
    return fetch(paths[0])
      .then(r => r.ok ? r.json() : Promise.reject(new Error(`No se pudo leer ${paths[0]}`)))
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
          <img src="../assets/games/${appId}/steam-header.jpg" alt="${htmlEscape(title)}" loading="lazy" onerror="__steamDetailImgFallback(this)" />
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
