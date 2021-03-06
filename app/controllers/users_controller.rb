class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update, :delete]
  
  ssl_required :new, :create, :edit, :update, :destroy if Rails.env.production?
  ssl_allowed :index if Rails.env.production?

  def index
    redirect_back_or_default :controller => "application",:action => "index"
  end

  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Registration successful."
      Notifier.deliver_new_user(@user)
      redirect_to :controller => "identities", :action => "index"
    else
      render :action => 'new'
    end
  end
  
  def edit
    @user = current_user
  end
  
  def update
    @user = current_user
    if @user.update_attributes(params[:user])
      flash[:notice] = "Successfully updated profile."
      redirect_back_or_default root_url
    else
      render :action => 'edit'
    end
  end
  
  def destroy
    @user = current_user
    @user_session = UserSession.find
    digested_key = hash_secretkey(params[:secretkey])
    if current_user.secretkey != digested_key 
      flash[:error] = 'Sorry but your secret key doesn\'t match.'
      render :action => "edit"
    else
      if @user.destroy
        Notifier.deliver_delete_account(@user)
        Notifier.deliver_lost_user(@user)      
        @user_session.destroy
        flash[:notice] = "Successfully deleted your account"
        redirect_to :controller => :application, :action => "index"
      else
        flash[:error] = 'Sorry an error occurs while deleting your account'
        render :action => "edit"
      end
    end
    
  end
end
