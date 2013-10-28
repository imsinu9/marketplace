class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :token, type: String
  field :shop, type: String
  field :name, type: String
  field :contact, type: String
  field :primary_email, type: String
  field :secondary_email, type: String

  #validates_length_of :token => 16, :contact => 12
  validates_presence_of :token
  validates_uniqueness_of :token

  has_many :products, dependent: :delete

  class<<self
    def generate_token (token = SecureRandom.hex(8))
      token = SecureRandom.hex(8) while token_present?(token)
      token
    end

    def token_present? (token)
      User.where(:token => token).exists?
    end

    def get_user_with_token(token)
      User.find_by(:token => token)
    end
  end
end