# frozen_string_literal: true

require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
civic_info.key = File.read('api.key').strip

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(str)
  /^1?(\d{10})$/.match(str.gsub(/\D/, ''))&.captures
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip, levels: 'country', roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') { |file| file.puts form_letter }
end

puts 'EventManager initialized.'

contents = CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)

# Create thank you letters
def create_thank_you_letters(contents)
  template_letter = File.read('form_letter.erb')
  erb_template = ERB.new template_letter

  contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode])
    legislators = legislators_by_zipcode(zipcode)

    form_letter = erb_template.result(binding)
    save_thank_you_letter(id, form_letter)
  end
end

# Assignment part 1
def clean_phone_numbers(contents)
  contents.each do |row|
    puts clean_phone_number(row[:homephone])
  end
end

# create_thank_you_letters(contents)
clean_phone_numbers(contents)
