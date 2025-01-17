require 'rails_helper'

RSpec.describe LookupAreaByPostcodeWorker do
  let(:api) { instance_double(Postcodes::IO) }
  let(:result) { double }
  let(:application_form) { create :application_form, postcode: 'SW1A 1AA' }

  before do
    allow(Postcodes::IO).to receive(:new).and_return(api)
    allow(api).to receive(:lookup).and_return(result)
  end

  context 'with `region_from_postcode` feature flag inactive' do
    before do
      FeatureFlag.deactivate(:region_from_postcode)
    end

    context 'when the API returns an English region' do
      it 'updates the region code' do
        described_class.new.perform(application_form.id)
        expect(application_form.reload.region_code).to be_nil
        expect(api).not_to have_received(:lookup)
      end
    end
  end

  context 'with `region_from_postcode` feature flag active' do
    before do
      FeatureFlag.activate(:region_from_postcode)
    end

    context 'when the API returns an English region' do
      before do
        allow(result).to receive(:region).and_return('South West')
        allow(result).to receive(:country).and_return('England')
      end

      it 'updates the region code' do
        described_class.new.perform(application_form.id)
        expect(application_form.reload.region_code).to eq('south_west')
      end
    end

    context 'when the API returns Scotland' do
      before do
        allow(result).to receive(:region).and_return(nil)
        allow(result).to receive(:country).and_return('Scotland')
      end

      it 'updates the region code' do
        described_class.new.perform(application_form.id)
        expect(application_form.reload.region_code).to eq('scotland')
      end
    end
  end
end
