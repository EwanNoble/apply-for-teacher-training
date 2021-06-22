require 'rails_helper'

RSpec.describe SummerRecruitmentBanner do
  before { FeatureFlag.activate('summer_recruitment_banner') }

  subject(:result) { render_inline(SummerRecruitmentBanner.new) }

  context 'when the provider information banner feature flag is on' do
    it 'renders the banner title' do
      expect(result.text).to include('Summer Recruitment')
    end

    it 'renders the banner header' do
      expect(result.text).to include('Header content')
    end

    it 'renders the banner content' do
      expect(result.text).to include('Body content')
    end
  end

  context 'when the provider information banner feature flag is off' do
    it 'does not render the banner' do
      FeatureFlag.deactivate('summer_recruitment_banner')

      expect(result.text).to be_empty
    end
  end
end
