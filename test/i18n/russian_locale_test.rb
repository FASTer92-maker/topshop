require "test_helper"

class RussianLocaleTest < ActiveSupport::TestCase
  include ActionView::Helpers::NumberHelper

  NBSP = " "

  test "Russian is the default and only available locale" do
    assert_equal :ru, I18n.default_locale
    assert_equal [ :ru ], I18n.available_locales
  end

  test "formats prices in rubles with non-breaking spaces" do
    assert_equal "1#{NBSP}990#{NBSP}₽", number_to_currency(1990)
    assert_equal "12#{NBSP}500#{NBSP}₽", number_to_currency(BigDecimal("12500.00"))
    assert_equal "349#{NBSP}₽", number_to_currency(349)
  end

  test "uses Russian plural forms" do
    length = ->(count) { I18n.t("errors.messages.wrong_length", count: count) }

    assert_equal "неверной длины (должно быть 1 символ)", length.call(1)
    assert_equal "неверной длины (должно быть 3 символа)", length.call(3)
    assert_equal "неверной длины (должно быть 5 символов)", length.call(5)
    assert_equal "неверной длины (должно быть 11 символов)", length.call(11)
    assert_equal "неверной длины (должно быть 21 символ)", length.call(21)
    assert_equal "неверной длины (должно быть 22 символа)", length.call(22)
    assert_equal "неверной длины (должно быть 112 символов)", length.call(112)
  end

  test "transliterates Cyrillic for slugs" do
    assert_equal "dom-i-sad", "Дом и сад".parameterize
    assert_equal "kurtka-steganaya", "Куртка стёганая".parameterize
    assert_equal "shchetka-i-yubka", "Щётка и юбка".parameterize
    assert_equal "nyanya-y", "Ньяня Й".parameterize
  end

  test "translates validation messages" do
    assert_equal "не может быть пустым", I18n.t("errors.messages.blank")
    assert_equal "слишком короткое (не менее 8 символов)", I18n.t("errors.messages.too_short", count: 8)
  end

  test "formats dates in Russian" do
    date = Date.new(2026, 11, 8)

    assert_equal "08.11.2026", I18n.l(date)
    assert_equal "8 ноября 2026", I18n.l(date, format: :long)
  end
end
