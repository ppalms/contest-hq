# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

Account.find_or_create_by!(name: "Contest HQ")

roles = [
  { name: 'SysAdmin' },
  { name: 'TenantAdmin' },
  { name: 'Director' },
  { name: 'Scheduler' },
  { name: 'Judge' }
]

roles.each do |role|
  Role.find_or_create_by!(role)
end

default_role = Role.find_by(name: 'Director')

User.find_each do |user|
  user.roles << default_role if user.roles.empty?
end
