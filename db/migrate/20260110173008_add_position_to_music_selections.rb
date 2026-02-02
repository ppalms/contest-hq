class AddPositionToMusicSelections < ActiveRecord::Migration[8.1]
  def change
    add_column :music_selections, :position, :integer

    reversible do |dir|
      dir.up do
        MusicSelection.reset_column_information

        MusicSelection.find_each do |ms|
          entry_selections = MusicSelection.where(contest_entry_id: ms.contest_entry_id)
          prescribed = entry_selections.where.not(prescribed_music_id: nil).order(:id).to_a
          custom = entry_selections.where(prescribed_music_id: nil).order(:id).to_a

          all_ordered = prescribed + custom
          position = all_ordered.index(ms) + 1
          ms.update_column(:position, position)
        end
      end
    end
  end
end
