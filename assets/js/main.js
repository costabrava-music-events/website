/* Costa Brava Music Events — static site JS (vanilla + Alpine) */

/**
 * Subtle hero parallax (respects reduced motion)
 */
(() => {
  const reduce = window.matchMedia && window.matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (reduce) return;

  const hero = document.querySelector("[data-hero]");
  if (!hero) return;

  const onScroll = () => {
    const y = window.scrollY || 0;
    // Move background layers slightly for depth
    hero.style.setProperty("--parallax", `${Math.min(y * 0.12, 80)}px`);
  };

  onScroll();
  window.addEventListener("scroll", onScroll, { passive: true });
})();

/**
 * Internal quote tool easter egg.
 * Type "presu" on the public site.
 */
(() => {
  const code = "presu";
  let buffer = "";
  const isTyping = (target) =>
    target && ["INPUT", "TEXTAREA", "SELECT"].includes(target.tagName);

  window.addEventListener("keydown", (event) => {
    if (event.metaKey || event.ctrlKey || event.altKey || isTyping(event.target)) return;
    buffer = `${buffer}${event.key.toLowerCase()}`.slice(-code.length);
    if (buffer !== code) return;

    const localPrefix = /\/(ca|es|en)\//.test(window.location.pathname) ? "../" : "./";
    window.location.href =
      window.location.protocol === "http:" || window.location.protocol === "https:"
        ? `${window.location.origin}/presupuestos/`
        : `${localPrefix}presupuestos/index.html`;
  });
})();

/**
 * Swiper init (gallery)
 */
(() => {
  const el = document.querySelector(".js-gallery-swiper");
  if (!el || typeof Swiper === "undefined") return;

  // eslint-disable-next-line no-new
  new Swiper(el, {
    loop: true,
    speed: 1800,
    slidesPerView: 1.15,
    spaceBetween: 16,
    centeredSlides: false,
    autoplay: {
      delay: 1400,
      disableOnInteraction: false,
      pauseOnMouseEnter: true,
    },
    breakpoints: {
      640: { slidesPerView: 2.0, spaceBetween: 16 },
      1024: { slidesPerView: 3.0, spaceBetween: 18 },
      1280: { slidesPerView: 4.0, spaceBetween: 20 },
    },
  });
})();

/**
 * Swiper init (artists/partners)
 */
(() => {
  const el = document.querySelector(".js-partners-swiper");
  if (!el || typeof Swiper === "undefined") return;

  // eslint-disable-next-line no-new
  new Swiper(el, {
    loop: true,
    speed: 1200,
    slidesPerView: 1.15,
    spaceBetween: 16,
    centeredSlides: false,
    autoplay: {
      delay: 3200,
      disableOnInteraction: false,
      pauseOnMouseEnter: true,
    },
    allowTouchMove: true,
    breakpoints: {
      640: { slidesPerView: 2.0, spaceBetween: 16 },
      1024: { slidesPerView: 3.0, spaceBetween: 18 },
      1280: { slidesPerView: 4.0, spaceBetween: 20 },
    },
  });
})();

/**
 * AOS init (scroll animations)
 */
(() => {
  if (typeof AOS === "undefined") return;
  AOS.init({
    duration: 650,
    easing: "ease-out-cubic",
    once: true,
    offset: 90,
    disable: () =>
      window.matchMedia &&
      window.matchMedia("(prefers-reduced-motion: reduce)").matches,
  });
})();

/**
 * Alpine app state
 * - Shared across pages to keep layout consistent.
 */
window.cbmeApp = function cbmeApp() {
  return {
    openMenu: false,
    lockBody(lock) {
      document.body.classList.toggle("cbme-lock", !!lock);
    },
  };
};

/**
 * Basic i18n (ES/CA/EN) for static text content.
 */
(() => {
  const selector = document.querySelector("#language-selector");
  const langButtons = Array.from(document.querySelectorAll("[data-lang]"));
  if (!selector || langButtons.length === 0) return;
  const langSeo = {
    es: {
      locale: "es_ES",
      url: "https://costabravamusicevents.com/",
    },
    ca: {
      locale: "ca_ES",
      url: "https://costabravamusicevents.com/ca/",
    },
    en: {
      locale: "en_GB",
      url: "https://costabravamusicevents.com/en/",
    },
  };
  const canUseCanonicalUrls = () =>
    window.location.protocol === "http:" || window.location.protocol === "https:";
  const isStaticLocalePath = (path) =>
    path.endsWith("/ca/") || path.endsWith("/ca/index.html") || path.endsWith("/en/") || path.endsWith("/en/index.html");
  const goToCanonicalLocale = (locale, mode = "assign") => {
    if (!canUseCanonicalUrls()) return false;
    const target = langSeo[locale] && langSeo[locale].url;
    if (!target || window.location.href === target) return false;
    window.location[mode](target);
    return true;
  };
  const localPrefix = () => {
    const path = window.location.pathname || "";
    return isStaticLocalePath(path) ? "../" : "./";
  };
  const localHref = (path) => `${localPrefix()}${path}`;
  const guidesHub = {
    es: "es/guias-locales.html",
    ca: "ca/guies-locals.html",
    en: "en/local-guides.html",
  };
  const blogHub = {
    es: "es/blog.html",
    ca: "ca/blog.html",
    en: "en/blog.html",
  };
  const serviceLinks = {
    es: { dj: "es/dj-bodas-costa-brava.html", sound: "es/alquiler-sonido-eventos-girona.html", decor: "es/decoracion-eventos-costa-brava.html", privateEvents: "es/musica-eventos-privados-girona.html" },
    ca: { dj: "ca/dj-bodas-costa-brava.html", sound: "ca/alquiler-sonido-eventos-girona.html", decor: "ca/decoracion-eventos-costa-brava.html", privateEvents: "ca/musica-eventos-privados-girona.html" },
    en: { dj: "en/dj-bodas-costa-brava.html", sound: "en/alquiler-sonido-eventos-girona.html", decor: "en/decoracion-eventos-costa-brava.html", privateEvents: "en/musica-eventos-privados-girona.html" },
  };

  const translations = {
    es: {
      page_title: "DJ, música y sonido para eventos en Costa Brava | CBME",
      meta_description: "DJ, música en vivo, sonido e iluminación para bodas y eventos privados en Costa Brava y Girona. Producción técnica y musical a medida.",
      meta_og_title: "DJ, música y sonido para eventos en Costa Brava | CBME",
      meta_og_description: "DJ, música en vivo, sonido e iluminación para bodas y eventos privados en Costa Brava y Girona. Producción técnica y musical a medida.",
      skip_to_content: "Saltar al contenido",
      hero_title: "Música, sonido e iluminación para eventos que se recuerdan",
      hero_intro:
        'Creamos experiencias musicales a medida para bodas, eventos privados y celebraciones en la Costa Brava y en toda Cataluña. Coordinamos DJs, música en directo, sonido, iluminación y ambientación para que cada momento encaje con tu espacio, tus invitados y tu estilo.',
      hero_offers_title: "Ofrecemos:",
      hero_bullet_1: "DJs profesionales con repertorio adaptado al público y al momento",
      hero_bullet_2: "Música en directo: pop, rock, flamenco, rumba, boleros, chill y más",
      hero_bullet_3: "Sonido profesional ajustado al espacio, al formato y al número de invitados",
      hero_bullet_4: "Iluminación ambiental y de fiesta para transformar cada zona del evento",
      hero_bullet_5: "Coordinación técnica y musical para que todo fluya sin improvisaciones",
      hero_outro:
        "Diseñamos cada propuesta a medida, cuidando la energía de cada momento de principio a fin.",
      hero_signature: "Tú imaginas el ambiente. Nosotros lo hacemos sonar.",
      proposal_title: "¿Quieres una propuesta a medida?",
      proposal_copy:
        "Ponte en contacto con nosotros, estaremos encantados de darte un presupuesto personalizado",
      proposal_cta: "Solicitar propuesta",
      partners_title: "Artistas",
      partners_copy:
        "Colaboramos con DJs, bandas y propuestas en vivo para crear experiencias musicales a medida en cada evento.",
      event_partners_title: "Partners",
      event_partners_copy: "Espacios, marcas y proyectos con los que compartimos eventos, criterio y forma de trabajar.",
      partner_logo_pending: "Logo pendiente",
      partner_can_marc_name: "Can Marc",
      partner_can_marc_desc: "Espacio exclusivo en Begur para bodas, eventos y celebraciones, con jardines mediterráneos y vistas privilegiadas.",
      partner_bcn_alturas_name: "BCN en las Alturas",
      partner_bcn_alturas_desc: "Market pionero en Barcelona que fusiona moda, gastronomía, arte, ocio y actuaciones musicales en Torre Bellesguard.",
      partner_bodalia_name: "Bodalia",
      partner_bodalia_desc: "Proveedor recomendado en Bodalia para parejas que preparan su boda y buscan música, sonido e iluminación.",
      partners_instagram_cta: "Ver Instagram",
      role_dj: "DJ",
      role_band: "Banda",
      role_dance: "Baile",
      role_artist: "Artista",
      style_dj_pro: "DJ profesional",
      style_oneday: "Música 80/90 con percusión y batería en directo",
      style_rumba: "Rumba Catalana",
      style_litus: "Versiones de Pop/Rock (U2, REM, Queen, Beatles y Oasis)",
      style_bailaoras: "Bailaoras de Flamenco",
      style_inma: "Boleros, chill y música mediterránea",
      style_flamenco_trad: "Flamenco tradicional",
      moments_title: "Momentos",
      moments_copy:
        "Así suenan y se viven nuestros eventos: música en vivo, ritmo en la pista y momentos que nadie olvida.",
      moment_1_title: "Boda",
      moment_1_desc: "El Jardí de Can Marc (Begur - Costa Brava)",
      moment_2_desc: "Actuación en directo de Bailaoras de Flamenco y trío flamenco tradicional",
      moment_3_desc: "Versiones electrónicas 80/90s con percusión y dj en directo",
      moment_4_desc: "Boleros, chill y música mediterránea",
      services_title: "Servicios",
      services_copy:
        "Diseñamos música personalizada para tu evento, adaptada a tu estilo y a tus invitados. Trabajamos todos los géneros musicales, con equipos de sonido ajustados al espacio e iluminación con ambiente de discoteca y decoración adaptada a los diferentes espacios.",
      service_card_1_title: "DJs y Grupos Musicales",
      service_card_1_desc:
        "Selección de DJs y grupos musicales adaptados a tu evento, con repertorio pensado para tu estilo y tus invitados.",
      service_card_2_title: "Sonido & iluminación",
      service_card_2_desc:
        "Sistema de sonido ajustado al recinto, cabina DJ y propuesta de iluminación decorativa y de fiesta.",
      service_card_3_title: "Decoración",
      service_card_3_desc:
        "Ofrecemos servicios de decoración para tu evento: flores, globos, fuego frío, confeti y más, adaptados a tu estilo.",
      private_events_cta: "Música, DJ, sonido e iluminación para eventos privados en Girona",
      contact_title: "Contacto / Reserva",
      contact_email: "Email",
      contact_phone: "Teléfono de contacto",
      form_title: "Envíanos un mensaje",
      form_note: "Respondemos normalmente en menos de 24 horas laborables.",
      form_name: "Nombre",
      form_email: "Email",
      form_phone: "Teléfono",
      form_location: "Ubicación del evento",
      form_date: "Fecha del evento",
      form_guests: "Número de invitados",
      form_event_type: "Tipo de evento",
      event_wedding: "Boda",
      event_private: "Evento privado",
      event_anniversary: "Aniversario",
      event_fiesta: "Fiesta mayor",
      form_message: "Mensaje",
      form_submit: "Enviar",
      form_privacy: "Usaremos tus datos solo para responder a tu solicitud.",
      footer_local_guides: "Guías locales",
      footer_blog: "Blog",
      footer_brand: "Costa Brava Music Events",
      footer_tagline: "Música, sonido e iluminación que hacen vibrar tu evento",
      footer_rights:
        '© <span x-text="new Date().getFullYear()"></span> Costa Brava Music Events. Todos los derechos reservados.',
    },
    ca: {
      page_title: "DJ, música i so per a esdeveniments a Costa Brava | CBME",
      meta_description: "DJ, música en directe, so i il·luminació per a casaments i esdeveniments privats a Costa Brava i Girona.",
      meta_og_title: "DJ, música i so per a esdeveniments a Costa Brava | CBME",
      meta_og_description: "DJ, música en directe, so i il·luminació per a casaments i esdeveniments privats a Costa Brava i Girona.",
      skip_to_content: "Vés al contingut",
      hero_title: "Música, so i il·luminació per a esdeveniments que es recorden",
      hero_intro:
        'Creem experiències musicals a mida per a casaments, esdeveniments privats i celebracions a la Costa Brava i a tot Catalunya. Coordinem DJs, música en directe, so, il·luminació i ambientació perquè cada moment encaixi amb el teu espai, els teus convidats i el teu estil.',
      hero_offers_title: "Oferim:",
      hero_bullet_1: "DJs professionals amb repertori adaptat al públic i al moment",
      hero_bullet_2: "Música en directe: pop, rock, flamenc, rumba, boleros, chill i més",
      hero_bullet_3: "So professional ajustat a l'espai, al format i al nombre de convidats",
      hero_bullet_4: "Il·luminació ambiental i de festa per transformar cada zona de l'esdeveniment",
      hero_bullet_5: "Coordinació tècnica i musical perquè tot flueixi sense improvisacions",
      hero_outro: "Dissenyem cada proposta a mida, cuidant l'energia de cada moment de principi a fi.",
      hero_signature: "Tu imagines l'ambient. Nosaltres el fem sonar.",
      proposal_title: "Vols una proposta a mida?",
      proposal_copy: "Posa't en contacte amb nosaltres, estarem encantats de preparar-te un pressupost personalitzat",
      proposal_cta: "Sol·licitar proposta",
      partners_title: "Artistes",
      partners_copy: "Col·laborem amb DJs, bandes i propostes en directe per crear experiències musicals a mida a cada esdeveniment.",
      event_partners_title: "Partners",
      event_partners_copy: "Espais, marques i projectes amb qui compartim esdeveniments, criteri i manera de treballar.",
      partner_logo_pending: "Logo pendent",
      partner_can_marc_name: "Can Marc",
      partner_can_marc_desc: "Espai exclusiu a Begur per a casaments, esdeveniments i celebracions, amb jardins mediterranis i vistes privilegiades.",
      partner_bcn_alturas_name: "BCN en las Alturas",
      partner_bcn_alturas_desc: "Market pioner a Barcelona que fusiona moda, gastronomia, art, oci i actuacions musicals a Torre Bellesguard.",
      partner_bodalia_name: "Bodalia",
      partner_bodalia_desc: "Proveïdor recomanat a Bodalia per a parelles que preparen el seu casament i busquen música, so i il·luminació.",
      partners_instagram_cta: "Veure Instagram",
      role_dj: "DJ",
      role_band: "Banda",
      role_dance: "Ball",
      role_artist: "Artista",
      style_dj_pro: "DJ professional",
      style_oneday: "Música 80/90 amb percussió i bateria en directe",
      style_rumba: "Rumba catalana",
      style_litus: "Versions de Pop/Rock (U2, REM, Queen, Beatles i Oasis)",
      style_bailaoras: "Bailaoras de flamenc",
      style_inma: "Boleros, chill i música mediterrània",
      style_flamenco_trad: "Flamenc tradicional",
      moments_title: "Moments",
      moments_copy: "Així sonen i es viuen els nostres esdeveniments: música en viu, ritme a la pista i moments que ningú oblida.",
      moment_1_title: "Casament",
      moment_1_desc: "El Jardí de Can Marc (Begur - Costa Brava)",
      moment_2_desc: "Actuació en directe de bailaoras de flamenc i trio flamenc tradicional",
      moment_3_desc: "Versions electròniques 80/90 amb percussió i DJ en directe",
      moment_4_desc: "Boleros, chill i música mediterrània",
      services_title: "Serveis",
      services_copy:
        "Dissenyem música personalitzada per al teu esdeveniment, adaptada al teu estil i als teus convidats. Treballem tots els gèneres musicals, amb equips de so ajustats a l'espai i il·luminació amb ambient de discoteca i decoració adaptada als diferents espais.",
      service_card_1_title: "DJs i grups musicals",
      service_card_1_desc: "Selecció de DJs i grups musicals adaptats al teu esdeveniment, amb repertori pensat per al teu estil i els teus convidats.",
      service_card_2_title: "So & il·luminació",
      service_card_2_desc: "Sistema de so ajustat al recinte, cabina DJ i proposta d'il·luminació decorativa i de festa.",
      service_card_3_title: "Decoració",
      service_card_3_desc: "Oferim serveis de decoració per al teu esdeveniment: flors, globus, foc fred, confeti i més, adaptats al teu estil.",
      private_events_cta: "Música, DJ, so i il·luminació per a esdeveniments privats a Girona",
      contact_title: "Contacte / Reserva",
      contact_email: "Correu electrònic",
      contact_phone: "Telèfon de contacte",
      form_title: "Envia'ns un missatge",
      form_note: "Normalment responem en menys de 24 hores laborables.",
      form_name: "Nom",
      form_email: "Correu electrònic",
      form_phone: "Telèfon",
      form_location: "Ubicació de l'esdeveniment",
      form_date: "Data de l'esdeveniment",
      form_guests: "Nombre de convidats",
      form_event_type: "Tipus d'esdeveniment",
      event_wedding: "Casament",
      event_private: "Esdeveniment privat",
      event_anniversary: "Aniversari",
      event_fiesta: "Festa major",
      form_message: "Missatge",
      form_submit: "Enviar",
      form_privacy: "Farem servir les teves dades només per respondre la sol·licitud.",
      footer_local_guides: "Guies locals",
      footer_blog: "Blog",
      footer_brand: "Costa Brava Music Events",
      footer_tagline: "Música, so i il·luminació que fan vibrar el teu esdeveniment",
      footer_rights:
        '© <span x-text="new Date().getFullYear()"></span> Costa Brava Music Events. Tots els drets reservats.',
    },
    en: {
      page_title: "DJ, live music and sound for Costa Brava events | CBME",
      meta_description: "DJ, live music, sound and lighting for weddings and private events in Costa Brava and Girona. Tailored technical production.",
      meta_og_title: "DJ, live music and sound for Costa Brava events | CBME",
      meta_og_description: "DJ, live music, sound and lighting for weddings and private events in Costa Brava and Girona. Tailored technical production.",
      skip_to_content: "Skip to content",
      hero_title: "Music, sound and lighting for events people remember",
      hero_intro:
        'We create tailor-made music experiences for weddings, private events and celebrations across the Costa Brava and Catalonia. We coordinate DJs, live music, sound, lighting and atmosphere so every moment fits your venue, your guests and your style.',
      hero_offers_title: "We offer:",
      hero_bullet_1: "Professional DJs with music adapted to the crowd and the moment",
      hero_bullet_2: "Live music: pop, rock, flamenco, rumba, boleros, chill and more",
      hero_bullet_3: "Professional sound matched to the venue, format and guest count",
      hero_bullet_4: "Ambient and party lighting to transform every area of the event",
      hero_bullet_5: "Technical and musical coordination so everything flows without guesswork",
      hero_outro:
        "We design each proposal around the energy of the event, from the first arrival to the final song.",
      hero_signature: "You imagine the atmosphere. We make it sound right.",
      proposal_title: "Need a custom proposal?",
      proposal_copy: "Get in touch with us, we will be happy to prepare a personalized quote for your event",
      proposal_cta: "Request proposal",
      partners_title: "Artists",
      partners_copy: "We collaborate with DJs, bands and live acts to create tailor-made music experiences for every event.",
      event_partners_title: "Partners",
      event_partners_copy: "Venues, brands and projects that share our events, standards and way of working.",
      partner_logo_pending: "Logo pending",
      partner_can_marc_name: "Can Marc",
      partner_can_marc_desc: "Exclusive venue in Begur for weddings, events and celebrations, with Mediterranean gardens and privileged views.",
      partner_bcn_alturas_name: "BCN en las Alturas",
      partner_bcn_alturas_desc: "Pioneering Barcelona market blending fashion, gastronomy, art, leisure and live music at Torre Bellesguard.",
      partner_bodalia_name: "Bodalia",
      partner_bodalia_desc: "Recommended supplier on Bodalia for couples planning their wedding and looking for music, sound and lighting.",
      partners_instagram_cta: "View Instagram",
      role_dj: "DJ",
      role_band: "Band",
      role_dance: "Dance",
      role_artist: "Artist",
      style_dj_pro: "Professional DJ",
      style_oneday: "80/90s music with live percussion and drums",
      style_rumba: "Catalan rumba",
      style_litus: "Pop/Rock covers (U2, REM, Queen, Beatles and Oasis)",
      style_bailaoras: "Flamenco dancers",
      style_inma: "Boleros, chill and Mediterranean music",
      style_flamenco_trad: "Traditional flamenco",
      moments_title: "Moments",
      moments_copy: "This is how our events sound and feel: live music, rhythm on the dance floor and moments no one forgets.",
      moment_1_title: "Wedding",
      moment_1_desc: "El Jardí de Can Marc (Begur - Costa Brava)",
      moment_2_desc: "Live performance with flamenco dancers and a traditional flamenco trio",
      moment_3_desc: "Electronic 80/90s versions with live percussion and DJ",
      moment_4_desc: "Boleros, chill and Mediterranean music",
      services_title: "Services",
      services_copy:
        "We design custom music for your event, adapted to your style and guests. We work across all musical genres, with sound systems tuned to the venue and lighting with nightclub ambiance plus decoration adapted to each space.",
      service_card_1_title: "DJs and Music Groups",
      service_card_1_desc:
        "Selection of DJs and music groups tailored to your event, with a repertoire designed for your style and guests.",
      service_card_2_title: "Sound & lighting",
      service_card_2_desc:
        "Sound system tailored to the venue, DJ booth and decorative plus party lighting proposal.",
      service_card_3_title: "Decoration",
      service_card_3_desc:
        "We offer decoration services for your event: flowers, balloons, cold sparks, confetti and more, adapted to your style.",
      private_events_cta: "Music, DJ, sound and lighting for private events in Girona",
      contact_title: "Contact / Booking",
      contact_email: "Email",
      contact_phone: "Contact phone",
      form_title: "Send us a message",
      form_note: "We usually reply within one business day.",
      form_name: "Name",
      form_email: "Email",
      form_phone: "Phone",
      form_location: "Event location",
      form_date: "Event date",
      form_guests: "Number of guests",
      form_event_type: "Event type",
      event_wedding: "Wedding",
      event_private: "Private event",
      event_anniversary: "Anniversary",
      event_fiesta: "Local festival",
      form_message: "Message",
      form_submit: "Send",
      form_privacy: "We will only use your details to respond to your request.",
      footer_local_guides: "Local guides",
      footer_blog: "Blog",
      footer_brand: "Costa Brava Music Events",
      footer_tagline: "Music, sound and lighting that make your event come alive",
      footer_rights:
        '© <span x-text="new Date().getFullYear()"></span> Costa Brava Music Events. All rights reserved.',
    },
  };

  const applyLanguage = (lang) => {
    const locale = translations[lang] ? lang : "es";
    const dict = translations[locale];

    document.documentElement.lang = locale;
    langButtons.forEach((button) => {
      const isActive = button.getAttribute("data-lang") === locale;
      button.classList.toggle("is-active", isActive);
      button.setAttribute("aria-pressed", isActive ? "true" : "false");
    });

    document.title = dict.page_title;
    const titleNode = document.querySelector("#page-title");
    if (titleNode) titleNode.textContent = dict.page_title;

    const metaDescription = document.querySelector("#meta-description");
    if (metaDescription) metaDescription.setAttribute("content", dict.meta_description);

    const metaOgTitle = document.querySelector("#meta-og-title");
    if (metaOgTitle) metaOgTitle.setAttribute("content", dict.meta_og_title);

    const metaOgDescription = document.querySelector("#meta-og-description");
    if (metaOgDescription) metaOgDescription.setAttribute("content", dict.meta_og_description);

    const metaTwitterTitle = document.querySelector("#meta-twitter-title");
    if (metaTwitterTitle) metaTwitterTitle.setAttribute("content", dict.meta_og_title);

    const metaTwitterDescription = document.querySelector("#meta-twitter-description");
    if (metaTwitterDescription) metaTwitterDescription.setAttribute("content", dict.meta_og_description);

    const canonical = document.querySelector("link[rel='canonical']");
    if (canonical) canonical.setAttribute("href", langSeo[locale].url);

    const metaOgUrl = document.querySelector("#meta-og-url");
    if (metaOgUrl) metaOgUrl.setAttribute("content", langSeo[locale].url);

    const metaOgLocale = document.querySelector("#meta-og-locale");
    if (metaOgLocale) metaOgLocale.setAttribute("content", langSeo[locale].locale);

    document.querySelectorAll("[data-i18n]").forEach((node) => {
      const key = node.getAttribute("data-i18n");
      if (!key || !dict[key]) return;
      node.textContent = dict[key];
    });

    document.querySelectorAll("[data-i18n-html]").forEach((node) => {
      const key = node.getAttribute("data-i18n-html");
      if (!key || !dict[key]) return;
      node.innerHTML = dict[key];
    });

    const guidesLink = document.querySelector("#local-guides-link");
    if (guidesLink) guidesLink.setAttribute("href", localHref(guidesHub[locale]));
    const blogLink = document.querySelector("#blog-link");
    if (blogLink) blogLink.setAttribute("href", localHref(blogHub[locale]));
    document.querySelectorAll("[data-service-link]").forEach((node) => {
      const key = node.getAttribute("data-service-link");
      const href = serviceLinks[locale] && serviceLinks[locale][key];
      if (href) node.setAttribute("href", localHref(href));
    });

    try {
      localStorage.setItem("cbme_lang", locale);
    } catch (_error) {
      // ignore localStorage errors
    }

    try {
      const url = new URL(window.location.href);
      if (!canUseCanonicalUrls() && !isStaticLocalePath(url.pathname)) {
        if (locale === "es") {
          url.searchParams.delete("lang");
        } else {
          url.searchParams.set("lang", locale);
        }
        window.history.replaceState({}, "", `${url.pathname}${url.search}${url.hash}`);
      }
    } catch (_error) {
      // ignore URL/history errors
    }
  };

  const getInitialLanguage = () => {
    try {
      const urlLang = new URLSearchParams(window.location.search).get("lang");
      if (urlLang && translations[urlLang]) {
        goToCanonicalLocale(urlLang, "replace");
        return urlLang;
      }
    } catch (_error) {
      // ignore URLSearchParams errors
    }
    try {
      const path = window.location.pathname;
      if (path.endsWith("/ca/") || path.endsWith("/ca/index.html")) return "ca";
      if (path.endsWith("/en/") || path.endsWith("/en/index.html")) return "en";
    } catch (_error) {
      // ignore path errors
    }
    try {
      const saved = localStorage.getItem("cbme_lang");
      if (saved && translations[saved]) return saved;
    } catch (_error) {
      // ignore localStorage errors
    }
    const nav = (navigator.language || "es").toLowerCase();
    if (nav.startsWith("ca")) {
      goToCanonicalLocale("ca", "replace");
      return "ca";
    }
    if (nav.startsWith("en")) {
      goToCanonicalLocale("en", "replace");
      return "en";
    }
    return "es";
  };

  langButtons.forEach((button) => {
    button.addEventListener("click", () => {
      const locale = button.getAttribute("data-lang");
      if (goToCanonicalLocale(translations[locale] ? locale : "es")) return;
      applyLanguage(locale);
    });
  });

  applyLanguage(getInitialLanguage());
})();

/**
 * Optional Instagram links for artist/partner cards.
 * Show the CTA only when a URL is present in `data-instagram-url`.
 */
(() => {
  document.querySelectorAll("[data-instagram-link]").forEach((link) => {
    const href = (link.getAttribute("data-instagram-url") || "").trim();
    if (!href) return;

    link.setAttribute("href", href);
    link.classList.remove("hidden");
  });
})();
