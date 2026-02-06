class MusicSelectionsController < ApplicationController
  before_action :set_contest_entry
  before_action :set_music_selection, only: [ :edit, :update, :destroy ]
  before_action :set_breadcrumbs

  def index
    @music_selections = @contest_entry.music_selections.order(:position)
  end

  def new
    @music_selection = @contest_entry.music_selections.build
    @selection_type = params[:type]&.to_sym || :custom
  end

  def create
    @music_selection = @contest_entry.music_selections.build(music_selection_params)

    if @music_selection.prescribed_music_id.present?
      if at_max_prescribed?
        render_error("You have already added the maximum number of prescribed music selections (#{@contest_entry.contest.required_prescribed_count})")
        return
      end
    else
      if at_max_custom?
        render_error("You have already added the maximum number of custom music selections (#{@contest_entry.contest.required_custom_count})")
        return
      end
    end

    # Always assign position as next available
    if music_selection_params[:position].blank?
      @music_selection.position = next_available_position
    end

    if @music_selection.save
      redirect_to contest_entry_path(@contest_entry.contest, @contest_entry), notice: "Music selection added successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @music_selection.prescribed? && music_selection_params[:prescribed_music_id].blank?
      flash.now[:alert] = "Cannot change prescribed music to custom music. Please delete and create a new selection."
      render :edit, status: :unprocessable_entity
      return
    end

    if @music_selection.update(music_selection_params)
      redirect_to contest_entry_path(@contest_entry.contest, @contest_entry), notice: "Music selection updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @music_selection.destroy
    redirect_to contest_entry_path(@contest_entry.contest, @contest_entry), notice: "Music selection removed."
  end

  def reorder
    positions = params[:positions] || {}

    ActiveRecord::Base.transaction do
      positions.each do |id, position|
        selection = @contest_entry.music_selections.find(id)
        selection.update!(position: position)
      end
    end

    redirect_to contest_entry_path(@contest_entry.contest, @contest_entry), notice: "Music selections reordered."
  rescue ActiveRecord::RecordInvalid => e
    redirect_to contest_entry_path(@contest_entry.contest, @contest_entry), alert: "Error reordering: #{e.message}"
  end

  def new_prescribed
    @prescribed_music = []

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
  end

  private

  def set_contest_entry
    @contest_entry = ContestEntry.find(params[:entry_id])
  end

  def set_music_selection
    @music_selection = @contest_entry.music_selections.find(params[:id])
  end

  def set_breadcrumbs
    add_breadcrumb("Contests", contests_path)
    add_breadcrumb(@contest_entry.contest.name, @contest_entry.contest)
    add_breadcrumb("Entry", contest_entry_path(@contest_entry.contest, @contest_entry))
  end

  def music_selection_params
    params.require(:music_selection).permit(:title, :composer, :prescribed_music_id, :position)
  end

  def next_available_position
    # Find the first available position (fills gaps first)
    existing_positions = MusicSelection.where(contest_entry_id: @contest_entry.id).pluck(:position)
    max_allowed = @contest_entry.contest.total_required_music_count

    (1..max_allowed).each do |position|
      return position unless existing_positions.include?(position)
    end

    # If all positions are filled, this shouldn't happen due to max checks
    # but return 1 as a fallback
    1
  end

  def at_max_prescribed?
    current_count = @contest_entry.music_selections.reload.count(&:prescribed?)
    current_count >= @contest_entry.contest.required_prescribed_count
  end

  def at_max_custom?
    current_count = @contest_entry.music_selections.reload.count(&:custom?)
    current_count >= @contest_entry.contest.required_custom_count
  end

  def render_error(message)
    @music_selection.errors.add(:base, message)
    respond_to do |format|
      format.html { render :new, status: :unprocessable_entity }
      format.json { render json: { error: message }, status: :unprocessable_entity }
    end
  end
end
