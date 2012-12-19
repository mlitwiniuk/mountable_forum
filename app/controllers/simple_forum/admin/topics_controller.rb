module SimpleForum
  module Admin
    class TopicsController < ::SimpleForum::Admin::BaseController
      def destroy
        resource.destroy

        redirect_to :back
      end


      def resource
        @forum ||= SimpleForum::Forum.find(params[:forum_id])
        @topic ||= params[:id] ? @forum.topics.find(params[:id]) : @forum.topics.new(resource_params)
      end
      helper_method :resource

    end
  end
end
