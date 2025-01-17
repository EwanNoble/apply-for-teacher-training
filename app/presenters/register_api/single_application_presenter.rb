module RegisterAPI
  class SingleApplicationPresenter
    include CandidateAPIData
    include ContactDetailsAPIData
    include QualificationAPIData

    def initialize(application_choice)
      @application_choice = ApplicationChoiceExportDecorator.new(application_choice)
      @application_form = application_choice.application_form
    end

    def as_json
      {
        id: application_choice.id.to_s,
        type: 'application',
        attributes: {
          support_reference: application_form.support_reference,
          status: status, # keep to show offer withdrawn and deferred
          updated_at: application_choice.updated_at.iso8601,
          submitted_at: application_form.submitted_at.iso8601,
          recruited_at: application_choice.recruited_at.iso8601,
          candidate: candidate_data_for_register,
          contact_details: contact_details,
          course: course_info_for(application_choice.current_course_option),
          qualifications: qualifications,
          hesa_itt_data: hesa_itt_data.presence,
        },
      }
    end

  private

    attr_reader :application_choice, :application_form

    def candidate_data_for_register
      candidate.merge({ gender: equality_and_diversity_data['sex'],
                        disabilities: equality_and_diversity_data['disabilities'].presence || [],
                        ethnic_group: equality_and_diversity_data['ethnic_group'],
                        ethnic_background: equality_and_diversity_data['ethnic_background'] })
    end

    def status
      application_choice.status
    end

    def course_info_for(course_option)
      {
        recruitment_cycle_year: course_option.course.recruitment_cycle_year,
        course_code: course_option.course.code,
        course_uuid: course_option.course.uuid,
        training_provider_code: course_option.course.provider.code,
        training_provider_type: course_option.course.provider.provider_type,
        accredited_provider_type: course_option.course.accredited_provider&.provider_type,
        accredited_provider_code: course_option.course.accredited_provider&.code,
        site_code: course_option.site.code,
        study_mode: course_option.study_mode,
      }
    end

    def structured_gcse_to_hashes(gcse)
      constituent_grades = gcse[:constituent_grades]
      constituent_grades.reduce([]) do |array, (subject, hash)|
        array << qualification_to_hash(gcse)
                     .merge(subject: subject.humanize, grade: hash['grade'], id: hash['public_id'])
      end
    end

    def qualification_to_hash(qualification)
      {
        id: qualification.public_id,
        qualification_type: qualification.qualification_type,
        non_uk_qualification_type: qualification.non_uk_qualification_type,
        subject: qualification.subject,
        grade: grade_details(qualification),
        start_year: qualification.start_year,
        award_year: qualification.award_year,
        institution_details: institution_details(qualification),
        equivalency_details: qualification.composite_equivalency_details,
        comparable_uk_degree: qualification.comparable_uk_degree,
      }.merge HesaQualificationFieldsPresenter.new(qualification).to_hash
    end

    def hesa_itt_data
      if equality_and_diversity_data.present?
        {
          sex: equality_and_diversity_data['hesa_sex'],
          disability: equality_and_diversity_data['hesa_disabilities'],
          ethnicity: equality_and_diversity_data['hesa_ethnicity'],
        }
      end
    end

    def equality_and_diversity_data
      application_form.equality_and_diversity || {}
    end
  end
end
