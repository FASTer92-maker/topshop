require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset email is in Russian and contains the reset link" do
    user = users(:customer)
    email = PasswordsMailer.reset(user)

    assert_equal "Сброс пароля в TopShop", email.subject
    assert_equal [ user.email_address ], email.to

    text = email.text_part.body.to_s
    assert_includes text, "Здравствуйте, Иван!"
    assert_includes text, "/passwords/"
    assert_includes text, "Ссылка действует 15 минут."
  end
end
