module SimpleForum
  class Forum < ::ActiveRecord::Base
    has_many :topics,
             dependent: :destroy,
             class_name: '::SimpleForum::Topic'

    has_many :posts,
             -> { ::SimpleForum.show_deleted_posts ? where('1=1') : where("#{::SimpleForum::Post.quoted_table_name}.deleted_at IS NULL") },
             class_name: '::SimpleForum::Post',
             dependent: :delete_all

    belongs_to :recent_topic,
               class_name: '::SimpleForum::Topic'

    belongs_to :recent_post,
               class_name: '::SimpleForum::Post'

    belongs_to :category,
               class_name: '::SimpleForum::Category'

    has_many :moderatorships,
             class_name: '::SimpleForum::Moderatorship'

    has_many :moderators,
             through: :moderatorships,
             source: :user

    scope :default_order, -> { order("#{quoted_table_name}.position ASC, #{quoted_table_name}.id ASC") }

    validates :name, presence: true
    validates :position, presence: true, numericality: {only_integer: true, allow_nil: true}

    if respond_to?(:has_friendly_id)
      has_friendly_id :name, use_slug: true, approximate_ascii: true
    else
      def to_param
        "#{id}-#{name.to_s.parameterize}"
      end
    end

    def moderated_by?(user)
      return false unless user
      @moderated_by_cache ||= {}
      if @moderated_by_cache.has_key?(user.id)
        @moderated_by_cache[user.id]
      else
        @moderated_by_cache[user.id] = moderators.include?(user)
      end
    end
    alias_method :is_moderator?, :moderated_by?

  end
end
