class MusicSelection < ApplicationRecord
  include AccountScoped

  belongs_to :contest_entry
  belongs_to :prescribed_music, optional: true

  validates :title, presence: true
  validates :composer, presence: true

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
end
