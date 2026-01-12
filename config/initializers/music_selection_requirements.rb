# frozen_string_literal: true

# Music selection requirements for contest entries
# These constants define the required number of prescribed and custom music pieces
# that must be submitted with each contest entry.
module MusicSelectionRequirements
  # Number of prescribed music pieces required per contest entry
  REQUIRED_PRESCRIBED_COUNT = 1

  # Number of custom music pieces required per contest entry
  REQUIRED_CUSTOM_COUNT = 2

  # Total number of music pieces required per contest entry
  TOTAL_REQUIRED_COUNT = REQUIRED_PRESCRIBED_COUNT + REQUIRED_CUSTOM_COUNT

  # Position index for the prescribed music selection (1-based)
  PRESCRIBED_POSITION = 1

  # Helper method to determine if a position is for prescribed music
  def self.prescribed_position?(position)
    position == PRESCRIBED_POSITION
  end
end
