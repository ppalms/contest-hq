module Contests
  class PerformancePhasesController < ApplicationController
    before_action :authenticate
    before_action :set_contest
    before_action :authorize_manager

    def index
    end

    def edit
    end

    def update
      @contest.assign_attributes(phase_params)
      PerformancePhaseOrderer.normalize_ordinals(@contest)

      if @contest.save
        respond_to do |format|
          format.turbo_stream do
            flash[:notice] = "Performance setup updated."

            render turbo_stream: [
              turbo_stream.append("notifications", partial: "shared/notification"),
              turbo_stream.replace("contest_phase_content", partial: "contests/performance_phases/phase_list")
            ]

            flash.discard(:notice)
          end

          format.html do
            flash[:notice] = "Performance setup updated."
            redirect_to contest_setup_path(@contest)
          end
        end
      else
        Rails.logger.error "Save failed: #{@contest.errors.full_messages.inspect}"
        render :edit
      end
    end

    private

    def set_contest
      @contest = Contest.find(params[:contest_id])
    end

    def authorize_manager
      unless current_user.manages_contest(@contest)
        redirect_to contest_schedule_summary_path(@contest),
          alert: "You must be a manager of this contest to access this area"
      end
    end

    def phase_params
      params.require(:contest).permit(
        performance_phases_attributes: [
          :id,
          :ordinal,
          :name,
          :room_id,
          :duration,
          :_destroy
        ]
      )
    end
  end
end
