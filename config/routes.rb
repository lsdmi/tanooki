# frozen_string_literal: true

Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'home#index'
  post '/' => 'home#index'

  devise_for :users,
             path: '',
             path_names: {
               sign_in: 'login',
               sign_up: 'register'
             },
             controllers: {
               confirmations: 'users/confirmations',
               omniauth_callbacks: 'users/omniauth_callbacks',
               passwords: 'users/passwords',
               registrations: 'users/registrations',
               sessions: 'users/sessions'
             }

  namespace :admin do
    resources :advertisements, path: 'ads', except: %i[show destroy]
    resources :avatars, except: %i[new edit show update]
    resources :tags, except: :new
    resources :tales, only: :index
  end

  resources :comments, except: %i[index show] do
    member do
      get :cancel_edit
      get :cancel_reply
    end
  end
  resources :publications, except: %i[index show]
  resources :search, only: :index
  resources :tales, only: :show
  resources :users do
    member { put :update_avatar }
  end

  get :dashboard, to: 'users#show', as: :dashboard
end
