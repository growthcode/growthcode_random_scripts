#! /usr/bin/env ruby

require 'nokogiri'
require 'open-uri'
require 'awesome_print'
require 'pry'
require 'colorize'
require 'csv'

url = 'http://www.nahu.org/consumer/findagent3.cfm?State=NE'

# state acronym from URL
state_acronym = url.slice(-2..-1).downcase

# save as filename:
filename = state_acronym + "_nahu"


# -----------------------------------------------------------
# Initial page load gets number of brokers for the state;
# Stop scrapper when we have this many for CSV;
# Also sets up variables and script methods
# -----------------------------------------------------------

page = Nokogiri::HTML(open(url)).css('*').remove_attr('style')
filename_path = "#{`pwd`.chomp}/#{filename}.csv"

string = page.css('body div.container div.contentContainer p b').text
pre_string = "Please note:Displaying 20 people of"
post_string = " found."

num_of_contacts = string.gsub(pre_string, '').gsub(post_string, '').to_i


def is_numeric?(string)
  # `!!` converts parsed number to `true`
  !!Kernel.Float(string)
rescue TypeError, ArgumentError
  false
end

count = 0
name_ary = []
email_ary = []
csv = []
headers = ['name', 'email', 'title', 'work_phone', 'fax', 'chapter', 'website', 'company', 'address1', 'address2', 'city', 'state', 'zip', 'cert_array', 'practice_areas',]

# -----------------------------------------------------------
# Create CSV
# -----------------------------------------------------------
CSV.open(filename_path, 'wb') do |csv|
  csv << headers

  # -----------------------------------------------------------
  # loop until we have all the brokers
  # -----------------------------------------------------------
  while name_ary.count < num_of_contacts
    count += 1

    # -----------------------------------------------------------
    # Get new page load to retrieve new random set set of brokers
    # -----------------------------------------------------------
    page = Nokogiri::HTML(open(url)).css('*').remove_attr('style')


    contact_blocks = page.css('body div.container div.contentContainer > div')

    parsed = contact_blocks.map do |contact|

      name = ''
      email = ''
      title = ''

      work_phone = ''
      fax = ''
      chapter = ''
      website = ''
      company = ''
      address1 = ''
      address2 = ''
      city = ''
      state = ''
      zip = ''
      cert_string = ''
      practice_areas = ''

      name_tag = contact.css('.h2')
      name = name_tag.css('> text()').text.strip
      title_tag = name_tag.css('span')
      title = title_tag.text.strip

      next_element = name_tag.first.next_element

      cert_array = []
      while next_element.name != 'div' do
        if next_element.name == 'b'
          cert_array << next_element.text.strip
        end
        next_element = next_element.next_element
      end
      cert_string == cert_array.join("; ")


      left_div = next_element
      left_div_array = left_div.to_s.gsub(/(<div>|<\/div>|\n|<b>|<\/b>)/, '').split('<br>').map(&:strip).reject(&:empty?)

      company_address = left_div_array.reject do |el|
        if el.include?('Work Phone:')
          work_phone = el.gsub('Work Phone:', '').strip
        end

        if el.include?('Fax:')
          fax = el.gsub('Fax:', '').strip
        end

        el.include?('Work Phone:') || el.include?('Fax:') || el.nil? || el == ''
      end

      company = company_address.shift

      if is_numeric?(company_address.last[-5..-1])
        city, state_zip = company_address.pop.split(', ')
        state = state_zip.split(' ').shift.strip

        zip = state_zip.gsub(state, '').strip
        # if 0 > state_zip[-4..-1].to_i
        #   zip = state_zip[-10..-1]
        # else
        #   zip = state_zip[-5..-1]
        # end
        state = state_zip.gsub(zip, '').strip
      end

      address1, address2 = company_address

      right_div = left_div.next_element

      right_div_array = right_div.to_s.to_s.gsub(/(<div>|<\/div>|\n|<b>|<\/b>|<\/a>)/, '').split('<br>').map(&:strip).reject(&:empty?)

      email = right_div.children.map {|el| el.text.strip }.select {|el| el.include?('@')}.first


      other_details = right_div_array.reject do |el|
        if el.include?('Chapter:')
          chapter = el.gsub('Chapter:', '').strip
        end

        if el.include?('Web Site:')
          website = el.split('>').last.strip
        end

        if el.include?('Practice Areas:')
          practice_areas = el.gsub('Practice Areas:', '').strip
        end

        el.include?('Web Site:') ||
          el.include?('Chapter:') ||
          el.include?('E-mail:') ||
          el.include?('Practice Areas:') ||
          el.nil? ||
          el == ''
      end

      if email.nil? || email.empty?
        email = "__no_email__#{count}"
      end

      if !email_ary.include?(email) #|| name_ary.include?(name)

        name_ary << name
        email_ary << email

        # -----------------------------------------------------------
        # Print to console the new contact added to CSV
        # -----------------------------------------------------------
        puts "#{email_ary.count}.".colorize(:white) + " #{email}".colorize(:light_blue)

        csv << [name, email, title, work_phone, fax, chapter, website, company, address1, address2, city, state, zip, cert_string, practice_areas,]
      end

    end
    # -----------------------------------------------------------
    # Print to console stats of scraper
    # -----------------------------------------------------------
    puts '============================================================'.colorize(:color => :blue)
    puts '============================================================'.colorize(:color => :blue)
    puts " Round #{count} complete, ".colorize(:light_blue) + "#{email_ary.count}" + " of ".colorize(:light_blue) + "#{num_of_contacts}."
    puts '============================================================'.colorize(:color => :blue)
    puts '============================================================'.colorize(:color => :blue)

    # -----------------------------------------------------------
    # Optional Break if loop count is excessive
    # -----------------------------------------------------------
    # break if count == 75
  end
end







