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
      @room = @contest.rooms.build
    end

    def create
      @room = @contest.rooms.new(room_params)

      if @room.save
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
            redirect_to contest_setup_path, turbo_frame: "contest_setup_content"
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
        respond_to do |format|
          format.turbo_stream do
            flash[:notice] = "Room was successfully updated."

            render turbo_stream: [
              turbo_stream.append("notifications", partial: "shared/notification"),
              turbo_stream.replace("contest_room_content", partial: "contests/rooms/room_list")
            ]

            flash.discard(:notice)
          end

          format.html do
            redirect_to contest_setup_path, turbo_frame: "contest_setup_content"
          end
        end
      else
        puts "Save failed: #{@room.errors.full_messages.inspect}"
        render :edit
      end
    end

    def destroy
      if @room.destroy
        respond_to do |format|
          format.turbo_stream do
            flash[:notice] = "Room was successfully deleted."

            render turbo_stream: [
              turbo_stream.append("notifications", partial: "shared/notification"),
              turbo_stream.replace("contest_room_content", partial: "contests/rooms/room_list")
            ]

            flash.discard(:notice)
          end

          format.html do
            redirect_to contest_setup_path, turbo_frame: "contest_setup_content"
          end
        end
      else
        puts "Save failed: #{@room.errors.full_messages.inspect}"
        redirect_to contest_setup_path, turbo_frame: "contest_setup_content"
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
      unless current_user.manager? && current_user.managed_contests&.exists?(params[:contest_id])
            redirect_to contest_schedule_path(@contest),
              alert: "You must be a manager of this contest to access this area",
              turbo_frame: "contest_setup_content"
      end
    end

    def room_params
      params.require(:room).permit(:name, :room_number)
    end
  end
end

#   class RoomsController < ApplicationController
#     def index
#       @rooms = Rooms.find_by(schedule_id: params[:schedule_id])
#     end
#
#     def create
#       Room.create(room_params)
#
#       respond_to do |format|
#         if @room.save!
#           format.html { redirect_to contest_schedules_path(params[:contest_id]), notice: "Room was successfully created." }
#           format.json { render :index, status: :ok, rooms: @rooms }
#         else
#           format.html { render :edit, status: :unprocessable_entity }
#           format.json { render json: @room.errors, status: :unprocessable_entity }
#         end
#       end
#     end
#
#     private
#
#     def room_params
#       params.expect(room: [ :name, :room_number, :schedule_id, :contest_id ])
#     end
#   end
# end
