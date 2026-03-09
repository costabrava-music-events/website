/* Costa Brava Music Events — GA4 + conversion events */
(() => {
  // Set your real GA4 Measurement ID, e.g. G-ABC123XYZ.
  const GA4_ID = "G-3LVTS738CB";
  const isConfigured = /^G-[A-Z0-9]+$/i.test(GA4_ID) && GA4_ID !== "G-XXXXXXXXXX";
  if (!isConfigured) return;

  const script = document.createElement("script");
  script.async = true;
  script.src = `https://www.googletagmanager.com/gtag/js?id=${GA4_ID}`;
  document.head.appendChild(script);

  window.dataLayer = window.dataLayer || [];
  function gtag() {
    window.dataLayer.push(arguments);
  }
  window.gtag = gtag;

  gtag("js", new Date());
  gtag("config", GA4_ID, {
    anonymize_ip: true,
    allow_google_signals: true,
  });

  const track = (name, params = {}) => {
    if (typeof window.gtag !== "function") return;
    window.gtag("event", name, params);
  };

  document.addEventListener("click", (event) => {
    const link = event.target.closest("a[href]");
    if (!link) return;

    const href = link.getAttribute("href") || "";
    const label = (link.textContent || "").trim().slice(0, 120);

    if (href.startsWith("tel:")) {
      track("contact_phone_click", { link_url: href, link_text: label });
      return;
    }

    if (href.startsWith("mailto:")) {
      track("contact_email_click", { link_url: href, link_text: label });
      return;
    }

    if (href.includes("instagram.com/costabrava_music_events")) {
      track("instagram_click", { link_url: href, link_text: label });
      return;
    }

    if (href === "#contacto" || href.endsWith("/#contacto")) {
      track("contact_cta_click", { link_url: href, link_text: label });
    }
  });

  document.addEventListener("submit", (event) => {
    const form = event.target;
    if (!(form instanceof HTMLFormElement)) return;

    const action = form.getAttribute("action") || "";
    const id = form.getAttribute("id") || "";

    track("generate_lead", {
      form_id: id,
      form_action: action,
      page_location: window.location.pathname,
    });
  });
})();
