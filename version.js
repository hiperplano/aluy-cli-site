/* aluy CLI — version badge. Pulls the latest release of hiperplano/aluy-cli from
   the GitHub API (CORS-enabled) and writes it into [data-version]. Includes
   prereleases (RC), so it uses /releases (not /releases/latest, which skips them).
   Caches in localStorage for 1h to spare the 60 req/h anonymous rate limit.
   If anything fails, the static fallback already in the HTML stays. */
(function () {
  "use strict";
  var el = document.querySelector("[data-version]");
  if (!el) return; // only the Home badge has it

  var REPO = "hiperplano/aluy-cli";
  var KEY = "aluy-cli-version";
  var TTL = 3600 * 1000; // 1h

  function render(tag, prerelease) {
    if (!tag) return;
    el.textContent = prerelease ? tag + " · beta" : tag;
  }

  // paint cached value immediately (fresh enough)
  try {
    var c = JSON.parse(localStorage.getItem(KEY) || "null");
    if (c && c.tag && (Date.now() - c.t) < TTL) render(c.tag, c.pre);
  } catch (_) {}

  fetch("https://api.github.com/repos/" + REPO + "/releases?per_page=1", {
    headers: { Accept: "application/vnd.github+json" }
  })
    .then(function (r) { return r.ok ? r.json() : null; })
    .then(function (list) {
      var rel = (list && list.length) ? list[0] : null;
      if (!rel || !rel.tag_name) return;
      render(rel.tag_name, !!rel.prerelease);
      try { localStorage.setItem(KEY, JSON.stringify({ tag: rel.tag_name, pre: !!rel.prerelease, t: Date.now() })); } catch (_) {}
    })
    .catch(function () { /* keep the static fallback */ });
})();
