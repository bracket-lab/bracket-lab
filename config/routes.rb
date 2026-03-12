Rails.application.routes.draw do
  resource :setup, only: [ :new, :create ], controller: "setup"

  get "/rules", to: "pages#rules", as: "rules"
  get "/countdown", to: "pages#countdown", as: "countdown"
  get "/leaderboard", to: "leaderboard#index", as: "leaderboard"

  resources :game_results, only: [ :index ]
  resources :possible_outcomes, only: [ :index ]

  namespace :admin do
    root to: "dashboard#index"
    resource :tournament, only: [ :show, :edit, :update ] do
      post :set_teams, on: :member
      post :start, on: :member
      post :update_region_labels, on: :member
    end

    resources :brackets, only: [ :index, :destroy ]

    resources :teams, only: [ :index, :update ] do
      collection do
        get :import
        post :import_preview
        post :import_apply
      end
    end

    resources :invites, only: [ :index, :new, :create, :show, :destroy ] do
      collection do
        get :bulk_new
        post :bulk_preview
        post :bulk_create
      end
    end
    resources :users, only: [ :index, :edit, :update, :destroy ]

    mount MissionControl::Jobs::Engine, at: "/jobs", as: :jobs
  end

  resources :invite_acceptances, only: [ :new, :create ]

  resource :session
  resources :passwords, param: :token
  resources :brackets

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root to: "pages#home"
end
