#!/usr/bin/env ruby

require 'rubygems'
require 'open-uri'
require 'nokogiri'

PRODUCT_URL = 'http://www.meckabc.com/Products'

doc = Nokogiri::HTML(open(PRODUCT_URL))

categories = doc.xpath('//select[contains(@id,"AlcoholType")]/option[@value != "-1"]').map { |node| node.attribute('value').value.strip }

categories.sort.each do |category|
  url = URI::encode("http://www.meckabc.com/Products?t=#{category}&d=&c=")
  doc = Nokogiri::HTML(open(url))

  headers = doc.xpath('//table[contains(@id,"SearchResults")]/*/th').map { |node| node.text.strip }
  rows    = doc.xpath('//table[contains(@id,"SearchResults")]/*/tr[not(descendant::th)]')
end
