import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list", "title", "artists", "release", "reviewLink", "button"]

  connect() {
    this.delayTimer = null
    this.abortController = null
    console.log("✅ MusicBrainz controller connected!")
  }

  search(event) {
    const q = this.hasInputTarget ? this.inputTarget.value.trim() : ''
    console.debug('[MB] search triggered', { q: q, eventType: event && event.type })
    if (!q) return this.clear()

    const immediate = event && (event.type === 'click' || (event.type === 'keydown' && event.key === 'Enter'))
    clearTimeout(this.delayTimer)
    if (immediate) {
      console.debug('[MB] immediate search for:', q)
      return this.doSearch(q)
    }

    this.delayTimer = setTimeout(() => this.doSearch(q), 200)
  }

  doSearch(q) {
    if (this.abortController) this.abortController.abort()
    this.abortController = new AbortController()
    console.debug('[MB] fetching /musicbrainz/search', q)
    fetch(`/musicbrainz/search?q=${encodeURIComponent(q)}`, { signal: this.abortController.signal })
      .then(r => {
        console.debug('[MB] fetch status', r.status)
        return r.json()
      })
      .then(json => this.renderList(json))
      .catch(e => {
        if (e.name !== 'AbortError') {
          console.warn('[MB] musicbrainz search error', e)
          this.clear()
        }
      })
  }

  renderList(items) {
    if (!this.hasListTarget) return
    console.debug('[MB] renderList, items length=', items && items.length)
    this.listTarget.innerHTML = ''
    items.forEach(item => {
      const li = document.createElement('li')
      li.className = 'mb-suggestion'

      const text = document.createElement('span')
      text.textContent = `${item.title} — ${item.artists}${item.release ? ' — ' + item.release : ''}`
      text.style.marginRight = '8px'
      li.appendChild(text)

      // Clicking the text selects the item into the hidden fields
      text.addEventListener('click', () => this.select(item))

      // Add a Review button for each result so users can jump directly to the review form
      const btn = document.createElement('button')
      btn.type = 'button'
      btn.className = 'btn btn-sm btn-secondary'
      btn.textContent = 'Review'
      btn.addEventListener('click', (e) => {
        e.stopPropagation()
        const href = `/reviews/new?album_title=${encodeURIComponent(item.release || '')}&artists=${encodeURIComponent(item.artists || '')}&track_id=${encodeURIComponent(item.id || '')}&track_name=${encodeURIComponent(item.title || '')}`
        // navigate to the review form with prefilled params
        window.location.href = href
      })
      li.appendChild(btn)

      li.dataset.title = item.title
      li.dataset.artists = item.artists
      li.dataset.release = item.release
      li.dataset.id = item.id
      this.listTarget.appendChild(li)
    })
  }

  select(item) {
    console.debug('[MB] selected item', item && item.id)
    if (this.hasTitleTarget) this.titleTarget.value = item.title
    if (this.hasArtistsTarget) this.artistsTarget.value = item.artists
    if (this.hasReleaseTarget) this.releaseTarget.value = item.release

    const albumInput = document.getElementById('album_title')
    const artistsInput = document.getElementById('artists')
    const trackIdInput = document.getElementById('track_id')
    const trackNameInput = document.getElementById('track_name')
    if (albumInput) albumInput.value = item.release || ''
    if (artistsInput) artistsInput.value = item.artists || ''
    if (trackIdInput) trackIdInput.value = item.id || ''
    if (trackNameInput) trackNameInput.value = item.title || ''

    if (this.hasReviewLinkTarget) {
      const href = `/reviews/new?album_title=${encodeURIComponent(item.release || '')}&artists=${encodeURIComponent(item.artists || '')}&track_id=${encodeURIComponent(item.id || '')}&track_name=${encodeURIComponent(item.title || '')}`
      Object.assign(this.reviewLinkTarget, {
        href,
        style: "display:inline-block",
        textContent: `Review "${item.title}"`
      })
    }

    this.clear()
  }

  clear() {
    if (this.hasListTarget) this.listTarget.innerHTML = ''
  }
}
