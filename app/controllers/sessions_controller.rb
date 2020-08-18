class SessionsController < ApplicationController
  layout "auth"
  skip_before_action :authenticate_user!, only: %i[new create create_from_oauth]

  def create
    @user = User.where(email: user_params[:email]).first
    if @user&.authenticate(user_params[:password])
      set_current_user(@user, user_params[:remember_me])
      if params["chrome-callback"].present?
        redirect_to params["chrome-callback"] + "?extension-token=#{@user.extension_token}"
      else
        redirect_to root_path
      end
    else
      flash.now[:error] = "Email or password is wrong"
      render "new"
    end
  end

  def create_from_oauth
    @user = User.find_or_create_from_auth(request.env["omniauth.auth"])
    if @user
      set_current_user(@user)
      flash[:success] = "Login successed"
      if request.env["omniauth.params"]["chrome-callback"].present?
        redirect_to request.env["omniauth.params"]["chrome-callback"] + "?extension-token=#{@user.extension_token}"
      else
        redirect_to root_path
      end
    else
      flash[:error] = "Login failed"
      redirect_to root_path
    end
  end

  def destroy
    cookies[:remember_token_v2] = {
      value: nil
    }
    flash[:success] = "Logout successed"
    redirect_to root_path
  end

  def new
    @user = User.new
  end

  def user_params
    params.require(:user).permit(:email, :password, :remember_me)
  end
end