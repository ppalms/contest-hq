class MusicSelection < ApplicationRecord
  include AccountScoped

  belongs_to :contest_entry
  belongs_to :prescribed_music, optional: true

  validates :title, presence: true
  validates :composer, presence: true
  validate :prescribed_music_matches_contest, if: :prescribed_music_id?

  default_scope { order(position: :asc) }

  before_validation :populate_from_prescribed_music, if: :prescribed_music_id_changed?
  before_create :set_default_position

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

    max_position = contest_entry.music_selections.unscoped.maximum(:position) || 0
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
end
