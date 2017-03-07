require 'open-uri'
require 'nokogiri'
require 'csv'
require 'httparty'
require 'rubygems'
require 'active_support'
require 'active_support/all'



csv_options = { col_sep: ';', force_quotes: true, quote_char: '"' }
filepath    = 'restaurants.csv'
CSV.open(filepath, 'a+', csv_options) do |csv|
  csv << ["resto_name", "error_message", "resto_mean_price", "resto_mean_rating", "resto_kitchen_rating", "resto_service_rating", "resto_ambiance_rating", "resto_labels_qualiteprix", "resto_labels_niveausonore", "resto_labels_tempsdattente", "resto_tags"]
end

response = HTTParty.get('https://nsvojtaze0.execute-api.us-east-1.amazonaws.com/dev/places')
puts response["items"].first["name"]

response["items"].each do |hash_places|

  # For each restaurant - Data to be collected
  resto_name = hash_places["name"].parameterize
  error_message = "no error"
  resto_url = "resto_url_test"
  resto_mean_price = "zero pas cher"
  resto_tags = []
  resto_mean_rating = 0
  resto_kitchen_rating = 0
  resto_service_rating = 0
  resto_ambiance_rating = 0
  resto_labels = []

  #  Step 1 - Searching for the restaurant url from home page
  html_file_search = open("https://www.lafourchette.com/search-refine/#{resto_name}/2017-03-07/19:30:00/3")
  html_doc_search = Nokogiri::HTML(html_file_search)

  # Step 1.1 - Check if error or if results exist
  if html_doc_search.search('.noResultContainer').count > 0
    error_message = "Error message from search bar"
    CSV.open(filepath, 'a+', csv_options) do |csv|
      csv << [resto_name, error_message, resto_mean_price, resto_mean_rating, resto_kitchen_rating, resto_service_rating, resto_ambiance_rating, resto_labels[0], resto_labels[1], resto_labels[2], resto_tags]
    end
  else
    if html_doc_search.search('.resultItem-name a').count > 0
      # puts html_doc_search.search('.resultItem-name a').first
      element = html_doc_search.search('.resultItem-name a').first
      name = element.text.strip
      puts name
      suffix = element.attribute('href')
      resto_url = "https://www.lafourchette.com#{suffix}"
      puts resto_url

      # Step 2 - Getting the data from to the restaurant page
      # html_file_resto = open('https://www.lafourchette.com/restaurant/hao-long/215199')
      html_file_resto = open("#{resto_url}")
      html_doc_resto = Nokogiri::HTML(html_file_resto)

      html_doc_resto.search('.restaurantSummary-price').each do |element|
       # puts element.text
       # puts resto_mean_price = element.text.strip.scan(/\d+.\d/)
       resto_mean_price = element.text.gsub("\n", "").strip.scan(/\d+/).first
      end

      html_doc_resto.search('#restaurantTagContainer li').each do |element|
       resto_tags << element.text
      end
      # print resto_tags

      html_doc_resto.search('#restaurantAvgRating .rating--big .rating-ratingValue').each do |element|
         puts element.text
         resto_mean_rating = element.text.gsub(/^$\n/, "").strip
      end

      html_doc_resto.search('#restaurantAvgRating').each do |element|
         resto_kitchen_rating = element.attribute('data-score-kitchen')
         resto_service_rating = element.attribute('data-score-service')
         resto_ambiance_rating = element.attribute('data-score-ambiance')
      end

      html_doc_resto.search('.reviewSummary-reviewStat').each do |element|
        resto_labels << element.text.strip
      end
      # print resto_labels

      # Last step : storing everything about this restaurant in a CSV
      CSV.open(filepath, 'a+', csv_options) do |csv|
        csv << [resto_name, error_message, resto_mean_price, resto_mean_rating, resto_kitchen_rating, resto_service_rating, resto_ambiance_rating, resto_labels[0], resto_labels[1], resto_labels[2], resto_tags]
      end
    else
      puts "Error message from restaurant list"
    end
  end
end









