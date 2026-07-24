local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local Workspace      = workspace

local LocalPlayer    = Players.LocalPlayer

local function getChar(plr)
	plr = plr or LocalPlayer
	return plr and plr.Character
end

local function getRoot(char)
	return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChildWhichIsA("BasePart"))
end

local function getHum(char)
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getHead(char)
	return char and char:FindFirstChild("Head")
end

local function getTorso(char)
	return char
		and (char:FindFirstChild("UpperTorso")
		  or char:FindFirstChild("Torso"))
end

local flingManager = {}

flingManager.FlingVelocity        = Vector3.new(9e7, 9e8, 9e7)
flingManager.FlingAngularVelocity = Vector3.new(9e8, 9e8, 9e8)
flingManager.MoverFlingVelocity   = Vector3.new(9e8, 9e8, 9e8)
flingManager.cFlingOldPos         = nil

function flingManager.IsFiniteNumber(v)
	return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

function flingManager.IsFiniteVector(v)
	return typeof(v) == "Vector3"
		and flingManager.IsFiniteNumber(v.X)
		and flingManager.IsFiniteNumber(v.Y)
		and flingManager.IsFiniteNumber(v.Z)
end

function flingManager.SetFlingVelocity(part)
	if not part then return end
	pcall(function() part.AssemblyLinearVelocity  = flingManager.FlingVelocity end)
	pcall(function() part.AssemblyAngularVelocity = flingManager.FlingAngularVelocity end)
	pcall(function() part.Velocity    = flingManager.FlingVelocity end)
	pcall(function() part.RotVelocity = flingManager.FlingAngularVelocity end)
end

function flingManager.SetMoverFlingVelocity(mover)
	if not mover then return end
	pcall(function() mover.Velocity = flingManager.MoverFlingVelocity end)
end

function flingManager.ClearPartVelocity(part)
	if not part then return end
	local zero = Vector3.zero
	pcall(function() part.AssemblyLinearVelocity  = zero end)
	pcall(function() part.AssemblyAngularVelocity = zero end)
	pcall(function() part.Velocity    = zero end)
	pcall(function() part.RotVelocity = zero end)
end

function flingManager.GetPartVelocity(part)
	local best, bestSq = Vector3.zero, 0
	if not part then return best, 0 end

	local ok, av = pcall(function() return part.AssemblyLinearVelocity end)
	if ok and flingManager.IsFiniteVector(av) then
		best   = av
		bestSq = av:Dot(av)
	end

	local ok2, lv = pcall(function() return part.Velocity end)
	if ok2 and flingManager.IsFiniteVector(lv) then
		local sq = lv:Dot(lv)
		if sq > bestSq then best = lv; bestSq = sq end
	end

	return best, math.sqrt(bestSq)
end

local function fling(targetPlayer)
	local char     = getChar(LocalPlayer)
	local hum      = getHum(char)
	local root     = hum and hum.RootPart or getRoot(char)
	if not root then return end

	local tChar    = getChar(targetPlayer)
	if not tChar then return end
	local tHum     = getHum(tChar)
	local tRoot    = tHum and tHum.RootPart or getRoot(tChar)
	local tHead    = getHead(tChar)
	local acc      = tChar:FindFirstChildOfClass("Accessory")
	local handle   = acc and acc:FindFirstChild("Handle")

	local orgFPDH  = Workspace.FallenPartsDestroyHeight

	local function targetLost(basePart)
		return not tChar or not basePart:IsDescendantOf(tChar)
	end

	local _, rootSpeed = flingManager.GetPartVelocity(root)
	if not flingManager.cFlingOldPos or rootSpeed < 50 then
		flingManager.cFlingOldPos = root.CFrame
	end

	local flingPart = Instance.new("Part")
	flingPart.Anchored    = false
	flingPart.CanCollide  = false
	flingPart.Transparency = 1
	flingPart.Size        = Vector3.one
	flingPart.CFrame      = root.CFrame
	flingPart.Parent      = Workspace

	local weld   = Instance.new("WeldConstraint")
	weld.Part0   = flingPart
	weld.Part1   = root
	weld.Parent  = flingPart

	local function cleanupFlingPart()
		if flingPart then flingPart:Destroy(); flingPart = nil end
	end

	if tHead then
		Workspace.CurrentCamera.CameraSubject = tHead
	elseif tHum then
		Workspace.CurrentCamera.CameraSubject = tHum
	end

	if not tChar:FindFirstChildWhichIsA("BasePart") then
		cleanupFlingPart(); return
	end

	local function FPos(basePart, pos, ang)
		local cf = CFrame.new(basePart.Position) * pos * ang
		flingPart.CFrame = cf

		pcall(function() char:PivotTo(cf) end)
		flingManager.SetFlingVelocity(flingPart)
	end

	local function SFBasePart(basePart)
		local timeLimit = tick() + 2
		local angle = 0
		repeat
			if root and tHum then
				local _, baseSpeed = flingManager.GetPartVelocity(basePart)
				if baseSpeed < 50 then
					angle += 100
					FPos(basePart, CFrame.new(0, 1.5, 0)   + tHum.MoveDirection * baseSpeed/1.25, CFrame.Angles(math.rad(angle),0,0)) task.wait()
					FPos(basePart, CFrame.new(0,-1.5, 0)   + tHum.MoveDirection * baseSpeed/1.25, CFrame.Angles(math.rad(angle),0,0)) task.wait()
					FPos(basePart, CFrame.new( 2.25, 1.5,-2.25) + tHum.MoveDirection * baseSpeed/1.25, CFrame.Angles(math.rad(angle),0,0)) task.wait()
					FPos(basePart, CFrame.new(-2.25,-1.5, 2.25) + tHum.MoveDirection * baseSpeed/1.25, CFrame.Angles(math.rad(angle),0,0)) task.wait()
					FPos(basePart, CFrame.new(0, 1.5, 0)   + tHum.MoveDirection, CFrame.Angles(math.rad(angle),0,0)) task.wait()
					FPos(basePart, CFrame.new(0,-1.5, 0)   + tHum.MoveDirection, CFrame.Angles(math.rad(angle),0,0)) task.wait()
				else
					local _, tRootSpeed = flingManager.GetPartVelocity(tRoot)
					FPos(basePart, CFrame.new(0, 1.5, tHum.WalkSpeed),     CFrame.Angles(math.rad(90),0,0)) task.wait()
					FPos(basePart, CFrame.new(0,-1.5,-tHum.WalkSpeed),     CFrame.Angles(0,0,0))            task.wait()
					FPos(basePart, CFrame.new(0, 1.5, tHum.WalkSpeed),     CFrame.Angles(math.rad(90),0,0)) task.wait()
					FPos(basePart, CFrame.new(0, 1.5, tRootSpeed/1.25),    CFrame.Angles(math.rad(90),0,0)) task.wait()
					FPos(basePart, CFrame.new(0,-1.5,-tRootSpeed/1.25),    CFrame.Angles(0,0,0))            task.wait()
					FPos(basePart, CFrame.new(0, 1.5, tRootSpeed/1.25),    CFrame.Angles(math.rad(90),0,0)) task.wait()
					FPos(basePart, CFrame.new(0,-1.5, 0),                  CFrame.Angles(math.rad(90),0,0)) task.wait()
					FPos(basePart, CFrame.new(0,-1.5, 0),                  CFrame.Angles(0,0,0))            task.wait()
					FPos(basePart, CFrame.new(0,-1.5, 0),                  CFrame.Angles(math.rad(-90),0,0))task.wait()
					FPos(basePart, CFrame.new(0,-1.5, 0),                  CFrame.Angles(0,0,0))            task.wait()
				end
			else
				break
			end
		until targetLost(basePart)
			or targetPlayer.Parent ~= Players
			or hum.Health <= 0
			or tick() > timeLimit
	end

	Workspace.FallenPartsDestroyHeight = 0/0

	local bv        = Instance.new("BodyVelocity")
	bv.MaxForce     = Vector3.new(math.huge, math.huge, math.huge)
	bv.Parent       = flingPart
	flingManager.SetMoverFlingVelocity(bv)

	hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)

	if tRoot and tHead then
		if (tRoot.CFrame.p - tHead.CFrame.p).Magnitude > 5 then
			SFBasePart(tHead)
		else
			SFBasePart(tRoot)
		end
	elseif tRoot   then SFBasePart(tRoot)
	elseif tHead   then SFBasePart(tHead)
	elseif handle  then SFBasePart(handle)
	end

	bv:Destroy()
	cleanupFlingPart()
	hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
	Workspace.CurrentCamera.CameraSubject = hum

	repeat
		local returnCF = flingManager.cFlingOldPos * CFrame.new(0, 0.5, 0)
		pcall(function() char:PivotTo(returnCF) end)
		hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		for _, p in char:GetChildren() do
			if p:IsA("BasePart") then flingManager.ClearPartVelocity(p) end
		end
		task.wait()
	until (root.Position - flingManager.cFlingOldPos.p).Magnitude < 25

	Workspace.FallenPartsDestroyHeight = orgFPDH
end

local walkflingConn  = nil
local walkflingActive = false
local walkflingSpeed  = 10000

local function parseFlingSpeed(value)
	local speed = tonumber(value)
	if not speed or speed ~= speed or speed <= 0 then speed = 10000 end
	return math.clamp(speed, 1, 1e9)
end

local function walkFlingBurst(root, speed)
	if not (root and root.Parent) then return end
	speed    = parseFlingSpeed(speed)
	local ok, v = pcall(function() return root.Velocity end)
	if not ok or typeof(v) ~= "Vector3" then
		v = select(1, flingManager.GetPartVelocity(root))
	end
	pcall(function() root.Velocity = v * speed + Vector3.new(0, speed, 0) end)
	RunService.RenderStepped:Wait()
	if root and root.Parent then
		pcall(function() root.Velocity = v end)
	end
	RunService.Stepped:Wait()
	if root and root.Parent then
		pcall(function() root.Velocity = v + Vector3.new(0, 0.1, 0) end)
	end
end

local function startWalkFling(speed)
	walkflingSpeed  = parseFlingSpeed(speed)
	walkflingActive = true
	if walkflingConn then walkflingConn:Disconnect() end
	walkflingConn = RunService.Heartbeat:Connect(function()
		if not walkflingActive then return end
		local ch = getChar(LocalPlayer)
		local r  = ch and getRoot(ch)
		if r then walkFlingBurst(r, walkflingSpeed) end
	end)
end

local function stopWalkFling()
	walkflingActive = false
	if walkflingConn then walkflingConn:Disconnect(); walkflingConn = nil end
end

local touchflingActive = false
local touchflingConn   = nil
local touchflingSpeed  = 10000

local touchFlingState = {
	busy    = false,
	range   = 3.35,
	params  = nil,
	dirs    = {},
	origins = {},
	ignore  = {},
}

local function touchFlingFilterType()
	local ok, v = pcall(function() return Enum.RaycastFilterType.Exclude end)
	return (ok and v) or Enum.RaycastFilterType.Blacklist
end

local function touchFlingModel(part)
	local cur = part
	while cur and cur ~= Workspace do
		if cur:IsA("Model") then
			local h = getHum(cur)
			local r = (h and h.RootPart) or getRoot(cur)
			if h and r then return cur end
		end
		cur = cur.Parent
	end
	return nil
end

local function touchFlingTarget(model, char)
	if not (model and model:IsA("Model") and model.Parent) then return false end
	if char and (model == char or model:IsDescendantOf(char)) then return false end
	local h = getHum(model)
	if not h or h.Health <= 0 then return false end
	local plr = Players:GetPlayerFromCharacter(model)
	if plr then return plr ~= LocalPlayer end
	return true
end

local function touchFlingDetect(char, root, hum)
	if not (char and root and root.Parent) then return nil end

	local st = touchFlingState
	st.params = st.params or RaycastParams.new()
	st.params.FilterType = touchFlingFilterType()
	st.params.IgnoreWater = true
	st.ignore[1] = char
	for i = 2, #st.ignore do st.ignore[i] = nil end
	st.params.FilterDescendantsInstances = st.ignore

	local cf  = root.CFrame
	local dirs = st.dirs
	dirs[1]  = cf.LookVector
	dirs[2]  = -cf.LookVector
	dirs[3]  = cf.RightVector
	dirs[4]  = -cf.RightVector
	dirs[5]  = Vector3.new(0,  1, 0)
	dirs[6]  = Vector3.new(0, -1, 0)
	dirs[7]  = (cf.LookVector + cf.RightVector).Unit
	dirs[8]  = (cf.LookVector - cf.RightVector).Unit
	dirs[9]  = (-cf.LookVector + cf.RightVector).Unit
	dirs[10] = (-cf.LookVector - cf.RightVector).Unit
	local dCount = 10
	local mv = hum and hum.MoveDirection or Vector3.zero
	if mv.Magnitude > 0.05 then dCount += 1; dirs[dCount] = mv.Unit end

	local origins = st.origins
	origins[1]    = root.Position
	local oCount  = 1
	local torso   = getTorso(char)
	if torso and torso ~= root then oCount += 1; origins[oCount] = torso.Position end
	local head    = getHead(char)
	if head and head ~= root and head ~= torso then oCount += 1; origins[oCount] = head.Position end
	for i = oCount + 1, #origins do origins[i] = nil end

	local dist = tonumber(st.range) or 3.35
	for o = 1, oCount do
		for d = 1, dCount do
			local dir = dirs[d]
			if dir and dir.Magnitude > 0 then
				local ok, result = pcall(function() return Workspace:Raycast(origins[o], dir * dist, st.params) end)
				local inst  = ok and result and result.Instance or nil
				local model = inst and touchFlingModel(inst)
				if touchFlingTarget(model, char) then return model end
			end
		end
	end
	return nil
end

local function startTouchFling(speed)
	touchflingSpeed = parseFlingSpeed(speed)
	touchflingActive = true
	stopWalkFling()
	if touchflingConn then touchflingConn:Disconnect() end
	touchflingConn = RunService.Heartbeat:Connect(function()
		if not touchflingActive then return end
		local ch = getChar(LocalPlayer)
		local h  = getHum(ch)
		local r  = ch and ((h and h.RootPart) or getRoot(ch))
		if r and h and touchFlingDetect(ch, r, h) then
			if not touchFlingState.busy then
				touchFlingState.busy = true
				walkFlingBurst(r, touchflingSpeed)
				touchFlingState.busy = false
			end
		end
	end)
end

local function stopTouchFling()
	touchflingActive = false
	touchFlingState.busy = false
	if touchflingConn then touchflingConn:Disconnect(); touchflingConn = nil end
end

local loopflingActive = false
local loopflingId     = 0

local function startLoopFling(targetPlayer)
	loopflingActive = false
	task.wait()
	loopflingActive = true
	loopflingId    += 1
	local id        = loopflingId

	task.spawn(function()
		while loopflingActive and id == loopflingId do
			if targetPlayer then
				if targetPlayer.Parent == Players and targetPlayer ~= LocalPlayer then
					pcall(fling, targetPlayer)
				end
			else
				for _, p in Players:GetPlayers() do
					if p ~= LocalPlayer then pcall(fling, p) end
				end
			end
			task.wait(0.05)
		end
	end)
end

local function stopLoopFling()
	loopflingActive = false
	loopflingId    += 1
end

local clickflingConn    = nil
local clickflingActive  = false

local function startClickFling()
	clickflingActive = true
	local mouse = LocalPlayer:GetMouse()
	if clickflingConn then clickflingConn:Disconnect() end
	clickflingConn = mouse.Button1Down:Connect(function()
		if not clickflingActive then return end
		local target = mouse.Target
		if not target then return end

		local model = target
		while model and not model:IsA("Model") do model = model.Parent end
		local targetPlayer = model and Players:GetPlayerFromCharacter(model)
		if targetPlayer and targetPlayer ~= LocalPlayer then
			pcall(fling, targetPlayer)
		end
	end)
end

local function stopClickFling()
	clickflingActive = false
	if clickflingConn then clickflingConn:Disconnect(); clickflingConn = nil end
end

local function startFlyFling(speed)
	stopWalkFling()
	startWalkFling(speed)

end

local function stopFlyFling()
	stopWalkFling()

end

local function invisfling()
	local player    = LocalPlayer
	local character = getChar(player)
	local humanoid  = getHum(character)
	if not (player and character and humanoid) then return end

	humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)

	local proxyModel    = Instance.new("Model")
	proxyModel.Name     = "InvisFlingProxy"
	proxyModel.Parent   = character

	local torso         = Instance.new("Part")
	torso.Name          = "Torso"
	torso.CanCollide    = false
	torso.Anchored      = true
	torso.Position      = Vector3.new(0, 9999, 0)
	torso.Parent        = proxyModel

	local head          = Instance.new("Part")
	head.Name           = "Head"
	head.CanCollide     = false
	head.Anchored       = true
	head.Parent         = proxyModel

	local proxyHum      = Instance.new("Humanoid")
	proxyHum.Name       = "Humanoid"
	proxyHum.Parent     = proxyModel

	player.Character    = proxyModel
	task.wait(3)
	player.Character    = character
	task.wait(3)

	character = getChar(player)
	if not character then return end

	local root = getRoot(character)
	if not root then return end

	for _, child in character:GetChildren() do
		if child ~= root and not child:IsA("Humanoid") then
			child:Destroy()
		end
	end

	root.Transparency = 0
	root.Color        = Color3.new(1, 1, 1)

	local invisConn
	invisConn = RunService.PreSimulation:Connect(function()
		local ch = getChar(player)
		local r  = ch and getRoot(ch)
		if r then
			r.CanCollide = false
		else
			invisConn:Disconnect()
		end
	end)

	local thrust        = Instance.new("BodyThrust")
	thrust.Force        = Vector3.new(99999, 999990, 99999)
	thrust.Location     = root.Position
	thrust.Parent       = root

	Workspace.CurrentCamera.CameraSubject = root
end

local function flingNPCs()
	for _, hum in Workspace:GetDescendants() do
		if hum:IsA("Humanoid") then
			local model = hum.Parent

			if model and not Players:GetPlayerFromCharacter(model) then
				pcall(function() hum.HipHeight = 1024 end)
			end
		end
	end
end

return {
	fling          = fling,

	startWalkFling = startWalkFling,
	stopWalkFling  = stopWalkFling,
	walkFlingBurst = walkFlingBurst,

	startTouchFling = startTouchFling,
	stopTouchFling  = stopTouchFling,

	startLoopFling = startLoopFling,
	stopLoopFling  = stopLoopFling,

	startClickFling = startClickFling,
	stopClickFling  = stopClickFling,

	startFlyFling  = startFlyFling,
	stopFlyFling   = stopFlyFling,

	invisfling     = invisfling,
	flingNPCs      = flingNPCs,

	flingManager   = flingManager,
	parseFlingSpeed = parseFlingSpeed,
}
--[[
local randomTarget = (function()
    local list = {}
    for _, p in Players:GetPlayers() do
        if p ~= LocalPlayer then
            list[#list + 1] = p
        end
    end
    return list[math.random(#list)]
end)()

if randomTarget then
    fling(randomTarget)
end
]]