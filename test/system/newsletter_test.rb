require "application_system_test_case"

class NewsletterTest < ApplicationSystemTestCase
  test "guest subscribes from the block above the footer" do
    visit root_path

    assert_text(/новости и акции/i)

    within("#newsletter") do
      fill_in "Почта для рассылки", with: " New@Example.com "
      click_on "Подписаться"

      assert_text "Спасибо! Подписка оформлена."
    end

    assert_equal 1, Subscriber.where(email: "new@example.com").count
  end

  test "a repeated subscription shows the same message without a duplicate or reload" do
    Subscriber.create!(email: "repeat@example.com")

    visit root_path
    page.execute_script("window.__newsletterMarker = true")

    within("#newsletter") do
      fill_in "Почта для рассылки", with: "REPEAT@example.com"
      click_on "Подписаться"

      assert_text "Спасибо! Подписка оформлена."
    end

    assert_equal 1, Subscriber.where(email: "repeat@example.com").count
    assert_equal true, page.evaluate_script("window.__newsletterMarker")
  end

  test "an invalid email shows an error inside the block" do
    visit root_path

    within("#newsletter") do
      fill_in "Почта для рассылки", with: "not-an-email"
      click_on "Подписаться"

      assert_text(/имеет неверное значение/)
      assert_selector "input[name='subscriber[email]']"
    end

    assert_equal 0, Subscriber.where(email: "not-an-email").count
  end
end
