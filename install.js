/* aluy CLI — install block. OS toggle (Linux/macOS · Windows) + copy buttons.
   On Windows: main terminal shows the PowerShell one-liner; a SECOND terminal
   (cmd) appears below with its own copy button. Install host: aluy.dev.
   Single source of truth for the install command (Home + Install pages). */
(function () {
  "use strict";

  var HOST = "aluy.dev";

  // labels follow <html lang>
  var isPt = (document.documentElement.getAttribute("lang") || "en")
    .toLowerCase().indexOf("pt") === 0;
  var L = isPt
    ? { copy: "copiar", copied: "copiado", bash: "bash — instalar aluy", ps: "powershell — instalar aluy" }
    : { copy: "copy", copied: "copied", bash: "bash — install aluy", ps: "powershell — install aluy" };

  var CMD = {
    unix: "curl -fsSL https://" + HOST + "/install.sh | bash",
    win:  "irm https://" + HOST + "/install.ps1 | iex",
    winCmd: 'curl -fsSL https://' + HOST + '/install.cmd -o "%TEMP%\\aluy.cmd" && "%TEMP%\\aluy.cmd"'
  };

  var cmdEl = document.getElementById("cmd");
  if (!cmdEl) return; // page has no install block

  var titleEl  = document.getElementById("term-title");
  var winExtra = document.getElementById("win-extra");
  var cmd2El   = document.getElementById("cmd2");
  var tabs = Array.prototype.slice.call(document.querySelectorAll(".tab"));
  var current = "unix";

  var ICON_COPY  = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect x="9" y="9" width="13" height="13" rx="2"/><path d="M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1"/></svg>';
  var ICON_CHECK = '<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';

  if (cmd2El) cmd2El.textContent = CMD.winCmd;

  function render(os) {
    current = os;
    cmdEl.textContent = (os === "unix") ? CMD.unix : CMD.win;
    if (titleEl) titleEl.textContent = (os === "unix") ? L.bash : L.ps;
    if (winExtra) winExtra.hidden = (os !== "win");
    tabs.forEach(function (t) {
      t.setAttribute("aria-selected", t.dataset.os === os ? "true" : "false");
    });
  }

  function wireCopy(btnId, getText) {
    var btn = document.getElementById(btnId);
    if (!btn) return;
    var lbl  = btn.querySelector(".copy-label");
    var icon = btn.querySelector(".copy-icon");
    var timer = null;
    function reset() {
      if (timer) { clearTimeout(timer); timer = null; }
      btn.classList.remove("copied");
      if (icon) icon.innerHTML = ICON_COPY;
      if (lbl) lbl.textContent = L.copy;
    }
    function done() {
      btn.classList.add("copied");
      if (icon) icon.innerHTML = ICON_CHECK;
      if (lbl) lbl.textContent = L.copied;
      if (timer) clearTimeout(timer);
      timer = setTimeout(reset, 1800);
    }
    btn.addEventListener("click", function () {
      var text = getText();
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done).catch(function () { fallback(text, done); });
      } else {
        fallback(text, done);
      }
    });
    reset();
  }

  function fallback(text, done) {
    var ta = document.createElement("textarea");
    ta.value = text; ta.setAttribute("readonly", "");
    ta.style.position = "absolute"; ta.style.left = "-9999px";
    document.body.appendChild(ta); ta.select();
    try { document.execCommand("copy"); done(); } catch (_) {}
    document.body.removeChild(ta);
  }

  // primary copy (main terminal) + the CTA "copy install command" button
  wireCopy("copy",     function () { return current === "unix" ? CMD.unix : CMD.win; });
  wireCopy("copy-cta", function () { return current === "unix" ? CMD.unix : CMD.win; });
  wireCopy("copy2",    function () { return CMD.winCmd; });

  tabs.forEach(function (t) {
    t.addEventListener("click", function () { render(t.dataset.os); });
  });
  var tablist = document.querySelector('[role="tablist"]');
  if (tablist) {
    tablist.addEventListener("keydown", function (e) {
      if (e.key !== "ArrowRight" && e.key !== "ArrowLeft") return;
      e.preventDefault();
      var idx = tabs.findIndex(function (t) { return t.getAttribute("aria-selected") === "true"; });
      var next = e.key === "ArrowRight" ? (idx + 1) % tabs.length : (idx - 1 + tabs.length) % tabs.length;
      render(tabs[next].dataset.os);
      tabs[next].focus();
    });
  }

  var ua = (navigator.userAgentData && navigator.userAgentData.platform) || navigator.platform || navigator.userAgent || "";
  render(/win/i.test(ua) ? "win" : "unix");
})();
