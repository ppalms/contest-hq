class MusicSelectionsController < ApplicationController
  before_action :set_contest_entry
  before_action :set_music_selection, only: %i[ show destroy ]
  before_action :set_breadcrumbs

  def index
    @music_selections = @contest_entry.music_selections.all
  end

  def new
    @music_selection = @contest_entry.music_selections.new
  end

  def select_prescribed
    @prescribed_music = []
    @current_prescribed_selection = @contest_entry.prescribed_selection

    if params.key?(:search)
      base_query = PrescribedMusic
        .for_season(@contest_entry.contest.season.id)
        .for_school_class(@contest_entry.large_ensemble.school.school_class.id)

      if params[:search].present?
        search_term = "%#{params[:search]}%"
        @prescribed_music = base_query
          .where("LOWER(title) LIKE LOWER(?) OR LOWER(composer) LIKE LOWER(?)", search_term, search_term)
          .by_title
      else
        @prescribed_music = base_query.by_title
      end
    end

    render layout: false
  end

  def select_custom
    @music_selection = @contest_entry.music_selections.new
    @slot_number = params[:slot]&.to_i || 1
    render layout: false
  end

  def add_prescribed
    prescribed_music = PrescribedMusic.find(params[:prescribed_music_id])

    existing_prescribed = @contest_entry.prescribed_selection
    if existing_prescribed
      existing_prescribed.update!(prescribed_music: prescribed_music)
      @music_selection = existing_prescribed
    else
      @music_selection = @contest_entry.music_selections.create!(prescribed_music: prescribed_music)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to contest_entry_path(@contest_entry.contest, @contest_entry), notice: "Prescribed music selected." }
    end
  end

  def create
    @music_selection = @contest_entry.music_selections.new(music_selection_params)

    respond_to do |format|
      if @music_selection.save
        format.turbo_stream
        format.html { redirect_to contest_entry_path(@contest_entry.contest, @contest_entry), notice: "Music selection added." }
        format.json { render :show, status: :created, music_selection: @music_selection }
      else
        format.html { render :select_custom, status: :unprocessable_content, layout: false }
        format.json { render json: @music_selection.errors, status: :unprocessable_content }
      end
    end
  end

  def show
  end

  def destroy
    @music_selection.destroy!

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to contest_entry_path(@contest_entry.contest, @contest_entry), notice: "Music selection removed." }
      format.json { head :no_content }
    end
  end

  def bulk_edit
    @music_selections = @contest_entry.music_selections.order(:position)
    render layout: false
  end

  def bulk_update
    ActiveRecord::Base.transaction do
      params[:music_selections].each do |ms_params|
        music_selection = @contest_entry.music_selections.unscoped.find(ms_params[:id])
        music_selection.update!(
          position: ms_params[:position],
          title: ms_params[:title],
          composer: ms_params[:composer]
        )
      end
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("music_selections", partial: "contest_entries/music_selections") }
      format.html { redirect_to contest_entry_path(@contest_entry.contest, @contest_entry), notice: "Music selections updated." }
    end
  end

  private

  def set_contest_entry
    @contest_entry = ContestEntry.find(params[:entry_id])
  end

  def set_music_selection
    @music_selection = MusicSelection.find(params[:id])
  end

  def music_selection_params
    params.expect(music_selection: [ :contest_entry_id, :title, :composer, :prescribed_music_id ])
  end

  def set_breadcrumbs
    add_breadcrumb("Contests", contests_path)
    add_breadcrumb(@contest_entry.contest.name, @contest_entry.contest)
  end
end
