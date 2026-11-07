class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  before_action :redirect_if_authenticated
  rate_limit to: 10, within: 3.minutes, only: :create,
             with: -> { redirect_to new_registration_path, alert: t("registrations.create.rate_limited") }

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    if @user.save
      start_new_session_for @user
      redirect_to root_path, notice: t(".success", name: @user.first_name)
    else
      render :new, status: :unprocessable_content
    end
  end

  private
    # The role is never accepted from the form: new users are always customers.
    def registration_params
      params.expect(user: [ :email_address, :first_name, :last_name, :password, :password_confirmation ])
    end

    def redirect_if_authenticated
      redirect_to root_path if authenticated?
    end
end
