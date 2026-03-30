Rails.application.routes.draw do
  root "demo#index"

  post "demo/cache_write"
  post "demo/cache_read"
  post "demo/enqueue_job"
  post "demo/broadcast"
  post "demo/stats"

  get "up" => "rails/health#show", as: :rails_health_check
end
