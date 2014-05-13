#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'csv'
require 'slim'
require 'tilt'
require 'tempfile'
require 'launchy'

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
        sku: sku,
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

products = inventory.values.sort_by { |p| [ p[:type], p[:description] ] }

template = Tilt.new('table.slim')
output   = template.render(Object.new, products: products)

file = Tempfile.new(%w(boozer .html))  # The dumb array forces the .html extension
begin
  file.write(output)

  Launchy.open(file.path)
  sleep 3 # Wait until the browser has opened the file
ensure
  file.close
  file.unlink
end
