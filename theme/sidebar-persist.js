/**
 * Steam High Family mdBook — persistencia de ancho del sidebar.
 *
 * Permite redimensionar el sidebar de mdBook y guardar el ancho en `localStorage` para que
 * no se resetee al cambiar de página.
 */
(() => {
  const STORAGE_KEY = "steam-high-mdbook-sidebar-width-v6-5-7";
  const MIN_WIDTH = 220;
  const MAX_WIDTH = 620;
  const DEFAULT_WIDTH = 300;

  let isDragging = false;

  function clamp(width) {
    const value = Number.parseInt(width, 10);

    if (Number.isNaN(value)) {
      return DEFAULT_WIDTH;
    }

    return Math.min(Math.max(value, MIN_WIDTH), MAX_WIDTH);
  }

  function readSavedWidth() {
    return clamp(window.localStorage.getItem(STORAGE_KEY));
  }

  function readCurrentWidth() {
    const rootValue = window
      .getComputedStyle(document.documentElement)
      .getPropertyValue("--sidebar-width")
      .trim();

    if (rootValue) {
      return clamp(rootValue);
    }

    const sidebar = document.getElementById("sidebar");

    if (sidebar) {
      return clamp(sidebar.getBoundingClientRect().width);
    }

    return DEFAULT_WIDTH;
  }

  function applyWidth(width) {
    const safeWidth = clamp(width);
    const sidebar = document.getElementById("sidebar");

    document.documentElement.style.setProperty("--sidebar-width", `${safeWidth}px`);

    if (sidebar) {
      sidebar.style.width = `${safeWidth}px`;
    }

    return safeWidth;
  }

  function saveWidth(width) {
    const safeWidth = clamp(width);
    window.localStorage.setItem(STORAGE_KEY, String(safeWidth));
    return safeWidth;
  }

  function saveCurrentWidth() {
    saveWidth(readCurrentWidth());
  }

  function bindResizeHandle() {
    const handle = document.getElementById("sidebar-resize-handle");

    if (!handle) {
      return;
    }

    handle.addEventListener(
      "pointerdown",
      (event) => {
        if (event.button !== undefined && event.button !== 0) {
          return;
        }

        isDragging = true;
        document.body.classList.add("steam-sidebar-resizing");
        handle.setPointerCapture?.(event.pointerId);
        event.preventDefault();
      },
      true
    );

    window.addEventListener(
      "pointermove",
      (event) => {
        if (!isDragging) {
          return;
        }

        applyWidth(event.clientX);
      },
      true
    );

    window.addEventListener(
      "pointerup",
      (event) => {
        if (!isDragging) {
          return;
        }

        isDragging = false;
        document.body.classList.remove("steam-sidebar-resizing");
        saveCurrentWidth();
        handle.releasePointerCapture?.(event.pointerId);
      },
      true
    );
  }

  function bindPassivePersistence() {
    ["mouseup", "touchend", "resize", "beforeunload"].forEach((eventName) => {
      window.addEventListener(eventName, saveCurrentWidth, true);
    });
  }

  function boot() {
    const savedWidth = readSavedWidth();

    applyWidth(savedWidth);
    bindResizeHandle();
    bindPassivePersistence();

    // mdBook termina de aplicar su layout después del render inicial.
    // Reaplicamos el ancho guardado para evitar que se pierda al navegar.
    window.setTimeout(() => applyWidth(savedWidth), 50);
    window.setTimeout(() => applyWidth(readSavedWidth()), 250);
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot);
  } else {
    boot();
  }
})();
