require 'fastlane/action'
require 'googleauth'
require_relative '../helper/upload_google_data_safety_helper'
require 'net/http'
require 'json'

module Fastlane
  module Actions
    class UploadGoogleDataSafetyAction < Action
      def self.run(params)

        csv_content = self.csv_file_content(params: params)

        service_account_data = self.service_account_authentication(params: params)

        body = self.get_google_auth(service_account_json: service_account_data)

        access_token = body["access_token"]

        self.send_data_safety_sheet(package_name: params[:package_name], auth_token: access_token, csv_content: csv_content)

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
        unless params[:json_key] || params[:json_key_data]
          if UI.interactive?
            UI.important("To not be asked about this value, you can specify it using 'json_key'")
            json_key_path = UI.input("The service account json file used to authenticate with Google: ")
            json_key_path = File.expand_path(json_key_path)

            UI.user_error!("Could not find service account json file at path '#{json_key_path}'") unless File.exist?(json_key_path)
            params[:json_key] = json_key_path
          else
            UI.user_error!("Could not load Google authentication. Make sure it has been added as an environment variable in 'json_key' or 'json_key_data'")
          end
        end

        if params[:json_key]
          service_account_json = File.open(File.expand_path(params[:json_key]))
        elsif params[:json_key_data]
          service_account_json = StringIO.new(params[:json_key_data])
        end

        service_account_json
      end

      def self.get_google_auth(service_account_json: nil)
        scope = 'https://www.googleapis.com/auth/androidpublisher'

        auth = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: service_account_json, scope: scope)

        token = auth.fetch_access_token!

        token
      end

      def self.send_data_safety_sheet(package_name: nil, auth_token: nil, csv_content: nil)
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

        response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme = 'https') do | http |
          http.request(request)
        end

        if response.is_a?(Net::HTTPSuccess)
          UI.success("Google Safety Data sheet has been uploaded!")
        else
          if response.is_a?(Net::HTTPUnauthorized)
            UI.error("Unauthorized request to upload Google Data Safety sheet.")
          elsif response.is_a?(Net::HTTPBadRequest)
            UI.error("Bad request to upload Google Data Safety sheet.")
          else
            UI.error("Google Data Safety sheet upload error with API")
          end
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
            description: "Json key file for service account authentication",
            optional: true,
            type: String
          ),
          FastlaneCore::ConfigItem.new(
            key: :json_key_data,
            env_name: "JSON_KEY_DATA",
            description: "Json key data for service account authentication",
            optional: true,
            type: Hash
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
