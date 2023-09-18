# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'home#index'
  post '/' => 'home#index'

  devise_for :users,
             skip: %i[registrations],
             path: '',
             path_names: {
               sign_in: 'login'
             },
             controllers: {
               confirmations: 'users/confirmations',
               omniauth_callbacks: 'users/omniauth_callbacks',
               passwords: 'users/passwords',
               sessions: 'users/sessions'
             }

  devise_scope :user do
    get '/register', to: 'users/registrations#new'
    post '/register', to: 'users/registrations#create'
  end

  namespace :admin do
    resources :advertisements, path: 'ads', except: %i[show destroy]
    resources :avatars, except: %i[new edit show update]
    resources :genres, except: :new
    resources :pokemons, except: :show
    resources :tags, except: :new
    resources :tales, only: :index
  end

  resources :comments, except: %i[index show] do
    member do
      get :cancel_edit
      get :cancel_reply
    end
  end
  resources :chapters, except: :index
  resources :fictions
  resources :publications, except: %i[index show]
  resources :search, only: :index
  resources :tales, only: :show
  resources :users, only: :update
  resources :youtube_videos, path: 'watch', only: %i[index show] do
    collection do
      post :index
    end
  end

  get :avatars, to: 'users#avatars', as: :avatars
  get :blogs, to: 'users#blogs', as: :blogs
  get :pokemons, to: 'users#pokemons', as: :pokemons
  get :readings, to: 'users#readings', as: :readings

  post :pokemon_details, to: 'users#pokemon_details', as: :pokemon_details

  get :library, to: 'library#index'

  post '/pokemon/catch', to: 'user_pokemons#create', as: :catch_pokemon
  post :battle_start, to: 'pokemon_battles#start', as: :battle_start
end
