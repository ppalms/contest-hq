class AddContestSeasonToContests < ActiveRecord::Migration[8.0]
  def change
    add_reference :contests, :contest_season, null: false, foreign_key: true
  end
end
