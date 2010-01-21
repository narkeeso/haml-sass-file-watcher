#!/usr/local/bin/ruby

require "rubygems"
require "hpricot"

# START CONFIGURATION OPTIONS

# Define where your haml and sass files are stored (omit slashes)
# NOTE: HAML or SASS files must be under these directories.
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

if ARGV.empty?
  puts "Usage: #{$0} watch_folder"
  puts "       Example: #{$0} ."
  exit
end

watch_folder = ARGV[0]
mtimes = {}

puts "Watching #{watch_folder} and subfolders for changes in SASS & HAML files..."

while true do
  files = Dir.glob( File.join( watch_folder, "**", "*.haml" ) )
  files += Dir.glob( File.join( watch_folder, "**", "*.sass" ) )

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
      puts "- #{cmd}"
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