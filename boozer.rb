#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'csv'

PRODUCT_URL = 'http://www.meckabc.com/Products'

inventory = {}

root_doc = Nokogiri::HTML(open(PRODUCT_URL))
categories = root_doc.css('select[id *= "AlcoholType"] option:not([value = "-1"])').map { |node| node.attribute('value').value.strip }

categories.sort.each do |category|
  url = URI::encode("http://www.meckabc.com/Products?t=#{category}&d=&c=")
  doc = Nokogiri::HTML(open(url))

  next unless doc

  results = doc.css('table[id *= "SearchResults"]')

  headers = results.css('th').map { |node| node.text.strip }
  rows    = results.css('tr')

  rows.each do |row|
    cells = row.css('> td')

    if cells.any?
      sku, brand, type, description, size, price = cells.map { |node| node.text.strip }

      inventory[sku] = {
        brand: brand,
        type: type,
        description: description,
        size: size,
        price: price,
      }
    end
  end
end

inventory.keys.sort.each do |sku|
  product = inventory[sku]

  puts [
    sku,
    product[:brand],
    product[:type],
    product[:description],
    product[:size],
    product[:price],
  ].to_csv
end
