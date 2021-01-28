require 'rails_helper'

RSpec.describe CandidateInterface::RestructuredWorkHistoryWorkBreakComponent do
  let(:january2018) { Time.zone.local(2018, 1, 1) }
  let(:february2019) { Time.zone.local(2019, 2, 1) }
  let(:april2019) { Time.zone.local(2019, 4, 1) }
  let(:work_break) do
    build_stubbed(
      :application_work_history_break,
      start_date: february2019,
      end_date: april2019,
      reason: 'I fell asleep.',
    )
  end

  it 'renders the component with the break length, reason and dates' do
    result = render_inline(CandidateInterface::RestructuredWorkHistoryWorkBreakComponent.new(work_break: work_break))

    expect(result.text).to include('I fell asleep.')
    expect(result.text).to include('February 2019 - April 2019')
  end

  it 'renders the component with a delete link' do
    result = render_inline(CandidateInterface::RestructuredWorkHistoryWorkBreakComponent.new(work_break: work_break))

    expect(result.css('a').first.text).to include('Change')
  end

  it 'renders the component with change links' do
    result = render_inline(CandidateInterface::RestructuredWorkHistoryWorkBreakComponent.new(work_break: work_break))

    expect(result.css('a').last.text).to include('Delete')
  end

  context 'when not editable' do
    it 'renders the component without a delete link' do
      result = render_inline(CandidateInterface::RestructuredWorkHistoryWorkBreakComponent.new(work_break: work_break, editable: false))

      expect(result.text).not_to include('Delete entry for break between February 2019 and April 2019')
    end

    it 'renders the component without change links' do
      result = render_inline(CandidateInterface::RestructuredWorkHistoryWorkBreakComponent.new(work_break: work_break, editable: false))

      expect(result.text).not_to include('Change description for break between February 2019 and April 2019')
      expect(result.text).not_to include('Change dates for break between February 2019 and April 2019')
    end
  end
end
