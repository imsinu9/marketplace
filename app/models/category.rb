class Category
  include Mongoid::Document
  include Mongoid::Timestamps

  field :name, type: String
  field :active, type: Boolean, :default => true

  validates_presence_of :name
  validates_uniqueness_of :name

  scope :active, where(:active => true)

  class<<self
    def total_categories
      Category.active.count
    end
  end

  def category_url
    "#{Marketplace::API::BASE_URL}/#{Marketplace::API::routes[0].route_version}/store/category/#{self.id}"
  end

  def total_products
    Product.tagged_with(:categories, self.name.downcase).count
  end

  def as_json(options={})
    only = options[:only] || []
    methods = options[:methods] || []
    super(:only => only.push(:name), :methods => methods.push(:total_products))
  end
end