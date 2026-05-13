/**
 * Steam High Family mdBook — tooltips flotantes de juegos.
 *
 * Lee elementos `.game-hover`, crea un preview flotante fuera de tablas para evitar clipping
 * y posiciona la tarjeta según el viewport. No modifica datos; solo mejora navegación visual.
 */
(() => {
  const SELECTOR = ".game-hover";

  let preview = null;
  let activeTarget = null;

  function ensurePreview() {
    if (preview) return preview;

    preview = document.createElement("div");
    preview.className = "game-floating-preview";
    preview.setAttribute("aria-hidden", "true");
    preview.innerHTML = `
      <img class="game-floating-preview__img" alt="" />
      <div class="game-floating-preview__title"></div>
    `;
    document.body.appendChild(preview);
    return preview;
  }

  function getPreviewData(target) {
    const imgFromData = target.getAttribute("data-preview-src");
    const titleFromData = target.getAttribute("data-game-title");

    const innerCard = target.querySelector(".game-hover-card");
    const innerImg = innerCard ? innerCard.querySelector("img") : null;
    const innerTitle = innerCard ? innerCard.querySelector("strong") : null;

    const link = target.querySelector("a");

    return {
      src: imgFromData || (innerImg ? innerImg.getAttribute("src") : ""),
      title:
        titleFromData ||
        (innerTitle ? innerTitle.textContent.trim() : "") ||
        (link ? link.textContent.trim() : "")
    };
  }

  function movePreview(event) {
    if (!preview || !preview.classList.contains("is-visible")) return;

    const margin = 18;
    const previewRect = preview.getBoundingClientRect();
    let x = event.clientX + margin;
    let y = event.clientY + margin;

    if (x + previewRect.width > window.innerWidth - 8) {
      x = event.clientX - previewRect.width - margin;
    }

    if (y + previewRect.height > window.innerHeight - 8) {
      y = event.clientY - previewRect.height - margin;
    }

    x = Math.max(8, x);
    y = Math.max(8, y);

    preview.style.left = `${x}px`;
    preview.style.top = `${y}px`;
  }

  function showPreview(target, event) {
    const data = getPreviewData(target);
    if (!data.src) return;

    const node = ensurePreview();
    const img = node.querySelector(".game-floating-preview__img");
    const title = node.querySelector(".game-floating-preview__title");

    img.src = data.src;
    img.alt = data.title || "Preview";
    title.textContent = data.title || "";

    activeTarget = target;
    node.classList.add("is-visible");
    movePreview(event);
  }

  function hidePreview(target) {
    if (activeTarget && target && activeTarget !== target) return;

    activeTarget = null;

    if (preview) {
      preview.classList.remove("is-visible");
    }
  }

  document.addEventListener("pointerover", (event) => {
    const target = event.target.closest(SELECTOR);
    if (!target) return;
    showPreview(target, event);
  });

  document.addEventListener("pointermove", (event) => {
    if (!activeTarget) return;
    movePreview(event);
  });

  document.addEventListener("pointerout", (event) => {
    const target = event.target.closest(SELECTOR);
    if (!target) return;

    if (event.relatedTarget && target.contains(event.relatedTarget)) return;

    hidePreview(target);
  });

  document.addEventListener("focusin", (event) => {
    const target = event.target.closest(SELECTOR);
    if (!target) return;

    const rect = target.getBoundingClientRect();
    showPreview(target, {
      clientX: rect.left,
      clientY: rect.bottom
    });
  });

  document.addEventListener("focusout", (event) => {
    const target = event.target.closest(SELECTOR);
    if (!target) return;
    hidePreview(target);
  });

  document.addEventListener("scroll", () => {
    if (preview) preview.classList.remove("is-visible");
  }, true);
})();
