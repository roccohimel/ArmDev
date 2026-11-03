local ffi = require("ffi")

ffi.cdef[[
typedef struct FILE FILE;
FILE *fopen(const char *path, const char *mode);
size_t fread(void *ptr, size_t size, size_t count, FILE *stream);
size_t fwrite(const void *ptr, size_t size, size_t count, FILE *stream);
int fclose(FILE *stream);
int fflush(FILE *stream);
]]

io.write("Input file: ")
local source = io.read("*l")

io.write("Output file: ")
local destination = io.read("*l")

io.write("Block size [1M]: ")
local bs = io.read("*l")
if bs == "" then
	bs = "1M"
end

local units = {
	[""] = 1,
	K = 1024,
	M = 1024^2,
	G = 1024^3
}

local number, unit = bs:upper():match("^(%d+)([KMG]?)$")
assert(number, "Invalid block size")

local block_size = tonumber(number) * units[unit]
assert(block_size > 0, "Invalid block size")

local input = assert(ffi.C.fopen(source, "rb"), "Cannot open input")
local output = assert(ffi.C.fopen(destination, "wb"), "Cannot open output")
local buffer = ffi.new("uint8_t[?]", block_size)

local copied = 0
local started = os.clock()

while true do
	local count = tonumber(ffi.C.fread(buffer, 1, block_size, input))
	if count == 0 then
		break
	end

	local written = tonumber(ffi.C.fwrite(buffer, 1, count, output))
	assert(written == count, "Write failed")

	copied = copied + written

	local elapsed = os.clock() - started
	local speed = elapsed > 0 and copied / elapsed / 1048576 or 0

	io.write(string.format(
		"\r%d bytes | %.2f MiB/s",
		copied, speed
	))
	io.flush()
end

ffi.C.fflush(output)
ffi.C.fclose(output)
ffi.C.fclose(input)

print("\nComplete!")
