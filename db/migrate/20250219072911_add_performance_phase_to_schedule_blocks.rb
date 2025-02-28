class AddPerformancePhaseToScheduleBlocks < ActiveRecord::Migration[8.0]
  def change
    add_reference :schedule_blocks, :performance_phase, null: true, foreign_key: true
  end
end
