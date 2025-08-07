local function log(msg) DEFAULT_CHAT_FRAME:AddMessage(msg) end -- alias for convenience
local GetSpellInfoVanilla = CreateFrame("Frame", nil, UIParent, "ActionButtonTemplate")

GetSpellInfoVanilla.OnEvent = function() -- functions created in "object:method"-style have an implicit first parameter of "this", which points to object || in 1.12 parsing arguments as ... doesn't work
	this[event](GetSpellInfoVanilla, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10) -- route event parameters to GetSpellInfoVanilla:event methods
end
GetSpellInfoVanilla:SetScript("OnEvent", GetSpellInfoVanilla.OnEvent)
GetSpellInfoVanilla:RegisterEvent("PLAYER_ENTERING_WORLD")

function GetSpellInfoVanilla_OnUpdate(elapsed)
end

function GetSpellInfoVanilla:PLAYER_ENTERING_WORLD()

end

function GetSpellInfoById(id)
	local name, rank, icon, cost, isFunnel, powerType
	name = GetSpellInfoVanillaDB["spells"][id]["name"]
	rank = GetSpellInfoVanillaDB["spells"][id]["rank"]
	icon = GetSpellInfoVanillaDB["spells"][id]["icon"]
	cost = GetSpellInfoVanillaDB["spells"][id]["cost"]
	isFunnel = GetSpellInfoVanillaDB["spells"][id]["isFunnel"]
	powerType = GetSpellInfoVanillaDB["spells"][id]["powerType"]
	
	return name, rank, icon, cost, isFunnel, powerType
end

function GetSpellInfoByIcon(Icon)
	local resultArray = {}
	for id,v in pairs(GetSpellInfoVanillaDB["spells"]) do
		local name, rank, icon, cost, isFunnel, powerType
		name = GetSpellInfoVanillaDB["spells"][id]["name"]
		rank = GetSpellInfoVanillaDB["spells"][id]["rank"]
		icon = GetSpellInfoVanillaDB["spells"][id]["icon"]
		cost = GetSpellInfoVanillaDB["spells"][id]["cost"]
		isFunnel = GetSpellInfoVanillaDB["spells"][id]["isFunnel"]
		powerType = GetSpellInfoVanillaDB["spells"][id]["powerType"]
		if icon == Icon then
			if type(resultArray[id]) ~= "table" then resultArray[id] = {} end
			resultArray[id]["name"] = name
			resultArray[id]["rank"] = rank
			resultArray[id]["icon"] = icon
			resultArray[id]["cost"] = cost
			resultArray[id]["isFunnel"] = isFunnel
			resultArray[id]["powerType"] = powerType
		end
	end
	return resultArray
end

function GetSpellInfoByName(Name)
	local resultArray = {}
	for id,v in pairs(GetSpellInfoVanillaDB["spells"]) do
		local name, rank, icon, cost, isFunnel, powerType
		name = GetSpellInfoVanillaDB["spells"][id]["name"]
		rank = GetSpellInfoVanillaDB["spells"][id]["rank"]
		icon = GetSpellInfoVanillaDB["spells"][id]["icon"]
		cost = GetSpellInfoVanillaDB["spells"][id]["cost"]
		isFunnel = GetSpellInfoVanillaDB["spells"][id]["isFunnel"]
		powerType = GetSpellInfoVanillaDB["spells"][id]["powerType"]
		if Name == name then
			if type(resultArray[id]) ~= "table" then resultArray[id] = {} end
			resultArray[id]["name"] = name
			resultArray[id]["rank"] = rank
			resultArray[id]["icon"] = icon
			resultArray[id]["cost"] = cost
			resultArray[id]["isFunnel"] = isFunnel
			resultArray[id]["powerType"] = powerType
		end
	end
	return resultArray
end

function GetSpellInfoByIconAndName(Icon, Name)
	local resultArray = {}
	for id,v in pairs(GetSpellInfoVanillaDB["spells"]) do
		local name, rank, icon, cost, isFunnel, powerType
		name = GetSpellInfoVanillaDB["spells"][id]["name"]
		rank = GetSpellInfoVanillaDB["spells"][id]["rank"]
		icon = GetSpellInfoVanillaDB["spells"][id]["icon"]
		cost = GetSpellInfoVanillaDB["spells"][id]["cost"]
		isFunnel = GetSpellInfoVanillaDB["spells"][id]["isFunnel"]
		powerType = GetSpellInfoVanillaDB["spells"][id]["powerType"]
		if icon == Icon and name == Name then
			if type(resultArray[id]) ~= "table" then resultArray[id] = {} end
			resultArray[id]["name"] = name
			resultArray[id]["rank"] = rank
			resultArray[id]["icon"] = icon
			resultArray[id]["cost"] = cost
			resultArray[id]["isFunnel"] = isFunnel
			resultArray[id]["powerType"] = powerType
		end
	end
	return resultArray
end

function GSIV_Test()
	local buffTexture, buffApplications = UnitBuff("target", 1);
	local tempTable = GetSpellInfoByIcon(buffTexture)
	for k,v in pairs(tempTable) do
		log(k.."  "..v["name"])
	end
end
