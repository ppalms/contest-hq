class DesignSystemController < ApplicationController
  skip_before_action :authenticate
  skip_before_action :set_selected_account

  def buttons
    # Test page for button design system
  end
end
