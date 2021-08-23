module ProviderInterface
  class ApplicationDataExportController < ProviderInterfaceController
    before_action :redirect_to_hesa_export_unless_feature_enabled

    def new
      @application_data_export_form = ApplicationDataExportForm.new(current_provider_user: current_provider_user)
    end

    def export
      @application_data_export_form = ApplicationDataExportForm.new(application_data_export_params.merge({ current_provider_user: current_provider_user }))

      if @application_data_export_form.valid?
        providers = @application_data_export_form.selected_providers
        cycle_years = @application_data_export_form.selected_years
        statuses = @application_data_export_form.selected_statuses
        fields = [
          'application_choices.id',
          Arel.sql("CONCAT('C', candidates.id)"),
          'application_forms.support_reference',
          'application_choices.status',
          'application_forms.submitted_at',
          'application_choices.updated_at',
          'application_choices.recruited_at',
          'application_choices.rejection_reason',
          'application_choices.rejected_at',
          'application_choices.reject_by_default_at',
          'application_forms.first_name',
          'application_forms.last_name',
          'application_forms.date_of_birth',
          Arel.sql("ARRAY_REMOVE(
            ARRAY[
              application_forms.first_nationality,
              application_forms.second_nationality,
              application_forms.third_nationality,
              application_forms.fourth_nationality,
              application_forms.fifth_nationality
            ],
            NULL
          )"),
          'application_forms.country',
          'application_forms.uk_residency_status',
          'application_forms.english_main_language',
          'candidates.email_address',
          'application_forms.phone_number',
          'application_forms.address_line1',
          'application_forms.address_line2',
          'application_forms.address_line3',
          'application_forms.address_line4',
          'application_forms.postcode',
          'application_forms.country',
          'application_forms.recruitment_cycle_year',
          Arel.sql('CASE WHEN application_forms.degrees_completed THEN 1 ELSE 0 END'),
          'degrees.qualification_type',
          'degrees.non_uk_qualification_type',
          'degrees.subject',
          'degrees.grade',
          'degrees.start_year',
          'degrees.award_year',
          'degrees.institution_name',
          Arel.sql("STRING_AGG(CONCAT(
              UPPER(gcses.qualification_type), ' ', UPPER(gcses.subject), ', ',
              gcses.grade, ', ', gcses.start_year, '-', gcses.award_year
          ), ', ')"),
          Arel.sql("
            STRING_AGG(INITCAP(missing_gcses.subject) || ' GCSE or equivalent: ' || missing_gcses.missing_explanation, ',         ')"),
          'application_forms.disability_disclosure',
        ]

        @csv_data = GetApplicationChoicesForProviders
          .call(
            providers: providers,
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
          .joins("LEFT OUTER JOIN application_qualifications gcses ON gcses.application_form_id = application_forms.id AND gcses.level = 'gcse' AND gcses.qualification_type != 'missing'")
          .joins("LEFT OUTER JOIN application_qualifications missing_gcses ON missing_gcses.application_form_id = application_forms.id AND missing_gcses.level = 'gcse' AND missing_gcses.qualification_type = 'missing'")
          .joins("INNER JOIN application_qualifications degrees ON degrees.application_form_id = application_forms.id AND degrees.level = 'degree'")
          .where('courses.recruitment_cycle_year' => cycle_years)
          .where(status: statuses)
          .where('candidates.hide_in_reporting': false)
          .group(*(fields.reject.with_index { |_, i| [34, 35].include?(i) }))
          .pluck(*fields)

        render :profile
      else
        render :new
      end
    end

  private

    def application_data_export_params
      params.require(:provider_interface_application_data_export_form).permit(:application_status_choice, statuses: [], provider_ids: [], recruitment_cycle_years: [])
    end

    def csv_filename
      "#{Time.zone.now}.applications-export.csv"
    end

    def redirect_to_hesa_export_unless_feature_enabled
      redirect_to provider_interface_new_hesa_export_path unless FeatureFlag.active?(:export_application_data)
    end

    def summary_for_gcse(gcse)
      return if gcse.blank?

      "#{gcse.qualification_type.humanize} #{gcse.subject.capitalize}, #{gcse.grade}, #{gcse.start_year}-#{gcse.award_year}"
    end
  end
end
