class EndOfCycleTimetable
  DATES = {
    apply_1_deadline: Date.new(2020, 8, 24),
    apply_2_deadline: Date.new(2020, 9, 18),
    next_cycles_courses_open: Date.new(2020, 10, 13),
  }.freeze

  def self.between_cycles?(phase)
    phase == 'apply_1' ? between_cycles_apply_1? : between_cycles_apply_2?
  end

  def self.show_apply_1_deadline_banner?
    Time.zone.now < date(:apply_1_deadline).end_of_day
  end

  def self.show_apply_2_deadline_banner?
    Time.zone.now < date(:apply_2_deadline).end_of_day
  end

  def self.apply_1_deadline
    date(:apply_1_deadline)
  end

  def self.apply_2_deadline
    date(:apply_2_deadline)
  end

  def self.next_cycles_courses_open
    date(:next_cycles_courses_open)
  end

  def self.between_cycles_apply_1?
    Time.zone.now > date(:apply_1_deadline).end_of_day &&
      Time.zone.now < date(:next_cycles_courses_open).beginning_of_day
  end

  def self.between_cycles_apply_2?
    Time.zone.now > date(:apply_2_deadline).end_of_day &&
      Time.zone.now < date(:next_cycles_courses_open).beginning_of_day
  end

  def self.date(name)
    if HostingEnvironment.test_environment? && FeatureFlag.active?(:simulate_time_between_cycles)
      return simulate_time_between_cycles_dates[name]
    end

    DATES[name]
  end

  def self.next_cycle_year
    date(:next_cycles_courses_open).year + 1
  end

  def self.simulate_time_between_cycles_dates
    {
      apply_1_deadline: 5.days.ago.to_date,
      apply_2_deadline: 2.days.ago.to_date,
      next_cycles_courses_open: Date.new(2020, 10, 13) > Time.zone.today ? Date.new(2020, 10, 13) : (Time.zone.today + 1),
    }
  end
end
