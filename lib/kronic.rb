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
      :today       => 'today',
      :tomorrow    => 'tomorrow',
      :yesterday   => 'yesterday',
      :this        => 'this',
      :last        => 'last',
      :months      => Date::MONTHNAMES.map{|m| m ? m.downcase : m},
      :months_abbr => Date::ABBR_MONTHNAMES.map{|m| m ? m.downcase : m},
      :days        => Date::DAYNAMES.map(&:downcase),
      :days_abbr   => Date::ABBR_DAYNAMES.map(&:downcase),
      :number_with_ordinal => /^[0-9]+(st|nd|rd|th)?$/
    },
    :de => {
      :today       => 'heute',
      :tomorrow    => 'morgen',
      :yesterday   => 'gestern',
      :this        => /diese(n|r)/,
      :last        => /letzte(r|n)/,
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
    t[:months].index(month) || t[:months_abbr].index(month)
  end

  # Parse "Today", "Tomorrow" and "Yesterday"
  def parse_nearby_days(string)
    case string
    when t[:today]; today
    when t[:yesterday]; today - 1
    when t[:tomorrow]; today + 1
    end
  end

  # Parse "Last Monday", "This Monday"
  def parse_last_or_this_day(string)
    tokens  = string.split(/\s+/)
    is_last = t[:last] === tokens[0]
    is_next = t[:this] === tokens[0]

    if is_last || is_next
      wday = t[:days].index(tokens[1]) || t[:days_abbr].index(tokens[1])
      today - (today.wday - wday) + ((is_last ? 0 : 7) - (today.wday == 0 ? 7 : 0)) if wday
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

    year && month && day ? Date.new(year, month, day) : nil
  end
end
