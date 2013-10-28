class Product
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::TaggableWithContext

  field :title, type: String
  field :description, type: String
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

  taggable :categories, separator: ','
  taggable :tags, separator: ','

  validates_presence_of :title, :user_id, :stock, :price, :display_image

  belongs_to :user, dependent: :delete

  scope :by_category, lambda { |category| tagged_with(:categories, category) }

  def product_url
    "#{Marketplace::API::BASE_URL}/#{Marketplace::API::routes[0].route_version}/store/product/#{self.id}"
  end

  def seller
    self.user.shop
  end

  def date_posted
    self.created_at
  end

  def image_count
    self.screenshots.count + 1
  end

  def increment_view_count
    self.inc(:views, 1)
  end

  def related_products
    Product.tagged_with(:categories, self.categories).limit(3)
  end

  def as_json(options={})
    only = options[:only] || []
    methods = options[:methods] || []
    super(:only => only.push(:title, :price, :display_image), :methods => methods.push(:product_url))
  end
end