require 'grape'

class Marketplace::API < Grape::API
  version 'v1'
  format :json

  BASE_URL = 'http://marketplace.com/api'
  RELATED_PRODUCT_COUNT = 3

  #before do
  #  metadata(401,'Not Authorized') unless authenticate?(request.env['HTTP_AUTHORIZATION'])
  #end

  helpers do
    def authenticate? (token)
      token_present?(token)
    end

    def metadata(status=200, message='OK')
      {
          :status => status,
          :message => message
      }
    end

    #def product_present? (id)
    #  product = Product.find(id)
    #  product.blank? ? metadata(404, 'Not Found') : product
    #end

    #def category_present?(id)
    #  category = Category.find(id)
    #  category.blank? ? metadata(404, 'Not Found') : category
    #end
  end


  namespace :store do
    resources :product do
      get 'search' do
        metadata
      end

      segment :manage do
        post 'add' do
          metadata
        end

        params do
          requires :product_id, type: String, desc: 'Product ID'
        end

        get 'edit/:product_id' do
          metadata
        end

        put 'update/:product_id' do
          metadata
        end

        delete 'delete/:product_id' do
          metadata
        end
      end

      get ':product_id' do
        @product = Product.find(params[:product_id])
        if @product.blank?
          {
              :metadata => metadata(404, 'Not Found'),
              :response => ''
          }
        else
          @product.increment_view_count

          {
              :metadata => metadata,
              :response => @product.as_json(:only => [:description, :categories, :permalink, :created_date, :stock, :discount, :tax_inclusive,
                                                      :shipment_charge, :cash_on_delievery, :offer, :offer_description, :views, :buys, :rating,
                                                      :screenshots], :methods => [:product_url, :seller, :image_count, :related_products])
          }
        end
      end

      resources :category do
        get 'list' do
          @categories = Category.as_json(:methods => [:total_products])
        end

        params do
          requires :category_id, type: String, desc: 'Category ID'
        end

        get ':category_id' do
          @category = Category.find(params[:category_id])
          if @categories.blank?
            {
                :metadata => metadata(404, 'Not Found'),
                :response => ''
            }
          else
            {
                :metadata => metadata(404, 'Not Found'),
                :response => @category.as_json(:methods => [:total_products])
            }
          end
        end
      end

      resources :user do
        get 'ownedproduct' do
          metadata
        end
      end
    end
  end
end