--!nonstrict

local Players = game:GetService("Players")

---@return boolean
local function Error()
	local success, err = pcall(function()
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local animate = Character.Animate
		local idle_anim = animate:FindFirstChild("idle"):FindFirstChild("Animation1")

		local old_animid = idle_anim.AnimationId
		animate.Enabled = true
		idle_anim.AnimationId = "active://" .. ".\n\t\t" .. "ahhh" .. "\n"
		task.wait()
		animate.Enabled = false
		animate.Enabled = true
		idle_anim.AnimationId = old_animid
		task.wait()
		animate.Enabled = false
		animate.Enabled = true
	end)

	return success
end

return Error
