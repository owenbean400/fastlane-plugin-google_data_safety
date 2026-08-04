require 'fastlane/action'
require 'googleauth'
require_relative '../helper/prompt_create_data_safety_csv_helper'
require 'net/http'
require 'json'
require 'csv'

module Fastlane
  module Actions
    class PromptCreateDataSafetyCsvAction < Action
      FORMULA_CHARS = %w[= + - @].freeze

      # Run the prompt_create_data_safety_csv action.
      #
      # @param param [hash] Fastlane parameters
      def self.run(params)
        if !UI.interactive?
          UI.error("Prompts questions can only display in interactive.")
        end

        csv_file_path = params[:csv_file]
        csv_file_path = File.expand_path(csv_file_path)

        hash = {}

        self.headerDisplay(csv_file: csv_file_path)
        self.startingQuestion(hash: hash)

        template_data = Helper::PromptCreateDataSafetyHelper.template_array()

        safety_data = template_data.each_with_index do | row |
            hash_key = "#{row[0]},#{row[1]}"
            if hash.key?(hash_key)
                row[2] = hash[hash_key]
            end
        end

        self.saveCsvFile(data: safety_data, csv_file_path: csv_file_path)
      end

      # Array of valid answer strings for true.
      def self.valid_true_answers = ["y", "yes", "true", "t"]
      # Array of valid answer strings for false.
      def self.valid_false_answers = ["n", "no", "false", "f"]
      # Array of valid answer strings for ninety days selection (delete account data).
      def self.valid_90_day_answers = ["90", "ninety"]

      # Displays terminal header of Fastlane action and about the upcoming prompts.
      #
      # @param csv_file [String] The CSV file location that display to user where the file will be saved in
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
        UI.important("Answer the following prompts below to generate CSV file to upload at #{csv_file}")
        UI.important("")
      end

      # Prompt questions for Google Data Safety sheet.
      # 
      # @param hash [hash] The hash to save data of answers to questions
      def self.startingQuestion(hash: nil)
        isDataInputAppInfo = self.promptForAnswerBoolean(
            question: "Does your app collect or share any of the required user data types?",
            hash: hash,
            question_id: "PSL_DATA_COLLECTION_COLLECTS_PERSONAL_DATA",
            response_id: "",
            is_false_blank: false)

        if isDataInputAppInfo

            self.promptForAnswerBoolean(
              question: "Is all of the user data collected by your app encrypted in transit?",
              hash: hash,
              question_id: "PSL_DATA_COLLECTION_ENCRYPTED_IN_TRANSIT",
              response_id: "",
              is_false_blank: false)

            isDataInputAccountCreate = self.promptForAnswerBoolean(
              question: "Does the app allow for account creation from within the app?",
              hash: nil,
              question_id: nil,
              response_id: nil,
              is_false_blank: false)

            if isDataInputAccountCreate
                self.promptForAnswerBoolean(
                  question: "Does the app allow for account creation from username and password?",
                  hash: hash,
                  question_id: "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS",
                  response_id: "PSL_ACM_USER_ID_PASSWORD",
                  is_false_blank: true)

                self.promptForAnswerBoolean(
                  question: "Does the app allow for account creation from username and other authentication?",
                  hash: hash,
                  question_id: "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS",
                  response_id: "PSL_ACM_USER_ID_OTHER_AUTH",
                  is_false_blank: true)

                self.promptForAnswerBoolean(
                  question: "Does the app allow for account creation from username, password, and other authentication?",
                  hash: hash,
                  question_id: "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS",
                  response_id: "PSL_ACM_USER_ID_PASSWORD_OTHER_AUTH",
                  is_false_blank: true)

                self.promptForAnswerBoolean(
                  question: "Does the app allow for account creation from OAuth?",
                  hash: hash,
                  question_id: "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS",
                  response_id: "PSL_ACM_OAUTH",
                  is_false_blank: true)

                isDataInputCreateOther = self.promptForAnswerBoolean(
                  question: "Does the app allow for other account creation method?",
                  hash: hash,
                  question_id: "PSL_SUPPORTED_ACCOUNT_CREATION_METHODS",
                  response_id: "PSL_ACM_OTHER",
                  is_false_blank: true)

                if isDataInputCreateOther
                    self.promptForAnswer(
                      question: "Describe the method of account creation that your app supports",
                      hash: hash,
                      question_id: "PSL_ACM_SPECIFY",
                      response_id: "")
                end

                self.promptForUrl(
                      question: "Add a valid URL for account deletion",
                      hash: hash,
                      question_id: "PSL_ACCOUNT_DELETION_URL",
                      response_id: "")
            else
                isDataInputLoginOutside = self.promptForAnswerBoolean(
                  question: "Can users login to your app with accounts created outside of the app?",
                  hash: hash,
                  question_id: "PSL_HAS_OUTSIDE_APP_ACCOUNTS",
                  response_id: "",
                  is_false_blank: true)

                if isDataInputLoginOutside
                    self.promptForAnswerBoolean(
                      question: "Can users create account outside of app by app identification (e.g. SIM binding, service subscription)?",
                      hash: hash,
                      question_id: "PSL_OUTSIDE_APP_ACCOUNT_TYPES",
                      response_id: "PSL_LOGIN_WITH_OUTSIDE_APP_ID",
                      is_false_blank: true)

                    self.promptForAnswerBoolean(
                      question: "Can users create account outside of app by employment or enterprise account?",
                      hash: hash,
                      question_id: "PSL_OUTSIDE_APP_ACCOUNT_TYPES",
                      response_id: "PSL_LOGIN_THROUGH_EMPLOYMENT_OR_ENTERPRISE_ACCOUNT",
                      is_false_blank: true)

                    isDataInputLoginOutsideOther = self.promptForAnswerBoolean(
                      question: "Is there other way users can create account outside of app?",
                      hash: hash,
                      question_id: "PSL_OUTSIDE_APP_ACCOUNT_TYPES",
                      response_id: "PSL_OUTSIDE_APP_ACCOUNT_TYPE_OTHER",
                      is_false_blank: true)

                    if isDataInputLoginOutsideOther
                        self.promptForAnswer(
                          question: "Describe how these accounts are created",
                          hash: hash,
                          question_id: "PSL_OUTSIDE_APP_ACCOUNT_TYPE_SPECIFY",
                          response_id: "")
                    end
                end
            end

            dataInputDeleteData = UI.input("Do you provide a way for users to request that their data is deleted? Type 90 for deletion after 90 days. Y/N/90")

            while !self.valid_true_answers.include?(dataInputDeleteData.downcase) &&
                !self.valid_false_answers.include?(dataInputDeleteData.downcase) &&
                !self.valid_90_day_answers.include?(dataInputDeleteData.downcase)
              UI.important("Please provide an answer of either yes, no, or 90")
              dataInputDeleteData = UI.input("Do you provide a way for users to request that their data is deleted? Type 90 for deletion after 90 days. Y/N/90")
            end

            if self.valid_true_answers.include?(dataInputDeleteData.downcase)
                self.addToHash(hash: hash, question_id: "PSL_SUPPORT_DATA_DELETION_BY_USER", response_id: "DATA_DELETION_YES", value: "true")

                self.promptForUrl(
                  question: "What URL link can users request to delete data?",
                  hash: hash,
                  question_id: "PSL_DATA_DELETION_URL",
                  response_id: "")
            elsif self.valid_90_day_answers.include?(dataInputDeleteData.downcase)
              self.addToHash(hash: hash, question_id: "PSL_SUPPORT_DATA_DELETION_BY_USER", response_id: "DATA_DELETION_NO_AUTO_DELETED", value: "true")
            else
              self.addToHash(hash: hash, question_id: "PSL_SUPPORT_DATA_DELETION_BY_USER", response_id: "DATA_DELETION_NO", value: "true")
            end

            self.questionDataInfo(hash: hash)
        end
      end

      # Prompt question data type group question for Google Data Safety sheet.
      # 
      # @param hash [hash] The hash to save data of answers to questions
      def self.questionDataInfo(hash: nil)
        UI.important("*** Below questions will be asked about location data ***")
        self.questionDataType(title: "approximate location", code: "PSL_APPROX_LOCATION", group_code: "PSL_DATA_TYPES_LOCATION", hash: hash)
        self.questionDataType(title: "precise location", code: "PSL_PRECISE_LOCATION", group_code: "PSL_DATA_TYPES_LOCATION", hash: hash)

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

        UI.important("\n*** Below questions will be asked about audio and music data ***")
        self.questionDataType(title: "health info", code: "PSL_HEALTH", group_code: "PSL_DATA_TYPES_HEALTH_AND_FITNESS", hash: hash)
        self.questionDataType(title: "fitness info", code: "PSL_FITNESS", group_code: "PSL_DATA_TYPES_HEALTH_AND_FITNESS", hash: hash)

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

        UI.important("*** Below questions will be asked about files and documents data ***")
        self.questionDataType(title: "files and docs", code: "PSL_FILES_AND_DOCS", group_code: "PSL_DATA_TYPES_FILES_AND_DOCS", hash: hash)

        UI.important("*** Below questions will be asked about calendar data ***")
        self.questionDataType(title: "calendar events", code: "PSL_CALENDAR", group_code: "PSL_DATA_TYPES_CALENDAR", hash: hash)

        UI.important("*** Below questions will be asked about contact data ***")
        self.questionDataType(title: "contacts", code: "PSL_CONTACTS", group_code: "PSL_DATA_TYPES_CONTACTS", hash: hash)

        UI.important("*** Below questions will be asked about app activity data ***")
        self.questionDataType(title: "app interactions", code: "PSL_USER_INTERACTION", group_code: "PSL_DATA_TYPES_APP_ACTIVITY", hash: hash)
        self.questionDataType(title: "in-app search history", code: "PSL_IN_APP_SEARCH_HISTORY", group_code: "PSL_DATA_TYPES_APP_ACTIVITY", hash: hash)
        self.questionDataType(title: "installed apps", code: "PSL_APPS_ON_DEVICE", group_code: "PSL_DATA_TYPES_APP_ACTIVITY", hash: hash)
        self.questionDataType(title: "other user-generated content", code: "PSL_USER_GENERATED_CONTENT", group_code: "PSL_DATA_TYPES_APP_ACTIVITY", hash: hash)
        self.questionDataType(title: "other actions", code: "PSL_OTHER_APP_ACTIVITY", group_code: "PSL_DATA_TYPES_APP_ACTIVITY", hash: hash)

        UI.important("*** Below questions will be asked about location data ***")
        self.questionDataType(title: "web browser history", code: "PSL_WEB_BROWSING_HISTORY", group_code: "PSL_DATA_TYPES_SEARCH_AND_BROWSING", hash: hash)

        UI.important("*** Below questions will be asked about app performance data ***")
        self.questionDataType(title: "crash log", code: "PSL_CRASH_LOGS", group_code: "PSL_DATA_TYPES_APP_PERFORMANCE", hash: hash)
        self.questionDataType(title: "performance diagnostics", code: "PSL_PERFORMANCE_DIAGNOSTICS", group_code: "PSL_DATA_TYPES_APP_PERFORMANCE", hash: hash)
        self.questionDataType(title: "other app performance data", code: "PSL_OTHER_PERFORMANCE", group_code: "PSL_DATA_TYPES_APP_PERFORMANCE", hash: hash)

        UI.important("*** Below questions will be asked about identifier data ***")
        self.questionDataType(title: "device or other IDs", code: "PSL_DEVICE_ID", group_code: "PSL_DATA_TYPES_IDENTIFIERS", hash: hash)
      end

      # Prompt question of a specific data type about data sharing and data collection for Google Data Safety sheet.
      # 
      # @param title [String] The data type title
      # @param code [String] Google Data Safety code name for CSV file format
      # @param group_code [String] Google Data Safety group code name for CSV file format
      # @param hash [hash] The hash to save data of answers to questions
      def self.questionDataType(title: "", code: "", group_code: "", hash: nil)
        isDataInputCollectOrShare = self.promptForAnswerBoolean(
          question: "Is #{title} data being collected or shared?",
          hash: hash,
          question_id: group_code,
          response_id: code,
          is_false_blank: true)

        if isDataInputCollectOrShare
          isDataInputShared = self.promptForAnswerBoolean(
            question: "Is #{title} data being shared?",
            hash: hash,
            question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:PSL_DATA_USAGE_COLLECTION_AND_SHARING",
            response_id: "PSL_DATA_USAGE_ONLY_SHARED",
            is_false_blank: true)

          if isDataInputShared
              self.promptForAnswerBoolean(
                question: "Is #{title} shared for app functionality?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE",
                response_id: "PSL_APP_FUNCTIONALITY",
                is_false_blank: true)

              self.promptForAnswerBoolean(
                question: "Is #{title} shared for analytics?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE",
                response_id: "PSL_ANALYTICS",
                is_false_blank: true)

              self.promptForAnswerBoolean(
                question: "Is #{title} shared for developer communications?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE",
                response_id: "PSL_DEVELOPER_COMMUNICATIONS",
                is_false_blank: true)

              self.promptForAnswerBoolean(
                question: "Is #{title} shared for advertising or marketing?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE",
                response_id: "PSL_ADVERTISING",
                is_false_blank: true)

              self.promptForAnswerBoolean(
                question: "Is #{title} shared for fraud prevention, security, or compliance?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE",
                response_id: "PSL_FRAUD_PREVENTION_SECURITY",
                is_false_blank: true)

              self.promptForAnswerBoolean(
                question: "Is #{title} shared for personalizing the app?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE",
                response_id: "PSL_PERSONALIZATION",
                is_false_blank: true)

              self.promptForAnswerBoolean(
                question: "Is #{title} shared to manage account?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_SHARING_PURPOSE",
                response_id: "PSL_ACCOUNT_MANAGEMENT",
                is_false_blank: true)
          end

          isDataInputCollected = self.promptForAnswerBoolean(
            question: "Is #{title} data being collected?",
            hash: hash,
            question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:PSL_DATA_USAGE_COLLECTION_AND_SHARING",
            response_id: "PSL_DATA_USAGE_ONLY_COLLECTED",
            is_false_blank: true)

          if isDataInputCollected
              self.promptForAnswerBoolean(
                question: "Is #{title} data processed ephemerally?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:PSL_DATA_USAGE_EPHEMERAL",
                response_id: "",
                is_false_blank: false)

              isDataInputRequired = self.promptForAnswerBoolean(
                question: "Is #{title} data required for your app?",
                hash: nil,
                question_id: nil,
                response_id: nil,
                is_false_blank: false)

              if isDataInputRequired
                  self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_USER_CONTROL", response_id: "PSL_DATA_USAGE_USER_CONTROL_REQUIRED", value: "true")
              else
                  self.addToHash(hash: hash, question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_USER_CONTROL", response_id: "PSL_DATA_USAGE_USER_CONTROL_OPTIONAL", value: "true")
              end

              self.promptForAnswerBoolean(
                question: "Is #{title} collected for app functionality?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE",
                response_id: "PSL_APP_FUNCTIONALITY",
                is_false_blank: true)

              self.promptForAnswerBoolean(
                question: "Is #{title} collected for analytics?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE",
                response_id: "PSL_ANALYTICS",
                is_false_blank: true)

              self.promptForAnswerBoolean(
                question: "Is #{title} collected for developer communications?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE",
                response_id: "PSL_DEVELOPER_COMMUNICATIONS",
                is_false_blank: true)

              self.promptForAnswerBoolean(
                question: "Is #{title} collected for advertising or marketing?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE",
                response_id: "PSL_ADVERTISING",
                is_false_blank: true)

              self.promptForAnswerBoolean(
                question: "Is #{title} collected for fraud prevention, security, or compliance?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE",
                response_id: "PSL_FRAUD_PREVENTION_SECURITY",
                is_false_blank: true)

              self.promptForAnswerBoolean(
                question: "Is #{title} collected for personalizing the app?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE",
                response_id: "PSL_PERSONALIZATION",
                is_false_blank: true)

              self.promptForAnswerBoolean(
                question: "Is #{title} collected to manage account?",
                hash: hash,
                question_id: "PSL_DATA_USAGE_RESPONSES:#{code}:DATA_USAGE_COLLECTION_PURPOSE",
                response_id: "PSL_ACCOUNT_MANAGEMENT",
                is_false_blank: true)
          end
        end
      end

      # Save CSV file with data sanitation.
      #
      # @param data [hash] Google Data Safety hash of CSV content
      # @param csv_file_path [String] CSV file path to save file at
      def self.saveCsvFile(data: nil, csv_file_path: "")
        FileUtils.mkdir_p(File.dirname(csv_file_path))

        CSV.open(csv_file_path, "w") do |csv|
          data.each do |row|
            sanitized_row = row.map do |cell|
              if cell.is_a?(String)
                cleaned = cell.gsub(/[\t\r\n]/, '').strip

                if cleaned.lstrip.start_with?(*FORMULA_CHARS)
                  cleaned = "'#{cleaned}"
                end

                cleaned
              else
                cell
              end
            end

            csv << sanitized_row
          end
        end
      end

      # Prompt question to terminal for a yes or no answer. Reprompt user if answer is not a valid yes or no.
      #
      # @param question [String] The question that displays in terminal
      # @param hash [hash] The hash data for Google Data Safety.
      # @param question_id [String] The question id to add in the hash data. Review CSV file from Google Data Safety sheet for more details.
      # @param response_id [String] The response id to add in the hash data. Review CSV file from Google Data Safety sheet for more details.
      # @param is_false_blank [Boolean] Whether the false answer should be false or blank in CSV file. It is dependent on the question ID and response ID for Google Data Safety sheet format.
      # @return [Boolean] The user's answer to the question
      def self.promptForAnswerBoolean(question: "", hash: nil, question_id: nil, response_id: "", is_false_blank: false)
        answer = UI.input(question + " Y/N")

        while !self.valid_true_answers.include?(answer.downcase) && !self.valid_false_answers.include?(answer.downcase)
          UI.important("Please provide \"y\", \"yes\", \"true\", or \"t\" for yes; and \"n\", \"no\", \"false\", \"f\" for no")
          answer = UI.input(question + " Y/N")
        end

        if self.valid_true_answers.include?(answer.downcase)
          self.addToHash(hash: hash, question_id: question_id, response_id: response_id, value: "true")
          return true
        else
          self.addToHash(hash: hash, question_id: question_id, response_id: response_id, value: is_false_blank ? "" : "false")
          return false
        end
      end

      # Prompt question to terminal for a string answer. Reprompt user if answer is empty string.
      #
      # @param question [String] The question that displays in terminal
      # @param hash [hash] The hash data for Google Data Safety
      # @param question_id [String] The question id to add in the hash data. Review CSV file from Google Data Safety sheet for more details.
      # @param response_id [String] The response id to add in the hash data. Review CSV file from Google Data Safety sheet for more details.
      # @return [String] The user's answer to question
      def self.promptForAnswer(question: "", hash: nil, question_id: nil, response_id: "")
        answer = UI.input(question)

        while answer.empty?
          UI.important("Please provide an answer")
          answer = UI.input(question) 
        end

        self.addToHash(hash: hash, question_id: question_id, response_id: response_id, value: answer)
        return answer
      end

      # Prompt question to terminal for URL answer. Reprompt user if answer is not a valid URL.
      #
      # @param question [String] The question that displays in terminal
      # @param hash [hash] The hash data for Google Data Safety
      # @param question_id [String] The question id to add in the hash data. Review CSV file from Google Data Safety sheet for more details.
      # @param response_id [String] The response id to add in the hash data. Review CSV file from Google Data Safety sheet for more details.
      # @return [String] The user's answer to question
      def self.promptForUrl(question: "", hash: nil, question_id: nil, response_id: "")
        answer = UI.input(question)

        while !self.validUrl?(answer)
          UI.important("Please provide a proper URL")
          answer = UI.input(question) 
        end

        self.addToHash(hash: hash, question_id: question_id, response_id: response_id, value: answer)
        return answer
      end

      # Detect if URL is valid format.
      #
      # @param url [String] The url to validate
      # @return [Boolean] The url is valid
      def self.validUrl?(url)
        uri = URI.parse(url)
        uri.is_a?(URI::HTTP) && !uri.host.nil?
      rescue URI::InvalidURIError
        false
      end

      # Prompt question and answer to Google Data Safety hash
      #
      # @param hash [hash] The hash data for Google Data Safety
      # @param question_id [String] The question id to add in the hash data. Review CSV file from Google Data Safety sheet for more details.
      # @param response_id [String] The response id to add in the hash data. Review CSV file from Google Data Safety sheet for more details.
      # @param value [String] The answer value
      def self.addToHash(hash: nil, question_id: nil, response_id: "", value: nil)
        if !value.nil? && !hash.nil?
            hash["#{question_id},#{response_id}"] = value
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