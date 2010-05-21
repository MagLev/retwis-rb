# A note on unique ids vs. object ids.
#
# MagLev supports global, atomic counters that we use to generate a unique
# user and post ids.  See the MagLev RDoc for System for more details on
# the persistent shared counters. We do not use Object#object_id, as object
# ids can be recycled (e.g., a user is created, then deleted later, the
# object id for that user could be re-used on a new instance of a user).

class Timeline
  def self.page(page)
    Maglev::PERSISTENT_ROOT[:timeline][(page-1)*10, 10]
  end

  def self.add_post(post)
    Maglev::PERSISTENT_ROOT[:timeline] << post
  end
end

class Model
  def initialize(id)
    @id = id
  end

  def ==(other)
    @id.to_s == other.id.to_s
  end

  attr_reader :id
end

class User < Model
  # The shared persistent counter id for users.  See comments at top of
  # file for more info.
  USER_COUNTER = 11

  def self.add_user(user)
    # Using three collections seemed to be the simplist way to map this.
    #
    # TODO: Experiment with a single identity set, plus an index on id and
    # an index on name.  Would also then need a separate bounded queue to
    # hold the newest N users for self.new_users()
    Maglev::PERSISTENT_ROOT[:user_by_name][user.username] = user
    Maglev::PERSISTENT_ROOT[:user_by_id][user.id] = user
    Maglev::PERSISTENT_ROOT[:users] << user
    user
  end

  def self.key?(username)
    Maglev::PERSISTENT_ROOT[:user_by_name].has_key?(username)
  end

  def self.find_by_username(username)
    Maglev::PERSISTENT_ROOT[:user_by_name][username]
  end

  def self.find_by_id(id)
    Maglev::PERSISTENT_ROOT[:user_by_id][id]
  end

  def self.create(username, password)
    user_id = Maglev::System.increment_pcounter(USER_COUNTER)
    salt = User.new_salt
    self.add_user User.new(username, user_id, salt, hash_pw(salt, password))
  end

  def self.new_users
    if Maglev::PERSISTENT_ROOT[:users].size > 10
      Maglev::PERSISTENT_ROOT[:users][-10, -1]
    else
      Maglev::PERSISTENT_ROOT[:users]
    end
  end

  def self.new_salt
    arr = %w(a b c d e f)
    (0..6).to_a.map{ arr[rand(6)] }.join
  end

  def self.hash_pw(salt, password)
    Digest::MD5.hexdigest(salt + password)
  end

  attr_reader :username, :salt, :hashed_password

  def initialize(username, id, salt, hashed_password)
    super(id)
    @salt = salt
    @username = username
    @hashed_password = hashed_password
    @posts = []
    @timeline = []
    @mentions = []
    @followers = IdentitySet.new
    @followees = IdentitySet.new
  end

  def posts(page=1)
    @posts[(page-1)*10, 10]
  end

  def timeline(page=1)
    @timeline[(page-1)*10, 10]
  end

  def mentions(page=1)
    @mentions[(page-1)*10, 10]
  end

  def add_post(post)
    Timeline.add_post(post)
    @posts << post
    @timeline << post
  end

  def add_timeline_post(post)
    @timeline << post
  end

  def add_mention(post)
    @mentions << post
  end

  def follow(user)
    return if user == self
    @followees << user
    user.add_follower(self)
  end

  def stop_following(user)
    @followees.delete(user)
    user.remove_follower(self)
  end

  def following?(user)
    @followees.include? user
  end

  def followers
    @followers.to_a
  end

  def followees
    @followees.to_a
  end

  protected

  def add_follower(user)
    @followers << user
  end

  def remove_follower(user)
    @followers.delete(user)
  end

  def to_s
    "#<User: username: #{username} following #{@followees.size} followed by #{@followers.size}>"
  end
  alias :inspect :to_s
end

class Post < Model
  # The shared persistent counter id for posts.  See comments at top of
  # file for more info.
  POST_COUNTER = 10

  def self.create(user, content)
    post_id = Maglev::System.increment_pcounter(POST_COUNTER)
    post = Post.new(post_id, content, user)
    user.add_post(post)
    Timeline.add_post(post)

    post.user.followers.each do |follower|
      follower.add_timeline_post(post)
    end
    content.scan(/@\w+/).each do |mention|
      if user = User.find_by_username(mention[1..-1])
        user.add_mention(post)
      end
    end
  end

  attr_reader :content, :user, :created_at

  def initialize(id, content, user)
    super(id)
    @content = content
    @user = user
    @created_at = Time.now
  end
end
