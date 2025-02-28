module Schedules
  class DaysController < ApplicationController
    before_action :set_schedule

    def index
      @days = @schedule.days
      @selected_day = @days.first
    end

    def show
      @selected_day = @schedule.days.find(params[:id])
    end

    private

    def set_schedule
      @schedule = Schedule.find(params[:schedule_id])
    end
  end
end
