/* ============================================================================
   Aluy CLI — cookie consent + Google Analytics loader.
   GA (G-PPT1WQQWHY) only loads after the visitor accepts. Choice is kept in
   localStorage ('aluy-consent': 'granted' | 'denied'). Shared by EN and /pt
   pages; language picked from <html lang>. window.aluyConsent.reset() clears
   the choice and shows the banner again.
   ========================================================================== */
(function () {
  var GA_ID = 'G-PPT1WQQWHY';
  var KEY = 'aluy-consent';
  var isPT = (document.documentElement.lang || '').toLowerCase().indexOf('pt') === 0;

  var T = isPT ? {
    text: 'Usamos cookies do Google Analytics para medir o uso do site. Nenhum dado é usado para publicidade.',
    more: 'Saiba mais',
    accept: 'Aceitar',
    decline: 'Recusar'
  } : {
    text: 'We use Google Analytics cookies to measure site usage. No data is used for advertising.',
    more: 'Learn more',
    accept: 'Accept',
    decline: 'Decline'
  };

  function loadGA() {
    var s = document.createElement('script');
    s.async = true;
    s.src = 'https://www.googletagmanager.com/gtag/js?id=' + GA_ID;
    document.head.appendChild(s);
    window.dataLayer = window.dataLayer || [];
    window.gtag = function () { window.dataLayer.push(arguments); };
    window.gtag('js', new Date());
    window.gtag('config', GA_ID, { anonymize_ip: true });
  }

  function save(choice) {
    try { localStorage.setItem(KEY, choice); } catch (e) { /* private mode */ }
  }

  function stored() {
    try { return localStorage.getItem(KEY); } catch (e) { return null; }
  }

  function showBanner() {
    var css =
      '#aluy-consent{position:fixed;left:16px;right:16px;bottom:16px;z-index:9999;' +
      'margin:0 auto;max-width:680px;display:flex;flex-wrap:wrap;gap:12px;align-items:center;' +
      'padding:16px 18px;border-radius:12px;' +
      'background:var(--s1,#0F0F0F);border:1px solid var(--bd-strong,rgba(255,255,255,.16));' +
      'box-shadow:0 12px 40px rgba(0,0,0,.55);' +
      'font-family:var(--ui,system-ui,sans-serif);font-size:13.5px;line-height:1.5;color:var(--tx2,#ABABAB)}' +
      '#aluy-consent p{margin:0;flex:1 1 300px}' +
      '#aluy-consent a{color:var(--amber,#DDA13F);text-decoration:none}' +
      '#aluy-consent a:hover{text-decoration:underline}' +
      '#aluy-consent .aluy-consent-actions{display:flex;gap:8px;flex:0 0 auto;margin-left:auto}' +
      '#aluy-consent button{font-family:inherit;font-size:13px;font-weight:600;cursor:pointer;' +
      'padding:8px 16px;border-radius:8px;border:1px solid transparent}' +
      '#aluy-consent .aluy-accept{background:var(--amber,#DDA13F);color:var(--ink,#0E0C09)}' +
      '#aluy-consent .aluy-accept:hover{filter:brightness(1.08)}' +
      '#aluy-consent .aluy-decline{background:transparent;color:var(--mut,#9A9A9A);' +
      'border-color:var(--bd,rgba(255,255,255,.10))}' +
      '#aluy-consent .aluy-decline:hover{color:var(--tx,#F4F4F4);border-color:var(--bd-strong,rgba(255,255,255,.16))}';

    var style = document.createElement('style');
    style.textContent = css;
    document.head.appendChild(style);

    var el = document.createElement('div');
    el.id = 'aluy-consent';
    el.setAttribute('role', 'dialog');
    el.setAttribute('aria-live', 'polite');
    el.innerHTML =
      '<p>' + T.text + ' <a href="termos.html">' + T.more + '</a></p>' +
      '<div class="aluy-consent-actions">' +
      '<button type="button" class="aluy-decline">' + T.decline + '</button>' +
      '<button type="button" class="aluy-accept">' + T.accept + '</button>' +
      '</div>';

    el.querySelector('.aluy-accept').addEventListener('click', function () {
      save('granted');
      el.remove();
      loadGA();
    });
    el.querySelector('.aluy-decline').addEventListener('click', function () {
      save('denied');
      el.remove();
    });

    document.body.appendChild(el);
  }

  window.aluyConsent = {
    reset: function () {
      try { localStorage.removeItem(KEY); } catch (e) {}
      var old = document.getElementById('aluy-consent');
      if (old) old.remove();
      showBanner();
    }
  };

  function init() {
    var choice = stored();
    if (choice === 'granted') { loadGA(); return; }
    if (choice === 'denied') { return; }
    showBanner();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
