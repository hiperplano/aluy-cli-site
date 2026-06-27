/* aluy CLI — site: dark-only (Aluy DS dark theme). No theme switcher.
   Only behavior here is the mobile nav toggle. i18n lives in lang.js. */
(function () {
  "use strict";
  document.addEventListener("DOMContentLoaded", function () {
    var toggle = document.querySelector(".nav-toggle");
    var nav = document.querySelector(".nav");
    if (toggle && nav) {
      toggle.addEventListener("click", function () {
        var open = nav.classList.toggle("open");
        toggle.setAttribute("aria-expanded", open ? "true" : "false");
      });
    }
  });
})();
