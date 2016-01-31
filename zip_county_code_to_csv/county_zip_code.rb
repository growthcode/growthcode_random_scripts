#! /usr/bin/env ruby

require 'awesome_print'
require 'pry'
require 'colorize'
# require 'zip-codes'
require 'csv'
require 'fips_county_codes'

# put broker file in same folder as this script
# assign the file name variable, include `.csv` # => 'broker_counties.csv'
import_filename = 'ja_benefits_counties.csv'
export_filename = 'ja_counties_zipcodes.csv'


# -------------------------------------------------
# csv header default key mapping
# -------------------------------------------------
brokerage_key = 'brokerage'
location_key = 'location'



# -------------------------------------------------
# main variables and methods
# -------------------------------------------------
input_broker_path = "#{`pwd`.chomp}/#{import_filename}"
output_broker_path = "#{`pwd`.chomp}/#{export_filename}"
zip_count_codes_path = "#{`pwd`.chomp}/zip_county_codes.csv"
headers = ['brokerage', 'zipcode', 'state', 'county', 'county_code']


# -------------------------------------------------
# CSV ZipCode County Parsing
# -------------------------------------------------
zip_county_codes_csv = CSV.read(zip_count_codes_path, headers:true)
zip_county_codes_hash = Hash.new
zip_county_codes_csv.each do |row|
  zip_county_codes_hash[row['ZIP']] = row['COUNTY']
end

# -------------------------------------------------
# CSV Broker Parsing
# -------------------------------------------------
broker_county_csv = CSV.read(input_broker_path, headers:true)

# -----------------------------------------------------------
# Create CSV
# -----------------------------------------------------------
count = 0
CSV.open(output_broker_path, 'wb') do |csv|
  csv << headers

  broker_county_codes_array = broker_county_csv.map do |row|
    brokerage = row[brokerage_key].strip
    location = row[location_key].strip

    county, state = location.split(', ')
    county_code = FipsCountyCodes::FIPS[state][county].to_s

    zip_county_codes_hash.each do |zip, county_number|
      if county_number == county_code
        count += 1
        color = count.odd? ? :blue : :light_blue
        puts "[#{brokerage}, #{zip}, #{state}, #{county}, #{county_code}]".colorize(color)
        csv << [brokerage, zip, state, county, county_code]
      end
    end
  end
end







