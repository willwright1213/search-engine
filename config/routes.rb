Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
  post '/crawl', to: "crawlers#crawl"
  get '/populars', to: "populars#index"
  get '/page/:id', to: "populars#show"

end
