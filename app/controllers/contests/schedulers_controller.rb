module Contests
  class SchedulersController < ApplicationController
    include Pagy::Backend

    before_action :authenticate
    before_action :set_contest
    before_action :set_contest_scheduler, only: [ :destroy ]
    before_action -> { require_role "AccountAdmin" }

    def index
      @contest_schedulers = @contest.contest_schedulers.includes(:user)
      @pagy, @users = pagy(User.joins(:roles).where(roles: { name: "Scheduler" }).where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%", "%#{params[:search]}%"), limit: 10)
    end

    def new
      @contest_scheduler = @contest.contest_schedulers.new
      @pagy, @users = pagy(User.joins(:roles).where(roles: { name: "Scheduler" }), limit: 10)
    end

    def create
      @contest_scheduler = @contest.contest_schedulers.new(contest_scheduler_params)

      if @contest_scheduler.save
        redirect_to contest_schedulers_path(@contest), notice: "Scheduler was successfully associated with the contest."
      else
        @pagy, @users = pagy(User.joins(:roles).where(roles: { name: "Scheduler" }), limit: 10)
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      if @contest_scheduler.destroy
        redirect_to contest_schedulers_path(@contest), notice: "Scheduler association was successfully removed."
      else
        redirect_to contest_schedulers_path(@contest), alert: "Unable to remove scheduler association."
      end
    end

    private

    def set_contest
      @contest = Contest.find(params[:contest_id])
    end

    def set_contest_scheduler
      @contest_scheduler = @contest.contest_schedulers.find(params[:id])
    end

    def contest_scheduler_params
      params.require(:contest_scheduler).permit(:user_id)
    end
  end
end