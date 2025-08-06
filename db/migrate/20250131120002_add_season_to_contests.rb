class AddSeasonToContests < ActiveRecord::Migration[8.0]
  def up
    # Add the season_id column without making it required yet
    add_reference :contests, :season, null: true, foreign_key: true

    # Create default seasons and assign contests
    Account.find_each do |account|
      # Get years from existing contests in this account
      contest_years = Contest.where(account: account)
                           .where.not(contest_start: nil)
                           .distinct
                           .pluck(Arel.sql("EXTRACT(YEAR FROM contest_start)::integer"))
                           .sort

      # If no contests have dates, create a current year season
      contest_years = [ Date.current.year ] if contest_years.empty?

      # Create seasons for each year and assign contests
      contest_years.each do |year|
        season = Season.create!(
          name: year.to_s,
          account: account,
          archived: year < Date.current.year
        )

        # Assign contests from this year to this season
        Contest.where(account: account)
               .where(Arel.sql("EXTRACT(YEAR FROM contest_start) = ?", year))
               .update_all(season_id: season.id)
      end

      # Assign any contests without dates to the most recent season
      recent_season = Season.where(account: account).order(:name).last
      if recent_season
        Contest.where(account: account, season_id: nil)
               .update_all(season_id: recent_season.id)
      end
    end

    # Now make season_id required
    change_column_null :contests, :season_id, false
  end

  def down
    remove_index :contests, :season_id
    remove_reference :contests, :season, foreign_key: true
  end
end
