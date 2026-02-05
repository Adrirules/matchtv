import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.lastScroll = 0
  }

  hideNav() {
    this.element.classList.add("hidden")
  }

  showNav() {
    this.element.classList.remove("hidden")
  }

  onScroll() {
    const currentScroll = window.pageYOffset

    if (currentScroll > this.lastScroll) {
      this.hideNav()
    } else {
      this.showNav()
    }

    this.lastScroll = currentScroll
  }
}
