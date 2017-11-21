require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Blackboard < OmniAuth::Strategies::OAuth2

      option :name, "blackboard"

      option :client_options,
             site:          "https://bd-partner-a-original.blackboard.com",
             authorize_url: "/learn/api/public/v1/oauth2/authorizationcode",
             token_url:     "/learn/api/public/v1/oauth2/token"

      # Blackboard does use state but we want to control it rather than letting
      # omniauth-oauth2 handle it.
      option :provider_ignores_state, true

      option :token_params,
             parse: :json

      uid do
        access_token["user"]["id"]
      end

      info do
        {
          "name" => raw_info["name"],
          "email" => raw_info["primary_email"],
          "bio" => raw_info["bio"],
          "title" => raw_info["title"],
          "nickname" => raw_info["login_id"],
          "active_avatar" => raw_info["avatar_url"],
          "url" => access_token.client.site
        }
      end

      extra do
        { raw_info: raw_info }
      end

      def raw_info
        @raw_info ||= access_token.get("/learn/api/public/v1/users/#{access_token['user']['id']}").parsed
      end

      # Passing any query string value to Blackboard will result in:
      # redirect_uri does not match client settings
      # so we set the value to empty string
      def query_string
        ""
      end

      # Override authorize_params so that we can be deliberate about the value for state
      # and not use the session which is unavailable inside of an iframe for some
      # browsers (ie Safari)
      def authorize_params
        # Only set state if it hasn't already been set
        options.authorize_params[:state] ||= SecureRandom.hex(24)
        params = options.authorize_params.merge(options_for("authorize"))
        if OmniAuth.config.test_mode
          @env ||= {}
          @env["rack.session"] ||= {}
        end
        params
      end

    end
  end
end

OmniAuth.config.add_camelization "blackboard", "Blackboard"
