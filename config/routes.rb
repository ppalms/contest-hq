Rails.application.routes.draw do
  resources :users, only: [ :index, :edit, :update ]

  namespace :organizations do
    get "/", to: "index"
    resources :schools
    resources :school_classes
  end

  resources :contests
  resources :contest_entries

  namespace :roster do
    get "/", to: "index"
    resources :large_ensembles
  end

  resources :performance_classes, only: [ :index, :show ]

  resource :invitation, only: [ :new, :create ]
  get  "sign_in", to: "sessions#new"
  post "sign_in", to: "sessions#create"
  get  "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"
  post "users/:user_id/masquerade", to: "masquerades#create", as: :user_masquerade
  resources :sessions, only: [ :index, :show, :destroy ]
  resource  :password, only: [ :edit, :update ]
  namespace :identity do
    resource :email,              only: [ :edit, :update ]
    resource :email_verification, only: [ :show, :create ]
    resource :password_reset,     only: [ :new, :edit, :create, :update ]
    resource :profile,            only: [ :show, :edit, :update ]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"
  get "settings", to: "home#settings"
end
