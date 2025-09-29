# frozen_string_literal: true

Rails.application.routes.draw do
  root 'home#index'
  post '/' => 'home#index'

  devise_for :users,
             skip: %i[registrations],
             path: '',
             path_names: { sign_in: 'login' },
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

  # Legacy routes
  get '/session/new', to: redirect('/login')
  get '/register/new', to: redirect('/register')

  namespace :admin do
    resources :advertisements, path: 'ads', except: %i[show destroy]
    resources :avatars, except: %i[new edit show update]
    resources :genres, except: %i[new show]
    resources :pokemons, except: :show
    resources :tags, except: %i[new show]
  end

  namespace :api do
    namespace :v1 do
      resources :fictions, only: :index
    end
  end

  resources :comments, except: %i[index show] do
    member do
      get :cancel_edit
      get :cancel_reply
    end
  end
  resources :chapters, except: %i[index destroy] do
    member do
      get :comments
    end
  end
  resources :fictions do
    member do
      get :details
    end
    collection do
      get :alphabetical, to: 'fiction_lists#alphabetical'
      get :calendar, to: 'chapters_calendar#index'
      post :toggle_order
    end
    resources :fiction_ratings, only: %i[create update]
  end

  resources :fictions, only: [] do
    resource :reading_progress, only: [], controller: 'reading_progresses' do
      patch :update_status
    end
  end
  resources :publications, except: %i[index show]
  resources :scanlators
  resources :bookshelves, param: :sqid
  resources :search, only: :index
  resources :studio, only: :index do
    member do
      get :tab
    end
  end
  resources :tales, only: %i[index show]
  resources :translation_requests, only: %i[index create update], path: 'translate' do
    member do
      patch :assign
      delete :unassign
    end
    resources :translation_request_votes, only: [:create], path: 'votes'
  end
  resources :users, only: :update

  resources :profiles, only: :show, param: :id, path: 'profile'

  resources :youtube_videos, path: 'watch', only: %i[index show] do
    collection do
      post :index
    end
  end

  # Chat routes
  get '/chat/recent_messages', to: 'chat#recent_messages'

  # Redirect old routes to new studio controller with appropriate tabs
  get :blogs, to: 'studio#set_tab_and_redirect', defaults: { tab: 'blogs' }
  get :pokemons, to: 'studio#set_tab_and_redirect', defaults: { tab: 'pokemons' }
  get :avatars, to: 'studio#set_tab_and_redirect', defaults: { tab: 'profile' }
  get :readings, to: 'studio#set_tab_and_redirect', defaults: { tab: 'writings' }
  get :scanlators, to: 'studio#set_tab_and_redirect', defaults: { tab: 'teams' }
  get :notifications, to: 'studio#set_tab_and_redirect', defaults: { tab: 'notifications' }

  post :blogs, to: 'studio#set_tab_and_redirect', defaults: { tab: 'blogs' }
  post :pokemons, to: 'studio#set_tab_and_redirect', defaults: { tab: 'pokemons' }
  post :avatars, to: 'studio#set_tab_and_redirect', defaults: { tab: 'profile' }
  post :readings, to: 'studio#set_tab_and_redirect', defaults: { tab: 'writings' }
  post :scanlators, to: 'studio#set_tab_and_redirect', defaults: { tab: 'teams' }
  post :notifications, to: 'studio#set_tab_and_redirect', defaults: { tab: 'notifications' }

  # Redirect scanlators index to studio teams tab
  get 'scanlators/index', to: 'studio#set_tab_and_redirect', defaults: { tab: 'teams' }

  resources :readings, only: %i[show destroy]

  post :pokemon_details, to: 'users#pokemon_details', as: :pokemon_details

  get :library, to: 'library#index'
  patch 'reading_progresses/:id', to: 'library#update_status', as: :update_reading_progress

  get :rules, to: 'pages#rules'

  post '/pokemon/catch', to: 'user_pokemons#create', as: :catch_pokemon
  post '/pokemon/training', to: 'user_pokemons#training', as: :training_pokemon

  get '/pokemon/opponent/regenerate', to: 'user_pokemons#regenerate_opponent', as: :regenerate_pokemon_opponent

  post :battle_start, to: 'pokemon_battles#start', as: :battle_start

  resources :downloads, only: [] do
    member { get :epub }
    collection { get :epub_multiple }
  end
end
