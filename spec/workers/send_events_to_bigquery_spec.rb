require 'rails_helper'

RSpec.describe SendEventsToBigquery do
  describe '#perform' do
    let(:request_event) do
      {
        environment: 'production',
        request_method: 'GET',
        request_path: '/provider/applications',
        request_uuid: '1c94ee0c-c217-4c45-a633-d649ff30a4c3',
        namespace: 'provider_interface',
        timestamp: Time.zone.now.iso8601,
        user_id: 3456,
      }
    end

    let(:project) { instance_double(Google::Cloud::Bigquery::Project, dataset: dataset) }
    let(:dataset) { instance_double(Google::Cloud::Bigquery::Dataset, table: table) }
    let(:table) { instance_double(Google::Cloud::Bigquery::Table) }
    let(:response) { instance_double('response', success?: true) }

    before do
      allow(Google::Cloud::Bigquery).to receive(:new).and_return(project)
      allow(table).to receive(:insert).and_return(response)
    end

    context 'when the request is successful' do
      it 'sends the events JSON to Bigquery' do
        ClimateControl.modify(BIG_QUERY_PROJECT_ID: 'bat-apply-test', BIG_QUERY_DATASET: 'bat-apply-test-events') do
          described_class.new.perform([request_event.as_json])

          expect(table).to have_received(:insert).with([request_event.as_json])
        end
      end
    end

    context 'when the request is unsuccessful' do
      let(:response) { instance_double('response', success?: false) }

      before do
        allow(Sentry).to receive(:capture_message)
      end

      it 'posts the response and request details to Sentry' do
        ClimateControl.modify(BIG_QUERY_PROJECT_ID: 'bat-apply-test', BIG_QUERY_DATASET: 'bat-apply-test-events') do
          described_class.new.perform([request_event.as_json])

          expect(table).to have_received(:insert).with([request_event.as_json])
          expect(Sentry).to have_received(:capture_message).with("SendEventsToBigquery: #{response} data: #{[request_event.as_json]}")
        end
      end
    end
  end
end
