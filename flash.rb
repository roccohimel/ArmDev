#!/usr/bin/env ruby

print "Input image: "
source = gets.chomp

print "Output file: "
destination = gets.chomp

print "Block size [1M]: "
bs = gets.chomp.upcase
bs = "1M" if bs.empty?

abort "Input image not found!" unless File.file?(source)
abort "Output must not be a block device!" if File.blockdev?(destination)
abort "Output must not be a device!" if destination.start_with?("/dev/")

match = /\A(\d+)([KMG]?)\z/.match(bs)
abort "Invalid block size!" unless match

multipliers = {
	""  => 1,
	"K" => 1024,
	"M" => 1024**2,
	"G" => 1024**3
}

buffer_size = match[1].to_i * multipliers[match[2]]
abort "Block size must be greater than zero!" if buffer_size.zero?

size = File.size(source)
copied = 0

puts "Starting copy..."
puts "Block size: #{bs}"

File.open(source, "rb") do |input|
	File.open(destination, "wb") do |output|
		while (buffer = input.read(buffer_size))
			output.write(buffer)
			copied += buffer.bytesize

			percent = size.zero? ? 100.0 : copied * 100.0 / size
			print "\rCopied: #{copied} / #{size} bytes (#{percent.round(1)}%)"
			$stdout.flush
		end

		output.flush
		output.fsync
	end
end

puts "\nCopy complete!"
