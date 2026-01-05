class AddPrescribedMusicToMusicSelections < ActiveRecord::Migration[8.1]
  def change
    add_reference :music_selections, :prescribed_music, null: true, foreign_key: true
  end
end
