require 'wework/request'
require 'wework/api/methods/media'
require 'wework/api/methods/user'
require 'wework/api/methods/agent'
require 'wework/api/methods/department'
require 'wework/api/methods/tag'
require 'wework/api/methods/crm'
require 'wework/api/methods/menu'
require 'wework/api/methods/checkin'
require 'wework/api/methods/message'
require 'wework/api/methods/service'
require 'wework/api/methods/provider'
require 'wework/api/methods/batch'
require 'wework/api/methods/approval'
require 'wework/api/methods/appchat'
require 'wework/token/base'
require 'wework/token/app_token'
module Wework
  module Api
    class Base

      include Methods::Media
      include Methods::User
      include Methods::Department
      include Methods::Tag
      include Methods::Crm
      include Methods::Batch

      attr_accessor :corp_id, :secret, :options

      def initialize options={}
        @corp_id      = options.delete(:corp_id)
        @secret       = options.delete(:secret)
        @token_store  = options.delete(:token_store)
        @options      = options
      end

      def request
        @request ||= Wework::Request.new(API_ENDPOINT, true)
      end

      def valid?
        return false if corp_id.nil?
        token_store.token.present?
      rescue AccessTokenExpiredError
        false
      rescue => e
        Rails.logger.error "[WEWORK] (valid?) fetch access token error(#{corp_id}): #{e.inspect}" if defined?(Rails)
        false
      end

      def get(path, headers = {})
        with_token(headers[:params]) do |params|
          request.get path, headers.merge(params: params)
        end
      end

      def post(path, payload, headers = {})
        with_token(headers[:params]) do |params|
          request.post path, payload, headers.merge(params: params)
        end
      end

      def post_file(path, file, headers = {})
        with_token(headers[:params]) do |params|
          request.post_file path, file, headers.merge(params: params)
        end
      end

      def access_token
        token_store.token
      end

      private

      def with_token(params = {}, tries = 2)
        params ||= {}
        yield(params.merge(token_params))
      rescue AccessTokenExpiredError
        token_store.update_token
        retry unless (tries -= 1).zero?
      end

      def token_store
        @token_store ||= Token::AppToken.new self
      end

      def token_params
        {access_token: access_token}
      end

    end
  end
end
