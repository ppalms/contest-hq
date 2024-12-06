class Identity::ProfilesController < ApplicationController
  before_action :set_user, only: %i[ show edit update ]

  def show
  end

  def edit
  end

  def update
    if @user.update(user_params)
      redirect_to settings_path, notice: "Your profile has been updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_user
      @user = current_user
    end

    def user_params
      params.expect(user: [ :first_name, :last_name, :time_zone ])
    end
end
