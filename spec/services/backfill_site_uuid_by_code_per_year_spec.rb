require 'rails_helper'

RSpec.describe BackfillSiteUuidByCodePerYear do
  include TeacherTrainingPublicAPIHelper
  describe 'call' do
    context 'when run for current year' do
      let!(:provider){ create(:provider)}
      let!(:course){ create(:course, provider: provider)}
      let!(:course_option) { create(:course_option, course: course, site: site_from_apply)}
      let!(:site_from_apply){ create(:site, provider: provider, name: 'James Site')}
      it 'puts uuids on sites in the current year' do
        uuid = SecureRandom.uuid
        stub_teacher_training_api_sites(provider_code: provider.code,
                                        course_code: course.code,
                                        recruitment_cycle_year: RecruitmentCycle.current_year,
                                        specified_attributes: [code: site_from_apply.code, uuid: uuid])

        described_class.new(RecruitmentCycle.current_year, provider, course).call
        expect(site_from_apply.reload.uuid).to eq(uuid)
      end
    end
    context 'when run for previous year' do
      let!(:provider){ create(:provider)}
      let!(:course){ create(:course, provider: provider, recruitment_cycle_year: RecruitmentCycle.previous_year)}
      let!(:course_option) { create(:course_option, course: course, site: site_from_apply)}
      let!(:site_from_apply){ create(:site, provider: provider, name: 'James Site')}
      it 'puts duplicates sites from precious years and assigns uuids to them' do
        uuid = SecureRandom.uuid
        stub_teacher_training_api_sites(provider_code: provider.code,
                                        course_code: course.code,
                                        recruitment_cycle_year: RecruitmentCycle.previous_year,
                                        specified_attributes: [code: site_from_apply.code, uuid: uuid])

        described_class.new(RecruitmentCycle.previous_year, provider, course).call
        expect(Site.where(code: site_from_apply.code, provider: provider).count).to eq(2)
        expect(Site.where(code: site_from_apply.code, provider: provider, uuid: uuid).count).to eq(1)
      end
    end
  end
end
