module SupportInterface
  class PersonalDetailsComponent < ViewComponent::Base
    MISSING = '<em>Not provided</em>'.html_safe
    RIGHT_TO_WORK_OR_STUDY_DISPLAY_VALUES = {
      'yes' => 'Yes',
      'no' => 'Not yet',
      'decide_later' => 'Candidate does not know',
    }.freeze

    include ViewHelper

    delegate :first_name,
             :last_name,
             :phone_number,
             :candidate,
             to: :application_form

    delegate :email_address, to: :candidate

    def initialize(application_form:)
      @application_form = application_form
    end

    def rows
      [
        first_name_row,
        last_name_row,
        date_of_birth_row,
        nationality_row,
        domicile_row,
        right_to_work_or_study_row,
        residency_details_row,
        phone_number_row,
        email_row,
        address_row,
      ].compact
    end

  private

    def first_name_row
      row = {
        key: 'First name',
        value: first_name,
      }
      return row unless editable?

      row.merge(
        action: {
          href: support_interface_application_form_edit_applicant_details_path(application_form),
          visually_hidden_text: 'first name',
        },
      )
    end

    def last_name_row
      row = {
        key: 'Last name',
        value: last_name,
      }
      return row unless editable?

      row.merge(
        action: {
          href: support_interface_application_form_edit_applicant_details_path(application_form),
          visually_hidden_text: 'last name',
        },
      )
    end

    def email_row
      row = {
        key: 'Email address',
        value: govuk_mail_to(email_address, email_address),
      }
      return row unless editable?

      row.merge(
        action: {
          href: support_interface_application_form_edit_applicant_details_path(application_form),
          visually_hidden_text: 'email address',
        },
      )
    end

    def phone_number_row
      row = {
        key: 'Phone number',
        value: phone_number || MISSING,
      }
      return row unless editable?

      row.merge(
        action: {
          href: support_interface_application_form_edit_applicant_details_path(application_form),
          visually_hidden_text: 'phone number',
        },
      )
    end

    def nationality_row
      row = {
        key: 'Nationality',
        value: application_form.nationalities.to_sentence(last_word_connector: ' and '),
      }
      return row unless editable?

      row.merge(
        action: {
          href: support_interface_application_form_edit_nationalities_path(application_form),
          visually_hidden_text: 'nationality',
        },
      )
    end

    def domicile_row
      {
        key: 'Domicile',
        value: application_form.domicile,
      }
    end

    def right_to_work_or_study_row
      return if application_form.right_to_work_or_study.blank?

      row = {
        key: 'Has the right to work or study in the UK?',
        value: RIGHT_TO_WORK_OR_STUDY_DISPLAY_VALUES.fetch(application_form.right_to_work_or_study),
      }
      return row unless editable?

      row.merge(
        action: {
          href: support_interface_application_form_edit_right_to_work_or_study_path(application_form),
          visually_hidden_text: 'right to work or study',
        },
      )
    end

    def residency_details_row
      return unless application_form.right_to_work_or_study == 'yes'

      row = {
        key: 'Residency details',
        value: application_form.right_to_work_or_study_details,
      }
      return row unless editable?

      row.merge(
        action: {
          href: support_interface_application_form_edit_right_to_work_or_study_path(application_form),
          visually_hidden_text: 'residency details',
        },
      )
    end

    def date_of_birth_row
      row = {
        key: 'Date of birth',
        value: application_form.date_of_birth ? application_form.date_of_birth.to_s(:govuk_date) : MISSING,
      }
      return row unless editable?

      row.merge(
        action: {
          href: support_interface_application_form_edit_applicant_details_path(application_form),
          visually_hidden_text: 'date of birth',
        },
      )
    end

    def address_row
      row = {
        key: 'Address',
        value: full_address,
      }
      return row unless editable?

      row.merge(
        action: {
          href: support_interface_application_form_edit_address_type_path(application_form),
          visually_hidden_text: 'address',
        },
      )
    end

    def full_address
      if @application_form.address_type == 'uk'
        local_address.reject(&:blank?)
      else
        local_address.concat([COUNTRIES_AND_TERRITORIES[@application_form.country]]).reject(&:blank?)
      end
    end

    def local_address
      [
        @application_form.address_line1,
        @application_form.address_line2,
        @application_form.address_line3,
        @application_form.address_line4,
        @application_form.postcode,
      ]
    end

    attr_reader :application_form

    def editable?
      application_form.editable?
    end
  end
end
