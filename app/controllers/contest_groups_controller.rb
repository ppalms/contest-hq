class ContestGroupsController < ApplicationController
  before_action :set_contest_group, only: %i[show]

  def index
    @empty_text = "No contest groups found"
    @empty_hint = "Create a contest group to register for contests"
    @create_text = "Create contest group"
    @create_path = new_contest_group_path

    if index_params[:filter_current_user] == "false"
      @contest_groups = ContestGroup.includes(:contest_group_class).all
    else
      @contest_groups = current_user.conducted_groups.includes(:contest_group_class).all
    end
  end

  def show
  end

  private

  def set_contest_group
    @contest_group = ContestGroup.find(params[:id])
  end

  def contest_group_params
    params.expect(contest_group: [ :name, :contest_group_class_id ])
  end

  def index_params
    params.permit(:filter_current_user)
  end
end
