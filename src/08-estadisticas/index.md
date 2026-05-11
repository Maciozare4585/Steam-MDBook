# 📊 Estadísticas de la biblioteca

<div id="stats-root"><p style="opacity:.6;font-style:italic">Cargando estadísticas…</p></div>

<script>
(function () {
  const root = document.getElementById("stats-root");
  if (!root) return;

  const paths = [
    "../assets/data/games-index.json",
    "../../assets/data/games-index.json",
    "assets/data/games-index.json"
  ];

  function tryFetch(ps) {
    if (!ps.length) return Promise.reject(new Error("No se encontró games-index.json"));
    return fetch(ps[0]).then(r => r.ok ? r.json() : Promise.reject()).catch(() => tryFetch(ps.slice(1)));
  }

  function pct(n, total) {
    return total ? Math.round((n / total) * 100) : 0;
  }

  function bar(value, max, color) {
    const w = max ? Math.round((value / max) * 100) : 0;
    return `<div style="background:rgba(128,128,128,.15);border-radius:999px;height:8px;overflow:hidden;margin:.2rem 0 .45rem">
              <div style="background:${color};width:${w}%;height:100%;border-radius:999px;transition:width .4s"></div>
            </div>`;
  }

  tryFetch(paths).then(games => {
    const total = games.length;

    // Estados personales
    const stateMap = {};
    games.forEach(g => {
      const s = (g.playerState && g.playerState.mainStatus) || "sin-estado";
      stateMap[s] = (stateMap[s] || 0) + 1;
    });

    // Modos
    const sp  = games.filter(g => g.playModes && g.playModes.singlePlayer === true).length;
    const mp  = games.filter(g => g.playModes && g.playModes.onlineMultiplayer === true).length;
    const coo = games.filter(g => g.playModes && (g.playModes.onlineCoop === true || g.playModes.localCoop === true)).length;
    const vr  = games.filter(g => g.steamFeatures && g.steamFeatures.vrSupported === true).length;

    // Checkboxes
    const fav       = games.filter(g => g.playerState && g.playerState.checkboxes && g.playerState.checkboxes.favorite).length;
    const finished  = games.filter(g => g.playerState && g.playerState.checkboxes && g.playerState.checkboxes.finishedMainStory).length;
    const abandoned = games.filter(g => g.playerState && g.playerState.checkboxes && g.playerState.checkboxes.abandoned).length;
    const platinum  = games.filter(g => g.playerState && g.playerState.checkboxes && g.playerState.checkboxes.completed100Percent).length;
    const withMeta  = games.filter(g => g.steamMetadata && g.steamMetadata.genres && g.steamMetadata.genres.length > 0).length;

    // Géneros top
    const genreCount = {};
    games.forEach(g => {
      ((g.steamMetadata && g.steamMetadata.genres) || []).forEach(genre => {
        genreCount[genre] = (genreCount[genre] || 0) + 1;
      });
    });
    const topGenres = Object.entries(genreCount)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 8);
    const maxGenre = topGenres.length ? topGenres[0][1] : 1;

    // Render
    const stateLabels = {
      "jugando": "🎮 Jugando ahora",
      "terminado": "✅ Terminados",
      "sin-terminar": "🔄 Sin terminar",
      "nuevo": "📦 Nuevo / por jugar",
      "abandonado": "⏸ Abandonados",
      "replay": "🔁 Replay pendiente",
      "platinar": "🏆 Para platinar",
      "sin-estado": "❓ Sin estado"
    };

    const stateColors = {
      "jugando": "#4f8cff",
      "terminado": "#34d399",
      "sin-terminar": "#fbbf24",
      "nuevo": "#a78bfa",
      "abandonado": "#f87171",
      "replay": "#22d3ee",
      "platinar": "#f59e0b",
      "sin-estado": "#6b7280"
    };

    const stateRows = Object.entries(stateMap)
      .sort((a, b) => b[1] - a[1])
      .map(([s, n]) => {
        const label = stateLabels[s] || s;
        const color = stateColors[s] || "#6b7280";
        return `<div style="margin:.65rem 0">
          <div style="display:flex;justify-content:space-between;font-size:.92rem">
            <span>${label}</span>
            <strong>${n} <span style="opacity:.6;font-weight:400">(${pct(n, total)}%)</span></strong>
          </div>
          ${bar(n, total, color)}
        </div>`;
      }).join("");

    const genreRows = topGenres.map(([g, n]) =>
      `<div style="margin:.55rem 0">
        <div style="display:flex;justify-content:space-between;font-size:.9rem">
          <span>${g}</span><strong>${n}</strong>
        </div>
        ${bar(n, maxGenre, "#4f8cff")}
      </div>`
    ).join("") || `<p style="opacity:.6">Metadata de géneros pendiente de enriquecer.</p>`;

    root.innerHTML = `
      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:1rem;margin:1.2rem 0">
        <div class="callout" style="text-align:center">
          <div style="font-size:2.2rem;font-weight:800">${total}</div>
          <div style="opacity:.75">Juegos en biblioteca</div>
        </div>
        <div class="callout" style="text-align:center">
          <div style="font-size:2.2rem;font-weight:800">${finished}</div>
          <div style="opacity:.75">Historias terminadas</div>
        </div>
        <div class="callout" style="text-align:center">
          <div style="font-size:2.2rem;font-weight:800">${fav}</div>
          <div style="opacity:.75">Favoritos</div>
        </div>
        <div class="callout" style="text-align:center">
          <div style="font-size:2.2rem;font-weight:800">${platinum}</div>
          <div style="opacity:.75">100% / Platinados</div>
        </div>
        <div class="callout" style="text-align:center">
          <div style="font-size:2.2rem;font-weight:800">${abandoned}</div>
          <div style="opacity:.75">Abandonados</div>
        </div>
        <div class="callout" style="text-align:center">
          <div style="font-size:2.2rem;font-weight:800">${pct(withMeta, total)}%</div>
          <div style="opacity:.75">Con metadata Steam</div>
        </div>
      </div>

      <div style="display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:1.5rem;margin-top:1.5rem">

        <div class="game-detail__panel">
          <h3 style="margin-top:0">📈 Estados personales</h3>
          ${stateRows}
        </div>

        <div class="game-detail__panel">
          <h3 style="margin-top:0">🎮 Modos de juego</h3>
          <div style="margin:.65rem 0">
            <div style="display:flex;justify-content:space-between;font-size:.92rem">
              <span>Single-player</span><strong>${sp} (${pct(sp, total)}%)</strong>
            </div>
            ${bar(sp, total, "#4f8cff")}
          </div>
          <div style="margin:.65rem 0">
            <div style="display:flex;justify-content:space-between;font-size:.92rem">
              <span>Online Multiplayer</span><strong>${mp} (${pct(mp, total)}%)</strong>
            </div>
            ${bar(mp, total, "#34d399")}
          </div>
          <div style="margin:.65rem 0">
            <div style="display:flex;justify-content:space-between;font-size:.92rem">
              <span>Co-op (local u online)</span><strong>${coo} (${pct(coo, total)}%)</strong>
            </div>
            ${bar(coo, total, "#fbbf24")}
          </div>
          <div style="margin:.65rem 0">
            <div style="display:flex;justify-content:space-between;font-size:.92rem">
              <span>🥽 VR</span><strong>${vr}</strong>
            </div>
            ${bar(vr, total, "#a78bfa")}
          </div>
          <p style="font-size:.83rem;opacity:.6;margin-top:.8rem">
            Los modos solo se cuentan cuando están confirmados como <code>true</code>.<br>
            Los valores <code>null</code> son juegos sin metadata aún.
          </p>
        </div>

        <div class="game-detail__panel">
          <h3 style="margin-top:0">🏷️ Géneros más frecuentes</h3>
          ${genreRows}
          ${topGenres.length ? `<p style="font-size:.83rem;opacity:.6;margin-top:.8rem">Solo juegos con metadata enriquecida (${withMeta} de ${total}).</p>` : ""}
        </div>

      </div>
    `;
  }).catch(e => {
    root.innerHTML = `<p style="opacity:.65;color:#f87171">No se pudieron cargar las estadísticas: ${e.message}</p>`;
  });
})();
</script>
