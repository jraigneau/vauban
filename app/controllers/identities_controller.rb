require "encryptor"

class IdentitiesController < ApplicationController

  before_filter :require_user
  ssl_required :index, :new, :edit, :create, :update, :destroy if Rails.env.production?

  # GET /identities
  # GET /identities.xml
  def index
    @identities = current_user.identities.find(:all,:order => "name,created_at")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @identities }
    end
  end

  # GET /identities/new
  # GET /identities/new.xml
  def new
    @identity = Identity.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @identity }
    end
  end

  # GET /identities/1/edit
  def edit
    #test secretsentence here
    digested_key = hash_secretkey(params[:secretkey])
    if current_user.secretkey != digested_key 
      flash[:error] = 'Sorry but your secret key doesn\'t match.'
      redirect_to(identities_url) 
    else
      @identity = current_user.identities.find(params[:id])
      @identity.login = decrypt_identity(digested_key,@identity.login)
      @identity.password = decrypt_identity(digested_key,@identity.password)
    end
  end


  # POST /identities
  # POST /identities.xml
  def create
    @identity = current_user.identities.new(params[:identity])      
    #1 check secretkey
    digested_key = hash_secretkey(params[:secretkey])
    if current_user.secretkey != digested_key
      respond_to do |format|
        flash[:error] = 'Sorry but your secret key doesn\'t match!'
        format.html { render :action => "new" }
      end
    elsif @identity.login.empty? || @identity.password.empty?
      respond_to do |format|
        flash[:error] = 'Sorry but you need to type a login and a password'
        format.html { render :action => "new" }
      end
    else
      #2 encrypt login/pwd
      @identity.login = encrypt_identity(digested_key,@identity.login)
      @identity.password = encrypt_identity(digested_key,@identity.password)
      respond_to do |format|
        if @identity.save
          flash[:notice] = 'Identity was successfully created.'
          format.html { redirect_to(identities_url) }
          #format.xml  { render :xml => @identity, :status => :created, :location => @identity }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @identity.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /identities/1
  # PUT /identities/1.xml
  def update
    @identity = current_user.identities.find(params[:id])
    #1 check secretkey
    digested_key = hash_secretkey(params[:secretkey])
    if current_user.secretkey != digested_key
        @identity.login = params[:identity][:login]
        @identity.password = params[:identity][:password]
        respond_to do |format|
            flash[:error] = 'Sorry but your secret key doesn\'t match!'
            format.html { render :action => "edit" }
        end
     elsif params[:identity][:login].blank? or params[:identity][:password].blank?
        @identity.login = params[:identity][:login]
        @identity.password = params[:identity][:password]
        respond_to do |format|
            flash[:error] = 'Sorry but you need to type a login and a password'
            format.html { render :action => "edit" }
        end
        
     else
      #2 encrypt login/pwd
      params[:identity][:login] = encrypt_identity(digested_key,params[:identity][:login])
      params[:identity][:password] = encrypt_identity(digested_key,params[:identity][:password])

       respond_to do |format|
         if @identity.update_attributes(params[:identity])
           flash[:notice] = 'Identity was successfully updated.'
           format.html { redirect_to(identities_url) }
           format.xml  { head :ok }
         else
           format.html { render :action => "edit" }
           format.xml  { render :xml => @identity.errors, :status => :unprocessable_entity }
         end
       end
    end
  end

  # DELETE /identities/1
  # DELETE /identities/1.xml
  def destroy
    @identity = current_user.identities.find(params[:id])
    @identity.destroy

    respond_to do |format|
      flash[:notice] = 'Identity was successfully deleted.'
      format.html { redirect_to(identities_url) }
      format.xml  { head :ok }
    end
  end


  

end
