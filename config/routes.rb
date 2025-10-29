Rails.application.routes.draw do
  root "albums#index"

  resources :users, only: %i[new create show]
  resource  :session, only: %i[new create destroy]
  resources :albums, only: %i[index show new create] do
    resources :reviews, only: %i[create]
  end
end
