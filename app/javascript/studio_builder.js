import grapesjs from "grapesjs"
import "grapesjs/dist/css/grapes.min.css"
import "./stylesheets/studio_builder.css"
import french from "grapesjs/locale/fr.mjs"
import { registerWave, installControls, waveSelector, isWave } from "./studio_editor_controls"
import { installLegalEditor } from "./studio_legal_editor"

const root = document.querySelector("[data-studio-builder]")

if (root) {
  const config = JSON.parse(root.querySelector("[data-studio-config]").textContent)
  const library = root.querySelector("[data-studio-library]")
  const status = root.querySelector("[data-studio-status]")
  const saveButton = root.querySelector("[data-studio-save]")
  const csrf = document.querySelector("meta[name='csrf-token']")?.content
  let dirty = false
  let saving = false
  let ready = false
  let baseline = ""

  const esc = value => String(value || "").replace(/[&<>\"]/g, character => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" })[character])
  const svgIcon = path => `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="${path}"/></svg>`
  const icons = {
    heading: "M5 6v12M19 6v12M5 12h14", paragraph: "M6 5h12M6 9h12M6 13h9M6 17h11",
    image: "M4 5h16v14H4z M6 17l4-5 3 3 2-2 4 4", button: "M4 8h16v8H4z M9 12h6",
    container: "M3 5h18v14H3z", columns: "M3 5h8v14H3z M13 5h8v14h-8z", divider: "M3 12h18",
    spacer: "M5 4h14M5 20h14M12 5v14M9 8l3-3 3 3M9 16l3 3 3-3", wave: "M2 15c4-7 7 7 11 0s6-3 9-1",
    bubbles: "M7 14a3 3 0 1 0 0-6 3 3 0 0 0 0 6zM16 18a4 4 0 1 0 0-8 4 4 0 0 0 0 8z",
    curve: "M2 18c5-13 15-13 20 0", diagonal: "M3 17 21 7v10H3z",
    eyebrow: "M5 7h14M8 12h8M10 17h4", quote: "M7 9h4v4H8l-2 4M15 9h4v4h-3l-2 4",
    list: "M9 6h11M9 12h11M9 18h11M4 6h1M4 12h1M4 18h1", video: "M4 6h12v12H4zM16 10l4-2v8l-4-2z",
    card: "M4 4h16v16H4zM4 9h16", callout: "M12 3 2 21h20zM12 9v5M12 18h.01",
    accordion: "M4 6h16v5H4zM4 14h16v5H4z", stats: "M5 19V9h4v10M10 19V5h4v14M15 19v-7h4v7",
    gallery: "M3 5h8v6H3zM13 5h8v6h-8zM3 13h8v6H3zM13 13h8v6h-8z",
    columns3: "M3 5h5v14H3zM10 5h4v14h-4zM16 5h5v14h-5z", stack: "M4 5h16v5H4zM4 14h16v5H4z",
    hero: "M3 5h18v14H3zM6 9h6M6 13h9M17 9h2v6h-2z", zigzag: "M2 16l4-8 4 8 4-8 4 8 4-8",
    dots: "M5 12h.01M12 12h.01M19 12h.01", gradient: "M4 5h16v14H4z"
  }
  const imageSource = config.templates.image?.html?.match(/src="([^"]+)"/)?.[1] || ""
  const blocks = [
    ["heading", "Titre", "<h2>Votre nouveau titre</h2>", "Éléments"],
    ["paragraph", "Texte", "<p>Double-cliquez pour écrire votre texte.</p>", "Éléments"],
    ["eyebrow", "Petit titre", '<span class="eyebrow">Votre introduction</span>', "Éléments"],
    ["quote", "Citation", '<blockquote class="studio-quote"><p>Une phrase forte ou un témoignage éditorial.</p><cite>Nom de la personne</cite></blockquote>', "Éléments"],
    ["list", "Liste", '<ul class="studio-list"><li>Premier élément</li><li>Deuxième élément</li><li>Troisième élément</li></ul>', "Éléments"],
    ["image", "Image", `<figure><img src="${esc(imageSource)}" alt="Décrivez cette image"><figcaption>Votre légende</figcaption></figure>`, "Éléments"],
    ["video", "Vidéo", `<video controls playsinline preload="metadata" poster="${esc(imageSource)}">Ajoutez l’adresse HTTPS de votre vidéo dans les réglages de contenu.</video>`, "Médias"],
    ["gallery", "Galerie 4 images", `<div class="studio-gallery"><img src="${esc(imageSource)}" alt="Description de l’image 1"><img src="${esc(imageSource)}" alt="Description de l’image 2"><img src="${esc(imageSource)}" alt="Description de l’image 3"><img src="${esc(imageSource)}" alt="Description de l’image 4"></div>`, "Médias"],
    ["button", "Bouton", '<a class="btn btn-deep" href="/contact">Votre bouton</a>', "Éléments"],
    ["card", "Carte", '<article class="studio-card"><h3>Titre de la carte</h3><p>Présentez une information importante.</p><a href="/contact">En savoir plus</a></article>', "Éléments"],
    ["callout", "Encadré important", '<aside class="studio-callout"><strong>À retenir</strong><p>Ajoutez une information à mettre particulièrement en valeur.</p></aside>', "Éléments"],
    ["accordion", "Accordéon", '<details class="studio-accordion"><summary>Question ou information</summary><div><p>Le contenu détaillé apparaît à l’ouverture.</p></div></details>', "Éléments"],
    ["stats", "Chiffres clés", '<div class="studio-stats"><div><strong>1 200</strong><span>Membres</span></div><div><strong>340</strong><span>Services rendus</span></div><div><strong>86</strong><span>Villes</span></div></div>', "Éléments"],
    ["divider", "Séparateur", "<hr>", "Éléments"],
    ["spacer", "Espace", '<div style="min-height:80px"></div>', "Éléments"],
    ["container", "Conteneur", '<div class="container" style="min-height:120px;padding:32px"></div>', "Mise en page"],
    ["columns", "2 colonnes", '<div class="studio-grid-2"><div style="min-height:120px;padding:24px"></div><div style="min-height:120px;padding:24px"></div></div>', "Mise en page"],
    ["columns3", "3 colonnes", '<div class="studio-grid-3"><div style="min-height:120px;padding:24px"></div><div style="min-height:120px;padding:24px"></div><div style="min-height:120px;padding:24px"></div></div>', "Mise en page"],
    ["stack", "Pile verticale", '<div class="studio-stack"><div style="min-height:80px;padding:24px"></div><div style="min-height:80px;padding:24px"></div></div>', "Mise en page"],
    ["hero", "Hero libre", `<section class="studio-hero"><div><span class="eyebrow">Votre accroche</span><h1>Un grand titre mémorable</h1><p>Présentez votre proposition en quelques mots.</p><a class="btn btn-gold" href="/contact">Passer à l’action</a></div><img src="${esc(imageSource)}" alt="Décrivez l’image principale"></section>`, "Mise en page"],
    ["card-grid", "Grille de cartes", '<section class="studio-card-grid"><article class="studio-card"><h3>Première carte</h3><p>Votre contenu.</p></article><article class="studio-card"><h3>Deuxième carte</h3><p>Votre contenu.</p></article><article class="studio-card"><h3>Troisième carte</h3><p>Votre contenu.</p></article></section>', "Mise en page"],
    ["wave", "Vague", '<div class="studio-transition studio-transition--wave"><svg viewBox="0 0 1200 120" preserveAspectRatio="none"><path d="M0 45 C240 120 420 0 660 55 C880 110 1020 18 1200 58 L1200 120 L0 120 Z"></path></svg></div>', "Transitions"],
    ["bubbles", "Bulles", '<div class="studio-transition studio-transition--bubbles"><span></span><span></span><span></span><span></span></div>', "Transitions"],
    ["curve", "Courbe", '<div class="studio-transition studio-transition--curve"><span></span></div>', "Transitions"],
    ["diagonal", "Diagonale", '<div class="studio-transition studio-transition--diagonal"><span></span></div>', "Transitions"],
    ["zigzag", "Zigzag", '<div class="studio-transition studio-transition--zigzag"><span></span></div>', "Transitions"],
    ["dots", "Points", '<div class="studio-transition studio-transition--dots"><span></span></div>', "Décorations"],
    ["gradient", "Halo dégradé", '<div class="studio-decoration studio-decoration--gradient"></div>', "Décorations"]
  ]

  const editor = grapesjs.init({
    container: "#studio-v2-editor",
    height: "100%",
    width: "auto",
    storageManager: false,
    noticeOnUnload: false,
    telemetry: false,
    i18n: { locale: "fr", localeFallback: "fr", messages: { fr: french } },
    canvasCss: `${waveSelector}{pointer-events:auto!important;cursor:pointer}.studio-wave-selection{outline:2px solid #087b91!important}`,

    cssIcons: "",
    components: config.initialHtml,
    style: `${config.initialCss}\n.studio-grid-2,.studio-grid-3,.studio-card-grid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px}.studio-grid-3,.studio-card-grid{grid-template-columns:repeat(3,minmax(0,1fr))}.studio-stack{display:flex;flex-direction:column;gap:20px}.studio-hero{display:grid;grid-template-columns:minmax(0,1fr) minmax(280px,.85fr);gap:48px;align-items:center;padding:72px max(24px,6vw)}.studio-hero img{width:100%;min-height:360px;object-fit:cover;border-radius:32px}.studio-gallery{display:grid;grid-template-columns:repeat(2,1fr);gap:12px}.studio-gallery img{width:100%;aspect-ratio:4/3;object-fit:cover;border-radius:16px}.studio-card{padding:28px;border:1px solid var(--line,#dbe5e7);border-radius:20px;background:var(--white,#fff);box-shadow:0 12px 32px rgba(7,62,80,.08)}.studio-callout{padding:24px;border-left:5px solid var(--gold,#d2b34e);border-radius:12px;background:var(--mist,#eef5f5)}.studio-quote{max-width:65ch;padding:28px;border-left:5px solid var(--gold,#d2b34e);font-size:1.25rem}.studio-list{display:grid;gap:10px}.studio-accordion{border:1px solid var(--line,#dbe5e7);border-radius:14px;background:#fff}.studio-accordion summary{padding:18px;font-weight:700;cursor:pointer}.studio-accordion div{padding:0 18px 18px}.studio-stats{display:grid;grid-template-columns:repeat(3,1fr);gap:16px;text-align:center}.studio-stats div{padding:24px;border-radius:18px;background:var(--mist,#eef5f5)}.studio-stats strong,.studio-stats span{display:block}.studio-stats strong{font-size:2rem;color:var(--deep,#073e50)}.studio-transition{position:relative;min-height:90px;overflow:hidden}.studio-transition--wave svg{display:block;width:100%;height:var(--wave-height,90px);transform:rotate(var(--wave-angle,0deg));transform-origin:center}.studio-transition--wave path{fill:var(--wave-color,#d2b34e)}.studio-transition--bubbles span{position:absolute;border-radius:50%;background:var(--bubble-color,#d2b34e);opacity:.72}.studio-transition--bubbles span:nth-child(1){width:44px;height:44px;left:8%;top:24px}.studio-transition--bubbles span:nth-child(2){width:76px;height:76px;left:32%;top:5px}.studio-transition--bubbles span:nth-child(3){width:30px;height:30px;right:28%;top:40px}.studio-transition--bubbles span:nth-child(4){width:60px;height:60px;right:8%;top:15px}.studio-transition--curve span,.studio-transition--diagonal span,.studio-transition--zigzag span{position:absolute;inset:0;background:var(--transition-color,#d2b34e)}.studio-transition--curve span{border-radius:50% 50% 0 0/100% 100% 0 0;transform:translateY(32%)}.studio-transition--diagonal span{clip-path:polygon(0 68%,100% 10%,100% 100%,0 100%)}.studio-transition--zigzag span{clip-path:polygon(0 55%,5% 25%,10% 55%,15% 25%,20% 55%,25% 25%,30% 55%,35% 25%,40% 55%,45% 25%,50% 55%,55% 25%,60% 55%,65% 25%,70% 55%,75% 25%,80% 55%,85% 25%,90% 55%,95% 25%,100% 55%,100% 100%,0 100%)}.studio-transition--dots span{position:absolute;inset:12px;background-image:radial-gradient(circle,var(--gold,#d2b34e) 2px,transparent 2.5px);background-size:22px 22px}.studio-decoration{min-height:180px}.studio-decoration--gradient{background:radial-gradient(circle at 30% 50%,rgba(15,151,173,.35),transparent 35%),radial-gradient(circle at 70% 45%,rgba(210,179,78,.35),transparent 32%)}.studio-anim-fade{animation:studioFade .55s ease-out both}.studio-anim-up{animation:studioUp .55s ease-out both}.studio-anim-side{animation:studioSide .55s ease-out both}.studio-anim-zoom{animation:studioZoom .45s ease-out both}.studio-anim-float{animation:studioFloat 4s ease-in-out infinite}@keyframes studioFade{from{opacity:0}to{opacity:1}}@keyframes studioUp{from{opacity:0;transform:translateY(28px)}to{opacity:1;transform:none}}@keyframes studioSide{from{opacity:0;transform:translateX(-28px)}to{opacity:1;transform:none}}@keyframes studioZoom{from{opacity:0;transform:scale(.94)}to{opacity:1;transform:none}}@keyframes studioFloat{50%{transform:translateY(-8px)}}@media(max-width:700px){.studio-grid-2,.studio-grid-3,.studio-card-grid,.studio-hero,.studio-stats{grid-template-columns:1fr}.studio-hero{padding:40px 20px}.studio-hero img{min-height:240px}}@media(prefers-reduced-motion:reduce){.studio-anim-fade,.studio-anim-up,.studio-anim-side,.studio-anim-zoom,.studio-anim-float{animation:none!important}}`,
    canvas: { styles: config.stylesheets },
    blockManager: { appendTo: library },
    layerManager: { appendTo: "[data-studio-layers]" },
    traitManager: { appendTo: "[data-studio-traits]" },
    selectorManager: { componentFirst: true },
    deviceManager: { devices: [
      { id: "Desktop", name: "Ordinateur", width: "" },
      { id: "Tablet", name: "Tablette", width: "768px", widthMedia: "992px" },
      { id: "Mobile portrait", name: "Téléphone", width: "390px", widthMedia: "600px" }
    ] },
    styleManager: {
      appendTo: "[data-studio-styles]",
      sectors: [
        { name: "Typographie", open: true, buildProps: ["font-family", "font-size", "font-weight", "line-height", "letter-spacing", "color", "text-align", "text-decoration", "text-shadow"] },
        { name: "Dimensions et position", open: false, buildProps: ["display", "position", "top", "right", "bottom", "left", "width", "min-height", "max-width", "overflow"] },
        { name: "Espacement", open: false, buildProps: ["margin", "padding", "gap"] },
        { name: "Fond", open: false, buildProps: ["background-color", "background", "opacity"] },
        { name: "Bordure et forme", open: false, buildProps: ["border", "border-radius", "box-shadow"] },
        { name: "Transformation et animation", open: false, buildProps: ["transform", "transition", "animation"] }
      ]
    },
    panels: { defaults: [] },
    plugins: [instance => {
      registerWave(instance)
      instance.DomComponents.addType("studio-page", {
        isComponent: element => element.hasAttribute?.("data-studio-page"),
        model: { defaults: { selectable: false, hoverable: false, draggable: false, removable: false, copyable: false } }
      })
      instance.DomComponents.addType("studio-dynamic", {
        isComponent: element => element.hasAttribute?.("data-studio-dynamic"),
        model: {
          defaults: { droppable: false, editable: false, copyable: false, removable: false },
          init() {
            const protect = component => {
              component.set({ selectable: false, hoverable: false, draggable: false, droppable: false, editable: false, copyable: false, removable: false, stylable: false })
              component.components().each(protect)
            }
            this.components().each(protect)
          }
        }
      })
      instance.DomComponents.addType("studio-chrome", {
      isComponent: element => element.hasAttribute?.("data-studio-chrome"),
      model: { defaults: { selectable: false, hoverable: false, layerable: false, draggable: false, droppable: false, copyable: false, removable: false } }
      })
    }],
    richTextEditor: { actions: ["bold", "italic", "underline", "strikethrough", "link"] }
  })

  const categoryFor = key => {
    if (key.startsWith("home-")) return "Accueil"
    if (key.startsWith("travel-")) return "Voyage solidaire"
    if (key.startsWith("community-")) return "Communauté"
    if (/^(don|exchange|points)-/.test(key)) return "Don, échange et points"
    return "Compositions"
  }
  const addBlock = (id, name, html, category, kind = "widget") => editor.BlockManager.add(`seos-${id}`, {
    label: `<span class="visual-template-icon">${svgIcon(icons[id] || icons.container)}</span><strong>${esc(name)}</strong><button type="button" class="visual-template-add" tabindex="-1">＋</button>`,
    content: html,
    category: { id: `${kind}-${category}`, label: category, open: category === "Éléments" || category === "Compositions" },
    attributes: { "data-library-kind": kind, "data-block-id": `seos-${id}`, "data-search": `${name} ${category}`.toLowerCase(), title: `Glisser ${name}` }
  })
  blocks.forEach(block => addBlock(...block))
  Object.entries(config.templates).filter(([key]) => !["heading", "paragraph", "image", "button", "divider", "spacer", "text", "blank-section"].includes(key)).forEach(([key, value]) => addBlock(`preset-${key}`, value.name, value.html, categoryFor(key), "section"))

  const switchPanel = name => {
    root.querySelectorAll("[data-studio-tab]").forEach(button => button.classList.toggle("is-active", button.dataset.studioTab === name))
    root.querySelectorAll("[data-studio-panel]").forEach(panel => { panel.hidden = panel.dataset.studioPanel !== name; panel.classList.toggle("is-active", !panel.hidden) })
  }
  root.querySelectorAll("[data-studio-tab]").forEach(button => button.addEventListener("click", () => {
    if (button.dataset.studioTab === "legal" && config.page !== "legal") {
      pages.value = "legal"; pages.dispatchEvent(new Event("change")); return
    }
    switchPanel(button.dataset.studioTab)
  }))
  root.querySelector("[data-studio-back]").addEventListener("click", () => switchPanel("library"))

  const setSettingsTab = name => {
    root.querySelectorAll("[data-settings-tab]").forEach(button => button.classList.toggle("is-active", button.dataset.settingsTab === name))
    root.querySelectorAll("[data-settings-panel]").forEach(panel => { panel.hidden = panel.dataset.settingsPanel !== name })
  }
  root.querySelectorAll("[data-settings-tab]").forEach(button => button.addEventListener("click", () => setSettingsTab(button.dataset.settingsTab)))

  editor.on("component:selected", component => {
    const dynamicLabel = component.getAttributes()["data-studio-dynamic"]
    const names = { wrapper: "Page entière", div: "Conteneur", section: "Section", h1: "Titre principal", h2: "Titre", h3: "Sous-titre", p: "Texte", span: "Texte", a: "Lien ou bouton", img: "Image", body: "Page entière" }
    const label = dynamicLabel || (isWave(component) ? "Vague de séparation" : names[component.get("tagName")]) || component.getName() || "Élément"
    root.querySelector("[data-studio-selection-name]").textContent = label.charAt(0).toUpperCase() + label.slice(1)
    root.querySelector("[data-dynamic-notice]").hidden = !dynamicLabel
    root.querySelector('[data-settings-tab="content"]').disabled = Boolean(dynamicLabel)
    root.querySelector("[data-studio-delete]").disabled = Boolean(dynamicLabel)
    const animation = component.getClasses().find(name => name.startsWith("studio-anim-")) || ""
    root.querySelector("[data-studio-animation]").value = animation
    switchPanel(dynamicLabel === "Documents légaux" ? "legal" : "settings")
  })
  const originalIds = new Set(Array.from(new DOMParser().parseFromString(config.initialHtml, "text/html").querySelectorAll("[id]")).map(node => node.id))
  const snapshot = () => {
    const html = new DOMParser().parseFromString(editor.getHtml(), "text/html")
    html.querySelectorAll("[data-studio-chrome]").forEach(node => node.remove())
    html.querySelectorAll("[id]").forEach(node => { if (/^i[a-z0-9]+$/.test(node.id) && !originalIds.has(node.id)) node.removeAttribute("id") })
    return JSON.stringify([html.body.innerHTML, (editor.getCss() || "").replace(/[^{}]+\{\s*\}/g, ""), config.settings.legal_documents || {}])
  }
  const refreshDirty = () => {
    if (!ready) return
    dirty = snapshot() !== baseline
    status.textContent = dirty ? "Modifications non enregistrées" : "Toutes les modifications sont enregistrées"
    status.dataset.state = dirty ? "dirty" : "saved"
  }
  let dirtyFrame
  editor.on("component:add component:remove component:update styleable:change", () => {
    cancelAnimationFrame(dirtyFrame)
    dirtyFrame = requestAnimationFrame(refreshDirty)
  })
  installControls(editor, root)
  installLegalEditor(root, config, editor, refreshDirty)
  root.querySelectorAll("[data-device]").forEach(button => button.addEventListener("click", () => {
    editor.setDevice(button.dataset.device)
    root.querySelectorAll("[data-device]").forEach(item => item.classList.toggle("is-active", item === button))
  }))
  root.querySelectorAll("[data-studio-command]").forEach(button => button.addEventListener("click", () => editor.Commands.run(`core:${button.dataset.studioCommand}`)))
  root.querySelector("[data-studio-delete]").addEventListener("click", () => {
    const selected = editor.getSelected()
    if (selected && !selected.getAttributes()["data-studio-dynamic"]) selected.remove()
  })
  root.querySelector("[data-studio-animation]").addEventListener("change", event => {
    const selected = editor.getSelected()
    if (!selected) return
    selected.getClasses().filter(name => name.startsWith("studio-anim-")).forEach(name => selected.removeClass(name))
    if (event.target.value) selected.addClass(event.target.value)
  })
  root.querySelector("[data-studio-fullscreen]").addEventListener("click", () => root.classList.toggle("visual-focus"))
  const updateLibrary = () => {
    const view = root.dataset.libraryView || "widgets"
    const query = root.querySelector("[data-studio-search]").value.trim().toLowerCase()
    let count = 0
    library.querySelectorAll(".gjs-block").forEach(block => {
      const kind = block.dataset.libraryKind === "section" ? "sections" : "widgets"
      block.hidden = kind !== view || (query && !block.dataset.search.includes(query))
      if (!block.hidden) count += 1
    })
    library.querySelectorAll(".gjs-block-category").forEach(category => { category.hidden = !category.querySelector(".gjs-block:not([hidden])") })
    root.querySelector("[data-library-empty]").hidden = count > 0
  }
  root.dataset.libraryView = "widgets"
  root.querySelectorAll("[data-library-view]").forEach(button => button.addEventListener("click", () => {
    root.dataset.libraryView = button.dataset.libraryView
    root.querySelectorAll("[data-library-view]").forEach(item => item.classList.toggle("is-active", item === button))
    root.querySelector("[data-studio-search]").value = ""
    updateLibrary()
  }))
  root.querySelector("[data-studio-search]").addEventListener("input", updateLibrary)
  library.addEventListener("click", event => {
    const button = event.target.closest(".visual-template-add")
    if (!button) return
    event.preventDefault()
    event.stopPropagation()
    const blockElement = button.closest(".gjs-block")
    const block = editor.BlockManager.get(blockElement?.dataset.blockId)
    if (!block) return
    const container = editor.getWrapper().find("[data-studio-page] .page")[0] || editor.getWrapper().find("[data-studio-page]")[0] || editor.getWrapper()
    const added = container.append(block.get("content"))
    const selected = Array.isArray(added) ? added[0] : added
    if (selected) editor.select(selected)
  })

  const pages = root.querySelector("[data-studio-pages]")
  Object.entries(config.pages).forEach(([slug, page]) => pages.add(new Option(page.title || slug, slug, false, slug === config.page)))
  pages.addEventListener("change", async () => {
    const slug = pages.value
    refreshDirty()
    if (dirty) {
      const result = await save()
      if (!result || dirty) { pages.value = config.page; return }
    }
    dirty = false
    const url = new URL(window.location.href); url.searchParams.set("page", slug); window.location.assign(url)
  })

  const save = async () => {
    if (saving) return null
    saving = true
    saveButton.disabled = true
    pages.disabled = true
    root.querySelector("[data-studio-review]").disabled = true
    saveButton.textContent = "Enregistrement…"
    status.textContent = "Enregistrement…"
    const savedSnapshot = snapshot()
    const settings = structuredClone(config.settings)
    settings.site ||= {}; settings.site.pages ||= {}
    settings.site.pages[config.page] ||= config.pages[config.page]
    const document = new DOMParser().parseFromString(editor.getHtml(), "text/html")
    document.querySelectorAll("[data-studio-chrome]").forEach(element => element.remove())
    document.querySelectorAll("[data-studio-page]").forEach(element => element.replaceWith(...element.childNodes))
    settings.site.pages[config.page].canvas = { version: 1, html: document.body.innerHTML, css: editor.getCss() }
    const body = new FormData()
    body.append("document", JSON.stringify({ site: settings.site, tokens: settings.tokens || {}, legal_documents: settings.legal_documents || {} }))
    body.append("digest", config.digest)
    body.append("page", config.page)
    try {
      const response = await fetch(config.save, { method: "POST", headers: { "X-CSRF-Token": csrf, Accept: "application/json" }, body })
      const result = await response.json()
      if (!response.ok) throw new Error(result.error || "Impossible d’enregistrer")
      const pendingLegalDocuments = config.settings.legal_documents
      config.digest = result.digest; config.save = result.save; config.review = result.review; config.settings = settings
      config.settings.legal_documents = pendingLegalDocuments
      baseline = savedSnapshot; refreshDirty(); if (!dirty) status.textContent = "Modifications enregistrées"
      window.history.replaceState({}, "", result.url + `?page=${encodeURIComponent(config.page)}`)
      return result
    } catch (error) {
      status.textContent = error.message; status.dataset.state = "error"; return null
    } finally {
      saving = false
      saveButton.disabled = false
      pages.disabled = false
      root.querySelector("[data-studio-review]").disabled = false
      saveButton.textContent = "Enregistrer"
    }
  }
  saveButton.addEventListener("click", save)
  root.querySelector("[data-studio-review]").addEventListener("click", async () => { const result = await save(); if (result && !dirty) window.location.assign(result.review) })
  window.addEventListener("beforeunload", event => { if (ready && snapshot() !== baseline) event.preventDefault() })
  editor.on("load", () => {
    const protect = component => {
      component.set({ selectable: false, hoverable: false, draggable: false, droppable: false, editable: false, copyable: false, removable: false, stylable: false })
      component.components().each(protect)
    }
    editor.getWrapper().find("[data-studio-dynamic]").forEach(widget => widget.components().each(protect))
    editor.Canvas.getBody().classList.add("app-shell")
    editor.getWrapper().getEl().classList.add("app-shell")
    editor.getWrapper().set({ selectable: false, hoverable: false })
    editor.UndoManager.clear(); editor.clearDirtyCount(); updateLibrary()
    baseline = snapshot(); ready = true; dirty = false
    if (config.page === "legal") switchPanel("legal")
    status.textContent = "Cliquez sur un texte, une image ou une vague pour le modifier."
  })
}
