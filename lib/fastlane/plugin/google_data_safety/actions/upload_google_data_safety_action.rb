require 'fastlane/action'
require 'googleauth'
require_relative '../helper/upload_google_data_safety_helper'
require 'net/http'
require 'json'
require 'stringio'

module Fastlane
  module Actions
    class UploadGoogleDataSafetyAction < Action
      def self.run(params)

        csv_content = self.csv_file_content(params: params)

        service_account_data = self.service_account_authentication(params: params)

        body = self.get_google_auth(service_account_json: service_account_data)

        access_token = body["access_token"]

        debug = false

        if !params[:debug].nil?
          debug = params[:debug]
        end

        self.send_data_safety_sheet(package_name: params[:package_name], auth_token: access_token, csv_content: csv_content, debug: debug)

      end

      def self.csv_file_content(params: nil)
        unless params[:csv_file] || params[:csv_content]
          if UI.interactive?
            UI.important("To not be asked about this value, you can specify it using 'csv_file'")
            csv_file_path = UI.input("The csv file used for Google data safety sheet: ")
            csv_file_path = File.expand_path(csv_file_path)

            UI.user_error!("Could not find csv file at path '#{csv_file_path}'") unless File.exist?(csv_file_path)
            params[:csv_file]
          else
            UI.user_error!("Could not obtain data safety information as comma separated values. Please have 'csv_file' or 'csv_content' variable set.")
          end
        end

        csv_file_content = ""

        if params[:csv_file]
          csv_file_content = File.read(File.expand_path(params[:csv_file]))
        elsif params[:csv_content]
          csv_file_content = params[:csv_content]
        end

        csv_file_content
      end

      def self.service_account_authentication(params: nil)
        if params[:json_key]
          service_account_json = StringIO.new(File.read(File.expand_path(params[:json_key])))
        elsif params[:json_key_data]
          data = params[:json_key_data]
          service_account_json = StringIO.new(data.is_a?(String) ? data : JSON.generate(data))
        end

        service_account_json
      end

      def self.get_google_auth(service_account_json: nil)
        scope = 'https://www.googleapis.com/auth/androidpublisher'

        auth = if service_account_json
                 credentials = JSON.parse(service_account_json.read)
                 service_account_json.rewind
                 case credentials['type']
                 when 'external_account'
                   Google::Auth::ExternalAccount::Credentials.make_creds(json_key_io: service_account_json, scope: scope)
                 when 'authorized_user'
                   Google::Auth::UserRefreshCredentials.make_creds(json_key_io: service_account_json, scope: scope)
                 when 'service_account'
                   Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: service_account_json, scope: scope)
                 else
                   UI.user_error!('Unsupported Google credential type. Use service_account, external_account or authorized_user credentials.')
                 end
               else
                 Google::Auth.get_application_default(scope)
               end

        # External-account refresh returns a listener result, not a token response Hash.
        # All googleauth credential types expose the refreshed token through access_token.
        auth.fetch_access_token!
        token = auth.access_token
        UI.user_error!('Google authentication did not provide an access token.') unless token.is_a?(String) && !token.empty?

        { 'access_token' => token }
      end

      def self.send_data_safety_sheet(package_name: nil, auth_token: nil, csv_content: nil, debug: false)
        if package_name.nil?
          if UI.interactive?
            UI.important("To not be asked package name, you can specify it using 'package_name'.")
            package_name_input = UI.input("The package name to upload Google safety data sheet: ")
            package_name = package_name_input
          else
            UI.Error("Package name is required to upload Google safety data sheet. Please specify package name with 'package_name' variable.")
          end
        end

        uri = URI("https://androidpublisher.googleapis.com/androidpublisher/v3/applications/#{package_name}/dataSafety")

        request = Net::HTTP::Post.new(uri)
        request["Authorization"] = "Bearer #{auth_token}"
        request["Content-Type"] = "application/json"
        request.body = { safetyLabels: csv_content }.to_json

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 30, read_timeout: 30, write_timeout: 30) do | http |
          http.request(request)
        end

        if response.is_a?(Net::HTTPSuccess)
          UI.success("Google Safety Data sheet has been uploaded!")
        else
          if debug
            UI.important("Google Data Safety API response body")
            UI.important(response.body)
          end
          UI.user_error!("Google Data Safety upload failed (HTTP #{response.code}); declaration upload was not confirmed.")
        end

      end

      def self.description
        "Google safety data sheet for automation of safety form"
      end

      def self.authors
        ["Owen Bean"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        # Optional:
        "Uploads and update any data safety sheet on Google Play Console API."
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :csv_file,
            env_name: "CSV_FILE",
            description: "Csv file path to upload to Google Play Console Data Safety",
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :csv_content,
            env_name: "CSV_CONTENT",
            description: "Comma delimited list of Google Data Safety form",
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :package_name,
            env_name: "PACKAGE_NAME",
            description: "Package name of project",
            optional: false,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :json_key,
            env_name: "JSON_KEY_FILE",
            description: "Google credential JSON file (service account, Workload Identity Federation or user credentials); defaults to ADC",
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :json_key_data,
            env_name: "JSON_KEY_DATA",
            description: "Google credential JSON data; defaults to Application Default Credentials when omitted",
            optional: true,
            type: Hash
          ),
          FastlaneCore::ConfigItem.new(
            key: :debug,
            env_name: "DEBUG",
            description: "Set to debug mode for troubleshooting",
            optional: true,
            type: Boolean
          ),
        ]
      end

      def self.is_supported?(platform)
        # Adjust this if your plugin only works for a particular platform (iOS vs. Android, for example)
        # See: https://docs.fastlane.tools/advanced/#control-configuration-by-lane-and-by-platform
        #
        # [:ios, :mac, :android].include?(platform)
        true
      end
    end
  end
end
