--------------------------------------------------------------
-- ###                   #####                              --
--  #   ####  ######    #     # #    # ###### ###### #    # --
--  #  #    # #         #     # #    # #      #      ##   # --
--  #  #      #####     #     # #    # #####  #####  # #  # --
--  #  #      #         #   # # #    # #      #      #  # # --
--  #  #    # #         #    #  #    # #      #      #   ## --
-- ###  ####  ######     #### #  ####  ###### ###### #    # --
--------------------------------------------------------------
--		 Parasite Bot Version 0.1		--
------------------------------------------
--		  Created by: Mellow_Ink		--
--		  Assistance by: Kairus101		--
------------------------------------------


------------------------------------------
--          Bot Initialization          --
------------------------------------------    

local _G = getfenv(0)
local object = _G.object

object.myName = object:GetName()

object.bRunLogic = true
object.bRunBehaviors = true
object.bUpdates = true
object.bUseShop = true

object.bRunCommands = true
object.bMoveCommands = true
object.bAttackCommands = true
object.bAbilityCommands = true
object.bOtherCommands = true

object.bReportBehavior = false
object.bDebugUtility = false
object.bDebugExecute = false

object.logger = {}
object.logger.bWriteLog = false
object.logger.bVerboseLog = false

object.core = {}
object.eventsLib = {}
object.metadata = {}
object.behaviorLib = {}
object.skills = {}

runfile "bots/core.lua"
runfile "bots/botbraincore.lua"
runfile "bots/eventsLib.lua"
runfile "bots/metadata.lua"
runfile "bots/behaviorLib.lua"

runfile "bots/jungleLib.lua"
local jungleLib = object.jungleLib

local core, eventsLib, behaviorLib, metadata, skills = object.core, object.eventsLib, object.behaviorLib, object.metadata, object.skills

local print, ipairs, pairs, string, table, next, type, tinsert, tremove, tsort, format, tostring, tonumber, strfind, strsub
	= _G.print, _G.ipairs, _G.pairs, _G.string, _G.table, _G.next, _G.type, _G.table.insert, _G.table.remove, _G.table.sort, _G.string.format, _G.tostring, _G.tonumber, _G.string.find, _G.string.sub
local ceil, floor, pi, tan, atan, atan2, abs, cos, sin, acos, max, random
	= _G.math.ceil, _G.math.floor, _G.math.pi, _G.math.tan, _G.math.atan, _G.math.atan2, _G.math.abs, _G.math.cos, _G.math.sin, _G.math.acos, _G.math.max, _G.math.random

local BotEcho, VerboseLog, BotLog = core.BotEcho, core.VerboseLog, core.BotLog
local Clamp = core.Clamp

local sqrtTwo = math.sqrt(2)

BotEcho('loading parasite_main...')

---------------------------------
--          Constants          --
---------------------------------

-- Hero Name
object.heroName = 'Hero_Parasite'

-- Item buy order. internal names
behaviorLib.StartingItems =
	{"Item_IronBuckler", "Item_Scarab"}
behaviorLib.LaneItems =
	{"Item_Marchers", "Item_EnhancedMarchers", "Item_Nuke 5", "Item_SpellShards 3"}
behaviorLib.MidItems =
	{"Item_Lightning2", "Item_Evasion"} 
behaviorLib.LateItems =
	{"Item_Weapon3", "Item_BehemothsHeart", "Item_LifeSteal4"}

-- Skill build. 0 is Leech, 1 is Infest, 2 is Draining Venom, 3 is Facehug, 4 is Attributes
object.tSkills = {
	1, 0, 1, 0, 0,
	3, 0, 2, 2, 2,
	3, 1, 1, 4, 4,
	3, 4, 4, 4, 4,
	4, 4, 4, 4, 4
}

-- Bonus aggression points if a skill/item is available for use
object.nLeechUp = 5
object.nInfestUp = 0
object.nFacehugUp = 10
object.nNukeUp = 7
object.nChargedHammerUp = 4
object.nSymbolOfRageUp = 4

-- Bonus aggression points that are applied to the bot upon successfully using a skill/item
object.nLeechUse = 10
object.nInfestUse = 0
object.nFacehugUse = 20
object.nNukeUse = 14
object.nChargedHammerUse = 8
object.nSymbolOfRageUse = 8

-- Thresholds of aggression the bot must reach to use these abilities
object.nLeechThreshold = 12
object.nInfestThreshold = 0
object.nFacehugThreshold = 40
object.nNukeThreshold = 10
object.nChargedHammerThreshold = 16
object.nSymbolOfRageThreshold = 16

-- Other variables
behaviorLib.nCreepPushbackMul = 0.3
behaviorLib.nTargetPositioningMul = 0.8
behaviorLib.safeTreeAngle = 360

------------------------------
--          Skills          --
------------------------------

function object:SkillBuild()
	core.VerboseLog("SkillBuild()")

	local unitSelf = self.core.unitSelf
	if  skills.abilLeech == nil then
		skills.abilLeech = unitSelf:GetAbility(0)
		skills.abilInfest = unitSelf:GetAbility(1)
		skills.abilDrainingVenom = unitSelf:GetAbility(2)
		skills.abilFacehug = unitSelf:GetAbility(3)
		skills.abilAttributeBoost = unitSelf:GetAbility(4)
	end

	local nPoints = unitSelf:GetAbilityPointsAvailable()
	if nPoints <= 0 then
		return
	end

	local nLevel = unitSelf:GetLevel()
	for i = nLevel, (nLevel + nPoints) do
		unitSelf:GetAbility(self.tSkills[i]):LevelUp()
	end

	if nLevel == 16 then
		jungleLib.currentMaxDifficulty = 300
	end
end

------------------------------------------
--          FindItems Override          --
------------------------------------------

local function funcFindItemsOverride(botBrain)
	local bUpdated = object.FindItemsOld(botBrain)
	
	--removes item if sold
	core.ValidateItem(core.itemGhostMarchers)	
	core.ValidateItem(core.itemNuke)
	core.ValidateItem(core.itemChargedHammer)
	core.ValidateItem(core.itemSymbolOfRage)

	if bUpdated then
		if core.itemNuke and core.itemChargedHammer and core.itemSymbolOfRage then
			return
		end

		local inventory = core.unitSelf:GetInventory(true)
		for slot = 1, 6, 1 do
			local curItem = inventory[slot]
			if curItem then
				if core.itemNuke == nil and curItem:GetName() == "Item_Nuke" then
					core.itemNuke = core.WrapInTable(curItem)
					botecho("got Nuke")					
				elseif core.itemChargedHammer == nil and curItem:GetName() == "Item_Lightning2" then
					core.itemChargedHammer = core.WrapInTable(curItem)
				elseif core.itemSymbolOfRage == nil and curItem:GetName() == "Item_LifeSteal4" then
					core.itemSymbolOfRage = core.WrapInTable(curItem)
				end
			end
		end
	end
end

object.FindItemsOld = core.FindItems
core.FindItems = funcFindItemsOverride

----------------------------------------
--          OnThink Override          --
----------------------------------------

function object:onthinkOverride(tGameVariables)
	self:onthinkOld(tGameVariables)
	
	jungleLib.assess(self)
end

object.onthinkOld = object.onthink
object.onthink = object.onthinkOverride

----------------------------------------------
--          OnCombatEvent Override          --
----------------------------------------------

function object:oncombateventOverride(EventData)
	self:oncombateventOld(EventData)

	local nAddBonus = 0

	if EventData.Type == "Ability" then
		if EventData.InflictorName == "Ability_Parasite1" then
			nAddBonus = nAddBonus + object.nLeechUse
		elseif EventData.InflictorName == "Ability_Parasite2" then
			nAddBonus = nAddBonus + object.nInfestUse
		elseif EventData.InflictorName == "Ability_Parasite4" then
			nAddBonus = nAddBonus + object.nFacehugUse
		end
	elseif EventData.Type == "Item" then
		if core.itemNuke ~= nil and EventData.SourceUnit == core.unitSelf:GetUniqueID() and EventData.InflictorName == core.itemNuke:GetName() then
			nAddBonus = nAddBonus + object.nNukeUse
		elseif core.itemChargedHammer ~= nil and EventData.SourceUnit == core.unitSelf:GetUniqueID() and EventData.InflictorName == core.itemChargedHammer:GetName() then
			nAddBonus = nAddBonus + object.nChargedHammerUse
		elseif core.itemSymbolOfRage ~= nil and EventData.SourceUnit == core.unitSelf:GetUniqueID() and EventData.InflictorName == core.itemSymbolOfRage:GetName() then
			nAddBonus = nAddBonus + object.nBSymbolOfRageUse
		end
	end

	if nAddBonus > 0 then
		core.DecayBonus(self)
		core.nHarassBonus = core.nHarassBonus + nAddBonus
	end
end

object.oncombateventOld = object.oncombatevent
object.oncombatevent = object.oncombateventOverride

----------------------------------------------------
--          CustomHarassUtility Override          --
----------------------------------------------------

local function CustomHarassUtilityFnOverride(hero)
	local nUtility = 0
	
	if skills.abilLeech:CanActivate() then
		nUtility = nUtility + object.nLeechUp
	end
	
	if skills.abilInfest:CanActivate() then
		nUtility = nUtility + object.nInfestUp
	end

	if skills.abilFacehug:CanActivate() then
		nUtility = nUtility + object.nFacehugUp
	end
	
	if object.itemNuke and object.itemNuke:CanActivate() then
		nUtility = nUtility + object.nNukeUp
	end
	
	if object.itemChargedHammer and object.itemChargedHammer:CanActivate() then
		nUtility = nUtility + object.nChargedHammerUp
	end

	if object.itemSymbolOfRage and object.itemSymbolOfRage:CanActivate() then
		nUtility = nUtility + object.nSymbolOfRageUp
	end
	
	return nUtility
end

behaviorLib.CustomHarassUtility = CustomHarassUtilityFnOverride


----------------------------------------
--          Harass Behaviour          --
----------------------------------------

local function HarassHeroExecuteOverride(botBrain)
	
	local unitTarget = behaviorLib.heroTarget
	--Target is invalid, move on to the next behaviour
	if unitTarget == nil then
		return object.harassExecuteOld(botBrain)
	end

	local unitSelf = core.unitSelf
	local vecMyPosition = unitSelf:GetPosition()
	local vecTargetPosition = unitTarget:GetPosition()
	local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPosition, vecTargetPosition)
	local nLastHarassUtility = behaviorLib.lastHarassUtil
	local bActionTaken = false

	-- Leech
	if not bActionTaken then
		local abilLeech = skills.abilLeech
		if abilLeech:CanActivate() and nLastHarassUtility > botBrain.nLeechThreshold then
				bActionTaken = core.OrderAbilityEntity(botBrain, abilLeech, unitTarget, false)
		end
	end

	-- Facehug
	if not bActionTaken then
		local abilFacehug = skills.abilFacehug
		if abilFacehug:CanActivate() and nLastHarassUtility > botBrain.nFacehugThreshold then
			bActionTaken = core.OrderAbilityEntity(botBrain, abilFacehug, unitTarget, false)
		end
	end

	-- Codex
	if not bActionTaken then
		local itemNuke = core.itemNuke
		if itemNuke then
			local nNukeRange = itemNuke:GetRange()
			if itemNuke:CanActivate() and nLastHarassUtility > botBrain.nNukeThreshold then
				if nTargetDistanceSq <= (nNukeRange * nNukeRange) then
					bActionTaken = core.OrderItemEntityClamp(botBrain, unitSelf, itemNuke, unitTarget)
					bActionTaken = core.OrderAttackClamp(botBrain, unitSelf, unitTarget, false, true)
				elseif nTargetDistanceSq > (nNukeRange * nNukeRange) then
					bActionTaken = core.OrderMoveToUnitClamp(botBrain, unitSelf, unitTarget)
				end
			end
		end
	end

	if not bActionTaken then
		return object.harassExecuteOld(botBrain)
	end

	return bActionTaken
end

object.harassExecuteOld = behaviorLib.HarassHeroBehavior["Execute"]
behaviorLib.HarassHeroBehavior["Execute"] = HarassHeroExecuteOverride

---------------------------------------
--          Jungle Behavior          --
---------------------------------------
--
-- Utility: 21
-- This is effectively an "idle" behavior
--
-- Execute:
-- Move to unoccupied camps
-- Attack strongest Neutral until they are all dead
--

-------- Global Constants & Variables --------
behaviorLib.nCreepAggroUtility = 0
--behaviorLib.nRecentDamageMul = 0.20

-------- Behavior Functions --------
function jungleUtility(botBrain)
	if HoN.GetRemainingPreMatchTime() and HoN.GetRemainingPreMatchTime()>40000 then
		return 0
	end
	-- Wait until level 9 to start grouping/pushing/defending
	behaviorLib.nTeamGroupUtilityMul = 0.13 + core.unitSelf:GetLevel() * 0.01
	behaviorLib.pushingCap = 13 + core.unitSelf:GetLevel()
	behaviorLib.nTeamDefendUtilityVal = 13 + core.unitSelf:GetLevel()
	return 21
end

function jungleExecute(botBrain)
	local unitSelf = core.unitSelf
	local debugMode = true

	local vecMyPos = unitSelf:GetPosition()
	local vecTargetPos, nCamp = jungleLib.getNearestCampPos(vecMyPos, 0, jungleLib.currentMaxDifficulty)
	if not vecTargetPos then
		if core.myTeam == HoN.GetHellbourneTeam() then
			return core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, jungleLib.jungleSpots[7].outsidePos)
		else
			return core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, jungleLib.jungleSpots[1].outsidePos)
		end
	end

	if debugMode then core.DrawDebugArrow(vecMyPos, vecTargetPos, 'green') end
	
	local nTargetDistanceSq = Vector3.Distance2DSq(vecMyPos, vecTargetPos)
	--BotEcho(math.sqrt(nTargetDistanceSq))
	if nTargetDistanceSq > (550 * 550) then
		--moving to the camp
		if (skills.abilInfest:CanActivate()) then
			return core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, vecTargetPos)
		else
			return core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, jungleLib.jungleSpots[nCamp].outsidePos)
		end
	else 
		-- Kill neutrals in the camp
		local tUnits = HoN.GetUnitsInRadius(vecMyPos, 800, core.UNIT_MASK_ALIVE + core.UNIT_MASK_UNIT)
		if tUnits then
			if (skills.abilInfest:CanActivate()) then
				-- Find the strongest unit in the camp
				local nHighestHealth = 0
				local unitStrongest = nil
				for _, unitTarget in pairs(tUnits) do
					if unitTarget:GetHealth() > nHighestHealth and unitTarget:IsAlive() and unitTarget:GetTeam() ~= core.myTeam and unitTarget:GetTeam() ~= core.enemyTeam then
						unitStrongest = unitTarget
						nHighestHealth = unitTarget:GetHealth()
					end
				end
				-- Infest the strongest unit
				if unitStrongest then
					bActionTaken = core.OrderAbilityEntity(botBrain, skills.abilInfest, unitStrongest, false)
				else
					return core.OrderAttackPosition(botBrain, unitSelf, vecTargetPos)
				end
			end
			if unitSelf:GetAbility(0):CanActivate() then
				core.OrderAbility(botBrain, unitSelf:GetAbility(0))
			else
				local nLowestHealth = 0
				local unitWeakest = nil
				for _, unitTarget in pairs(tUnits) do
					if unitTarget:GetHealth() < nLowestHealth and unitTarget:IsAlive() and unitTarget:GetTeam() ~= core.myTeam and unitTarget:GetTeam() ~= core.enemyTeam then
						unitWeakest = unitTarget
						nLowestHealth = unitTarget:GetHealth()
					end
				end
				if (unitWeakest) then
					core.OrderAttackClamp(botBrain, unitSelf, unitWeakest, false)
				else
					return core.OrderAttackPosition(botBrain, unitSelf, vecTargetPos)
				end
			end
		else
			return core.OrderMoveToPosAndHoldClamp(botBrain, unitSelf, vecTargetPos)
		end
	end
	return false
end

behaviorLib.jungleBehavior = {}
behaviorLib.jungleBehavior["Utility"] = jungleUtility
behaviorLib.jungleBehavior["Execute"] = jungleExecute
behaviorLib.jungleBehavior["Name"] = "jungle"
tinsert(behaviorLib.tBehaviors, behaviorLib.jungleBehavior)

----------------------------------------
--          Behaviour Changes         --
----------------------------------------

function zeroUtility(botBrain)
	return 0
end

behaviorLib.PositionSelfBehavior["Utility"] = zeroUtility
behaviorLib.PreGameBehavior["Utility"] = zeroUtility

-----------------------------------
--          Custom Chat          --
-----------------------------------

core.tKillChatKeys={
    "BUAHAHAHA!",
    "Off with their heads!",
    "I put the meaning into human blender.",
    "You spin me right round!",
    "Did I break your spirit?",
    "You spin my head right round, right round. When ya go down, when ya go down down."
}

core.tDeathChatKeys = {
    "Spinning out of control..",
    "I think I'm gonna throw up...",
    "Stop taunting me!",
    "Off with.....my head?"
}

BotEcho(object:GetName()..' finished loading parasite_main')