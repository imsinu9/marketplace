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
              :response => @product.as_json(:only => [:description, :categories, :permalink, :created_at, :stock,
                                                      :discount, :tax_inclusive, :shipment_charge, :cash_on_delievery,
                                                      :offer, :offer_description, :views, :buys, :rating, :screenshots],
                                            :methods => [:product_url, :date_posted, :seller, :image_count, :related_products])
          }
        end
      end
    end

    resources :category do
      get 'list' do
        params do
          requires :sort, type: String
          requires :order, type: String
        end

        @categories = Category.all.order_by(params[:order].eql?('Asc') ? :name.asc : :name.desc)

        {
            :metadata => metadata,
            :response =>
                {
                    :total_categories => Category.total_categories,
                    :categories => @categories.as_json(:only => [:_id])
                }
        }
      end

      get ':category_id' do
        params do
          requires :sort, type: String
          requires :order, type: String
          requires :page, type: Integer
          requires :per, type: Integer
        end

        @category = Category.find(params[:category_id])

        if @category.blank?
          {
              :metadata => metadata(404, 'Not Found'),
              :response => ''
          }
        else
          sort = params[:sort].to_sym
          #ordered = params[:order].to_sym
          @products = Product.tagged_with(:categories, @category.name).order_by(sort.send(params[:order])).page(params[:page]).per(params[:per])

          {
              :metadata => metadata,
              :response =>
                  {
                      :total_products => @category.total_products,
                      :products => @products.as_json(:only => [:stock, :discount, :offer, :views, :buys],
                                                     :methods => [:seller_shop, :product_url, :date_posted])
                  }
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