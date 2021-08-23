class ApplicationsExport
  def self.call
    @csv_data = GetApplicationChoicesForProviders
      .call(
        providers: [Provider.find(1)],
        includes: [
          :provider,
          :accredited_provider,
          :site,
          :current_site,
          :current_provider,
          :current_accredited_provider,
          course: %i[provider accredited_provider],
          course_option: %i[course site],
          current_course: %i[provider accredited_provider],
          current_course_option: %i[course site],
          application_form: %i[candidate english_proficiency application_qualifications],
        ],
      )
      .joins("INNER JOIN application_qualifications gcses ON gcses.application_form_id = application_forms.id AND gcses.level = 'gcse'")
      .joins("INNER JOIN application_qualifications degrees ON degrees.application_form_id = application_forms.id AND degrees.level = 'degree'")
      .where('courses.recruitment_cycle_year' => '2021')
      .where(status: %w[awaiting_provider_decision interviewing recruited deferred rejected])
      .where('candidates.hide_in_reporting': false)
      .pluck(
        'application_choices.id AS application_choice_id',
        'candidates.id AS candidate_id',
        'application_forms.support_reference AS support_reference',
        'application_choices.status AS status',
        'application_forms.submitted_at AS submitted_at',
        'application_choices.updated_at AS updated_at',
        'application_choices.recruited_at AS recruited_at',
        'application_choices.rejection_reason AS rejection_reason',
        'application_choices.rejected_at AS rejected_at',
        'application_choices.reject_by_default_at AS reject_by_default_at',
        'application_forms.first_name AS first_name',
        'application_forms.last_name AS last_name',
        'application_forms.date_of_birth AS date_of_birth',
        'application_forms.country AS domicile',
        'application_forms.uk_residency_status AS uk_residency_status',
        'application_forms.english_main_language AS english_main_language',
        'candidates.email_address AS email',
        'application_forms.phone_number AS phone_number',
        'application_forms.address_line1 AS address_line1',
        'application_forms.address_line2 AS address_line2',
        'application_forms.address_line3 AS address_line3',
        'application_forms.address_line4 AS address_line4',
        'application_forms.postcode AS postcode',
        'application_forms.country AS country',
        'application_forms.recruitment_cycle_year AS recruitment_cycle_year',
        'application_forms.degrees_completed AS degrees_completed_flag',
        'degrees.qualification_type AS qualification_type',
        'degrees.non_uk_qualification_type AS non_uk_qualification_type',
        'degrees.subject AS subject',
        'degrees.grade AS grade',
        'degrees.start_year AS start_year',
        'degrees.award_year AS award_year',
        'degrees.institution_name AS institution_details',
        'application_forms.disability_disclosure AS disability_disclosure'
      )
  end
end
