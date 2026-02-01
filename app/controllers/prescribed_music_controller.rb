class PrescribedMusicController < ApplicationController
  include Pagy::Method

  before_action :set_prescribed_music, only: [ :edit, :update, :destroy ]
  before_action :require_account_admin, only: [ :new, :create, :edit, :update, :destroy ]
  before_action :set_breadcrumbs

  def index
    @selected_season_id = params[:season_id]
    @seasons = Season.by_name

    if @selected_season_id.present?
      @selected_season = Season.find(@selected_season_id)
    else
      @selected_season = Season.current_season
      @selected_season_id = @selected_season&.id
    end

    scope = PrescribedMusic.includes(:season, :school_class).by_title
    scope = scope.for_season(@selected_season_id) if @selected_season_id.present?
    scope = scope.for_school_class(params[:school_class_id]) if params[:school_class_id].present?

    @pagy, @prescribed_music = pagy(scope, limit: 20)
    @school_classes = SchoolClass.order(:ordinal)
  end

  def new
    @prescribed_music = PrescribedMusic.new
    @prescribed_music.season = Season.current_season
  end

  def create
    @prescribed_music = PrescribedMusic.new(prescribed_music_params)

    if @prescribed_music.save
      redirect_to prescribed_music_index_path(season_id: @prescribed_music.season_id),
                  notice: "Prescribed music was successfully created."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @prescribed_music.update(prescribed_music_params)
      redirect_to prescribed_music_index_path(season_id: @prescribed_music.season_id),
                  notice: "Prescribed music was successfully updated."
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    season_id = @prescribed_music.season_id
    @prescribed_music.destroy!

    redirect_to prescribed_music_index_path(season_id: season_id),
                notice: "Prescribed music was successfully deleted."
  end

  private

  def set_prescribed_music
    @prescribed_music = PrescribedMusic.find(params[:id])
  end

  def prescribed_music_params
    params.expect(prescribed_music: [ :title, :composer, :season_id, :school_class_id ])
  end

  def require_account_admin
    unless current_user.account_admin?
      redirect_to prescribed_music_index_path,
                  alert: "You must be an account admin to perform this action."
    end
  end

  def set_breadcrumbs
    add_breadcrumb("Prescribed Music", prescribed_music_index_path)
  end
end
