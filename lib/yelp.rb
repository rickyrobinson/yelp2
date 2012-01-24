require 'oauth'
require 'json'
require 'pathname'
require 'cgi'
require 'nokogiri'
require 'open-uri'

module Yelp

  class ApiError < StandardError; end
  
  mattr_reader :connection
  mattr_reader :yelp
  mattr_reader :yelp_config
  @@yelp_config = {
    :consumer_key => ENV['YELP_CONSUMER_KEY'],
    :consumer_secret => ENV['YELP_CONSUMER_SECRET'],
    :token => ENV['YELP_TOKEN'],
    :token_secret => ENV['YELP_TOKEN_SECRET']
  }
  
  mattr_reader :categories
  @@categories = nil
  
  class << self
    def setup
      @@yelp_config = {}
      yield self
    end
  
    def consumer_key=(key)
      @@yelp_config[:consumer_key] = key
    end
  
    def consumer_secret=(secret)
      @@yelp_config[:consumer_secret] = secret
    end
  
    def token=(t)
      @@yelp_config[:token] = t
    end
  
    def token_secret=(secret)
      @@yelp_config[:token_secret] = secret
    end
  
    def find(params)
      self.yelp.find(params)
    end
    
    def build_query(path, opts)
      "#{path}?#{opts.map { |k,v| "#{k}=#{CGI.escape(v)}" }.join('&')}"
    end
  
    def categories
      @@categories ||= self.get_categories
    end
  
    def get_categories
      doc = Nokogiri::HTML(open("http://www.yelp.com/developers/documentation/category_list").read)
      cats = doc.css("ul.attr-list").children
      self.extract_categories cats
    end
  
    def extract_categories items, parent = nil
      cats = []
      prev = nil
      items.each do |item|
        if item.name == "li"
          parent_key = (parent ? parent[:key] : "")
          key =
            if parent_key.empty?
              item.content.match(/\((.*)\)/)[1]
            else
              "#{parent_key}_#{item.content.match(/\((.*)\)/)[1]}"
            end
          name = item.content.match(/^(.*) \(/)[1]
          short_name = name.split[0]
          prev = {:key => key, :name => name, :short_name => short_name, :parent_key => parent_key, :num_children => 0, :icon => "https://foursquare.com/img/categories/arts_entertainment/arcade_32.png"}
          cats << prev
          parent[:num_children] += 1 if parent
        elsif item.name == "ul"
          subcats = self.extract_categories item.children, prev
          cats += subcats
        end
      end
      cats
    end

    def yelp
      @@yelp ||= Yelp::Search.new(@@yelp_config)
    end
  end
end

dir = Pathname(__FILE__).dirname.expand_path
require dir + 'yelp/base'
require dir + 'yelp/search'
