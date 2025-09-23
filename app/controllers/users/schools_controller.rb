module Users
  class SchoolsController < ApplicationController
    include Pagy::Backend

    before_action -> { require_role "SysAdmin", "AccountAdmin" }
    before_action :set_user
    before_action :set_breadcrumbs

    def index
      search_query = School.order(:name)
      if params[:search].present?
        search_term = "%#{params[:search]}%"
        search_query = search_query.where("name LIKE ?", search_term)
      end

      @pagy, @schools = pagy(search_query, limit: 10)
    end

    def create
      school_ids = params[:user][:school_ids].reject(&:blank?)
      new_schools = School.where(id: school_ids) - @user.schools

      if new_schools.any?
        @user.schools += new_schools
        success_message = "#{new_schools.count} school(s) added successfully."
        if params[:from_invitation]
          redirect_to edit_user_path(@user), notice: "#{success_message} Invitation email has been sent to #{@user.email}."
        else
          redirect_to edit_user_path(@user), notice: success_message
        end
      else
        redirect_to edit_user_path(@user), alert: "No new schools were selected."
      end
    end

    private

    def set_user
      @user = User.find(params[:user_id])
    end

    def set_breadcrumbs
      add_breadcrumb("Users", users_path)
      add_breadcrumb("Edit #{@user.first_name} #{@user.last_name}", edit_user_path(@user))
      add_breadcrumb("Select Schools", user_schools_path(@user))
    end
  end
end
