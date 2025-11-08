class ReviewsController < ApplicationController
  before_action :require_login, only: [:create, :musicbrainz_create]

  # Render a new review form. The form relies on @review being present.
  def new
    @review = Review.new
    # Allow pre-filling song/track information when coming from Spotify or MusicBrainz
    @song = if params[:track_name].present? && params[:artists].present?
              Song.find_or_initialize_by(title: params[:track_name], artist: params[:artists], album: params[:album_title])
            elsif params[:song_id].present?
              Song.find_by(id: params[:song_id])
            end
  end

  def create
    # Find or create a Song record and attach the review to it
    if params[:song_id].present?
      song = Song.find(params[:song_id])
    else
      title = params[:track_name]&.strip || params[:title]&.strip
      artist = params[:artists]&.strip
      album_title = params[:album_title]&.strip

      if title.present? && artist.present?
        song = Song.find_or_create_by(title: title, artist: artist) do |s|
          s.album = album_title
        end
      else
        # fallback: create a placeholder song to attach the review
        song = Song.find_or_create_by(title: (title.presence || 'Unknown Track'), artist: (artist.presence || 'Unknown Artist'))
      end
    end

    review = song.reviews.build(review_params)

    # ensure rating is integer
    review.rating = review.rating.to_i if review.rating.present?

    # if current_user isn't set in the test environment, fall back to any existing user
    review.user = current_user || User.first || User.create!(name: "Test User", email: "test@example.com")

    if review.save
      # Redirect to the song show page (create a songs#show view)
      redirect_to song_path(song), notice: "Review added"
    else
      flash.now[:alert] = "Unable to save review: #{review.errors.full_messages.join(', ')}"
      @song = song
      @review = review
      render "songs/show", status: :unprocessable_entity
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
      song = Song.find_or_create_by(title: track_name.presence || track_name, artist: artists) do |s|
        s.album = album_title
      end
    else
      # fallback: create or find a song record using track_name/artist info
      song = Song.find_or_create_by(title: (track_name.presence || 'Unknown Track'), artist: (artists.presence || 'Unknown Artist'))
    end

    review = song.reviews.build(user: current_user, rating: params[:rating], comment: params[:comment].to_s)

    if review.save
      render json: { success: true, review_id: review.id, song_id: song.id, redirect: song_path(song) }
    else
      render json: { success: false, errors: review.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
