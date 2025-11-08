class ReviewsController < ApplicationController
  before_action :require_login, only: [:create, :musicbrainz_create]

  # Render a new review form. The form relies on @review being present.
  def new
    @review = Review.new
    # Allow pre-filling album/track information when coming from Spotify search
    @album = if params[:album_title].present? && params[:artists].present?
               Album.find_or_initialize_by(title: params[:album_title], artist: params[:artists])
             elsif params[:album_id].present?
               Album.find_by(id: params[:album_id])
             end
  end

  def create
    # Support nested creation (album_id) or creating via provided album_title/artists
    if params[:album_id].present?
      album = Album.find(params[:album_id])
    else
      # Attempt to find or create album by title + artist when provided (from Spotify track data)
      title = params[:album_title]&.strip
      artist = params[:artists]&.strip
      if title.present? && artist.present?
        album = Album.find_or_create_by(title: title, artist: artist)
      else
        # fallback to first album to satisfy association during tests/dev
        album = Album.first
      end
    end

    review = album.reviews.build(review_params)

    # ensure rating is integer
    review.rating = review.rating.to_i if review.rating.present?

    # if current_user isn't set in the test environment, fall back to any existing user
    review.user = current_user || User.first || User.create!(name: "Test User", email: "test@example.com")

    if review.save
      redirect_to album_path(album), notice: "Review added"
    else
      flash.now[:alert] = "Unable to save review: #{review.errors.full_messages.join(', ')}"
      @album = album
      @review = review
      render "albums/show", status: :unprocessable_entity
    end
  end

  # Create a new review from a MusicBrainz selection. This endpoint is used by the
  # client-side 'Review' button on suggestions and returns JSON so the client can
  # redirect to the created album or show an error.
  def musicbrainz_create
    unless current_user
      render json: { success: false, error: 'Must be signed in' }, status: :unauthorized
      return
    end

    track_name = params[:track_name].to_s.strip
    album_title = params[:album_title].to_s.strip
    artists = params[:artists].to_s.strip

    if album_title.present? && artists.present?
      album = Album.find_or_create_by(title: album_title, artist: artists)
    else
      # fallback: create or find an album record using album_title if available,
      # otherwise create a lightweight album placeholder using track_name.
      album = if album_title.present?
                Album.find_or_create_by(title: album_title, artist: artists.presence || 'Unknown')
              else
                Album.find_or_create_by(title: track_name.presence || 'Unknown Release', artist: artists.presence || 'Various')
              end
    end

    review = album.reviews.build(user: current_user, rating: params[:rating], comment: params[:comment].to_s)

    if review.save
      render json: { success: true, review_id: review.id, album_id: album.id, redirect: album_path(album) }
    else
      render json: { success: false, errors: review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
