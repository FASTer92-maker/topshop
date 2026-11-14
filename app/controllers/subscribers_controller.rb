class SubscribersController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 1.minute, only: :create,
             with: -> { redirect_to root_path, alert: t("subscribers.create.rate_limited") }

  def create
    @subscriber = Subscriber.subscribe(subscriber_params[:email])

    if @subscriber.persisted?
      respond_with_success
    else
      respond_with_error
    end
  end

  private
    def subscriber_params
      params.expect(subscriber: [ :email ])
    end

    def turbo_frame_request?
      request.headers["Turbo-Frame"].present?
    end

    def respond_with_success
      if turbo_frame_request?
        render :create, layout: false
      else
        redirect_back fallback_location: root_path, notice: t("newsletter.success")
      end
    end

    def respond_with_error
      message = @subscriber.errors.full_messages.to_sentence

      if turbo_frame_request?
        render :create, status: :unprocessable_content, layout: false
      else
        redirect_back fallback_location: root_path, alert: message
      end
    end
end
