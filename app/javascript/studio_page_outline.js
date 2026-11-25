import { isWave } from "./studio_editor_controls"

const clean = value => String(value || "").replace(/\s+/g, " ").trim()
const shorten = value => value.length > 78 ? value.slice(0, 77) + "…" : value
const plainText = value => {
  const template = document.createElement("template")
  template.innerHTML = value || ""
  return template.content.textContent || ""
}
const textOf = component => {
  if (["svg", "path", "style", "script"].includes(component.get("tagName"))) return ""
  return clean([plainText(component.get("content")), ...component.components().map(textOf)].join(" "))
}
const descendants = component => component.components().map(child => [child, ...descendants(child)]).flat()

export function outlineLabel(component, config) {
  const attributes = component.getAttributes()
  const tag = component.get("tagName")
  const classes = component.getClasses()
  const text = shorten(textOf(component))
  if (component.get("type") === "textnode") return text ? `Texte : ${text}` : "Texte vide"
  if (attributes["data-studio-dynamic"]) return attributes["data-studio-dynamic"]
  if (isWave(component)) {
    const fills = descendants(component).filter(item => item.get("tagName") === "path").map(path => path.getAttributes().fill || path.getStyle().fill || "").join(" ")
    return /--gold|#(?:cdae4f|d2b34e|d4bc5d|d2b34f)/i.test(fills) ? "Vague dorée" : "Vague de séparation"
  }
  if (/^h[1-6]$/.test(tag)) return `Titre${text ? " : " + text : " à écrire"}`
  if (tag === "a" || tag === "button") return `${classes.some(name => /btn|button/.test(name)) || tag === "button" ? "Bouton" : "Lien"}${text ? " : " + text : " sans texte"}`
  if (tag === "img") return `Image : ${shorten(clean(attributes.alt)) || "description à compléter"}`
  if (tag === "figure") return `Image et légende${text ? " : " + text : ""}`
  if (tag === "video") return "Vidéo"
  if (tag === "hr") return "Ligne de séparation"
  if (tag === "ul" || tag === "ol") return `Liste${text ? " : " + text : ""}`
  if (tag === "blockquote") return `Citation${text ? " : " + text : ""}`
  if (tag === "details") return `Texte à déplier${text ? " : " + text : ""}`
  if (["p", "span", "strong", "em", "small", "li", "summary"].includes(tag)) return `Texte${text ? " : " + text : " à écrire"}`

  const heading = descendants(component).find(item => /^h[1-3]$/.test(item.get("tagName")))
  const title = heading && shorten(textOf(heading))
  const block = config.pages[config.page]?.blocks?.find(item => item.id === attributes["data-studio-block"])
  if (!block && tag === "section" && component.closest("[data-studio-block]")) return "Contenu de la section"
  if (classes.includes("container")) return title ? "Titre et présentation" : text ? "Zone de texte" : "Zone de contenu"
  if (block || tag === "section" || tag === "article") {
    const name = block?.template === "home-0" ? "Présentation d’accueil" : "Section"
    return `${name}${title ? " : " + title : block ? " : " + (config.templates[block.template]?.name || "Contenu libre") : " de contenu"}`
  }
  if (classes.some(name => /gallery/.test(name))) return "Galerie d’images"
  if (classes.some(name => /grid|columns/.test(name))) return "Éléments en colonnes"
  if (classes.includes("studio-spacer") || (!component.components().length && !text)) return "Espace vide"
  return title ? `Groupe : ${title}` : text ? `Groupe : ${text}` : "Groupe d’éléments"
}

function decorateLayer(component, el, config) {
  const row = el.querySelector(":scope > [data-toggle-select]")
  if (!row) return
  const label = outlineLabel(component, config)
  const name = row.querySelector("[data-name]")
  // Labels are UI text, never HTML or persisted component properties.
  name.textContent = label
  name.setAttribute("role", "button")
  name.setAttribute("tabindex", "0")
  name.setAttribute("aria-label", `Sélectionner ${label}`)
  row.querySelector(".gjs-layer-title-inn").title = label
  const control = (selector, title) => {
    const element = row.querySelector(selector)
    if (!element) return
    element.title = title
    element.setAttribute("aria-label", title)
    element.setAttribute("role", "button")
    element.setAttribute("tabindex", "0")
    return element
  }
  const visible = component.getStyle().display !== "none"
  control("[data-toggle-visible]", `${visible ? "Masquer" : "Afficher"} ${label}`)?.setAttribute("aria-pressed", String(!visible))
  const hasChildren = component.components().some(child => child.get("layerable") && child.get("type") !== "textnode")
  const caret = control("[data-toggle-open]", `${component.get("open") ? "Replier" : "Déplier"} ${label}`)
  caret?.setAttribute("aria-expanded", String(Boolean(component.get("open"))))
  caret?.setAttribute("tabindex", hasChildren ? "0" : "-1")
  if (!hasChildren) caret?.removeAttribute("role")
  const move = row.querySelector("[data-toggle-move]")
  if (move) move.title = `Glisser pour déplacer ${label}`
}

export const outlineOptions = config => ({
  appendTo: "[data-studio-layers]", showWrapper: false,
  onInit({ component, render }) { this.listenTo(component, "change:open change:style:display", render) },
  onRender({ component, el }) { decorateLayer(component, el, config) },
  extend: { handleEdit(event) { event?.preventDefault(); event?.stopPropagation() } }
})

export function installPageOutline(editor, root, config) {
  const pending = new Set()
  let frame
  editor.on("component:update component:add component:remove", component => {
    for (let item = component; item; item = item.parent()) pending.add(item)
    cancelAnimationFrame(frame)
    frame = requestAnimationFrame(() => {
      pending.forEach(item => { if (item.viewLayer?.el) decorateLayer(item, item.viewLayer.el, config) })
      pending.clear()
    })
  })
  root.querySelector("[data-studio-layers]").addEventListener("keydown", event => {
    const control = event.target.closest("[data-toggle-open],[data-toggle-visible],[data-name]")
    if (!control || !["Enter", " "].includes(event.key)) return
    event.preventDefault(); event.stopPropagation(); control.click()
  }, true)
  editor.on("load", () => {
    const wrapper = editor.getWrapper()
    descendants(wrapper).forEach(component => {
      if (["template", "style", "script", "link", "meta"].includes(component.get("tagName"))) component.set("layerable", false)
    })
    const page = wrapper.find("[data-studio-page] .page")[0] || wrapper.find("[data-studio-page]")[0] || wrapper
    editor.LayerManager.setRoot(page)
    editor.LayerManager.setOpen(page, true)
  })
}
