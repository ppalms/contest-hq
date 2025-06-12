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
            redirect_to contest_setup_path, turbo_frame: "contest_setup_content"
          end
        end
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
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to contest_setup_path(contest), alert: "Invalid phase order provided." }
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
      # TODO: add contest/user association
      unless current_user.manager?
        redirect_to contest_schedule_summary_path(@contest),
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
