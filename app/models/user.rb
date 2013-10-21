class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :token, type: String, default: generate_token
  field :shop, type: String
  field :name, type: String
  field :contact, type: String
  field :primary_email, type: String
  field :secondary_email, type: String

  validates_length_of :token => 16, :contact => 12
  validates_presence_of :token
  validates_uniqueness_of :token

  belongs_to :product

  class<<self
    def generate_token (token = SecureRandom.hex(8))
      token = SecureRandom.hex(8) while token_present?(token)
      token
    end

  end

  def token_present? (token)
    User.find(:token => token).exists?
  end
end