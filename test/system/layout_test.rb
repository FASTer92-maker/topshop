require "application_system_test_case"

class LayoutTest < ApplicationSystemTestCase
  test "home page shows header, hero and footer" do
    visit root_path

    assert_text "Бесплатная доставка от 10 000 ₽"
    assert_link "TopShop", href: root_path
    assert_selector "h1", text: "ОДЕЖДА НА КАЖДЫЙ ДЕНЬ" # uppercase via CSS
    assert_text "НОВИНКИ"
    assert_link "Смотреть все", href: products_path
    within("footer") { assert_text "ДОКУМЕНТЫ" }
  end

  test "header stays visible after scrolling" do
    visit root_path
    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")

    header_top = page.evaluate_script("document.querySelector('header').getBoundingClientRect().top")
    assert_equal 0, header_top
  end

  test "layout fits a 390px phone screen without horizontal scroll" do
    page.driver.browser.manage.window.resize_to(390, 844)
    visit root_path

    overflow = page.evaluate_script("document.documentElement.scrollWidth - document.documentElement.clientWidth")
    assert_equal 0, overflow
  ensure
    page.driver.browser.manage.window.resize_to(1400, 1000)
  end
end
