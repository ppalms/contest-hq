module Schedules
  class PerformanceSequencesController < ApplicationController
    before_action :authenticate
    before_action :set_schedule
    # before_action :authorize_manager

    def index
      @sequence = @schedule.performance_sequence
    end

    def edit
      @sequence = @schedule.performance_sequence
    end

    def update
      @sequence = @schedule.performance_sequence
      @sequence.assign_attributes(sequence_params)
      Schedules::PerformanceStepOrderer.normalize_ordinals(@sequence)
      @sequence.save

      if @sequence.errors.empty?
        redirect_to contest_schedule_setup_path,
          turbo_frame: "schedule_sequence_content",
          notice: "Performance setup updated."
      else
        render :edit
      end
    end

    def reorder
      sequence = PerformanceSequence.find(params[:sequence_id])
      step_ids = params[:step_ids]

      PerformanceStepOrderer.reorder_steps(step_ids, sequence.id)

      respond_to do |format|
        format.html { redirect_to contest_schedule_setup_path(sequence), notice: "Steps reordered successfully." }
        format.json { head :ok }
      end
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to contest_schedule_setup_path(sequence), alert: "Invalid step order provided." }
        format.json { head :unprocessable_entity }
      end
    end

    def move
      step = PerformanceStep.find(params[:id])

      if [ :up, :down ].include?(params[:direction].to_sym)
        PerformanceStepOrderer.move_step(step.id, params[:direction])
        redirect_to contest_schedule_setup_path(step.performance_sequence), notice: "Step moved successfully."
      else
        redirect_to contest_schedule_setup_path(step.performance_sequence), alert: "Invalid direction."
      end
    end
    private

    def set_schedule
      @schedule = Schedule.find(params[:schedule_id])
    end

    def authorize_manager
      unless current_user.managed_contests.exists?(params[:contest_id])
        redirect_to root_path,
          alert: "You must be a manager of this contest to access this area",
          turbo: false
      end
    end

    def sequence_params
      params.require(:performance_sequence).permit(
        performance_steps_attributes: [
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
