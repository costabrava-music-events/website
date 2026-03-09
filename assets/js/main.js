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
      delay: 700,
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
      url: "https://costabravamusicevents.com/?lang=ca",
    },
    en: {
      locale: "en_GB",
      url: "https://costabravamusicevents.com/?lang=en",
    },
  };
  const guidesHub = {
    es: "./es/guias-locales.html",
    ca: "./ca/guies-locals.html",
    en: "./en/local-guides.html",
  };

  const translations = {
    es: {
      page_title: "Costa Brava Music Events — Eventos musicales en la Costa Brava",
      meta_description: "Música, sonido e iluminación que hacen vibrar tu evento",
      meta_og_title: "Costa Brava Music Events",
      meta_og_description: "Música, sonido e iluminación que hacen vibrar tu evento",
      skip_to_content: "Saltar al contenido",
      hero_title: "Música, sonido e iluminación que hacen vibrar tu evento",
      hero_intro:
        'Somos <span class="inline-block rounded-lg bg-white/15 px-2 py-0.5 text-lg font-black tracking-wide text-white shadow-sm sm:text-xl">Costa Brava Music Events</span>, tu partner de confianza para bodas, eventos privados, cumpleaños, aniversarios, inauguraciones, fiestas mayores y verbenas.',
      hero_offers_title: "Ofrecemos:",
      hero_bullet_1: "DJs profesionales y selección musical personalizada",
      hero_bullet_2: "Bandas y propuestas en vivo (pop/rock, flamenco, rumba, boleros y más)",
      hero_bullet_3: "Equipos de sonido premium adaptados a cada espacio",
      hero_bullet_4: "Iluminación creativa y ambiental para crear el ambiente perfecto",
      hero_bullet_5: "Decoración personalizada para cada espacio y estilo de evento",
      hero_outro:
        "Diseñamos cada evento a medida, cuidando cada detalle para que tú solo te ocupes de disfrutar.",
      hero_signature: "Tu evento suena mejor con nosotros.",
      proposal_title: "¿Quieres una propuesta a medida?",
      proposal_copy:
        "Ponte en contacto con nosotros, estaremos encantados de darte un presupuesto personalizado",
      proposal_cta: "Solicitar propuesta",
      partners_title: "Artistas & partners",
      partners_copy:
        "Colaboramos con DJs, bandas y propuestas en vivo para crear experiencias musicales a medida en cada evento.",
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
      contact_title: "Contacto / Reserva",
      contact_email: "Email",
      contact_phone: "Teléfono de contacto",
      form_title: "Envíanos un mensaje",
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
      footer_local_guides: "Guías locales",
      footer_brand: "Costa Brava Music Events",
      footer_tagline: "Música, sonido e iluminación que hacen vibrar tu evento",
      footer_rights:
        '© <span x-text="new Date().getFullYear()"></span> Costa Brava Music Events. Todos los derechos reservados.',
    },
    ca: {
      page_title: "Costa Brava Music Events — Esdeveniments musicals a la Costa Brava",
      meta_description: "Música, so i il·luminació que fan vibrar el teu esdeveniment",
      meta_og_title: "Costa Brava Music Events",
      meta_og_description: "Música, so i il·luminació que fan vibrar el teu esdeveniment",
      skip_to_content: "Vés al contingut",
      hero_title: "Música, so i il·luminació que fan vibrar el teu esdeveniment",
      hero_intro:
        'Som <span class="inline-block rounded-lg bg-white/15 px-2 py-0.5 text-lg font-black tracking-wide text-white shadow-sm sm:text-xl">Costa Brava Music Events</span>, el teu partner de confiança per a casaments, esdeveniments privats, aniversaris, inauguracions, festes majors i revetlles.',
      hero_offers_title: "Oferim:",
      hero_bullet_1: "DJs professionals i selecció musical personalitzada",
      hero_bullet_2: "Bandes i propostes en directe (pop/rock, flamenc, rumba, boleros i més)",
      hero_bullet_3: "Equips de so premium adaptats a cada espai",
      hero_bullet_4: "Il·luminació creativa i ambiental per crear l'ambient perfecte",
      hero_bullet_5: "Decoració personalitzada per a cada espai i estil d'esdeveniment",
      hero_outro: "Dissenyem cada esdeveniment a mida, cuidant cada detall perquè tu només gaudeixis.",
      hero_signature: "El teu esdeveniment sona millor amb nosaltres.",
      proposal_title: "Vols una proposta a mida?",
      proposal_copy: "Posa't en contacte amb nosaltres, estarem encantats de preparar-te un pressupost personalitzat",
      proposal_cta: "Sol·licitar proposta",
      partners_title: "Artistes & partners",
      partners_copy: "Col·laborem amb DJs, bandes i propostes en directe per crear experiències musicals a mida a cada esdeveniment.",
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
      contact_title: "Contacte / Reserva",
      contact_email: "Correu electrònic",
      contact_phone: "Telèfon de contacte",
      form_title: "Envia'ns un missatge",
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
      footer_local_guides: "Guies locals",
      footer_brand: "Costa Brava Music Events",
      footer_tagline: "Música, so i il·luminació que fan vibrar el teu esdeveniment",
      footer_rights:
        '© <span x-text="new Date().getFullYear()"></span> Costa Brava Music Events. Tots els drets reservats.',
    },
    en: {
      page_title: "Costa Brava Music Events — Music events on the Costa Brava",
      meta_description: "Music, sound and lighting that make your event come alive",
      meta_og_title: "Costa Brava Music Events",
      meta_og_description: "Music, sound and lighting that make your event come alive",
      skip_to_content: "Skip to content",
      hero_title: "Music, sound and lighting that make your event come alive",
      hero_intro:
        'We are <span class="inline-block rounded-lg bg-white/15 px-2 py-0.5 text-lg font-black tracking-wide text-white shadow-sm sm:text-xl">Costa Brava Music Events</span>, your trusted partner for weddings, private events, birthdays, anniversaries, openings, local festivals and traditional celebrations.',
      hero_offers_title: "We offer:",
      hero_bullet_1: "Professional DJs and tailored music selection",
      hero_bullet_2: "Bands and live acts (pop/rock, flamenco, rumba, boleros and more)",
      hero_bullet_3: "Premium sound systems adapted to each venue",
      hero_bullet_4: "Creative ambient lighting to build the perfect atmosphere",
      hero_bullet_5: "Custom decoration for each space and event style",
      hero_outro:
        "We design each event to measure, taking care of every detail so you can focus on enjoying it.",
      hero_signature: "Your event sounds better with us.",
      proposal_title: "Need a custom proposal?",
      proposal_copy: "Get in touch with us, we will be happy to prepare a personalized quote for your event",
      proposal_cta: "Request proposal",
      partners_title: "Artists & partners",
      partners_copy: "We collaborate with DJs, bands and live acts to create tailor-made music experiences for every event.",
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
      contact_title: "Contact / Booking",
      contact_email: "Email",
      contact_phone: "Contact phone",
      form_title: "Send us a message",
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
      footer_local_guides: "Local guides",
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
    if (guidesLink) guidesLink.setAttribute("href", guidesHub[locale]);

    try {
      localStorage.setItem("cbme_lang", locale);
    } catch (_error) {
      // ignore localStorage errors
    }

    try {
      const url = new URL(window.location.href);
      if (locale === "es") {
        url.searchParams.delete("lang");
      } else {
        url.searchParams.set("lang", locale);
      }
      window.history.replaceState({}, "", `${url.pathname}${url.search}${url.hash}`);
    } catch (_error) {
      // ignore URL/history errors
    }
  };

  const getInitialLanguage = () => {
    try {
      const urlLang = new URLSearchParams(window.location.search).get("lang");
      if (urlLang && translations[urlLang]) return urlLang;
    } catch (_error) {
      // ignore URLSearchParams errors
    }
    try {
      const saved = localStorage.getItem("cbme_lang");
      if (saved && translations[saved]) return saved;
    } catch (_error) {
      // ignore localStorage errors
    }
    const nav = (navigator.language || "es").toLowerCase();
    if (nav.startsWith("ca")) return "ca";
    if (nav.startsWith("en")) return "en";
    return "es";
  };

  langButtons.forEach((button) => {
    button.addEventListener("click", () => {
      applyLanguage(button.getAttribute("data-lang"));
    });
  });

  applyLanguage(getInitialLanguage());
})();
