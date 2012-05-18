require 'nokogiri'
require 'net/http'
require 'net/https'

module OmniAuth
  module Strategies
    class Crowd
      class CrowdValidator
        AUTHENTICATION_REQUEST_BODY = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><authentication-context><username><![CDATA[%s]]></username><password><![CDATA[%s]]></password><validation-factors><validation-factor><name>remote_address</name><value>%s</value></validation-factor></validation-factors></authentication-context>"
        TOKEN_REQUEST_BODY = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><validation-factors><validation-factor><name>remote_address</name><value>%s</value></validation-factor></validation-factors>"
        def initialize(configuration, username, password, token, ip_addr)
          @configuration, @username, @password, @token, @ip_addr = configuration, username, password, token, ip_addr
          @authentiction_uri = URI.parse(@configuration.authentication_url)
          @token_uri = URI.parse(@configuration.token_url(@token)) if not @token.nil?
          @user_group_uri    = @configuration.include_users_groups? ? URI.parse(@configuration.user_group_url(@username)) : nil
        end

        def user_info
          user_info_hash = retrieve_user_info!
          if user_info_hash && @configuration.include_users_groups?
            if @username.nil?
              @user_group_uri = URI.parse(@configuration.user_group_url(user_info_hash['user']))
            end
            user_info_hash = add_user_groups!(user_info_hash)
          else
            user_info_hash
          end
          user_info_hash
        end

        private
        def add_user_groups!(user_info_hash)
          response = make_user_group_request
          unless response.code.to_i != 200 || response.body.nil? || response.body == '' 
            doc = Nokogiri::XML(response.body)
            user_info_hash["groups"] = doc.xpath("//groups/group/@name").map(&:to_s)
          end
          user_info_hash
        end
        
        def retrieve_user_info!
          response = make_authorization_request
          if response.code.to_i == 201 || response.code.to_i == 200
            doc = Nokogiri::XML(response.body)
            {
              "user" => doc.xpath("//user/@name").to_s,
              "name" => doc.xpath("//user/display-name/text()").to_s,
              "first_name" => doc.xpath("//user/first-name/text()").to_s,
              "last_name" => doc.xpath("//user/last-name/text()").to_s,
              "email" => doc.xpath("//user/email/text()").to_s,
              "token" => doc.xpath("//session/token/text()").to_s
            }
          else
            nil
          end
        end
        
        def make_user_group_request
          http = Net::HTTP.new(@user_group_uri.host, @user_group_uri.port)
          http.use_ssl = @user_group_uri.port == 443 || @user_group_uri.instance_of?(URI::HTTPS)
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl? && @configuration.disable_ssl_verification?
          http.start do |c|
            req = Net::HTTP::Get.new("#{@user_group_uri.path}?#{@user_group_uri.query}")
            req.basic_auth @configuration.crowd_application_name, @configuration.crowd_password
            http.request(req)
          end
        end
        
        def make_authorization_request 
          if not @token.nil?
            http = Net::HTTP.new(@token_uri.host, @token_uri.port)
            http.use_ssl = @token_uri.port == 443 || @token_uri.instance_of?(URI::HTTPS)
            http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl? && @configuration.disable_ssl_verification?
            response = http.start do |c|
              req = Net::HTTP::Post.new("#{@token_uri.path}?#{@token_uri.query}")
              req.body = TOKEN_REQUEST_BODY % @ip_addr
              req.basic_auth @configuration.crowd_application_name, @configuration.crowd_password
              req.add_field 'Content-Type', 'text/xml'
              http.request(req)
            end
            return response if response.code.to_i == 200
          end

          http = Net::HTTP.new(@authentiction_uri.host, @authentiction_uri.port)
          http.use_ssl = @authentiction_uri.port == 443 || @authentiction_uri.instance_of?(URI::HTTPS)
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE if http.use_ssl? && @configuration.disable_ssl_verification?
          http.start do |c|
            req = Net::HTTP::Post.new("#{@authentiction_uri.path}?#{@authentiction_uri.query}")
            req.body = AUTHENTICATION_REQUEST_BODY % [@username, @password, @ip_addr]
            req.basic_auth @configuration.crowd_application_name, @configuration.crowd_password
            req.add_field 'Content-Type', 'text/xml'
            http.request(req)
          end
        end
      end
    end
  end
end
