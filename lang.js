/* aluy CLI — site i18n (EN default at root, PT-BR under /pt/).
   - Marks the active language in the .lang-toggle.
   - Persists the choice in localStorage ("aluy-site-lang": "en" | "pt").
   - Light preference redirect on load: if a saved lang differs from the page's
     language, send the visitor to the equivalent page in the other language.
   First visit with no preference stays on EN (the default). Loop-safe. */
(function () {
  "use strict";

  var KEY = "aluy-site-lang"; // "en" | "pt"

  // The page declares its own language on <html lang>.
  var pageLang = (document.documentElement.getAttribute("lang") || "en")
    .toLowerCase().indexOf("pt") === 0 ? "pt" : "en";

  function read() {
    try {
      var v = localStorage.getItem(KEY);
      if (v === "en" || v === "pt") return v;
    } catch (_) {}
    return null;
  }
  function write(v) {
    try { localStorage.setItem(KEY, v); } catch (_) {}
  }

  // Map the current path to its counterpart in the other language.
  // EN lives at root (/, /funcionalidades.html …); PT lives under /pt/.
  // Returns null when there is no sensible counterpart.
  function counterpartPath(targetLang) {
    var path = location.pathname;
    // normalize a bare directory to its index
    var isDir = /\/$/.test(path);
    var file = isDir ? "index.html" : path.split("/").pop();
    // strip the directory part
    var dir = path.slice(0, path.length - (isDir ? 0 : file.length));
    // dir ends with "/"; detect a trailing /pt/
    var inPt = /\/pt\/$/.test(dir);
    var base = inPt ? dir.replace(/pt\/$/, "") : dir;

    if (targetLang === "pt") return base + "pt/" + (file || "index.html");
    return base + (file || "index.html");
  }

  // ----- redirect by saved preference (runs before paint where possible) -----
  var saved = read();
  if (saved && saved !== pageLang) {
    var dest = counterpartPath(saved);
    if (dest && dest !== location.pathname) {
      location.replace(dest + location.hash);
      return; // stop; the new page takes over
    }
  }

  document.addEventListener("DOMContentLoaded", function () {
    var toggle = document.querySelector(".lang-toggle");
    if (!toggle) return;

    var links = toggle.querySelectorAll("a[data-lang]");
    Array.prototype.forEach.call(links, function (a) {
      var lang = a.getAttribute("data-lang");
      a.setAttribute("aria-current", lang === pageLang ? "true" : "false");
      a.addEventListener("click", function () {
        // record the choice; the href already points to the counterpart page
        write(lang);
      });
    });
  });
})();
