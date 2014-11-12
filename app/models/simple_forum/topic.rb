module SimpleForum
  class Topic < ::ActiveRecord::Base
    belongs_to :user, class_name: instance_eval(&::SimpleForum.invoke(:user_class)).name

    belongs_to :forum,
               class_name: '::SimpleForum::Forum',
               counter_cache: true

    has_many :posts,
             -> { ::SimpleForum.show_deleted_posts ? where('1=1') : where("#{::SimpleForum::Post.quoted_table_name}.deleted_at IS NULL") },
             class_name: '::SimpleForum::Post',
             dependent: :delete_all

    belongs_to :recent_post,
               class_name: '::SimpleForum::Post'

    scope :recent, -> { "#{::SimpleForum::Topc.quoted_table_name}.created_at DESC" }

    validates :title, :forum, presence: true
    validates :user, presence: true, on: :create
    validates :body, presence: true, on: :create
    validate :forum_must_be_topicable, on: :create

    def forum_must_be_topicable
      errors.add(:base, t('simple_forum.validations.forum_must_be_topicable')) if forum && !forum.is_topicable?
    end

    before_destroy :decrement_posts_counter_cache_for_forum

    before_validation :set_default_attributes, on: :create
    after_create :create_initial_post
    after_create :notify_user

    attr_accessor :body
    #attr_accessible :title, :body

    def last_post
      posts.recent.first
    end
    def update_cached_post_fields(post)
      if remaining_post = post.frozen? ? last_post : post
        self.class.where(id: id).
                    update_all(last_updated_at: remaining_post.created_at,
                               recent_post_id: remaining_post.id,
                               posts_count: posts.count(:id))
        forum.class.where(id: forum.id).
                    update_all(recent_post_id: remaining_post.id,
                               posts_count: forum.posts.count(:id))
      else
        destroy
      end
    end

    def paged?
      posts.size > SimpleForum::Post.per_page
    end

    def last_page
      @last_page ||= [(posts.size.to_f / SimpleForum::Post.per_page).ceil.to_i, 1].max
    end

      #return array with page numbers
      # topic.page_numbers => [1, 2, 3, 4] #when pages count is 4
      # topic.page_numbers => [1, 2, 3, 4, 5] #when pages count is 5
      # topic.page_numbers => [1, nil, 3, 4, 5, 6] #when pages count is 6
      # topic.page_numbers => [1, nil, 4, 5, 6, 7] #when pages count is 7
    def page_numbers(max=5)
      if last_page > max
        [1] + [nil] + ((last_page-max+2)..last_page).to_a
      else
        (1..last_page).to_a
      end
    end

    if respond_to?(:has_friendly_id)
      has_friendly_id :title, :use_slug => true, :approximate_ascii => true
    else
      def to_param
        "#{id}-#{title.to_s.parameterize}"
      end
    end

    def author?(u)
      user == u
    end

    def is_open
      !is_closed?
    end

    alias_method :is_open?, :is_open

    def open!
      update_attribute(:is_closed, false)
    end

    def close!
      update_attribute(:is_closed, true)
    end

    def increment_views_count
      self.class.increment_counter(:views_count, self)
    end

    private

    def decrement_posts_counter_cache_for_forum
      forum.class.update_counters(forum.id, :posts_count => (-1) * posts.size) if forum
    end

    def set_default_attributes
      self.last_updated_at ||= Time.now
    end

    def create_initial_post
      p = self.posts.new(:body => @body) do |post|
        post.user = user
      end
      p.save!
      @body = nil
    end

    def notify_user
      if user && user.respond_to?(:topic_created)
        user.topic_created(self)
      end
    end
  end
end
