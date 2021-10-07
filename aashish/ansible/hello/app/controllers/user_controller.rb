class UserController < ApplicationController
  def index
    users = User.all
    render json: users.to_json
  end

  def show
    user = User.find_by(id: params[:id])
    puts 
    render json: user.to_json
  end

  def create
    user = User.new(username: params[:username], password: params[:password])
    user.save
    render json: user.to_json
  end

  def destroy
    user = User.delete(params[:id])
    render json: user.to_json
  end
end
