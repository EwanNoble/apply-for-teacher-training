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
           :support_reference,
           :submitted_at,
           to: :application_form

  delegate :email_address, to: :candidate

  def initialize(application_form:)
    @application_form = application_form
  end

  def rows
    [
      application_submitted_row,
      support_reference_row,
      name_row,
      date_of_birth_row,
      nationality_row,
      right_to_work_or_study_row,
      residency_details_row,
      phone_number_row,
      email_row,
      address_row,
    ].compact
  end

private

  def application_submitted_row
    return unless submitted_at

    {
      key: 'Application submitted',
      value: submitted_at.to_s(:govuk_date),
    }
  end

  def name_row
    {
      key: 'Full name',
      value: "#{first_name} #{last_name}",
    }
  end

  def email_row
    {
      key: 'Email address',
      value: mail_to(email_address, email_address, class: 'govuk-link'),
    }
  end

  def phone_number_row
    {
      key: 'Phone number',
      value: phone_number || MISSING,
    }
  end

  def nationality_row
    {
      key: 'Nationality',
      value: formatted_nationalities,
    }
  end

  def formatted_nationalities
    [
      @application_form.first_nationality,
      @application_form.second_nationality,
      @application_form.third_nationality,
      @application_form.fourth_nationality,
      @application_form.fifth_nationality,
    ]
    .reject(&:blank?)
    .to_sentence
  end

  def right_to_work_or_study_row
    return if @application_form.right_to_work_or_study.blank?

    {
      key: 'Has the right to work or study in the UK?',
      value: RIGHT_TO_WORK_OR_STUDY_DISPLAY_VALUES.fetch(@application_form.right_to_work_or_study),
    }
  end

  def residency_details_row
    return unless @application_form.right_to_work_or_study == 'yes'

    {
      key: 'Residency details',
      value: @application_form.right_to_work_or_study_details,
    }
  end

  def date_of_birth_row
    {
      key: 'Date of birth',
      value: application_form.date_of_birth ? application_form.date_of_birth.to_s(:govuk_date) : MISSING,
    }
  end

  def address_row
    {
      key: 'Address',
      value: full_address,
    }
  end

  def full_address
    if @application_form.international?
      [
        @application_form.international_address,
        COUNTRIES[@application_form.country],
      ]
        .reject(&:blank?)
    else
      [
        @application_form.address_line1,
        @application_form.address_line2,
        @application_form.address_line3,
        @application_form.address_line4,
        @application_form.postcode,
      ]
        .reject(&:blank?)
    end
  end

  def support_reference_row
    {
      key: 'Reference',
      value: support_reference,
    }
  end

  attr_reader :application_form
end
