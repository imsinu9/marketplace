# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#

require 'yaml'
User.delete_all
Category.delete_all
Product.delete_all

users = YAML.load(File.open(File.expand_path('db/user.yml')))
users.each do |key, value|
  user_new = User.new
  user_new.token = value['token']
  user_new.name = value['name']
  user_new.shop = value['shop']
  user_new.contact = value['contact']
  user_new.primary_email = value['primary_email']
  user_new.secondary_email= value['secondary_email']
  user_new.save!
end

categories = YAML.load(File.open(File.expand_path('db/category.yml')))
categories.each do |key, value|
  category_new = Category.new
  category_new.name = value['name']
  category_new.save!
end

products = YAML.load(File.open(File.expand_path('db/product.yml')))
i = 0
User.each do |user|
  2.times do
    i = i+1
    value = products['prod_'+i.to_s]
    product_new = user.products.create
    product_new.title = value['title']
    product_new.description = value['description']
    product_new.categories = value['categories'].map { |a| a.downcase }
    product_new.tags = value['tags'].map { |t| t.downcase }
    product_new.permalink = value['link']
    product_new.stock = value['stock']
    product_new.price = value['price']
    product_new.discount = value['discount']
    product_new.tax_inclusive = value['inctax']
    product_new.shipment_charge = value['shipment']
    product_new.cash_on_delievery = value['cod']
    product_new.offer = value['offer']
    product_new.offer_description = value['offerdesc']
    product_new.display_image = value['dpimg']
    product_new.screenshots = value['screenshots']
    product_new.save!
  end
end
