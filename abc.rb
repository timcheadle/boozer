require 'rubygems'
require 'bundler/setup'

require 'json'
require 'rest-client'

host = "https://www.abc.virginia.gov/api/stores/"
sku = ARGV[0]
$debug = ARGV[1] == '--debug'
$stores = {}

def check_quantity(store)
  p store if $debug
  quantity = store['quantity']

  if quantity > 0
    $stores[store['storeId']] = quantity
  end
end

(32..400).each do |store|
  print "#{store} / 400\r"

  if $stores.has_key?(store)
    next
  end

  response = begin
   RestClient.get "#{host}/inventory/#{store}/#{sku}", accept: :json
  rescue => e
    e.response
  end
  stock_json = response.body
  next if stock_json == ""
  stock = JSON.parse(stock_json)

  product = stock['products'][0]
  if product['productId'] = sku.to_s
    check_quantity(product['storeInfo'])

    product['nearbyStores'].each do |nearby_store|
      check_quantity(nearby_store)
    end
  end
end

puts ""
puts ""

$cities = Hash.new { |h,k| h[k] = [] }

$stores.sort.each do |store, qty|
  response = begin
   RestClient.get "#{host}/#{store}", accept: :json
  rescue => e
    e.response
  end
  info_json = response.body
  next if info_json == ""
  info = JSON.parse(info_json)

  address = info['Address']['Address1']
  city    = info['Address']['City']
  zip     = info['Address']['Zipcode']
  phone   = info['PhoneNumber']['FormattedPhoneNumber']
  hours   = info['Hours']

  $cities[city] << "#{store} - qty #{qty} - #{address}, #{city}, #{zip}, #{phone}, #{hours}"
end

$cities.sort.each do |city, lines|
  puts city
  puts "-----"
  puts lines
  puts ""
end

puts ""

total = $stores.values.inject(:+)
puts "Total quantity: #{total}"

if total != nil && total > 0
  num_stores = $stores.keys.length
  avg = total / num_stores

  puts "Avg per store: #{avg}"
end
