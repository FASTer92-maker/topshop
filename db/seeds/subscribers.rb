# Demo newsletter subscribers. Subscriber.subscribe returns the existing
# record for a known email, so re-running the seed creates no duplicates.

%w[ anna@example.com maria@example.com demo@example.com ].each do |email|
  Subscriber.subscribe(email)
end
