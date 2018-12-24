Rails.application.routes.draw do
  get "/pages/:page", to: "pages#show"
  post "/pages/set_name", to: 'pages#set_name'
end
