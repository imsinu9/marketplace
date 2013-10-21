class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :token, type: String
  field :shop, type: String
  field :name, type: String
  field :contact, type: String
  field :primary_email, type: String
  field :secondary_email, type: String

  validates_length_of :token => 16 , :contact => 12
  validates_presence_of :token
  validates_uniqueness_of :token

  belongs_to :product
end