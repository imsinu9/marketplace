require 'grape'

class Marketplace::API < Grape::API
  version 'v1'
  format :json

  BASE_URL = 'http://heroku-marketplace.herokuapp.com/api'
  RELATED_PRODUCT_COUNT = 3

  before do
    if request.env['HTTP_AUTHORIZATION'].blank? || !authenticate?(request.env['HTTP_AUTHORIZATION'])
      throw :error, :message => {:metadata => metadata(401, 'Not Authorized')}
    end
  end

  helpers do
    def authenticate? (token)
      User.token_present?(token)
    end

    def metadata(status=200, message='OK')
      {
          :status => status,
          :message => message
      }
    end
  end


  namespace :store do
    resources :product do
      get 'search' do
        params do
          optional :q, type: String
          optional :category, type: String
          optional :seller, type: String
          requires :available, type: Boolean
          requires :offer, type: Boolean
          requires :sort, type: String
          requires :order, type: String
          requires :page, type: Integer
          requires :per, type: Integer
        end

        page = params[:page] || 1
        per = params[:per] || 30
        order = params[:order] || 'desc'
        sort = params[:sort] || 'views'
        avail = params[:available] || false
        offer = params[:offer] || false

        unless params[:category].blank?
          products_by_category = Product.by_category(params[:category])
        end

        unless params[:seller].blank?
          products_by_seller = User.where(:shop => params[:seller]).product
        end

        unless params[:q].blank?
          keywords = params[:q].gsub(/[^a-z A-Z 1-9]/, ' ').downcase.split(" ")
          keywords.reject! { |words| words.length<3 }
          products_by_query = Product.where(:title.in => keywords)
        end

        products =
            (products_by_category.to_a + products_by_seller.to_a + products_by_query.to_a).flatten.uniq
        products.reject! { |product| product.blank? }
        {
            :metadata => metadata,
            :response =>
                {
                    :total_products => products.count,
                    :products => products.as_json(:only => [:categories, :stock, :discount, :offer, :views, :buys],
                                                  :method => [:seller, :date_posted])
                }
        }
      end

      segment :manage do
        post 'add' do
          params do
            requires :title, type: String
            optional :description, type: String
            requires :category, type: Array
            optional :permalink, type: String
            requires :stock, type: Integer
            requires :price, type: Float
            optional :discount, type: Float
            requires :shipment_charge, type: Float
            requires :cash_on_delivery, type: Boolean
            requires :offer, type: Boolean
            optional :offer_description, type: String
            requires :display_image, type: String
            optional :screenshots, type: Array
            optional :tags, type: Array
          end

          if params[:title].nil? || params[:category].nil? || params[:stock].nil? ||params[:price].nil? ||
              params[:offer].nil? || params[:cash_on_delivery].nil? || params[:shipment_charge].nil? ||
              params[:display_image].nil?
            {
                :metadata => metadata(501, 'Bad Request')
            }

          else
            user = User.get_user_with_token(request.env['HTTP_AUTHORIZATION'])
            product_new = user.products.new
            product_new.title = params[:title]
            product_new.description = params[:description] || nil
            product_new.categories = params[:category].map { |a| a.downcase }
            product_new.permalink = params[:link]
            product_new.stock = params[:stock]
            product_new.price = params[:price]
            product_new.discount = params[:discount] || nil
            product_new.shipment_charge = params[:shipment_charge]
            product_new.cash_on_delievery = params[:cash_on_delivery]
            product_new.offer = params[:offer]
            product_new.offer_description = params[:offer_description] || nil
            product_new.tags = params[:tags].map { |t| t.downcase }
            product_new.offer_description = params[:offerdesc]
            product_new.display_image = params[:display_image]
            product_new.screenshots = params[:screenshots] || nil
            product_new.tags = params[:tags] || nil
            product_new.save!

            {
                :metadata => metadata(201, 'Created'),
                :response => {:url => product_new.url}
            }
          end
        end

        get 'edit/:product_id' do
          user = User.get_user_with_token(request.env['HTTP_AUTHORIZATION'])
          @product = Product.find(params[:product_id])
          if @product.blank?
            {
                :metadata => metadata(404, 'Not Found'),
                :response => ''
            }
          elsif @product.user.id != user.id
            {
                :metadata => metadata(401, 'Not Authorized'),
                :response => ''
            }
          else
            {
                :metadata => metadata,
                :response => @product.as_json(:only => [:description, :categories, :permalink, :stock, :discount,
                                                        :shipment_charge, :cash_on_delievery, :offer, :tags,
                                                        :offer_description, :screenshots])
            }
          end
        end

        put 'update/:product_id' do
          params do
            requires :title, type: String
            optional :description, type: String
            requires :category, type: Array
            optional :permalink, type: String
            requires :stock, type: Integer
            requires :price, type: Float
            optional :discount, type: Float
            requires :shipment_charge, type: Float
            requires :cash_on_delivery, type: Boolean
            requires :offer, type: Boolean
            optional :offer_description, type: String
            requires :display_image, type: String
            optional :screenshots, type: Array
            optional :tags, type: Array
          end
          user = User.get_user_with_token(request.env['HTTP_AUTHORIZATION'])
          @product = Product.find(params[:product_id])
          if @product.blank?
            {
                :metadata => metadata(404, 'Not Found'),
                :response => ''
            }
          elsif params[:title].nil? || params[:category].nil? || params[:stock].nil? ||params[:price].nil? ||
              params[:offer].nil? || params[:cash_on_delivery].nil? || params[:shipment_charge].nil? ||
              params[:display_image].nil?
            {
                :metadata => metadata(501, 'Bad Request')
            }

          elsif @product.user.id != user.id
            {
                :metadata => metadata(401, 'Not Authorized'),
                :response => ''
            }
          else
            @product.update_product(params[:title], params[:description], params[:category], params[:permalink],
                                    params[:stock], params[:price], params[:discount], params[:shipment_charge],
                                    params[:cash_on_delivery], params[:offer], params[:offer_description],
                                    params[:display_image], params[:screenshots], params[:tags])
            {
                :metadata => metadata,
                :response => {:url => @product.url}
            }
          end
        end

        delete 'delete/:product_id' do
          params do
            requires :permanent, type: Boolean
          end

          permanent = params[:permanent].nil? ? false : params[:permanent]
          user = User.get_user_with_token(request.env['HTTP_AUTHORIZATION'])
          @product = Product.find(params[:product_id])

          if @product.blank?
            {
                :metadata => metadata(404, 'Not Found'),
                :response => ''
            }
          elsif @product.user.id != user.id
            {
                :metadata => metadata(401, 'Not Authorized'),
                :response => ''
            }
          else
            Product.where(:_id => params[:product_id]).delete
            {
                :metadata => metadata,
                :response => {:permanent => permanent}
            }
          end
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
              :response => @product.as_json(:only => [:description, :categories, :permalink, :stock, :discount,
                                                      :tax_inclusive, :shipment_charge, :cash_on_delievery, :offer,
                                                      :offer_description, :views, :buys, :rating, :screenshots],
                                            :methods => [:date_posted, :seller, :image_count, :related_products])
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

        page = params[:page] || 1
        per = params[:per] || 30
        order = params[:order] || 'desc'
        sort = params[:sort] || 'views'

        @category = Category.find(params[:category_id])

        if @category.blank?
          {
              :metadata => metadata(404, 'Not Found'),
              :response => ''
          }
        else
          sorts = sort.to_sym
          @products = Product.by_category(@category.name).order_by(sorts.send(params[:order])).page(params[:page]).per(params[:per])

          {
              :metadata => metadata,
              :response =>
                  {
                      :total_products => @category.total_products_in_category,
                      :products => @products.as_json(:only => [:stock, :discount, :offer, :views, :buys],
                                                     :methods => [:seller_shop, :date_posted])
                  }
          }
        end
      end
    end

    resources :user do
      get 'ownedproduct' do
        params do
          requires :sort, type: String
          requires :order, type: String
          requires :page, type: Integer
          requires :per, type: Integer
        end

        page = params[:page] || 1
        per = params[:per] || 30
        order = params[:order] || 'asc'
        sort = params[:sort] || 'title'

        @user_products = User.get_user_with_token(request.env['HTTP_AUTHORIZATION']).products
        sorts = sort.to_sym
        {
            :metadata => metadata,
            :response =>
                {
                    :total_products => @user_products.count,
                    :products => @user_products.order_by(sorts.send(params[:order])).page(params[:page]).per(
                        params[:per]).as_json(:only => [:stock], :methods => [:date_posted])
                }
        }
      end
    end
  end
end