#!/bin/ruby

require 'pry'

if ARGV[3].nil?
  puts
  puts "ruby deeptiler.rb IMAGE_PATH IMAGE_SIZE DEPTH OUTPUT_DIR"
  puts
  puts "IMAGE_PATH: _PNG_ image to split without filetype, ex. 'images/buddhabrot'"
  puts "IMAGE_SIZE: assumes square images, ex. '200'"
  puts "DEPTH: how many levels of tiles it should split into, ex. '4'"
  puts "OUTPUT_DIR: where to output the tiles and folder structure, ex. 'tiles/'"
  exit
end

@image = ARGV[0]
@size = ARGV[1].to_i
@depth = ARGV[2].to_i
@outdir = ARGV[3]

@target_dim = @size / (2 ** (@depth - 1))

def rowsplit(input, height, width, z, out_offset = 0)
  print ">> #{z} (#{input}.png)"
  `./im/convert.exe #{input}.png +repage +gravity -crop #{height}x#{width} #{@outdir}/#{z}/%d.png`
  unless out_offset == 0
    `mv #{@outdir}/#{z}/0.png #{@outdir}/#{z}/#{out_offset + 0}.png`
    `mv #{@outdir}/#{z}/1.png #{@outdir}/#{z}/#{out_offset + 1}.png`
  end
  print " [x]\n"
end

def tile(input, height, width, z, y)
  print ">> #{z}/#{y}"
  `./im/convert.exe #{input}.png +repage +gravity -crop #{height}x#{width} -resize #{@target_dim} #{@outdir}/#{z}/#{y}/%d.png`
  print " [x]\n"
end

`rm -r #{@outdir}` if Dir.exists?(@outdir)
Dir.mkdir(@outdir) unless Dir.exists?(@outdir)

def deep_tile
  @depth.times do |z|
    row_count = 2 ** z
    dim = @size / row_count
  
    Dir.mkdir("#{@outdir}/#{z}") unless Dir.exists?("#{@outdir}/#{z}")
  
    if z == 0
      rowsplit(@image, @size, dim, z)
    else
      prev_z = z - 1
      prev_row_count = 2 ** prev_z
      (0...prev_row_count).to_a.reverse.each do |prev_z_row|
        previous_row_image = "#{@outdir}/#{prev_z}/#{prev_z_row}"
        rowsplit(previous_row_image, @size, dim, z, prev_z_row * 2)
        File.delete("#{previous_row_image}.png")
      end
    end
  
    row_count.times do |row_number|
      row_image = "#{@outdir}/#{z}/#{row_number}"
  
      Dir.mkdir("#{@outdir}/#{z}/#{row_number}") unless Dir.exists?("#{@outdir}/#{z}/#{row_number}")
  
      tile(row_image, dim, dim, z, row_number)
      
      File.delete("#{row_image}.png") if z == @depth - 1
    end
  end
end

start_time = Time.now

deep_tile

end_time = Time.now

total_duration = end_time - start_time

puts "Start job: #{start_time}"
puts "       ==> #{total_duration} seconds"
puts "Full time: #{end_time}"

