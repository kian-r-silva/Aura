Rails.application.routes.draw do
  root "albums#index"
  resources :users, only: [:new, :create, :show]
  resource :session, only: [:new, :create, :destroy]
  resources :albums do
    resources :reviews, only: [:create]
  end
end
