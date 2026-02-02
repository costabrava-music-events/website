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
    speed: 700,
    slidesPerView: 1.15,
    spaceBetween: 16,
    centeredSlides: true,
    autoplay: {
      delay: 3500,
      disableOnInteraction: false,
    },
    pagination: {
      el: ".swiper-pagination",
      clickable: true,
    },
    navigation: {
      nextEl: ".swiper-button-next",
      prevEl: ".swiper-button-prev",
    },
    breakpoints: {
      640: { slidesPerView: 1.6, spaceBetween: 18 },
      1024: { slidesPerView: 2.4, spaceBetween: 22 },
      1280: { slidesPerView: 3.0, spaceBetween: 24 },
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

