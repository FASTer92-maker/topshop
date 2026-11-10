module Admin
  class BaseController < ApplicationController
    layout "admin"

    before_action :require_admin

    private
      def require_admin
        return if Current.user&.admin?

        redirect_to root_path, alert: t("admin.base.denied")
      end
  end
end
