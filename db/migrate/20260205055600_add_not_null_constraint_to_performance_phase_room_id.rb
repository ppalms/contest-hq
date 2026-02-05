class AddNotNullConstraintToPerformancePhaseRoomId < ActiveRecord::Migration[8.1]
  def change
    change_column_null :performance_phases, :room_id, false
  end
end
