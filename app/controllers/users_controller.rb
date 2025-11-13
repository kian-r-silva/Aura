class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to songs_path, notice: "Welcome, #{@user.name}"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @user = User.find(params[:id])
    @analytics = AnalyticsService.new(@user)
    
    # Fetch images for reviews if Last.fm is available
    @review_images = {}
    if ENV['LASTFM_API_KEY'] && @user.reviews.any?
      client = LastfmClient.new(current_user)
      @user.reviews.includes(:song).each do |review|
        next unless review.song.artist.present? && review.song.title.present?
        image = client.get_track_image(review.song.artist, review.song.title)
        @review_images[review.id] = image if image.present?
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :username, :password, :password_confirmation)
  end
end
