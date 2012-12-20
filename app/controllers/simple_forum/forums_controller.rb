module SimpleForum
  class ForumsController < ::SimpleForum::ApplicationController

    before_filter :find_forum, :except => [:index, :search]

    def index
      @categories = SimpleForum::Category.default_order.includes({:forums => [{:recent_post => [:user, :topic]}, :moderators]})

      respond_to :html
    end

    def show
      bang_simple_forum_recent_activity(@forum)

      scope = @forum.topics.includes([:user, {:recent_post => :user}])
      @topics = scope.respond_to?(:paginate) ? scope.paginate(:page => params[:page], :per_page => params[:per_page]) : scope.all

      respond_to :html
    end

    def search
      q = "%#{params[:q]}%"
      @posts_search = Post.visible.includes([:topic]).where("#{SimpleForum::Topic.quoted_table_name}.title like ? OR #{SimpleForum::Post.quoted_table_name}.body like ?", q, q)
      @posts = @posts_search.respond_to?(:paginate) ?
          @posts_search.paginate(:page => params[:page], :per_page => params[:per_page] || SimpleForum::Post.per_page) :
          @posts_search.all

    end

    private

    def find_forum
      @forum = SimpleForum::Forum.find params[:id]
    end

  end
end
