local Players = game:GetService("Players")

---@param marketplaceid number
---@return boolean
local function PlayMarketplaceAnimation(marketplaceid)
	local success, err = pcall(function()
		local LocalPlayer = Players.LocalPlayer
		local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
		local Humanoid = Character:FindFirstChildOfClass("Humanoid")
		local Animator = Humanoid:FindFirstChildOfClass("Animator")

		local rbx = game:GetObjects("rbxassetid://" .. marketplaceid)
		local animObject = rbx[1]

		if animObject and animObject:IsA("Animation") then
			local track = Animator:LoadAnimation(animObject)
			track:Play()
		else
			warn("Not an Animation object:", animObject)
		end
	end)

	return success
end

return PlayMarketplaceAnimation
