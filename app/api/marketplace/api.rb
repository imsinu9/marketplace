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
        avail = params[:available] == 'true' ? true : false
        offer = params[:offer] == 'true' ? true : false
        sorts = sort.to_sym

        if !sort.in?(['discount', 'created_at', 'views', 'price', 'buys']) || !order.in?(['desc', 'asc'])
          {
              :metadata => metadata(501, 'Bad Request'),
              :response => ''
          }
        else

          if offer
            @products = Product.with_offer
          else
            @products = Product.all
          end

          if avail
            @products = Product.with_availability
          end

          if !params[:seller].blank?
            @products = User.find_by(:shop => params[:seller]).products || @products
          end

          if !params[:category].blank?
            @products = @products.by_category(params[:category]) || @products
          end

          if !params[:q].blank?
            keywords = params[:q].gsub(/[^a-z A-Z 1-9]/, ' ').downcase.split(" ")
            keywords.reject! { |words| words.length<3 }
            @products_id = []
            @products.each do |product|
              sample_keywords = keywords
              title_words = product.title.gsub(/[^a-z A-Z 1-9]/, ' ').downcase.split(" ")
              title_words.reject! { |word| word.length<3 }
              tags_words = product.tags.map { |t| t.downcase }
              tags_words.reject! { |word| word.length<3 }

              words = (tags_words + title_words).flatten.uniq
              sample_keywords.reject! { |word| !word.in?(words) }

              if sample_keywords.count>0
                @products_id << product.id
              end
            end
          end

          final_products = @products.where(:id.in => @products_id).order_by(sorts.send(params[:order])).page(params[:page]).per(params[:per])
          {
              :metadata => metadata,
              :response =>
                  {
                      :total_products => final_products.count,
                      :products => final_products.as_json(:only => [:categories, :stock, :discount, :offer, :views, :buys],
                                                          :methods => [:seller, :date_posted])
                  }
          }
        end
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

          if params[:title].blank? || params[:category].blank? || params[:stock].blank? ||params[:price].blank? ||
              params[:offer].nil? || params[:cash_on_delivery].nil? || params[:shipment_charge].blank? ||
              params[:display_image].blank?
            {
                :metadata => metadata(501, 'Bad Request')
            }

          else
            user = User.get_user_with_token(request.env['HTTP_AUTHORIZATION'])
            @product = user.create_product(params[:title], params[:description], params[:category], params[:permalink],
                                           params[:stock], params[:price], params[:discount], params[:shipment_charge],
                                           params[:cash_on_delivery], params[:offer], params[:offer_description],
                                           params[:display_image], params[:screenshots], params[:tags])

            {
                :metadata => metadata(201, 'Created'),
                :response => {:url => @product.url}
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
          elsif params[:title].blank? || params[:category].blank? || params[:stock].blank? ||params[:price].blank? ||
              params[:offer].nil? || params[:cash_on_delivery].nil? || params[:shipment_charge].blank? ||
              params[:display_image].blank?
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
        elsif !sort.in?(['discount', 'created_at', 'views', 'price', 'buys']) || !order.in?(['desc', 'asc'])
          {
              :metadata => metadata(501, 'Bad Request'),
              :response => ''
          }
        else
          sorts = sort.to_sym
          @products = Product.by_category(@category.name).order_by(sorts.send(params[:order])).page(params[:page]).per(params[:per])

          {
              :metadata => metadata,
              :response =>
                  {
                      :total_products => @category.total_products,
                      :products => @products.as_json(:only => [:stock, :discount, :offer, :views, :buys],
                                                     :methods => [:seller, :date_posted])
                  }
          }
        end
      end
    end

    resources :user do
      post 'add' do
        params do
          requires :name, type: String
          requires :shop, type: String
          requires :primary_mail, type: String
          optional :contact, type: String
          optional :secondary_mail, type: String
        end

        if params[:name].blank? || params[:shop].blank? || params[:primary_mail].blank?
          {
              :metadata => metadata(501, 'Bad Request')
          }
        else
          @new_user = User.create_user(params[:name], params[:shop], params[:contact], params[:primary_mail],
                                       params[:secondary_mail])
          {
              :metadata => metadata(201, 'Created'),
              :response => {:token => @new_user.token}
          }
        end
      end

      delete 'delete' do
        user = User.get_user_with_token(request.env['HTTP_AUTHORIZATION'])
        user.products.each { |product| product.delete }
        user.delete
        {
            :metadata => metadata,
            :response => ''
        }
      end

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

        if !sort.in?(['title', 'created_at', 'views', 'stock']) || !order.in?(['desc', 'asc'])
          {
              :metatdata => metadata(501, 'Bad Request'),
              :response => ''
          }
        else
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
end