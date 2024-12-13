describe Fastlane::Actions::UploadGoogleDataSafetyAction do
  describe '#run' do
    it 'prints a message' do
      expect(Fastlane::UI).to receive(:message).with("The google_data_safety plugin is working!")

      Fastlane::Actions::UploadGoogleDataSafetyAction.run(nil)
    end
  end
end
