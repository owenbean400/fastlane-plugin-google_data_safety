require 'fastlane/action'
require 'googleauth'
require_relative '../helper/prompt_create_data_safety_csv_helper'
require 'net/http'
require 'json'
require 'csv'

module Fastlane
  module Actions
    class PromptCreateDataSafetyCsvAction < Action
      def self.run(params)

        csv_file_path = params[:csv_file]
        csv_file_path = File.expand_path(csv_file_path)

        hash = {}

        self.headerDisplay(csv_file: csv_file_path)
        self.startingQuestion(hash: hash)

        template_data = Helper::PromptCreateDataSafetyHelper.template_array()

        template_data.each_with_index do | row |
            hash_key = "#{row[0]},#{row[1]}"
            if hash.key?(hash_key)
                row[2] = hash[hash_key]
            end
        end

        CSV.open(csv_file_path, "w") do |csv|
          template_data.each do |row|
              csv << row
            end
          end

      end

      def self.headerDisplay(csv_file: nil)
        UI.important("")
        UI.important("   ____                   _        ____        _          ____         __      _         ")
        UI.important("  / ___| ___   ___   __ _| | ___  |  _ \\  __ _| |_ __ _  / ___|  __ _ / _| ___| |_ _   _ ")
        UI.important(" | |  _ / _ \\ / _ \\ / _` | |/ _ \\ | | | |/ _` | __/ _` | \\___ \\ / _` | |_ / _ | __| | | |")
        UI.important(" | |_| | (_) | (_) | (_| | |  __/ | |_| | (_| | || (_| |  ___) | (_| |  _|  __| |_| |_| |")
        UI.important("  \\____|\\___/ \\___/ \\__, |_|\\___| |____/ \\__,_|\\__\\__,_| |____/ \\__,_|_|  \\___|\\__|\\__, |")
        UI.important("                    |___/                                                          |___/ ")
        UI.important("")
        UI.important("By: Owen Bean")
        UI.important("Report problems at https://github.com/owenbean400/fastlane-plugin-google_data_safety/issues")
        UI.important("")
        UI.important("Answer the following prompt below to generate CSV file to upload at #{csv_file}")
        UI.important("")
      end

      def self.startingQuestion(hash: nil)
        dataInputAppInfo = UI.input("Does your app collect or share any of the required user data types? Y/N")

        self.addToHash(hash: hash, question_id: "PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA", response_id: "", value: self.trueOrFalse(str_response: dataInputAppInfo))

        if dataInputAppInfo.downcase == "y" || dataInputAppInfo.downcase == "yes"

            dataInputEncryption = UI.input("Is all of the user data collected by your app encrypted in transit? Y/N")
            self.addToHash(hash: hash, question_id: "PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT", response_id: "", value: self.trueOrFalse(str_response: dataInputEncryption))

            dataInputAccountCreate = UI.input("Does the app allow for account creation from within the app? Y/N")

            if dataInputAccountCreate.downcase == "y" || dataInputAccountCreate.downcase == "yes"

                dataInputCreateUserPass = UI.input("Does the app allow for account creation from username and password? Y/N")
                self.addToHash(hash: hash, question_id: "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS", response_id: "PSL_ACM_USER_ID_PASSWORD", value: self.trueOrBlank(str_response: dataInputCreateUserPass))

                dataInputCreateUserAuth = UI.input("Does the app allow for account creation from username and other authentication? Y/N")
                self.addToHash(hash: hash, question_id: "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS", response_id: "PSL_ACM_USER_ID_OTHER_AUTH", value: self.trueOrBlank(str_response: dataInputCreateUserAuth))

                dataInputCreateUserPassAuth = UI.input("Does the app allow for account creation from username, password, and other authentication? Y/N")
                self.addToHash(hash: hash, question_id: "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS", response_id: "PSL_ACM_USER_ID_PASSWORD_OTHER_AUTH", value: self.trueOrBlank(str_response: dataInputCreateUserPassAuth))

                dataInputCreateOauth = UI.input("Does the app allow for account creation from OAuth? Y/N")
                self.addToHash(hash: hash, question_id: "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS", response_id: "PSL_ACM_OAUTH", value: self.trueOrBlank(str_response: dataInputCreateOauth))

                dataInputCreateOther = UI.input("Does the app allow for other account creation method? Y/N")
                self.addToHash(hash: hash, question_id: "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS", response_id: "PSL_ACM_OTHER", value: self.trueOrBlank(str_response: dataInputCreateOther))

                if dataInputCreateOther.downcase == "y" || dataInputCreateOther.downcase == "yes"

                    dataInputCreateOtherDesc = UI.input("Describe the method of account creation that your app supports")
                    self.addToHash(hash: hash, question_id: "PSL_ACM_SPECIFY", response_id: "", value: dataInputCreateOtherDesc)

                end

                dataInputAccountDeletionURL = UI.input("Added valid URL for account deletion")
                self.addToHash(hash: hash, question_id: "PSL_ACCOUNT_DELETION_URL", response_id: "", value: dataInputAccountDeletionURL)

            else
                self.addToHash(hash: hash, question_id: "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS", response_id: "PSL_ACM_NONE", value: "true")

                dataInputLoginOutside = UI.input("Can users login to your app with accounts created outside of the app?")
                self.addToHash(hash: hash, question_id: "PSL_HAS_OUTSIDE_APP_ACCOUNTS", response_id: "", value: self.trueOrBlank(str_response: dataInputLoginOutside))

                if dataInputLoginOutside.downcase == "y" || dataInputLoginOutside.downcase == "yes"

                    dataInputLoginOutsideOut = UI.input("Can users create account outside of app by app identification (e.g. SIM binding, service subscription)? Y/N")
                    self.addToHash(hash: hash, question_id: "PSL_OUTSIDE_APP_ACCOUNT_TYPES", response_id: "PSL_LOGIN_WITH_OUTSIDE_APP_ID", value: self.trueOrBlank(str_response: dataInputLoginOutsideOut))

                    dataInputLoginOutsideAccount = UI.input("Can users create account outside of app by employment or enterprise account?")
                    self.addToHash(hash: hash, question_id: "PSL_OUTSIDE_APP_ACCOUNT_TYPES", response_id: "PSL_LOGIN_THROUGH_EMPLOYMENT_OR_ENTERPRISE_ACCOUNT", value: self.trueOrBlank(str_response: dataInputLoginOutsideAccount))

                    dataInputLoginOutsideOther = UI.input("Is there other way users can create account outside of app?")
                    self.addToHash(hash: hash, question_id: "PSL_OUTSIDE_APP_ACCOUNT_TYPES", response_id: "PSL_OUTSIDE_APP_ACCOUNT_TYPE_OTHER", value: self.trueOrBlank(str_response: dataInputLoginOutsideOther))

                    if dataInputLoginOutsideOther.downcase == "y" || dataInputLoginOutsideOther.downcase == "yes"

                        dataInputLoginOutsideOther = UI.input("Describe how these accounts are created")
                        self.addToHash(hash: hash, question_id: "PSL_OUTSIDE_APP_ACCOUNT_TYPE_SPECIFY", response_id: "", value: dataInputLoginOutsideOther)

                    end

                end

            end

            dataInputDeleteData = UI.input("Do you provide a way for users to request that their data is deleted? Type 90 for deletion after 90 days. Y/N/90")

            if dataInputDeleteData.downcase == "y" || dataInputDeleteData == "yes"
                self.addToHash(hash: hash, question_id: "PSL_SUPPORT_DATA_DELETION_BY_USER", response_id: "DATA_DELETION_YES", value: "true")

                dataInputDeleteLink = UI.input("What URL link can users request to delete data?")
                self.addToHash(hash: hash, question_id: "PSL_DATA_DELETION_URL", response_id: "", value: dataInputDeleteLink)
            elsif dataInputDeleteData.downcase == "90"
              self.addToHash(hash: hash, question_id: "PSL_SUPPORT_DATA_DELETION_BY_USER", response_id: "DATA_DELETION_NO_AUTO_DELETED", value: "true")
            else
              self.addToHash(hash: hash, question_id: "PSL_SUPPORT_DATA_DELETION_BY_USER", response_id: "DATA_DELETION_NO", value: "true")
            end

            self.questionDataInfo(hash: hash)
        end
      end

      def self.questionDataInfo(hash: nil)
        UI.important("*** Below questions will be asked about personal information data ***")
        self.questionDataType(title: "name", code: "PSL_NAME", group_code: "PSL_DATA_TYPES_PERSONAL", hash: hash)
        self.questionDataType(title: "email", code: "PSL_EMAIL", group_code: "PSL_DATA_TYPES_PERSONAL", hash: hash)
        self.questionDataType(title: "user ID", code: "PSL_USER_ACCOUNT", group_code: "PSL_DATA_TYPES_PERSONAL", hash: hash)
        self.questionDataType(title: "address", code: "PSL_ADDRESS", group_code: "PSL_DATA_TYPES_PERSONAL", hash: hash)
        self.questionDataType(title: "phone", code: "PSL_PHONE", group_code: "PSL_DATA_TYPES_PERSONAL", hash: hash)
        self.questionDataType(title: "race and ethnicity", code: "PSL_RACE_ETHNICITY", group_code: "PSL_DATA_TYPES_PERSONAL", hash: hash)
        self.questionDataType(title: "political or religious beliefs", code: "PSL_POLITICAL_RELIGIOUS", group_code: "PSL_DATA_TYPES_PERSONAL", hash: hash)
        self.questionDataType(title: "sexual orientation", code: "PSL_SEXUAL_ORIENTATION_GENDER_IDENTITY", group_code: "PSL_DATA_TYPES_PERSONAL", hash: hash)
        self.questionDataType(title: "other personal information", code: "PSL_OTHER_PERSONAL", group_code: "PSL_DATA_TYPES_PERSONAL", hash: hash)

        UI.important("*** Below questions will be asked about financial data ***")
        self.questionDataType(title: "user payment information", code: "PSL_CREDIT_DEBIT_BANK_ACCOUNT_NUMBER", group_code: "PSL_DATA_TYPES_FINANCIAL", hash: hash)
        self.questionDataType(title: "purchase history", code: "PSL_PURCHASE_HISTORY", group_code: "PSL_DATA_TYPES_FINANCIAL", hash: hash)
        self.questionDataType(title: "credit score", code: "PSL_CREDIT_SCORE", group_code: "PSL_DATA_TYPES_FINANCIAL", hash: hash)
        self.questionDataType(title: "other financial info", code: "PSL_OTHER", group_code: "PSL_DATA_TYPES_FINANCIAL", hash: hash)

        UI.important("*** Below questions will be asked about location data ***")
        self.questionDataType(title: "approximate location", code: "PSL_APPROX_LOCATION", group_code: "PSL_DATA_TYPES_LOCATION", hash: hash)
        self.questionDataType(title: "precise location", code: "PSL_PRECISE_LOCATION", group_code: "PSL_DATA_TYPES_LOCATION", hash: hash)

        UI.important("*** Below questions will be asked about location data ***")
        self.questionDataType(title: "web browser history", code: "PSL_WEB_BROWSING_HISTORY", group_code: "PSL_DATA_TYPES_SEARCH_AND_BROWSING", hash: hash)

        UI.important("*** Below questions will be asked about email and text data ***")
        self.questionDataType(title: "email", code: "PSL_EMAILS", group_code: "PSL_DATA_TYPES_EMAIL_AND_TEXT", hash: hash)
        self.questionDataType(title: "SMS or MMS", code: "PSL_SMS_CALL_LOG", group_code: "PSL_DATA_TYPES_EMAIL_AND_TEXT", hash: hash)
        self.questionDataType(title: "Other in-app messages", code: "PSL_OTHER_MESSAGES", group_code: "PSL_DATA_TYPES_EMAIL_AND_TEXT", hash: hash)

        UI.important("*** Below questions will be asked about photo and video data ***")
        self.questionDataType(title: "photo", code: "PSL_PHOTOS", group_code: "PSL_DATA_TYPES_PHOTOS_AND_VIDEOS", hash: hash)
        self.questionDataType(title: "videos", code: "PSL_VIDEOS", group_code: "PSL_DATA_TYPES_PHOTOS_AND_VIDEOS", hash: hash)

        UI.important("*** Below questions will be asked about audio and music data ***")
        self.questionDataType(title: "voice or sound recordings", code: "PSL_AUDIO", group_code: "PSL_DATA_TYPES_AUDIO", hash: hash)
        self.questionDataType(title: "music files", code: "PSL_MUSIC", group_code: "PSL_DATA_TYPES_AUDIO", hash: hash)
        self.questionDataType(title: "Other audio files", code: "PSL_OTHER_AUDIO", group_code: "PSL_DATA_TYPES_AUDIO", hash: hash)

        UI.important("\n*** Below questions will be asked about audio and music data ***")
        self.questionDataType(title: "health info", code: "PSL_HEALTH", group_code: "PSL_DATA_TYPES_HEALTH_AND_FITNESS", hash: hash)
        self.questionDataType(title: "fitness info", code: "PSL_FITNESS", group_code: "PSL_DATA_TYPES_HEALTH_AND_FITNESS", hash: hash)

        UI.important("*** Below questions will be asked about contact data ***")
        self.questionDataType(title: "contacts", code: "PSL_CONTACTS", group_code: "PSL_DATA_TYPES_CONTACTS", hash: hash)

        UI.important("*** Below questions will be asked about calendar data ***")
        self.questionDataType(title: "calendar events", code: "PSL_CALENDAR", group_code: "PSL_DATA_TYPES_CALENDAR", hash: hash)

        UI.important("*** Below questions will be asked about app performance data ***")
        self.questionDataType(title: "crash log", code: "PSL_CRASH_LOGS", group_code: "PSL_DATA_TYPES_APP_PERFORMANCE", hash: hash)
        self.questionDataType(title: "performance diagnostics", code: "PSL_PERFORMANCE_DIAGNOSTICS", group_code: "PSL_DATA_TYPES_APP_PERFORMANCE", hash: hash)
        self.questionDataType(title: "other app performance data", code: "PSL_OTHER_PERFORMANCE", group_code: "PSL_DATA_TYPES_APP_PERFORMANCE", hash: hash)

        UI.important("*** Below questions will be asked about files and documents data ***")
        self.questionDataType(title: "files and docs", code: "PSL_FILES_AND_DOCS", group_code: "PSL_DATA_TYPES_FILES_AND_DOCS", hash: hash)

        UI.important("*** Below questions will be asked about app activity data ***")
        self.questionDataType(title: "app interactions", code: "PSL_USER_INTERACTION", group_code: "PSL_DATA_TYPES_APP_ACTIVITY", hash: hash)
        self.questionDataType(title: "installed apps", code: "PSL_IN_APP_SEARCH_HISTORY", group_code: "PSL_DATA_TYPES_APP_ACTIVITY", hash: hash)
        self.questionDataType(title: "other user-generated content", code: "PSL_USER_GENERATED_CONTENT", group_code: "PSL_DATA_TYPES_APP_ACTIVITY", hash: hash)
        self.questionDataType(title: "other actions", code: "PSL_OTHER_APP_ACTIVITY", group_code: "PSL_DATA_TYPES_APP_ACTIVITY", hash: hash)

        UI.important("*** Below questions will be asked about identifier data ***")
        self.questionDataType(title: "device or other IDs", code: "PSL_DEVICE_ID", group_code: "PSL_DATA_TYPES_IDENTIFIERS", hash: hash)
      end

      def self.questionDataType(title: "", code: "", group_code: "", hash: nil)
        dataInputCollectOrShare = UI.input("Is #{title} data being collected or shared? Y/N")
        self.addToHash(hash: hash, question_id: group_code, response_id: code, value: self.trueOrBlank(str_response: dataInputCollectOrShare))

        if dataInputCollectOrShare.downcase == "y" || dataInputCollectOrShare.downcase == "yes"
          dataInputShared = UI.input("Is #{title} data being shared? Y/N")
          self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:PSL_DATA_USAGE_COLLECTION_AND_SHARING", response_id: "PSL_DATA_USAGE_ONLY_SHARED", value: self.trueOrBlank(str_response: dataInputShared))

          # Data Shared Question
          if dataInputShared.downcase == "y" || dataInputShared.downcase == "yes"
              dataInputShareAppFunctionality = UI.input("Is #{title} shared for app functionality? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE", response_id: "PSL_APP_FUNCTIONALITY", value: self.trueOrBlank(str_response: dataInputShareAppFunctionality))

              dataInputShareAnalytics = UI.input("Is #{title} shared for analytics? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE", response_id: "PSL_ANALYTICS", value: self.trueOrBlank(str_response: dataInputShareAnalytics))

              dataInputShareDeveloperComm = UI.input("Is #{title} shared for developer communications? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE", response_id: "PSL_DEVELOPER_COMMUNICATIONS", value: self.trueOrBlank(str_response: dataInputShareDeveloperComm))

              dataInputShareAdvertise = UI.input("Is #{title} shared for advertising or marketing? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE", response_id: "PSL_ADVERTISING", value: self.trueOrBlank(str_response: dataInputShareAdvertise))

              dataInputShareFraud = UI.input("Is #{title} shared for fraud prevention, security, or compliance? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE", response_id: "PSL_FRAUD_PREVENTION_SECURITY", value: self.trueOrBlank(str_response: dataInputShareFraud))

              dataInputSharePersonal = UI.input("Is #{title} shared for personalizing the app? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE", response_id: "PSL_PERSONALIZATION", value: self.trueOrBlank(str_response: dataInputSharePersonal))

              dataInputShareAccount = UI.input("Is #{title} shared to manage account? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE", response_id: "PSL_ACCOUNT_MANAGEMENT", value: self.trueOrBlank(str_response: dataInputShareAccount))
          end

          dataInputCollected = UI.input("Is #{title} data being collected? Y/N")
          self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:PSL_DATA_USAGE_COLLECTION_AND_SHARING", response_id: "PSL_DATA_USAGE_ONLY_COLLECTED", value: self.trueOrBlank(str_response: dataInputCollected))

          # Data Collection Question
          if dataInputCollected.downcase == "y" || dataInputCollected.downcase == "yes"
              dataInputEphemeral = UI.input("Is #{title} data processed ephemerally? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:PSL_DATA_USAGE_EPHEMERAL", response_id: "", value: self.trueOrBlank(str_response: dataInputEphemeral))

              dataInputRequired = UI.input("Is #{title} data required for your app? Y/N")
              if dataInputRequired.downcase == "y" || dataInputRequired == "yes"
                  self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_USER_CONTROL", response_id: "PSL_DATA_USAGE_USER_CONTROL_REQUIRED", value: "true")
              else
                  self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_USER_CONTROL", response_id: "PSL_DATA_USAGE_USER_CONTROL_OPTIONAL", value: "true")
              end


              dataInputCollectAppFunctionality = UI.input("Is #{title} collected for app functionality? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE", response_id: "PSL_APP_FUNCTIONALITY", value: self.trueOrBlank(str_response: dataInputCollectAppFunctionality))

              dataInputCollectAnalytics = UI.input("Is #{title} collected for analytics? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE", response_id: "PSL_ANALYTICS", value: self.trueOrBlank(str_response: dataInputCollectAnalytics))

              dataInputCollectDeveloperComm = UI.input("Is #{title} collected for developer communications? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE", response_id: "PSL_DEVELOPER_COMMUNICATIONS", value: self.trueOrBlank(str_response: dataInputCollectDeveloperComm))

              dataInputCollectAdvertise = UI.input("Is #{title} collected for advertising or marketing? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE", response_id: "PSL_ADVERTISING", value: self.trueOrBlank(str_response: dataInputCollectAdvertise))

              dataInputCollectFraud = UI.input("Is #{title} collected for fraud prevention, security, or compliance? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE", response_id: "PSL_FRAUD_PREVENTION_SECURITY", value: self.trueOrBlank(str_response: dataInputCollectFraud))

              dataInputCollectPersonal = UI.input("Is #{title} collected for personalizing the app? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE", response_id: "PSL_PERSONALIZATION", value: self.trueOrBlank(str_response: dataInputCollectPersonal))

              dataInputCollectAccount = UI.input("Is #{title} collected to manage account? Y/N")
              self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE", response_id: "PSL_ACCOUNT_MANAGEMENT", value: self.trueOrBlank(str_response: dataInputCollectAccount))
          end
        end
      end

      def self.addToHash(hash: nil, question_id: nil, response_id: "", value: nil)
        if !value.nil?
            hash["#{question_id},#{response_id}"] = value
        end
      end

      def self.trueOrBlank(str_response: nil)
        if str_response.downcase == "y" || str_response.downcase == "yes"
            "true"
        else
            nil
        end
      end

      def self.trueOrFalse(str_response: nil)
        if str_response.downcase == "y" || str_response.downcase == "yes"
            "true"
        else
            "false"
        end
    end

      def self.description
        "Prompt user questions to generate Google data safety sheet"
      end

      def self.authors
        ["Owen Bean"]
      end

      def self.return_value
        # If your method provides a return value, you can describe here what it does
      end

      def self.details
        "Command line question prompts for information about Android app data collection"
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(
            key: :csv_file,
            env_name: "CSV_FILE",
            description: "File location to save csv file for Google data safety sheet",
            optional: false,
            type: String
          )
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