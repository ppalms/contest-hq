module Schedules
  class PerformanceStepOrderer
    def self.reorder_steps(step_ids_in_new_order, sequence_id)
      new.reorder_steps(step_ids_in_new_order, sequence_id)
    end

    def reorder_steps(step_ids_in_new_order, sequence_id)
      ApplicationRecord.transaction do
        sequence = PerformanceSequence.find(sequence_id)
        steps = sequence.performance_steps.where(id: step_ids_in_new_order).to_a

        # Validate all steps exist and belong to the sequence
        raise ActiveRecord::RecordNotFound unless steps.length == step_ids_in_new_order.length

        # Create a hash of new ordinals
        updates = {}
        step_ids_in_new_order.each_with_index do |id, index|
          updates[id] = { ordinal: index + 1 }
        end

        # Update using nested attributes
        sequence.update!(
          performance_steps_attributes: updates.map do |id, attrs|
            attrs.merge(id: id)
          end
        )
      end
    end

    def self.move_step(step_id, direction)
      new.move_step(step_id, direction)
    end

    def move_step(step_id, direction)
      ApplicationRecord.transaction do
        step = PerformanceStep.find(step_id)
        sequence = step.performance_sequence
        steps = sequence.performance_steps.in_order.to_a
        current_index = steps.index(step)

        case direction.to_sym
        when :up
          return if current_index == 0
          other_step = steps[current_index - 1]
        when :down
          return if current_index == steps.length - 1
          other_step = steps[current_index + 1]
        else
          return
        end

        # Swap ordinals using nested attributes
        sequence.update!(
          performance_steps_attributes: [
            { id: step.id, ordinal: other_step.ordinal },
            { id: other_step.id, ordinal: step.ordinal }
          ]
        )
      end
    end

    def self.normalize_ordinals(sequence)
      new.normalize_ordinals(sequence)
    end

    def normalize_ordinals(sequence)
      ApplicationRecord.transaction do
        # Get all non-destroyed steps in their current order
        steps = sequence.performance_steps
          .reject(&:marked_for_destruction?)
          .sort_by(&:ordinal)

        # First move all steps to negative positions to avoid conflicts
        steps.each_with_index do |step, index|
          step.ordinal = -(index + 1)
          step.save!
        end

        # Then move them to their final positions
        steps.each_with_index do |step, index|
          step.ordinal = index + 1
          step.save!
        end
      end
    end
  end
end
