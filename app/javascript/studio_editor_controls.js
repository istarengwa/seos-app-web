export const waveSelector = ".studio-transition--wave,.site-transition,.hero-organic-cut,.page-hero-organic-cut,.public-hero-wave,.yoga-separator,.hero-wave"
export const isWave = component => ["studio-wave", "studio-wave-svg"].includes(component?.get("type"))

export function registerWave(instance) {
  const model = {
    defaults: { name: "Vague de séparation", "custom-name": "Vague de séparation", editable: false, droppable: false },
    init() {
      const protect = child => {
        child.set({ selectable: false, hoverable: false, layerable: false, draggable: false, droppable: false })
        child.components().each(protect)
      }
      this.components().each(protect)
    }
  }
  instance.DomComponents.addType("studio-wave", {
    isComponent: element => element.tagName?.toLowerCase() !== "svg" && element.matches?.(waveSelector), model
  })
  instance.DomComponents.addType("studio-wave-svg", {
    extend: "svg",
    isComponent: element => element.tagName?.toLowerCase() === "svg" && element.matches?.(waveSelector), model
  })
}

export function installControls(editor, root) {
  const field = name => root.querySelector(`[data-wave-control="${name}"]`)
  const selected = () => editor.getSelected()
  const hex = color => {
    if (/^#[0-9a-f]{6}$/i.test(color || "")) return color
    const values = (color || "").match(/\d+/g)
    return values?.length >= 3 ? "#" + values.slice(0, 3).map(value => Number(value).toString(16).padStart(2, "0")).join("") : "#ffffff"
  }
  const synchronize = component => {
    const computed = component.getEl() && editor.Canvas.getWindow().getComputedStyle(component.getEl())
    root.querySelectorAll("[data-simple-style]").forEach(input => {
      const property = input.dataset.simpleStyle
      const value = computed?.getPropertyValue(property) || component.getStyle()[property] || ""
      if (input.type === "color") input.value = hex(value === "rgba(0, 0, 0, 0)" || value === "transparent" ? "#ffffff" : value)
      else if (input.type === "range") input.value = property === "opacity" ? Math.round((Number.isFinite(parseFloat(value)) ? parseFloat(value) : 1) * 100) : parseFloat(value) || 0
      else input.value = value
      const output = input.closest("label")?.querySelector("output")
      if (output) output.textContent = input.value + (property === "opacity" ? " %" : " px")
    })
    root.querySelector("[data-wave-controls]").hidden = !isWave(component)
    if (isWave(component)) {
      const attributes = component.getAttributes()
      const path = component.find("path").at(-1)?.getEl()
      const color = path && editor.Canvas.getWindow().getComputedStyle(path).fill
      if (color) root.querySelector("[data-wave-color]").value = hex(color)
      for (const [key, fallback] of Object.entries({ roundness: 55, depth: 65, angle: 0, height: 100 })) {
        field(key).value = attributes[`data-wave-${key}`] || fallback
        root.querySelector(`[data-wave-output="${key}"]`).textContent = field(key).value + (key === "angle" ? "°" : key === "height" ? " px" : "%")
      }
      root.querySelector("[data-wave-direction]").value = attributes["data-wave-direction"] || "up"
    }
    root.querySelectorAll("[data-studio-flip]").forEach(button => button.setAttribute("aria-pressed", String(component.getAttributes()[`data-studio-flip-${button.dataset.studioFlip}`] === "true")))
  }
  editor.on("component:selected", synchronize)
  root.querySelectorAll("[data-simple-style]").forEach(input => input.addEventListener("input", () => {
    const component = selected()
    if (!component || !input.value) return
    const property = input.dataset.simpleStyle
    const value = input.type === "range" ? property === "opacity" ? String(Number(input.value) / 100) : input.value + "px" : input.value
    const styles = { [property]: value }
    if (property === "background-color") {
      styles["--section-bg"] = value
      styles["background-image"] = "none"
    }
    component.addStyle(styles)
    const output = input.closest("label")?.querySelector("output")
    if (output) output.textContent = input.value + (property === "opacity" ? " %" : " px")
  }))
  root.querySelectorAll("[data-studio-flip]").forEach(button => button.addEventListener("click", () => {
    const component = selected()
    if (!component) return
    const key = `data-studio-flip-${button.dataset.studioFlip}`
    component.addAttributes({ [key]: component.getAttributes()[key] === "true" ? "false" : "true" })
    const attributes = component.getAttributes()
    component.addStyle({ scale: `${attributes["data-studio-flip-x"] === "true" ? -1 : 1} ${attributes["data-studio-flip-y"] === "true" ? -1 : 1}` })
    synchronize(component)
  }))
  const svgFor = wave => {
    let svg = wave.get("tagName") === "svg" ? wave : wave.find("svg")[0]
    if (!svg) {
      wave.components('<svg viewBox="0 0 1200 120" preserveAspectRatio="none"><path d="M0 45 Q600 120 1200 45 L1200 120 L0 120 Z" fill="#cdae4f"></path></svg>')
      svg = wave.find("svg")[0]
    }
    return svg
  }
  const updateShape = () => {
    const wave = selected()
    if (!isWave(wave)) return
    const svg = svgFor(wave)
    const viewBox = (svg.getAttributes()["data-wave-original-box"] || svg.getAttributes().viewBox || svg.getAttributes().viewbox || "0 0 1200 120").split(/\s+/).map(Number)
    const width = viewBox[2], height = viewBox[3]
    const roundness = Number(field("roundness").value), depth = Number(field("depth").value)
    const path = svg.find("path").at(-1)
    path?.addAttributes({ d: `M0 ${height * .4} C${width * roundness / 200} ${height * depth / 100} ${width * .4} ${height * (1 - depth / 100)} ${width * .55} ${height * .45} S${width * .85} ${height * .95} ${width} ${height * .4} L${width} ${height} L0 ${height} Z` })
    const attributes = {}
    for (const key of ["roundness", "depth", "angle", "height"]) attributes[`data-wave-${key}`] = field(key).value
    wave.addAttributes(attributes)
    wave.addStyle({ height: field("height").value + "px", "min-height": "0", rotate: field("angle").value + "deg" })
    if (svg !== wave) svg.addStyle({ width: "100%", height: "100%" })
    synchronize(wave)
  }
  root.querySelectorAll("[data-wave-control]").forEach(input => input.addEventListener("input", updateShape))
  root.querySelector("[data-wave-direction]").addEventListener("change", event => {
    const wave = selected()
    if (!isWave(wave)) return
    const svg = svgFor(wave)
    const original = svg.getAttributes()["data-wave-original-box"] || svg.getAttributes().viewBox || svg.getAttributes().viewbox || "0 0 1200 120"
    const [, , width, height] = original.split(/\s+/).map(Number)
    let rotation = svg.components().find(child => child.getAttributes()["data-wave-rotation"])
    if (!rotation) {
      const children = [...svg.components().models]
      rotation = svg.append({ type: "svg-in", tagName: "g", attributes: { "data-wave-rotation": "true" } })[0]
      children.forEach(child => child.move(rotation))
    }
    const direction = event.target.value
    const vertical = ["left", "right"].includes(direction)
    const transforms = { up: "matrix(1 0 0 1 0 0)", down: `matrix(1 0 0 -1 0 ${height})`, left: `matrix(0 1 -1 0 ${height} 0)`, right: `matrix(0 -1 1 0 0 ${width})` }
    rotation.addAttributes({ transform: transforms[direction] })
    svg.addAttributes({ "data-wave-original-box": original, viewBox: vertical ? `0 0 ${height} ${width}` : original })
    if (svg !== wave) svg.addStyle({ width: "100%", height: "100%" })
    wave.addAttributes({ "data-wave-direction": direction })
    wave.addStyle({ width: vertical ? "100px" : "100%", height: vertical ? "300px" : field("height").value + "px", "min-height": "0" })
  })
  root.querySelector("[data-wave-color]").addEventListener("input", event => {
    const wave = selected()
    if (!isWave(wave)) return
    svgFor(wave).find("path").forEach(path => { path.addAttributes({ fill: event.target.value }); path.addStyle({ fill: event.target.value }) })
  })
  return synchronize
}
