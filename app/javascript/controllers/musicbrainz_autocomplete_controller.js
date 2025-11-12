import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["titleInput", "artistInput", "albumInput", "input", "list", "title", "artists", "release", "reviewLink", "button"]

  connect() {
    this.delayTimer = null
    this.abortController = null
    console.log("✅ MusicBrainz controller connected!")
  }

  search(event) {
    // Support separate title and artist inputs. Prefer explicit title/artist targets
    const title = this.hasTitleInputTarget ? this.titleInputTarget.value.trim() : (this.hasInputTarget ? this.inputTarget.value.trim() : '')
  const artist = this.hasArtistInputTarget ? this.artistInputTarget.value.trim() : ''
  const album = this.hasAlbumInputTarget ? this.albumInputTarget.value.trim() : ''

    let q = ''
    const esc = s => s.replace(/\"/g, '\\\"')
    // Build query using title, artist, and album (release). Avoid using 'recording' field per request.
    const parts = []
    if (title) parts.push(`title:"${esc(title)}"`)
    if (artist) parts.push(`artist:"${esc(artist)}"`)
    if (album) parts.push(`release:"${esc(album)}"`)
    q = parts.join(' AND ')
  console.debug('[MB] search triggered', { q: q, title: title, artist: artist, eventType: event && event.type })
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
        this.createReview(item)
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

  createReview(item) {
    // Open an inline modal so the user can add rating/comment before creating
    this.showCreateModal(item)
  }

  clear() {
    if (this.hasListTarget) this.listTarget.innerHTML = ''
  }

  showCreateModal(item) {
    // remove any existing modal
    const existing = document.getElementById('mb-create-modal')
    if (existing) existing.remove()

    const modal = document.createElement('div')
    modal.id = 'mb-create-modal'
    modal.style.position = 'fixed'
    modal.style.left = 0
    modal.style.top = 0
    modal.style.width = '100%'
    modal.style.height = '100%'
    modal.style.background = 'rgba(0,0,0,0.4)'
    modal.style.display = 'flex'
    modal.style.alignItems = 'center'
    modal.style.justifyContent = 'center'
    modal.style.zIndex = 10000

    const dialog = document.createElement('div')
    dialog.style.background = 'white'
    dialog.style.padding = '16px'
    dialog.style.borderRadius = '8px'
    dialog.style.width = 'min(720px, 92%)'
    dialog.style.boxShadow = '0 6px 18px rgba(0,0,0,0.2)'

    const title = document.createElement('h3')
    title.textContent = 'Create review for selected track'
    dialog.appendChild(title)

    const info = document.createElement('div')
    info.style.marginBottom = '8px'
    info.innerHTML = `<div><strong>Track:</strong> ${this.escapeHtml(item.title || '')}</div><div><strong>Artist(s):</strong> ${this.escapeHtml(item.artists || '')}</div><div><strong>Album:</strong> ${this.escapeHtml(item.release || '')}</div>`
    dialog.appendChild(info)

    const form = document.createElement('div')
    form.style.display = 'flex'
    form.style.flexDirection = 'column'
    form.style.gap = '8px'

    const ratingWrapper = document.createElement('div')
    ratingWrapper.style.display = 'flex'
    ratingWrapper.style.gap = '8px'
    ratingWrapper.style.alignItems = 'center'
    const ratingLabel = document.createElement('label')
    ratingLabel.textContent = 'Rating:'
    ratingLabel.htmlFor = 'mb_modal_rating'
    const ratingSelect = document.createElement('select')
    ratingSelect.id = 'mb_modal_rating'
    ratingSelect.innerHTML = '<option value="">(no rating)</option>' + [1,2,3,4,5].map(n => `<option value="${n}">${n}</option>`).join('')
    ratingWrapper.appendChild(ratingLabel)
    ratingWrapper.appendChild(ratingSelect)
    form.appendChild(ratingWrapper)

    const commentLabel = document.createElement('label')
    commentLabel.textContent = 'Comment (optional):'
    commentLabel.htmlFor = 'mb_modal_comment'
    const commentArea = document.createElement('textarea')
    commentArea.id = 'mb_modal_comment'
    commentArea.rows = 4
    commentArea.style.width = '100%'
    form.appendChild(commentLabel)
    form.appendChild(commentArea)

    dialog.appendChild(form)

    const actions = document.createElement('div')
    actions.style.display = 'flex'
    actions.style.gap = '8px'
    actions.style.justifyContent = 'flex-end'
    actions.style.marginTop = '12px'

    const cancel = document.createElement('button')
    cancel.type = 'button'
    cancel.className = 'btn'
    cancel.textContent = 'Cancel'
    cancel.addEventListener('click', () => modal.remove())

    const create = document.createElement('button')
    create.type = 'button'
    create.className = 'btn btn-primary'
    create.textContent = 'Create review'
    create.addEventListener('click', async () => {
      create.disabled = true
      create.textContent = 'Creating...'
      const payload = {
        album_title: item.release || '',
        artists: item.artists || '',
        track_id: item.id || '',
        track_name: item.title || '',
        rating: ratingSelect.value || null,
        comment: commentArea.value || ''
      }
      try {
        const token = document.querySelector('meta[name="csrf-token"]')?.content
        const resp = await fetch('/reviews/musicbrainz_create', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': token || ''
          },
          body: JSON.stringify(payload)
        })
        const json = await resp.json()
        if (resp.ok && json.success) {
            window.location.href = json.redirect || (json.song_id ? `/songs/${json.song_id}` : window.location.href)
        } else {
          alert('Unable to create review: ' + (json.errors ? json.errors.join(', ') : json.error || 'unknown'))
          create.disabled = false
          create.textContent = 'Create review'
        }
      } catch (e) {
        console.error('createReview error', e)
        alert('Network error while creating review')
        create.disabled = false
        create.textContent = 'Create review'
      }
    })

    actions.appendChild(cancel)
    actions.appendChild(create)
    dialog.appendChild(actions)

    modal.appendChild(dialog)
    document.body.appendChild(modal)
    // focus the rating select for quicker keyboard workflow
    ratingSelect.focus()
  }

  escapeHtml(str) {
    if (!str) return ''
    return String(str).replace(/[&<>\"]/g, function (s) {
      return ({'&':'&amp;','<':'&lt;','>':'&gt;','\"':'&quot;'})[s]
    })
  }
}
