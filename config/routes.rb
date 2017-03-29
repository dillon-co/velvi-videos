Rails.application.routes.draw do

  resources :videos # do
    # get :download, on: :member
  # end

  get 'create_new_video' => 'videos#create_new_video', as: :create_new_video

  root to: 'pages#landing'

  devise_for :users, controllers: { :omniauth_callbacks => "users/omniauth_callbacks" }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
