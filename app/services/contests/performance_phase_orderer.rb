module Contests
  class PerformancePhaseOrderer
    def self.normalize_ordinals(contest)
      new.normalize_ordinals(contest)
    end

    def normalize_ordinals(contest)
      ApplicationRecord.transaction do
        # Get all non-destroyed phases in their current order
        phases = contest.performance_phases
          .reject(&:marked_for_destruction?)
          .sort_by(&:ordinal)

        # First move all phases to negative positions to avoid conflicts
        phases.each_with_index do |phase, index|
          phase.ordinal = -(index + 1)
          phase.save!
        end

        # Then move them to their final positions
        phases.each_with_index do |phase, index|
          phase.ordinal = index + 1
          phase.save!
        end
      end
    end
  end
end
