Rails.application.routes.draw do
  # root to: 'home#index'
  root to: redirect(path: '/dashboard')

  get 'version', to: Proc.new { |env| [200, {"Content-Type" => 'text/plain'}, ["__COMMIT_INFO__"]] }

  get 'regulations', to: 'home#index', as: :regulations
  get 'dashboard', to: 'dashboard#index', as: :dashboard

  # Authentication
  get 'ping' => 'auth#ping'

  resources :reports do
    member do
      get :copy
      get :make
      get :result
      get :source
      get :export
      get :email
      # get :make_data
      # get :make_image
    end
  end

  resources :base_reports, only: [:show] do
    member do
      get :make
      get :draw
      get :export
      get :email
    end
  end
  get '500_test', to: proc{ raise '500' }
end
