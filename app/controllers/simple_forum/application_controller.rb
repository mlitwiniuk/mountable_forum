module SimpleForum
  class ApplicationController < ::ActionController::Base

    protect_from_forgery

    layout "simple_forum"

    helper_method :authenticated_user, :user_authenticated?

    private

    def authenticated_user
      instance_eval &AbstractAuth.invoke(:authenticated_user)
    end

    def user_authenticated?
      instance_eval &AbstractAuth.invoke(:user_authenticated?)
    end

    def authenticate_user
      redirect_to :back, :alert => "You have to be logged in" unless user_authenticated?
#      authenticate_user!
    end
  end

end


