Rails.application.routes.draw do
  devise_for :users

  root "pages#landing"

  get "feed", to: "feed#index", as: :feed
  get "search", to: "search#index", as: :search
  get "smart-money", to: "smart_money#index", as: :smart_money

  resources :tokens, only: [ :index, :show ], param: :mint_address do
    member do
      post :scan
      post :vote
    end
  end

  resource :dashboard, only: [ :show ], controller: "dashboard"

  resources :watchlist_items, only: [ :index, :create, :destroy ], path: "watchlist"

  resources :tracked_wallets, only: [ :index, :create, :show, :destroy ], path: "wallets" do
    member do
      post :refresh
    end
  end

  resource :portfolio, only: [ :show ], controller: "portfolio" do
    post :scan_wallet
  end

  resources :alerts, only: [ :index ] do
    collection do
      post :mark_all_read
    end
    member do
      patch :mark_read
    end
  end

  resource :subscription, only: [ :show, :create, :destroy ] do
    get :success
    get :cancel
  end

  post "webhooks/stripe", to: "webhooks/stripe#create"
  post "webhooks/telegram", to: "webhooks/telegram#create"

  get "up" => "rails/health#show", as: :rails_health_check
end
