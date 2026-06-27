/* aluy CLI — docs (split layout). Scroll-spy on the CONTENT pane (#docs-content),
   not the window: highlights the active TOC link in #docs-sidebar, smooth-scrolls
   the pane on click (offset -18px), and keeps the active link in view. */
(function () {
  "use strict";

  document.addEventListener("DOMContentLoaded", function () {
    var pane = document.getElementById("docs-content");
    var sidebar = document.getElementById("docs-sidebar");
    if (!pane || !sidebar) return;

    var links = Array.prototype.slice.call(sidebar.querySelectorAll('a[href^="#"]'));
    if (!links.length) return;

    var sections = [];
    links.forEach(function (a) {
      var sec = document.getElementById(a.getAttribute("href").slice(1));
      if (sec) sections.push({ a: a, sec: sec });
    });

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
      var line = pane.getBoundingClientRect().top + 110; // reading line near pane top
      var current = sections[0];
      // bottom of pane → force last section
      if (pane.scrollTop + pane.clientHeight >= pane.scrollHeight - 4) {
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

    pane.addEventListener("scroll", onScroll, { passive: true });
    window.addEventListener("resize", onScroll);

    links.forEach(function (a) {
      a.addEventListener("click", function (e) {
        var sec = document.getElementById(a.getAttribute("href").slice(1));
        if (!sec) return;
        e.preventDefault();
        var top = sec.getBoundingClientRect().top - pane.getBoundingClientRect().top + pane.scrollTop - 18;
        pane.scrollTo({ top: top, behavior: "smooth" });
        if (history.replaceState) history.replaceState(null, "", a.getAttribute("href"));
      });
    });

    // initial: honor hash, else first
    var initial = sections[0];
    if (location.hash) {
      var match = sections.filter(function (s) { return "#" + s.sec.id === location.hash; })[0];
      if (match) {
        initial = match;
        var top = match.sec.getBoundingClientRect().top - pane.getBoundingClientRect().top + pane.scrollTop - 18;
        pane.scrollTop = top;
      }
    }
    setActive(initial);
  });
})();
