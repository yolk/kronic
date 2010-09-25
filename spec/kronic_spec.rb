require 'spec_helper'

describe Kronic do
  def self.should_parse(string, date, options={})
    it "should parse '#{string}'" do
      Kronic.parse(string, options).should == date
    end
  end

  def self.date(key)
    {
      :today       => Date.new(2010, 9, 18),
      :last_monday => Date.new(2010, 9, 13),
      :next_monday => Date.new(2010, 9, 20),
      :sep_4       => Date.new(2010, 9, 4),
      :sep_20      => Date.new(2009, 9, 20),
      :sep_28      => Date.new(2010, 9, 28),
      :jan_28      => Date.new(2010, 1, 28)
    }.fetch(key)
  end
  def date(key); self.class.date(key); end;

  before :all do 
    Timecop.freeze(date(:today))
  end

  after :all do 
    Timecop.return
  end

  should_parse('Today',       date(:today))
  should_parse(:today,        date(:today))
  should_parse('today',       date(:today))
  should_parse('  Today',     date(:today))
  should_parse('Yesterday',   date(:today) - 1)
  should_parse('Tomorrow',    date(:today) + 1)
  should_parse('Last Monday', date(:last_monday))
  should_parse('This Monday', date(:next_monday))
  should_parse('4 Sep',       date(:sep_4))
  should_parse('4  Sep',      date(:sep_4))
  should_parse('4 September', date(:sep_4))
  should_parse('20 Sep',      date(:sep_20))
  should_parse('28 Sep 2010', date(:sep_28))
  should_parse('14 Sep 2008',       Date.new(2008, 9, 14))
  should_parse('14th Sep 2008',     Date.new(2008, 9, 14))
  should_parse('23rd Sep 2008',     Date.new(2008, 9, 23))
  should_parse('September 14 2008', Date.new(2008, 9, 14))
  should_parse('Sep 4th',     date(:sep_4))
  should_parse('September 4', date(:sep_4))
  should_parse('bogus',       nil)
  should_parse('14',          nil)
  should_parse('14 bogus in', nil)
  should_parse('14 June oen', nil)
  should_parse('today', date(:today) + 1, {:today => date(:today) + 1})

  context "in german" do
    should_parse('Heute',           date(:today),           :locale => "de")
    should_parse('morgen',          date(:today) + 1,       :locale => :de)
    should_parse('gestern',         date(:today) - 1,       :locale => :de)
    should_parse('28 Januar',       date(:jan_28),          :locale => :de)
    should_parse('1 Mrz 2010',      Date.new(2010, 3, 1),   :locale => :de)
    should_parse('1 Mrz 2008',      Date.new(2008, 3, 1),   :locale => :de)
    should_parse('28. Januar',      date(:jan_28),          :locale => :de)
    should_parse('28er Januar',     date(:jan_28),          :locale => :de)
    should_parse('2ter Mrz',        Date.new(2010, 3, 2),   :locale => :de)
    should_parse('Letzten Montag',  date(:last_monday),     :locale => :de)
    should_parse('diesen Montag',   date(:next_monday),     :locale => :de)
  end
end
