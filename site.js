/* aluy CLI — site (dark-only, Aluy DS dark theme). No theme switcher.
   1) mobile nav toggle.
   2) dynamic version: writes the latest release of hiperplano/aluy-cli into every
      [data-version] element (hero badge + header pill). Uses /releases (includes
      prereleases/RC; /releases/latest skips them). Cached 1h; static fallback kept.
      data-version="tag" → just the tag; otherwise → "tag · beta" when prerelease. */
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

    function paint(tag, pre) {
      if (!tag) return;
      els.forEach(function (el) {
        el.textContent = (el.getAttribute("data-version") === "tag")
          ? tag
          : (pre ? tag + " · beta" : tag);
      });
    }

    try {
      var c = JSON.parse(localStorage.getItem(KEY) || "null");
      if (c && c.tag && (Date.now() - c.t) < TTL) paint(c.tag, c.pre);
    } catch (_) {}

    fetch("https://api.github.com/repos/" + REPO + "/releases?per_page=1", {
      headers: { Accept: "application/vnd.github+json" }
    })
      .then(function (r) { return r.ok ? r.json() : null; })
      .then(function (list) {
        var rel = (list && list.length) ? list[0] : null;
        if (!rel || !rel.tag_name) return;
        paint(rel.tag_name, !!rel.prerelease);
        try { localStorage.setItem(KEY, JSON.stringify({ tag: rel.tag_name, pre: !!rel.prerelease, t: Date.now() })); } catch (_) {}
      })
      .catch(function () { /* keep static fallback */ });
  });
})();
