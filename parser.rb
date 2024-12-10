require 'httparty'
require 'nokogiri'
require 'csv'

# Базовый URL страницы для парсинга
base_url = 'https://restproperty.com/filter/?type-search=44&rooms=&type-country=1&reginput%5B0%5D=47&price1=&price2=&objectid=&area-from=&area-to=&etag-from=&etag-to=&year-from=&year-to=&sea-from=&sea-to=&aero=&PAGEN_1='

# Метод для получения HTML страницы
def fetch_page(url)
  response = HTTParty.get(url)
  if response.code == 200
    Nokogiri::HTML(response.body)
  else
    puts "Ошибка при запросе страницы: #{response.code}"
    nil
  end
end

# Метод для извлечения данных о недвижимости с одной страницы
def extract_properties(parsed_page)
  properties = []
  parsed_page.css('.propery-list__item').each do |item|
    city_element = item.at_css('.property_info_city')
    price_element = item.at_css('.propery-info__price')
    rooms_element = item.at_css('.property_info_room')
    area_element = item.at_css('.property_info_area')

    city = city_element ? city_element.text.strip : 'N/A'
    price = price_element ? price_element.text.strip : 'N/A'
    rooms = rooms_element ? rooms_element.text.strip : 'N/A'
    area = area_element ? area_element.text.strip : 'N/A'

    properties << { city: city, price: price, rooms: rooms, area: area }
  end
  properties
end

# Метод для проверки наличия следующей страницы
def next_page_exists?(parsed_page)
  !parsed_page.at_css('.page-nav__item.page-nav__item--next').nil?
end

# Сбор всех данных со всех страниц
all_properties = []
page_number = 1

loop do
  puts "Загрузка страницы #{page_number}"
  url = "#{base_url}#{page_number}"
  parsed_page = fetch_page(url)
  break if parsed_page.nil?

  properties = extract_properties(parsed_page)
  all_properties.concat(properties)

  break unless next_page_exists?(parsed_page)
  page_number += 1
end

# Запись данных в CSV файл
CSV.open('properties.csv', 'wb') do |csv|
  csv << ['City', 'Price', 'Rooms', 'Area']
  all_properties.each do |property|
    csv << [property[:city], property[:price], property[:rooms], property[:area]]
  end
end

puts 'Данные успешно сохранены в properties.csv'