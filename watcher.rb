#!/usr/local/bin/ruby

require "rubygems"
require "hpricot"

# START CONFIGURATION OPTIONS

# Define where your haml and sass files are stored (omit slashes)
# NOTE: HAML or SASS files must be in the root of named directories
haml_dir_name = "haml"
sass_dir_name = "sass"

# Define your output folders (can be relative to the watched folder)
haml_output_dir = "output"
sass_output_dir = "stylesheets"

# Define your haml output extension (useful if you want another output such as "php")
haml_output_ext = "html"

# Choose your SASS output style (consult current sass documentation for available styles)
# As of Sass 2.2.17 options are "nested", "expanded", "compact", "compressed"
sass_style = "compact"

# END OF CONFIGURATION OPTIONS

trap("SIGINT") { exit }

# Set defaults
disable_haml = nil
disable_sass = nil
watching = false # Folder watching is disabled unless argument conditions are met

# Assign arguments
arg = ARGV[0]
watch_folder = ARGV[1]

if watch_folder == nil
  puts "\n\tUsage:\t#{$0} --arg(optional) watch_folder"
  puts "\tExample: #{$0} ."
  puts "\t\t--help for more options"
  exit
end

case arg
when "--sass"
  puts "\n\tWatching #{watch_folder} and subfolders for changes in SASS files only...\n"
  puts "\n\tSASS files must be in root of directory #{sass_dir_name}\n"
  disable_haml = true
  watching = true
when "--haml"
  puts "\n\tWatching #{watch_folder} and subfolders for changes in HAML files only...\n"
  puts "\n\tHAML files must be in root of directory #{haml_dir_name}\n"
  disable_sass = true
  watching = true
when "--help"
  puts "\n\tUsage:"
  puts "\t\t--help  :  This help file."
  puts "\t\t--haml  :  Watch haml files only."
  puts "\t\t--sass  :  Watch sass files only."
  puts "\n\t\tUse no arguments to watch both haml and sass files."
  puts ""
  exit
else
  watch_folder = ARGV[0]
  puts "\n\tWatching #{watch_folder} and subfolders for changes in SASS & HAML files..."
  puts "\tTo watch HAML or SASS files only use --sass or --haml\n"
  watching = true
end

if ARGV.empty? then
  puts "\n\tUsage:\t#{$0} --arg(optional) watch_folder"
  puts "\tExample: #{$0} ."
  puts "\t\t--help for more options"
  exit
end

  mtimes = {}

while watching == true do
  files = Dir.glob( File.join( watch_folder, "**", "*.haml" "#{disable_haml}") ) # Argument --sass will disable haml file look ups
  files += Dir.glob( File.join( watch_folder, "**", "*.sass" "#{disable_sass}") ) # Argument --haml will disable sass file look ups

  new_hash = files.collect {|f| [ f, File.stat(f).mtime.to_i ] }
  hash ||= new_hash
  diff_hash = new_hash - hash

  unless diff_hash.empty?
    hash = new_hash

    diff_hash.each do |df|
      f = df.first
  
      output_file = ""
      options = ""
      is_haml = false
  
      ex = f.match(/(#{sass_dir_name}|#{haml_dir_name})$/)[1]
      case ex
      when "#{haml_dir_name}"
        output_folder = "#{watch_folder}/#{haml_output_dir}"
        Dir.mkdir(output_folder) unless File.directory?(output_folder)
    
        output_file = f.gsub(/\/haml\/([^\/]+)\.haml/, "/#{haml_output_dir}/" '\1.' "#{haml_output_ext}")
        is_haml = true

      when "#{sass_dir_name}"
        output_folder = "#{watch_folder}/#{sass_output_dir}"
        Dir.mkdir(output_folder) unless File.directory?(output_folder)

        output_file = f.gsub(/\/sass\/([^\/]+)\.sass/, "/#{sass_output_dir}/" '\1.css')
        options = "--style #{sass_style}"

      end

      cmd = "#{ex} #{options} #{f} #{output_file}"
      puts "\t*Change detected - #{cmd}"
      system(cmd)
  
      next unless is_haml
  
      html = Hpricot( File.read(output_file) )
      (html/"include").each do |inc|
        fragment = File.read("#{watch_folder}/#{haml_output_dir}/#{ inc['file'] }.#{haml_output_ext}") rescue nil
        next unless fragment
  
        inc.swap("\n<!-- INCLUDE: #{ inc['file'] } START -->\n#{fragment}<!-- INCLUDE: #{ inc['file'] } END -->\n")
      end
  
      File.open(output_file, "w") do |f|
        f.puts html.to_html
      end
  
    end
  end

  sleep 1
end