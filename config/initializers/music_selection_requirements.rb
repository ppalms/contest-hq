# frozen_string_literal: true

# Music selection requirements for contest entries.
#
# This module centralizes all business rules for music selection requirements,
# making it easy to modify the required number of prescribed and custom pieces
# from a single location.
#
# @example Checking if music is complete
#   entry.music_complete? # Uses REQUIRED_CUSTOM_COUNT internally
#
# @example Building slots for UI
#   (1..MusicSelectionRequirements::TOTAL_REQUIRED_COUNT).each do |position|
#     # Create slot
#   end
#
# @see ContestEntry#music_complete?
# @see MusicSelectionsController#build_slots
module MusicSelectionRequirements
  # Number of prescribed music pieces required per contest entry
  REQUIRED_PRESCRIBED_COUNT = 1

  # Number of custom music pieces required per contest entry
  REQUIRED_CUSTOM_COUNT = 2

  # Total number of music pieces required per contest entry
  TOTAL_REQUIRED_COUNT = REQUIRED_PRESCRIBED_COUNT + REQUIRED_CUSTOM_COUNT

  # Position index for the prescribed music selection (1-based)
  PRESCRIBED_POSITION = 1

  # Position index for the first custom music selection (1-based)
  FIRST_CUSTOM_POSITION = PRESCRIBED_POSITION + 1

  # Determines if a given position is for prescribed music
  # @param position [Integer] 1-based position to check
  # @return [Boolean] true if position is for prescribed music
  def self.prescribed_position?(position)
    position == PRESCRIBED_POSITION
  end
end
