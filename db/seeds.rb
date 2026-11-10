# Loads seed files from db/seeds/ in alphabetical order.
# Every file is idempotent, so running this repeatedly never duplicates data.
Dir[Rails.root.join("db", "seeds", "*.rb")].sort.each { |file| require file }
