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

  namespace :admin do
    resources :advertisements, path: 'ads', except: %i[show destroy]
    resources :avatars, except: %i[new edit show update]
    resources :genres, except: %i[new show]
    resources :pokemons, except: :show
    resources :tags, except: %i[new show]
    resources :tales, only: :index
  end

  resources :comments, except: %i[show] do
    collection do
      post :dropdown
    end
    member do
      get :cancel_edit
      get :cancel_reply
    end
  end
  resources :chapters, except: :index
  resources :fictions do
    collection do
      get :alphabetical, to: 'fiction_lists#alphabetical'
      post :toggle_order
    end
  end
  resources :publications, except: %i[index show]
  resources :scanlators
  resources :search, only: :index
  resources :tales, only: %i[index show]
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
  delete 'reading_progresses/:id', to: 'library#destroy', as: :destroy_reading_progress

  post '/pokemon/catch', to: 'user_pokemons#create', as: :catch_pokemon
  post '/pokemon/training', to: 'user_pokemons#training', as: :training_pokemon
  post :battle_start, to: 'pokemon_battles#start', as: :battle_start
end
