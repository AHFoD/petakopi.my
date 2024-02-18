class OpeningHoursPresenter
  def initialize(opening_hours)
    @opening_hours = opening_hours
  end

  def list
    previous_day = nil

    formatted_opening_hours =
      @opening_hours
        .sort_by { |x| [x.start_day, x.start_time] }
        .map do |opening_hour|
          opening_hour = ActiveDecorator::Decorator.instance.decorate(opening_hour)

          if opening_hour.start_day_name != previous_day
            display_day = opening_hour.start_day_name
            previous_day = opening_hour.start_day_name
          end

          {
            display_day: display_day,
            start_day: opening_hour.start_day_name,
            start_time: opening_hour.start_time_formatted,
            close_day: opening_hour.close_day,
            close_time: opening_hour.close_time_formatted
          }
        end

    current_days = formatted_opening_hours.map { |x| x[:start_day] }.compact.uniq

    return formatted_opening_hours if current_days.count == 7

    missing_days = (0..6).to_a - current_days.map { |x| Date::DAYNAMES.index(x) }
    missing_days.each do |day|
      formatted_opening_hours << {
        display_day: Date::DAYNAMES[day],
        start_day: Date::DAYNAMES[day],
        start_time: "-",
        close_day: nil,
        close_time: "-"
      }
    end

    formatted_opening_hours
      .sort_by { |x| [Date::DAYNAMES.index(x[:start_day]), x[:start_time]] }
  end
end
