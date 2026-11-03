#!/usr/bin/env ruby

print "Input file: "
source = gets.chomp

print "Output file: "
destination = gets.chomp

print "Block size [1M]: "
bs = gets.chomp.upcase
bs = "1M" if bs.empty?

units = {
	"" => 1,
	"K" => 1024,
	"M" => 1024**2,
	"G" => 1024**3
}

match = /\A(\d+)([KMG]?)\z/.match(bs)
abort "Invalid block size" unless match

block_size = match[1].to_i * units[match[2]]
abort "Invalid block size" if block_size.zero?

size = File.size(source)
copied = 0
started = Process.clock_gettime(Process::CLOCK_MONOTONIC)

File.open(source, "rb") do |input|
	File.open(destination, "wb") do |output|
		while (buffer = input.read(block_size))
			output.write(buffer)
			copied += buffer.bytesize

			elapsed = Process.clock_gettime(
				Process::CLOCK_MONOTONIC
			) - started

			speed = elapsed > 0 ? copied / elapsed / 1048576.0 : 0
			percent = size.zero? ? 100 : copied * 100.0 / size

			printf "\r%.1f%% | %.2f MiB/s | %d / %d bytes",
				percent, speed, copied, size

			$stdout.flush
		end

		output.flush
		output.fsync
	end
end

puts "\nComplete!"
