local pcall = pcall

local task = task
local task_wait = task.wait

local print = print

local Players = game:GetService("Players")

---@param Message string
---@return boolean
local function Error()
	local success, err = pcall(function()
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local animate = Character.Animate
		local idle_anim = animate:FindFirstChild("idle"):FindFirstChild("Animation1")

		local old_animid = idle_anim.AnimationId
		animate.Enabled = true
		idle_anim.AnimationId = "active://" .. ".\n\t\t" .. "PublicAbuse" .. "\n"
		task_wait()
		animate.Enabled = false
		animate.Enabled = true
		idle_anim.AnimationId = old_animid
		task_wait()
		animate.Enabled = false
		animate.Enabled = true
	end)

	return success
end

return Error
