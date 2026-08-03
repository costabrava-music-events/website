import { initializeApp } from "https://www.gstatic.com/firebasejs/11.10.0/firebase-app.js";
import {
  GoogleAuthProvider,
  getAuth,
  onAuthStateChanged,
  signInWithPopup,
  signOut,
} from "https://www.gstatic.com/firebasejs/11.10.0/firebase-auth.js";
import {
  collection,
  doc,
  getDocs,
  getFirestore,
  orderBy,
  query,
  runTransaction,
  serverTimestamp,
  writeBatch,
} from "https://www.gstatic.com/firebasejs/11.10.0/firebase-firestore.js";

const firebaseConfig = {
  projectId: "costa-brava-music-events-web",
  appId: "1:1026151316968:web:3e7701c421d1a0f888f85d",
  storageBucket: "costa-brava-music-events-web.firebasestorage.app",
  apiKey: "AIzaSyAuyktqCP6pA4TJKjjOM0utUDadUhfkxrs",
  authDomain: "costa-brava-music-events-web.firebaseapp.com",
  messagingSenderId: "1026151316968",
};
const adminEmail = "albertarredondoalfaro@gmail.com";
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app, "cbme-quotes");

(() => {
  const data = window.CBME_QUOTE_DATA;
  const euro = new Intl.NumberFormat("es-ES", { style: "currency", currency: "EUR" });
  const $ = (selector) => document.querySelector(selector);
  const allItems = data.catalog.flatMap((group) => group.items.map((item) => ({ ...item, group: group.group })));
  const defaultLanguage = "ca";
  const previewRenderDelay = 300;

  let state = loadState() || createInitialState();
  let savedQuotes = [];
  let previewRenderTimeout;
  let currentUser;

  function createInitialState() {
    const language = defaultLanguage;
    const template = data.templates[0];
    return {
      quoteId: null,
      language,
      templateId: template.id,
      quoteNumber: makeQuoteNumber(),
      quoteDate: new Date().toISOString().slice(0, 10),
      validUntil: "",
      clientName: "",
      clientEmail: "",
      status: "draft",
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
    return `CBME-${date.getFullYear()}${String(date.getMonth() + 1).padStart(2, "0")}${String(date.getDate()).padStart(2, "0")}`;
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
    return copy ? { name: copy[0], eventType: copy[1], intro: copy[2] } : { name: template.name, eventType: template.eventType, intro: template.intro };
  }

  function itemText(item, language = currentLanguage()) {
    const copy = data.itemCopy[item.id] && data.itemCopy[item.id][language];
    return copy ? { name: copy[0], description: copy[1] } : { name: item.name, description: item.description };
  }

  function localizedItem(item, language = currentLanguage()) {
    if (item.custom) return item;
    const base = allItems.find((entry) => entry.id === item.id) || item;
    return { ...item, ...itemText(base, language), group: base.group };
  }

  function templateItems(template, language = currentLanguage()) {
    return template.itemIds.map((id) => allItems.find((item) => item.id === id)).filter(Boolean).map((item) => ({ ...item, ...itemText(item, language), qty: 1, custom: false }));
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
      status: ["draft", "sent", "accepted", "discarded"].includes(draft.status) ? draft.status : "draft",
      terms: Array.isArray(draft.terms) ? draft.terms : String(draft.terms || "").split("\n"),
      items: Array.isArray(draft.items) ? draft.items.map((item) => ({ ...localizedItem(item, language), qty: Number(item.qty || 0), price: Number(item.price || 0) })) : fresh.items,
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
    renderSavedQuotes();
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
    ["language", "quoteNumber", "quoteDate", "validUntil", "clientName", "clientEmail", "status", "eventName", "eventDate", "eventPlace", "guests", "intro"].forEach((field) => ($(`#${field}`).value = state[field]));
    $("#includeTax").checked = state.includeTax;
    $("#hideBranding").checked = state.hideBranding;
    $("#copySummary").textContent = t("copySummary");
  }

  function renderCatalog() {
    const language = currentLanguage();
    $("#catalogItem").innerHTML = data.catalog.map((group) => {
      const options = group.items.map((item) => {
        const copy = itemText(item, language);
        return `<option value="${item.id}">${copy.name} - ${euro.format(item.price)}</option>`;
      }).join("");
      return `<optgroup label="${(data.groups[language] && data.groups[language][group.group]) || group.group}">${options}</optgroup>`;
    }).join("");
    $("#templateSelect").innerHTML = data.templates.map((template) => `<option value="${template.id}">${templateText(template, language).name}</option>`).join("");
    $("#templateSelect").value = state.templateId || data.templates[0].id;
  }

  function renderItems() {
    $("#itemsBody").innerHTML = state.items.map((item, index) => `
      <tr><td><input data-item="${index}" data-field="name" value="${escapeAttr(item.name)}" /><textarea data-item="${index}" data-field="description" rows="2">${escapeHtml(item.description)}</textarea></td>
      <td><input class="qty" type="number" min="0" step="1" data-item="${index}" data-field="qty" value="${item.qty}" /></td>
      <td><input class="price" type="number" min="0" step="5" data-item="${index}" data-field="price" value="${item.price}" /></td>
      <td class="line-total">${euro.format(Number(item.qty) * Number(item.price))}</td>
      <td><button class="icon-button danger" type="button" data-remove="${index}" aria-label="Eliminar partida">x</button></td></tr>`).join("") || `<tr><td colspan="5" class="empty">Afegeix una partida del catàleg.</td></tr>`;
  }

  function renderTerms() {
    $("#terms").value = state.terms.join("\n");
  }

  function renderPreview() {
    const total = totals();
    const quoteNumber = state.hideBranding ? unbrandedQuoteNumber(state.quoteNumber) : state.quoteNumber;
    const rows = state.items.map((item) => `<tr><td><strong>${escapeHtml(item.name)}</strong><span>${escapeHtml(item.description || "")}</span></td><td>${Number(item.qty || 0)}</td><td>${euro.format(Number(item.price || 0))}</td><td>${euro.format(Number(item.price || 0) * Number(item.qty || 0))}</td></tr>`).join("");
    $("#preview").innerHTML = `<article class="quote-sheet"><header class="quote-head${state.hideBranding ? " quote-head--unbranded" : ""}">${state.hideBranding ? "" : `<div class="quote-brand"><span>${t("technicalProposal")}</span><img src="${data.company.logo}" alt="${data.company.name}" /><p>${t("tagline")}</p></div>`}<div class="quote-meta-card"><strong>${t("quote")}</strong><dl><div><dt>${t("number")}</dt><dd>${escapeHtml(quoteNumber)}</dd></div><div><dt>${t("date")}</dt><dd>${formatDate(state.quoteDate)}</dd></div>${state.validUntil ? `<div><dt>${t("validUntil")}</dt><dd>${formatDate(state.validUntil)}</dd></div>` : ""}</dl></div></header><section class="quote-hero"><div><p class="eyebrow">${t("personalizedProposal")}</p><h1>${escapeHtml(state.eventName || "Esdeveniment")}</h1><p>${escapeHtml(state.intro)}</p></div><dl><div><dt>${t("client")}</dt><dd>${escapeHtml(state.clientName || t("pendingClient"))}</dd></div><div><dt>${t("date")}</dt><dd>${formatDate(state.eventDate) || t("undefined")}</dd></div><div><dt>${t("eventPlace")}</dt><dd>${escapeHtml(state.eventPlace || t("undefined"))}</dd></div><div><dt>${t("guests")}</dt><dd>${escapeHtml(String(state.guests || t("undefined")))}</dd></div></dl></section><section class="quote-summary"><div><span>${t("totalProposal")}</span><strong>${euro.format(total.total)}</strong></div><div><span>${t("deposit")}</span><strong>${euro.format(total.deposit)}</strong></div><div><span>${t("pending")}</span><strong>${euro.format(total.pending)}</strong></div></section><table class="quote-table"><thead><tr><th>${t("service")}</th><th>${t("qty")}</th><th>${t("price")}</th><th>${t("total")}</th></tr></thead><tbody>${rows}</tbody></table><section class="quote-totals"><div><h2>${t("terms")}</h2><ul>${state.terms.filter(Boolean).map((term) => `<li>${escapeHtml(term)}</li>`).join("")}</ul></div><dl><div><dt>${t("subtotal")}</dt><dd>${euro.format(total.base)}</dd></div>${state.includeTax ? `<div><dt>${t("tax")}</dt><dd>${euro.format(total.tax)}</dd></div>` : ""}<div class="grand"><dt>${t("total")}</dt><dd>${euro.format(total.total)}</dd></div><div><dt>${t("deposit")}</dt><dd>${euro.format(total.deposit)}</dd></div><div><dt>${t("pending")}</dt><dd>${euro.format(total.pending)}</dd></div></dl></section>${state.hideBranding ? "" : `<footer class="quote-footer"><span>${data.company.email}</span><span>${data.company.phones.join(" / ")}</span><span>${data.company.instagram}</span></footer>`}</article>`;
  }

  function renderSavedQuotes() {
    const term = $("#quoteSearch").value.trim().toLowerCase();
    const visible = savedQuotes.filter((quote) => [quote.quoteNumber, quote.clientName, quote.eventName].join(" ").toLowerCase().includes(term));
    const total = savedQuotes.reduce((sum, quote) => sum + Number(quote.total || 0), 0);
    $("#quotesSummary").innerHTML = `<div><span>Guardados</span><strong>${savedQuotes.length}</strong></div><div><span>Valor acumulado</span><strong>${euro.format(total)}</strong></div>`;
    $("#quotesList").innerHTML = visible.length ? visible.map((quote) => `
      <article class="quote-card${quote.id === state.quoteId ? " is-active" : ""}">
        <button class="quote-card-main" type="button" data-open-quote="${quote.id}" aria-label="Abrir ${escapeAttr(quote.quoteNumber || "presupuesto")}">
          <div class="quote-card-top"><strong class="quote-card-client">${escapeHtml(quote.clientName || "Sin cliente")}</strong><span class="quote-status quote-status--${escapeAttr(quote.status || "draft")}">${statusLabel(quote.status)}</span></div>
          <span class="quote-card-event">${escapeHtml(quote.eventName || "Evento sin definir")}</span>
          <span class="quote-card-metrics"><span class="quote-card-meta">${escapeHtml(quote.quoteNumber || "Sin número")} · v${Number(quote.version || 1)}</span><strong class="quote-card-total">${euro.format(Number(quote.total || 0))}</strong></span>
        </button>
        <div class="quote-card-footer"><span class="quote-card-date">Editado ${formatSavedDate(quote.updatedAt)}</span><button class="quote-delete" type="button" data-delete-quote="${quote.id}">Eliminar</button></div>
      </article>`).join("") : `<p class="quotes-empty">No hay presupuestos que coincidan.</p>`;
  }

  async function loadSavedQuotes() {
    if (!currentUser) return;
    const result = await getDocs(query(collection(db, "quotes"), orderBy("updatedAt", "desc")));
    savedQuotes = result.docs.map((snapshot) => ({ id: snapshot.id, ...snapshot.data() }));
    renderSavedQuotes();
  }

  async function saveQuote() {
    if (!currentUser) return;
    setSaveStatus("Guardando…");
    const quoteRef = state.quoteId ? doc(db, "quotes", state.quoteId) : doc(collection(db, "quotes"));
    const quoteData = { ...state, quoteId: quoteRef.id };
    const payload = JSON.stringify(quoteData);
    const total = totals();
    try {
      await runTransaction(db, async (transaction) => {
        const current = await transaction.get(quoteRef);
        const version = current.exists() ? Number(current.data().version || 0) + 1 : 1;
        const summary = {
          quoteNumber: String(state.quoteNumber || ""),
          clientName: String(state.clientName || ""),
          clientEmail: String(state.clientEmail || ""),
          eventName: String(state.eventName || ""),
          eventDate: String(state.eventDate || ""),
          status: state.status,
          total: total.total,
          version,
          payload,
          createdBy: current.exists() ? current.data().createdBy : currentUser.uid,
          updatedAt: serverTimestamp(),
        };
        if (!current.exists()) summary.createdAt = serverTimestamp();
        transaction.set(quoteRef, summary, { merge: current.exists() });
        transaction.set(doc(collection(quoteRef, "versions"), String(version)), { version, payload, savedBy: currentUser.uid, savedAt: serverTimestamp() });
      });
      state.quoteId = quoteRef.id;
      saveState();
      await loadSavedQuotes();
      setSaveStatus("Guardado");
    } catch (error) {
      console.error(error);
      setSaveStatus("No se ha podido guardar");
    }
  }

  async function openQuote(id) {
    const quote = savedQuotes.find((entry) => entry.id === id);
    if (!quote) return;
    try {
      state = normalizeState(JSON.parse(quote.payload));
      state.quoteId = id;
      render();
      setSaveStatus(`Versión ${quote.version || 1} abierta`);
    } catch {
      setSaveStatus("El presupuesto guardado no es válido");
    }
  }

  async function deleteQuote(id) {
    const quote = savedQuotes.find((entry) => entry.id === id);
    if (!quote || !window.confirm(`¿Eliminar ${quote.quoteNumber || "este presupuesto"} y todo su historial? Esta acción no se puede deshacer.`)) return;
    setSaveStatus("Eliminando…");
    try {
      const quoteRef = doc(db, "quotes", id);
      const versions = await getDocs(collection(quoteRef, "versions"));
      for (let start = 0; start < versions.docs.length; start += 499) {
        const batch = writeBatch(db);
        versions.docs.slice(start, start + 499).forEach((snapshot) => batch.delete(snapshot.ref));
        await batch.commit();
      }
      const batch = writeBatch(db);
      batch.delete(quoteRef);
      await batch.commit();
      if (state.quoteId === id) state = createInitialState();
      await loadSavedQuotes();
      render();
      setSaveStatus("Presupuesto eliminado");
    } catch (error) {
      console.error(error);
      setSaveStatus("No se ha podido eliminar");
    }
  }

  function updateFromTarget(target) {
    const field = target.id;
    if (field === "language") {
      changeLanguage(target.value);
      render();
      return true;
    }
    if (field === "terms") {
      state.terms = target.value.split("\n");
      schedulePreviewRender();
      return true;
    }
    if (field in state) {
      state[field] = target.type === "checkbox" ? target.checked : target.value;
      schedulePreviewRender();
      return true;
    }
    if (target.dataset.item !== undefined) {
      const item = state.items[Number(target.dataset.item)];
      item[target.dataset.field] = target.type === "number" ? Number(target.value) : target.value;
      updateItemLineTotal(target, item);
      schedulePreviewRender();
      return true;
    }
    return false;
  }

  function bindEvents() {
    document.addEventListener("input", (event) => updateFromTarget(event.target));
    document.addEventListener("change", (event) => {
      const target = event.target;
      if (target.type === "checkbox" || target.tagName === "SELECT") updateFromTarget(target);
    });
    document.addEventListener("click", (event) => {
      const remove = event.target.dataset.remove;
      if (remove !== undefined) {
        state.items.splice(Number(remove), 1);
        render();
      }
      if (event.target.dataset.openQuote) openQuote(event.target.dataset.openQuote);
      if (event.target.dataset.deleteQuote) deleteQuote(event.target.dataset.deleteQuote);
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
      state.items.push({ id: `custom-${Date.now()}`, name: t("customName"), description: t("customDescription"), price: 0, qty: 1, custom: true });
      render();
    });
    $("#newQuote").addEventListener("click", () => {
      state = createInitialState();
      render();
      setSaveStatus("Nuevo presupuesto");
    });
    $("#saveQuote").addEventListener("click", saveQuote);
    $("#refreshQuotes").addEventListener("click", () => loadSavedQuotes().catch(() => setSaveStatus("No se ha podido cargar el histórico")));
    $("#quoteSearch").addEventListener("input", renderSavedQuotes);
    $("#printQuote").addEventListener("click", () => {
      flushPreviewRender();
      window.print();
    });
    $("#copySummary").addEventListener("click", async () => {
      const total = totals();
      const quoteNumber = state.hideBranding ? unbrandedQuoteNumber(state.quoteNumber) : state.quoteNumber;
      await navigator.clipboard.writeText([`${quoteNumber} - ${state.clientName || "Client"}`, `${state.eventName} · ${state.eventPlace}`, `${t("total")}: ${euro.format(total.total)}${state.includeTax ? t("taxIncluded") : t("plusTax")}`, `${t("deposit")}: ${euro.format(total.deposit)}`].join("\n"));
      $("#copySummary").textContent = t("copied");
      setTimeout(() => ($("#copySummary").textContent = t("copySummary")), 1200);
    });
    $("#lockForm").addEventListener("submit", async (event) => {
      event.preventDefault();
      try {
        await signInWithPopup(auth, new GoogleAuthProvider());
      } catch (error) {
        $("#lockError").textContent = "No se ha podido iniciar sesión.";
        console.error(error);
      }
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
    if (state.eventName === previousTemplate.eventType) state.eventName = templateText(template, state.language).eventType;
    if (state.intro === previousTemplate.intro) state.intro = templateText(template, state.language).intro;
    if (wasDefaultTerms) state.terms = defaultTerms(state.language);
  }

  function updateItemLineTotal(target, item) {
    const lineTotal = target.closest("tr")?.querySelector(".line-total");
    if (lineTotal) lineTotal.textContent = euro.format(Number(item.qty || 0) * Number(item.price || 0));
  }

  function setSaveStatus(message) {
    $("#saveStatus").textContent = message;
  }

  function formatDate(value) {
    if (!value) return "";
    const locales = { ca: "ca-ES", es: "es-ES", en: "en-GB" };
    return new Intl.DateTimeFormat(locales[currentLanguage()] || "ca-ES", { day: "2-digit", month: "long", year: "numeric" }).format(new Date(`${value}T00:00:00`));
  }

  function formatSavedDate(value) {
    return value?.toDate ? new Intl.DateTimeFormat("es-ES", { dateStyle: "short" }).format(value.toDate()) : "Sin fecha";
  }

  function statusLabel(status) {
    return { draft: "Borrador", sent: "Enviado", accepted: "Aceptado", discarded: "Descartado" }[status] || "Borrador";
  }

  function unbrandedQuoteNumber(value) {
    return String(value || "").replace(/^CBME[-\s]*/i, "");
  }

  function escapeHtml(value) {
    return String(value).replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;").replaceAll('"', "&quot;").replaceAll("'", "&#039;");
  }

  function escapeAttr(value) {
    return escapeHtml(value).replaceAll("\n", " ");
  }

  bindEvents();
  render();
  onAuthStateChanged(auth, async (user) => {
    if (!user) return;
    if (user.email !== adminEmail || !user.emailVerified) {
      $("#lockError").textContent = "Esta cuenta no tiene acceso.";
      await signOut(auth);
      return;
    }
    currentUser = user;
    $("#lockScreen").classList.add("is-hidden");
    $("#quoteApp").classList.remove("is-hidden");
    try {
      await loadSavedQuotes();
    } catch (error) {
      setSaveStatus("No se ha podido cargar el histórico");
      console.error(error);
    }
  });
})();
