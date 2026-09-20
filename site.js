/* aluy CLI — site (dark-only, Aluy DS dark theme). No theme switcher.
   1) mobile nav toggle.
   2) dynamic version: writes the latest release of hiperplano/aluy-cli into every
      [data-version] element (hero badge + header pill). Uses /releases (includes
      prereleases/RC; /releases/latest skips them). Cached 1h; static fallback kept.
      data-version="tag" → just the tag (header pill); "beta" → only the stage,
      hidden once the release is stable; anything else → "tag · beta" while pre-1.0.
      "beta" comes from the TAG (SemVer: a `-` means prerelease), not from GitHub's
      prerelease FLAG: the flag is a release-CHANNEL decision (it drives the "Latest"
      badge, and while there is no stable the rc IS the current release, so the flag is
      false), while what the visitor needs to know is whether the build is pre-1.0. */
(function () {
  "use strict";
  document.addEventListener("DOMContentLoaded", function () {
    // --- mobile nav ---
    var toggle = document.querySelector(".nav-toggle");
    var nav = document.querySelector(".nav");
    if (toggle && nav) {
      toggle.addEventListener("click", function () {
        var open = nav.classList.toggle("open");
        toggle.setAttribute("aria-expanded", open ? "true" : "false");
      });
    }

    // --- dynamic version badge/pill ---
    var els = document.querySelectorAll("[data-version]");
    if (!els.length) return;
    var REPO = "hiperplano/aluy-cli", KEY = "aluy-cli-version", TTL = 3600 * 1000;

    function paint(tag) {
      if (!tag) return;
      var pre = tag.indexOf("-") !== -1; // SemVer prerelease (v1.0.0-rc.N)
      els.forEach(function (el) {
        var modo = el.getAttribute("data-version");
        if (modo === "tag") { el.textContent = tag; return; }
        if (modo === "beta") {
          // o numero ja esta fixo na pilula do topo; aqui so o estagio.
          if (pre) { el.textContent = "beta"; }
          else { var selo = el.closest(".badge") || el; selo.style.display = "none"; }
          return;
        }
        el.textContent = pre ? tag + " · beta" : tag;
      });
    }

    try {
      var c = JSON.parse(localStorage.getItem(KEY) || "null");
      if (c && c.tag && (Date.now() - c.t) < TTL) paint(c.tag);
    } catch (_) {}

    fetch("https://api.github.com/repos/" + REPO + "/releases?per_page=1", {
      headers: { Accept: "application/vnd.github+json" }
    })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (list) {
        var rel = (list && list.length) ? list[0] : null;
        if (!rel || !rel.tag_name) return;
        paint(rel.tag_name);
        try { localStorage.setItem(KEY, JSON.stringify({ tag: rel.tag_name, t: Date.now() })); } catch (_) {}
      })
      .catch(function () { /* keep static fallback */ });
  });
})();

/* --- tema claro/escuro -----------------------------------------------------
   Segue a preferência do sistema por padrão. O botão .theme-toggle fixa a
   escolha em data-theme e guarda no localStorage. */
(function () {
  "use strict";
  var KEY = "aluy-site-theme";
  var root = document.documentElement;
  try {
    var salvo = localStorage.getItem(KEY);
    if (salvo === "dark" || salvo === "light") root.setAttribute("data-theme", salvo);
  } catch (_) {}
  document.addEventListener("DOMContentLoaded", function () {
    var btn = document.querySelector(".theme-toggle");
    if (!btn) return;
    btn.addEventListener("click", function () {
      var escuroAgora = root.getAttribute("data-theme") === "dark" ||
        (!root.hasAttribute("data-theme") &&
          window.matchMedia("(prefers-color-scheme: dark)").matches);
      var proximo = escuroAgora ? "light" : "dark";
      root.setAttribute("data-theme", proximo);
      try { localStorage.setItem(KEY, proximo); } catch (_) {}
    });
  });
})();

/* A gravacao da home toca sozinha, muda e em laco. Quem pediu menos movimento
   no sistema recebe ela parada, com os controles para tocar se quiser. */
(function () {
  "use strict";
  document.addEventListener("DOMContentLoaded", function () {
    var v = document.querySelector(".proof-video");
    if (!v) return;
    var menos = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)");
    if (menos && menos.matches) { v.removeAttribute("autoplay"); v.pause(); v.currentTime = 0; return; }

    // Varri a gravacao inteira medindo pixels acesos: os primeiros 20s tem
    // pouco na tela e o miolo (22s a 62s) e o trecho denso. O laco comeca la,
    // e volta pra la em vez de voltar pro zero.
    var INICIO = 22;
    function daInicio() { if (v.currentTime < INICIO) { try { v.currentTime = INICIO; } catch (_) {} } }
    // mover o currentTime interrompe o autoplay, entao religamos UMA vez.
    // depois disso quem manda e o usuario: se ele pausar, fica pausado.
    var religado = false;
    function toca() {
      if (religado) return;
      religado = true;
      var p = v.play();
      if (p && p.catch) p.catch(function () {});
    }
    if (v.readyState >= 1) daInicio();
    else v.addEventListener("loadedmetadata", daInicio, { once: true });
    v.addEventListener("seeked", toca);
    v.addEventListener("canplay", toca);
    v.addEventListener("timeupdate", function () {
      // o loop nativo volta pro 0; devolvemos pro ponto util
      if (v.currentTime < INICIO - 1) daInicio();
    });
  });
})();
