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
def prg_exists?(prg)
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

# Run scripts
input  = File.expand_path input
output = File.expand_path output
temp   = Tempfile.new 'Marx'
temp2  = Tempfile.new 'Marx'

# check for stylesheet
`#{MARKDOWN} #{input} > #{temp.path}`

# --user-style-sheet ../markdown.css

if options[:stylesheet]
  stylesheet = File.expand_path options[:stylesheet]
  `cat #{stylesheet} #{temp.path} > #{temp2.path}`
  `mv #{temp2.path} #{temp.path}`
end

if /(htm|html)/i.match options[:format]
  `mv #{temp.path} #{output}`
elsif /(pdf)/i.match options[:format]
  `cat #{temp.path} | #{PDF} --page-size Letter #{ARGV.join ' '} - - > #{output}`
else
  puts "Error: No output format specified."
  exit ERROR_CODE
end

# Clean up
temp.close!
temp2.close!
