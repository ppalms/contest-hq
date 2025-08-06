Rails.application.routes.draw do
  resources :accounts
  resources :users, only: [ :index, :edit, :update ]
  resources :seasons, except: [ :show ]

  namespace :organizations do
    get "/", to: "index"
    resources :schools
    resources :school_classes
  end

  resources :contests do
    resources :contest_entries, as: "entries", path: "entries" do
      resources :music_selections, as: "selections", path: "selections"
    end

    patch "times", to: "contests#set_times"
    get "schedule_summary", to: "contests#schedule" # TODO: move to schedules folder
    get "setup", to: "contests#setup"

    resources :rooms, controller: "contests/rooms"
    resources :managers, controller: "contests/managers", only: [ :index, :new, :create, :destroy ]

    get :performance_phases, path: "phases", to: "contests/performance_phases#index"
    get :performance_phases, as: "phase_bulk_edit", path: "phases/edit", to: "contests/performance_phases#edit"
    put :performance_phases, as: "phases", path: "phases", to: "contests/performance_phases#update"
  end

  post "schedules/:id/generate", as: "generate_schedule", to: "schedules#generate"
  post "schedules/:id/reset", as: "reset_schedule", to: "schedules#reset"
  resources :schedules, only: [ :show ] do
    resources :schedule_days, as: "days", path: "days", controller: "schedules/days", only: [ :index, :show ]
    # Reschedule actions
    post "contest_entries/:contest_entry_id/move_up", as: "move_entry_up", to: "schedules#move_entry_up"
    post "contest_entries/:contest_entry_id/move_down", as: "move_entry_down", to: "schedules#move_entry_down"  
    post "contest_entries/:contest_entry_id/swap/:target_entry_id", as: "swap_entries", to: "schedules#swap_entries"
  end

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
