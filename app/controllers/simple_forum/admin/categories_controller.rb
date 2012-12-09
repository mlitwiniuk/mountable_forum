module SimpleForum
  module Admin
    class CategoriesController < ::SimpleForum::Admin::BaseController
      before_filter :cleanup_params
      def index
        @categories = SimpleForum::Category.default_order.all

        respond_with(@categories)
      end

      def show

        respond_with([:admin, resource])
      end

      def edit

        respond_with([:admin, resource])
      end

      def new

        respond_with([:admin, resource])
      end

      def create
        success = resource.save

        respond_with([:admin, resource]) do |format|
          format.html do
            if success
              redirect_to [:admin, resource]
            else
              render :new
            end
          end
        end
      end

      def update
        success = resource.update_attributes(resource_params)

        respond_with([:admin, resource]) do |format|
          format.html do
            if success
              redirect_to [:admin, resource]
            else
              render :edit
            end
          end
        end
      end

      def destroy
        resource.destroy

        respond_with([:admin, resource])
      end

      private

      def resource
        @category ||= params[:id] ? SimpleForum::Category.find(params[:id]) : SimpleForum::Category.new(resource_params)
      end
      helper_method :resource

      def resource_params
        unless p = params[:category].presence
          {}
        else
          p.permit(:name, :body, :position)
        end
      end

    end
  end
end
