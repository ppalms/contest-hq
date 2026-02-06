class NormalizeMusicSelectionPositions < ActiveRecord::Migration[8.1]
  def change
    # First, update any records without positions to sequential numbers
    execute <<-SQL
      UPDATE music_selections#{' '}
      SET position = (
        SELECT COALESCE(MIN(t.seq), 1)
        FROM (
          SELECT id, ROW_NUMBER() OVER (PARTITION BY contest_entry_id ORDER BY created_at) as seq
          FROM music_selections#{' '}
          WHERE contest_entry_id = music_selections.contest_entry_id AND position IS NULL
        ) t
        WHERE t.id = music_selections.id
      )
      WHERE position IS NULL
    SQL

    # Ensure prescribed music is at position 1 for each contest entry
    execute <<-SQL
      UPDATE music_selections#{' '}
      SET position = 1
      WHERE position != 1#{' '}
        AND prescribed_music_id IS NOT NULL
        AND contest_entry_id IN (
          SELECT contest_entry_id#{' '}
          FROM music_selections#{' '}
          WHERE prescribed_music_id IS NOT NULL
          GROUP BY contest_entry_id
          HAVING COUNT(*) = 1
        )
    SQL

    # Reorder custom selections to fill gaps
    execute <<-SQL
      UPDATE music_selections#{' '}
      SET position = (
        SELECT new_pos
        FROM (
          SELECT id,#{' '}
                 ROW_NUMBER() OVER (PARTITION BY contest_entry_id ORDER BY#{' '}
                   CASE WHEN prescribed_music_id IS NOT NULL THEN 1 ELSE 2 END,
                   CASE WHEN prescribed_music_id IS NULL THEN created_at END
                 ) as new_pos
          FROM music_selections
          WHERE contest_entry_id = music_selections.contest_entry_id
        ) t
        WHERE t.id = music_selections.id
      )
    SQL
  end
end
