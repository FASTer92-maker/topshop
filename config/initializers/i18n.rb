# Enables locale-specific plural rules (Russian needs one/few/many/other).
# The rule itself lives in config/locales/plurals.rb.
require "i18n/backend/pluralization"

I18n::Backend::Simple.include(I18n::Backend::Pluralization)
