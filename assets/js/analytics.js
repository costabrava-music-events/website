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

  const ATTRIBUTION_STORAGE_KEY = "cbme_utm_attribution";
  const CAMPAIGN_KEYS = [
    "utm_source",
    "utm_medium",
    "utm_campaign",
    "utm_content",
    "utm_term",
  ];

  const campaignParamsFromObject = (value) => {
    if (!value || typeof value !== "object" || Array.isArray(value)) return {};
    return CAMPAIGN_KEYS.reduce((campaignParams, key) => {
      if (typeof value[key] !== "string") return campaignParams;
      const campaignValue = value[key].trim().slice(0, 100);
      if (campaignValue) campaignParams[key] = campaignValue;
      return campaignParams;
    }, {});
  };

  const campaignParamsFromUrl = (search) => {
    const urlParams = new URLSearchParams(search);
    return campaignParamsFromObject(
      CAMPAIGN_KEYS.reduce((campaignParams, key) => {
        campaignParams[key] = urlParams.get(key) || "";
        return campaignParams;
      }, {}),
    );
  };

  const captureAttribution = () => {
    const currentAttribution = campaignParamsFromUrl(window.location.search);
    try {
      const storedAttribution = window.sessionStorage.getItem(ATTRIBUTION_STORAGE_KEY);
      if (storedAttribution !== null) {
        return campaignParamsFromObject(JSON.parse(storedAttribution));
      }
      window.sessionStorage.setItem(
        ATTRIBUTION_STORAGE_KEY,
        JSON.stringify(currentAttribution),
      );
    } catch (_error) {
      // Private browsing or disabled storage must not stop analytics events.
    }
    return currentAttribution;
  };

  const sessionAttribution = captureAttribution();

  const pageContext = () => ({
    page_language: document.documentElement.lang || "unknown",
    page_path: window.location.pathname,
  });

  const track = (name, params = {}) => {
    if (typeof window.gtag !== "function") return;
    window.gtag("event", name, {
      ...pageContext(),
      ...sessionAttribution,
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

  const isFormspreeForm = (form) => {
    try {
      const url = new URL(form.getAttribute("action") || "", window.location.href);
      return url.hostname === "formspree.io" && url.pathname.startsWith("/f/");
    } catch (_error) {
      return false;
    }
  };

  const leadParams = (form) => {
    const data = new FormData(form);
    return {
      form_id: form.getAttribute("id") || "contact_form",
      form_action: form.getAttribute("action") || "",
      contact_method: "form",
      cta_location: form.getAttribute("data-cta-location") || "contact_form",
      event_type: String(data.get("event_type") || "unknown").slice(0, 60),
      guest_count_bucket: guestBucket(data.get("guest_count")),
      has_phone: Boolean(String(data.get("phone") || "").trim()),
      has_event_date: Boolean(String(data.get("event_date") || "").trim()),
      has_event_location: Boolean(String(data.get("event_location") || "").trim()),
    };
  };

  const setFormStatus = (form, message) => {
    const status = form.querySelector("[data-form-status]");
    if (status) status.textContent = message;
  };

  const formMessage = (form, name, fallback) => form.dataset[`form${name}`] || fallback;

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
        contact_method: "whatsapp",
        cta_location: ctaLocation || "contact",
      });
      return;
    }

    if (href.startsWith("tel:")) {
      track("contact_phone_click", {
        link_url: href,
        link_text: label,
        contact_method: "phone",
        cta_location: ctaLocation || "contact",
      });
      return;
    }

    if (href.startsWith("mailto:")) {
      track("contact_email_click", {
        link_url: href,
        link_text: label,
        contact_method: "email",
        cta_location: ctaLocation || "contact",
      });
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
        contact_method: "form",
        cta_location: ctaLocation || "unknown",
      });
      return;
    }

    if (service) {
      track("service_link_click", {
        service,
        link_url: href,
        link_text: label,
        cta_location: ctaLocation || "service_content",
      });
    }
  });

  document.addEventListener("submit", (event) => {
    const form = event.target;
    if (!(form instanceof HTMLFormElement)) return;
    if (!isFormspreeForm(form)) return;
    event.preventDefault();

    if (form.dataset.formspreeSubmitting === "true") return;
    form.dataset.formspreeSubmitting = "true";

    const submitButton = form.querySelector("button[type='submit'], input[type='submit']");
    if (submitButton) submitButton.disabled = true;
    setFormStatus(form, formMessage(form, "Sending", "Enviando..."));

    const action = form.getAttribute("action") || "";
    fetch(action, {
      method: (form.getAttribute("method") || "POST").toUpperCase(),
      body: new FormData(form),
      headers: { Accept: "application/json" },
    })
      .then((response) => {
        if (!response.ok) throw new Error(`Formspree request failed: ${response.status}`);
        const params = leadParams(form);
        form.reset();
        delete form.dataset.formspreeSubmitting;
        if (submitButton) submitButton.disabled = false;
        setFormStatus(form, formMessage(form, "Success", "Gracias. Hemos recibido tu mensaje."));
        try {
          track("generate_lead", params);
        } catch (_error) {
          // A GA4 failure must not turn a successful Formspree submission into a retry.
        }
      })
      .catch(() => {
        delete form.dataset.formspreeSubmitting;
        if (submitButton) submitButton.disabled = false;
        setFormStatus(form, formMessage(form, "Error", "No se ha podido enviar el mensaje. Inténtalo de nuevo."));
      });
  });
})();
