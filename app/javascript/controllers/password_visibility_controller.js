import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "closedIcon", "openIcon", "button"]

  connect() { this.setVisibility(false) }
  disconnect() { this.setVisibility(false) }

  toggle() {
    this.setVisibility(this.inputTarget.type === "password")
  }

  setVisibility(revealing) {
    this.inputTarget.type = revealing ? "text" : "password"
    this.closedIconTarget.toggleAttribute("hidden", revealing)
    this.openIconTarget.toggleAttribute("hidden", !revealing)
    this.buttonTarget.setAttribute("aria-pressed", String(revealing))
    this.buttonTarget.setAttribute("aria-label", revealing ? "Masquer le mot de passe" : "Afficher le mot de passe")
  }
}
