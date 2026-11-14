# Loads seed files from db/seeds/. The catalogue and demo accounts are loaded
# first; demo data that depends on them (favourites, orders, subscribers) is
# loaded last. Every file is idempotent, so running this repeatedly never
# duplicates data.

demo_seeds = %w[ favorites orders subscribers ]

seed_files = Dir[Rails.root.join("db", "seeds", "*.rb")].sort
base_files, demo_files = seed_files.partition do |file|
  demo_seeds.exclude?(File.basename(file, ".rb"))
end

(base_files + demo_files).each { |file| require file }
