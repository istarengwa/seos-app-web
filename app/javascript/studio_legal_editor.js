// The visual text editor serializes to the small, escaped document format Rails renders.
export function installLegalEditor(root, config, editor, changed) {
  const select = root.querySelector("[data-legal-document]")
  if (config.legalDocument) select.value = config.legalDocument
  const title = root.querySelector('[data-legal-field="title"]')
  const summary = root.querySelector('[data-legal-field="summary"]')
  const body = root.querySelector("[data-legal-body]")
  const drafts = structuredClone(config.settings.legal_documents || {})
  const documents = structuredClone(config.legalDocuments)
  const editedHtml = {}
  // GrapesJS shortcuts act on the canvas. Keep writing shortcuts in this document.
  body.addEventListener("keydown", event => {
    event.stopPropagation()
    if ((event.ctrlKey || event.metaKey) && event.key.toLowerCase() === "a") {
      event.preventDefault()
      const range = document.createRange()
      range.selectNodeContents(body)
      const selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange(range)
    }
  })
  body.addEventListener("keyup", event => event.stopPropagation())
  const inline = node => {
    if (node.nodeType === Node.TEXT_NODE) return node.textContent
    const text = Array.from(node.childNodes).map(inline).join("")
    if (["STRONG", "B"].includes(node.tagName)) return `**${text}**`
    return node.tagName === "BR" ? "\n" : text
  }
  const serialize = element => Array.from(element.childNodes).map(node => {
    if (node.nodeType === Node.TEXT_NODE) return node.textContent
    if (/^H[1-6]$/.test(node.tagName)) return "## " + inline(node)
    if (["UL", "OL"].includes(node.tagName)) return Array.from(node.children).map(item => "- " + inline(item)).join("\n")
    if (node.tagName === "TABLE" || node.querySelector?.("table")) {
      const rows = Array.from(node.querySelectorAll("tr")).map(row => "| " + Array.from(row.children).map(cell => inline(cell).replaceAll("|", "/")).join(" | ") + " |")
      if (rows.length) rows.splice(1, 0, "| " + Array.from(node.querySelector("tr").children).map(() => "---").join(" | ") + " |")
      return rows.join("\n")
    }
    return inline(node)
  }).filter(text => text.trim()).join("\n\n")
  const refreshPreview = () => {
    const frame = editor.Canvas.getDocument()
    const panel = frame?.querySelector(`.legal-document[data-tab="${select.value}"]`)
    if (!panel) return
    panel.querySelector("h2").textContent = title.value
    const excerpt = panel.querySelector(".legal-document-summary")
    if (excerpt) { excerpt.textContent = summary.value; excerpt.hidden = !summary.value.trim() }
    const content = panel.querySelector(".legal-document-body")
    if (content) content.innerHTML = body.innerHTML
    // Update the canvas without clicking a link: clicking would steal keyboard focus
    // from the document being typed in the sidebar.
    frame.querySelectorAll(".legal-document").forEach(item => { item.hidden = item.dataset.tab !== select.value })
    frame.querySelectorAll(".legal-sidebar a[data-tab]").forEach(tab => {
      if (tab.dataset.tab === select.value) tab.setAttribute("aria-current", "location")
      else tab.removeAttribute("aria-current")
    })
  }
  const update = event => {
    const fields = documents[select.value]
    fields.title = title.value
    fields.summary = summary.value
    if (event?.target === body) fields.body = serialize(body)
    drafts[select.value] = structuredClone(fields)
    config.settings.legal_documents = drafts
    root.querySelector("[data-legal-count]").textContent = fields.body.length
    root.querySelector("[data-legal-state]").textContent = "Brouillon modifié · pas encore en ligne"
    refreshPreview()
    changed()
  }
  const load = () => {
    const fields = documents[select.value]
    title.value = fields.title
    summary.value = fields.summary
    body.innerHTML = config.legalDocumentHtml[select.value]
    // Keep local edits when returning to a document without translating its text again.
    if (editedHtml[select.value]) body.innerHTML = editedHtml[select.value]
    root.querySelector("[data-legal-count]").textContent = fields.body.length
    root.querySelector("[data-legal-state]").textContent = drafts[select.value] ? "Brouillon de cette copie" : fields.base_id ? "Document public · modifications enregistrées dans une nouvelle version" : "Exemple de travail à personnaliser"
    refreshPreview()
  }
  [title, summary].forEach(input => input.addEventListener("input", update))
  body.addEventListener("input", event => { update(event); editedHtml[select.value] = body.innerHTML })
  body.addEventListener("paste", event => { event.preventDefault(); document.execCommand("insertText", false, event.clipboardData.getData("text/plain")) })
  root.querySelectorAll("[data-legal-format]").forEach(button => {
    button.addEventListener("mousedown", event => event.preventDefault())
    button.addEventListener("click", () => {
      body.focus()
      const command = button.dataset.legalFormat
      if (command === "heading" || command === "paragraph") document.execCommand("formatBlock", false, command === "heading" ? "h3" : "p")
      else document.execCommand(command === "list" ? "insertUnorderedList" : "bold")
      update({ target: body }); editedHtml[select.value] = body.innerHTML
    })
  })
  select.addEventListener("change", load)
  root.querySelector("[data-legal-reload]").addEventListener("click", () => {
    documents[select.value] = structuredClone(config.publishedLegalDocuments[select.value])
    config.legalDocumentHtml[select.value] = config.publishedLegalDocumentHtml[select.value]
    delete editedHtml[select.value]
    delete drafts[select.value]
    config.settings.legal_documents = drafts
    load()
    changed()
  })
  editor.on("load", load)
  return () => { load(); body.focus() }
}
