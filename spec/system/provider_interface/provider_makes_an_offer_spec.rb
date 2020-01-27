require 'rails_helper'

RSpec.feature 'Provider makes an offer' do
  include CourseOptionHelpers
  include DfESignInHelpers

  scenario 'Provider makes an offer' do
    given_i_am_a_provider_user_with_dfe_sign_in
    and_application_choices_exist_for_my_provider
    and_i_am_permitted_to_see_applications_for_my_provider
    and_i_sign_in_to_the_provider_interface

    when_i_respond_to_an_application
    and_i_choose_to_make_an_offer
    then_i_see_some_application_info

    when_i_select_standard_reasons
    and_i_add_optional_further_conditions
    and_i_click_to_continue
    then_i_am_asked_to_confirm_the_offer
    and_i_see_the_correct_offer_conditions

    when_i_confirm_the_offer
    then_i_am_back_to_the_application_page
    and_i_can_see_the_application_has_an_offer_made
  end

  def given_i_am_a_provider_user_with_dfe_sign_in
    provider_exists_in_dfe_sign_in
  end

  def and_application_choices_exist_for_my_provider
    course_option = course_option_for_provider_code(provider_code: 'ABC')
    @application_awaiting_provider_decision = create(:application_choice, status: 'awaiting_provider_decision', course_option: course_option, application_form: create(:completed_application_form, first_name: 'Alice', last_name: 'Wunder'))
  end

  def and_i_am_permitted_to_see_applications_for_my_provider
    provider_user_exists_in_apply_database
  end

  def when_i_respond_to_an_application
    visit provider_interface_application_choice_respond_path(
      @application_awaiting_provider_decision.id,
    )
  end

  def and_i_choose_to_make_an_offer
    choose 'Make an offer (including any conditions)'
    click_on 'Continue'
  end

  def then_i_see_some_application_info
    expect(page).to have_content \
      @application_awaiting_provider_decision.course.name_and_code
    expect(page).to have_content \
      @application_awaiting_provider_decision.application_form.first_name
    expect(page).to have_content \
      @application_awaiting_provider_decision.application_form.last_name
  end

  def when_i_select_standard_reasons
    page.check 'Fitness to Teach check', allow_label_click: true
  end

  def and_i_add_optional_further_conditions
    fill_in('make_an_offer[further_conditions0]', with: 'A further condition')
  end

  def and_i_click_to_continue
    click_on 'Continue'
  end

  def then_i_am_asked_to_confirm_the_offer
    expect(page).to have_current_path(
      provider_interface_application_choice_confirm_offer_path(
        @application_awaiting_provider_decision.id,
      ),
    )
    expect(page).to have_content 'Confirm offer'
  end

  def and_i_see_the_correct_offer_conditions
    expect(page).to have_content 'Fitness to Teach check'
    expect(page).to have_content 'A further condition'
  end

  def when_i_confirm_the_offer
    click_on 'Confirm offer'
  end

  def then_i_am_back_to_the_application_page
    expect(page).to have_current_path(
      provider_interface_application_choice_path(
        @application_awaiting_provider_decision.id,
      ),
    )
    expect(page).to have_content @application_awaiting_provider_decision.application_form.first_name
    expect(page).to have_content @application_awaiting_provider_decision.application_form.last_name
  end

  def and_i_can_see_the_application_has_an_offer_made
    expect(page).to have_content 'Application status changed to ‘Offer made’'
  end
end
