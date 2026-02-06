class MusicSelection < ApplicationRecord
  include AccountScoped

  belongs_to :contest_entry
  belongs_to :prescribed_music, optional: true

  validates :title, presence: true
  validates :composer, presence: true
  validates :position, uniqueness: { scope: :contest_entry_id }
  validate :prescribed_music_matches_contest, if: :prescribed_music_id?
  validate :position_within_allowed_range

  default_scope { order(position: :asc) }

  before_validation :populate_from_prescribed_music, if: :prescribed_music_id_changed?

  def prescribed?
    prescribed_music_id.present?
  end

  def custom?
    !prescribed?
  end

  private

  def populate_from_prescribed_music
    return unless prescribed_music

    self.title = prescribed_music.title
    self.composer = prescribed_music.composer
  end

  def set_default_position
    return if position.present?

    max_position = MusicSelection.unscoped.where(contest_entry_id: contest_entry.id).maximum(:position) || 0
    self.position = max_position + 1
  end

  def prescribed_music_matches_contest
    return unless prescribed_music && contest_entry

    contest = contest_entry.contest
    school_class = contest_entry.large_ensemble&.school&.school_class

    if contest && prescribed_music.season_id != contest.season_id
      errors.add(:prescribed_music, "must be from the #{contest.season.name} season")
    end

    if school_class && prescribed_music.school_class_id != school_class.id
      errors.add(:prescribed_music, "must be for #{school_class.name} schools")
    end
  end

  def position_within_allowed_range
    return unless contest_entry && position

    contest = contest_entry.contest
    return unless contest

    max_position = contest.total_required_music_count
    if position < 1 || position > max_position
      errors.add(:position, "must be between 1 and #{max_position}")
    end
  end
end
