# == Schema Information
#
# Table name: users
#
#  id               :bigint           not null, primary key
#  about            :text
#  email            :string
#  extension_token  :string
#  followers_count  :integer          default(0)
#  followings_count :integer          default(0)
#  homepage         :string
#  password_digest  :string
#  remember_token   :string
#  username         :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_users_on_email               (email) UNIQUE
#  index_users_on_email_lower_unique  (lower((email)::text)) UNIQUE
#  index_users_on_remember_token      (remember_token) UNIQUE
#
class User < ApplicationRecord
  has_secure_password
  has_one_attached :avatar
  has_many :auth_providers, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :like_bookmarks, through: :likes, source: "bookmark"
  has_many :follows, dependent: :destroy
  has_many :follow_users, through: :follows, source: "following_user"

  has_many :followers, class_name: "Follow", foreign_key: "following_user_id"
  has_many :follower_users, through: :followers, source: "user"

  validates_format_of :email, with: /\A[^@\s]+@[^@\s]+\z/
  validates :email, uniqueness: true

  before_create { generate_token(:remember_token) }
  before_create { generate_token(:extension_token) }

  def generate_token(column)
    begin
      self[column] = SecureRandom.hex(32)
    end while User.exists?(column => self[column])
  end

  attr_accessor :remember_me

  has_many :bookmarks, dependent: :destroy

  def remember_me
    true
  end

  def username
    read_attribute(:username) || email.split("@")[0]
  end

  def avatar_url
    if avatar.attached?
      avatar.variant(resize_to_limit: [150, nil])
    else
      ["https://www.gravatar.com/avatar", Digest::MD5.hexdigest(email)].join("/")
    end
  end

  def followed_by?(user)
    return unless user

    user.follows.where(following_user: self).exists?
  end

  def self.find_or_create_from_auth(auth)
    auth_provider = AuthProvider.find_or_initialize_by(provider: auth["provider"], uid: auth["uid"])
    if auth_provider.new_record?
      auth_provider.data = auth
      if user = User.where("lower(email) = ?", auth["info"]["email"].downcase).first
        auth_provider.user = user
        auth_provider.save
      else
        user = auth_provider.build_user(
          email: auth["info"]["email"],
          username: auth["info"]["nickname"],
          password: SecureRandom.hex,
          about: auth_provider.description,
          homepage: auth_provider.homepage
        )
        auth_provider.save
      end
    else
      user = auth_provider.user
    end
    user
  end
end