Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'home#index'
  post '/' => "home#index"

  devise_for :users,
    controllers: {
      confirmations: 'users/confirmations',
      passwords: 'users/passwords',
      registrations: 'users/registrations',
      sessions: 'users/sessions'
    }

  resources :tales, only: [:show]

  namespace :admin do
    resources :tales, except: :show
  end
end
