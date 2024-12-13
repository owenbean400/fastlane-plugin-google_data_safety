require 'fastlane_core/ui/ui'

module Fastlane
  UI = FastlaneCore::UI unless Fastlane.const_defined?(:UI)

  module Helper
    class GoogleDataSafetyHelper
      # class methods that you define here become available in your action
      # as `Helper::DataSafetyHelper.your_method`
      #
      def self.show_message
        UI.message("Hello from the data_safety plugin helper!")
      end
    end
  end
end
