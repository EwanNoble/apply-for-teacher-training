require 'rails_helper'

RSpec.describe Candidate, type: :model do
  describe 'a valid candidate' do
    subject { create(:candidate) }

    it { is_expected.to validate_presence_of :email_address }
    it { is_expected.to validate_length_of(:email_address).is_at_most(100) }
    it { is_expected.to allow_value('user@example.com').for(:email_address) }
    it { is_expected.not_to allow_value('foo').for(:email_address) }
    it { is_expected.not_to allow_value(Faker::Lorem.characters(number: 251)).for(:email_address) }
  end

  describe '#delete' do
    it 'deletes all dependent records through cascading deletes in the database' do
      candidate = create(:candidate)
      application_form = create(:application_form, candidate: candidate)
      application_choice = create(:application_choice, application_form: application_form)
      application_work_experience = create(:application_work_experience, application_form: application_form)
      application_volunteering_experience = create(:application_volunteering_experience, application_form: application_form)
      application_qualification = create(:application_qualification, application_form: application_form)
      application_reference = create(:reference, application_form: application_form)
      ucas_match = create(:ucas_match, candidate: candidate)

      candidate.delete

      expect { candidate.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { application_form.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { application_choice.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { application_work_experience.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { application_volunteering_experience.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { application_qualification.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { application_reference.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { ucas_match.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '#current_application' do
    let(:candidate) { create(:candidate) }

    context 'mid cycle' do
      around do |example|
        Timecop.travel(CycleTimetable.find_opens + 1.day) do
          example.run
        end
      end

      it 'returns an existing application_form' do
        application_form = create(:application_form, candidate: candidate)

        expect(candidate.current_application).to eq(application_form)
      end

      it 'creates an application_form with the current cycle if there are none' do
        expect { candidate.current_application }.to change { candidate.application_forms.count }.from(0).to(1)
        expect(candidate.current_application.recruitment_cycle_year).to eq CycleTimetable.current_year
      end

      it 'returns the most recent application' do
        first_application = create(:application_form, candidate: candidate, created_at: 3.days.ago)
        create(:application_form, candidate: candidate, created_at: 10.days.ago)

        expect(candidate.current_application.created_at).to eq(first_application.created_at)
      end
    end

    context 'after the apply1 deadline' do
      around do |example|
        Timecop.travel(CycleTimetable.apply_1_deadline + 1.day) do
          example.run
        end
      end

      it 'returns an existing application_form' do
        application_form = create(:application_form, candidate: candidate)

        expect(candidate.current_application).to eq(application_form)
      end

      it 'creates an application_form in the next cycle if there are none' do
        expect { candidate.current_application }.to change { candidate.application_forms.count }.from(0).to(1)
        expect(candidate.current_application.recruitment_cycle_year).to eq CycleTimetable.next_year
      end
    end
  end

  describe '#current_application_choice' do
    let(:candidate) { create(:candidate) }

    context 'with a single application choice' do
      let!(:application_choice) { create(:application_choice, candidate: candidate) }

      it 'returns the application choice' do
        expect(candidate.current_application_choice).to eq(application_choice)
      end
    end

    context 'with multiple application choices' do
      let!(:application_choice) { create(:application_choice, candidate: candidate, created_at: Time.zone.now - 1.week) }
      let!(:most_recent_application_choice) { create(:application_choice, candidate: candidate) }

      it 'returns the most recent application choice' do
        expect(candidate.current_application_choice).to eq(most_recent_application_choice)
      end
    end

    context 'with multiple application forms' do
      let(:application_choice) { create(:application_choice, candidate: candidate) }
      let(:most_recent_application_choice) { create(:application_choice, candidate: candidate) }
      let!(:application_form_apply_1) { create(:application_form, candidate: candidate, application_choices: [application_choice], created_at: Time.zone.now - 1.week) }
      let!(:application_form_apply_2) { create(:application_form, candidate: candidate, phase: 'apply_2', application_choices: [most_recent_application_choice]) }

      it 'returns the most recent application choice' do
        expect(candidate.current_application_choice).to eq(most_recent_application_choice)
      end
    end
  end

  describe 'find_from_course' do
    it 'returns the correct course' do
      course = create(:course)
      candidate = create(:candidate, course_from_find_id: course.id)

      expect(candidate.course_from_find).to eq(course)
    end

    it 'returns nil if there is no course_from_find_id' do
      candidate = create(:candidate)

      expect(candidate.course_from_find).to eq(nil)
    end
  end

  describe '#encrypted_id' do
    let(:candidate) { create(:candidate) }

    it 'invokes Encryptor to encrypt id' do
      allow(Encryptor).to receive(:encrypt).with(candidate.id).and_return 'encrypted id value'

      expect(candidate.encrypted_id).to eq 'encrypted id value'
    end
  end

  describe '#in_apply_2?' do
    subject(:candidate) { build(:candidate) }

    let!(:application_form) { create(:application_form, candidate: candidate) }

    context 'when the candidate has no applications in apply again' do
      it 'returns false' do
        expect(candidate.in_apply_2?).to be false
      end
    end

    context 'when the candidate has applications in apply again' do
      let!(:application_form) { create(:application_form, candidate: candidate, phase: 'apply_2') }

      it 'returns true' do
        expect(candidate.in_apply_2?).to be true
      end
    end

    context 'when the candidate has applications in apply again in previous cycle' do
      let!(:application_form_previous_year) { create(:application_form, candidate: candidate, phase: 'apply_2', recruitment_cycle_year: RecruitmentCycle.previous_year) }
      let!(:application_form) { create(:application_form, candidate: candidate) }

      it 'returns true' do
        expect(candidate.in_apply_2?).to be false
      end
    end
  end
end
