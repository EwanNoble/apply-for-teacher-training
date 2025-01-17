require 'rails_helper'

RSpec.describe SupportInterface::ExternalReportApplicationsExport do
  describe '#call' do
    it 'generates the full report with the correct totals' do
      hash = create_base_hash_with_key

      generate_test_data_for_hash
      hash = add_test_data_to_hash(hash)
      generate_deferred_offer

      expected_output = remove_key_from_hash(hash).sort
      output = described_class.new.data_for_export.sort

      expected_output_with_empty_rows_removed = expected_output.reject { |row| row['Total'].zero? }
      output_with_empty_rows_removed = output.reject { |row| row['Total'].zero? }

      expect(output_with_empty_rows_removed).to eq(expected_output_with_empty_rows_removed)
    end

  private

    def create_base_hash_with_key
      hash = {}

      ExternalReportApplications::COURSE_TYPES.each do |course_type|
        ExternalReportApplications::PRIMARY_SUBJECTS.each do |subject|
          ExternalReportApplications::PROVIDER_AREAS.each do |provider_area|
            hash[construct_key(course_type, ExternalReportApplications::PRIMARY_AGE_GROUP, subject, provider_area)] = {
              'Course type' => course_type,
              'Age group' => ExternalReportApplications::PRIMARY_AGE_GROUP,
              'Subject' => subject,
              'Provider area' => provider_area,
              'Total' => 0,
            }
          end
        end

        ExternalReportApplications::SECONDARY_SUBJECTS.each do |subject|
          ExternalReportApplications::PROVIDER_AREAS.each do |provider_area|
            hash[construct_key(course_type, ExternalReportApplications::SECONDARY_AGE_GROUP, subject, provider_area)] = {
              'Course type' => course_type,
              'Age group' => ExternalReportApplications::SECONDARY_AGE_GROUP,
              'Subject' => subject,
              'Provider area' => provider_area,
              'Total' => 0,
            }
          end
        end

        ExternalReportApplications::PROVIDER_AREAS.each do |provider_area|
          hash[construct_key(course_type, ExternalReportApplications::FURTHER_EDUCATION_AGE_GROUP, ExternalReportApplications::FURTHER_EDUCATION_SUBJECT, provider_area)] = {
            'Course type' => course_type,
            'Age group' => ExternalReportApplications::FURTHER_EDUCATION_AGE_GROUP,
            'Subject' => ExternalReportApplications::FURTHER_EDUCATION_SUBJECT,
            'Provider area' => provider_area,
            'Total' => 0,
          }
        end
      end

      hash
    end

    def generate_test_data_for_hash
      create_subjects

      region = Provider.region_codes.keys.reject { |key| %w[no_region wales scotland].include?(key) }.sample
      statuses = ApplicationChoice.statuses.keys.reject { |status| %w[unsubmitted cancelled application_not_sent offer_deferred].include?(status) }

      ExternalReportApplications::PRIMARY_SUBJECTS.each do |subject|
        persisted_subject = Subject.find_by!(name: subject)
        provider = create(:provider, region_code: region)

        course = create(:course,
                        provider: provider,
                        subjects: [persisted_subject],
                        program_type: Course.program_types.keys.sample,
                        level: 'primary')

        course_option = create(:course_option, course: course)

        create(:application_choice, :with_completed_application_form, status: statuses.sample, course_option: course_option)
      end

      (ExternalReportApplications::SECONDARY_SUBJECTS + ExternalReportApplications::LANGUAGE_SUBJECTS).each do |subject|
        subject = 'Art and design' if subject == 'Art, or Art and design'

        persisted_subject = Subject.find_by!(name: subject)
        provider = create(:provider, region_code: region)

        course = create(:course,
                        provider: provider,
                        subjects: [persisted_subject],
                        program_type: Course.program_types.keys.sample,
                        level: 'secondary')

        course_option = create(:course_option, course: course)

        create(:application_choice, :with_completed_application_form, status: statuses.sample, course_option: course_option)
      end

      further_education_subject = Subject.find_by!(name: ExternalReportApplications::FURTHER_EDUCATION_SUBJECT)
      provider = create(:provider, region_code: region)

      course = create(:course,
                      provider: provider,
                      subjects: [further_education_subject],
                      program_type: Course.program_types.keys.sample,
                      level: 'further_education')

      course_option = create(:course_option, course: course)

      create(
        :application_choice,
        :with_deferred_offer,
        course_option: course_option,
        application_form: create(:completed_application_form, recruitment_cycle_year: RecruitmentCycle.previous_year),
      )
    end

    def add_test_data_to_hash(hash)
      ApplicationChoice.includes(course: :subjects, site: :provider).each do |application_choice|
        hash[construct_key(
          ExternalReportApplications::COURSE_TYPE_MAPPING[application_choice.course.program_type],
          ExternalReportApplications::AGE_GROUP_MAPPING[application_choice.course.level],
          ExternalReportApplications::SUBJECTS_MAPPING[application_choice.course.subjects.first.name],
          ExternalReportApplications::PROVIDER_AREAS_MAPPING[application_choice.provider.region_code],
        )]['Total'] += 1
      end

      hash
    end

    def generate_deferred_offer
      further_education_subject = Subject.find_by!(name: ExternalReportApplications::FURTHER_EDUCATION_SUBJECT)

      course = create(:course,
                      subjects: [further_education_subject],
                      program_type: Course.program_types.keys.sample,
                      level: 'further_education')

      course_option = create(:course_option, course: course)

      create(
        :application_choice,
        :with_deferred_offer,
        :with_completed_application_form,
        course_option: course_option,
      )
    end

    def construct_key(program_type, level, subject_name, provider_area)
      "#{program_type},#{level},#{subject_name},#{provider_area}"
    end

    def create_subjects
      (Subjects::PRIMARY_SUBJECT_NAMES + Subjects::SECONDARY_SUBJECT_NAMES)
       .each { |subject_name| create(:subject, name: subject_name) }
    end

    def remove_key_from_hash(hash)
      hash.values
    end
  end
end
