module Schedules
  class DaysController < ApplicationController
    before_action :set_schedule

    def index
      @days = @schedule.days
    end

    def show
      @day = @schedule.days.find(params[:id])
    end

    private

    def set_schedule
      @schedule = Schedule.find(params[:schedule_id])
    end
  end
end
