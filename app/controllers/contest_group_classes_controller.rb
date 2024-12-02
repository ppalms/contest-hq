class ContestGroupClassesController < ApplicationController
  before_action :set_contest_group_class, only: %i[show]

  def index
    @contest_group_classes = ContestGroupClass.all
  end

  def show
  end

  private

  def set_contest_group_class
    @contest_group_class = ContestGroupClass.find(params[:id])
  end

  def contest_group_class_params
    params.require(:contest_group_class).permit(:name)
  end
end
