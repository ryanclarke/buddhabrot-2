#!/bin/ruby

require 'pry'

@start_time = Time.now

if ARGV[3].nil?
  puts
  puts "ruby tilegluer.rb INPUT_DIR IMAGE_SIZE DEPTH OUTPUT_DIR"
  puts
  puts "INPUT_DIR: where the y-coordinate dirs are (0/, 1/, etc.) ex. 'tiles/3/'"
  puts "IMAGE_SIZE: assumes square images, ex. '200'"
  puts "DEPTH: how many levels of tiles it should glue, ex. '4'"
  puts "OUTPUT_DIR: no copy if the root dir is the same as INPUT_DIR, ex. 'tiles/'"
  exit
end

@input_dir = ARGV[0]
@image_size = "#{ARGV[1]}x#{ARGV[1]}+0+0"
@depth = ARGV[2].to_i
@max_z = @depth - 1
@output_dir = ARGV[3]

def create_dir(dir)
  Dir.mkdir(dir) unless Dir.exists?(dir)
end

def clean_dir(dir)
  `rm -r #{dir}` if Dir.exists?(dir)
  create_dir(dir)
end

def get_path(z, y = nil, x = nil)
  path = "#{@output_dir}#{z}/"
  path << "#{y}/" unless y.nil?
  path << "#{x}.png" unless x.nil?
  path
end

def get_quad_paths(z, y1, y2, x1, x2)
 "#{get_path(z, y1, x1)} #{get_path(z, y1, x2)} #{get_path(z, y2, x1)} #{get_path(z, y2, x2)}"
end

def get_out_path(z, y, x = nil)
  y1 = y / 2
  x1 = x / 2 unless x.nil?
  path = get_path(z, y1, x1)
  path
end

def level_dim(z)
  2 ** z
end

def create_level(z)
  create_dir(get_path(z))
  prev_z = z + 1
  prev_dim = level_dim(prev_z)
  prev_dim.times.each_slice(2) do |y1, y2|
    out_path = get_out_path(z, y1)
    print_timing_info(out_path)
    create_dir(out_path)
    prev_dim.times.each_slice(2) do |x1, x2|
      out_path = get_out_path(z, y1, x1)
      `./im/montage.exe #{get_quad_paths(prev_z, y1, y2, x1, x2)} -geometry #{@image_size} #{out_path}`
      `./im/convert.exe #{out_path} -resize #{@image_size} #{out_path}`
    end
  end
end

def create_levels
  (0...@max_z).to_a.reverse.each do |z|
    create_level(z)
  end
end

def create_deepest_level
  create_dir(get_path(@max_z))
  `cp -Rf #{@input_dir} #{@output_dir}`
end

def print_timing_info(path)
  vars = path.split("/").reverse
  y = vars[0].to_i
  z = vars[1].to_i
  elapsed_time = Time.now - @mid_time
  estimated_time = elapsed_time / percent_complete(z, y)
  puts "populating #{path} ... (elapsed: #{elapsed_time} sec; estimated: #{estimated_time} sec)"
end

def percent_complete(z, y)
  count = number_of_tiles_above(z)
  count += y * (2 ** z)
  total = number_of_tiles_above(0)
  count / total.to_f
end

def number_of_tiles_above(z)
  start = z + 1
  (start...@max_z).reduce(0) {|sum, n| sum += 4 ** n }
end

create_dir(@output_dir)
create_deepest_level

@mid_time = Time.now
@copy_duration = @mid_time - @start_time

create_levels

end_time = Time.now

generation_duration = end_time - @mid_time
total_duration = end_time - @start_time

puts "Start job: #{@start_time}"
puts "       ==> #{@copy_duration} seconds"
puts "Copy done: #{@mid_time}"
puts "       ==> #{generation_duration} seconds"
puts "Full time: #{end_time}"
puts "       ==> #{total_duration} seconds"


