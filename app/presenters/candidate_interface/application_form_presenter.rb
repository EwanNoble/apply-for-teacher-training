module CandidateInterface
  class ApplicationFormPresenter
    ErrorMessage = Struct.new(:message, :anchor)

    attr_reader :application_form

    delegate :apply_2?,
             :cache_key_with_version,
             :candidate_has_previously_applied?,
             :english_main_language,
             :first_name,
             :first_nationality,
             :previous_application_form,
             :phase,
             :personal_details_completed,
             :support_reference, to: :application_form

    def initialize(application_form)
      @application_form = application_form
    end

    def updated_at
      "Last saved on #{application_form.updated_at.to_s(:govuk_date_and_time)}"
    end

    def sections_with_completion
      [
        # "Courses" section
        [:course_choices, course_choices_completed?],

        # "About you" section
        [:personal_details, personal_details_completed?],
        [:contact_details, contact_details_completed?],
        [:training_with_a_disability, training_with_a_disability_completed?],
        [:work_experience, work_experience_completed?],
        [:volunteering, volunteering_completed?],
        [:safeguarding, safeguarding_completed?],

        # "Qualifications" section
        [:degrees, degrees_completed?],
        [:maths_gcse, maths_gcse_completed?],
        [:english_gcse, english_gcse_completed?],
        ([:science_gcse, science_gcse_completed?] if application_form.science_gcse_needed?),
        [:other_qualifications, other_qualifications_completed?],
        ([:efl, english_as_a_foreign_language_completed?] if display_efl_link?),

        # "Personal statement and interview" section
        [:becoming_a_teacher, becoming_a_teacher_completed?, becoming_a_teacher_review_pending?],
        [:subject_knowledge, subject_knowledge_completed?, subject_knowledge_review_pending?],
        [:interview_preferences, interview_preferences_completed?],

        # "References" section
        references_section_definition,
      ].compact
    end

    def references_section_definition
      [:references_selected, references_completed?]
    end

    def incomplete_sections
      section_structs = sections_with_completion
                          .reject(&:second)
                          .map do |sections_with_completion|
                            if sections_with_completion.first == :other_qualifications && application_form.international_applicant?
                              Struct.new(:name, :needs_review?).new(:other_qualifications_international, false)
                            else
                              Struct.new(:name, :needs_review?).new(sections_with_completion.first, sections_with_completion.third)
                            end
                          end

      section_structs.map do |section|
        message = section.needs_review? ? "review_application.#{section.name}.not_reviewed" : "review_application.#{section.name}.incomplete"
        Struct.new(:name, :message).new(section.name, message)
      end
    end

    ApplicationChoiceError = Struct.new(:message, :course_choice_id) do
      def anchor
        "#course-choice-#{course_choice_id}"
      end
    end

    def application_choice_errors
      [].tap do |error_list|
        application_form.application_choices.each do |choice|
          if choice.course_not_available?
            error_list << ApplicationChoiceError.new(
              choice.course_not_available_error, choice.id
            )
            next
          end

          if choice.course_closed_on_apply?
            error_list << ApplicationChoiceError.new(
              choice.course_closed_on_apply_error, choice.id
            )
            next
          end

          if choice.course_full?
            error_list << ApplicationChoiceError.new(
              choice.course_full_error, choice.id
            )
            next
          end

          if choice.site_full?
            error_list << ApplicationChoiceError.new(
              choice.site_full_error, choice.id
            )
            next
          end
          if choice.site_invalid?
            error_list << ApplicationChoiceError.new(
              choice.site_invalid_error, choice.id
            )
            next
          end

          next unless choice.study_mode_full?

          error_list << ApplicationChoiceError.new(
            choice.study_mode_full_error, choice.id
          )
        end
      end
    end

    def reference_section_errors
      [].tap do |errors|
        # A defensive check, in case the candidate somehow ends up in this state
        if application_form.references_completed? && application_form.selected_incorrect_number_of_references?
          errors << ErrorMessage.new(I18n.t('application_form.references.review.incorrect_number_selected'), '#references')
        end
      end
    end

    def ready_to_submit?
      sections_with_completion.map(&:second).all? &&
        application_choice_errors.empty? &&
        reference_section_errors.empty?
    end

    def application_choices_added?
      application_form.application_choices.present?
    end

    delegate :personal_details_completed?, to: :application_form

    def contact_details_completed?
      application_form.contact_details_completed
    end

    def contact_details_valid?
      form = ContactDetailsForm.build_from_application(application_form)
      form.valid?(:base) && form.valid?(:address) && form.valid?(:address_type)
    end

    def work_experience_completed?
      application_form.work_history_completed
    end

    def references_link_text
      if application_form.application_references.present?
        I18n.t('section_items.manage_references')
      else
        I18n.t('section_items.add_references')
      end
    end

    def references_selection_path
      if application_form.application_references.includes(:application_form).selected.count >= 2
        Rails.application.routes.url_helpers.candidate_interface_review_selected_references_path
      else
        Rails.application.routes.url_helpers.candidate_interface_select_references_path
      end
    end

    def work_experience_path(params = nil)
      if application_form.feature_restructured_work_history
        if application_form.application_work_experiences.any? || application_form.work_history_explanation.present?
          Rails.application.routes.url_helpers.candidate_interface_restructured_work_history_review_path(params)
        else
          Rails.application.routes.url_helpers.candidate_interface_restructured_work_history_path(params)
        end
      elsif application_form.application_work_experiences.any? || application_form.work_history_explanation.present?
        Rails.application.routes.url_helpers.candidate_interface_work_history_show_path(params)
      else
        Rails.application.routes.url_helpers.candidate_interface_work_history_length_path(params)
      end
    end

    def degrees_path
      if degrees_completed? || degrees_added?
        Rails.application.routes.url_helpers.candidate_interface_degrees_review_path
      else
        Rails.application.routes.url_helpers.candidate_interface_new_degree_path
      end
    end

    def other_qualification_path
      if other_qualifications_completed? || other_qualifications_added? || application_form.no_other_qualifications
        Rails.application.routes.url_helpers.candidate_interface_review_other_qualifications_path
      else
        Rails.application.routes.url_helpers.candidate_interface_other_qualification_type_path
      end
    end

    def english_as_a_foreign_language_path
      if application_form.english_proficiency.present?
        Rails.application.routes.url_helpers.candidate_interface_english_foreign_language_review_path
      else
        Rails.application.routes.url_helpers.candidate_interface_english_foreign_language_start_path
      end
    end

    def volunteering_path
      if show_review_volunteering?
        Rails.application.routes.url_helpers.candidate_interface_review_volunteering_path
      else
        Rails.application.routes.url_helpers.candidate_interface_volunteering_experience_path
      end
    end

    def degrees_completed?
      application_form.degrees_completed
    end

    def degrees_added?
      application_form.application_qualifications.degrees.any?
    end

    def maths_gcse_completed?
      application_form.maths_gcse_completed
    end

    def maths_gcse_added?
      application_form.maths_gcse.present?
    end

    def english_gcse_completed?
      application_form.english_gcse_completed
    end

    def english_gcse_added?
      application_form.english_gcse.present?
    end

    def science_gcse_completed?
      application_form.science_gcse_completed
    end

    def science_gcse_added?
      application_form.science_gcse.present?
    end

    def other_qualifications_completed?
      application_form.other_qualifications_completed && no_incomplete_qualifications?
    end

    def other_qualifications_added?
      application_form.application_qualifications.other.any?
    end

    def english_as_a_foreign_language_completed?
      application_form.efl_completed?
    end

    def becoming_a_teacher_completed?
      application_form.becoming_a_teacher_completed
    end

    def becoming_a_teacher_valid?
      BecomingATeacherForm.build_from_application(application_form).valid?
    end

    def becoming_a_teacher_path
      if becoming_a_teacher_valid?
        Rails.application.routes.url_helpers.candidate_interface_becoming_a_teacher_show_path
      else
        Rails.application.routes.url_helpers.candidate_interface_new_becoming_a_teacher_path
      end
    end

    def becoming_a_teacher_review_pending?
      application_form.review_pending?(:becoming_a_teacher)
    end

    def subject_knowledge_completed?
      application_form.subject_knowledge_completed
    end

    def subject_knowledge_valid?
      SubjectKnowledgeForm.build_from_application(application_form).valid?
    end

    def subject_knowledge_path
      if subject_knowledge_valid?
        Rails.application.routes.url_helpers.candidate_interface_subject_knowledge_show_path
      else
        Rails.application.routes.url_helpers.candidate_interface_new_subject_knowledge_path
      end
    end

    def subject_knowledge_review_pending?
      application_form.review_pending?(:subject_knowledge)
    end

    def interview_preferences_completed?
      application_form.interview_preferences_completed
    end

    def interview_preferences_valid?
      InterviewPreferencesForm.build_from_application(application_form).valid?
    end

    def training_with_a_disability_completed?
      application_form.training_with_a_disability_completed
    end

    def training_with_a_disability_valid?
      TrainingWithADisabilityForm.build_from_application(application_form).valid?
    end

    def course_choices_completed?
      application_form.course_choices_completed
    end

    def volunteering_completed?
      application_form.volunteering_completed
    end

    def volunteering_added?
      application_form.application_volunteering_experiences.any?
    end

    def references_completed?
      application_form.references_completed
    end

    def safeguarding_completed?
      application_form.safeguarding_issues_completed
    end

    def safeguarding_valid?
      SafeguardingIssuesDeclarationForm.build_from_application(application_form).valid?
    end

    def no_incomplete_qualifications?
      application_form.application_qualifications.other.select(&:incomplete_other_qualification?).blank?
    end

    def display_efl_link?
      application_form.international_applicant?
    end

    def references
      application_form.application_references.includes(:application_form)
    end

    def previous_application_choices_rejected?
      application_form.previous_application_form.application_choices.rejected.any?
    end

    def right_to_work_or_study_present?
      application_form.right_to_work_or_study.present?
    end

  private

    def show_review_volunteering?
      no_volunteering_confirmed = application_form.volunteering_experience == false && application_form.application_volunteering_experiences.empty?

      volunteering_completed? || volunteering_added? || no_volunteering_confirmed
    end

    def gcse_completed?(gcse)
      if gcse.present?
        return gcse.grade.present? && gcse.award_year.present? unless gcse.qualification_type == 'missing'

        true
      end
    end
  end
end
