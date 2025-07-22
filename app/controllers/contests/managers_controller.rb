module Contests
  class ManagersController < ApplicationController
    include Pagy::Backend

    before_action :authenticate
    before_action :set_contest
    before_action :set_contest_manager, only: [ :destroy ]
    before_action -> { require_role "AccountAdmin" }
    before_action :set_breadcrumbs

    def index
      @contest_managers = @contest.contest_managers.includes(:user)
      @pagy, @users = pagy(User.joins(:roles).where(roles: { name: "Manager" }).where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"), limit: 10)
    end

    def new
      @contest_manager = @contest.contest_managers.new

      if params[:search].present?
        @pagy, @users = pagy(
          User.joins(:roles)
              .where(roles: { name: "Manager" })
              .where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?",
                     "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"),
          limit: 10
        )
      else
        @pagy, @users = pagy(User.joins(:roles).where(roles: { name: "Manager" }), limit: 10)
      end
    end

    def create
      @contest_manager = @contest.contest_managers.new(contest_manager_params)

      if @contest_manager.save
        redirect_to contest_managers_path(@contest), notice: "Manager was successfully associated with the contest."
      else
        @pagy, @users = pagy(User.joins(:roles).where(roles: { name: "Manager" }), limit: 10)
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      if @contest_manager.destroy
        redirect_to contest_managers_path(@contest), notice: "Manager association was successfully removed."
      else
        redirect_to contest_managers_path(@contest), alert: "Unable to remove manager association."
      end
    end

    private

    def set_contest
      @contest = Contest.find(params[:contest_id])
    end

    def set_contest_manager
      @contest_manager = @contest.contest_managers.find(params[:id])
    end

    def contest_manager_params
      params.require(:contest_manager).permit(:user_id)
    end

    def set_breadcrumbs
      add_breadcrumb("Contests", contests_path)
      add_breadcrumb(@contest.name, @contest) if @contest
      add_breadcrumb("Managers")
    end
  end
end
