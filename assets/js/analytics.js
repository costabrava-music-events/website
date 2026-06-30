/* Costa Brava Music Events — GA4 + conversion events */
(() => {
  if (window.location.hostname === "www.costabravamusicevents.com") {
    window.location.replace(`https://costabravamusicevents.com${window.location.pathname}${window.location.search}${window.location.hash}`);
    return;
  }

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

  const pageContext = () => ({
    page_language: document.documentElement.lang || "unknown",
    page_path: window.location.pathname,
  });

  const track = (name, params = {}) => {
    if (typeof window.gtag !== "function") return;
    window.gtag("event", name, {
      ...pageContext(),
      ...params,
    });
  };

  const guestBucket = (value) => {
    const count = Number(value);
    if (!Number.isFinite(count) || count <= 0) return "unknown";
    if (count <= 50) return "1_50";
    if (count <= 100) return "51_100";
    if (count <= 200) return "101_200";
    return "201_plus";
  };

  document.addEventListener("click", (event) => {
    const link = event.target.closest("a[href]");
    if (!link) return;

    const href = link.getAttribute("href") || "";
    const label = (link.textContent || "").trim().slice(0, 120);
    const ctaLocation = link.getAttribute("data-cta-location") || "";
    const service = link.getAttribute("data-service-link") || "";

    if (href.includes("wa.me/") || href.includes("api.whatsapp.com/")) {
      track("contact_whatsapp_click", {
        link_url: href.split("?")[0],
        link_text: label,
        cta_location: ctaLocation || "contact",
      });
      return;
    }

    if (href.startsWith("tel:")) {
      track("contact_phone_click", { link_url: href, link_text: label });
      return;
    }

    if (href.startsWith("mailto:")) {
      track("contact_email_click", { link_url: href, link_text: label });
      return;
    }

    if (href.includes("instagram.com/")) {
      track("instagram_click", { link_url: href, link_text: label });
      return;
    }

    if (ctaLocation || href === "#contacto" || href.endsWith("/#contacto")) {
      track("contact_cta_click", {
        link_url: href,
        link_text: label,
        cta_location: ctaLocation || "unknown",
      });
      return;
    }

    if (service) {
      track("service_link_click", {
        service,
        link_url: href,
        link_text: label,
      });
    }
  });

  document.addEventListener("submit", (event) => {
    const form = event.target;
    if (!(form instanceof HTMLFormElement)) return;

    const action = form.getAttribute("action") || "";
    const id = form.getAttribute("id") || "";
    const data = new FormData(form);

    track("generate_lead", {
      form_id: id || "contact_form",
      form_action: action,
      event_type: String(data.get("event_type") || "unknown").slice(0, 60),
      guest_count_bucket: guestBucket(data.get("guest_count")),
      has_phone: Boolean(String(data.get("phone") || "").trim()),
      has_event_date: Boolean(String(data.get("event_date") || "").trim()),
      has_event_location: Boolean(String(data.get("event_location") || "").trim()),
    });
  });
})();
