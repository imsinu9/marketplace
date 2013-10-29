class User
  include Mongoid::Document
  include Mongoid::Timestamps

  field :token, type: String
  field :shop, type: String
  field :name, type: String
  field :contact, type: String
  field :primary_email, type: String
  field :secondary_email, type: String

  validates_presence_of :token, :primary_email, :shop
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

    def create_user(name, shop, contact, p_mail, s_mail)
      user_new = User.new
      user_new.token = User.generate_token
      user_new.name = name
      user_new.shop = shop
      user_new.contact = contact || nil
      user_new.primary_email = p_mail
      user_new.secondary_email= s_mail || nil
      user_new.save!
      user_new
    end
  end

  def create_product(title, desc, category, link, stock, price, discount, shipment, cod, offer, offerdesc, dp, screenshots, tags)
    product_new = self.products.new
    product_new.title = title
    product_new.description = desc || nil
    product_new.categories = category.map { |a| a.downcase }
    product_new.permalink = link
    product_new.stock = stock
    product_new.price = price
    product_new.discount = discount || nil
    product_new.shipment_charge = shipment
    product_new.cash_on_delievery = cod
    product_new.offer = offer
    product_new.offer_description = offerdesc || nil
    product_new.display_image = dp
    product_new.screenshots = screenshots || nil
    product_new.tags = tags.map { |t| t.downcase }
    product_new.save!
    product_new
  end
end