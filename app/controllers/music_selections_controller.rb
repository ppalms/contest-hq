class MusicSelectionsController < ApplicationController
  before_action :set_contest_entry
  before_action :set_music_selection, only: %i[ show edit update destroy ]
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
      mark_prescribed_as_changed(existing_prescribed.id)
    else
      @music_selection = @contest_entry.music_selections.create!(prescribed_music: prescribed_music)
    end

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to bulk_edit_contest_entry_selections_path(entry_id: @contest_entry.id) }
    end
  rescue ActiveRecord::RecordInvalid => e
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("flash", partial: "shared/flash", locals: { flash: { alert: e.message } }), status: :unprocessable_entity }
      format.html { redirect_to bulk_edit_contest_entry_selections_path(entry_id: @contest_entry.id), alert: e.message }
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

  def edit
    render layout: false
  end

  def update
    respond_to do |format|
      if @music_selection.update(music_selection_params)
        format.turbo_stream { render turbo_stream: turbo_stream.replace(dom_id(@music_selection), partial: "contest_entries/music_selection_item", locals: { music_selection: @music_selection, index: @music_selection.position - 1 }) }
        format.html { redirect_to contest_entry_path(@contest_entry.contest, @contest_entry), notice: "Music selection updated." }
      else
        format.html { render :edit, status: :unprocessable_content, layout: false }
      end
    end
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
    has_restored_state = restore_edit_state_from_session

    if has_restored_state
      @slots = build_slots_from_restored_state
    else
      @slots = build_slots
    end

    @changed_prescribed_id = get_changed_prescribed_id
    render layout: false
  end

  def bulk_edit_prescribed_slot
    prescribed = @contest_entry.prescribed_selection
    @slot = { type: :prescribed, music_selection: prescribed, position: MusicSelectionRequirements::PRESCRIBED_POSITION }

    render partial: "music_selections/prescribed_slot",
           layout: false,
           locals: { slot: @slot, contest_entry: @contest_entry }
  end

  def save_edit_state
    save_edit_state_to_session
    head :ok
  end

  def bulk_update
    ActiveRecord::Base.transaction do
      if params[:music_selections].present?
        params[:music_selections].each do |ms_params|
          next if ms_params[:_destroy] == "1"

          if ms_params[:id].present?
            music_selection = @contest_entry.music_selections.unscoped.find(ms_params[:id])
            music_selection.update!(
              position: ms_params[:position],
              title: ms_params[:title],
              composer: ms_params[:composer]
            )
          else
            @contest_entry.music_selections.create!(
              position: ms_params[:position],
              title: ms_params[:title],
              composer: ms_params[:composer]
            )
          end
        end
      end

      if params[:music_selections_to_delete].present?
        params[:music_selections_to_delete].each do |id|
          music_selection = @contest_entry.music_selections.find(id)
          music_selection.destroy!
        end
      end
    end

    clear_edit_state_from_session

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

  def build_slots
    prescribed = @contest_entry.prescribed_selection
    custom_selections = @contest_entry.custom_selections

    slots = []

    # Add prescribed slot (always position 1)
    slots << {
      type: :prescribed,
      music_selection: prescribed,
      position: MusicSelectionRequirements::PRESCRIBED_POSITION
    }

    # Add custom slots (positions starting from FIRST_CUSTOM_POSITION)
    MusicSelectionRequirements::REQUIRED_CUSTOM_COUNT.times do |i|
      slots << {
        type: :custom,
        music_selection: custom_selections[i],
        position: MusicSelectionRequirements::FIRST_CUSTOM_POSITION + i
      }
    end
    slots
  end

  def save_edit_state_to_session
    return unless params[:music_selections].present? || params[:music_selections_to_delete].present?

    session[:music_edit_state] = {
      contest_entry_id: @contest_entry.id,
      music_selections: params[:music_selections]&.to_unsafe_h,
      music_selections_to_delete: params[:music_selections_to_delete],
      timestamp: Time.current.to_i,
      db_timestamps: @contest_entry.music_selections.pluck(:id, :updated_at).to_h
    }
  end

  def restore_edit_state_from_session
    return false unless session[:music_edit_state]

    state = session[:music_edit_state]

    if state[:contest_entry_id] != @contest_entry.id ||
       (Time.current.to_i - state[:timestamp]) >= 3600
      return false
    end

    if detect_conflicts(state[:db_timestamps])
      @has_conflicts = true
      @conflict_message = "The music selections have been modified by another user. Your unsaved changes are preserved, but please review carefully before saving."
    end

    @restored_music_selections = state[:music_selections]
    @restored_deletions = state[:music_selections_to_delete]
    true
  end

  def clear_edit_state_from_session
    session.delete(:music_edit_state)
    session.delete(:changed_prescribed_id)
  end

  def detect_conflicts(stored_timestamps)
    return false unless stored_timestamps

    current_timestamps = @contest_entry.music_selections.pluck(:id, :updated_at).to_h

    stored_timestamps.any? do |id, stored_time|
      current_time = current_timestamps[id]
      current_time && current_time.to_i > stored_time.to_i
    end
  end

  def mark_prescribed_as_changed(music_selection_id)
    session[:changed_prescribed_id] = music_selection_id
  end

  def get_changed_prescribed_id
    session[:changed_prescribed_id]
  end

  def build_slots_from_restored_state
    slots = []

    restored_by_position = {}
    @restored_music_selections&.each do |ms_data|
      position = ms_data[:position].to_i
      restored_by_position[position] = ms_data
    end

    (1..MusicSelectionRequirements::TOTAL_REQUIRED_COUNT).each do |position|
      restored_data = restored_by_position[position]

      if restored_data
        is_deleted = @restored_deletions&.include?(restored_data[:id])
        type = MusicSelectionRequirements.prescribed_position?(position) ? :prescribed : :custom

        slots << {
          type: type,
          position: position,
          music_selection: build_music_selection_from_data(restored_data),
          is_deleted: is_deleted,
          is_new: restored_data[:id].blank?
        }
      else
        type = MusicSelectionRequirements.prescribed_position?(position) ? :prescribed : :custom
        slots << {
          type: type,
          position: position,
          music_selection: nil
        }
      end
    end

    slots
  end

  def build_music_selection_from_data(data)
    if data[:id].present?
      ms = @contest_entry.music_selections.unscoped.find(data[:id])
      ms.assign_attributes(
        position: data[:position],
        title: data[:title],
        composer: data[:composer]
      )
      ms
    else
      @contest_entry.music_selections.new(
        position: data[:position],
        title: data[:title],
        composer: data[:composer]
      )
    end
  end
end
