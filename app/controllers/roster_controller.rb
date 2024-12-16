  class RosterController < ApplicationController
    before_action :set_breadcrumbs

    def index
    end

    private

    def set_breadcrumbs
      add_breadcrumb("Roster", roster_path)
    end
  end
