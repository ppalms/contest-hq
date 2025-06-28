class AccountsController < ApplicationController
  include Pagy::Backend

  before_action :authorize_sysadmin!
  before_action :set_account, only: %i[ show edit update ]
  before_action :set_breadcrumbs

  def index
    @pagy, @accounts = pagy(Account.all, limit: 6)
  end

  def show
  end

  def new
    @account = Account.new
  end

  def edit
  end

  def create
    @account = Account.new(account_params)

    respond_to do |format|
      if @account.save
        format.html { redirect_to @account, notice: "Account was successfully created." }
        format.json { render :show, status: :created, location: @account }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @account.update(account_params)
        format.html { redirect_to @account, notice: "Account was successfully updated." }
        format.json { render :show, status: :ok, location: @account }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @account.errors, status: :unprocessable_entity }
      end
    end
  end

  private
    def set_account
      @account = Account.find(params.expect(:id))
    end

    def account_params
      params.expect(account: [ :name ])
    end

    def set_breadcrumbs
      add_breadcrumb("Accounts", accounts_path)
    end

    def authorize_sysadmin!
      unless current_user.sysadmin?
        flash[:alert] = "You must be a system administrator to access this area"
        redirect_to root_path
      end
    end
end
