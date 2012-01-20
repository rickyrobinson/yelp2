class Yelp::Base
  
  API_HOST = 'http://api.yelp.com'
  
  def initialize(params)
    consumer = OAuth::Consumer.new(params[:consumer_key], params[:consumer_secret], { :site => API_HOST })
    @connection = OAuth::AccessToken.new(consumer, params[:token], params[:token_secret])
  end
  
end