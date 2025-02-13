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
        redirect_to contest_setup_path,
          turbo_frame: "contest_setup_content",
          notice: "Performance setup updated."
      else
        puts "Save failed: #{@contest.errors.full_messages.inspect}"
        render :edit
      end
    end

    def reorder
      phase_ids = params[:phase_ids]

      PerformancePhaseOrderer.reorder_phases(phase_ids, contest.id)

      respond_to do |format|
        format.html { redirect_to contest_setup_path(contest), notice: "Phases reordered successfully." }
        format.json { head :ok }
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to contest_setup_path(contest), alert: "Invalid phase order provided." }
        format.json { head :unprocessable_entity }
      end
    end

    def move
      phase = PerformancePhase.find(params[:id])

      if [ :up, :down ].include?(params[:direction].to_sym)
        PerformancePhaseOrderer.move_phase(phase.id, params[:direction])
        redirect_to contest_setup_path(phase.performance_phase), notice: "Phase moved successfully."
      else
        redirect_to contest_setup_path(phase.performance_phase), alert: "Invalid direction."
      end
    end
    private

    def set_contest
      @contest = Contest.find(params[:contest_id])
    end

    def authorize_manager
      unless current_user.manager? && current_user.managed_contests&.exists?(params[:contest_id])
            redirect_to contest_schedule_path(@contest),
              alert: "You must be a manager of this contest to access this area",
              turbo_frame: "contest_setup_content"
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
