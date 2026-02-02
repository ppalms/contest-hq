class AddPositionToMusicSelections < ActiveRecord::Migration[8.1]
  def change
    add_column :music_selections, :position, :integer

    reversible do |dir|
      dir.up do
        MusicSelection.reset_column_information

        # Process by contest_entry_id to avoid redundant queries
        processed_entries = Set.new
        
        MusicSelection.find_each do |ms|
          next if processed_entries.include?(ms.contest_entry_id)
          
          # Get all selections for this entry in one query
          entry_selections = MusicSelection.where(contest_entry_id: ms.contest_entry_id).order(:id).to_a
          
          # Separate prescribed and custom, maintaining order
          prescribed = entry_selections.select { |s| s.prescribed_music_id.present? }
          custom = entry_selections.select { |s| s.prescribed_music_id.nil? }
          
          # Assign positions: prescribed first, then custom
          all_ordered = prescribed + custom
          all_ordered.each_with_index do |selection, index|
            selection.update_column(:position, index + 1)
          end
          
          processed_entries.add(ms.contest_entry_id)
        end
      end
    end
  end
end
