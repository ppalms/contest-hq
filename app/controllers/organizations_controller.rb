  class OrganizationsController < ApplicationController
    before_action :set_breadcrumbs

    def index
    end

    private

    def set_breadcrumbs
      add_breadcrumb("Organizations", organizations_path)
    end
  end
