class SessionsController < ApplicationController
  def new; end

  def create
    user = User.find_by(email: params[:email])
    if user
      session[:user_id] = user.id
      redirect_to root_path
    else
      redirect_to new_user_path, alert: "Please sign up"
    end
  end

  def destroy
    session.delete(:user_id)
    redirect_to root_path
  end
end
