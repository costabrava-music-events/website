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
const adminEmails = ["albertarredondoalfaro@gmail.com", "danifocus.40@gmail.com"];
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
  let previewRenderTimeout = null;
  let currentUser;
  let isPrinting = false;
  let isSaving = false;
  let isLoadingQuote = false;
  let isLoadingQuotes = false;
  let isDeleting = false;

  function createInitialState() {
    const language = defaultLanguage;
    const template = data.templates[0];
    return {
      quoteId: null,
      language,
      templateId: template.id,
      quoteNumber: makeQuoteNumber(),
      quoteDate: todayISO(),
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

  function dateLabel(kind) {
    const labels = {
      ca: { quote: "Data del pressupost", event: "Data de l'esdeveniment" },
      es: { quote: "Fecha del presupuesto", event: "Fecha del evento" },
      en: { quote: "Quote date", event: "Event date" },
    };
    return (labels[currentLanguage()] || labels[defaultLanguage])[kind];
  }

  function todayISO() {
    const now = new Date();
    return new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 10);
  }

  function isValidDateValue(value) {
    const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(value || ""));
    if (!match) return false;
    const date = new Date(`${value}T00:00:00`);
    return !Number.isNaN(date.getTime()) && date.getFullYear() === Number(match[1]) && date.getMonth() + 1 === Number(match[2]) && date.getDate() === Number(match[3]);
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
    const copy = itemText(base, language);
    return { ...item, ...(item.nameEdited ? {} : { name: copy.name }), ...(item.descriptionEdited ? {} : { description: copy.description }), group: base.group };
  }

  function templateItems(template, language = currentLanguage()) {
    return template.itemIds.map((id) => allItems.find((item) => item.id === id)).filter(Boolean).map((item) => ({ ...item, ...itemText(item, language), qty: 1, custom: false, nameEdited: false, descriptionEdited: false }));
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
      quoteDate: isValidDateValue(draft.quoteDate) ? draft.quoteDate : fresh.quoteDate,
      validUntil: isValidDateValue(draft.validUntil) ? draft.validUntil : "",
      eventDate: isValidDateValue(draft.eventDate) ? draft.eventDate : "",
      status: ["draft", "sent", "accepted", "discarded"].includes(draft.status) ? draft.status : "draft",
      terms: Array.isArray(draft.terms) ? draft.terms : String(draft.terms || "").split("\n"),
      items: Array.isArray(draft.items) ? draft.items.map((item) => normalizeItem(item, language)) : fresh.items,
    };
  }

  function normalizeItem(item, language) {
    const base = allItems.find((entry) => entry.id === item.id) || item;
    const copy = itemText(base, language);
    const name = String(item.name ?? copy.name);
    const description = String(item.description ?? copy.description ?? "");
    const nameEdited = item.nameEdited === true || (item.nameEdited !== false && name !== copy.name);
    const descriptionEdited = item.descriptionEdited === true || (item.descriptionEdited !== false && description !== String(copy.description || ""));
    return {
      ...item,
      ...(!item.custom && !nameEdited ? { name: copy.name } : { name }),
      ...(!item.custom && !descriptionEdited ? { description: copy.description } : { description }),
      group: base.group,
      nameEdited,
      descriptionEdited,
      qty: Number(item.qty || 0),
      price: Number(item.price || 0),
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
    previewRenderTimeout = null;
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
    previewRenderTimeout = setTimeout(() => {
      previewRenderTimeout = null;
      renderPreview();
    }, previewRenderDelay);
  }

  function flushPreviewRender(force = false) {
    const hasPendingRender = previewRenderTimeout !== null;
    clearTimeout(previewRenderTimeout);
    previewRenderTimeout = null;
    if (force || hasPendingRender) renderPreview();
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
    $("#preview").innerHTML = `<article class="quote-sheet"><header class="quote-head${state.hideBranding ? " quote-head--unbranded" : ""}">${state.hideBranding ? "" : `<div class="quote-brand"><span>${t("technicalProposal")}</span><img src="${data.company.logo}" alt="${data.company.name}" /><p>${t("tagline")}</p></div>`}<div class="quote-meta-card"><strong>${t("quote")}</strong><dl><div><dt>${t("number")}</dt><dd>${escapeHtml(quoteNumber)}</dd></div><div><dt>${dateLabel("quote")}</dt><dd>${formatDate(state.quoteDate)}</dd></div>${state.validUntil ? `<div><dt>${t("validUntil")}</dt><dd>${formatDate(state.validUntil)}</dd></div>` : ""}</dl></div></header><section class="quote-hero"><div><p class="eyebrow">${t("personalizedProposal")}</p><h1>${escapeHtml(state.eventName || "Esdeveniment")}</h1><p>${escapeHtml(state.intro)}</p></div><dl><div><dt>${t("client")}</dt><dd>${escapeHtml(state.clientName || t("pendingClient"))}</dd></div><div><dt>${dateLabel("event")}</dt><dd>${formatDate(state.eventDate) || t("undefined")}</dd></div><div><dt>${t("eventPlace")}</dt><dd>${escapeHtml(state.eventPlace || t("undefined"))}</dd></div><div><dt>${t("guests")}</dt><dd>${escapeHtml(String(state.guests || t("undefined")))}</dd></div></dl></section><section class="quote-summary"><div><span>${t("totalProposal")}</span><strong>${euro.format(total.total)}</strong></div><div><span>${t("deposit")}</span><strong>${euro.format(total.deposit)}</strong></div><div><span>${t("pending")}</span><strong>${euro.format(total.pending)}</strong></div></section><table class="quote-table"><thead><tr><th>${t("service")}</th><th>${t("qty")}</th><th>${t("price")}</th><th>${t("total")}</th></tr></thead><tbody>${rows}</tbody></table><section class="quote-totals"><div><h2>${t("terms")}</h2><ul>${state.terms.filter(Boolean).map((term) => `<li>${escapeHtml(term)}</li>`).join("")}</ul></div><dl><div><dt>${t("subtotal")}</dt><dd>${euro.format(total.base)}</dd></div>${state.includeTax ? `<div><dt>${t("tax")}</dt><dd>${euro.format(total.tax)}</dd></div>` : ""}<div class="grand"><dt>${t("total")}</dt><dd>${euro.format(total.total)}</dd></div><div><dt>${t("deposit")}</dt><dd>${euro.format(total.deposit)}</dd></div><div><dt>${t("pending")}</dt><dd>${euro.format(total.pending)}</dd></div></dl></section>${state.hideBranding ? "" : `<footer class="quote-footer"><span>${data.company.email}</span><span>${data.company.phones.join(" / ")}</span><span>${data.company.instagram}</span></footer>`}</article>`;
  }

  function renderSavedQuotes() {
    const term = $("#quoteSearch").value.trim().toLowerCase();
    const visible = savedQuotes.filter((quote) => [quote.quoteNumber, quote.clientName, quote.eventName].join(" ").toLowerCase().includes(term));
    const total = savedQuotes.reduce((sum, quote) => sum + Number(quote.total || 0), 0);
    $("#quotesSummary").innerHTML = `<div><span>Guardados</span><strong>${savedQuotes.length}</strong></div><div><span>Valor acumulado</span><strong>${euro.format(total)}</strong></div>`;
    $("#quotesList").innerHTML = visible.length ? visible.map((quote) => `
      <article class="quote-card${quote.id === state.quoteId ? " is-active" : ""}">
        <button class="quote-card-main" type="button" data-open-quote="${escapeAttr(quote.id)}" aria-label="Abrir ${escapeAttr(quote.quoteNumber || "presupuesto")}">
          <div class="quote-card-top"><strong class="quote-card-client">${escapeHtml(quote.clientName || "Sin cliente")}</strong><span class="quote-status quote-status--${escapeAttr(quote.status || "draft")}">${statusLabel(quote.status)}</span></div>
          <span class="quote-card-event">${escapeHtml(quote.eventName || "Evento sin definir")}</span>
          <span class="quote-card-metrics"><span class="quote-card-meta">${escapeHtml(quote.quoteNumber || "Sin número")} · v${Number(quote.version || 1)}</span><strong class="quote-card-total">${euro.format(Number(quote.total || 0))}</strong></span>
        </button>
        <div class="quote-card-footer"><span class="quote-card-date">Editado ${formatSavedDate(quote.updatedAt)}</span><button class="quote-delete" type="button" data-delete-quote="${escapeAttr(quote.id)}">Eliminar</button></div>
      </article>`).join("") : `<p class="quotes-empty">No hay presupuestos que coincidan.</p>`;
  }

  async function loadSavedQuotes() {
    if (!currentUser || isLoadingQuotes) return;
    isLoadingQuotes = true;
    const button = $("#refreshQuotes");
    button.disabled = true;
    button.textContent = "Cargando…";
    try {
      const result = await getDocs(query(collection(db, "quotes"), orderBy("updatedAt", "desc")));
      savedQuotes = result.docs.map((snapshot) => ({ id: snapshot.id, ...snapshot.data() }));
      renderSavedQuotes();
    } finally {
      isLoadingQuotes = false;
      button.disabled = false;
      button.textContent = "Actualizar";
    }
  }

  async function saveQuote() {
    if (!currentUser || isSaving || isLoadingQuote || isLoadingQuotes || isDeleting) return;
    isSaving = true;
    const button = $("#saveQuote");
    button.disabled = true;
    button.classList.add("is-loading");
    button.textContent = "Guardando…";
    setSaveStatus("Guardando…");
    syncStateFromForm();
    setEditorBusy(true);
    flushPreviewRender(true);
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
      try {
        await loadSavedQuotes();
      } catch (error) {
        console.error(error);
        setSaveStatus("Guardado, pero no se ha podido actualizar el histórico");
        return;
      }
      setSaveStatus("Guardado");
    } catch (error) {
      console.error(error);
      setSaveStatus(error.code === "permission-denied" ? "No tienes permisos para guardar este presupuesto" : "No se ha podido guardar");
    } finally {
      isSaving = false;
      button.disabled = false;
      button.classList.remove("is-loading");
      button.textContent = "Guardar";
      setEditorBusy(false);
    }
  }

  async function openQuote(id, trigger) {
    if (isLoadingQuote || isSaving || isLoadingQuotes || isDeleting) return;
    const quote = savedQuotes.find((entry) => entry.id === id);
    if (!quote) return;
    isLoadingQuote = true;
    if (trigger) {
      trigger.disabled = true;
      trigger.classList.add("is-loading");
      trigger.setAttribute("aria-busy", "true");
    }
    setSaveStatus("Cargando presupuesto…");
    setEditorBusy(true);
    try {
      await new Promise((resolve) => requestAnimationFrame(resolve));
      state = normalizeState(JSON.parse(quote.payload));
      state.quoteId = id;
      render();
      setSaveStatus(`Presupuesto cargado · versión ${quote.version || 1}`);
    } catch {
      setSaveStatus("El presupuesto guardado no es válido");
    } finally {
      isLoadingQuote = false;
      setEditorBusy(false);
      renderSavedQuotes();
    }
  }

  async function deleteQuote(id) {
    if (isSaving || isLoadingQuote || isLoadingQuotes || isDeleting) return;
    const quote = savedQuotes.find((entry) => entry.id === id);
    if (!quote || !window.confirm(`¿Eliminar ${quote.quoteNumber || "este presupuesto"} y todo su historial? Esta acción no se puede deshacer.`)) return;
    isDeleting = true;
    setEditorBusy(true);
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
      try {
        await loadSavedQuotes();
      } catch (error) {
        console.error(error);
        render();
        setSaveStatus("Presupuesto eliminado, pero no se ha podido actualizar el histórico");
        return;
      }
      render();
      setSaveStatus("Presupuesto eliminado");
    } catch (error) {
      console.error(error);
      setSaveStatus(error.code === "permission-denied" ? "No tienes permisos para eliminar este presupuesto" : "No se ha podido eliminar");
    } finally {
      isDeleting = false;
      setEditorBusy(false);
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
      if (!item) return false;
      item[target.dataset.field] = target.type === "number" ? Number(target.value) : target.value;
      if (target.dataset.field === "name") item.nameEdited = true;
      if (target.dataset.field === "description") item.descriptionEdited = true;
      updateItemLineTotal(target, item);
      schedulePreviewRender();
      return true;
    }
    return false;
  }

  function syncStateFromForm() {
    ["language", "quoteNumber", "quoteDate", "validUntil", "clientName", "clientEmail", "status", "eventName", "eventDate", "eventPlace", "guests", "intro"].forEach((field) => {
      const target = $(`#${field}`);
      if (!target) return;
      state[field] = field === "guests" ? Number(target.value || 0) : target.value;
    });
    state.includeTax = $("#includeTax").checked;
    state.hideBranding = $("#hideBranding").checked;
    state.terms = $("#terms").value.split("\n");
    $("#itemsBody").querySelectorAll("[data-item]").forEach((target) => {
      const item = state.items[Number(target.dataset.item)];
      if (!item) return;
      const value = target.type === "number" ? Number(target.value || 0) : target.value;
      item[target.dataset.field] = value;
      const base = allItems.find((entry) => entry.id === item.id);
      if (base && target.dataset.field === "name") item.nameEdited = value !== itemText(base, currentLanguage()).name;
      if (base && target.dataset.field === "description") item.descriptionEdited = value !== String(itemText(base, currentLanguage()).description || "");
    });
  }

  function bindEvents() {
    document.addEventListener("input", (event) => {
      if (event.target.tagName !== "SELECT" && event.target.type !== "checkbox") updateFromTarget(event.target);
    });
    document.addEventListener("change", (event) => updateFromTarget(event.target));
    document.addEventListener("click", (event) => {
      const removeButton = event.target.closest("[data-remove]");
      if (removeButton) {
        state.items.splice(Number(removeButton.dataset.remove), 1);
        render();
        return;
      }
      const openButton = event.target.closest("[data-open-quote]");
      if (openButton) {
        openQuote(openButton.dataset.openQuote, openButton);
        return;
      }
      const deleteButton = event.target.closest("[data-delete-quote]");
      if (deleteButton) deleteQuote(deleteButton.dataset.deleteQuote);
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
      state.items.push({ ...item, ...itemText(item), qty: 1, custom: false, nameEdited: false, descriptionEdited: false });
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
    $("#refreshQuotes").addEventListener("click", () => loadSavedQuotes().catch((error) => {
      console.error(error);
      setSaveStatus(error.code === "permission-denied" ? "No tienes permisos para cargar el histórico" : "No se ha podido cargar el histórico");
    }));
    $("#quoteSearch").addEventListener("input", renderSavedQuotes);
    $("#printQuote").addEventListener("click", printQuote);
    window.addEventListener("afterprint", finishPrinting);
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

  function setEditorBusy(busy) {
    const appShell = $("#quoteApp");
    appShell.classList.toggle("is-busy", busy);
    appShell.setAttribute("aria-busy", String(busy));
  }

  function printQuote() {
    if (isPrinting || isSaving || isLoadingQuote || isLoadingQuotes || isDeleting) return;
    isPrinting = true;
    const button = $("#printQuote");
    button.disabled = true;
    button.classList.add("is-loading");
    button.textContent = "Preparando PDF…";
    button.setAttribute("aria-busy", "true");
    setSaveStatus("Preparando vista para imprimir…");
    syncStateFromForm();
    flushPreviewRender(true);

    requestAnimationFrame(() => requestAnimationFrame(() => {
      syncStateFromForm();
      flushPreviewRender(true);
      const quote = $("#preview .quote-sheet");
      if (!quote) {
        setSaveStatus("No se ha podido preparar el presupuesto");
        finishPrinting();
        return;
      }
      window.print();
    }));
  }

  function finishPrinting() {
    if (!isPrinting) return;
    isPrinting = false;
    const button = $("#printQuote");
    button.disabled = false;
    button.classList.remove("is-loading");
    button.textContent = "Imprimir / PDF";
    button.removeAttribute("aria-busy");
    if ($("#saveStatus").textContent === "Preparando vista para imprimir…") setSaveStatus("");
  }

  function formatDate(value) {
    if (!isValidDateValue(value)) return "";
    const date = new Date(`${value}T00:00:00`);
    const locales = { ca: "ca-ES", es: "es-ES", en: "en-GB" };
    return new Intl.DateTimeFormat(locales[currentLanguage()] || "ca-ES", { day: "2-digit", month: "long", year: "numeric" }).format(date);
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
    if (!adminEmails.includes(user.email) || !user.emailVerified) {
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
      setSaveStatus(error.code === "permission-denied" ? "No tienes permisos para cargar el histórico" : "No se ha podido cargar el histórico");
      console.error(error);
    }
  });
})();
