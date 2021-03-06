# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'encryptor'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include SslRequirement


  # Scrub sensitive parameters from your log
  filter_parameter_logging :username,:login,:password, :password_confirmation , :secretkey, :secretkey_confirmation

  # GET /
  def index
    respond_to do |format|
      format.html # index.html.erb
    end
  end



  helper_method :current_user
        
  
  
  
  private
    def current_user_session
      return @current_user_session if defined?(@current_user_session)
      @current_user_session = UserSession.find
    end
    
    def current_user
      return @current_user if defined?(@current_user)
      @current_user = current_user_session && current_user_session.record
    end
     
    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        flash[:notice] = "You must be logged out to access this page"
        redirect_to root_url
        return false
      end
    end
    
    def store_location
      session[:return_to] = request.request_uri
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    def hash_secretkey(secret_key)
      Digest::SHA256.hexdigest(secret_key)
    end
    
    def encrypt_identity(digested_key,value)
      [Encryptor.encrypt(:value => value, :key => digested_key)].pack('m*')
    end
    
    def decrypt_identity(digested_key,encrypted_value)
      Encryptor.decrypt(:value => encrypted_value.unpack('m*').to_s, :key => digested_key)
    end

end
