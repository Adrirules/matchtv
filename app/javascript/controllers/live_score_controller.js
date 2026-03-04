import { Controller } from "@hotwired/stimulus"

const LIVE_STATUSES = ["1H", "HT", "2H", "ET", "BT", "P"]
const FINISHED_STATUSES = ["FT", "AET", "PEN"]

export default class extends Controller {
  static targets = ["score", "status", "elapsed"]
  static values  = { url: String, status: String }

  connect() {
    if (LIVE_STATUSES.includes(this.statusValue)) {
      this.poll()
      this.interval = setInterval(() => this.poll(), 60000)
    }
  }

  disconnect() {
    clearInterval(this.interval)
  }

  async poll() {
    try {
      const res  = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      const data = await res.json()

      this.statusValue = data.status
      this.renderScore(data)

      // Arrête le polling si le match est terminé
      if (FINISHED_STATUSES.includes(data.status)) {
        clearInterval(this.interval)
      }
    } catch (e) {
      console.warn("Live score fetch error", e)
    }
  }

  renderScore(data) {
    const { status, home_score, away_score, elapsed, events } = data
    const hasScore = home_score !== null && away_score !== null

    if (this.hasScoreTarget && hasScore) {
      this.scoreTarget.textContent = `${home_score} - ${away_score}`
    }

    if (this.hasStatusTarget) {
      this.statusTarget.textContent = this.statusLabel(status, elapsed)
      this.statusTarget.className   = this.statusClass(status)
    }

    if (events && events.length > 0) {
      this.renderTimeline(events)
    }
  }

  renderTimeline(events) {
    const section = document.getElementById('match-timeline')
    if (!section) {
      // Crée la section si elle n'existe pas encore (match qui vient de commencer)
      const wrapper = document.querySelector('.match-detail-wrapper')
      if (!wrapper) return
      const newSection = document.createElement('section')
      newSection.id = 'match-timeline'
      newSection.style.cssText = 'margin:25px 0;background:#fff;border-radius:12px;padding:20px;box-shadow:0 2px 10px rgba(0,0,0,0.04)'
      newSection.innerHTML = '<h2 style="font-size:18px;font-weight:800;color:#010e1b;margin-bottom:16px">Résumé du match</h2><div class="timeline" id="timeline-body"></div>'
      wrapper.after(newSection)
    }

    const body = document.getElementById('timeline-body') || section?.querySelector('.timeline')
    if (!body) return

    const icons = {
      'Normal Goal': '⚽', 'Own Goal': '⚽', 'Penalty': '⚽',
      'Missed Penalty': '❌', 'Yellow Card': '🟨', 'Red Card': '🟥',
      'Yellow Red Card': '🟧'
    }
    const labels = {
      'Own Goal': 'CSC', 'Penalty': 'Penalty', 'Missed Penalty': 'Penalty raté', 'Yellow Red Card': '2e jaune'
    }

    const filtered = events.filter(e => e.type !== 'subst')
    body.innerHTML = filtered.map(e => {
      const time    = e.time.extra ? `${e.time.elapsed}+${e.time.extra}'` : `${e.time.elapsed}'`
      const icon    = icons[e.detail] || (e.type === 'subst' ? '🔁' : '•')
      const label   = labels[e.detail] || ''
      const parts   = (e.player.name || '').split(' ')
      const name    = parts.length > 1 ? `${parts[0][0]}. ${parts.slice(1).join(' ')}` : e.player.name
      const isHome  = e.team.name === this.element.dataset.homeTeam

      return isHome
        ? `<div class="timeline-row home"><div class="tl-player home-side"><span class="tl-name">${name}</span>${label ? `<span class="tl-label">${label}</span>` : ''}</div><div class="tl-center"><span class="tl-icon">${icon}</span><span class="tl-time">${time}</span></div><div class="tl-player away-side"></div></div>`
        : `<div class="timeline-row away"><div class="tl-player home-side"></div><div class="tl-center"><span class="tl-time">${time}</span><span class="tl-icon">${icon}</span></div><div class="tl-player away-side">${label ? `<span class="tl-label">${label}</span>` : ''}<span class="tl-name">${name}</span></div></div>`
    }).join('')
  }

  statusLabel(status, elapsed) {
    if (status === "HT")  return "Mi-temps"
    if (status === "FT")  return "Terminé"
    if (status === "AET") return "Terminé (Prol.)"
    if (status === "PEN") return "Terminé (Tab)"
    if (status === "ET")  return `Prol. ${elapsed || ""}′`
    if (["1H", "2H"].includes(status)) return `${elapsed || ""}′`
    return status
  }

  statusClass(status) {
    if (LIVE_STATUSES.includes(status))    return "match-status live"
    if (FINISHED_STATUSES.includes(status)) return "match-status finished"
    return "match-status upcoming"
  }
}
