class PerformanceClassesController < ApplicationController
  before_action :set_performance_class, only: %i[show]

  def index
    @performance_classes = PerformanceClass.all
  end

  def show
  end

  private

  def set_performance_class
    @performance_class = PerformanceClass.find(params[:id])
  end

  def performance_class_params
    params.require(:performance_class).permit(:name)
  end
end
