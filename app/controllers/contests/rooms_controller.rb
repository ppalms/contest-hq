module Contests
  class RoomsController < ApplicationController
    before_action :authenticate
    before_action :set_contest
    # before_action :authorize_manager

    def index
      @rooms = @contest.rooms
    end

    def new
      @room = @contest.rooms.build
    end

    def create
      @room = @contest.rooms.new(room_params)

      if @room.save
        redirect_to contest_setup_path(@contest, @contest), turbo_frame: "contest_room_content", notice: "Room was successfully created."
      else
        render :new
      end
    end

    def edit
      @room = @contest.rooms.find(params[:id])
    end

    def update
      @room = @contest.rooms.find(params[:id])
      if @room.update(room_params)
        redirect_to contest_setup_path(@contest, @contest), turbo_frame: "contest_room_content", notice: "Room was successfully updated."
      else
        render :edit
      end
    end

    def destroy
      @room = @contest.rooms.find(params[:id])
      @room.destroy

      redirect_to contest_setup_path(@contest), turbo_frame: "contest_room_content", notice: "Room was successfully deleted."
    end

    private

    def set_contest
      @contest = Contest.find(params[:contest_id])
    end

    def authorize_manager
      unless current_user.managed_contests.exists?(@contest.id)
        redirect_to root_path, alert: "You must be a manager of this contest to access this area", turbo: false
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
