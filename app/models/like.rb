# == Schema Information
#
# Table name: likes
#
#  id          :bigint           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  bookmark_id :bigint
#  user_id     :bigint
#
# Indexes
#
#  index_likes_on_bookmark_id              (bookmark_id)
#  index_likes_on_user_id                  (user_id)
#  index_likes_on_user_id_and_bookmark_id  (user_id,bookmark_id) UNIQUE
#
class Like < ApplicationRecord
  belongs_to :user
  belongs_to :bookmark, counter_cache: true

  after_create :sync_cached_like_user_ids
  after_destroy :sync_cached_like_user_ids
  after_destroy :decr_stats
  after_create :incr_stats

  def sync_cached_like_user_ids
    bookmark.update(cached_like_user_ids: bookmark.reload.like_user_ids)
  end

  def incr_stats
    BookmarkStat.incr_likes_count(bookmark_id)
  end

  def decr_stats
    BookmarkStat.decr_likes_count(bookmark_id)
  end
end