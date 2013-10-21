class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::TaggableWithContext

  field :title, type: String
  field :description, type: String
  field :keyword, type: Array, :default => []
  field :permalink, type: String
  field :stock, type: Integer

  field :price, type: Float
  field :discount, type: Float
  field :tax_inclusive, type: Boolean, default: true
  field :shipment_charge, type: Float
  field :cash_on_delievery, type: Boolean, default: false

  field :offer, type: Boolean, default: false
  field :offer_description, type: String

  field :views, type: Integer, default: 0
  field :buys, type: Integer, default: 0
  field :rating, type: Float, default: 0.0

  field :display_image, type: String
  field :screenshots, type: Array, default: []

  field :tags, type: Array, default: []
  taggable :categories, separator: ','

  validates_uniqueness_of :title , :display_image
  validates_presence_of :title, :user_id, :stock, :price, :display_image

  has_one :user, dependent: :delete

  def product_url
    "#{Marketplace::BASE_URL}/#{Marketplace::API::routes[0].route_version}/store/product/#{self.id}"
  end
end