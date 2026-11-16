export function installRetention(root, csrf) {
  const dialog = root.querySelector("[data-studio-retention]")
  const status = dialog.querySelector("[data-retention-status]")
  root.querySelector("[data-studio-retention-open]").addEventListener("click", () => dialog.showModal())
  dialog.querySelector("[data-retention-close]").addEventListener("click", () => dialog.close())
  if (dialog.hasAttribute("data-open-on-load")) dialog.showModal()
  dialog.addEventListener("submit", async event => {
    event.preventDefault()
    const form = event.target
    const body = new FormData(form)
    const buttons = Array.from(dialog.querySelectorAll('button[type="submit"]'))
    buttons.forEach(button => { button.disabled = true })
    status.textContent = "Enregistrement…"
    status.setAttribute("role", "status")
    try {
      const response = await fetch(form.action, { method: "POST", headers: { "X-CSRF-Token": csrf, Accept: "application/json" }, body })
      const result = await response.json()
      if (!response.ok) throw new Error(result.error || "Impossible d’enregistrer ces durées.")
      dialog.querySelector("[data-retention-content]").innerHTML = result.html
      status.textContent = result.message
    } catch (error) {
      status.textContent = error.message
      status.setAttribute("role", "alert")
    } finally { buttons.forEach(button => { button.disabled = false }) }
  })
}
