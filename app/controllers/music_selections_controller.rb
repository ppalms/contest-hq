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

  def create
    @music_selection = MusicSelection.new(music_selection_params)

    respond_to do |format|
      if @music_selection.save
        format.html { redirect_to contest_entry_path(id: @contest_entry.id), notice: "Music selection added to contest entry." }
        format.json { render :show, status: :created, music_selection: @music_selection }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @music_selection.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
  end

  def destroy
    @music_selection.destroy!

    respond_to do |format|
      format.html { redirect_to @contest_entry, notice: "Music selection removed from contest entry." }
      format.json { head :no_content }
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
    params.expect(music_selection: [ :contest_entry_id, :title, :composer ])
  end

  def set_breadcrumbs
    add_breadcrumb("Contests", contests_path)
    add_breadcrumb(@contest_entry.contest.name, @contest_entry.contest)
  end
end
