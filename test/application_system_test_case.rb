require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  # Every system test drives its own browser, so parallel workers would start
  # one Chrome each. Keep the browser tests in a single worker even above the
  # default parallelization threshold.
  parallelize(workers: 1)

  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1000 ]
end
