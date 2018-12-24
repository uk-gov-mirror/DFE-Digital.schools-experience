class PagesController < ApplicationController
  def show
    render template: "pages/#{params[:page]}"
  end
  
  def set_name
    if params[:name].present?
      session[:username] = params[:name]
    end
    
    redirect_to '/pages/home'
  end
end
