#!/usr/bin/ruby

# Marx
# Richard Mondello
# https://github.com/rmondello/Marx

# Constants
FORMAT     = "pdf" # either "pdf" or "html"
STYLESHEET = nil   # style.css
MARKDOWN   = "Markdown.pl"
PDF        = "wkhtmltopdf"
ERROR_CODE = 1

BANNER = "Usage: Marx.rb in.mdown out.(pdf|html) [options]"

# Dependency check
def prg_exists? (prg)
  `which #{prg}`
  $? == 0
end

unless prg_exists? MARKDOWN
  puts "Error: could not locate Markdown script"
  puts "http://daringfireball.net/projects/markdown/"
  exit ERROR_CODE
end

unless prg_exists? PDF
  puts "Error: could not locate html to pdf script"
  puts "http://code.google.com/p/wkhtmltopdf/"
  exit ERROR_CODE
end

# Options parsing
require "optparse"
require "tempfile"
options = {}

optparse = OptionParser.new do |opts|
  opts.banner = BANNER

  options[:stylesheet] = STYLESHEET
  opts.on( '-s', '--stylesheet file', 'use file as stylesheet' ) do |file|
    options[:stylesheet] = file
  end
  
  options[:format] = nil
  opts.on( '-f', '--format fmt',
                 'html|pdf, overrides file extension inference' ) do |fmt|
    options[:format] = fmt
  end
    
  opts.on( '-h', '--help', 'display this screen' ) do
    puts opts
    exit ERROR_CODE
  end
end

input  = ARGV.shift
output = ARGV.shift
unless input and output
  puts BANNER
  exit ERROR_CODE
end

begin
  optparse.parse!
rescue => e
  e.recover(ARGV) # put rejected arguments back
end

# Output format inference
unless options[:format]           # -f (--format) flag overrides filename
  if /(.htm|.html)$/.match(output)
    options[:format] = "html"
  elsif /(.pdf$)/.match(output)
    options[:format] = "pdf"
  else
    options[:format] = FORMAT
  end
end

# Set up file paths
input  = File.expand_path(input)
output = File.expand_path(output)
style  = options[:stylesheet] ? File.expand_path(options[:stylesheet]) : nil

# File checks
def file_check (path, type)
  unless FileTest.exists?(path)
    puts "Error: #{type} file not found: #{path}"
    exit ERROR_CODE
  end
end

file_check(input, "Input")
file_check(style, "Stylesheet") if options[:stylesheet]

# Prepare html
style_data = style ? IO.read(style) : ""
body_data = `#{MARKDOWN} #{input.gsub(/\s/, '\ ')}`

html_data = ["<html>\n<head>\n<style>\n" \
            , style_data \
            , "\n</style>\n</head>\n<body>\n" \
            , body_data \
            , "\n</body>\n</html>" \
            ].join

# Write proper output, whether html or pdf
if /(htm|html)/i.match options[:format]
  File.open(output, 'w') { |f| f.write(html_data) }
elsif /(pdf)/i.match options[:format]
  temp = Tempfile.new 'Marx'
  File.open(temp.path, 'w') { |f| f.write(html_data) }
  `cat #{temp.path} | #{PDF} --page-size Letter #{ARGV.join ' '} - - > #{output.gsub(/\s/, '\ ')}`
  temp.close!
else
  puts "Error: No output format specified"
  exit ERROR_CODE
end
