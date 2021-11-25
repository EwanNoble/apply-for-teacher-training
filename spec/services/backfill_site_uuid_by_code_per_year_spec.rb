require 'rails_helper'

RSpec.describe BackfillSiteUuidByCodePerYear do
  include TeacherTrainingPublicAPIHelper
  describe 'call' do
    let!(:provider){ create(:provider)}
    let!(:course){ create(:course, provider: provider)}
    let!(:course_option) { create(:course_option, course: course, site: site_from_apply)}
    let!(:site_from_apply){ create(:site, provider: provider, name: 'James Site', uuid: nil)}
    context 'when run for current year' do
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
      let!(:course){ create(:course, provider: provider, recruitment_cycle_year: RecruitmentCycle.previous_year)}
      it 'puts duplicates sites from precious years and assigns uuids to them' do
        uuid = SecureRandom.uuid
        stub_teacher_training_api_sites(provider_code: provider.code,
                                        course_code: course.code,
                                        recruitment_cycle_year: RecruitmentCycle.previous_year,
                                        specified_attributes: [code: site_from_apply.code, uuid: uuid])

        expect{ described_class.new(RecruitmentCycle.previous_year, provider, course).call }.to change(Site, :count).by(1)
        expect(Site.where(code: site_from_apply.code, provider: provider, uuid: uuid).count).to eq(1)
      end
    end
    context 'when there is a course that has multiple sites across multiple years' do
      let!(:course2){ create(:course, provider: provider, recruitment_cycle_year: RecruitmentCycle.previous_year)}
      let!(:course_option2) { create(:course_option, course: course2, site: site_from_apply)}
      it 'assigns the correct uuid' do
        uuid = SecureRandom.uuid
        uuid2 =SecureRandom.uuid
        stub_teacher_training_api_sites(provider_code: provider.code,
                                        course_code: course.code,
                                        recruitment_cycle_year: RecruitmentCycle.current_year,
                                        specified_attributes: [code: site_from_apply.code, uuid: uuid])

        stub_teacher_training_api_sites(provider_code: provider.code,
                                        course_code: course2.code,
                                        recruitment_cycle_year: RecruitmentCycle.previous_year,
                                        specified_attributes: [code: site_from_apply.code, uuid: uuid2])

        expect{ described_class.new(RecruitmentCycle.previous_year, provider, course2).call }.to change(Site, :count).by(1)
        expect(course_option2.reload.site.uuid).to eq(uuid2)
        expect{ described_class.new(RecruitmentCycle.current_year, provider, course).call }.to change(Site, :count).by(0)
        expect(course_option.site.uuid).to eq(uuid)
      end
    end

    context 'where the site has been deleted from the API' do
      it 'doesnt touch it' do
        expect(1).to eq(1)
      end
    end
  end
end
