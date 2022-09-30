Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'tickets#index'
  namespace :api do
    resources :tickets
  end
  resources :tickets
end
