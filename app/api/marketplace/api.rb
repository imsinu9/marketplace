require 'grape'

class Marketplace::API < Grape::API
  version 'v1'
  format :json

  before do
      error!('401 Unauthorized', 401) unless authenticate?(request.env['HTTP_AUTHORIZATION'])
  end

  helper do
    def authenticate? (key)
      User.find(:token => key).exists?
    end
  end
end