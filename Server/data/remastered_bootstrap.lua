local candidates = {
	"../Modules/Remastered/bootstrap.lua",
	"Modules/Remastered/bootstrap.lua",
	"Server/../Modules/Remastered/bootstrap.lua",
}

for _, path in ipairs(candidates) do
	local file = io.open(path, "r")
	if file ~= nil then
		file:close()
		dofile(path)
		return
	end
end

print("[Remastered] bootstrap not found; continuing without Remastered Core")
