#!/usr/bin/env ruby
# MIT License
#
# Copyright (c) 2017 Andrea Scarpino <me@andreascarpino.it>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

require 'net/http'
require 'json'
require 'optparse'
require 'ostruct'
require 'rss'

$options = OpenStruct.new
$options.tag = nil
$options.limit = 20
$options.instanceUrl = "mastodon.social"

def getToots(maxId = nil)
  if $options.tag.nil?
    uri = URI("https://#{$options.instanceUrl}/api/v1/timelines/public")
  else
    uri = URI("https://#{$options.instanceUrl}/api/v1/timelines/tag/#{$options.tag}")
  end

  params = { :limit => 40,
             :max_id => maxId }
  uri.query = URI.encode_www_form(params)

  res = Net::HTTP.get_response(uri)
  if res.is_a?(Net::HTTPSuccess)
    res
  else
    puts "Something went wrong :-("
    exit
  end
end

def parse(args)
  opt_parser = OptionParser.new do |opts|
    opts.banner = "Usage: feedtoot.rb [options]"
    opts.separator ""
    opts.separator "Options:"

    opts.on("--tag <tag>", "Fetch toots with this tag") do |tag|
      $options.tag = tag
    end

    opts.on("-l", "--limit <n>", Integer, "Fetch at most N toots (default: 20)") do |limit|
      $options.limit = limit
    end

    opts.on("-u", "--url <url>", "Mastodon instance URL") do |url|
      $options.instanceUrl = url
    end

    opts.on_tail("-h", "--help", "Show this help") do
      puts opts
      exit
    end
  end

  opt_parser.parse!(args)
end

def makeRSS
  if $options.tag.nil?
    title = "#{$options.instanceUrl}'s public toots"
    link = "https://#{$options.instanceUrl}/web/timelines/public"
  else
    title = "#{$options.instanceUrl}'s #{$options.tag} toots"
    link = "https://#{$options.instanceUrl}/web/timelines/tag/#{$options.tag}"
  end

  rss = RSS::Maker.make("2.0") do |maker|
    channel = maker.channel
    channel.title = title
    channel.description = channel.title
    channel.link = link

    counter = 0
    catch :done do
      while counter < $options.limit
        res = getToots

        JSON.parse(res.body).each do |toot|
          addToot(maker, toot)

          counter += 1
          throw :done if counter >= $options.limit
        end

        if not res['Link'].nil?
          res = getToots(res['Link'].scan(/.*&max_id=(\d+).*/).first.first)
        else
          break
        end
      end
    end
  end

  rss
end

def addToot(maker, toot)
  maker.items.new_item do |item|
    content = toot.fetch("content").gsub(/<\/?[^>]*>/, "")
    item.title = content

    # Elide title when text is very long
    if item.title.length >= 40
      item.title = item.title[0, 37]
      item.title += '...'
    end

    item.link = toot.fetch("url")
    item.description = content
    item.pubDate = toot.fetch("created_at")
    item.author = toot.fetch("account").fetch("acct")
  end
end

parse(ARGV)

rss = makeRSS

puts rss unless rss.nil?
