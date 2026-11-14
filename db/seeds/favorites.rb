# Demo favourites for the customer account. find_or_create_by! keeps the seed
# idempotent: re-running it does not duplicate rows.

customer = User.find_by!(email_address: "customer@example.com")

Product.where(active: true).order(:id).limit(6).each do |product|
  customer.favorites.find_or_create_by!(product: product)
end
