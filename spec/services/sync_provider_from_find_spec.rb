require 'rails_helper'

RSpec.describe SyncProviderFromFind do
  include FindAPIHelper

  describe '.call' do
    context 'ingesting a brand new provider' do
      it 'just creates the provider without any courses' do
        SyncProviderFromFind.call(provider_name: 'ABC College', provider_code: 'ABC')

        provider = Provider.find_by_code('ABC')
        expect(provider).to be_present
        expect(provider.courses).to be_blank
      end
    end

    context 'ingesting an existing provider not configured to sync courses' do
      before do
        @existing_provider = create :provider, code: 'ABC', sync_courses: false, name: 'Foobar College'
      end

      it 'correctly updates the provider but does not import any courses' do
        stub_find_api_provider_200(provider_code: 'ABC', findable: true)

        SyncProviderFromFind.call(provider_name: 'ABC College', provider_code: 'ABC')

        expect(@existing_provider.reload.courses).to be_blank
        expect(@existing_provider.reload.name).to eq 'ABC College'
      end
    end

    context 'ingesting an existing provider configured to sync courses, sites and course_options' do
      before do
        @existing_provider = create :provider, code: 'ABC', sync_courses: true
      end

      it 'correctly creates all the entities' do
        stub_find_api_provider_200(
          provider_code: 'ABC',
          course_code: '9CBA',
          findable: true,
        )

        SyncProviderFromFind.call(provider_name: 'ABC College', provider_code: 'ABC')

        course_option = CourseOption.last
        expect(course_option.course.provider.code).to eq 'ABC'
        expect(course_option.course.code).to eq '9CBA'
        expect(course_option.course.exposed_in_find).to be true
        expect(course_option.course.recruitment_cycle_year).to be FindAPI::RECRUITMENT_CYCLE_YEAR
        expect(course_option.course.description).to eq 'PGCE with QTS full time'
        expect(course_option.course.start_date).to eq Time.zone.local(2020, 10, 31)
        expect(course_option.course.course_length).to eq 'OneYear'
        expect(course_option.site.name).to eq 'Main site'
        expect(course_option.site.address_line1).to eq 'Gorse SCITT'
        expect(course_option.site.address_line2).to eq 'C/O The Bruntcliffe Academy'
        expect(course_option.site.address_line3).to eq 'Bruntcliffe Lane'
        expect(course_option.site.address_line4).to eq 'MORLEY, LEEDS'
        expect(course_option.site.postcode).to eq 'LS27 0LZ'
        expect(course_option.vacancy_status).to eq 'vacancies'
      end

      it 'correctly handles missing address info' do
        stub_find_api_provider_200(
          provider_code: 'ABC',
          course_code: '9CBA',
          findable: true,
          site_address_line2: nil,
        )

        SyncProviderFromFind.call(provider_name: 'ABC College', provider_code: 'ABC')

        course_option = CourseOption.last
        expect(course_option.course.provider.code).to eq 'ABC'
        expect(course_option.course.code).to eq '9CBA'
        expect(course_option.course.exposed_in_find).to be true
        expect(course_option.course.recruitment_cycle_year).to be FindAPI::RECRUITMENT_CYCLE_YEAR
        expect(course_option.site.name).to eq 'Main site'
        expect(course_option.site.address_line1).to eq 'Gorse SCITT'
        expect(course_option.site.address_line2).to be_nil
        expect(course_option.site.address_line3).to eq 'Bruntcliffe Lane'
        expect(course_option.site.address_line4).to eq 'MORLEY, LEEDS'
        expect(course_option.site.postcode).to eq 'LS27 0LZ'
      end

      it 'correctly updates vacancy status for any existing course options' do
        stub_find_api_provider_200(
          provider_code: 'ABC',
          course_code: '9CBA',
          findable: true,
        )
        SyncProviderFromFind.call(provider_name: 'ABC College', provider_code: 'ABC')
        expect(CourseOption.count).to eq 1
        CourseOption.first.update!(vacancy_status: 'no_vacancies')

        SyncProviderFromFind.call(provider_name: 'ABC College', provider_code: 'ABC')
        expect(CourseOption.count).to eq 1
        expect(CourseOption.first.vacancy_status).to eq 'vacancies'
      end

      it 'correctly handles accrediting providers' do
        stub_find_api_provider_200_with_accrediting_provider(
          provider_code: 'ABC',
          course_code: '9CBA',
          study_mode: 'full_time',
          accrediting_provider_code: 'DEF',
          accrediting_provider_name: 'Test Accrediting Provider',
        )

        SyncProviderFromFind.call(provider_name: 'ABC College', provider_code: 'ABC')

        course_option = CourseOption.last
        expect(course_option.course.accrediting_provider.code).to eq 'DEF'
        expect(course_option.course.accrediting_provider.name).to eq 'Test Accrediting Provider'
      end

      it 'stores full_time/part_time information within courses' do
        stub_find_api_provider_200_with_accrediting_provider(
          provider_code: 'ABC',
          course_code: '9CBA',
          study_mode: 'full_time_or_part_time',
        )

        SyncProviderFromFind.call(provider_name: 'ABC College', provider_code: 'ABC')

        course = Provider.find_by_code('ABC').courses.find_by_code('9CBA')
        expect(course.study_mode).to eq 'full_time_or_part_time'
      end

      it 'creates the correct number of course_options for sites and study_mode' do
        stub_find_api_provider_200_with_multiple_sites(
          provider_code: 'ABC',
          course_code: '9CBA',
          study_mode: 'full_time_or_part_time',
        )

        SyncProviderFromFind.call(provider_name: 'ABC College', provider_code: 'ABC')

        provider = Provider.find_by_code('ABC')
        course_options = provider.courses.find_by_code('9CBA').course_options

        expect(course_options.count).to eq 4
        provider.sites.each do |site|
          modes_for_site = course_options.where(site_id: site.id).pluck(:study_mode)
          expect(modes_for_site).to match_array %w[full_time part_time]
        end
      end

      it 'correctly updates the Provider#region_code' do
        stub_find_api_provider_200(
          provider_code: 'ABC',
          course_code: '9CBA',
          findable: true,
        )

        SyncProviderFromFind.call(provider_name: 'ABC College', provider_code: 'ABC')

        expect(@existing_provider.reload.region_code).to eq 'north_west'
      end
    end
  end

  describe 'CourseVacancyStatus#derive' do
    context 'when study_mode is part_time' do
      let(:study_mode) { 'part_time' }

      [
        { description: 'no_vacancies', vacancy_status: :no_vacancies },
        { description: 'both_full_time_and_part_time_vacancies', vacancy_status: :vacancies },
        { description: 'full_time_vacancies', vacancy_status: :no_vacancies },
        { description: 'part_time_vacancies', vacancy_status: :vacancies },
      ].each do |pair|
        it "returns #{pair[:vacancy_status]} when description is #{pair[:description]}" do
          derived_status = SyncProviderFromFind::CourseVacancyStatus.new(
            pair[:description],
            study_mode,
          ).derive

          expect(derived_status).to eq pair[:vacancy_status]
        end
      end

      it 'raises an error when description is an unexpected value' do
        expect {
          SyncProviderFromFind::CourseVacancyStatus.new('foo', study_mode).derive
        }.to raise_error(
          SyncProviderFromFind::CourseVacancyStatus::InvalidFindStatusDescriptionError,
        )
      end
    end

    context 'when study_mode is full_time' do
      let(:study_mode) { 'full_time' }

      [
        { description: 'no_vacancies', vacancy_status: :no_vacancies },
        { description: 'both_full_time_and_part_time_vacancies', vacancy_status: :vacancies },
        { description: 'full_time_vacancies', vacancy_status: :vacancies },
        { description: 'part_time_vacancies', vacancy_status: :no_vacancies },
      ].each do |pair|
        it "returns #{pair[:vacancy_status]} when description is #{pair[:description]}" do
          derived_status = SyncProviderFromFind::CourseVacancyStatus.new(
            pair[:description],
            study_mode,
          ).derive

          expect(derived_status).to eq pair[:vacancy_status]
        end
      end

      it 'raises an error when description is an unexpected value' do
        expect {
          SyncProviderFromFind::CourseVacancyStatus.new('foo', study_mode).derive
        }.to raise_error(
          SyncProviderFromFind::CourseVacancyStatus::InvalidFindStatusDescriptionError,
        )
      end
    end
  end
end
