# Demo accounts. Both use the password "password123".
# The admin account is promoted to admin even if it already exists.

admin = User.find_or_create_by!(email_address: "admin@example.com") do |user|
  user.first_name = "Админ"
  user.last_name = "Топшоп"
  user.password = "password123"
  user.password_confirmation = "password123"
end
admin.update!(role: :admin) unless admin.admin?

User.find_or_create_by!(email_address: "customer@example.com") do |user|
  user.first_name = "Покупатель"
  user.last_name = "Тестовый"
  user.password = "password123"
  user.password_confirmation = "password123"
end
