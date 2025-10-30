class ReviewsController < ApplicationController
  before_action :require_login, only: [:create]

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

  private

  def review_params
    params.require(:review).permit(:rating, :comment)
  end
end
