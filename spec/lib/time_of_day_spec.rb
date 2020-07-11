RSpec.describe TimeOfDay do

  describe '.second_offset' do

    [
      [TimeOfDay.new(0), 0],
      [TimeOfDay.new(0,0,1), 1.second],
      [TimeOfDay.new(0,1,0), 1.minute],
      [TimeOfDay.new(0,1,1), 1.minute + 1.second],
      [TimeOfDay.new(1), 1.hour],
      [TimeOfDay.new(23,59,59), 1.day - 1],
      [TimeOfDay.new(0, day_offset: 1), 1.day],
      [TimeOfDay.new(1, day_offset: 1), 1.day + 1.hour],
      [TimeOfDay.new(0, day_offset: -1), -1.day],
      [TimeOfDay.new(0, utc_offset: 1.hour), -1.hour],
      [TimeOfDay.new(0, utc_offset: -1.hour), 1.hour],
    ].each do |time_of_day, expected|
      it "returns #{expected} for #{time_of_day}" do
        expect(time_of_day.second_offset).to eq(expected)
      end
    end

  end

  describe '.parse' do

    [
      ['17', TimeOfDay.new(17)],
      ['17:41', TimeOfDay.new(17, 41)],
      ['17:41:12', TimeOfDay.new(17, 41, 12)],
      ['17:41:00', TimeOfDay.new(17, 41)],
      ['17:00:00', TimeOfDay.new(17)],
      ['00:00:00', TimeOfDay.new(0)],
      ['23:59:59', TimeOfDay.new(23,59,59)],
      ['08:05:02', TimeOfDay.new(8,5,2)]
    ].each do |definition, expected|
      it "creates #{expected.inspect} from '#{definition}'" do
        expect(TimeOfDay.parse(definition)).to eq(expected)
      end
    end

  end

  describe '.create' do

    [
      [Time.new(2100,01,01,17), nil, TimeOfDay.new(17) ],
      [Time.new(2000,01,01,17,16,15), nil, TimeOfDay.new(17,16,15) ],
      [GTFS::Time.new(17), nil, TimeOfDay.new(17) ],
      [GTFS::Time.new(17,16,15), nil, TimeOfDay.new(17,16,15) ],
      [GTFS::Time.new(17,16,15, day_offset: 1), nil, TimeOfDay.new(17,16,15, day_offset: 1) ],
      [GTFS::Time.new(12), {time_zone: ActiveSupport::TimeZone["Europe/Paris"]}, TimeOfDay.new(12, utc_offset: 3600) ],
      [GTFS::Time.new(16), {time_zone: ActiveSupport::TimeZone["America/Los_Angeles"]}, TimeOfDay.new(16, utc_offset: -3600*8) ],
      [GTFS::Time.new(16), {time_zone: ActiveSupport::TimeZone["America/Los_Angeles"]}, TimeOfDay.new(0, day_offset: 1) ]
    ].each do |time, attributes, expected|
      attributes ||= {}
      it "creates #{expected.inspect} from #{time.class} #{time.inspect} with #{attributes.inspect}" do
        expect(TimeOfDay.create(time, attributes)).to eq(expected)
      end
    end

  end

  describe '.from_second_offset' do

    [
      [ 0, TimeOfDay.new(0) ],
      [ 1.second, TimeOfDay.new(0,0,1) ],
      [ 1.minute, TimeOfDay.new(0,1,0) ],
      [ 1.hour, TimeOfDay.new(1,0,0) ],
      [ 23.hour + 59.minute + 59.second, TimeOfDay.new(23,59,59) ],
      [ 25.hour, TimeOfDay.new(1, day_offset: 1) ],
      [ -1.hour, TimeOfDay.new(23, day_offset: -1) ],
    ].each do |second_offset, expected|
      it "returns #{expected} for #{second_offset}" do
        expect(TimeOfDay.from_second_offset(second_offset)).to eq(expected)
      end
    end

    it "is the reverse of .second_offset method" do
      [
        TimeOfDay.new(23,59,59),
        TimeOfDay.new(1, day_offset: 1),
        TimeOfDay.new(1, utc_offset: 1.hour),
      ].each do |time_of_day|
        expect(TimeOfDay.from_second_offset(time_of_day.second_offset)).to eq(time_of_day)
      end
    end

  end

  describe '#without_utc_offset' do

    [
      [ TimeOfDay.new(12, utc_offset: 1.hour), TimeOfDay.new(11) ],
      [ TimeOfDay.new(16, utc_offset: -8.hours), TimeOfDay.new(0, day_offset: 1) ],
      [ TimeOfDay.new(0,5, utc_offset: 1.hour), TimeOfDay.new(23,5, day_offset: -1) ],
    ].each do |with, without|
      it "creates #{without.inspect} from #{with.inspect}" do
        expect(with.without_utc_offset).to eq(without)
      end
    end

  end

  describe '#with_utc_offset' do

    [
      [ TimeOfDay.new(14), -8.hours, TimeOfDay.new(6, utc_offset: -8.hours) ],
      [ TimeOfDay.new(0, day_offset: 1), -8.hours, TimeOfDay.new(16, utc_offset: -8.hours) ],
      [ TimeOfDay.new(23, day_offset: -1), 1.hour, TimeOfDay.new(0, utc_offset: 1.hour) ],
    ].each do |without, utc_offset, with|
      it "creates #{with.inspect} from #{without.inspect} and utc_offset #{utc_offset}" do
        expect(without.with_utc_offset(utc_offset)).to eq(with)
      end
    end

  end

  describe '#add' do

    [
      [ TimeOfDay.new(0), {day_offset: 1}, TimeOfDay.new(0, day_offset: 1) ],
      [ TimeOfDay.new(16, utc_offset: -8.hours), {day_offset: -1}, TimeOfDay.new(0) ],
    ].each do |time_of_day, arguments, expected|
      it "add #{arguments.inspect} to #{time_of_day.inspect} gives #{expected.inspect}" do
        expect(time_of_day.add(arguments)).to eq(expected)
      end
    end

  end

  describe "real examples" do

    it "allows to tranform 16:00:00 at Los Angeles into 00:00 day+1" do
      los_angeles = ActiveSupport::TimeZone["America/Los_Angeles"]

      gtfs_time_of_day = TimeOfDay.create(GTFS::Time.parse("16:00:00"), time_zone: los_angeles)
      utc_time_of_day = gtfs_time_of_day.without_utc_offset

      expect(utc_time_of_day).to have_attributes(hour: 0, minute: 0, day_offset: 1, utc_offset: 0)
    end

    it "allows to tranform 00:05:00 at Paris into 23:05 day-1" do
      paris = ActiveSupport::TimeZone["Europe/Paris"]

      gtfs_time_of_day = TimeOfDay.create(GTFS::Time.parse("00:05:00"), time_zone: paris)
      utc_time_of_day = gtfs_time_of_day.without_utc_offset

      expect(utc_time_of_day).to have_attributes(hour: 23, minute: 5, day_offset: -1, utc_offset: 0)
    end

  end

  describe '#to_iso_8601' do

    [
      [ TimeOfDay.new(12), "12:00:00Z" ],
      [ TimeOfDay.new(12,13), "12:13:00Z" ],
      [ TimeOfDay.new(12,13,14), "12:13:14Z" ],
      [ TimeOfDay.new(12,1,1), "12:01:01Z" ],
      [ TimeOfDay.new(12, utc_offset: 1.hour), "12:00:00+01:00" ],
      [ TimeOfDay.new(12, utc_offset: -1.hour), "12:00:00-01:00" ],
      [ TimeOfDay.new(12, utc_offset: 1.hour+1.minute), "12:00:00+01:01" ],
      [ TimeOfDay.new(12, utc_offset: -(1.hour+1.minute)), "12:00:00-01:01" ],
    ].each do |time_of_day, expected|
      it "returns #{expected.inspect} from #{time_of_day.inspect}" do
        expect(time_of_day.to_iso_8601).to eq(expected)
      end
    end

  end

end
