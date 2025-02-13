module Contests
  class PerformancePhaseOrderer
    def self.reorder_phases(phase_ids_in_new_order, contest_id)
      new.reorder_phases(phase_ids_in_new_order, contest_id)
    end

    def reorder_phases(phase_ids_in_new_order, contest_id)
      ApplicationRecord.transaction do
        contest = PerformancePhase.find(contest_id)
        phases = contest.performance_phases.where(id: phase_ids_in_new_order).to_a

        # Validate all phases exist and belong to the contest
        raise ActiveRecord::RecordNotFound unless phases.length == phase_ids_in_new_order.length

        # Create a hash of new ordinals
        updates = {}
        phase_ids_in_new_order.each_with_index do |id, index|
          updates[id] = { ordinal: index + 1 }
        end

        # Update using nested attributes
        contest.update!(
          performance_phases_attributes: updates.map do |id, attrs|
            attrs.merge(id: id)
          end
        )
      end
    end

    def self.move_phase(phase_id, direction)
      new.move_phase(phase_id, direction)
    end

    def move_phase(phase_id, direction)
      ApplicationRecord.transaction do
        phase = PerformancePhase.include(:contest).find(phase_id)
        phases = phase.contest.performance_phases.in_order.to_a
        current_index = phases.index(phase)

        case direction.to_sym
        when :up
          return if current_index == 0
          other_phase = phases[current_index - 1]
        when :down
          return if current_index == phases.length - 1
          other_phase = phases[current_index + 1]
        else
          return
        end

        # Swap moved phase with other phase
        contest.update!(
          performance_phases_attributes: [
            { id: phase.id, ordinal: other_phase.ordinal },
            { id: other_phase.id, ordinal: phase.ordinal }
          ]
        )
      end
    end

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
