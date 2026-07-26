-- im not dumping hydroxide into a single file currently

local owner = "Upbolt"
local branch = "revision"

local function webImport(file)
	return loadstring(
		game:HttpGetAsync(("https://raw.githubusercontent.com/%s/Hydroxide/%s/%s.lua"):format(owner, branch, file)),
		file .. ".lua"
	)()
end

webImport("init")
webImport("ui/main")
