#!/usr/bin/env ruby

print "Input image: "
source = gets.chomp

print "Output device: "
destination = gets.chomp

print "Block size [1M]: "
bs = gets.chomp.upcase
bs = "1M" if bs.empty?

abort "Input image not found!" unless File.file?(source)
abort "Cannot write directly to a block device!" if File.blockdev?(destination)
abort "Device paths are not supported!" if destination.start_with?("/dev/")

match = /\A(\d+)([KMG]?)\z/.match(bs)
abort "Invalid block size!" unless match

multipliers = {
	""  => 1,
	"K" => 1024,
	"M" => 1024**2,
	"G" => 1024**3
}

buffer_size = match[1].to_i * multipliers[match[2]]
abort "Invalid block size!" if buffer_size.zero?

size = File.size(source)
copied = 0
started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

puts "Starting copy..."

File.open(source, "rb") do |input|
	File.open(destination, "wb") do |output|
		while (buffer = input.read(buffer_size))
			output.write(buffer)
			copied += buffer.bytesize

			elapsed = Process.clock_gettime(
				Process::CLOCK_MONOTONIC
			) - started

			speed = elapsed > 0 ? copied / elapsed / 1024**2 : 0
			percent = size.zero? ? 100.0 : copied * 100.0 / size

			print "\r%.1f%% | %.2f MiB/s | %d / %d bytes" %
				[percent, speed, copied, size]

			$stdout.flush
		end

		output.flush
		output.fsync
	end
end

puts "\nCopy complete!"
