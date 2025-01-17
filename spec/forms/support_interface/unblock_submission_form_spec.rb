require 'rails_helper'

RSpec.describe SupportInterface::UnblockSubmissionForm, type: :model do
  let(:fraud_match) { create(:fraud_match, blocked: true, fraudulent: true) }
  let(:first_application) { create(:application_form, candidate: fraud_match.candidates.first, first_name: 'Jeffrey', submitted_at: Time.zone.now) }
  let(:second_application) { create(:application_form, candidate: fraud_match.candidates.second, first_name: 'Geoffrey') }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:accept_guidance) }
  end

  describe '#save' do
    it 'unblocks the candidate after being blocked' do
      candidate_to_block = described_class.new({ accept_guidance: true })

      expect(candidate_to_block.save(fraud_match.id)).to eq true

      fraud_match.reload

      expect(fraud_match.blocked).to eq false
      expect(fraud_match.fraudulent).to eq false
    end
  end
end
