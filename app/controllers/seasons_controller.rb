class SeasonsController < ApplicationController
  before_action :set_season, only: %i[ show edit update destroy ]
  before_action -> { require_role "AccountAdmin" }
  before_action :set_breadcrumbs

  # GET /seasons
  def index
    @seasons = Season.by_name
  end

  # GET /seasons/1
  def show
  end

  # GET /seasons/new
  def new
    @season = Season.new
    # Auto-suggest next year if current year season exists
    current_year = Date.current.year
    if Season.exists?(name: current_year.to_s)
      @season.name = (current_year + 1).to_s
    else
      @season.name = current_year.to_s
    end
  end

  # GET /seasons/1/edit
  def edit
  end

  # POST /seasons
  def create
    @season = Season.new(season_params)

    respond_to do |format|
      if @season.save
        format.html { redirect_to seasons_url, notice: "Season was successfully created." }
        format.json { render :show, status: :created, location: @season }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @season.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /seasons/1
  def update
    respond_to do |format|
      if @season.update(season_params)
        format.html { redirect_to seasons_url, notice: "Season was successfully updated." }
        format.json { render :show, status: :ok, location: @season }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @season.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /seasons/1
  def destroy
    respond_to do |format|
      if @season.contests.any?
        format.html { redirect_to seasons_url, alert: "Cannot delete season with contests. Archive it instead." }
        format.json { render json: { error: "Cannot delete season with contests" }, status: :unprocessable_entity }
      else
        @season.destroy!
        format.html { redirect_to seasons_url, notice: "Season was successfully deleted." }
        format.json { head :no_content }
      end
    end
  end

  private

  def set_season
    @season = Season.find(params[:id])
  end

  def season_params
    params.expect(season: [ :name, :archived ])
  end

  def set_breadcrumbs
    add_breadcrumb("Seasons", seasons_path)
  end
end
