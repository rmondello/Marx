#!/usr/bin/ruby

# Marx
# Richard Mondello
# Convenience script to turn Markdown into HTML or PDF
#
# Dependencies:
# * Ruby 1.9.2
# * Markdown.pl (http://daringfireball.net/projects/markdown/)
# * wkhtmltopdf (http://code.google.com/p/wkhtmltopdf/)
#
# Use:
# * Markdown -> html
#     Marx.rb in.mdown out.html
# * Markdown -> pdf
#     Marx.rb in.mdown out.pdf
# * Custom stylesheet
#     Marx.rb in.mdown out.pdf -s style.css
# * Override file extension inference
#     Marx.rb in.mdown out -f html

# Constants
FORMAT          = "pdf" # either "pdf" or "html"
STYLESHEET      = nil   # style.css
MARKDOWN_SCRIPT = "Markdown.pl"
PDF_APP         = "wkhtmltopdf"
ERROR_CODE      = 1

BANNER = "Usage: Marx.rb [options] input.mdown output.(pdf|html) [pdf options]"

# Dependency check
def prg_exists?(prg)
  `which #{prg}`
  $? == 0
end

unless prg_exists? MARKDOWN_SCRIPT
  puts "Error: could not locate Markdown script"
  puts "http://daringfireball.net/projects/markdown/"
  exit ERROR_CODE
end

unless prg_exists? PDF_APP
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

  options[:stylesheet] = nil
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

begin
  optparse.parse!
rescue
  d = 3
end

input  = ARGV[0]
output = ARGV[1]
unless input and output
  puts BANNER
  exit ERROR_CODE
end
options.delete 0
options.delete 1

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

# Run scripts
input  = File.expand_path ARGV[0]
output = File.expand_path ARGV[1]
temp   = Tempfile.new 'marx'
temp2  = Tempfile.new 'marx'

# check for stylesheet
`#{MARKDOWN_SCRIPT} #{input} > #{temp.path}`

if options[:stylesheet]
  stylesheet = File.expand_path options[:stylesheet]
  `cat #{stylesheet} #{temp.path} > #{temp2.path}`
  `mv #{temp2.path} #{temp.path}`
end

if /(htm|html)/i.match options[:format]
  `mv #{temp.path} #{output}`
elsif /(pdf)/i.match options[:format]
  `cat #{temp.path} | #{PDF_APP} - - > #{output}`
else
  puts "Error: No output format specified."
  exit ERROR_CODE
end

# Clean up
temp.close!
temp2.close!
