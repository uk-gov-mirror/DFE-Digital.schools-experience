Rails.application.routes.draw do
  get "/pages/:page", to: "pages#show"
  root to: 'pages#home'
end
