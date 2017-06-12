Rails.application.routes.draw do

  root to: 'pages#landing'

  post 'stripe_checkout' => 'subscriptions#stripe_checkout', as: :stripe_checkout

  get 'subscriptions/plans'

  get 'subscriptions/index'

  get 'privacy-policy' => 'pages#privacy', as: :privacy_policy

  resources :videos

  resources :charges

  # get 'charges/create' => 'charges#create', as: :create_new_charge

  get 'create_new_video' => 'videos#create_new_video', as: :create_new_video


  devise_for :users, controllers: { :omniauth_callbacks => "users/omniauth_callbacks" }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
