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

      params do
        requires :product_id, type: String, desc: 'Product ID'
      end

      get ':product_id' do
      end
    end

    resources :category do
      get 'list' do
        metadata
      end

      params do
        requires :category_id, type: String, desc: 'Category ID'
      end

      get ':category_id' do
      end
    end

    resources :user do
      get 'ownedproduct' do
        metadata
      end
    end
  end
end