require 'nokogiri'
require 'open-uri'
require 'csv'
require 'set'
require 'write_xlsx'

# Function to clean text from non-printable characters
def clean_text(text)
  text.gsub(/\s+/, ' ').strip
end

# Function to parse data from each apartment page
def parse_apartment_page(url)
  html = URI.open(url)
  doc = Nokogiri::HTML(html)

  short_info = {}
  facility_infrastructure = []
  description = ''
  property_id = ''
  price = ''
  city = ''
  location = ''
  property_type = ''

  # Parsing the Property ID
  property_id_section = doc.at_css('div.property-id')
  property_id = clean_text(property_id_section.text.split(': ').last) if property_id_section

  # Parsing the price
  price_section = doc.at_css('div.detail-block-price meta[itemprop="price"]')
  price = clean_text(price_section['content']) if price_section

  # Parsing short info
  short_info_section = doc.css('div.detail-params-property-items ul.line_param__list li.detail-style-ln')
  short_info_section.each do |item|
    key_element = item.at_css('div.value-param-detail')
    key = key_element ? clean_text(key_element.text.split(': ').first) : clean_text(item.at_css('i').next_sibling.text)
    value = clean_text(item.css('a, span').map(&:text).join(' / '))

    # Check for city and location
    if key == 'Property type'
      property_type = value
    elsif value.include?(' / ')
      city_candidate, location_candidate = value.split(' / ')
      if ['Alanya', 'Gazipasa', 'Antalya', 'Istanbul', 'Cyprus', 'Bodrum', 'Mersin', 'Other cities'].include?(city_candidate)
        city = city_candidate
        location = location_candidate
      else
        short_info[key] = value
      end
    else
      short_info[key] = value
    end
  end

  # Parsing facilities and infrastructure
  facility_section = doc.css('ul.infrastructure-list li.infrastructure-item')
  facility_section.each do |item|
    facility_infrastructure << clean_text(item.text)
  end

  # Parsing description
  description_section = doc.at_css('div.new-detail-description-text')
  description = clean_text(description_section.text) if description_section

  # Compile all data into one dictionary
  data = short_info
  data['Facility infrastructure'] = facility_infrastructure.join(', ')
  data['Description'] = description
  data['Property ID'] = property_id
  data['Price'] = price
  data['City'] = city
  data['Location'] = location
  data['Property type'] = property_type
  data['URL'] = url

  data
end

# Loading links from CSV file
links = CSV.read('apartment_links.csv', headers: true).map { |row| row['Link'] }

# Collect all possible headers
all_headers = Set.new
apartment_data = links.map do |link|
  full_url = "https://restproperty.com#{link}"
  begin
    data = parse_apartment_page(full_url)
    all_headers.merge(data.keys)
    data
  rescue StandardError => e
    puts "Error parsing #{full_url}: #{e.message}"
    nil
  end
end.compact

# Removing empty headers
all_headers.delete('City') if all_headers.include?('City') && apartment_data.all? { |row| row['City'].nil? || row['City'].empty? }
all_headers.delete('Location') if all_headers.include?('Location') && apartment_data.all? { |row| row['Location'].nil? || row['Location'].empty? }
all_headers.delete('Property type') if all_headers.include?('Property type') && apartment_data.all? { |row| row['Property type'].nil? || row['Property type'].empty? }

# Saving data to XLSX file
workbook = WriteXLSX.new('apartment_data.xlsx')
worksheet = workbook.add_worksheet

headers = all_headers.to_a
worksheet.write_row(0, 0, headers)

apartment_data.each_with_index do |row, index|
  worksheet.write_row(index + 1, 0, headers.map { |header| row[header] })
end

workbook.close

puts "Data saved to apartment_data.xlsx"
