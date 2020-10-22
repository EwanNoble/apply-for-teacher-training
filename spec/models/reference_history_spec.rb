require 'rails_helper'

RSpec.describe ReferenceHistory do
  describe '#all_events' do
    it 'returns the event history for a successful reference', with_audited: true do
      reference = create(:reference, :not_requested_yet, email_address: 'ericandre@email.com')
      start_time = reference.created_at
      Timecop.freeze(start_time + 1.day) { reference.feedback_requested! }
      Timecop.freeze(start_time + 2.days) { reference.email_bounced! }
      Timecop.freeze(start_time + 3.days) { reference.feedback_requested! }
      Timecop.freeze(start_time + 4.days) { reference.update!(reminder_sent_at: Time.zone.now) }
      Timecop.freeze(start_time + 5.days) { reference.feedback_provided! }

      events = described_class.new(reference).all_events

      expected_attributes = [
        { name: 'request_sent', time: start_time + 1.day, extra_info: nil },
        { name: 'request_bounced', time: start_time + 2.days, extra_info: OpenStruct.new(bounced_email: 'ericandre@email.com') },
        { name: 'request_sent', time: start_time + 3.days, extra_info: nil },
        { name: 'reminder_sent', time: start_time + 4.days, extra_info: nil },
        { name: 'reference_given', time: start_time + 5.days, extra_info: nil },
      ]
      compare_data(expected_attributes, events)
    end

    it 'returns the event history for a failed reference', with_audited: true do
      reference = create(:reference, :not_requested_yet, email_address: 'ericandre@email.com')
      start_time = reference.created_at
      Timecop.freeze(start_time + 1.day) { reference.feedback_requested! }
      Timecop.freeze(start_time + 2.days) { reference.feedback_refused! }

      events = described_class.new(reference).all_events

      expected_attributes = [
        { name: 'request_sent', time: start_time + 1.day, extra_info: nil },
        { name: 'request_declined', time: start_time + 2.days, extra_info: nil },
      ]
      compare_data(expected_attributes, events)
    end

    it 'returns as many events for each event type as exists in the audit log', with_audited: true do
      reference = create(:reference, :not_requested_yet, email_address: 'ericandre@email.com')
      2.times do
        reference.feedback_requested!
        reference.cancelled!
        reference.update!(reminder_sent_at: Time.zone.now)
        reference.email_bounced!
        reference.feedback_provided!
        reference.feedback_refused!
      end

      events = described_class.new(reference).all_events

      all_event_names.each do |event_name|
        expect(events.select { |e| e.name == event_name }.count).to eq 2
      end
    end

  private

    def compare_data(expected_attributes, events)
      expect(events.size).to eq expected_attributes.size
      expected_attributes.each_with_index do |attr, index|
        returned_event = events[index]
        expect(returned_event.name).to eq attr[:name]
        expect(returned_event.time).to eq attr[:time]
        expect(returned_event.extra_info).to eq attr[:extra_info]
      end
    end

    def all_event_names
      %w[
        request_sent
        request_cancelled
        reminder_sent
        request_bounced
        request_declined
        reference_given
      ]
    end
  end
end
