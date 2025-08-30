module Contests
  class RoomsController < ApplicationController
    before_action :authenticate
    before_action :set_contest
    before_action :set_room, only: [ :edit, :update, :destroy ]
    before_action :authorize_manager

    def index
      @rooms = @contest.rooms
    end

    def new
      @room = @contest.rooms.new
    end

    def create
      @room = @contest.rooms.new(room_params)

      if @room.save
        set_contest

        respond_to do |format|
          format.turbo_stream do
            flash[:notice] = "Room was successfully created."

            render turbo_stream: [
              turbo_stream.append("notifications", partial: "shared/notification"),
              turbo_stream.replace("contest_room_content", partial: "contests/rooms/room_list")
            ]

            flash.discard(:notice)
          end

          format.html do
            flash[:notice] = "Room was successfully created."
            redirect_to contest_setup_path(@contest)
          end
        end
      else
        puts "Save failed: #{@room.errors.full_messages.inspect}"
        render :new
      end
    end

    def edit
    end

    def update
      if @room.update(room_params)
        set_contest

        respond_to do |format|
          format.turbo_stream do
            flash[:notice] = "Room was successfully updated."

            render turbo_stream: [
              turbo_stream.append("notifications", partial: "shared/notification"),
              turbo_stream.replace("contest_room_content", partial: "contests/rooms/room_list"),
              turbo_stream.replace("contest_phase_content", partial: "contests/performance_phases/phase_list")
            ]

            flash.discard(:notice)
          end

          format.html do
            flash[:notice] = "Room was successfully updated."
            redirect_to contest_setup_path(@contest)
          end
        end
      else
        puts "Save failed: #{@room.errors.full_messages.inspect}"
        render :edit
      end
    end

    def destroy
      if @room.destroy
        set_contest

        respond_to do |format|
          format.turbo_stream do
            flash[:notice] = "Room was successfully deleted."

            render turbo_stream: [
              turbo_stream.append("notifications", partial: "shared/notification"),
              turbo_stream.replace("contest_room_content", partial: "contests/rooms/room_list"),
              turbo_stream.replace("contest_phase_content", partial: "contests/performance_phases/phase_list")
            ]

            flash.discard(:notice)
          end

          format.html do
            flash[:notice] = "Room was successfully deleted."
            redirect_to contest_setup_path(@contest)
          end
        end
      else
        puts "Save failed: #{@room.errors.full_messages.inspect}"
        redirect_to contest_setup_path(@contest)
      end
    end

    private

    def set_room
      @room = @contest.rooms.find(params[:id])
    end

    def set_contest
      @contest = Contest.find(params[:contest_id])
    end

    def authorize_manager
      # TODO: add contest/user association
      # unless current_user.manager? && current_user.managed_contests&.exists?(params[:contest_id])
      unless current_user.manager?
            redirect_to contest_schedule_summary_path(@contest),
              alert: "You must be a manager of this contest to access this area"
      end
    end

    def room_params
      params.require(:room).permit(:name, :room_number)
    end
  end
end
