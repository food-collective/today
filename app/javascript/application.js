// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Keep your place in the list after checking off a task.
const SCROLL_KEY = "bfc:scrollY"

document.addEventListener("submit", (event) => {
  if (event.target.matches("form[data-keep-scroll]")) {
    try { sessionStorage.setItem(SCROLL_KEY, String(window.scrollY)) } catch (_) {}
  }
}, true)

document.addEventListener("turbo:load", () => {
  let y = null
  try {
    y = sessionStorage.getItem(SCROLL_KEY)
    sessionStorage.removeItem(SCROLL_KEY)
  } catch (_) {}
  if (y !== null) requestAnimationFrame(() => window.scrollTo(0, parseInt(y, 10) || 0))
})

// Close the account menu when tapping anywhere else.
document.addEventListener("click", (event) => {
  document.querySelectorAll("details.menu[open]").forEach((menu) => {
    if (!menu.contains(event.target)) menu.removeAttribute("open")
  })
})
