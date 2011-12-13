#!/usr/bin/env ruby -wKU
# This script takes the one we use in development and makes a production-ready version.
# Includes minification, combination of CSS and JS.

# Commands that should be run manually externally
# Note coffeescript must not wrap the top-level scope
# coffee -cwb *.coffee
# compass watch

cdnPrefix = "http://cdn.logolifter.com/"
#cdnPrefix = "/"	# for dev

puts 'Merging CSS'
# TODO embed images
puts `juicer merge --force -d . css/style.css`

puts 'Merging JS'
# TODO manually collect the scripts out of the HTML
puts `juicer merge --force -s js/jquery.min.js js/jquery-ui.min.js js/handlebars-1.0.0.beta.4.js js/base64.js js/jquery.getimagedata.min.js js/app.js -o js/app.min.js`

stamp = Time.now.to_i
text = File.read 'index-dev.html'

cssUrl = "#{cdnPrefix}css/style.min.css?t=#{stamp}"
text = text.gsub(/<!-- CSS START -->.*<!-- CSS END -->/m, %Q(<link rel="stylesheet" href="#{cssUrl}" />))

jsUrl = "#{cdnPrefix}js/app.min.js?t=#{stamp}"
text = text.gsub(/<!-- JS START -->.*<!-- JS END -->/m, %Q(<script src="#{jsUrl}"></script>))

File.open('index.html', 'w') { |f| f.puts text }


# TODO make sure the caching headers are on

# see http://blog.trydionel.com/2010/08/22/easy-code-reloading-with-fssm/
#require 'rubygems'
#require 'fssm'
#puts "Monitoring for changes..."
#FSSM.Monitor(File.dirname(__FILE__), [''])

