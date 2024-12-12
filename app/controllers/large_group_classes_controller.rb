class LargeGroupClassesController < ApplicationController
  before_action :set_large_group_class, only: %i[show]

  def index
    @large_group_classes = LargeGroupClass.all
  end

  def show
  end

  private

  def set_large_group_class
    @large_group_class = LargeGroupClass.find(params[:id])
  end

  def large_group_class_params
    params.require(:large_group_class).permit(:name)
  end
end
