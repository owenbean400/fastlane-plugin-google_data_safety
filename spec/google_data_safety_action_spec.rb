describe Fastlane::Actions::UploadGoogleDataSafetyAction do
  let(:scope) { 'https://www.googleapis.com/auth/androidpublisher' }
  let(:auth) { double('Google credentials', fetch_access_token!: 'refresh-listener-result', access_token: 'short-lived-token') }

  describe '.get_google_auth' do
    {
      'service_account' => Google::Auth::ServiceAccountCredentials,
      'external_account' => Google::Auth::ExternalAccount::Credentials,
      'authorized_user' => Google::Auth::UserRefreshCredentials
    }.each do |type, credential_class|
      it "uses #{type} credentials with the Android Publisher scope" do
        json = StringIO.new(JSON.generate(type: type))
        expect(credential_class).to receive(:make_creds).with(json_key_io: json, scope: scope) do
          expect(JSON.parse(json.read)['type']).to eq(type)
          auth
        end
        expect(described_class.get_google_auth(service_account_json: json)).to eq('access_token' => 'short-lived-token')
      end
    end

    it 'discovers Application Default Credentials when no JSON is supplied' do
      expect(Google::Auth).to receive(:get_application_default).with(scope).and_return(auth)
      expect(described_class.get_google_auth).to eq('access_token' => 'short-lived-token')
    end

    [true, false].each do |impersonate|
      it "uploads using real external-account refresh (impersonation=#{impersonate}) without a private key" do
        require 'tempfile'
        Tempfile.create('workload-identity') do |file|
          config = {
            type: 'external_account',
            audience: '//iam.googleapis.com/projects/123/locations/global/workloadIdentityPools/github/providers/github',
            subject_token_type: 'urn:ietf:params:oauth:token-type:jwt',
            token_url: 'https://sts.googleapis.com/v1/token',
            credential_source: { url: 'https://example.invalid/oidc', format: { type: 'json', subject_token_field_name: 'value' } }
          }
          if impersonate
            config[:service_account_impersonation_url] = 'https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/example@example.iam.gserviceaccount.com:generateAccessToken'
          end
          file.write(JSON.generate(config))
          file.flush
          previous = ENV['GOOGLE_APPLICATION_CREDENTIALS']
          begin
            ENV['GOOGLE_APPLICATION_CREDENTIALS'] = file.path
            expect(Google::Auth).to receive(:get_application_default).with(scope).and_wrap_original do |method, *args|
              credentials = method.call(*args)
              expect(credentials).to be_a(Google::Auth::ExternalAccount::IdentityPoolCredentials)
              # Keep fetch_access_token! real: only stub the outbound exchanges. Its return
              # value differs from service-account credentials and must not be treated as a Hash.
              expect(credentials).to receive(:exchange_token).and_return('access_token' => 'sts-token', 'expires_in' => 3600)
              if impersonate
                expect(credentials).to receive(:get_impersonated_access_token).with('sts-token').and_return(
                  'accessToken' => 'impersonated-token', 'expireTime' => (Time.now.utc + 3600).iso8601
                )
              end
              credentials
            end
            expected_token = impersonate ? 'impersonated-token' : 'sts-token'
            expect(described_class).to receive(:send_data_safety_sheet).with(
              package_name: 'com.example.app', auth_token: expected_token, csv_content: 'reviewed,csv', debug: false
            )
            described_class.run(csv_content: 'reviewed,csv', package_name: 'com.example.app')
          ensure
            ENV['GOOGLE_APPLICATION_CREDENTIALS'] = previous
          end
        end
      end
    end

    it 'fails before upload when refresh does not populate an access token' do
      expect(Google::Auth).to receive(:get_application_default).with(scope).and_return(auth)
      allow(auth).to receive(:access_token).and_return(nil)
      expect(described_class).not_to receive(:send_data_safety_sheet)
      expect { described_class.run(csv_content: 'reviewed,csv', package_name: 'com.example.app') }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /did not provide an access token/)
    end

    it 'rejects unsupported credential types' do
      expect { described_class.get_google_auth(service_account_json: StringIO.new('{"type":"unknown"}')) }
        .to raise_error(FastlaneCore::Interface::FastlaneError, /Unsupported Google credential type/)
    end
  end

  describe '.service_account_authentication' do
    it 'allows ADC without prompting' do
      expect(Fastlane::UI).not_to receive(:input)
      expect(described_class.service_account_authentication(params: {})).to be_nil
    end

    it 'serializes Hash credentials accepted by json_key_data' do
      io = described_class.service_account_authentication(params: { json_key_data: { 'type' => 'external_account' } })
      expect(JSON.parse(io.read)).to eq('type' => 'external_account')
    end

    it 'loads explicit credential files without leaking an open file handle' do
      require 'tempfile'
      Tempfile.create('google-credentials') do |file|
        file.write('{"type":"external_account"}')
        file.flush
        io = described_class.service_account_authentication(params: { json_key: file.path })
        expect(io).to be_a(StringIO)
        expect(JSON.parse(io.read)['type']).to eq('external_account')
      end
    end
  end

  describe '.run' do
    it 'uploads with ADC and the exact CSV contents' do
      csv = "Question ID,Response ID\nquestion,response\n"
      expect(Google::Auth).to receive(:get_application_default).with(scope).and_return(auth)
      expect(described_class).to receive(:send_data_safety_sheet).with(
        package_name: 'com.example.app', auth_token: 'short-lived-token', csv_content: csv, debug: false
      )
      described_class.run(csv_content: csv, package_name: 'com.example.app')
    end
  end

  describe '.send_data_safety_sheet' do
    let(:csv) { "a,b\nc,d\n" }

    def respond_with(response)
      transport = double('HTTP transport')
      expect(Net::HTTP).to receive(:start).with(
        'androidpublisher.googleapis.com', 443,
        use_ssl: true, open_timeout: 30, read_timeout: 30, write_timeout: 30
      ).and_yield(transport)
      expect(transport).to receive(:request) do |request|
        expect(request.path).to eq('/androidpublisher/v3/applications/com.example.app/dataSafety')
        expect(request['Authorization']).to eq('Bearer short-lived-token')
        expect(JSON.parse(request.body)).to eq('safetyLabels' => csv)
        response
      end
    end

    def upload
      described_class.send_data_safety_sheet(package_name: 'com.example.app', auth_token: 'short-lived-token', csv_content: csv)
    end

    it 'posts the declaration successfully' do
      respond_with(Net::HTTPOK.new('1.1', '200', 'OK'))
      expect(Fastlane::UI).to receive(:success)
      upload
    end

    [Net::HTTPBadRequest, Net::HTTPUnauthorized, Net::HTTPForbidden, Net::HTTPFound].each do |response_class|
      it "fails the lane on #{response_class}, including redirects" do
        respond_with(response_class.new('1.1', '403', 'Rejected'))
        expect { upload }.to raise_error(FastlaneCore::Interface::FastlaneError, /upload failed \(HTTP 403\)/)
      end
    end

    it 'propagates timeouts without retrying or reporting success' do
      expect(Net::HTTP).to receive(:start).once.and_raise(Net::ReadTimeout)
      expect(Fastlane::UI).not_to receive(:success)
      expect { upload }.to raise_error(Net::ReadTimeout)
    end
  end
end
