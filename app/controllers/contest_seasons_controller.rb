class ContestSeasonsController < ApplicationController
  include Pagy::Backend

  before_action :set_contest_season, only: %i[show edit update destroy]
  before_action -> { require_role "AccountAdmin" }
  before_action :set_breadcrumbs

  # GET /contest_seasons
  def index
    @pagy, @contest_seasons = pagy(ContestSeason.all.order(:name), limit: 20)
  end

  # GET /contest_seasons/1
  def show
  end

  # GET /contest_seasons/new
  def new
    @contest_season = ContestSeason.new
  end

  # GET /contest_seasons/1/edit
  def edit
  end

  # POST /contest_seasons
  def create
    @contest_season = ContestSeason.new(contest_season_params)

    respond_to do |format|
      if @contest_season.save
        format.html { redirect_to contest_season_url(@contest_season), notice: "Contest season was successfully created." }
        format.json { render :show, status: :created, location: @contest_season }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @contest_season.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contest_seasons/1
  def update
    respond_to do |format|
      if @contest_season.update(contest_season_params)
        format.html { redirect_to contest_season_url(@contest_season), notice: "Contest season was successfully updated." }
        format.json { render :show, status: :ok, location: @contest_season }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @contest_season.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contest_seasons/1
  def destroy
    @contest_season.destroy!

    respond_to do |format|
      format.html { redirect_to contest_seasons_url, notice: "Contest season was successfully deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_contest_season
    @contest_season = ContestSeason.find(params[:id])
  end

  def contest_season_params
    params.expect(contest_season: [:name])
  end

  def set_breadcrumbs
    add_breadcrumb("Contest Seasons", contest_seasons_path)
  end
end
