# encoding: utf-8
require 'spec_helper'

describe Kronic do
  def self.should_parse(string, date, options={})
    it "should parse '#{string}'" do
      Kronic.parse(string, options).should == date
    end
  end
  
  def self.should_translate(string, string_en, locale)
    it "should parse '#{string}' same as '#{string_en}'" do
      Kronic.parse(string, {:locale => locale}).should == Kronic.parse(string_en)
    end
  end

  def self.date(key)
    {
      :today          => Date.new(2010, 9, 18),
      :last_monday    => Date.new(2010, 9, 13),
      :next_monday    => Date.new(2010, 9, 20),
      :this_monday    => Date.new(2010, 9, 13),
      :this_sunday    => Date.new(2010, 9, 12),
      :sep_4          => Date.new(2010, 9, 4),
      :sep_4_1999     => Date.new(1999, 9, 4),
      :sep_4_112      => Date.new(112, 9, 4),
      :sep_20         => Date.new(2010, 9, 20),
      :sep_28         => Date.new(2010, 9, 28),
      :jan_28         => Date.new(2010, 1, 28)
    }.fetch(key)
  end
  def date(key); self.class.date(key); end;

  before :all do 
    Timecop.freeze(date(:today))
  end

  after :all do 
    Timecop.return
  end

  should_parse('Today',             date(:today))
  should_parse(:today,              date(:today))
  should_parse('today',             date(:today))
  should_parse('  Today',           date(:today))
  should_parse('Yesterday',         date(:today) - 1)
  should_parse('Tomorrow',          date(:today) + 1)
  should_parse('Last Monday',       date(:last_monday))
  should_parse('Next Monday',       date(:next_monday))
  should_parse('This Monday',       date(:this_monday))
  should_parse('This Sunday',       date(:this_sunday))
  should_parse('Sunday',            date(:this_sunday))
  should_parse('Mon',               date(:this_monday))
  should_parse('last Mon',          date(:last_monday))
  should_parse('last Sat',          date(:today) - 7)
  should_parse('next Sat',          date(:today) + 7)
  should_parse('this Sat',          date(:today))
  should_parse('4 Sep',             date(:sep_4))
  should_parse('4  Sep',            date(:sep_4))
  should_parse('4 September',       date(:sep_4))
  should_parse('20 Sep',            date(:sep_20))
  should_parse('28 Sep 2010',       date(:sep_28))
  should_parse('14 Sep 2008',       Date.new(2008, 9, 14))
  should_parse('14th Sep 2008',     Date.new(2008, 9, 14))
  should_parse('23rd Sep 2008',     Date.new(2008, 9, 23))
  should_parse('September 14 2008', Date.new(2008, 9, 14))
  should_parse('Sep 4th',           date(:sep_4))
  should_parse('September 4',       date(:sep_4))
  
  should_parse('2010/9/4',          date(:sep_4))
  should_parse('4/9/2010',          date(:sep_4))
  should_parse('4/9',               date(:sep_4))
  should_parse('4/9/',              date(:sep_4))
  should_parse('4/9/10',            date(:sep_4))
  should_parse('4/9/99',            date(:sep_4_1999))
  should_parse('4/9/112',           date(:sep_4_112))
  should_parse('112/9/4',           date(:sep_4_112))
  
  should_parse('2010.9.4',          date(:sep_4))
  should_parse('4.9.2010',          date(:sep_4))
  should_parse('4.9',               date(:sep_4))
  should_parse('4.9.',              date(:sep_4))
  should_parse('4.9.10',            date(:sep_4))
  should_parse('4.9.99',            date(:sep_4_1999))
  should_parse('4.9.112',           date(:sep_4_112))
  should_parse('112.9.4',           date(:sep_4_112))
  
  should_parse('bogus',             nil)
  should_parse('14',                nil)
  should_parse('14 bogus in',       nil)
  should_parse('14 June oen',       nil)
  should_parse('1/1 oen',           nil)
  should_parse('1/1/2010 oen',      nil)
  should_parse('32.9.2010',         nil)
  should_parse('4.13.2010',         nil)
  should_parse('today',             date(:today) + 1, {:today => date(:today) + 1})

  context "in german" do
    should_translate('Heute',               "today",        "de")
    should_translate('morgen',              "tomorrow",     :de)
    should_translate('gestern',             "yesterday",    :de)
    should_translate('28 Januar',           "28 Jan",       :de)
    should_translate('1 Mai 2010',          "1 May 2010",   :de)
    should_translate('1 Mai 2008',          "1 May 2008",   :de)
    should_translate('28. Januar',          "28 Jan",       :de)
    should_translate('28er Januar',         "28 Jan",       :de)
    should_translate('2ter Mai',            "2 May",        :de)
    should_translate('Letzten Montag',      "last monday",  :de)
    should_translate('nächsten Montag',     "next monday",  :de)
    should_translate('diesen Montag',       "this monday",  :de)
    should_translate('Letzter Mo',          "last monday",  :de)
    should_parse('diesen sonntag',          date(:this_sunday) + 7, :locale => :de) # week starts at monday
    should_parse('übermorgen',              date(:today) + 2,       :locale => :de)
    should_parse('vorgestern',              date(:today) - 2,       :locale => :de)
  end
end
