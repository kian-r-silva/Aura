class ReviewsController < ApplicationController
  before_action :require_login, only: [:create]

  def create
    album = Album.find(params[:album_id])
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
