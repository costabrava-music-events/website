(() => {
  const data = window.CBME_QUOTE_DATA;
  const euro = new Intl.NumberFormat("es-ES", { style: "currency", currency: "EUR" });
  const $ = (selector) => document.querySelector(selector);
  const allItems = data.catalog.flatMap((group) => group.items.map((item) => ({ ...item, group: group.group })));
  const defaultLanguage = "ca";
  const previewRenderDelay = 300;

  let state = loadState() || createInitialState();
  let previewRenderTimeout;

  function createInitialState() {
    const language = defaultLanguage;
    const template = data.templates[0];
    return {
      language,
      templateId: template.id,
      quoteNumber: makeQuoteNumber(),
      quoteDate: new Date().toISOString().slice(0, 10),
      validUntil: "",
      clientName: "",
      clientEmail: "",
      eventName: templateText(template, language).eventType,
      eventDate: "",
      eventPlace: "Costa Brava / Girona",
      guests: 120,
      intro: templateText(template, language).intro,
      includeTax: false,
      hideBranding: false,
      items: templateItems(template, language),
      terms: defaultTerms(language),
    };
  }

  function makeQuoteNumber() {
    const date = new Date();
    const y = date.getFullYear();
    const m = String(date.getMonth() + 1).padStart(2, "0");
    const d = String(date.getDate()).padStart(2, "0");
    return `CBME-${y}${m}${d}`;
  }

  function currentLanguage() {
    return data.copy[state.language] ? state.language : defaultLanguage;
  }

  function t(key) {
    return data.copy[currentLanguage()][key] || data.copy[defaultLanguage][key] || key;
  }

  function defaultTerms(language = currentLanguage()) {
    return [...(data.localizedTerms[language] || data.localizedTerms[defaultLanguage] || data.defaultTerms)];
  }

  function templateText(template, language = currentLanguage()) {
    const copy = data.templateCopy[template.id] && data.templateCopy[template.id][language];
    if (!copy) return { name: template.name, eventType: template.eventType, intro: template.intro };
    return { name: copy[0], eventType: copy[1], intro: copy[2] };
  }

  function itemText(item, language = currentLanguage()) {
    const copy = data.itemCopy[item.id] && data.itemCopy[item.id][language];
    if (!copy) return { name: item.name, description: item.description };
    return { name: copy[0], description: copy[1] };
  }

  function localizedItem(item, language = currentLanguage()) {
    if (item.custom) return item;
    const base = allItems.find((entry) => entry.id === item.id) || item;
    return { ...item, ...itemText(base, language), group: base.group };
  }

  function templateItems(template, language = currentLanguage()) {
    return template.itemIds
      .map((id) => allItems.find((item) => item.id === id))
      .filter(Boolean)
      .map((item) => ({ ...item, ...itemText(item, language), qty: 1, custom: false }));
  }

  function loadState() {
    try {
      const saved = localStorage.getItem("cbme-quote");
      return saved ? normalizeState(JSON.parse(saved)) : null;
    } catch {
      return null;
    }
  }

  function normalizeState(draft) {
    const fresh = createInitialState();
    const language = data.copy[draft.language] ? draft.language : defaultLanguage;
    return {
      ...fresh,
      ...draft,
      language,
      terms: Array.isArray(draft.terms) ? draft.terms : String(draft.terms || "").split("\n"),
      items: Array.isArray(draft.items)
        ? draft.items.map((item) => ({
            ...localizedItem(item, language),
            qty: Number(item.qty || 0),
            price: Number(item.price || 0),
          }))
        : fresh.items,
    };
  }

  function saveState() {
    localStorage.setItem("cbme-quote", JSON.stringify(state));
  }

  function subtotal() {
    return state.items.reduce((sum, item) => sum + Number(item.price || 0) * Number(item.qty || 0), 0);
  }

  function totals() {
    const base = subtotal();
    const tax = state.includeTax ? base * data.taxRate : 0;
    const total = base + tax;
    const deposit = Math.round(total * data.depositRate);
    return { base, tax, total, deposit, pending: total - deposit };
  }

  function render() {
    clearTimeout(previewRenderTimeout);
    renderForms();
    renderCatalog();
    renderItems();
    renderTerms();
    renderPreview();
    saveState();
  }

  function schedulePreviewRender() {
    saveState();
    clearTimeout(previewRenderTimeout);
    previewRenderTimeout = setTimeout(renderPreview, previewRenderDelay);
  }

  function flushPreviewRender() {
    clearTimeout(previewRenderTimeout);
    renderPreview();
    saveState();
  }

  function renderForms() {
    $("#language").value = state.language;
    $("#quoteNumber").value = state.quoteNumber;
    $("#quoteDate").value = state.quoteDate;
    $("#validUntil").value = state.validUntil;
    $("#clientName").value = state.clientName;
    $("#clientEmail").value = state.clientEmail;
    $("#eventName").value = state.eventName;
    $("#eventDate").value = state.eventDate;
    $("#eventPlace").value = state.eventPlace;
    $("#guests").value = state.guests;
    $("#intro").value = state.intro;
    $("#includeTax").checked = state.includeTax;
    $("#hideBranding").checked = state.hideBranding;
    $("#copySummary").textContent = t("copySummary");
  }

  function renderCatalog() {
    const language = currentLanguage();
    const select = $("#catalogItem");
    select.innerHTML = data.catalog
      .map((group) => {
        const options = group.items
          .map((item) => {
            const copy = itemText(item, language);
            return `<option value="${item.id}">${copy.name} - ${euro.format(item.price)}</option>`;
          })
          .join("");
        const groupName = (data.groups[language] && data.groups[language][group.group]) || group.group;
        return `<optgroup label="${groupName}">${options}</optgroup>`;
      })
      .join("");

    $("#templateSelect").innerHTML = data.templates
      .map((template) => `<option value="${template.id}">${templateText(template, language).name}</option>`)
      .join("");
    $("#templateSelect").value = state.templateId || data.templates[0].id;
  }

  function renderItems() {
    const rows = state.items
      .map(
        (item, index) => `
          <tr>
            <td>
              <input data-item="${index}" data-field="name" value="${escapeAttr(item.name)}" />
              <textarea data-item="${index}" data-field="description" rows="2">${escapeHtml(item.description)}</textarea>
            </td>
            <td><input class="qty" type="number" min="0" step="1" data-item="${index}" data-field="qty" value="${item.qty}" /></td>
            <td><input class="price" type="number" min="0" step="5" data-item="${index}" data-field="price" value="${item.price}" /></td>
            <td class="line-total">${euro.format(Number(item.qty) * Number(item.price))}</td>
            <td><button class="icon-button danger" type="button" data-remove="${index}" aria-label="Eliminar partida">x</button></td>
          </tr>
        `
      )
      .join("");
    $("#itemsBody").innerHTML = rows || `<tr><td colspan="5" class="empty">Afegeix una partida del catàleg.</td></tr>`;
  }

  function renderTerms() {
    $("#terms").value = state.terms.join("\n");
  }

  function renderPreview() {
    const total = totals();
    const quoteNumber = state.hideBranding ? unbrandedQuoteNumber(state.quoteNumber) : state.quoteNumber;
    const rows = state.items
      .map(
        (item) => `
          <tr>
            <td>
              <strong>${escapeHtml(item.name)}</strong>
              <span>${escapeHtml(item.description || "")}</span>
            </td>
            <td>${Number(item.qty || 0)}</td>
            <td>${euro.format(Number(item.price || 0))}</td>
            <td>${euro.format(Number(item.price || 0) * Number(item.qty || 0))}</td>
          </tr>
        `
      )
      .join("");

    $("#preview").innerHTML = `
      <article class="quote-sheet">
        <header class="quote-head${state.hideBranding ? " quote-head--unbranded" : ""}">
          ${
            state.hideBranding
              ? ""
              : `<div class="quote-brand">
                  <span>${t("technicalProposal")}</span>
                  <img src="${data.company.logo}" alt="${data.company.name}" />
                  <p>${t("tagline")}</p>
                </div>`
          }
          <div class="quote-meta-card">
            <strong>${t("quote")}</strong>
            <dl>
              <div><dt>${t("number")}</dt><dd>${escapeHtml(quoteNumber)}</dd></div>
              <div><dt>${t("date")}</dt><dd>${formatDate(state.quoteDate)}</dd></div>
              ${state.validUntil ? `<div><dt>${t("validUntil")}</dt><dd>${formatDate(state.validUntil)}</dd></div>` : ""}
            </dl>
          </div>
        </header>

        <section class="quote-hero">
          <div>
            <p class="eyebrow">${t("personalizedProposal")}</p>
            <h1>${escapeHtml(state.eventName || "Esdeveniment")}</h1>
            <p>${escapeHtml(state.intro)}</p>
          </div>
          <dl>
            <div><dt>${t("client")}</dt><dd>${escapeHtml(state.clientName || t("pendingClient"))}</dd></div>
            <div><dt>${t("date")}</dt><dd>${formatDate(state.eventDate) || t("undefined")}</dd></div>
            <div><dt>${t("eventPlace")}</dt><dd>${escapeHtml(state.eventPlace || t("undefined"))}</dd></div>
            <div><dt>${t("guests")}</dt><dd>${escapeHtml(String(state.guests || t("undefined")))}</dd></div>
          </dl>
        </section>

        <section class="quote-summary">
          <div><span>${t("totalProposal")}</span><strong>${euro.format(total.total)}</strong></div>
          <div><span>${t("deposit")}</span><strong>${euro.format(total.deposit)}</strong></div>
          <div><span>${t("pending")}</span><strong>${euro.format(total.pending)}</strong></div>
        </section>

        <table class="quote-table">
          <thead>
            <tr><th>${t("service")}</th><th>${t("qty")}</th><th>${t("price")}</th><th>${t("total")}</th></tr>
          </thead>
          <tbody>${rows}</tbody>
        </table>

        <section class="quote-totals">
          <div>
            <h2>${t("terms")}</h2>
            <ul>${state.terms.filter(Boolean).map((term) => `<li>${escapeHtml(term)}</li>`).join("")}</ul>
          </div>
          <dl>
            <div><dt>${t("subtotal")}</dt><dd>${euro.format(total.base)}</dd></div>
            ${state.includeTax ? `<div><dt>${t("tax")}</dt><dd>${euro.format(total.tax)}</dd></div>` : ""}
            <div class="grand"><dt>${t("total")}</dt><dd>${euro.format(total.total)}</dd></div>
            <div><dt>${t("deposit")}</dt><dd>${euro.format(total.deposit)}</dd></div>
            <div><dt>${t("pending")}</dt><dd>${euro.format(total.pending)}</dd></div>
          </dl>
        </section>

        ${
          state.hideBranding
            ? ""
            : `<footer class="quote-footer">
                <span>${data.company.email}</span>
                <span>${data.company.phones.join(" / ")}</span>
                <span>${data.company.instagram}</span>
              </footer>`
        }
      </article>
    `;
  }

  function bindEvents() {
    bindAuth();

    document.addEventListener("input", (event) => {
      const target = event.target;
      const field = target.id;
      if (field === "language") {
        changeLanguage(target.value);
        render();
        return;
      }

      if (field === "terms") {
        state.terms = target.value.split("\n");
        schedulePreviewRender();
        return;
      }

      if (field in state) {
        state[field] = target.type === "checkbox" ? target.checked : target.value;
        schedulePreviewRender();
        return;
      }

      if (target.dataset.item !== undefined) {
        const item = state.items[Number(target.dataset.item)];
        item[target.dataset.field] = target.type === "number" ? Number(target.value) : target.value;
        updateItemLineTotal(target, item);
        schedulePreviewRender();
      }
    });

    document.addEventListener("click", (event) => {
      const remove = event.target.dataset.remove;
      if (remove !== undefined) {
        state.items.splice(Number(remove), 1);
        render();
      }
    });

    $("#applyTemplate").addEventListener("click", () => {
      const template = data.templates.find((item) => item.id === $("#templateSelect").value);
      if (!template) return;
      const copy = templateText(template);
      state.templateId = template.id;
      state.eventName = copy.eventType;
      state.intro = copy.intro;
      state.items = templateItems(template);
      state.terms = defaultTerms();
      render();
    });

    $("#addItem").addEventListener("click", () => {
      const item = allItems.find((entry) => entry.id === $("#catalogItem").value);
      if (!item) return;
      state.items.push({ ...item, ...itemText(item), qty: 1, custom: false });
      render();
    });

    $("#addCustom").addEventListener("click", () => {
      state.items.push({
        id: `custom-${Date.now()}`,
        name: t("customName"),
        description: t("customDescription"),
        price: 0,
        qty: 1,
        custom: true,
      });
      render();
    });

    $("#newQuote").addEventListener("click", () => {
      state = createInitialState();
      render();
    });

    $("#printQuote").addEventListener("click", () => {
      flushPreviewRender();
      window.print();
    });

    $("#copySummary").addEventListener("click", async () => {
      const total = totals();
      const quoteNumber = state.hideBranding ? unbrandedQuoteNumber(state.quoteNumber) : state.quoteNumber;
      const lines = [
        `${quoteNumber} - ${state.clientName || "Client"}`,
        `${state.eventName} · ${state.eventPlace}`,
        `${t("total")}: ${euro.format(total.total)}${state.includeTax ? t("taxIncluded") : t("plusTax")}`,
        `${t("deposit")}: ${euro.format(total.deposit)}`,
      ];
      await navigator.clipboard.writeText(lines.join("\n"));
      $("#copySummary").textContent = t("copied");
      setTimeout(() => ($("#copySummary").textContent = t("copySummary")), 1200);
    });
  }

  function changeLanguage(language) {
    const previousLanguage = currentLanguage();
    const previousTerms = state.terms.join("\n");
    const wasDefaultTerms = Object.values(data.localizedTerms).some((terms) => terms.join("\n") === previousTerms);
    const template = data.templates.find((item) => item.id === state.templateId) || data.templates[0];
    const previousTemplate = templateText(template, previousLanguage);

    state.language = data.copy[language] ? language : defaultLanguage;
    state.items = state.items.map((item) => localizedItem(item, state.language));

    if (state.eventName === previousTemplate.eventType) {
      state.eventName = templateText(template, state.language).eventType;
    }

    if (state.intro === previousTemplate.intro) {
      state.intro = templateText(template, state.language).intro;
    }

    if (wasDefaultTerms) {
      state.terms = defaultTerms(state.language);
    }
  }

  function updateItemLineTotal(target, item) {
    const row = target.closest("tr");
    const lineTotal = row && row.querySelector(".line-total");
    if (!lineTotal) return;
    lineTotal.textContent = euro.format(Number(item.qty || 0) * Number(item.price || 0));
  }

  function bindAuth() {
    const lockScreen = $("#lockScreen");
    const quoteApp = $("#quoteApp");
    const lockForm = $("#lockForm");
    const passwordInput = $("#passwordInput");
    const lockError = $("#lockError");

    const unlock = () => {
      lockScreen.classList.add("is-hidden");
      quoteApp.classList.remove("is-hidden");
    };

    if (sessionStorage.getItem(data.auth.sessionKey) === "1") {
      unlock();
      return;
    }

    lockForm.addEventListener("submit", async (event) => {
      event.preventDefault();
      const digest = await sha256(passwordInput.value);
      if (digest === data.auth.passwordHash) {
        sessionStorage.setItem(data.auth.sessionKey, "1");
        unlock();
        return;
      }

      lockError.textContent = "Contrasenya incorrecta.";
      passwordInput.select();
    });
  }

  async function sha256(value) {
    const bytes = new TextEncoder().encode(value);
    const hash = await crypto.subtle.digest("SHA-256", bytes);
    return [...new Uint8Array(hash)].map((byte) => byte.toString(16).padStart(2, "0")).join("");
  }

  function formatDate(value) {
    if (!value) return "";
    const date = new Date(`${value}T00:00:00`);
    const locales = { ca: "ca-ES", es: "es-ES", en: "en-GB" };
    return new Intl.DateTimeFormat(locales[currentLanguage()] || "ca-ES", { day: "2-digit", month: "long", year: "numeric" }).format(date);
  }

  function unbrandedQuoteNumber(value) {
    return String(value || "").replace(/^CBME[-\s]*/i, "");
  }

  function escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#039;");
  }

  function escapeAttr(value) {
    return escapeHtml(value).replaceAll("\n", " ");
  }

  bindEvents();
  render();
})();
