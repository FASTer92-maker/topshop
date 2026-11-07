require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:customer) }

  test "new" do
    get new_password_path

    assert_response :success
    assert_select "h1", "Сброс пароля"
  end

  test "create sends reset instructions" do
    post passwords_path, params: { email_address: @user.email_address }

    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "отправили на него ссылку"
  end

  test "create for an unknown user gives the same answer but sends no mail" do
    post passwords_path, params: { email_address: "missing-user@example.com" }

    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "отправили на него ссылку"
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)

    assert_response :success
    assert_select "h1", "Новый пароль"
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")

    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "недействительна или устарела"
  end

  test "update sets a new password and signs out other sessions" do
    @user.sessions.create!

    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "brand-new-1", password_confirmation: "brand-new-1" }
    end

    assert_redirected_to new_session_path
    assert_empty @user.sessions.reload

    follow_redirect!
    assert_notice "Пароль изменён"
  end

  test "update with non matching passwords re-renders the form" do
    token = @user.password_reset_token

    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(token), params: { password: "brand-new-1", password_confirmation: "something-else" }
    end

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Подтверждение пароля не совпадает/
  end

  test "update with a too short password re-renders the form" do
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "short", password_confirmation: "short" }
    end

    assert_response :unprocessable_content
    assert_select "[role=alert]", text: /Пароль слишком короткий/
  end

  private
    def assert_notice(text)
      assert_select "#flash", /#{text}/
    end
end
