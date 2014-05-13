#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'csv'

BASE_URL    = 'http://www.meckabc.com'
PRODUCT_URL = "#{BASE_URL}/Products"

inventory = {}

root_doc = Nokogiri::HTML(open(PRODUCT_URL))
categories = root_doc.css('select[id *= "AlcoholType"] option:not([value = "-1"])').map { |node| node.attribute('value').value.strip }

category_patterns = [
  /bourbon/i,
  /rye/i,
  /special packages/i,
]

def match_any?(patterns, value)
  patterns.map { |p| p.match(value) }.reject{ |v| v.nil? }.any?
end

categories.sort.each do |category|
  next unless match_any?(category_patterns, category)

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
      link = BASE_URL + cells[6].css('a').attr('href')

      inventory[sku] = {
        brand: brand,
        type: type,
        description: description,
        size: size,
        price: price,
        link: link,
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
    product[:link],
  ].to_csv
end
