require "test_helper"

class SubscribersControllerTest < ActionDispatch::IntegrationTest
  test "guest subscribes from the newsletter frame" do
    assert_difference -> { Subscriber.count }, 1 do
      post subscribers_path,
           params: { subscriber: { email: " New@Example.com " } },
           headers: { "Turbo-Frame" => "newsletter" }
    end

    assert_response :success
    assert_select "turbo-frame#newsletter" do
      assert_select "p[role=status]", text: "Спасибо! Подписка оформлена."
    end
    assert_equal "new@example.com", Subscriber.last.email
  end

  test "a duplicate subscription shows the same message and creates no duplicate" do
    assert_no_difference -> { Subscriber.count } do
      post subscribers_path,
           params: { subscriber: { email: " READER@Example.com " } },
           headers: { "Turbo-Frame" => "newsletter" }
    end

    assert_response :success
    assert_select "turbo-frame#newsletter" do
      assert_select "p[role=status]", text: "Спасибо! Подписка оформлена."
    end
  end

  test "an invalid email is rejected inside the frame" do
    assert_no_difference -> { Subscriber.count } do
      post subscribers_path,
           params: { subscriber: { email: "not-an-email" } },
           headers: { "Turbo-Frame" => "newsletter" }
    end

    assert_response :unprocessable_content
    assert_select "turbo-frame#newsletter" do
      assert_select "[role=alert]", text: /имеет неверное значение/
      assert_select "input[name='subscriber[email]']"
    end
  end

  test "html fallback redirects with a notice on success" do
    assert_difference -> { Subscriber.count }, 1 do
      post subscribers_path, params: { subscriber: { email: "new@example.com" } }
    end

    assert_redirected_to root_path
    assert_equal "Спасибо! Подписка оформлена.", flash[:notice]
  end

  test "html fallback redirects with an alert on an invalid email" do
    assert_no_difference -> { Subscriber.count } do
      post subscribers_path, params: { subscriber: { email: "broken" } }
    end

    assert_redirected_to root_path
    assert_match "имеет неверное значение", flash[:alert]
  end
end
