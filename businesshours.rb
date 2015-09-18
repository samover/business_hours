require 'time'

# A Ruby script which will determine the guaranteed time given a
# business hour schedule. The class called BusinessHours allows
# one to define the opening and closing time for each day with the
# methods 'update' and 'closed'.
class BusinessHours
  def initialize(opening, closing)
    @opening = opening  # e.g. "9:00 AM"
    @closing = closing  # e.g. "3:00 PM"
    @exception = []     # e.g. "{:fri, "10:00 AM", "5:00 PM"}"
    @closed_on = []     # e.g. "Dec 25, 2010"
  end

  def update(day, opening, closing)
    @exception << [day, opening, closing]
  end

  def closed(*days)
    days.each { |day| @closed_on << day }     # e.g. :fri OR "25 Dec, 2010"
  end

  def name_of_day_on(date)
    date.strftime('%a').downcase.to_sym       # e.g. :fri
  end

  def date_to_day(date)
    date.strftime('%b %e, %Y')
  end

  def closed_on?(date)
    @closed_on.any? { |d| d == date_to_day(date) || d == name_of_day_on(date) }
  end

  def exception?(date)
    @exception.each { |d| return parse_business_hours(date_to_day(date), d[1], d[2]) if d[0] == date_to_day(date) }
    @exception.each { |d| return parse_business_hours(date_to_day(date), d[1], d[2]) if d[0] == name_of_day_on(date) }
    false
  end

  def parse_business_hours(day, opening = @opening, closing = @closing)
    {   open:   Time.parse(day + ' ' + opening),
        closed: Time.parse(day + ' ' + closing) }
  end

  def opening_hours(date)
    return nil if closed_on?(date)
    return exception?(date) if exception?(date)
    parse_business_hours(date_to_day(date))
  end

  def next_day(date)
    date + 24 * 60 * 60
  end

  def calculate_deadline(interval, day)
    hours_this_day = opening_hours(Time.parse(day))
    start_counting_from = [Time.parse(day), hours_this_day[:open]].max

    while start_counting_from + interval > hours_this_day[:closed]
      interval -= hours_this_day[:closed] - start_counting_from
      hours_this_day = opening_hours(next_business_day(start_counting_from))
      start_counting_from = hours_this_day[:open]
    end
    start_counting_from + interval
  end

  def next_business_day(date)
    loop do
      date = next_day(date)
      next_day_hours = opening_hours(date)
      return date unless next_day_hours.nil?
    end
  end
end

hours = BusinessHours.new('9:00 AM', '3:00 PM')
hours.update :fri, '10:00 AM', '5:00 PM'
hours.update 'Dec 24, 2010', '8:00 AM', '1:00 PM'
hours.closed :sun, :wed, 'Dec 25, 2010'
puts hours.calculate_deadline(2 * 60 * 60, 'Jun 7, 2010 9:10 AM')
# => Mon Jun 07 11:10:00 2010
puts hours.calculate_deadline(15 * 60, 'Jun 8, 2010 2:48 PM')
# => Thu Jun 10 09:03:00 2010
puts hours.calculate_deadline(7 * 60 * 60, 'Dec 24, 2010 6:45 AM')
# => Mon Dec 27 11:00:00 2010
