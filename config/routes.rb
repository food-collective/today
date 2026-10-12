Rails.application.routes.draw do
  root 'sessions#new'
  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  post 'logout' => 'sessions#destroy'
  get 'today' => redirect('/tasks')

  post 'checkmark' => 'tasks#checkmark'
  post 'checking_as' => 'tasks#checking_as'

  get 'settings' => 'settings#index'
  post 'settings' => 'settings#update'
  get 'update_password' => 'settings#change_password'
  post 'update_password' => 'settings#update_password'

  resources :announcements, only: [:index]
  resources :tasks, only: [:index, :create, :edit, :update, :destroy]
end
