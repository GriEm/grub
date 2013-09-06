require './ImageLoader'
require 'optparse'

options = {}

opt_parser = OptionParser.new do |opt|

  opt.banner =  "Usage: grub.rb URL path [options]"
  opt.separator ""
  opt.separator "  URL  - web-page (with http://)"
  opt.separator "  path - folder"
  opt.separator ""
  opt.separator "Specific options:"
  opt.separator ""

  opt.on("-p","--proxy PROXY",String,"1") do |proxy|
    options[:proxy] = proxy
  end

  opt.on("-u","--user USER",String,"2") do |user|
    options[:user] = user
  end

  opt.on("-s","--password PASSWORD",String,"3") do |psw|
    options[:psw] = psw
  end

  opt.separator ""
  opt.separator "Common options:"
  opt.separator ""

  opt.on("-h","--help") do
    STDOUT.puts opt
  end

  opt.separator ""
  opt.separator "Example:"
  opt.separator ""
  opt.separator "  grub.rb 'http://www.test.ru' img"
  opt.separator "  grub.rb 'http://www.test.ru' img -p server:8080 -u tester -s qwerty"

end

begin
  opt_parser.parse!
rescue => err
  puts err
end

if ARGV.empty?
  puts opt_parser
else
  begin
    loader = ImageLoader.new(options[:proxy],options[:user],options[:psw])
    loader.load(ARGV[0],ARGV[1])
  rescue => ex
    puts ex
  end
end