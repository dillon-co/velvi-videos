Rails.application.routes.draw do

  resources :videos # do
    # get :download, on: :member
  # end

  root to: 'pages#landing'

  devise_for :users, controllers: { :omniauth_callbacks => "users/omniauth_callbacks" }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
