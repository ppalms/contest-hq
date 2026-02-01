# frozen_string_literal: true

# Music selection requirements for contest entries.
#
# This module centralizes all business rules for music selection requirements,
# making it easy to modify the required number of prescribed and custom pieces
# from a single location.
#
# The module uses a data-driven approach to determine slot types, allowing
# prescribed music to be positioned anywhere and supporting future configurability
# where admins can adjust the required counts.
#
# @example Checking if music is complete
#   entry.music_complete? # Uses REQUIRED_CUSTOM_COUNT internally
#
# @example Building slots for UI
#   (1..MusicSelectionRequirements::TOTAL_REQUIRED_COUNT).each do |position|
#     type = MusicSelectionRequirements.slot_type_for(position, existing_selections)
#     # Create slot based on type
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

  # Position index for the first custom music selection (1-based)
  # Note: Prescribed music can be at any position
  FIRST_CUSTOM_POSITION = 2

  # Determines the slot type based on actual data, not position.
  # This allows prescribed music to be reordered to any position and supports
  # future configurability where multiple prescribed selections may be required.
  #
  # For empty slots, only the FIRST empty slot will be marked as prescribed
  # if we still need prescribed music. This prevents all empty slots from
  # showing as prescribed.
  #
  # @param position [Integer] 1-based position to check
  # @param existing_selections [Array<MusicSelection>] Current selections
  # @return [Symbol] :prescribed or :custom
  def self.slot_type_for(position, existing_selections)
    # Check if there's already a selection at this position
    selection = existing_selections.find { |s| s.position == position }

    if selection
      # Type is determined by the data
      selection.prescribed? ? :prescribed : :custom
    else
      # Empty slot: determine if we need prescribed or custom
      prescribed_count = existing_selections.count(&:prescribed?)

      if prescribed_count < REQUIRED_PRESCRIBED_COUNT
        # We need prescribed music - but only mark the FIRST empty slot as prescribed
        # Find all positions that are filled
        filled_positions = existing_selections.map(&:position)
        # Find the first empty position
        first_empty_position = (1..TOTAL_REQUIRED_COUNT).find { |pos| !filled_positions.include?(pos) }

        # Only this position should be prescribed
        position == first_empty_position ? :prescribed : :custom
      else
        :custom
      end
    end
  end

  # Checks if more prescribed selections are needed
  # @param existing_selections [Array<MusicSelection>] Current selections
  # @return [Boolean]
  def self.needs_prescribed?(existing_selections)
    existing_selections.count(&:prescribed?) < REQUIRED_PRESCRIBED_COUNT
  end

  # Checks if more custom selections are needed
  # @param existing_selections [Array<MusicSelection>] Current selections
  # @return [Boolean]
  def self.needs_custom?(existing_selections)
    existing_selections.count(&:custom?) < REQUIRED_CUSTOM_COUNT
  end
end
