class MusicSelection < ApplicationRecord
  include AccountScoped

  belongs_to :contest_entry
  belongs_to :prescribed_music, optional: true

  validates :title, presence: true
  validates :composer, presence: true

  before_validation :populate_from_prescribed_music, if: :prescribed_music_id_changed?

  def prescribed?
    prescribed_music_id.present?
  end

  private

  def populate_from_prescribed_music
    return unless prescribed_music

    self.title = prescribed_music.title
    self.composer = prescribed_music.composer
  end
end
