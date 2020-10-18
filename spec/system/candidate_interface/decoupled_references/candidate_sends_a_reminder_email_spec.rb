require 'rails_helper'

RSpec.feature 'Candidate sends a reference reminder' do
  include CandidateHelper

  scenario 'the candidate has sent a reference request and decides to send a reminder' do
    given_i_am_signed_in
    and_the_decoupled_references_flag_is_on
    and_i_have_added_and_sent_a_reference

    when_i_review_my_references
    and_decide_to_send_a_reminder

    then_i_see_the_date_of_the_next_automated_reminder
    and_i_can_send_a_single_reminder_manually
    and_submitting_a_stale_confirmation_form_does_nothing
    and_the_reference_history_shows_the_reminder_i_just_sent
  end

  def given_i_am_signed_in
    create_and_sign_in_candidate
  end

  def and_the_decoupled_references_flag_is_on
    FeatureFlag.activate('decoupled_references')
  end

  def and_i_have_added_and_sent_a_reference
    @reference = create(:reference, :requested, application_form: current_candidate.current_application)
    current_candidate.current_application.update(first_name: 'Jeremy', last_name: 'Corbyn')
  end

  def when_i_review_my_references
    visit candidate_interface_decoupled_references_review_path
  end

  def and_decide_to_send_a_reminder
    within '#references_sent' do
      click_link 'Send a reminder to this referee'
    end
  end

  def then_i_see_the_date_of_the_next_automated_reminder
    expect(page).to have_content 'Would you like to send a reminder to this referee?'
    expect(page).to have_content @reference.chase_referee_at.strftime('%-d %B %Y')
  end

  def and_i_can_send_a_single_reminder_manually
    click_button 'Yes I’m sure - send a reminder'
    open_email(@reference.email_address)
    expect(current_email.subject).to include 'Jeremy Corbyn is waiting for you to give them a reference'
    expect(all_emails.size).to eq 1

    expect(page).to have_current_path candidate_interface_decoupled_references_review_path
    expect(page).to have_content "Reminder sent to #{@reference.name}"
    expect(page).not_to have_link 'Send a reminder to this referee'
  end

  def and_submitting_a_stale_confirmation_form_does_nothing
    visit candidate_interface_decoupled_references_new_reminder_path(@reference)
    click_button 'Yes I’m sure - send a reminder'
    expect(page).to have_current_path candidate_interface_decoupled_references_review_path
    expect(all_emails.size).to eq 1
  end

  def and_the_reference_history_shows_the_reminder_i_just_sent
    within '#references_sent' do
      within '.qa-reference-history' do
        expect(page).to have_content @reference.reload.reminder_sent_at.to_s(:govuk_date_and_time)
      end
    end
  end
end
