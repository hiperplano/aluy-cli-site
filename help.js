/* aluy CLI — docs (split layout). Scroll-spy na JANELA: quem rola e a pagina,
   e a barra lateral fica grudada (position:sticky). Antes rolava o painel, e o
   rodape ficava preso dentro dele.
   O spy: highlights the active TOC link in #docs-sidebar, smooth-scrolls
   the pane on click (offset -18px), and keeps the active link in view. */
(function () {
  "use strict";

  document.addEventListener("DOMContentLoaded", function () {
    var pane = document.getElementById("docs-content");
    var sidebar = document.getElementById("docs-sidebar");
    if (!pane || !sidebar) return;

    // The sidebar mixes local anchors with cross-page links (the reference on
    // comandos.html). Only the local ones drive the scroll-spy; all of them
    // stay searchable and clickable.
    var allLinks = Array.prototype.slice.call(sidebar.querySelectorAll("a[href]"));
    function localHash(a) {
      var href = a.getAttribute("href") || "";
      return href.charAt(0) === "#" ? href.slice(1) : null;
    }
    var links = allLinks.filter(function (a) { return localHash(a); });
    if (!links.length) return;

    var sections = [];
    links.forEach(function (a) {
      var sec = document.getElementById(localHash(a));
      if (sec) sections.push({ a: a, sec: sec });
    });
    // TOC order ≠ DOM order (e.g. Turbo/Artifacts groups); the spy walks this
    // list top-down, so sort by document position
    sections.sort(function (x, y) {
      return x.sec.compareDocumentPosition(y.sec) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1;
    });

    // --- docs search: filter the TOC by section heading + content ---
    var searchEl = document.getElementById("docs-search");
    var noRes = document.getElementById("docs-noresults");
    if (searchEl) {
      // index every sidebar link: local ones by their section's text, the
      // cross-page ones by their own label
      var index = allLinks.map(function (a) {
        var id = localHash(a);
        var sec = id ? document.getElementById(id) : null;
        return { a: a, text: ((a.textContent || "") + " " + (sec ? sec.textContent : "")).toLowerCase() };
      });
      var groups = Array.prototype.slice.call(sidebar.querySelectorAll(".docs-group"));
      function syncGroups() {
        // hide a group header when every link until the next header is hidden
        groups.forEach(function (g) {
          var any = false;
          for (var n = g.nextElementSibling; n && !n.classList.contains("docs-group"); n = n.nextElementSibling) {
            if (n.tagName === "A" && !n.hidden) { any = true; break; }
          }
          g.hidden = !any;
        });
      }
      searchEl.addEventListener("input", function () {
        var q = searchEl.value.trim().toLowerCase();
        var shown = 0;
        index.forEach(function (it) {
          var hit = !q || it.text.indexOf(q) !== -1;
          it.a.hidden = !hit;
          if (hit) shown++;
        });
        syncGroups();
        if (noRes) noRes.hidden = !(q && shown === 0);
      });
      searchEl.addEventListener("keydown", function (e) {
        if (e.key === "Escape") { searchEl.value = ""; searchEl.dispatchEvent(new Event("input")); }
      });
    }

    function setActive(entry) {
      links.forEach(function (a) { a.classList.remove("active"); a.removeAttribute("aria-current"); });
      if (!entry) return;
      entry.a.classList.add("active");
      entry.a.setAttribute("aria-current", "location");
      // keep the active link visible in the sidebar
      var ar = entry.a.getBoundingClientRect();
      var sr = sidebar.getBoundingClientRect();
      if (ar.top < sr.top + 8 || ar.bottom > sr.bottom - 8) {
        entry.a.scrollIntoView({ block: "nearest" });
      }
    }

    var ticking = false;
    function compute() {
      ticking = false;
      var line = 130; // linha de leitura, medida da borda de cima da janela
      var current = sections[0];
      // bottom of pane → force last section
      if (window.innerHeight + window.scrollY >= document.body.scrollHeight - 4) {
        current = sections[sections.length - 1];
      } else {
        for (var i = 0; i < sections.length; i++) {
          if (sections[i].sec.getBoundingClientRect().top <= line) current = sections[i];
          else break;
        }
      }
      setActive(current);
    }
    function onScroll() {
      if (!ticking) { ticking = true; window.requestAnimationFrame(compute); }
    }

    window.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll);

    links.forEach(function (a) {
      a.addEventListener("click", function (e) {
        var sec = document.getElementById(localHash(a));
        if (!sec) return;
        e.preventDefault();
        // scrollIntoView + scroll-margin-top (site.css): manual rect math breaks
        // under the html zoom (rects are zoomed, scrollTop isn't)
        sec.scrollIntoView({ behavior: "smooth", block: "start" });
        if (history.replaceState) history.replaceState(null, "", a.getAttribute("href"));
      });
    });

    // initial: honor hash, else first
    var initial = sections[0];
    if (location.hash) {
      var match = sections.filter(function (s) { return "#" + s.sec.id === location.hash; })[0];
      if (match) {
        initial = match;
        match.sec.scrollIntoView({ behavior: "auto", block: "start" });
      }
    }
    setActive(initial);
  });
})();
