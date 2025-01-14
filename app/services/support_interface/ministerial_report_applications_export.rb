module SupportInterface
  class MinisterialReportApplicationsExport
    def self.run_daily
      data_export = DataExport.create!(
        name: 'Daily export of the applications ministerial report',
        export_type: :ministerial_report_applications_export,
      )
      DataExporter.perform_async(SupportInterface::MinisterialReportApplicationsExport, data_export.id)
    end

    def call(*)
      report = initialize_empty_report

      report = choices_with_courses_and_subjects.each_with_object(report) do |choice, report_in_progress|
        add_choice_to_report(choice, report_in_progress)
      end

      assign_totals_to_report(report)
    end

    def add_choice_to_report(choice, report)
      return report if choice.phase == 'apply_2' && !choice.is_latest_a2_app

      subject_names_and_codes = choice.subject_names.zip(choice.subject_codes)

      subject = MinisterialReport.determine_dominant_course_subject_for_report(choice.course_name, choice.course_level, subject_names_and_codes.to_h)

      MinisterialReport::APPLICATIONS_REPORT_STATUS_MAPPING[choice.status.to_sym].each do |mapped_status|
        report[:stem][mapped_status] += 1 if MinisterialReport::STEM_SUBJECTS.include? subject
        report[:ebacc][mapped_status] += 1 if MinisterialReport::EBACC_SUBJECTS.include? subject
        report[:secondary][mapped_status] += 1 if MinisterialReport::SECONDARY_SUBJECTS.include? subject
        report[subject][mapped_status] += 1
      end

      report
    end

    def assign_totals_to_report(report)
      report[:total] = report[:primary].merge(report[:secondary]) { |_k, primary_value, secondary_value| primary_value + secondary_value }

      report.map { |subject, value| { subject: subject }.merge!(value) }
    end

    alias data_for_export call

  private

    def initialize_empty_report
      report_columns = {
        applications: 0,
        offer_received: 0,
        accepted: 0,
        application_declined: 0,
        application_rejected: 0,
        application_withdrawn: 0,
      }

      report_rows = {}
      MinisterialReport::SUBJECTS.each { |subject| report_rows[subject] = report_columns.dup }

      report_rows
    end

    def choices_with_courses_and_subjects
      ApplicationChoice
        .select('application_choices.id as id, application_choices.status as status, application_form.id as application_form_id, application_form.phase as phase, courses.name as course_name, courses.level as course_level, ARRAY_AGG(subjects.name) as subject_names, ARRAY_AGG(subjects.code) as subject_codes, (CASE WHEN a2_latest_application_forms.candidate_id IS NOT NULL THEN true ELSE false END) AS is_latest_a2_app')
        .joins(:application_form)
        .joins(course_option: { course: :subjects })
        .joins("LEFT JOIN (SELECT candidate_id, MAX(created_at) as created FROM application_forms WHERE phase = 'apply_2' GROUP BY candidate_id) a2_latest_application_forms ON application_form.created_at = a2_latest_application_forms.created AND application_form.candidate_id = a2_latest_application_forms.candidate_id")
        .where(application_form: { recruitment_cycle_year: RecruitmentCycle.current_year })
        .where.not(application_form: { submitted_at: nil })
        .group('application_choices.id, application_choices.status, application_form.id, application_form.phase, courses.name, courses.level, a2_latest_application_forms.candidate_id')
        .order('subject_names, subject_codes')
    end
  end
end
