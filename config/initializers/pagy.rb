# Pagy configuration for the storefront and admin lists.
# See https://ddnexus.github.io/pagy/toolbox/configuration/initializer/

Pagy::OPTIONS[:limit] = 12

Pagy::OPTIONS.freeze

# Use the standard I18n gem so that the Pagy navigation follows config.i18n.locale
# and the Russian dictionary shipped with the gem.
Pagy.translate_with_the_slower_i18n_gem!
