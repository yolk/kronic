# encoding: utf-8

require 'date'

class Kronic
  
  # Public: Initialises new Kronic instance with options.
  #
  # opts   - The Hash options used to customize parsing and formatting
  #          :today - The reference point for calculations (default: Date.today)
  #          :locale - The locale for used translation (default: :en)
  #
  # Returns a Kronic instance
  def initialize(options)
    @today        = options[:today ] || Date.today
    @translations = options[:locale] && TRANSLATIONS[options[:locale].to_sym] || TRANSLATIONS[:en]
  end
  
  # Public: Converts a human readable day (Today, yesterday) to a Date.
  #
  # Will call #to_s on the input, so can process Symbols or whatever other
  # object you wish to throw at it.
  #
  # string - The String to convert to a Date. Supported formats are: Today,
  #          yesterday, tomorrow, last thursday, this thursday, 14 Sep,
  #          Sep 14, 14 June 2010. Parsing is case-insensitive.
  #
  # Returns the Date, or nil if the input could not be parsed.
  def parse(string)
    string = string.to_s.downcase.strip

    parse_nearby_days(string) ||
    parse_last_or_this_day(string) ||
    parse_exact_date(string)
  end
  
  def self.parse(string, options={})
    new(options).parse(string)
  end
  
  private
  
  attr_reader :today, :locale, :translations
  alias_method :t, :translations
  
  # A hash containing key/value pairs for different locales. This hash is mutable, meaning
  # you should update it to change the translations.
  TRANSLATIONS = {
    :en => {
      :this        => 'this',
      :tomorrow    => 'tomorrow',
      :today       => 'today',
      :yesterday   => 'yesterday',
      :last        => 'last',
      :months      => Date::MONTHNAMES.map{|m| m ? m.downcase : m},
      :months_abbr => Date::ABBR_MONTHNAMES.map{|m| m ? m.downcase : m},
      :days        => Date::DAYNAMES.map(&:downcase),
      :days_abbr   => Date::ABBR_DAYNAMES.map(&:downcase),
      :number_with_ordinal => /^[0-9]+(st|nd|rd|th)?$/
    },
    :de => {
      :this        => 'diesen',
      :tomorrow    => 'morgen',
      :today       => 'heute',
      :yesterday   => 'gestern',
      :last        => 'letzten',
      :months      => [nil] + %w(januar februar märz april mai juni juli august september oktober november dezember),
      :months_abbr => [nil] + %w(jan feb mrz apr mai jun jul aug sep okt nov dez),
      :days        => %w(sonntag montag dienstag mittwoch donnerstag freitag samstag),
      :days_abbr   => %w(so mo di mi do fr sa),
      :number_with_ordinal => /^[0-9]+(\.|er|ter)?$/
    }
  }

  NUMBER              = /^[0-9]+$/

  # Examples
  #
  #   month_from_name("january") # => 1
  #   month_from_name("jan")     # => 1
  def month_from_name(month)
    f = lambda {|months| months.compact.map {|x| x.downcase }.index(month) }

    month = f[t[:months]] || f[t[:months_abbr]]
    month ? month + 1 : nil
  end

  # Parse "Today", "Tomorrow" and "Yesterday"
  def parse_nearby_days(string)
    return today     if string == t[:today]
    return today - 1 if string == t[:yesterday]
    return today + 1 if string == t[:tomorrow ]
  end

  # Parse "Last Monday", "This Monday"
  def parse_last_or_this_day(string)
    tokens = string.split(/\s+/)

    if [t[:last], t[:this]].include?(tokens[0])
      days = (1..7).map {|x| 
        today + (tokens[0] == t[:last] ? -x : x)
      }.inject({}) {|a, x| 
        a.update(t[:days][x.wday] => x) 
      }
      days[tokens[1]]
    end
  end

  # Parse "14 Sep", "14 September", "14 September 2010", "Sept 14 2010"
  def parse_exact_date(string)
    tokens = string.split(/\s+/)

    if tokens.length >= 2
      if    tokens[0] =~ t[:number_with_ordinal]
        parse_exact_date_parts(tokens[0], tokens[1], tokens[2])
      elsif tokens[1] =~ t[:number_with_ordinal]
        parse_exact_date_parts(tokens[1], tokens[0], tokens[2])
      end
    end
  end
  
  # Parses day, month and year parts
  def parse_exact_date_parts(raw_day, raw_month, raw_year)
    day   = raw_day.to_i
    month = month_from_name(raw_month)
    year = if raw_year
      raw_year =~ NUMBER ? raw_year.to_i : nil
    else
      today.year
    end

    return nil unless day && month && year

    result = Date.new(year, month, day)
    result = result << 12 if result > today && !raw_year
    result
  end
end
