class OrganizationsController < ApplicationController
  def index
    @organizations = Organization.includes(:organization_type).all.order(:name)
  end
end
