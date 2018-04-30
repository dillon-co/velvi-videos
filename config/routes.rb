Rails.application.routes.draw do

  resources :raffle_emails
  resources :events
  mount Sidekiq::Web => '/sidekiq'

  root to: 'pages#landing_page_drawing'

  post 'stripe_checkout' => 'subscriptions#stripe_checkout', as: :stripe_checkout

  get 'subscriptions/plans'

  get 'subscriptions/index'

  get 'privacy-policy' => 'pages#privacy', as: :privacy_policy

  resources :videos

  resources :charges

  get "this_is_so_cool" => 'raffle_emails#raffle_share', as: :raffle_share

  get 'color_fun' => 'pages#color_fun', as: :color_fun_path
  # get 'charges/create' => 'charges#create', as: :create_new_charge

  get 'create_new_video' => 'videos#create_new_video', as: :create_new_video

  get 'check_video_progress' => 'videos#check_video_progress'

  # get "/auth/:action/callback", :controller => "omniauth_callbacks", :constraints => { :action => /instagram|youtube/ }
  get 'upload_confirmation' => 'videos#upload_confirmation', as: :upload_confirmation

  devise_for :users, controllers: { :omniauth_callbacks => "users/omniauth_callbacks" }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
