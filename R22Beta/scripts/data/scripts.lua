-- ============================ GLOBAL ===================================
-- Note that global vars cannot be accessed via subfunctions!!
squadtable = {} -- tracks all squad objects on map
commandeertable = {} -- tracks units commandeered by avatar 
harvturntable = {} -- tracks harv turn
harvturncounttable = {} -- tracks harv turn change count
harvturntimetable = {} -- tracks last harv turn time
harvwarntimetable = {} -- tracks last warn time for harv bug per player
-- MOBA vars
mobacratetable = {} -- tracks moba salvage crate ids
mobaherocratetable = {} -- tracks moba hero crate level
mobastriketable = {} -- tracks moba airstrike progress
mobapowertable = {} -- tracks moba power objects
mobashockreg = {} -- tracks moba shock ownership
mobashockpods = {} -- tracks moba summoned shocktroopers per player
mobafiendreg = {} -- tracks moba tibfiend ownership
mobafiends = {} -- tracks moba summoned tibfiends per player
mobaapcreg = {} -- tracks moba apc ownership
mobaspawnreg = {} -- tracks moba spawner ownership
mobaheroreg = {} -- tracks moba hero ownership
mobarespawntimerreg = {} -- tracks moba respawntimer ownership
mobaspawnreg1 = {} -- tracks moba spawner ownership (spotter)
mobaheroreg1 = {} -- tracks moba hero ownership (spotter)
mobarespawntimerreg1 = {} -- tracks moba respawntimer ownership (spotter)
mobatotalkills = 0 -- tracks moba total kills
mobateam = {} -- tracks moba player side
mobakills = {} -- tracks moba kills per player
mobadeaths = {} -- tracks moba deaths per player
mobaassists = {} -- tracks moba assists per player
mobakillspree = {} -- tracks moba kill spree per player
mobadmgtracker = {} -- tracks moba last attacker
mobaquerycount = 0 -- tracks moba query count
mobaheroreset = {} -- tracks hero reset status
mobaunitteam = {} -- tracks moba original teams
mobaunitside = {} -- tracks moba original side
mobasideplayercount = {} -- tracks moba player count per side
mobachargestatus = {} -- tracks ability charge status
mobaredemptionstatus = {} -- tracks redemption status per player
mobactfmode = 0 -- tracks CTF mode
mobactfbase = {} -- tracks CTF flag in base per team
mobactftimer = 0 -- tracks CTF flag timers active
mobactftimerteam = {} -- tracks CTF flag timer per team
mobaarenamode = 0 -- tracks Arena mode
mobatimecount = {} -- tracks time elapsed per player
mobadetectionhackstatus = {} -- tracks detection hack enabled for player
mobaregenpods = {} -- tracks regen pod count
mobaenergypods = {} -- tracks energy pod count
mobatest = {}
mobaspawnrego = {}

playerTimes = {}
epicUnits = {"30354418", "565BE825", "CD5A5360", "1D137C85", "A4FD281B", "37F0A5F5", "D8BE0529", "711A18DF", "146C2890"}
husksTable = {}
playerTable = {"Player_1","Player_2","Player_3","Player_4","Player_5","Player_6","Player_7","Player_8","PlyrGDI", "Neutral", "PlyrNOD", "PlyrBlackHand", 
"PlyrSteelTalons", "PlyrAlien", "PlyrTraveler59", "PlyrZOCOM", "PlyrMarkedOfKane", "PlyrNeutral", "PlyrReaper17", "Skirmish", "SkirmishAlien", 
"SkirmishBlackHand", "SkirmishCivilian", "SkirmishCommentator", "SkirmishGDI", "SkirmishMarkedOfKane",
"SkirmishNeutral", "SkirmishNod", "SkirmishNull", "SkirmishObserver", "SkirmishReaper17","SkirmishSteelTalons", "SkirmishTraveler59", "SkirmishZOCOM", "PlyrCreeps", "PlyrCivilian"}

-- Ensure every player starts with the exact same variables
function CreateBaseTeamTable()
    return {
        units = {},
        reverseUnits = {},
        reverseUnitsByType = {},
        unitCount = 0,
        reverseUnitCount = 0
    }
end

teamPlayer_1 = CreateBaseTeamTable()
teamPlayer_2 = CreateBaseTeamTable()
teamPlayer_3 = CreateBaseTeamTable()
teamPlayer_4 = CreateBaseTeamTable()
teamPlayer_5 = CreateBaseTeamTable()
teamPlayer_6 = CreateBaseTeamTable()
teamPlayer_7 = CreateBaseTeamTable()
teamPlayer_8 = CreateBaseTeamTable()

function WriteToFile(file, content) 
	local file = openfile("C:\\Users\\Public\\Documents\\" .. file, "a")
	if file then
		write(file, content)
		closefile(file)
	end
end

function isValidTeam(team)
	if team == nil then return false end
	local validTeams = {	
		["teamPlayer_1"] = true,
		["teamPlayer_2"] = true,
		["teamPlayer_3"] = true,
		["teamPlayer_4"] = true,
		["teamPlayer_5"] = true,
		["teamPlayer_6"] = true,
		["teamPlayer_7"] = true,
		["teamPlayer_8"] = true
	}

	if validTeams[team] then 
		return true 
	end

	return false
end

function flushPlayerTeams()
	for i = 1, 8 do
		local player = "teamPlayer_" .. i
		local teamTable = getglobal(player)

		if teamTable ~= nil then
			for k, v in teamTable do
				if type(k) == "string" and strfind(k, "^group_") ~= nil and type(v) == "table" then
					for subKey, _ in v do
						v[subKey] = nil
					end
					teamTable[k] = nil
				end
			end

			if teamTable.units ~= nil then
				for k, _ in teamTable.units do
					teamTable.units[k] = nil
				end
			end

			if teamTable.reverseUnits ~= nil then
				for k, _ in teamTable.reverseUnits do
					teamTable.reverseUnits[k] = nil
				end
			end

			if teamTable.reverseUnitsByType ~= nil then
				for k, _ in teamTable.reverseUnitsByType do
					for unitId,_ in teamTable.reverseUnitsByType[k] do
						teamTable.reverseUnitsByType[k][unitId] = nil
					end
					teamTable.reverseUnitsByType[k] = nil
				end
			end

			teamTable.unitCount = 0
			teamTable.reverseUnitCount = 0
		end
	end	

	collectgarbage()
end

flushPlayerTeams()

harvesterData = {}
crystalData = {}
unitsReversing = {}

TURN_TRIGGER_COUNT = 2 -- number of turn triggers before checking if unit is bugging
NO_COLLISION_DURATION = 4 -- seconds to disable collision on a bugged unit during fix
REVERSE_SPAM_FRAME_WINDOW = 2 -- frames within which a repeat reverse-move command is ignored
CHECKS_DONE_THRESHOLD = 0.90 -- ratio of units that must finish checking before fix decision
BUG_THRESHOLD_LARGE_GROUP = 0.35 -- bugging ratio threshold for groups > LARGE_GROUP_SIZE
BUG_THRESHOLD_SMALL_GROUP = 0.50 -- bugging ratio threshold for groups <= LARGE_GROUP_SIZE
LARGE_GROUP_SIZE = 30 -- unit count that switches between small/large threshold
UNITS_STILL_MOVING_THRESHOLD = 0.75 -- ratio of units still moving before clearing movement flag

unitBugDataTable = {
	-- PARAMETER DOCUMENTATION:
	--
	-- frameCount:                How long a unit's reverse-bug lasts in frames (calculated as 7 * turn speed in seconds).
	--                            Faster-turning units have shorter durations, slower units have longer ones.
	--
	-- reallyDamagedDurationMult: Multiplier applied to frameCount when the unit has the REALLYDAMAGED status.
	--                            Damaged units turn slower, so the bug lasts longer (e.g. 1.5 = 50% longer duration).
	--
	-- avgTurnCountOffset:        Offset subtracted from bugDuration when comparing the average third-turn frame count.
	--                            Used to distinguish a legitimate 180-degree turn (whole group turning) from a bug
	--                            (only a few units stuck turning). Lower values = more sensitive detection (more false
	--                            positives). Higher values = less sensitive (fewer false positives). 
	--							  Used in: 1st false positive filter
	--
	-- bugCheckLowerLimit:        Lower bound of the frame window used to detect if a unit is reverse-bugging.
	--                            Lower values detect more units but may increase false positives.
	--
	-- bugCheckUpperLimit:        Upper bound of the frame window used to detect if a unit is reverse-bugging.
	--                            Lower values detect more units but may increase false positives.
	--
	-- thirdTurnMinRatio:         Minimum proportion of the group that must have performed a third turn for the fix
	--                            to apply. If fewer than this ratio turned 3 times, the group is likely doing a normal
	--                            turn, not bugging. 
	-- 							  Used in: 3rd false positive filter
	--
	-- notMovingBackupRatio:      Proportion of units that were stationary before backing up. If this ratio is exceeded,
	--                            the fix is allowed even when thirdTurnMinRatio is not met (handles units that were
	--                            attacking and then reverse-moved).
	-- 							  Used in: 3rd false positive filter
	--
	-- avgFirstTurnRatio:         Multiplier applied to bugDuration when checking the average first-turn frame count.
	--                            If the average is at or above this ratio of bugDuration, only units whose frameDiff
	--                            equals bugDuration are fixed. Higher values = less aggressive filtering.
	--							  Used in: 2nd false positive filter

	-- NOD UNITS --
	["E3C841B0"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -1, bugCheckLowerLimit = 3, bugCheckUpperLimit = 2, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- Mok Raider Buggy
	["79609108"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -1, bugCheckLowerLimit = 3, bugCheckUpperLimit = 2, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- Black Hand Raider Buggy
	["6354531D"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -1, bugCheckLowerLimit = 3, bugCheckUpperLimit = 2, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- Nod Raider Buggy

	["1B44D6AE"] = { frameCount = 11, reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 1, bugCheckLowerLimit = 4, bugCheckUpperLimit = 5, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.40 }, -- Mok Scorpion Tank
	["A33F11AF"] = { frameCount = 11, reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 1, bugCheckLowerLimit = 4, bugCheckUpperLimit = 5, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.40 }, -- Black Hand Scorpion Tank
	["2F9131D"]  = { frameCount = 11, reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 1, bugCheckLowerLimit = 4, bugCheckUpperLimit = 5, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.40 }, -- Nod Scorpion Tank
	
	["26538D"]   = { frameCount = 7,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = -3, bugCheckLowerLimit = 2, bugCheckUpperLimit = 3, thirdTurnMinRatio = 0.01, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.50 }, -- Nod Stealth Tank
	["1025B90B"] = { frameCount = 7,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = -3, bugCheckLowerLimit = 2, bugCheckUpperLimit = 3, thirdTurnMinRatio = 0.01, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.50 }, -- Marked of Kane Stealth Tank

	["F38615BD"] = { frameCount = 11, reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 1, bugCheckLowerLimit = 4, bugCheckUpperLimit = 5, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.40 }, -- Black Hand Mantis (Shares locomotor with Scorpion Tank)

	["FD8822B1"] = { frameCount = 14, reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 4, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Nod Flame Tank
	["1E1AEEBE"] = { frameCount = 14, reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 4, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Black Hand Flame Tank

	["4F9DF943"] = { frameCount = 14, reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Nod Beam Cannon
	["3D143A57"] = { frameCount = 14, reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Marked of Kane Beam Cannon
	["7F5C5CDA"] = { frameCount = 14, reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Black Hand Beam Cannon

	["53024F73"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 4, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Nod Reckoner
	["3000821A"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 4, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Marked of Kane Reckoner
	["198BF501"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 4, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Black Hand Reckoner

	["12CEBD57"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0, bugCheckLowerLimit = 4, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Nod Emissary
	["BDC39D7D"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0, bugCheckLowerLimit = 4, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Marked of Kane Emissary
	["7D560AEC"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0, bugCheckLowerLimit = 4, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Black Hand Emissary

	["3A3D109A"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -3, bugCheckLowerLimit = 5, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Nod Harvester
	["C3785BFE"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -3, bugCheckLowerLimit = 5, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Marked of Kane Harvester
	["21661DFB"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -3, bugCheckLowerLimit = 5, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Black Hand Harvester

	["4D1CFBBD"] = { frameCount = 14,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 3, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Nod Specter
	["9A533FC7"] = { frameCount = 14,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 3, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Marked of Kane Specter
	["7A639A9A"] = { frameCount = 14,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 3, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Black Hand Specter

	-- SCRIN UNITS --
	["B8802763"] = { frameCount = 12, reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0.01, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- Scrin Seeker
	["DB2B7D2F"] = { frameCount = 12, reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0.01, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- Reaper-17 Seeker
	["7296891C"] = { frameCount = 12, reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0.01, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- Traveler-59 Seeker

	["AF991372"] = { frameCount = 12, reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Scrin Devourer Tank
	["416EFDFF"] = { frameCount = 12, reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Reaper-17 Devourer Tank

	["77A0E8A9"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -2, bugCheckLowerLimit = 3, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.15, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- Scrin Corruptor
	["B187F87A"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -2, bugCheckLowerLimit = 3, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.15, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- Reaper-17 Corruptor
	["91B5B69D"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -2, bugCheckLowerLimit = 3, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.15, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- Traveler-59 Corruptor

	["1A54C1B"]  = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -6, bugCheckLowerLimit = 3, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.05, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.60 }, -- Scrin Gunwalker
	["7FCCFDE3"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -6, bugCheckLowerLimit = 3, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.05, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.60 }, -- Reaper-17 Shard Walker
	["51430053"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -6, bugCheckLowerLimit = 3, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.05, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.60 }, -- Traveler-59 Gunwalker

	-- GDI UNITS --
	["D01CFD88"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0, bugCheckLowerLimit = 4, bugCheckUpperLimit = 3, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.40 }, -- GDI APC
	["7CC56843"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0, bugCheckLowerLimit = 4, bugCheckUpperLimit = 3, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.40 }, -- Steel Talons APC
	["64BCB106"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0, bugCheckLowerLimit = 4, bugCheckUpperLimit = 3, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.40 }, -- ZOCOM APC
	["AF462A8F"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0, bugCheckLowerLimit = 4, bugCheckUpperLimit = 3, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.40 }, -- GDI Veteran APC
	["BD7701CB"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0, bugCheckLowerLimit = 4, bugCheckUpperLimit = 3, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.40 }, -- ZOCOM Veteran APC

	["F714BBD3"] = { frameCount = 14,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 2, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- ZOCOM Predator Tank
	["E6EAD02C"] = { frameCount = 14,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 2, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- GDI Predator Tank

	["AE73138F"] = { frameCount = 25,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- ZOCOM Zone Shatterer
	["2144BD64"] = { frameCount = 25,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- GDI Shatterer

	["12E1C8C8"] = { frameCount = 28,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 6, bugCheckLowerLimit = 10, bugCheckUpperLimit = 12, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- ZOCOM Mammoth Tank
	["BC0A0849"] = { frameCount = 28,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 6, bugCheckLowerLimit = 10, bugCheckUpperLimit = 12, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- GDI Mammoth Tank
	["C1B5AB13"] = { frameCount = 28,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 6, bugCheckLowerLimit = 10, bugCheckUpperLimit = 12, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Steel Talons Mammoth Tank
	
	["5A6044BC"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -2, bugCheckLowerLimit = 2, bugCheckUpperLimit = 3, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- ZOCOM Slingshot
	["B54034FF"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -2, bugCheckLowerLimit = 2, bugCheckUpperLimit = 3, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- GDI Slingshot
	["4AFAC6E8"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -2, bugCheckLowerLimit = 2, bugCheckUpperLimit = 3, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Steel Talons Slingshot

	["ZOCOMMCV"] = { frameCount = 20,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- ZOCOM MCV
	["GDIMCV"] = { frameCount = 20,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- GDI MCV
	["SteelTalonsMCV"] = { frameCount = 20,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Steel Talons MCV

	["30354418"] = { frameCount = 35,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- ZOCOM MARV
	["GDIMARV"] = { frameCount = 35,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- GDI MARV
	["565BE825"] = { frameCount = 35,  reallyDamagedDurationMult = 1.5, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Steel Talons MARV

	["FD890B01"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0, bugCheckLowerLimit = 4, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- ZOCOM Surveyor
	["921C06CC"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0, bugCheckLowerLimit = 4, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- GDI Surveyor
	["F3F183DD"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 0, bugCheckLowerLimit = 4, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Steel Talons Surveyor

	["AD5F0217"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -1, bugCheckLowerLimit = 3, bugCheckUpperLimit = 2, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- ZOCOM Pitbull
	["6FF52808"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -1, bugCheckLowerLimit = 3, bugCheckUpperLimit = 2, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- GDI Pitbull
	["C6387E0"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -1, bugCheckLowerLimit = 3, bugCheckUpperLimit = 2, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- Steel Talons Pitbull
	["AABD1C1F"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -1, bugCheckLowerLimit = 3, bugCheckUpperLimit = 2, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- ZOCOM Veteran Pitbull
	["D9E0C318"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -1, bugCheckLowerLimit = 3, bugCheckUpperLimit = 2, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- GDI Veteran Pitbull
	["90BA3D4D"] = { frameCount = 7,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -1, bugCheckLowerLimit = 3, bugCheckUpperLimit = 2, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.45 }, -- Steel Talons Veteran Pitbull

	["6FCB2318"] = { frameCount = 12,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- ZOCOM Rig
	["B48BEDD2"] = { frameCount = 12,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- GDI Rig
	["82D6E5D8"] = { frameCount = 12,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = 1, bugCheckLowerLimit = 5, bugCheckUpperLimit = 6, thirdTurnMinRatio = 0.35, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Steel Talons Rig

	["D258354"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -3, bugCheckLowerLimit = 5, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- GDI Harvester
	["F52AEEDF"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -3, bugCheckLowerLimit = 5, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 }, -- Steel Talons Heavy Harvester
	["C23B3A15"] = { frameCount = 9,  reallyDamagedDurationMult = 1.0, avgTurnCountOffset = -3, bugCheckLowerLimit = 5, bugCheckUpperLimit = 4, thirdTurnMinRatio = 0.25, notMovingBackupRatio = 0.15, avgFirstTurnRatio = 0.36 } -- ZOCOM Harvester
}

MAX_FRAMES_WHEN_NOT_HARVESTED = 900 -- 60s
MAX_FRAMES_BEING_HARVESTED = 50 -- 15 frames is 1s (gdi/scrin harvest action time)
MAX_FRAMES_BEING_HARVESTED_NOD = 40 -- 15 frames is 1s (1.7s harvest action time)

-- Example of ObjectDescription() output: 'Object 3525 [(0,0)DCB85878, owned by player 3 (cgf123)]'
function getObjectId(x) 
	return strsub(ObjectDescription(x),strfind(ObjectDescription(x),'t')+2,strfind(ObjectDescription(x),'%[')-2) -- Object id
end

function getObjectName(x)
	return strsub(ObjectTemplateName(x),strfind(ObjectTemplateName(x),'%}')+1)
end

function NoOp(self, source)
end

function kill(self) -- Kill unit self.
	ExecuteAction("NAMED_KILL", self);
end

function RadiateUncontrollableFear( self )
	ObjectBroadcastEventToEnemies( self, "BeUncontrollablyAfraid", 350 )
end

function RadiateGateDamageFear(self)
	ObjectBroadcastEventToAllies(self, "BeAfraidOfGateDamaged", 200)
end

function OnNeutralGarrisonableBuildingCreated(self)
	ObjectHideSubObjectPermanently( self, "ARMOR", true )
end

function OnGDITechCenterCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_Boost", true )
	ObjectHideSubObjectPermanently( self, "UG_Mortar", true )
	ObjectHideSubObjectPermanently( self, "B_MortarRound_1", true )
	ObjectHideSubObjectPermanently( self, "UG_Rail", true )
	ObjectHideSubObjectPermanently( self, "UG_Scan", true )
	ObjectHideSubObjectPermanently( self, "UG_Adaptive", true )
	ObjectHideSubObjectPermanently( self, "UG_Adaptive01", true )
	ObjectHideSubObjectPermanently( self, "UG_Adaptive02", true )
	ObjectHideSubObjectPermanently( self, "UG_Adaptive04", true )	
end

function OnGDIMedicalBayCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_CompositeArmor", true )
	ObjectHideSubObjectPermanently( self, "UG_CompositeArmor02", true )
	ObjectHideSubObjectPermanently( self, "UG_GrenadeEMP", true )
	ObjectHideSubObjectPermanently( self, "UG_GrenadeEMP01", true )
	ObjectHideSubObjectPermanently( self, "UG_StealthDetector", true )
	ObjectHideSubObjectPermanently( self, "UG_StealthDetector01", true )
	ObjectHideSubObjectPermanently( self, "UG_Injector", true )
	ObjectHideSubObjectPermanently( self, "UG_Armor", true )
end

function OnGDIAirfieldCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_Boost", true )
	ObjectHideSubObjectPermanently( self, "UG_Ceramic", true )
	ObjectHideSubObjectPermanently( self, "UG_Ceramic01", true )
	ObjectHideSubObjectPermanently( self, "UG_Hardpoints", true )
	ObjectHideSubObjectPermanently( self, "UG_Hardpoints01", true )
	ObjectHideSubObjectPermanently( self, "UG_Hardpoints02", true )
	ObjectHideSubObjectPermanently( self, "UG_Hardpoints03", true )
end


function OnGDIPowerPlantCreated(self)
	ObjectHideSubObjectPermanently( self, "Turbines", true )
	ObjectHideSubObjectPermanently( self, "TurbineGlows", true )
end

function OnGDICommandPostCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_StealthDetector", true )
	ObjectHideSubObjectPermanently( self, "UG_StealthDetector01", true )
	ObjectHideSubObjectPermanently( self, "UG_StealthDetector02", true )
	ObjectHideSubObjectPermanently( self, "UG_StealthDetector03", true )
	ObjectHideSubObjectPermanently( self, "UG_Scan", true )
	ObjectHideSubObjectPermanently( self, "UG_Scan01", true )
	ObjectHideSubObjectPermanently( self, "UG_Scan02", true )
	ObjectHideSubObjectPermanently( self, "UG_APAmmo", true )
	ObjectHideSubObjectPermanently( self, "UG_APAmmo01", true )
	ObjectHideSubObjectPermanently( self, "UG_APAmmo02", true )
end

function OnGDIZoneTrooperCreated(self)
	ObjectHideSubObjectPermanently( self, "UGSCANNER", true )
	ObjectHideSubObjectPermanently( self, "UGJUMP", true )
	ObjectHideSubObjectPermanently( self, "UGINJECTOR", true )
end

function OnGDIPredatorCreated(self)
	ObjectHideSubObjectPermanently( self, "UGRAIL_01", true )
end

function OnGDIMammothCreated(self)
	ObjectHideSubObjectPermanently( self, "UGRAIL_01", true )
	ObjectHideSubObjectPermanently( self, "UGRAIL_02", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_01", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_02", true )
end

function OnSteelTalonsMammothCreated(self)
	ObjectHideSubObjectPermanently( self, "UGRAIL_01", true )
	ObjectHideSubObjectPermanently( self, "UGRAIL_02", true )
	ObjectHideSubObjectPermanently( self, "UGRAILACCELERATOR_01", true )
	ObjectHideSubObjectPermanently( self, "UGRAILACCELERATOR_02", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_01", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_02", true )
end

-- Set the reference of an object in order to assign object status successfully.
function SetObjectReference(self)
	local ObjectStringRef = "object_" .. getObjectId(self) .. tostring(GetFrame()) .. tostring(floor(GetRandomNumber()*99999999))
	ExecuteAction("SET_UNIT_REFERENCE", ObjectStringRef, self)
	return ObjectStringRef
end

function GetHarvesterData(self)
	if self ~= nil then
		local a = getObjectId(self)
		harvesterData[a] = harvesterData[a] or {
			totalFramesHarvested75Full = 0, -- total number of frames harvested since becoming >= 75% full of tiberium
			frameOnHarvest75 = 0, -- the frame since becoming >= 75% full of tiberium
			isHarvestingBlue = false, -- is harvesting blue tiberium or not
			isAlreadyHarvesting = false, -- the harvester is already harvesting
			lastCrystalHarvested = nil, -- object reference to the last crystal harvested
			harvbluetib = 0, -- for counting blue tiberium in harvester
			harvgreentib = 0, -- for counting green tiberium in harvester
			harvesterObjectRef = SetObjectReference(self), -- set the object reference once instead of relying on GetRandomNumber()
			-- 1 is green tiberium 0 is for blue
			bar1 = nil, -- for tracking the bar one of the harvester
			bar2 = nil, -- for tracking the bar two of the harvester
			bar3 = nil, -- for tracking the bar three of the harvester
			bar4 = nil -- for tracking the bar four of the harvester
		}
		return a, harvesterData[a]
	end

	return nil, nil
end

function OnMoney1(self)
	local a, hData = GetHarvesterData(self)

	if ObjectTestModelCondition(self, "DOCKING") == false then
		if hData.isHarvestingBlue then
			if not EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeBlueOne") then
				ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueOne")
			end
			hData.harvbluetib = hData.harvbluetib + 1
			hData.bar1 = 0
		else
			if not EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeGreenOne") then
				ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenOne")
			end
			hData.harvgreentib = hData.harvgreentib + 1
			hData.bar1 = 1
		end
		if hData.lastCrystalHarvested ~= nil then
			HarvestedCrystalCheck(hData.lastCrystalHarvested, GetFrame())
		end
	end
end

function OnMoney2(self)
	local a, hData = GetHarvesterData(self)

	if ObjectTestModelCondition(self, "DOCKING") == false then
		if hData.isHarvestingBlue then
			if not EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeBlueTwo") then
				ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueTwo")
			end
			hData.harvbluetib = hData.harvbluetib + 1
			hData.bar2 = 0
		else
			if not EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeGreenTwo") then
				ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenTwo")
			end
			hData.harvgreentib = hData.harvgreentib + 1
			hData.bar2 = 1
		end
		if hData.lastCrystalHarvested ~= nil then
			HarvestedCrystalCheck(hData.lastCrystalHarvested, GetFrame())
		end
	end
end

function OnMoney3(self)
	local a, hData = GetHarvesterData(self)

	if ObjectTestModelCondition(self, "DOCKING") == false then
		if hData.isHarvestingBlue then
			if not EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeBlueThree") then
				ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueThree")
			end
			hData.harvbluetib = hData.harvbluetib + 1
			hData.bar3 = 0
		else
			if not EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeGreenThree") then
				ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenThree")
			end
			hData.harvgreentib = hData.harvgreentib + 1
			hData.bar3 = 1
		end
		UpdateMoney3Frames(self)

		if hData.lastCrystalHarvested ~= nil then
			HarvestedCrystalCheck(hData.lastCrystalHarvested, GetFrame())
		end
	end
end

function OnMoney4(self)
	local a, hData = GetHarvesterData(self)
	if ObjectTestModelCondition(self, "DOCKING") == false then
		if hData.isHarvestingBlue then
			if not EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeBlueFour") then
				ObjectGrantUpgrade(self, "Upgrade_UpgradeBlueFour")
			end
			hData.harvbluetib = hData.harvbluetib + 1
			hData.bar4 = 0
		else
			if not EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeGreenFour") then
				ObjectGrantUpgrade(self, "Upgrade_UpgradeGreenFour")
			end
			hData.harvgreentib = hData.harvgreentib + 1
			hData.bar4 = 1
		end
	end
end

function OnMoneyScrin(self)
	local _, hData = GetHarvesterData(self)
	if ObjectTestModelCondition(self, "DOCKING") == false then
		-- only do thiis when 75% full
		if ObjectTestModelCondition(self, "MONEY_STORED_AMOUNT_3") then
			UpdateMoney3Frames(self)
		end
		if hData.lastCrystalHarvested ~= nil then
			HarvestedCrystalCheck(hData.lastCrystalHarvested, GetFrame())
		end
	end
end

function OffMoney1(self)
	local a, hData = GetHarvesterData(self)

	if ObjectTestModelCondition(self, "DOCKING") then
		if EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeBlueOne") then
			ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueOne")
		end
		if EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeGreenOne") then
			ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenOne")
		end
		if hData.bar1 == 0 then
			hData.harvbluetib = hData.harvbluetib - 1
		elseif hData.bar1 == 1 then
			hData.harvgreentib = hData.harvgreentib - 1
		end
	end
end

function OffMoney2(self)
	local a, hData = GetHarvesterData(self)

	if ObjectTestModelCondition(self, "DOCKING") then
		if EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeBlueTwo") then
			ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueTwo")
		end
		if EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeGreenTwo") then
			ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenTwo")
		end
		if hData.bar2 == 0 then
			hData.harvbluetib = hData.harvbluetib - 1
		elseif hData.bar2 == 1 then
			hData.harvgreentib = hData.harvgreentib - 1
		end
	end
end

function OffMoney3(self)
	local a, hData = GetHarvesterData(self)

	-- clear the amount of frames when docked and unloading tib
	hData.totalFramesHarvested75Full = 0

	if ObjectTestModelCondition(self, "DOCKING") then
		if EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeBlueThree") then
			ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueThree")
		end
		if EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeGreenThree") then
			ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenThree")
		end
		if hData.bar3 == 0 then
			hData.harvbluetib = hData.harvbluetib - 1
		elseif hData.bar3 == 1 then
			hData.harvgreentib = hData.harvgreentib - 1
		end
	end
end

function OffMoney4(self)
	local a, hData = GetHarvesterData(self)

	if ObjectTestModelCondition(self, "DOCKING") then
		if EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeBlueFour") then
			ObjectRemoveUpgrade(self, "Upgrade_UpgradeBlueFour")
		end
		if EvaluateCondition("UNIT_HAS_UPGRADE",hData.harvesterObjectRef, "Upgrade_UpgradeGreenFour") then
			ObjectRemoveUpgrade(self, "Upgrade_UpgradeGreenFour")
		end
		if hData.bar4 == 0 then
			hData.harvbluetib = hData.harvbluetib - 1
		elseif hData.bar4 == 1 then
			hData.harvgreentib = hData.harvgreentib - 1
		end
	end
end

function OnHarvesterDeath(self)
	local a, hData = GetHarvesterData(self)
	if hData.harvbluetib >= 2 then
		ObjectCreateAndFireTempWeapon(self, "DeployBlueTiberium")
	elseif hData.harvbluetib == 1 or hData.harvgreentib > 0 then
		ObjectCreateAndFireTempWeapon(self, "DeployGreenTiberium")
	end
	harvesterData[a] = nil
	GroupUnitOnDeath(self)
end

function OnHarvesterDeathScrin(self)
	local a = getObjectId(self)
	-- new for tib exploit fix
	harvesterData[a] = nil
	GroupUnitOnDeath(self)
end

function OnCyborgSquadCreated_R21g(self)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "EMPBlastGetInRange", 1.75);
end

function OnCyborgCreated_R21g(self)
	ObjectHideSubObjectPermanently( self, "WEAPON_PARTICLEBM", true )
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "EMPBlast", 1.75);
end	

-- ################ NEW FUNCTIONS FOR 1.03 HARV BUG DETECTION #######################
function OnHarvCreated_103(self)
	local a = getObjectId(self) -- Get Object id
	harvturntable[a] = -1
	harvturntimetable[a] = 0
	harvturncounttable[a] = 0
end

function OnHarvTurnLeftHS_103(self)
	local a = getObjectId(self) -- Get Object id
	local f = GetFrame()	

	if isHarvBugAlertDisallowed(self) then
		harvturncounttable[a] = 0
	else
		local f = GetFrame()
		local p = getPlayerId(self)
		
		local lastTime = harvturntimetable[a]
		local lastMove = harvturntable[a]		
		--ExecuteAction("SHOW_MILITARY_CAPTION", "Harv LEFT! #" .. f .. ", " .. tostring(lastMove) .. ", " .. tostring(lastTime) ,3)				
		if lastTime ~= nil and lastMove == 0 and (f - lastTime) < 50 then
			harvturncounttable[a] = harvturncounttable[a] + 1
			--ExecuteAction("SHOW_MILITARY_CAPTION", "Harv LEFT = " .. tostring(harvturncounttable[a]) ,3)				
			
			local lastWarnTime = harvwarntimetable[p]
			if harvturncounttable[a] >= 15 and (lastWarnTime == nil or (f - lastWarnTime) > 150) then
				harvturncounttable[a] = 0
				harvwarntimetable[p] = f		
				ExecuteAction("NAMED_FLASH_WHITE", self, 10)
				local x = ObjectTemplateName(self)
				if strfind(tostring(x), "D258354") ~= nil then
					ObjectPlaySound(self, "GDI_Harvester_VoiceRetreat")
					--ExecuteAction("PLAY_SOUND_EFFECT", "GDI_Harvester_VoiceRetreat")
				elseif strfind(tostring(x), "F52AEEDF") then
					ObjectPlaySound(self, "GDI_HeavyHarvester_VoiceRetreat")
					--ExecuteAction("PLAY_SOUND_EFFECT", "GDI_HeavyHarvester_VoiceRetreat")				
				elseif strfind(tostring(x), "C23B3A15") then
					ObjectPlaySound(self, "GDI_HeavyHarvester_VoiceRetreat")			
					--ExecuteAction("PLAY_SOUND_EFFECT", "GDI_RocketHarvester_VoiceRetreat")
				elseif strfind(tostring(x), "3A3D109A") or strfind(tostring(x), "21661DFB") or strfind(tostring(x), "C3785BFE") then
					ObjectPlaySound(self, "NOD_Harvester_VoiceRetreat")				
					--ExecuteAction("PLAY_SOUND_EFFECT", "NOD_Harvester_VoiceRetreat")
				else
					ObjectPlaySound(self, "ALI_Harvester_SoundRetreat")				
					--ExecuteAction("PLAY_SOUND_EFFECT", "ALI_Harvester_SoundRetreat")
				end
				--ExecuteAction("OBJECT_CREATE_RADAR_EVENT", self, 5)
				ExecuteAction("SHOW_MILITARY_CAPTION", "Player " .. getPlayerName(self) .. " : HARVESTER BUGGED!",3)				
			end
		end	
	end

	harvturntable[a] = 1
	harvturntimetable[a] = f	
end

function OnHarvTurnLeftHSEnd_103(self)
	local a = getObjectId(self) -- Get Object id
	local f = GetFrame()	

	if isHarvBugAlertDisallowed(self) then
		harvturncounttable[a] = 0
	end
end

function OnHarvTurnRightHS_103(self)
	local a = getObjectId(self) -- Get Object id
	local f = GetFrame()	

	if isHarvBugAlertDisallowed(self) then
		harvturncounttable[a] = 0
	else
		local lastTime = harvturntimetable[a]
		local lastMove = harvturntable[a]
		--ExecuteAction("SHOW_MILITARY_CAPTION", "Harv RIGHT! #" .. f .. ", " .. tostring(lastMove) .. ", " .. tostring(lastTime) ,3)			
		if lastTime ~= nil and lastMove == 1 and (f - lastTime) > 50 then
			harvturncounttable[a] = 0
			--ExecuteAction("SHOW_MILITARY_CAPTION", "Harv RIGHT RESET! #" .. f ,3)		
		end			
	end
	
	harvturntable[a] = 0
	harvturntimetable[a] = f		
end

function OnHarvTurnRightHSEnd_103(self)
	local a = getObjectId(self) -- Get Object id
	local f = GetFrame()	

	if isHarvBugAlertDisallowed(self) then
		harvturncounttable[a] = 0
	end
end

function isHarvBugAlertDisallowed(self)
	return ObjectTestModelCondition(self, "MOVING") == false or ObjectTestModelCondition(self, "SELECTED") == true or ObjectTestModelCondition(self, "USER_60") == false
end

function OnHarvDestroyed_103(self)
	local a = getObjectId(self) -- Get Object id
	harvturntable[a] = nil
	harvturntimetable[a] = nil
	harvturncounttable[a] = nil
end

-- ###################################################################

-- ################ NEW FUNCTION FOR 1.03 RGA #######################
function OnSteelTalonsMammothCreated_103(self)
	ObjectHideSubObjectPermanently( self, "UGRAIL_01", true )
	ObjectHideSubObjectPermanently( self, "UGRAIL_02", true )
--	ObjectHideSubObjectPermanently( self, "UGRAILACCELERATOR_01", true )
--	ObjectHideSubObjectPermanently( self, "UGRAILACCELERATOR_02", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_01", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_02", true )
end
-- ###################################################################

function OnGDIJuggernaughtCreated(self)
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_01", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_02", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_03", true )
end

-- ####################### BROADCASTED EVENT TO HARVS ############################

function GetCrystalData(self)
	if self ~= nil then 
		local a = getObjectId(self)
		crystalData[a] = crystalData[a] or {
			firstHarvestedFrame = 0, -- the frame where the crystal begins to be harvested 
			lastHarvestedFrame = nil, -- the frame where the crystal finishes being harvested
			framesBeingHarvested = 0, -- the amount of frames the crystal has been harvested
			crystalHasBeenReset = false, -- the crystal has undergone a reset
			dontKillCrystal = false, -- flag to prevent the crystal from being killed with NAMED_KILL
			beingHarvestedBy = nil, -- harvester thats currently harvesting this crystal
			crystalObjectRef = SetObjectReference(self) -- set the object reference once instead of relying on GetRandomNumber()
		}
		return a, crystalData[a]
	end

	return nil, nil
end

-- self is the crystal, other is the harvester
function TiberiumEvent(self, other)
	if self ~= nil and other ~= nil then
		-- replace with a less costly method
		local _, crystal = GetCrystalData(self)
		-- local ObjectStringRef = "object_" .. floor(GetRandomNumber()*99999999)
		-- ExecuteAction("SET_UNIT_REFERENCE", crystal.crystalObjectRef, self)
		-- if IS_BEING_HARVESTED is true
		if EvaluateCondition("UNIT_HAS_OBJECT_STATUS", crystal.crystalObjectRef , 116) then
			local _, data = GetHarvesterData(other)
			--  the harvester is not already harvesting nor crystal is the crystal also being harvested (prevents nearby crystals in the 75 radius from triggering the same event on the same harvester)
			if not data.isAlreadyHarvesting and crystal.beingHarvestedBy == nil then
				-- assign the crystal this harvester is currently harvesting to the table 
				data.lastCrystalHarvested = self
				-- blue tiberium check
				if strfind(ObjectDescription(self), "BA9F66AB") ~= nil or strfind(ObjectDescription(self), "TiberiumCrystalBlue") ~= nil then
					data.isHarvestingBlue = true
					-- show the blue tib fx
					if not EvaluateCondition("UNIT_HAS_UPGRADE",data.harvesterObjectRef, "Upgrade_UpgradeBlueTib") then
						--ExecuteAction("SHOW_MILITARY_CAPTION", "granting the blue tib upgrade", 2)
						ObjectGrantUpgrade(other, "Upgrade_UpgradeBlueTib")
					end
				else
					data.isHarvestingBlue = false
					-- hide the blue tib fx
					if EvaluateCondition("UNIT_HAS_UPGRADE",data.harvesterObjectRef, "Upgrade_UpgradeBlueTib") then
						--ExecuteAction("SHOW_MILITARY_CAPTION", "removing the blue tib upgrade", 2)
						ObjectRemoveUpgrade(other, "Upgrade_UpgradeBlueTib")
					end
				end
				data.isAlreadyHarvesting = true
				crystal.beingHarvestedBy = other
				-- updated crystal harvested time
				UpdateHarvestedTime(crystal)
			end
		end
	end
end

-- ###################################################################

-- ####################### TIBERIUM EXPLOIT FIX ############################

-- this function assigns the frame when the harvester harvests it.
function OnTiberiumHarvested(self)
	ObjectBroadcastEventToUnits(self, "TiberiumEvent", 75)
end

function HarvestedCrystalCheck(self, curFrame)
	local a, data = GetCrystalData(self)
	if data.beingHarvestedBy ~= nil then 
		local factionHarvester = ObjectDescription(data.beingHarvestedBy)
		local maxFrames = GetMaxFrames(factionHarvester)
		-- if dontKillCrystal is false increment the framesBeingHarvested and check if it has been harvested longer than the max permitted frame count.
		if not data.dontKillCrystal and ObjectTestModelCondition(data.beingHarvestedBy, "MONEY_STORED_AMOUNT_4") == false then
			data.framesBeingHarvested = data.framesBeingHarvested + curFrame - data.firstHarvestedFrame	

			if data.framesBeingHarvested >= maxFrames and not data.crystalHasBeenReset then
				-- prevent death FX in FXListBehaviour
				ObjectSetObjectStatus(self, "RIDER1")
				-- cleanup
				crystalData[a] = nil
				ExecuteAction("NAMED_KILL", self)
				return true
			end
		end
		return false 
	end
end

function GetMaxFrames(factionHarvester)	
	-- assign a different value to nod and nod subfaction harvs as it has a 1.7s action time
	if strfind(factionHarvester, "3A3D109A") ~= nil or strfind(factionHarvester, "21661DFB") ~= nil or strfind(factionHarvester, "C3785BFE") ~= nil then 
		return MAX_FRAMES_BEING_HARVESTED_NOD
	else
		return MAX_FRAMES_BEING_HARVESTED
	end
end

-- checks if the crystal has been harvested longer than the maximum frames and if it doesn't have a flag assigned, it kills it. (not triggered when destroyed or fully harvested)
function OffTiberiumHarvested(self)
	local _, data = GetHarvesterData(self)
	if data ~= nil then 
		data.isAlreadyHarvesting = false
		if crystalData[getObjectId(data.lastCrystalHarvested)] ~= nil then
			local _, crystal = GetCrystalData(data.lastCrystalHarvested)	
			if crystal ~= nil then
				local curFrame = GetFrame()
				if not HarvestedCrystalCheck(data.lastCrystalHarvested, curFrame) then
					-- reset dontKillCrystal if its set to true
					crystal.dontKillCrystal = false
					-- reset flag if time since last harvest is more than MAX_FRAMES_WHEN_NOT_HARVESTED
					if crystal.lastHarvestedFrame ~= nil then
						if (curFrame - crystal.lastHarvestedFrame) <= MAX_FRAMES_WHEN_NOT_HARVESTED then
							crystal.crystalHasBeenReset = false
						else
							crystal.crystalHasBeenReset = true
						end
					end
					-- time since last harvest
					crystal.lastHarvestedFrame = curFrame
					crystal.beingHarvestedBy = nil
				end
			end
		end
	end
end

-- when the crystal is completely harvested and not killed, clear the crystalData element
function OffTiberiumGrowing(self)
	-- clear it
	local a, crystal = GetCrystalData(self)
	if crystal ~= nil then 
		local _, data = GetHarvesterData(crystal.beingHarvestedBy)
		if data ~= nil then
			data.isAlreadyHarvesting = false
		end
		crystalData[a] = nil
	end	
end

-- i also want to trigger this on just +MONEY_STORED_AMOUNT_3
-- triggered on +HARVEST_ACTION +MONEY_STORED_AMOUNT_3
function UpdateMoney3Frames(self)
	local a, data = GetHarvesterData(self)
	if data ~= nil and a ~= nil then 
		data.frameOnHarvest75 = GetFrame()
		local _, crystal = GetCrystalData(data.lastCrystalHarvested)
		-- safeguard incase the tib crystal is destroyed
		if crystal ~= nil then
			-- if the harvester since becoming 75% full of tiberium has harvested more than the threshold and also the crystal its harvesting has been harvested less than the max frames it can be harvested 
			-- and crystal.framesBeingHarvested < GetMaxFrames(a)
			if data.totalFramesHarvested75Full >= GetMaxFrames(ObjectDescription(self))  then
				crystal.dontKillCrystal = true
			end
		end
	end
end

-- update the number of frames harvested since becoming 75% full of tiberium
function UpdateMoney3FramesEnd(self)
	local _, data = GetHarvesterData(self)
	if data ~= nil then
		-- subtracting one to partially resolve repeated OffTiberiumHarvested calls on the same crystal from prematurely killing it off
		data.totalFramesHarvested75Full = data.totalFramesHarvested75Full + (GetFrame() - data.frameOnHarvest75) 
	end
end

-- check if the last time the crystal was harvested was over a minute ago and update the the first frame value
function UpdateHarvestedTime(self)
	local crystal = self
	crystal.firstHarvestedFrame = GetFrame()

	if crystal.lastHarvestedFrame ~= nil then
		if (GetFrame() - crystal.lastHarvestedFrame) > MAX_FRAMES_WHEN_NOT_HARVESTED then
			-- reset harvested frames
			crystal.framesBeingHarvested = 0
			crystal.lastHarvestedFrame = nil
		end
	end
end

-- ###################################################################

-- ####################### HUSK CAPTURE IMPLEMENTATION ############################

-- triggered when a unit such as a juggernaught spawns from a husk, this simply checks in the table of husks to see if there are any without these status 
-- then applies them.
function DelayHuskHide(self)

	-- play the husk repair sound found on EngineerContain at the spawned units location.
	-- ObjectPlaySound(self, "BuildingCaptured")	
	ObjectPlaySound(self, "BuildingRepaired")	

	local a = getObjectId(self)
	-- checks if it has the status bit RIDER1 (41) assigned in the husk xml
	if EvaluateCondition("UNIT_HAS_UPGRADE",SetObjectReference(self), "Upgrade_EngineerCapture") then
		ObjectRemoveUpgrade(self, "Upgrade_EngineerCapture")
	end

	-- kill the husk and delay its destruction in SlowDeath by 8s
	for key, husk in husksTable do
		if key ~= nil then		
			-- hide the husk here, this event prevents a flicker from appearing.
			if ObjectTestModelCondition(husk, "USER_3") == false then
				ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", husk, "USER_3", 999999, 100)
			end

			ExecuteAction("UNIT_SET_TEAM", husk, "/team")	

			-- kill the husk, but have it remain in play for 8s
			ExecuteAction("NAMED_KILL", husk)	
					
			husksTable[key] = nil
			break
		end
	end
end

-- This function will check if the slaughterer is not an epic unit 
-- and if not will store the owner of self in a local variable and then assign slaughterer the owner obtained from self.
function OnHuskCapture(self, slaughterer)
	if self ~= nil and slaughterer ~= nil then
		-- upgrade the husk and apply status to it
		if not EvaluateCondition("UNIT_HAS_UPGRADE",SetObjectReference(slaughterer), "Upgrade_EngineerCapture") then
			ObjectGrantUpgrade(slaughterer, "Upgrade_EngineerCapture")
		end
	
		local unitType = tostring(ObjectTemplateName(slaughterer))
		
		-- GDI MARV 30354418                  GDI CCA0AB62
		-- ZOCOM MARV 37F0A5F5                ZOCOM 8E3D36F8
		-- STEEL TALONS MARV 565BE825		  STEEL TALONS 38EA5BC0
		-- NOD REDEEMER D8BE0529              NOD ED46C05A
		-- BLACK HAND REDEEEMER CD5A5360      BLACK HAND 5D10A932
		-- MOK REDEEMER 711A18DF              MARKED OF KANE FB53CCFD
		-- SCRIN HEXAPOD 1D137C85             SCRIN 5B7BAA66
		-- REAPER HEXAPOD 146C2890            REAPER17 30883A9F
		-- T59 HEXAPOD A4FD281B               TRAVELER59 92CC2C04
		
		local isEpicUnit = false
		
		for _, epicUnit in epicUnits do 
		   if strfind(unitType, epicUnit) then
			 isEpicUnit = true
			 break
		   end	  
		end
		
		-- only do this if it not an epic unit 
		if not isEpicUnit then

			-- assign husk to the husktable
			local a = getObjectId(self)
			husksTable[a] = slaughterer

			local matched = false
			local engiOwner = tostring(ObjectTeamName(self))
			local huskOwner = tostring(ObjectTeamName(slaughterer))
			-- gets current frame and then compares it to the players frame
			local curFrame = GetFrame()
							
			for i = 1, getn(playerTable),1 do
	
				local teamStr =  "team" .. playerTable[i]
			
				-- i is the engineer owner
				if strfind(engiOwner, teamStr) then
					if strfind(huskOwner, teamStr) == nil then 
						-- Change the team of the player if it isnt the same team as the slaughterer.
						ExecuteAction("UNIT_SET_TEAM", slaughterer, playerTable[i] .. "/" .. teamStr)
					end
					-- Initialize value to 0 if it doesnt exist yet
					if playerTimes[i] == nil then
						playerTimes[i] = 0
					end			
					-- Play EVA sound if 150 (10s) frames has passed.
					if playerTimes[i] == 0 or (curFrame - playerTimes[i]) >= 150 then						
						local playerFaction = tostring(ObjectPlayerSide(self)) 		
						
						if strfind(playerFaction, "CCA0AB62") ~= nil or strfind(playerFaction, "8E3D36F8") ~= nil or strfind(playerFaction, "38EA5BC0") ~= nil then 
							-- GDI EVA
							ExecuteAction("PLAY_SOUND_EFFECT_AT_TEAM", "Geva_UnitRecovered", playerTable[i] .. "/" .. teamStr)
						elseif 
							strfind(playerFaction, "ED46C05A") ~= nil or strfind(playerFaction, "5D10A932") ~= nil or strfind(playerFaction, "FB53CCFD") ~= nil then 
							-- NOD EVA
							ExecuteAction("PLAY_SOUND_EFFECT_AT_TEAM", "Neva_UnitRecovered", playerTable[i] .. "/" .. teamStr)
						elseif 
							strfind(playerFaction, "5B7BAA66") ~= nil or strfind(playerFaction, "30883A9F") ~= nil or strfind(playerFaction, "92CC2C04") ~= nil then 
							-- SCRIN EVA
							ExecuteAction("PLAY_SOUND_EFFECT_AT_TEAM", "Aeva_UnitRecovered", playerTable[i] .. "/" .. teamStr)
						end
						playerTimes[i] = curFrame
					end	
					matched = true
					break
				end
			end

			-- alert the original husk owner if the engineer is a different player.		
			if not matched then
				ExecuteAction("UNIT_SET_TEAM", slaughterer, "/team")
			else
				for i = 1, getn(playerTable), 1 do
					local teamStr = "team" .. playerTable[i]
					if strfind(huskOwner, teamStr) and strfind(engiOwner, teamStr) == nil and i <= 8 then
						ObjectCreateAndFireTempWeapon(slaughterer, "AlertHuskPlayer" .. i)
						break
					end
				end
			end
			-- spawn the unit obtained from the husk
			ObjectDoSpecialPower(slaughterer, "SpecialPower_SpawnHuskOCL")
		end
	end
end

-- check if its a player or not and sets RIDER2 to it which will prevent the SlaughterHordeContain module from activating on this engineer, prevents skirmish AI from using it.
function OnEngineerCreatedR23(self)
	local engiOwner = tostring(ObjectTeamName(self))
	local isPlayer = false
	
	for i = 1, getn(playerTable),1 do
		if(strfind(engiOwner, "team" .. playerTable[i])) ~= nil then
			isPlayer = true
			break
		end
	end

	if not isPlayer then
		ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", self, "RIDER2", 999999, 100) 
	end
end

function OnCombatEngineerCreatedR23(self)
	ObjectHideSubObjectPermanently( self, "MUZZLEFLASH", true )
	ObjectHideSubObjectPermanently( self, "LASER", true )
	-- call the generic engineer function
	OnEngineerCreatedR23(self)
end

-- workaround for the original radar event
function OnHuskFXCreated(self)
	 ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", self, "Command_HuskCaptureFX")
end

-- ###################################################################

-- ####################### REVERSE MOVE WORKAROUND ############################

function GetUnitReversingData(self)
	if self ~= nil then
		local a = getObjectId(self)

		-- check if this object is a harvester that can reverse move, returns true if so, else false.
		local checkHarv = function()
			local objectName = getObjectName(%self) 
			local harvesters = {	
				["3A3D109A"] = true,
				["C3785BFE"] = true,
				["21661DFB"] = true,
				["D258354"] = true,
				["F52AEEDF"] = true,
				["C23B3A15"] = true
			}

			if harvesters[objectName] then
				return true
			end
			return false
		end

		unitsReversing[a] = unitsReversing[a] or {
			firstFrame = 0, -- first frame after reversing while turning fast
			isReverseMoving = false, -- flag to stop the re-assignment of firstFrame
			timesTriggeredFast = 0, 
			timesTriggeredNormal = 0, 
			hasBeenFixed = false,
			stringReference = SetObjectReference(self),
			selfReference = self,
			groupId = nil,
			lastMoveWasReverse = false,
			lastReverseMoveFrame = 0,
			hasAlreadyReversed = false,
			wasAttackingBeforeReverse = false,
			hasBeenCounted = false,
			fastTurnWas0Frames = false,
			hasComeToAStop = false, 
			unitAnchor = nil, -- can be an array from closest to farthest
			bugFrameDiff = 0,
			hasBeenSelected = false,
			expectedChecksFlag = false,
			groupIdAssigned = false,
			isReverseMoveHarvester = checkHarv()
		}
		return a, unitsReversing[a]
	end
	return nil, nil
end

-- Sets the initial frame when a unit fast turns while backing up, triggered by +BACKING_UP +TURN_LEFT_HIGH_SPEED
function BackingUpFast(self)
	local _,unitReversing = GetUnitReversingData(self)
	--local curFrame = GetFrame()
end

function GetNumberOfUnitsMoving(selectedUnitList)
	if selectedUnitList == nil then return 0 end
	local unitsMoving = 0
	for _, unitRef in selectedUnitList do
		if unitsReversing[unitRef] ~= nil and EvaluateCondition("NAMED_NOT_DESTROYED", unitsReversing[unitRef].stringReference) and ObjectTestModelCondition(unitsReversing[unitRef].selfReference, "MOVING") then
			unitsMoving = unitsMoving + 1
		end
	end
	return unitsMoving
end

-- returns the size of a a key/value pair table
function getTableSize(t)
	if t == nil then return end
	local size = 0
	for k, _ in t do
		if k ~= nil then 
			size = size + 1 
		end
	end
	return size
end

function UnitIsMoving(self)
	local _,unitReversing = GetUnitReversingData(self)
	if unitReversing == nil then return end
	if ObjectTestModelCondition(self, "BACKING_UP") == false then
		unitReversing.hasComeToAStop = false
	end
end

-- Gets the random key to assign to the unit for anchor purposes.
function GetRandomKey(t, unitId)
    if t == nil then return nil end
    local keys = {}
    for k, v in t do
		-- insert every unitid into the table except the unit that called this function
        if k ~= unitId then
            tinsert(keys, k)
        end
    end
    local count = getn(keys)
    if count == 0 then 
        return nil 
    end    
	-- WriteToFile("random units.txt",  "unit being assigned: " .. tostring(unitId) .. "   random unit assigned to it: "  .. tostring(keys[randomIndex]) .. "\n")
    return keys[random(1, count)]
end

function random(...) --overwritting lua native function for multiplayer compatibility 
    local randomNumber = function(a,b) return floor(a+((b-a)*GetRandomNumber())+0.5) end
    if getn(arg) == 0 then 
        return floor(GetRandomNumber()+0.5)
    elseif getn(arg) == 1 then 
        return randomNumber(1,arg[1])
    elseif getn(arg) == 2 then 
        return randomNumber(arg[1],arg[2])
    else 
        return arg[randomNumber(1,getn(arg))] 
    end
end 

function AssignGroupId(unitReversing, a, curFrame, self)
	if unitReversing == nil then return end
	-- print("assigning group again")
	local groupId = unitReversing.groupId
	-- unit was already tagged in the else block for loop.
	if not unitReversing.groupIdAssigned then
		local team = tostring(ObjectTeamName(self))
		local teamTable = isValidTeam(team) and getglobal(team) or nil
		if teamTable == nil or teamTable.units == nil then return end
		-- first unit in the group, create snapshot and tag all units currently selected, this will also copy the unitsCount over to teamSnapshot.
		-- local teamSnapshot = DeepCopyTable(teamTable)

		local teamSnapshot = {
			units = DeepCopyTable(teamTable.units or {}),
			unitCount = teamTable.unitCount or 0,
			reverseUnits = DeepCopyTable(teamTable.reverseUnits or {}),
			reverseUnitCount = teamTable.reverseUnitCount or 0,
			reverseUnitsByType = DeepCopyTable(teamTable.reverseUnitsByType or {})
		}

		-- the table contains a unique id that all units share when selected during this reverse move
		groupId = "group_" .. tostring(curFrame) .. "_" .. tostring(a) .. tostring(floor(GetRandomNumber()*99999999))
		-- store a global variable with the id generated for this group containing all selected units (obtained by DeepCopyTable)
		teamSnapshot.unitsToFixByType = {}
		teamSnapshot.checksDone = 0
		teamSnapshot.fixCancelled = false
		teamSnapshot.thirdTurnCountChecked = false
		teamSnapshot.fixCancelledByType = {}
		teamSnapshot.thirdTurnFrameCountByType = {}
		teamSnapshot.thirdTurnUnitCountByType = {}
		teamSnapshot.firstTurnFrameCountByType = {}
		teamSnapshot.firstTurnUnitCountByType = {}
		teamSnapshot.expectedChecks = 0
		teamSnapshot.unitsNotMovingBeforeBackingUp = 0
		--setglobal(groupId, teamSnapshot)
		teamTable[groupId] = teamSnapshot
		--groupIds[groupId] = groupId
		--unitGroups[groupId] = teamSnapshot
		-- assign every unit the same groupId
		local unitsNotMovingBeforeBackingUp = 0
		for _, unitRef in teamSnapshot.units do
			 -- WriteToFile("groupId.txt",  tostring(groupId) .. "\n")
			if unitsReversing[unitRef] ~= nil and EvaluateCondition("NAMED_NOT_DESTROYED", unitsReversing[unitRef].stringReference) and unitsReversing[unitRef].hasBeenSelected and not unitsReversing[unitRef].groupIdAssigned then
				unitsReversing[unitRef].groupId = groupId
				unitsReversing[unitRef].groupIdAssigned = true
				if teamSnapshot.reverseUnits ~= nil and teamSnapshot.reverseUnits[unitRef] ~= nil
				and ObjectTestModelCondition(unitsReversing[unitRef].selfReference, "MOVING") == false then
					unitsNotMovingBeforeBackingUp = unitsNotMovingBeforeBackingUp + 1
				end
			end
		end
		local assignedGroup = nil
		if groupId ~= nil then
			assignedGroup = teamTable[groupId]
		end
		--local assignedGroup = unitGroups[groupId]
		if assignedGroup ~= nil then
			assignedGroup.unitsNotMovingBeforeBackingUp = unitsNotMovingBeforeBackingUp
		end
		-- WriteToFile("groupId.txt",  "------------------------------------" .. "\n")
		-- assign the snapshot to groupId
		-- unitReversing.groupId = teamSnapshot
	end
end

-- checks if most units are moving and if the number returned exceeds the threshold then assign the hasComeToAStop to true
function UnitNoLongerMoving(self)
	--ExecuteAction("NAMED_FLASH_WHITE", self, 2)
	local _,unitReversing = GetUnitReversingData(self)
	if unitReversing == nil then return end
	local playerTeam = tostring(ObjectTeamName(self))
	--if unitReversing.hasComeToAStop then return end
	-- check if most units selected are not moving
	if not unitReversing.hasBeenFixed and unitReversing.groupIdAssigned and unitReversing.groupId ~= nil then
		local group = isValidTeam(playerTeam) and getglobal(playerTeam)[unitReversing.groupId] or nil
		
		--local group = unitGroups[unitReversing.groupId]
		if group ~= nil and group.reverseUnits ~= nil and group.reverseUnitCount ~= nil then
			-- if a few units are moving now but originally before backing up most units were not moving then set moving flag to true
			local numberOfUnitsMoving = GetNumberOfUnitsMoving(group.reverseUnits)
			for _, unitRef in group.reverseUnits do
				if unitsReversing[unitRef] ~= nil then
					if numberOfUnitsMoving <= floor(group.reverseUnitCount * UNITS_STILL_MOVING_THRESHOLD)
					and ((group.unitsNotMovingBeforeBackingUp or 0) >= floor(group.reverseUnitCount * 0.35)) and unitsReversing[unitRef].wasAttackingBeforeReverse then
						unitsReversing[unitRef].hasComeToAStop = false
					elseif numberOfUnitsMoving <= floor(group.reverseUnitCount * 0.15) and not unitsReversing[unitRef].wasAttackingBeforeReverse then
						unitsReversing[unitRef].hasComeToAStop = true
						--ExecuteAction("NAMED_FLASH_WHITE", unitsReversing[unitRef].selfReference, 2)
					end					
				end
			end
		end
	-- The player issued a stop (group no longer exists) --
	elseif not unitReversing.hasBeenFixed and not unitReversing.groupIdAssigned then
		local teamTable = isValidTeam(playerTeam) and getglobal(playerTeam) or nil
		if teamTable ~= nil and teamTable.reverseUnits ~= nil and teamTable.reverseUnitCount ~= nil and teamTable.reverseUnitCount > 0 then
			local numberOfUnitsMoving = GetNumberOfUnitsMoving(teamTable.reverseUnits)
			--WriteToFile("numberOfUnitsMoving.txt",  "units not moving: " .. tostring(numberOfUnitsMoving) .. "teamTable units size: " .. getTableSize(teamTable.reverseUnits) .. "\n")
			if numberOfUnitsMoving <= floor(teamTable.reverseUnitCount * 0.15) then
				-- assign hasComeToAStop as true only if the last move was a reverse move
				for _, unitRef in teamTable.reverseUnits do
					if unitsReversing[unitRef] ~= nil and not unitsReversing[unitRef].wasAttackingBeforeReverse then
						--unitsReversing[unitRef].lastMoveWasReverse = false
						unitsReversing[unitRef].hasComeToAStop = true
						--ExecuteAction("NAMED_FLASH_WHITE", unitsReversing[unitRef].selfReference, 2)
					end
				end
			end
		else
			-- team table is empty (player has deselected it), so clear flags for this unit directly
			if not unitReversing.wasAttackingBeforeReverse then
				unitReversing.hasComeToAStop = true
				--ExecuteAction("NAMED_FLASH_WHITE", self, 2)
			end
		end
	end
end

function CheckForObjReverseBugging(self, frameDiff)
	local a, unitReversing = GetUnitReversingData(self)
	if unitReversing == nil or not unitReversing.groupIdAssigned or unitReversing.groupId == nil then return end
	local unitBugData = unitBugDataTable[getObjectName(self)]
	if unitBugData == nil then return end
	local bugDuration = unitBugData.frameCount
	-- check if unit is really damaged
	bugDuration = ObjectTestModelCondition(self, "REALLYDAMAGED") and floor(bugDuration*unitBugData.reallyDamagedDurationMult+0.5) or bugDuration
	local playerTeam = tostring(ObjectTeamName(self))
	local group = isValidTeam(playerTeam) and getglobal(playerTeam)[unitReversing.groupId] or nil
	--local group = unitGroups[unitReversing.groupId]
	if group == nil or group.reverseUnits == nil or group.reverseUnitCount == nil then return end
	group.checksDone = group.checksDone or 0
	group.unitsToFixByType = group.unitsToFixByType or {}
	group.fixCancelled = group.fixCancelled or false
	group.fixCancelledByType = group.fixCancelledByType or {}
	group.thirdTurnFrameCountByType = group.thirdTurnFrameCountByType or {}
	group.thirdTurnUnitCountByType = group.thirdTurnUnitCountByType or {}
	group.firstTurnFrameCountByType = group.firstTurnFrameCountByType or {}
	group.firstTurnUnitCountByType = group.firstTurnUnitCountByType or {}
	group.expectedChecks = group.expectedChecks or 0
	group.unitsNotMovingBeforeBackingUp = group.unitsNotMovingBeforeBackingUp or 0
	local selectedUnitList = group.reverseUnits
	local selectedCount = group.reverseUnitCount
	if selectedCount <= 0 then return end
	--WriteToFile("groupId.txt",  tostring(unitReversing.groupId) .. " group size: " .. tostring(group.unitCount) .. " reverse move unit count: " .. tostring(group.reverseUnitCount) .. "\n")
	-- edge case for when units are attacking to permit an extended range check (disabled for now)
	--local enableExtendedCheck = unitReversing.wasAttackingBeforeReverse and (group.unitsNotMovingBeforeBackingUp >= ceil(selectedCount*0.50))
	unitReversing.wasAttackingBeforeReverse = false
	-- when units attack they always stop moving before a reverse move is issued
	--if (unitReversing.wasAttackingBeforeReverse and enableExtendedCheck) then print("attacking") end
	--local lowerLimit = enableExtendedCheck and unitBugData.bugCheckLowerLimit+1 or unitBugData.bugCheckLowerLimit
	--local upperLimit = enableExtendedCheck and unitBugData.bugCheckUpperLimit+1 or unitBugData.bugCheckUpperLimit
	local lowerLimit = unitBugData.bugCheckLowerLimit
	local upperLimit = unitBugData.bugCheckUpperLimit
	-- WriteToFile("upperLimit.txt",  tostring(upperLimit) .. "\n")
	-- lowerLimit causes false positives when units are ordered to move at more than screen distance
	if frameDiff > bugDuration + upperLimit then frameDiff = bugDuration end
	local inBugRange = frameDiff >= bugDuration - lowerLimit and frameDiff <= bugDuration + upperLimit
	-- if the average first turn frameDiff for this unit type equals bugDuration, override inBugRange
	local selfObjName = getObjectName(self)
	group.unitsToFixByType[selfObjName] = group.unitsToFixByType[selfObjName] or {}
	local unitsToFixForType = group.unitsToFixByType
	local isBugging = false
	if unitReversing.fastTurnWas0Frames then
		-- if two fast turns yields framediff of 0, it can be assumed the number of frames in -TURN_LEFT or -TURN_RIGHT is 7 (for buggies)
		if inBugRange then
			isBugging = true
		end
		 --ExecuteAction("NAMED_FLASH_WHITE", self, 2)
	elseif frameDiff == 0 then
		unitReversing.fastTurnWas0Frames = true
	elseif inBugRange then
		isBugging = true
	end

    --if isBugging then ExecuteAction("NAMED_FLASH_WHITE", self, 2) end
	-- checksDone is more than ceil(unitReversing.groupId.selectedCount*0.5)
	if not unitReversing.hasBeenCounted then
		group.checksDone = group.checksDone + 1
		unitReversing.hasBeenCounted = true
	end
	-- First determine if this unit is bugging and add it to the list, dont fix units that are being already fixed
	if isBugging then
		-- unitReversing.hasBeenFixed = true
		-- cache the units if they are to be fixed in this table
		unitReversing.bugFrameDiff = frameDiff
		--ExecuteAction("NAMED_FLASH", self, 2)
		-- verify the unit doesnt already exist in the table to prevent duplicate entries
		local alreadyExists = false
		for _, v in unitsToFixForType[selfObjName] do
			if v == a then
				alreadyExists = true
				break
			end
		end
		if not alreadyExists then
			tinsert(unitsToFixForType[selfObjName], a)
			--ExecuteAction("NAMED_FLASH", self, 2)
		end
	end

	-- WriteToFile("checksDoneInt.txt",  tostring(checksDone) .. " num of units bugging: " .. tostring(getn(unitsToFixForType)) "\n")
	-- Now check threshold after unitsToFixByType has been updated

	-- FALSE POSITIVE FILTERS -- 
	local fixUnits = false
	-- WriteToFile("data.txt", "this unit has three turn count: " .. tostring(thirdTurnUnitCount) .. "\n")
	-- this prevents fixing a group of units that are doing a 180 degree turn.
	--local fixCancelledForType = group.fixCancelledByType and group.fixCancelledByType[objName]

	if not group.fixCancelled then
		-- WriteToFile("checksDone.txt", "checks done: " .. tostring(group.checksDone) .. " expected checks: " .. tostring(group.expectedChecks) .. "\n")
		if group.checksDone >= ceil(group.expectedChecks * CHECKS_DONE_THRESHOLD) then

			-- fix units that havent backedUp
			if group.checksDone == group.expectedChecks-1 then
				for _, unitRef in selectedUnitList do
       				local unit = unitsReversing[unitRef]
        			if unit ~= nil and EvaluateCondition("NAMED_NOT_DESTROYED", unit.stringReference) and not unit.hasBeenFixed and not (unit.isReverseMoving or unit.hasComeToAStop) then
                		FixBuggingUnit(unit.selfReference, false)
        			end
 				 end
			end

			-- if number of units bugging is less than the count * BUG_THRESHOLD_SMALL_GROUP
			-- if more than LARGE_GROUP_SIZE units are selected, make the detection more forgiving

			local bugThreshold = selectedCount > LARGE_GROUP_SIZE and BUG_THRESHOLD_LARGE_GROUP or BUG_THRESHOLD_SMALL_GROUP
			local maxBugging = ceil(selectedCount*bugThreshold)
			local totalBugging = 0	

			for _, unitType in group.unitsToFixByType do totalBugging = totalBugging + getn(unitType) end
			--ExecuteAction("SHOW_MILITARY_CAPTION", tostring(totalBugging), 2)	
			--WriteToFile("totalBugging.txt", tostring(totalBugging) .. "\n")
			if totalBugging <= maxBugging then
				-- proceed to fix the units
				fixUnits = true
			else
				group.fixCancelled = true
			end

			-- key is the object name, value is the count of the units of that object name in this group
			for objName,_ in group.reverseUnitsByType do
				local unitBugDataType = unitBugDataTable[objName]
				bugDuration = unitBugDataType.frameCount
				-- WriteToFile("objName.txt",  tostring(objName) .. "\n")
				-- per-type counts for avg third turn cancellation
				local thirdTurnUnitCountForType = (group.thirdTurnUnitCountByType and group.thirdTurnUnitCountByType[objName]) or 0
				-- local thirdTurnUnitCount = group.unitsThatPerformedThirdTurn
				-- if the average amount of third turns exceeds the threshold for this unit type, cancel the fix for the entire group of that unit type.
				if thirdTurnUnitCountForType > 1 then
					local thirdTurnFrameCountForType = (group.thirdTurnFrameCountByType and group.thirdTurnFrameCountByType[objName]) or 0
					--local avgThirdTurnCount = ceil(thirdTurnFrameCountForType / thirdTurnUnitCountForType)
					local avgThirdTurnCount = floor((thirdTurnFrameCountForType + thirdTurnUnitCountForType - 1) / thirdTurnUnitCountForType) 
					--WriteToFile("average.txt",  tostring(avgThirdTurnCount) .. "\n")
					-- (disabled for now)
					--local avgTurnCountOffset  = enableExtendedCheck and unitBugData.avgTurnCountOffset-1 or unitBugData.avgTurnCountOffset-1
					if avgThirdTurnCount >= bugDuration-unitBugDataType.avgTurnCountOffset-1 then
						group.fixCancelledByType = group.fixCancelledByType or {}
						-- objName is currently only just this object
						group.fixCancelledByType[objName] = true
						-- fixUnits = false
						-- print("1st false positive filter")
						-- ExecuteAction("NAMED_FLASH_WHITE", self, 2)
					end
				end

				local firstTurnUnitCountForType = (group.firstTurnUnitCountByType and group.firstTurnUnitCountByType[objName]) or 0
				-- if the average first turn frameDiff for this unit type is within bug range, only fix units whose frameDiff == bugDuration
				if firstTurnUnitCountForType > 0 then
					local firstTurnFrameCountForType = (group.firstTurnFrameCountByType and group.firstTurnFrameCountByType[objName]) or 0
					--local avgFirstTurnCount = ceil(firstTurnFrameCountForType / firstTurnUnitCountForType)
					local avgFirstTurnCount = floor((firstTurnFrameCountForType + firstTurnUnitCountForType - 1) / firstTurnUnitCountForType) 
					--WriteToFile("averageFirst.txt",  tostring(avgFirstTurnCount) .. "\n")
					if avgFirstTurnCount >= floor(bugDuration*unitBugDataType.avgFirstTurnRatio+0.5) then
						--print("2nd false positive filter")
						local unitsForObj = unitsToFixForType[objName] or {}
						for i = getn(unitsForObj), 1, -1 do
							local unit = unitsReversing[unitsForObj[i]]
							if unit == nil or unit.bugFrameDiff ~= bugDuration and not unit.wasAttackingBeforeReverse and getObjectName(unit.selfReference) == tostring(objName) then
								--print("removing")
								--tremove(unitsToFixForType, i)
								group.fixCancelledByType[objName] = true
							end
						end
					end
				end
			end

			-- FOR ADDING NEW UNITS 
			-- A high thirdTurnUnitCount indicates units have performed the reverse move bug.
			-- A low value (0-2) means units are turning normally and not bugging, so cancel the fix.
			-- Exception: when most units were not moving before backing up (e.g. units that stopped to attack),
			-- used to prevent false detections when reversing in the direction it was oriented in before reverse moving.
			if not group.thirdTurnCountChecked then
				group.thirdTurnCountChecked = true
				-- total across all types for thirdTurnMinRatio check
				local notAllTypesAreBugging = false
				-- count is is the ObjName 
				for objName,count in group.reverseUnitsByType do 
					local count = getTableSize(count)
					unitBugDataType = unitBugDataTable[objName]
					local thirdTurnUnitCountForType = (group.thirdTurnUnitCountByType and group.thirdTurnUnitCountByType[objName]) or 0
					-- WriteToFile("data.txt", "thirdTurnUnitCount: " .. tostring(thirdTurnUnitCountForType) .. " is less than " .. tostring(ceil(count*unitBugData.thirdTurnMinRatio)) .. " group.unitsNotMovingBeforeBackingUp: " .. tostring(group.unitsNotMovingBeforeBackingUp) .. " is more than: " .. tostring(ceil(count*unitBugData.notMovingBackupRatio)) .. "\n")
					if not (thirdTurnUnitCountForType < ceil(count*unitBugDataType.thirdTurnMinRatio) and not (group.unitsNotMovingBeforeBackingUp >= ceil(count*unitBugDataType.notMovingBackupRatio))) then
						notAllTypesAreBugging = true
						--group.fixCancelledByType[objName] = true
						-- group.fixCancelled = true
						--ExecuteAction("NAMED_FLASH", self, 2)
					end
				end
				if not notAllTypesAreBugging then
					--print("3rd false positive filter")
					fixUnits = false
				end
			end
		end


		-- Apply fixes if threshold was met
		-- fixUnits alone triggers the fix so that a non-bugging unit that pushes
		-- checksDone over the threshold can still fix earlier-detected bugging units
		if fixUnits then
			local totalToFix = 0
			for _, unitType in group.unitsToFixByType do totalToFix = totalToFix + getn(unitType) end
			if totalToFix > 0 then
				--WriteToFile("fixUnits.txt", "fixing " .. tostring(totalToFix) .. " units\n\n\n" .. "------------------------------------------------")
				for k, unitType in group.unitsToFixByType do
					if not group.fixCancelledByType[k] then
						for i = getn(unitType), 1, -1 do
							local buggingUnit = unitsReversing[unitType[i]]
							if buggingUnit ~= nil then
								local buggingRef = buggingUnit.selfReference
								--ExecuteAction("NAMED_FLASH_WHITE", buggingRef, 2)
								FixBuggingUnit(buggingRef, true)
							else
								if unitType[i] ~= nil then
									tremove(unitType, i)
								end
							end
						end
					end
				end
			elseif isBugging then
				--ExecuteAction("NAMED_FLASH", self, 2)
				FixBuggingUnit(self, true)
			end
		elseif isBugging and group.checksDone >= ceil(group.expectedChecks * CHECKS_DONE_THRESHOLD) then
			-- Only clear bugging state when threshold was reached and we decided not to fix
			-- (too many bugging = likely false positive). Before threshold is reached,
			-- keep the state so the unit can still be fixed when slower types finish checking.
			if EvaluateCondition("UNIT_HAS_OBJECT_STATUS", unitReversing.stringReference, 4) then
				ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", unitReversing.stringReference, 4, 0)
			end
			--unitReversing.hasBeenFixed = false
		end
	end
end

function UnitIsAttacking(self)
	local _,unitReversing = GetUnitReversingData(self)
	if unitReversing == nil then return end
	unitReversing.wasAttackingBeforeReverse = true
end

-- Triggered by +BACKING_UP -TURN_LEFT_HIGH_SPEED and +BACKING_UP -TURN_RIGHT_HIGH_SPEED
function BackingUpFastTurnEnd(self)
    local _,unitReversing = GetUnitReversingData(self)
	if unitReversing == nil or unitReversing.groupId == nil then return end
	-- prevents this from executing when the unit is not moving or has already reverse moved 
	if unitReversing.hasComeToAStop or unitReversing.hasAlreadyReversed or unitReversing.timesTriggeredFast > TURN_TRIGGER_COUNT then return end
	-- check if its DOCKING or DOCKING_BEGINNING (to prevent harvesters from checking for bugs while docking)
	if unitReversing.isReverseMoveHarvester then
		if ObjectTestModelCondition(self, "DOCKING") or ObjectTestModelCondition(self, "DOCKING_BEGINNING") or ObjectTestModelCondition(self, "DOCKING_ENDING") then return end
	end
	local curFrame = GetFrame()
	local frameDiff = curFrame - unitReversing.firstFrame
	local playerTeam = tostring(ObjectTeamName(self))
	local group = isValidTeam(playerTeam) and getglobal(playerTeam)[unitReversing.groupId] or nil
	--local group = unitGroups[unitReversing.groupId]

	-- track units that have backedup after receiving a groupId
	if not unitReversing.expectedChecksFlag then
		if group ~= nil then
			group.expectedChecks = (group.expectedChecks or 0) + 1
		end
		unitReversing.expectedChecksFlag = true
	end

	if unitReversing.timesTriggeredFast == 1 then
		--WriteToFile("backingupfastend.txt",  "object went this long with 1 trigger: " .. tostring(frameDiff) .. "\n")
		if group ~= nil then
			local objName = getObjectName(self)
			group.firstTurnFrameCountByType = group.firstTurnFrameCountByType or {}
			group.firstTurnUnitCountByType = group.firstTurnUnitCountByType or {}
			group.firstTurnFrameCountByType[objName] = (group.firstTurnFrameCountByType[objName] or 0) + frameDiff
			group.firstTurnUnitCountByType[objName] = (group.firstTurnUnitCountByType[objName] or 0) + 1
		end
		CheckForObjReverseBugging(self, frameDiff)
	end
	
	if unitReversing.timesTriggeredFast == 2 and unitReversing.groupId ~= nil then
		--WriteToFile("backingupfastend2.txt",  "object went this long with 2 trigger: " .. tostring(frameDiff) .. "\n")	
		if group ~= nil then
			-- objName is the type of unit such as Scorpion Tank, Raider Buggy, Seeker Tank
			local objName = getObjectName(self)
			group.thirdTurnFrameCountByType = group.thirdTurnFrameCountByType or {}
			group.thirdTurnUnitCountByType = group.thirdTurnUnitCountByType or {}
			group.thirdTurnFrameCountByType[objName] = (group.thirdTurnFrameCountByType[objName] or 0) + frameDiff
			group.thirdTurnUnitCountByType[objName] = (group.thirdTurnUnitCountByType[objName] or 0) + 1
		end
	end
	unitReversing.timesTriggeredFast = unitReversing.timesTriggeredFast + 1
end	

-- Triggered by +BACKING_UP -TURN_LEFT and +BACKING_UP -TURN_RIGHT
function BackingUpTurnEnd(self)
    local _,unitReversing = GetUnitReversingData(self)
	if unitReversing == nil then return end
	if unitReversing.hasComeToAStop or unitReversing.hasAlreadyReversed then return end
	-- check if its DOCKING or DOCKING_BEGINNING (to prevent harvesters from checking for bugs while docking)
	if unitReversing.isReverseMoveHarvester then
		if ObjectTestModelCondition(self, "DOCKING") or ObjectTestModelCondition(self, "DOCKING_BEGINNING") or ObjectTestModelCondition(self, "DOCKING_ENDING") then return end
	end
	local timesToTrigger = TURN_TRIGGER_COUNT
	local frameDiff = GetFrame() - unitReversing.firstFrame

   if unitReversing ~= nil and unitReversing.timesTriggeredNormal < timesToTrigger then
		unitReversing.timesTriggeredNormal = unitReversing.timesTriggeredNormal + 1
		if unitReversing.fastTurnWas0Frames then
			--WriteToFile("backingupfastendthree.txt",  "object went this long with 3 triggers: " .. tostring(frameDiff) .. "\n")
			CheckForObjReverseBugging(self, frameDiff)
		end
	end
end

-- if the unitAnchor has bugged during the reverse move, seek out a unit that hasnt of that players selection.
-- selectedUnitsOfPlayer is the array of units whose value is ObjectId
-- unit is the string reference of the unit that called this function
function GetANonBuggingUnit(selectedUnitsOfPlayer, unit)
	if selectedUnitsOfPlayer == nil then return nil end
	local _,unitReversing = GetUnitReversingData(unit)
	local candidates = {}
	local isHarv = unitReversing.isReverseMoveHarvester 
	for _, unitRef in selectedUnitsOfPlayer do
		local cachedUnit = unitsReversing[unitRef]
		if cachedUnit ~= nil then
			if cachedUnit.selfReference ~= unit and not cachedUnit.hasBeenFixed then
				-- check to see if unit is bugging and isnt destroyed
				if EvaluateCondition("NAMED_NOT_DESTROYED",cachedUnit.stringReference) and not EvaluateCondition("UNIT_HAS_UPGRADE",cachedUnit.stringReference, "Upgrade_ReverseMoveSpeedBuff") and ObjectTestModelCondition(cachedUnit.selfReference, "USER_72") == false then
					if not isHarv then
						tinsert(candidates, cachedUnit.stringReference)
					else
						if cachedUnit.isReverseMoveHarvester then
							tinsert(candidates, cachedUnit.stringReference)
						end
					end
				end
			end
		end
	end
	if getn(candidates) > 0 then
		return candidates[random(1, getn(candidates))]
	end
end
		
-- Fixes a unit detected to be bugging and then checks if any selected unit has the bugged unit assigned as unitAnchor
function FixBuggingUnit(self, applySpeedBuff)
	local a,unitReversing = GetUnitReversingData(self)
	if unitReversing == nil or not unitReversing.groupIdAssigned or unitReversing.groupId == nil then return end
	local playerTeam = tostring(ObjectTeamName(self))
	local group = isValidTeam(playerTeam) and getglobal(playerTeam)[unitReversing.groupId] or nil
	--local group = unitGroups[unitReversing.groupId]
	if group == nil or group.units == nil then return end
	local selectedUnitList = group.units

	if group.unitCount == 1 then 
		-- only one unit selected, so stop this unit and end the function
		-- WriteToFile("only one unit selected.txt",  tostring(group.unitCount) .. "\n")
		-- ExecuteAction("NAMED_STOP", self)
		return 
	end

	-- check if unitAnchor is destroyed or is nil
	if unitReversing.unitAnchor ~= nil then
		if not EvaluateCondition("NAMED_NOT_DESTROYED",unitReversing.unitAnchor) then 
			unitReversing.unitAnchor = GetANonBuggingUnit(selectedUnitList, self)
		end
	else
		 unitReversing.unitAnchor = GetANonBuggingUnit(selectedUnitList, self)
		 -- there are no units that arent bugging so lets just stop this one and return the function
		 if unitReversing.unitAnchor == nil then
			-- ExecuteAction("NAMED_STOP", self)
			return 
		end
	end
	--WriteToFile("closeunit.txt",  "closest unit:  " .. tostring(unitReversing.unitAnchor) .. "\n")
	if not unitReversing.hasBeenFixed and unitReversing.unitAnchor ~= nil then
		ExecuteAction("UNIT_GUARD_OBJECT", unitReversing.stringReference, unitReversing.unitAnchor)	
		unitReversing.hasBeenFixed = true
	end

	if ObjectTestModelCondition(self, "USER_72") == false then
		ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", self, "USER_72", NO_COLLISION_DURATION, 100)
	end
	-- temporarily remove collisions to facilitate the reverse move, assign this on backing up
	if not EvaluateCondition("UNIT_HAS_OBJECT_STATUS", unitReversing.stringReference, 4) then
		ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", unitReversing.stringReference, 4, 1)
	end
	-- apply upgrade 
	if not EvaluateCondition("UNIT_HAS_UPGRADE",unitReversing.stringReference, "Upgrade_ReverseMoveSpeedBuff") and applySpeedBuff then
		ObjectGrantUpgrade(self, "Upgrade_ReverseMoveSpeedBuff") 
	end

	for _, unitRef in selectedUnitList do
		--  this unit is bugging so lets go through all the closest units and see if it coincides with this one
		-- 	WriteToFile("closeunit.txt",  "object 1:  " .. tostring(unitsReversing[unitRef].stringReference)  .. "  " .. "object 2: " .. tostring(unitsReversing[unitRef].unitAnchor) .. "\n")
		if unitsReversing[unitRef] ~= nil and unitsReversing[unitRef].unitAnchor ~= nil then
			if unitsReversing[unitRef].unitAnchor == unitReversing.stringReference then
				-- get a unit that hasnt bugged that isnt itself
				local nonBuggingUnit = GetANonBuggingUnit(group.units, unitsReversing[unitRef].selfReference)
				-- only proceed if we found a non-bugging unit
				if nonBuggingUnit ~= nil then
					-- assign the new closeestUnit to a unit not flagged as being bugged
					unitsReversing[unitRef].unitAnchor = nonBuggingUnit
					-- move this unit to the previously assigned non bugging unit
					if unitsReversing[unitRef].hasBeenFixed and EvaluateCondition("UNIT_HAS_UPGRADE",unitsReversing[unitRef].stringReference, "Upgrade_ReverseMoveSpeedBuff") and ObjectTestModelCondition(unitsReversing[unitRef].selfReference, "USER_72") then
						--print("assigning to different unit")
						ExecuteAction("UNIT_GUARD_OBJECT", unitsReversing[unitRef].stringReference, unitsReversing[unitRef].unitAnchor)
					end
				end
			end
		end
		-- WriteToFile("closeunit.txt",  "object 1:  " .. tostring(unitsReversing[unitRef].stringReference)  .. "  " .. "object 2: " .. tostring(unitsReversing[unitRef].unitAnchor) .. "\n")
	end
end

-- Gets a random selected unit of this players selection and assigns it to unitReversing.unitAnchor = unitAnchor
function AssignRandomAnchor(self)
	local a,unitReversing = GetUnitReversingData(self)
	if unitReversing == nil or unitReversing.groupId == nil then return end
	local playerTeam = tostring(ObjectTeamName(self))
	local group = isValidTeam(playerTeam) and getglobal(playerTeam)[unitReversing.groupId] or nil
	--local group = unitGroups[unitReversing.groupId]
	if group == nil or group.units == nil then return end
	-- list of ids
	local selectedUnitList = group.units
	-- Online interface lag sometimes assigns harvesters to a unit group, only use harvesters of this type as a candidate for anchor.
	if unitReversing.isReverseMoveHarvester then 
		--selectedUnitList = group.reverseUnitsByType[getObjectName(self)]
		local reverseHarvesters = {}
		for _,unitRef in group.reverseUnits do
			if unitsReversing[unitRef].isReverseMoveHarvester then
				reverseHarvesters[unitRef] = unitRef
			end
		end
		selectedUnitList = reverseHarvesters
	end
	-- Check if we have at least 2 units in the selection (self + at least one other)
	if next(selectedUnitList) ~= nil and next(selectedUnitList, next(selectedUnitList)) ~= nil then	
		-- gets a unit that isnt self randomly.
		local randomUnitId = GetRandomKey(selectedUnitList, a)
		if randomUnitId ~= nil and unitsReversing[randomUnitId] ~= nil then
			unitReversing.unitAnchor = unitsReversing[randomUnitId].stringReference
		end
	end
end

-- Triggered by +BACKING_UP
function BackingUp(self)
    local a, unitReversing = GetUnitReversingData(self)
	if unitReversing == nil then return end
	if unitReversing.isReverseMoveHarvester then
		if ObjectTestModelCondition(self, "DOCKING") or ObjectTestModelCondition(self, "DOCKING_BEGINNING") or ObjectTestModelCondition(self, "DOCKING_ENDING") then return end
	end
    local curFrame = GetFrame()
	unitReversing.lastMoveWasReverse = true

	--WriteToFile("wasAttackingBeforeReverse.txt",  tostring(unitReversing.wasAttackingBeforeReverse) .. "\n")
	if EvaluateCondition("UNIT_HAS_UPGRADE",unitReversing.stringReference, "Upgrade_ReverseMoveSpeedBuff") then
		--print("removing upgrade")
		ObjectRemoveUpgrade(self, "Upgrade_ReverseMoveSpeedBuff") 
	end	
	if ObjectTestModelCondition(self, "USER_72") then
		ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", self, "USER_72", 0, 100)
	end

	-- Reset the flags here to ensure we don't carry over bugs from previous moves
	local resetFlags = function()
		%unitReversing.hasBeenFixed = false
		%unitReversing.unitAnchor = nil
		%unitReversing.timesTriggeredFast = 0
		%unitReversing.timesTriggeredNormal = 0
		%unitReversing.firstFrame = %curFrame
		%unitReversing.isReverseMoving = true
		%unitReversing.hasBeenCounted = false
		%unitReversing.expectedChecksFlag = false
	end

	 -- Check if this is a spam/repeat command (within 2 frames) or a generic new command
    if curFrame - unitReversing.lastReverseMoveFrame <= REVERSE_SPAM_FRAME_WINDOW then
        unitReversing.hasAlreadyReversed = true
        return resetFlags()
	end 

	if unitReversing.hasComeToAStop then
		unitReversing.hasComeToAStop = false
		return resetFlags()
	end

	-- Reset the flags here to ensure we don't carry over bugs from previous moves
	resetFlags()
	unitReversing.hasAlreadyReversed = false

	local groupId = unitReversing.groupId 
	if groupId ~= nil then
		local playerTeam = tostring(ObjectTeamName(self))
		local group = isValidTeam(playerTeam) and getglobal(playerTeam)[groupId] or nil
		if group ~= nil and (group.unitCount <= 0 or next(group.units) == nil) then
			--unitGroups[groupId] = nil
			getglobal(playerTeam)[groupId] = nil
			--CheckExistingGroups(self)
			--print("clearing global")
		end
	end

	if unitReversing.hasBeenSelected then
		AssignGroupId(unitReversing, a, curFrame, self)
	end

	AssignRandomAnchor(self)
end

-- copies a snapshot and recursively snapshots nested tables within.
function DeepCopyTable(original)
    if type(original) ~= "table" then
        return original
    end

    local copy = {}
    for k, v in original do
        copy[k] = DeepCopyTable(v)
    end
    
    return copy
end

-- Triggered by +SELECTED
function AddToUnitSelection(self)
	-- initialized here to prevent first instance of BACKING_UP having a cascading effect.
	local _, unitReversing = GetUnitReversingData(self)
	unitReversing.hasBeenSelected = true
	-------------------------------------------------------------------------------------
    local unitId = getObjectId(self)
	local playerTeam = tostring(ObjectTeamName(self))
	local teamTable = isValidTeam(playerTeam) and getglobal(playerTeam) or nil

	if unitId ~= nil and teamTable ~= nil and teamTable.units ~= nil then
		if teamTable.units[unitId] == nil then
			teamTable.units[unitId] = unitId
			--teamTable.unitCount = (teamTable.unitCount or 0) + 1
			teamTable.unitCount = getTableSize(teamTable.units)
			-- if this units hash exists in the unitBugDataTable, it can reverse move therefore we count it
			local objName = getObjectName(self)
			if unitBugDataTable[objName] ~= nil then
				if teamTable.reverseUnits ~= nil and teamTable.reverseUnits[unitId] == nil then
					teamTable.reverseUnits[unitId] = unitId
					teamTable.reverseUnitCount = getTableSize(teamTable.reverseUnits)
					--store a table of current selected unit types
					--if teamTable.reverseUnitsByType[objName] == nil then
					--teamTable.reverseUnitsByType[objName] = (teamTable.reverseUnitsByType[objName] or 0) + 1 
					if teamTable.reverseUnitsByType[objName] == nil then
						teamTable.reverseUnitsByType[objName] = {}
						--getGlobals()
					end
					teamTable.reverseUnitsByType[objName][unitId] = unitId
				end
			end
		end
	end
end
-- Triggered by -SELECTED
function RemoveFromUnitSelection(self)
    local playerTeam = tostring(ObjectTeamName(self)) 
    local unitId = getObjectId(self)
	local teamTable = getglobal(playerTeam) 
    
    if unitId ~= nil and teamTable ~= nil and teamTable.units ~= nil then
        -- distinct check using the Key
        if teamTable.units[unitId] ~= nil then
            -- Set to nil to remove
            teamTable.units[unitId] = nil
            --teamTable.unitCount = (teamTable.unitCount or 1) - 1
			teamTable.unitCount = getTableSize(teamTable.units)
			if teamTable.reverseUnits ~= nil and teamTable.reverseUnits[unitId] ~= nil then
				teamTable.reverseUnits[unitId] = nil
				teamTable.reverseUnitCount = getTableSize(teamTable.reverseUnits)

				local objName = getObjectName(self)
				if teamTable.reverseUnitsByType[objName] ~= nil then
					teamTable.reverseUnitsByType[objName][unitId] = nil
					if getTableSize(teamTable.reverseUnitsByType[objName]) <= 0 then 
						teamTable.reverseUnitsByType[objName] = nil
					end
				end
			end
			--WriteToFile("teamTable.txt", "teamTable unitCount: " .. tostring(teamTable.unitCount) .. "\n")
			--if teamTable.unitCount <= 0 or next(teamTable.units) == nil then
			--	setglobal(playerTeam, CreateBaseTeamTable())		
				--print("clearing global, units deselected")
			--end
			--print("unit deselected")
        end
    end
end

function CheckExistingGroups(unitReversing, group)
	if group == nil or unitReversing == nil then return end
	local reverseUnitList = {}
	if group ~= nil and group.reverseUnits ~= nil then
		reverseUnitList = group.reverseUnits
	end
	-- prevents stale group state on non-reverse units
	local groupUnitList = {}
	if group ~= nil and group.units ~= nil then
		groupUnitList = group.units
	end

	--if checksDone == unitReversing.groupId.selectedCount-1 then
	local clearList = true
	local groupId  = unitReversing.groupId
	for _, unitRef in reverseUnitList do
		if unitsReversing[unitRef] ~= nil and unitsReversing[unitRef].isReverseMoving and (unitsReversing[unitRef].groupId == groupId) then
			-- if a unit is reverse moving, dont clear the list
			clearList = false
			break
		end
	end
	if clearList and group ~= nil then
		-- clear groupId for all units in this group including the current one.
		for _, unitRef in groupUnitList do
			-- WriteToFile("groupUnitList.txt", tostring(unitRef) .. "\n")
			-- if the id is the same as the id in current index clear it
			if unitsReversing[unitRef] ~= nil and unitsReversing[unitRef].groupId == groupId and EvaluateCondition("NAMED_NOT_DESTROYED", unitsReversing[unitRef].stringReference) then
				--unitsReversing[unitRef].groupId = nil
				unitsReversing[unitRef].groupIdAssigned = false
				unitsReversing[unitRef].expectedChecksFlag = false
				unitsReversing[unitRef].hasBeenCounted = false
				-- clear USER_72 and speed bonuses if this entire group no longer is no reverse moving 
				if ObjectTestModelCondition(unitsReversing[unitRef].selfReference, "USER_72") then
					--ExecuteAction("NAMED_FLASH", unitsReversing[unitRef].selfReference, 2)
					BuggedUnitTimeoutEnd(unitsReversing[unitRef].selfReference)
				end
			end
		end
		--WriteToFile("cleared list.txt", tostring(unitReversing.groupId) .. " " ..  tostring(unitReversing.groupIdAssigned) .. "\n")
		--free the global snapshot since all units have been cleared
		--unitGroups[groupId] = nil
		local playerTeam = tostring(ObjectTeamName(unitReversing.selfReference))
		if isValidTeam(playerTeam) then getglobal(playerTeam)[groupId] = nil end
		--CheckExistingGroups(self)
	end
end

-- Clears the unitsReversing table of this unit. If it belongs in a group, remove it. 
function GroupUnitOnDeath(self)
	local a,unitReversing = GetUnitReversingData(self)	
	local groupId = unitReversing and unitReversing.groupId
	unitsReversing[a] = nil
	if next(unitsReversing) == nil then
		flushPlayerTeams() 
		return
		--WriteToFile("flushingplayers.txt", tostring(getn(unitsReversing)) .. "\n")
	end

	-- remove from the group its part of
	-- WriteToFile("unitId.txt", tostring(a) .. "\n")
	if groupId ~= nil then
		local playerTeam = tostring(ObjectTeamName(self))
		local group = isValidTeam(playerTeam) and getglobal(playerTeam)[groupId] or nil
		--local group = unitGroups[groupId] 
		-- remove this unit from the group snapshot
		if group ~= nil and group.units ~= nil and group.units[a] ~= nil then
			group.units[a] = nil
			--group.unitCount = (group.unitCount or 1) - 1
			group.unitCount = getTableSize(group.units)
			if group.reverseUnits ~= nil and group.reverseUnits[a] ~= nil then
				group.reverseUnits[a] = nil
				group.reverseUnitCount = getTableSize(group.reverseUnits)
				if group.expectedChecks > 0 then
					group.expectedChecks = group.expectedChecks - 1
				end
			end
			-- check if theres no units left in the group and if so , clear the global.
			CheckExistingGroups(unitReversing, group)
			if group ~= nil and (group.unitCount <= 0 or next(group.units) == nil) then
				--unitGroups[groupId] = nil
				getglobal(playerTeam)[groupId] = nil
				--CheckExistingGroups(self)
				--print("clearing global on death")
			end
		end
	end
	RemoveFromUnitSelection(self)
end

-- gets the current selection count of units that are within a group of units
-- @param teamTable: the current selection of a player
-- @param group: the unit group to be compared against
-- @return the number of units that are currently selected that are within the unit group
function GetCurrentSelectionCountOfGroup(teamTable, group)
	if teamTable == nil or teamTable.units == nil or group == nil or group.reverseUnits == nil then return 0 end
	local count = 0
	for unitRef,_ in group.reverseUnits do
		if teamTable.units[unitRef] ~= nil then
			count = count + 1
		end
	end
	--WriteToFile("GetCurrentSelectionCountOfGroup.txt",  "# of units that are selected and also belong to the group: " .. tostring(count) .. "\n")
	return count
end

-- checks if the group still exists if most units are still moving, and if this one has stopped then call FixBuggingUnit to fix it
function SuddenStopCheck(self)
	local _,unitReversing = GetUnitReversingData(self)
	if unitReversing == nil or unitReversing.groupId == nil then return end
	local resetGroupId = function()
		--%unitReversing.groupId = nil
		%unitReversing.groupIdAssigned = false
	end
	if ObjectTestModelCondition(self, "MOVING") or unitReversing.hasBeenFixed or unitReversing.hasComeToAStop or not unitReversing.lastMoveWasReverse then return resetGroupId() end
	-- check if its DOCKING or DOCKING_BEGINNING (to prevent harvesters from checking for bugs while docking)
	if unitReversing.isReverseMoveHarvester then
		if ObjectTestModelCondition(self, "DOCKING") or ObjectTestModelCondition(self, "DOCKING_BEGINNING") or ObjectTestModelCondition(self, "DOCKING_ENDING") then return resetGroupId() end
	end
	unitReversing.lastMoveWasReverse = false
	--unitReversing.isReverseMoving = false
	local playerTeam = tostring(ObjectTeamName(self))
	local group = isValidTeam(playerTeam) and getglobal(playerTeam)[unitReversing.groupId] or nil
	--local group = unitGroups[unitReversing.groupId]
	if group == nil or group.reverseUnits == nil or group.reverseUnitCount == nil then return resetGroupId() end
	local curFrame = GetFrame()
	-- the duration of the reverse move since this unit came to an abrupt stop
	-- if most units are still moving but this one suddenly stopped, it bugged

	local frameDiff = curFrame - unitReversing.firstFrame
	--WriteToFile("SuddenStopAfterBackingUp.txt",  "this reverse move lasted: " .. tostring(frameDiff) .. " frames" .. "\n")

	-- look up this units bug duration and scale the threshold proportionally
	-- 15 frames works for Seeker (frameCount=12), ratio: 15/12 = 1.25
	-- This is necessary to prevent tagging units that never backed up but got the model state somehow.
	local unitBugData = unitBugDataTable[getObjectName(self)]
	if unitBugData == nil then return resetGroupId() end
	local bugDuration = unitBugData.frameCount
	bugDuration = ObjectTestModelCondition(self, "REALLYDAMAGED") and floor(bugDuration*unitBugData.reallyDamagedDurationMult+0.5) or bugDuration
	local maxFrameDiff = floor(bugDuration * 1.25)

	if GetNumberOfUnitsMoving(group.reverseUnits) >= floor(group.reverseUnitCount * 0.80) and frameDiff <= maxFrameDiff then
		local fixUnit = true
		local teamTable = isValidTeam(playerTeam) and getglobal(playerTeam) or nil

		if teamTable ~= nil and teamTable.reverseUnitCount ~= nil and teamTable.reverseUnitCount > 0 and teamTable.reverseUnits ~= nil then
			-- only fix the unit if the current selection is the same as the snapshot selection count. Also when teamTable.unitCount is 0 it means there are no units selected.
			if GetCurrentSelectionCountOfGroup(teamTable, group) < ceil(group.reverseUnitCount * 0.50) then
				fixUnit = false
			end
		end

		if fixUnit then
			--ExecuteAction("NAMED_FLASH_WHITE", self, 2)
			FixBuggingUnit(self, false)
		end
	end
	resetGroupId()
end

-- Triggered by -BACKING_UP, this triggers when multiple reverse move commands.
-- Removes groupId of this unit and then checks if the global of that group is empty and if it is, removes it.
function BackingUpEnd(self)
	local _,unitReversing = GetUnitReversingData(self)
	if unitReversing == nil then return end
	unitReversing.lastReverseMoveFrame =  GetFrame()
	-- unitGroups[unitReversing.groupId]
	if unitReversing ~= nil and not unitReversing.hasBeenFixed then
		-- need to prevent this when guarding
		if EvaluateCondition("UNIT_HAS_OBJECT_STATUS", unitReversing.stringReference, 4) then
			ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", unitReversing.stringReference, 4, 0)
		end
	end

	--unitReversing.firstFrame = 0 
	unitReversing.isReverseMoving = false
	unitReversing.timesTriggeredFast = 0
	unitReversing.timesTriggeredNormal = 0
	unitReversing.fastTurnWas0Frames = false

	-- necessary if units stop 
	SuddenStopCheck(self)
	
	local group = unitReversing.groupId ~= nil and (isValidTeam(playerTeam) and getglobal(playerTeam)[unitReversing.groupId] or nil)
	CheckExistingGroups(unitReversing, group)
end

-- USER_72 has ended, remove NO_COLLISIONS and speed buff if this unit has it.
function BuggedUnitTimeoutEnd(self)
	local _,unitReversing = GetUnitReversingData(self)
	if unitReversing == nil then return end
	unitReversing.hasBeenFixed = false
	--unitReversing.unitAnchor = nil
	if EvaluateCondition("UNIT_HAS_OBJECT_STATUS", unitReversing.stringReference, 4) then
		ExecuteAction("UNIT_CHANGE_OBJECT_STATUS", unitReversing.stringReference, 4, 0)	
	end

	if EvaluateCondition("UNIT_HAS_UPGRADE",unitReversing.stringReference, "Upgrade_ReverseMoveSpeedBuff") then
		ObjectRemoveUpgrade(self, "Upgrade_ReverseMoveSpeedBuff") 
	end		
end

-- ###################################################################

-- EMP EXPLOIT FIX --


function OnUnpackingDisableCommands(self)
	ObjectForbidPlayerCommands( self, true )
end

function OnUnpackingDisableCommandsEnd(self)
	ObjectForbidPlayerCommands( self, false )
end

-- FREE INF FIX R24 --

function CancelProduction(self)
	print("destroyed structure")
	ObjectCreateAndFireTempWeapon(self, "KillUnitsComingOut")
end



function OnGDIWatchTowerCreated(self)
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_01", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_02", true )
	ObjectHideSubObjectPermanently( self, "UG_BASE", true )
	ObjectHideSubObjectPermanently( self, "B_UG_TURRET", true )
end

function OnGDIFirehawkCreated(self)
	-- bomb load by default.
	-- comment out to fix harpoint subobject issue ObjectGrantUpgrade( self, "Upgrade_SelectLoad_02" )
	-- commented out because this is done through animation scripts ObjectHideSubObjectPermanently( self, "Plane04", true )
	ObjectHideSubObjectPermanently( self, "UG_Hardpoints", true )
end

function OnGDIPitbullCreated(self)
	ObjectHideSubObjectPermanently( self, "MortorTube", true )
end

function OnGDIOrcaCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_PROBE", true )
	ObjectHideSubObjectPermanently( self, "UG_HARDPOINTS", true )
	ObjectHideSubObjectPermanently( self, "UG_EC", true )
end

function OnGDISniperSquadCreated(self)
	ObjectSetObjectStatus( self, "CAN_SPOT_FOR_BOMBARD" )
end

function OnGDIOrcaClipEmpty(self)
	ObjectHideSubObjectPermanently( self, "MISSILE01", true )
end

function OnGDIOrcaClipFull(self)
	ObjectHideSubObjectPermanently( self, "MISSILE01", false )
end

function OnGDIV35Ox_SummonedForVehicleCreated(self)
	ObjectHideSubObjectPermanently( self, "LOADREF", true )
end

-- ################# NEW FUNCTIONS FOR 1.03 CFT FIX #################### 
function OnGDIV35Ox_Created_103(self)
	--ObjectForbidPlayerCommands( self, true )	
	ObjectSetObjectStatus( self, "UNSELECTABLE" )	
end

function OnGDIV35Ox1_Created_103(self)
	ObjectHideSubObjectPermanently( self, "LOADREF", true )
	--ObjectForbidPlayerCommands( self, true )
	ObjectSetObjectStatus( self, "UNSELECTABLE" )		
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Ox disabled...", 2)				
end

function OnGDIV35Ox_Carrying_103(self)
	ObjectGrantUpgrade( self, "Upgrade_Transporting" )
	--ObjectForbidPlayerCommands( self, false )
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Ox enabled...", 2)					
end

-- #######################################

function OnNODShredderCreated(self)

end

function OnNODRaiderTankCreated(self)
	ObjectHideSubObjectPermanently( self, "Gun_Upgrade", true )
	ObjectHideSubObjectPermanently( self, "Turret2_Gun", true )
	ObjectHideSubObjectPermanently( self, "Turret2", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_01", true )
	ObjectHideSubObjectPermanently( self, "DOZERBLADE", true )
end

function OnNODAvatarCreated(self)
	ObjectHideSubObjectPermanently( self, "NUBEAM", true )
	ObjectHideSubObjectPermanently( self, "FLAMETANK", true )
	ObjectHideSubObjectPermanently( self, "S_DETECTOR", true )
	ObjectHideSubObjectPermanently( self, "S_GENERATOR", true )
end

-- ################### NEW FUNCTIONS FOR 1.03 AVATAR MULTI UPGRADE FIX ###########
function OnCommandeerFlameTank(self, other)
    if commandeertable[self] == nil then 		
	    --ExecuteAction("SHOW_MILITARY_CAPTION", "Unit commndeered..." .. tostring(other), 2)	
	    commandeertable[self] = other
	    ObjectGrantUpgrade(other, "Upgrade_AvatarFlamer")	
	end
end

function OnCommandeerStealthTank(self, other)
    if commandeertable[self] == nil then 
	    --ExecuteAction("SHOW_MILITARY_CAPTION", "Unit commndeered..." .. tostring(other), 2)	
	    commandeertable[self] = other
	    ObjectGrantUpgrade(other, "Upgrade_AvatarInvisibility")	
	end
end

function OnCommandeerAttackBike(self, other)
    if commandeertable[self] == nil then 
	    --ExecuteAction("SHOW_MILITARY_CAPTION", "Unit commndeered..." .. tostring(other), 2)	
	    commandeertable[self] = other
	    ObjectGrantUpgrade(other, "Upgrade_AvatarStealthDetect")	
	end
end

function OnCommandeerBeamCannon(self, other)
    if commandeertable[self] == nil then 
	    --ExecuteAction("SHOW_MILITARY_CAPTION", "Unit commndeered..." .. tostring(other), 2)	
	    commandeertable[self] = other
	    ObjectGrantUpgrade(other, "Upgrade_AvatarBeamCannon")	
	end
end

function OnCommandeeredDestroyed(self)
    if commandeertable[self] ~= nil then 
       commandeertable[self] = nil
    end
end

-- ##############################################################################

function OnNODAvatarGenericEvent(self, data)

	local str = tostring( data )

	if str == "upgrades_copied" then
		ObjectRemoveUpgrade( self, "Upgrade_Veterancy_VETERAN" );
		ObjectRemoveUpgrade( self, "Upgrade_Veterancy_ELITE" );
		ObjectRemoveUpgrade( self, "Upgrade_Veterancy_HEROIC" );
	end
end

function OnNODScorpionBuggyCreated(self)
	ObjectHideSubObjectPermanently( self, "EMP", true )
	--UnitCreated(self)
end

function OnNODVenomCreated(self)
	ObjectHideSubObjectPermanently( self, "SigGen", true )
end

-- ################ NEW FUNCTIONS FOR 1.03 RAGE STATUS #######################
function OnRaged_103(self)
	ObjectGrantUpgrade( self, "Upgrade_Raged" )
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Unit raged...", 2)			
end

function OnRaged1_103(self)
	ObjectRemoveUpgrade( self, "Upgrade_Raged" )
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Unit no longer raged...", 2)			
end

-- #######################################################################

-- ################ NEW FUNCTIONS FOR 1.03 VENOM REFLECTOR FIX #######################
function OnNODVenomReflectorEnable_103(self)
	ObjectGrantUpgrade( self, "Upgrade_Reflector" )
end

function OnNODVenomReflectorDisable_103(self)
	ObjectRemoveUpgrade( self, "Upgrade_Reflector" )
end
-- #######################################################################


function OnNODTechAssembleyPlantCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_EMP", true )
	ObjectHideSubObjectPermanently( self, "UG_Lasers", true )
	ObjectHideSubObjectPermanently( self, "UG_SigGen", true )
	ObjectHideSubObjectPermanently( self, "UG_DozerBlades", true )
	ObjectHideSubObjectPermanently( self, "SUPERCHARGEDPARTICALBEAM", true )
	ObjectHideSubObjectPermanently( self, "CHARGEDPARTICALBEAM_01", true )
	ObjectHideSubObjectPermanently( self, "CHARGEDPARTICALBEAM_02", true )
	ObjectHideSubObjectPermanently( self, "CHARGEDPARTICALBEAM_03", true )
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILER02", true )
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILER", true )
end

function OnNODSecretShrineCreated(self)
	ObjectHideSubObjectPermanently( self, "GLOWS", true )	
	ObjectHideSubObjectPermanently( self, "ConfUpgrd", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_01", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_02", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_03", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_04", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_05", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_06", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_07", true )
	ObjectHideSubObjectPermanently( self, "CYBERNETICLEGS_08", true )
	ObjectHideSubObjectPermanently( self, "BLACKDISCIPLES_GLOWS", true )
	ObjectHideSubObjectPermanently( self, "BLACKDISCIPLESUPGRD", true )
	ObjectHideSubObjectPermanently( self, "PURIFYINGFLAME01", true )
	ObjectHideSubObjectPermanently( self, "PURIFYINGFLAME02", true )
end

function OnNODHangarCreated(self)
	ObjectHideSubObjectPermanently( self, "DISRUPTIONPODS", true )
	ObjectHideSubObjectPermanently( self, "UG_SIGGEN", true )
	ObjectHideSubObjectPermanently( self, "UG_SIGGEN_02", true )
end

function OnNODOperationsCenterCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_DOZERBLADES", true )
	ObjectHideSubObjectPermanently( self, "UG_QUADTURRETS", true )
	ObjectHideSubObjectPermanently( self, "UG_SIGGEN", true )
end

function OnNODSecretShrinePowerOutage(self)	
	if ObjectHasUpgrade( self, "Upgrade_NODConfessorUpgrade" ) == 1 then
		ObjectHideSubObjectPermanently( self, "GLOWS", true )	
	end
end

function OnNODSecretShrinePowerRestored(self)		 
	if ObjectHasUpgrade( self, "Upgrade_NODConfessorUpgrade" ) == 1 then
		ObjectHideSubObjectPermanently( self, "GLOWS", false )	
	end
end

function onCreatedControlPointFunctions(self)
	ObjectHideSubObjectPermanently( self, "TB_CP_ALN", true )
	ObjectHideSubObjectPermanently( self, "TB_CP_GDI", true )
	ObjectHideSubObjectPermanently( self, "TB_CP_NOD", true )
	ObjectHideSubObjectPermanently( self, "LIGHTSF01", true )
	ObjectHideSubObjectPermanently( self, "100", false)
	ObjectHideSubObjectPermanently( self, "75", false)
	ObjectHideSubObjectPermanently( self, "50", false)
	ObjectHideSubObjectPermanently( self, "25", false )
end

function onBuildingPowerOutage(self)
	ObjectHideSubObjectPermanently( self, "LIGHTS", true )
	ObjectHideSubObjectPermanently( self, "FXLIGHTS05", true )
	ObjectHideSubObjectPermanently( self, "FXLIGHTS", true )
	ObjectHideSubObjectPermanently( self, "FXGLOWS", true )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS", true )
	ObjectHideSubObjectPermanently( self, "MESH01", true )
	ObjectHideSubObjectPermanently( self, "POWERPLANTGLOWS", true )
	ObjectHideSubObjectPermanently( self, "LIGHTL", true )
	ObjectHideSubObjectPermanently( self, "LIGHTR", true )
	ObjectHideSubObjectPermanently( self, "LIGHTS1", true )
	ObjectHideSubObjectPermanently( self, "NBCHEMICALPTE1", true )
	ObjectHideSubObjectPermanently( self, "LINKS", true )
	ObjectHideSubObjectPermanently( self, "MESH28", true )
	ObjectHideSubObjectPermanently( self, "TURBINEGLOWS", true )
	ObjectHideSubObjectPermanently( self, "GLOWS", true )
end

function onBuildingPowerRestored(self)
	ObjectHideSubObjectPermanently( self, "LIGHTS", false )
	ObjectHideSubObjectPermanently( self, "FXLIGHTS05", false )
	ObjectHideSubObjectPermanently( self, "FXLIGHTS", false )
	ObjectHideSubObjectPermanently( self, "FXGLOWS", false )
	ObjectHideSubObjectPermanently( self, "FLASHINGLIGHTS", false )
	ObjectHideSubObjectPermanently( self, "MESH01", false )
	ObjectHideSubObjectPermanently( self, "POWERPLANTGLOWS", false )
	ObjectHideSubObjectPermanently( self, "LIGHTL", false )
	ObjectHideSubObjectPermanently( self, "LIGHTR", false )
	ObjectHideSubObjectPermanently( self, "LIGHTS1", false )
	ObjectHideSubObjectPermanently( self, "NBCHEMICALPTE1", false )
	ObjectHideSubObjectPermanently( self, "LINKS", false )
	ObjectHideSubObjectPermanently( self, "MESH28", false )
	ObjectHideSubObjectPermanently( self, "TURBINEGLOWS", false )
	ObjectHideSubObjectPermanently( self, "GLOWS", false )
end

function OnNeutralGarrisonableBuildingGenericEvent(self,data)
end

function onCreatedGDIOrcaAirstrike(self)
	ObjectForbidPlayerCommands( self, true )
end

function onCreatedAlienMCVUnpacking(self)
	ObjectForbidPlayerCommands( self, true )
end

function GoIntoRampage(self)
	ObjectEnterRampageState(self)
		
	--Broadcast fear to surrounding unit(if we actually rampaged)
	if ObjectTestModelCondition(self, "WEAPONSET_RAMPAGE") then
		ObjectBroadcastEventToUnits(self, "BeAfraidOfRampage", 250)
	end
end

function MakeMeAlert(self)
	ObjectEnterAlertState(self)
end

function BecomeUncontrollablyAfraid(self, other)
	if not ObjectTestCanSufferFear(self) then
		return
	end

	ObjectEnterUncontrollableCowerState(self, other)
end

function BecomeAfraidOfRampage(self, other)
	if not ObjectTestCanSufferFear(self) then
		return
	end

	ObjectEnterCowerState(self, other)
end

function RadiateTerror(self, other)
	ObjectBroadcastEventToEnemies(self, "BeTerrified", 180)
end
	
function RadiateTerrorEx(self, other, terrorRange)
	ObjectBroadcastEventToEnemies(self, "BeTerrified", terrorRange)
end
	

function BecomeTerrified(self, other)
	ObjectEnterRunAwayPanicState(self, other)
end

function BecomeAfraidOfGateDamaged(self, other)
	if not ObjectTestCanSufferFear(self) then
		return
	end

	ObjectEnterCowerState(self,other)
end


function ChantForUnit(self) -- Used by units to broadcast the chant event to their own side.
	ObjectBroadcastEventToAllies(self, "BeginChanting", 9999)
end

function StopChantForUnit(self) -- Used by units to stop the chant event to their own side.
	ObjectBroadcastEventToAllies(self, "StopChanting", 9999)
end

function SpyMoving(self, other)
	print(ObjectDescription(self).." spying movement of "..ObjectDescription(other));
end

function OnGarrisonableCreated(self)
	ObjectHideSubObjectPermanently( self, "GARRISON01", true )
	ObjectHideSubObjectPermanently( self, "GARRISON02", true )
end

function OnRubbleDropshipCreated(self)
	ObjectHideSubObjectPermanently( self, "Loadref", true )
end

-- XPACK LUA FUNCTION DEFINITIONS

function OnTitanCreated(self)
	ObjectHideSubObjectPermanently( self, "UGRail_01", true )
	ObjectHideSubObjectPermanently( self, "UGRail_Barrel", true )
	ObjectHideSubObjectPermanently( self, "MUZZLEFLASH_01", true )
	ObjectHideSubObjectPermanently( self, "UGRAILACCELERATOR_01", true )
	ObjectHideSubObjectPermanently( self, "UGRAILACCELERATOR_BARREL", true )
end

-- ################ NEW FUNCTION FOR 1.03 RGA #######################
function OnTitanCreated_103(self)
	ObjectHideSubObjectPermanently( self, "UGRail_01", true )
	ObjectHideSubObjectPermanently( self, "UGRail_Barrel", true )
	ObjectHideSubObjectPermanently( self, "MUZZLEFLASH_01", true )
--	ObjectHideSubObjectPermanently( self, "UGRAILACCELERATOR_01", true )
--	ObjectHideSubObjectPermanently( self, "UGRAILACCELERATOR_BARREL", true )
end
-- ###################################################################

function OnAlienHexapodCreated(self)
	ObjectHideSubObjectPermanently( self, "AUTELEPORT_LR", true )
	ObjectHideSubObjectPermanently( self, "AUTELEPORT_LM", true )
	ObjectHideSubObjectPermanently( self, "AUTELEPORT_LF", true )	

	ObjectHideSubObjectPermanently( self, "AUSHOCKBASE_LR", true )
	ObjectHideSubObjectPermanently( self, "AUSHOCKBASE_LM", true )
	ObjectHideSubObjectPermanently( self, "AUSHOCKBASE_LF", true )
	ObjectHideSubObjectPermanently( self, "AUSHOCKTURRET_LR", true )
	ObjectHideSubObjectPermanently( self, "AUSHOCKTURRET_LM", true )
	ObjectHideSubObjectPermanently( self, "AUSHOCKTURRET_LF", true )

	ObjectHideSubObjectPermanently( self, "AUSTALKBASE_LR", true )
	ObjectHideSubObjectPermanently( self, "AUSTALKBASE_LM", true )
	ObjectHideSubObjectPermanently( self, "AUSTALKBASE_LF", true )
	ObjectHideSubObjectPermanently( self, "AUSTALKTURRET_LR", true )
	ObjectHideSubObjectPermanently( self, "AUSTALKTURRET_LM", true )
	ObjectHideSubObjectPermanently( self, "AUSTALKTURRET_LF", true )	

	ObjectHideSubObjectPermanently( self, "AUPLASMABASE_LR", true )
	ObjectHideSubObjectPermanently( self, "AUPLASMABASE_LM", true )
	ObjectHideSubObjectPermanently( self, "AUPLASMABASE_LF", true )	
	ObjectHideSubObjectPermanently( self, "AUPLASMAGUN_LR", true )
	ObjectHideSubObjectPermanently( self, "AUPLASMAGUN_LM", true )
	ObjectHideSubObjectPermanently( self, "AUPLASMAGUN_LF", true )	
	
	ObjectHideSubObjectPermanently( self, "AUHEALTHBASE_LR", true )
	ObjectHideSubObjectPermanently( self, "AUHEALTHBASE_LM", true )
	ObjectHideSubObjectPermanently( self, "AUHEALTHBASE_LF", true )	
	ObjectHideSubObjectPermanently( self, "AUHEALTHTURRET_LR", true )
	ObjectHideSubObjectPermanently( self, "AUHEALTHTURRET_LM", true )
	ObjectHideSubObjectPermanently( self, "AUHEALTHTURRET_LF", true )	
	ObjectHideSubObjectPermanently( self, "FX_HEALTHRINGS_LR", true )
	ObjectHideSubObjectPermanently( self, "FX_HEALTHRINGS_LM", true )
	ObjectHideSubObjectPermanently( self, "FX_HEALTHRINGS_LF", true )	

	ObjectHideSubObjectPermanently( self, "AUTELEPORT_RR", true )
	ObjectHideSubObjectPermanently( self, "AUTELEPORT_RM", true )
	ObjectHideSubObjectPermanently( self, "AUTELEPORT_RF", true )	

	ObjectHideSubObjectPermanently( self, "AUSHOCKBASE_RR", true )
	ObjectHideSubObjectPermanently( self, "AUSHOCKBASE_RM", true )
	ObjectHideSubObjectPermanently( self, "AUSHOCKBASE_RF", true )
	ObjectHideSubObjectPermanently( self, "AUSHOCKTURRET_RR", true )
	ObjectHideSubObjectPermanently( self, "AUSHOCKTURRET_RM", true )
	ObjectHideSubObjectPermanently( self, "AUSHOCKTURRET_RF", true )
	
	ObjectHideSubObjectPermanently( self, "AUSTALKBASE_RR", true )
	ObjectHideSubObjectPermanently( self, "AUSTALKBASE_RM", true )
	ObjectHideSubObjectPermanently( self, "AUSTALKBASE_RF", true )
	ObjectHideSubObjectPermanently( self, "AUSTALKTURRET_RR", true )
	ObjectHideSubObjectPermanently( self, "AUSTALKTURRET_RM", true )
	ObjectHideSubObjectPermanently( self, "AUSTALKTURRET_RF", true )	

	ObjectHideSubObjectPermanently( self, "AUPLASMABASE_RR", true )
	ObjectHideSubObjectPermanently( self, "AUPLASMABASE_RM", true )
	ObjectHideSubObjectPermanently( self, "AUPLASMABASE_RF", true )	
	ObjectHideSubObjectPermanently( self, "AUPLASMAGUN_RR", true )
	ObjectHideSubObjectPermanently( self, "AUPLASMAGUN_RM", true )
	ObjectHideSubObjectPermanently( self, "AUPLASMAGUN_RF", true )	
	
	ObjectHideSubObjectPermanently( self, "AUHEALTHBASE_RR", true )
	ObjectHideSubObjectPermanently( self, "AUHEALTHBASE_RM", true )
	ObjectHideSubObjectPermanently( self, "AUHEALTHBASE_RF", true )	
	ObjectHideSubObjectPermanently( self, "AUHEALTHTURRET_RR", true )
	ObjectHideSubObjectPermanently( self, "AUHEALTHTURRET_RM", true )
	ObjectHideSubObjectPermanently( self, "AUHEALTHTURRET_RF", true )	
	ObjectHideSubObjectPermanently( self, "FX_HEALTHRINGS_RR", true )
	ObjectHideSubObjectPermanently( self, "FX_HEALTHRINGS_RM", true )
	ObjectHideSubObjectPermanently( self, "FX_HEALTHRINGS_RF", true )	
end

function OnGDIMARVCreated(self)
	ObjectHideSubObjectPermanently( self, "GN_Base_TreadLR", true )
	ObjectHideSubObjectPermanently( self, "GN_Base_TreadLF", true )
	ObjectHideSubObjectPermanently( self, "GN_Base_TreadRR", true )	
	ObjectHideSubObjectPermanently( self, "GN_Base_TreadRF", true )	
	ObjectHideSubObjectPermanently( self, "GN_Turret_TreadLR", true )	
	ObjectHideSubObjectPermanently( self, "GN_Turret_TreadLF", true )	
	ObjectHideSubObjectPermanently( self, "GN_Turret_TreadRR", true )	
	ObjectHideSubObjectPermanently( self, "GN_Turret_TreadRF", true )	
	
	ObjectHideSubObjectPermanently( self, "EN_Base_TreadLR", true )
	ObjectHideSubObjectPermanently( self, "EN_Base_TreadLF", true )
	ObjectHideSubObjectPermanently( self, "EN_Base_TreadRR", true )	
	ObjectHideSubObjectPermanently( self, "EN_Base_TreadRF", true )	
	ObjectHideSubObjectPermanently( self, "EN_Turret_TreadLR", true )	
	ObjectHideSubObjectPermanently( self, "EN_Turret_TreadLF", true )	
	ObjectHideSubObjectPermanently( self, "EN_Turret_TreadRR", true )	
	ObjectHideSubObjectPermanently( self, "EN_Turret_TreadRF", true )	
	
	ObjectHideSubObjectPermanently( self, "ZT_Base_TreadLR", true )
	ObjectHideSubObjectPermanently( self, "ZT_Base_TreadLF", true )
	ObjectHideSubObjectPermanently( self, "ZT_Base_TreadRR", true )	
	ObjectHideSubObjectPermanently( self, "ZT_Base_TreadRF", true )	
	ObjectHideSubObjectPermanently( self, "ZT_Turret_TreadLR", true )	
	ObjectHideSubObjectPermanently( self, "ZT_Turret_TreadLF", true )	
	ObjectHideSubObjectPermanently( self, "ZT_TURRETRR", true )	
	ObjectHideSubObjectPermanently( self, "ZT_Turret_TreadRF", true )	
	
	ObjectHideSubObjectPermanently( self, "MS_Base_TreadLR", true )
	ObjectHideSubObjectPermanently( self, "MS_Base_TreadLF", true )
	ObjectHideSubObjectPermanently( self, "MS_Base_TreadRR", true )	
	ObjectHideSubObjectPermanently( self, "MS_Base_TreadRF", true )	
	ObjectHideSubObjectPermanently( self, "MS_Turret_TreadLR", true )	
	ObjectHideSubObjectPermanently( self, "MS_Turret_TreadLF", true )	
	ObjectHideSubObjectPermanently( self, "MS_Turret_TreadRR", true )	
	ObjectHideSubObjectPermanently( self, "MS_Turret_TreadRF", true )	
	
	ObjectHideSubObjectPermanently( self, "RM_Base_TreadLR", true )
	ObjectHideSubObjectPermanently( self, "RM_Base_TreadLF", true )
	ObjectHideSubObjectPermanently( self, "RM_Base_TreadRR", true )	
	ObjectHideSubObjectPermanently( self, "RM_Base_TreadRF", true )	
	ObjectHideSubObjectPermanently( self, "RM_Turret_TreadLR", true )	
	ObjectHideSubObjectPermanently( self, "RM_Turret_TreadLF", true )	
	ObjectHideSubObjectPermanently( self, "RM_Turret_TreadRR", true )	
	ObjectHideSubObjectPermanently( self, "RM_Turret_TreadRF", true )
	
	ObjectHideSubObjectPermanently( self, "ST_Base_TreadLR", true )
	ObjectHideSubObjectPermanently( self, "ST_Base_TreadLF", true )
	ObjectHideSubObjectPermanently( self, "ST_Base_TreadRR", true )	
	ObjectHideSubObjectPermanently( self, "ST_Base_TreadRF", true )	
	ObjectHideSubObjectPermanently( self, "ST_Turret_TreadLR", true )	
	ObjectHideSubObjectPermanently( self, "ST_Turret_TreadLF", true )	
	ObjectHideSubObjectPermanently( self, "ST_Turret_TreadRR", true )	
	ObjectHideSubObjectPermanently( self, "ST_Turret_TreadRF", true )
	ObjectHideSubObjectPermanently( self, "ST_LASERLR", true )	
	ObjectHideSubObjectPermanently( self, "ST_LASERLF", true )		
	ObjectHideSubObjectPermanently( self, "ST_LASERRR", true )		
	ObjectHideSubObjectPermanently( self, "ST_LASERRF", true )		
	
end

function OnNODMetaUnitCreated(self)
	ObjectHideSubObjectPermanently( self, "B_FTR", true )
	ObjectHideSubObjectPermanently( self, "FTR", true )
	ObjectHideSubObjectPermanently( self, "FX_FTpilotflameR", true )
	ObjectHideSubObjectPermanently( self, "B_FTL", true )
	ObjectHideSubObjectPermanently( self, "FTL", true )	
	ObjectHideSubObjectPermanently( self, "FX_FTpilotflameL", true )	
	ObjectHideSubObjectPermanently( self, "HvyMGL", true )
	ObjectHideSubObjectPermanently( self, "HvyMGBarrelL", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_01", true )	
	ObjectHideSubObjectPermanently( self, "HvyMGR", true )
	ObjectHideSubObjectPermanently( self, "HvyMGBarrelR", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_02", true )	
	ObjectHideSubObjectPermanently( self, "RocketPodL", true )
	ObjectHideSubObjectPermanently( self, "RocketPodR", true )	
	ObjectHideSubObjectPermanently( self, "ModuleR", true )
	ObjectHideSubObjectPermanently( self, "ModuleBeacontR", true )
	ObjectHideSubObjectPermanently( self, "ModuleLightR", true )	
	ObjectHideSubObjectPermanently( self, "ModuleL", true )	
	ObjectHideSubObjectPermanently( self, "ModuleBeaconL", true )
	ObjectHideSubObjectPermanently( self, "ModuleLightL", true )	
end


function OnWolverineCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_Weapon01", true )
	ObjectHideSubObjectPermanently( self, "UG_Weapon02", true )
	ObjectHideSubObjectPermanently( self, "UG_Ammo", true )
end

function OnStalkerCreated(self)
	ObjectHideSubObjectPermanently( self, "AUStalker_C_B", true )
	ObjectHideSubObjectPermanently( self, "AUStalker_Gun", true )
end

function OnGunshipCreated(self)
	ObjectHideSubObjectPermanently( self, "FXWEAPON01", true )
	ObjectHideSubObjectPermanently( self, "FXWEAPON02", true )
	ObjectHideSubObjectPermanently( self, "FXWEAPON03", true )
	ObjectHideSubObjectPermanently( self, "FXWEAPON04", true )
end


function OnAAScoutCreated(self)
	ObjectHideSubObjectPermanently( self, "FXMUZZLEFLASH01", true )
	ObjectHideSubObjectPermanently( self, "FXMUZZLEFLASH02", true )
	ObjectHideSubObjectPermanently( self, "FXMUZZLEFLASH03", true )
	ObjectHideSubObjectPermanently( self, "FXMUZZLEFLASH04", true )
end

function OnMobileArtilleryCreated(self)
	ObjectHideSubObjectPermanently( self, "MUZZLEFLASH_01", true )
	--ObjectHideSubObjectPermanently( self, "TREDS", true )
end

function OnAABatteryCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_TUNGSTENBASE", true )
	ObjectHideSubObjectPermanently( self, "UG_TUNGSTENAMMO", true )
	ObjectHideSubObjectPermanently( self, "UG_TUNGSTENGUN", true )
	ObjectHideSubObjectPermanently( self, "UGTAmNewSkin", true )
	ObjectHideSubObjectPermanently( self, "UGTungNewSkin", true )
end

function OnNODRocketBunkerSpawnCreated(self)
	ObjectHideSubObjectPermanently( self, "TIBCOREMISSILE", true )
	ObjectHideSubObjectPermanently( self, "HOSE", true )
end

function OnCombatEngineerCreated(self)
	ObjectHideSubObjectPermanently( self, "MUZZLEFLASH", true )
	ObjectHideSubObjectPermanently( self, "LASER", true )
end

function OnZOCOMOrcaCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_PROBE", true )
	ObjectHideSubObjectPermanently( self, "UG_HARDPOINTS", true )
	ObjectHideSubObjectPermanently( self, "MISSILE01", true )
	--ObjectHideSubObjectPermanently( self, "UG_EC", true )
end

function OnGDIAPCCreated(self)
	ObjectHideSubObjectPermanently( self, "APC_UGAB", true )
	ObjectHideSubObjectPermanently( self, "APC_UGTURRET", true )
	ObjectHideSubObjectPermanently( self, "TURRET_PITCH", false )
end

function OnReaperTripodCreated(self)
	ObjectHideSubObjectPermanently( self, "AU_RPRTRIPOD_UPGR01", true )
end

function OnReaper17DevourerCreated(self)
	ObjectHideSubObjectPermanently( self, "AU_DEVOURER_UPGR01", true )
end

-- ############ NEW FUNCTIONS 1.03 FOR TIB SCAN ###########
function OnTibChargeNoAttack_103(self)
	ObjectGrantUpgrade(self, "Upgrade_NoAttack")	
end

function OnTibChargeNoAttackEnd_103(self)
	ObjectRemoveUpgrade(self, "Upgrade_NoAttack")	
end
-- ########################################################

function OnReaper17DevourerCreated(self)
	ObjectHideSubObjectPermanently( self, "AU_DEVOURER_UPGR01", true )
end

function OnAlienMotherShipCreated(self)
	ObjectSetObjectStatus( self, "AIRBORNE_TARGET" )
end

function OnBlackHandCustomWarmechCreated(self)
	ObjectHideSubObjectPermanently( self, "NUBEAM", true )
	ObjectHideSubObjectPermanently( self, "S_DETECTOR", true )
	ObjectHideSubObjectPermanently( self, "S_GENERATOR", true )
end


function OnAlienMechapedeCreated(self)
	ObjectHideSubObjectPermanently( self, "TIBERIUM_SPRAY_MODULE", true )
	ObjectHideSubObjectPermanently( self, "SHARD_MODULE", true )
	ObjectHideSubObjectPermanently( self, "PLASMA_DISC_MODULE", true )
	ObjectHideSubObjectPermanently( self, "DISINTEGRATOR_MODULE", true )	
end

-- ############ NEW FUNCTIONS 1.03 FOR TIB SCAN ###########
function OnTibScanCreated_103(self)
	ObjectDoSpecialPower(self, "SpecialPower_TiberiumVibrationScanDummy")	
end

-- ###########################################################

function OnAlienPACCreated(self)
	ObjectHideSubObjectPermanently( self, "TravEng01", true )
	ObjectHideSubObjectPermanently( self, "TravEng02", true )
end

function OnAlienDevastatorCreated(self)
	ObjectHideSubObjectPermanently( self, "TravEng01", true )
	ObjectHideSubObjectPermanently( self, "TravEng02", true )
end

function OnGDIGrenadeSoldierCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_STRAPS", true )
	ObjectHideSubObjectPermanently( self, "UG_GRENADEEMP_PROJECTILE", true )
end

-- ############ NEW FUNCTIONS 1.03 FOR BATTLEBASE ###########
function OnGDIBattleBaseCreated_103(self)
	ObjectHideSubObjectPermanently( self, "UGRAILMAIN", true )
	ObjectHideSubObjectPermanently( self, "UGRAILMAINR", true )
	ObjectHideSubObjectPermanently( self, "UG_RAILBARREL1", true )
	ObjectHideSubObjectPermanently( self, "UG_RAILBARREL1R", true )
end
-- ##########################################################################

function OnGDIGuardianCannonCreated(self)
	ObjectHideSubObjectPermanently( self, "UGRAILMAIN", true )
	ObjectHideSubObjectPermanently( self, "UG_RAILBARREL2", true )
	ObjectHideSubObjectPermanently( self, "UG_RAILBARREL1", true )
end

function OnAlienPhotonCannonCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_SHARD", true )
	ObjectHideSubObjectPermanently( self, "UG_SHARDWEAPON", true )
end

function OnAlienPMBatteryCreated(self)
	ObjectHideSubObjectPermanently( self, "UG_SHARD", true )
	ObjectHideSubObjectPermanently( self, "UG_SHARDWEAPON", true )
end

function OnNODShadowSquadBeaconCreated(self)
	ObjectSetObjectStatus( self, "CAN_SPOT_FOR_BOMBARD" )
end

function OnAlienSeekerTankCreated(self)
	ObjectHideSubObjectPermanently( self, "AUSHARDWEAPON_C_G", true )
	ObjectHideSubObjectPermanently( self, "UG_SHARDWEAPON", true )
end


--function OnImprovedCyborgCreated(self)
--	ObjectHideSubObjectPermanently( self, "WEAPON_PARTICLEBM_UPGRADED", true )
--end

function OnBunkerTruckCreated(self)
	ObjectHideSubObjectPermanently( self, "DOZERBLADE", true )
end

function OnCyborgCreated(self)
	ObjectHideSubObjectPermanently( self, "WEAPON_PARTICLEBM", true )
end

-- ############ NEW FUNCTIONS 1.03 FOR EMP/CONFESSOR GRENADE ###########
-- For BH Concabs
function OnConfessorSquadCreated_103(self)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "SpecialPower_BlackHandConfessorCabalGetToGrenadeRange", 1.5);
end

function OnConfessorCreated_103(self)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "SpecialPower_BlackHandConfessorCabalFireGrenade", 1.5);
end
-- For Awakened/SilentOnes
function OnCyborgCreated_103(self)
	ObjectHideSubObjectPermanently( self, "WEAPON_PARTICLEBM", true )
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "EMPBlast", 1.5);
end

function OnCyborgSquadCreated_103(self)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "EMPBlastGetInRange", 1.5);
end
-- For Enlightened
function OnImprovedCyborgCreated_103(self)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "EMPBlast", 1.5);
end

function OnImprovedCyborgSquadCreated_103(self)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "ImprovedEMPBlastGetInRange", 1.5);
end
-- ##########################################################################


-- ############# NEW FUNCTIONS FOR 1.03 FREE SQUADS FIX ####################

-- How many frames (minimum) it takes for each squad to exit rax (No. members * rax exit delay)
function SquadLookupTable(x)  -- x = object template
	
	local delay1 = 1 -- gdi rax delay
	local delay2 = 1 -- nod rax delay
	local delay3 = 5 -- scrin rax delay
	
	-- Disints
	if strfind(tostring(x), "2B9428D0") ~= nil or strfind(tostring(x), "240FB1") ~= nil then
		ans = 5*delay3
	-- Shocks
	elseif strfind(tostring(x), "4803957E") ~= nil or strfind(tostring(x), "6495F509") ~= nil or strfind(tostring(x), "40241AC3") ~= nil then
		ans = 3*delay3
	-- Ravs
	elseif strfind(tostring(x), "32EA13B3") ~= nil or strfind(tostring(x), "7F2D0EF5") ~= nil or strfind(tostring(x), "72A9F5D5") ~= nil then
		ans = 3*delay3
	-- Cults
	elseif strfind(tostring(x), "C46CECA2") ~= nil then
		ans = 5*delay3
	-- Rifles
	elseif strfind(tostring(x), "9096966E") ~= nil or strfind(tostring(x), "AC645E3") ~= nil or strfind(tostring(x), "CF35F1B4") ~= nil then
		ans = 6*delay1
	-- Missiles
	elseif strfind(tostring(x), "EF1252DB") ~= nil or strfind(tostring(x), "EA23C76F") ~= nil or strfind(tostring(x), "17A153BA") ~= nil then
		ans = 2*delay1
	-- Grenades
	elseif strfind(tostring(x), "42896060") ~= nil or strfind(tostring(x), "C43CF79F") ~= nil or strfind(tostring(x), "FC6A915") ~= nil then
		ans = 4*delay1
	-- Zones
	elseif strfind(tostring(x), "5D5E5931") ~= nil or strfind(tostring(x), "D213112") ~= nil or strfind(tostring(x), "7E8CB87C") ~= nil then
		ans = 4*delay1
	-- Militants
	elseif strfind(tostring(x), "BC36257A") ~= nil then
		ans = 9*delay2
	-- Rockets
	elseif strfind(tostring(x), "89C45844") ~= nil or strfind(tostring(x), "20126F6") ~= nil or strfind(tostring(x), "C3011861") ~= nil then
		ans = 2*delay2
	-- Shadows
	elseif strfind(tostring(x), "A6E10008") ~= nil or strfind(tostring(x), "6AEA240A") ~= nil then
		ans = 4*delay2
	-- Blackhands/Tibtrooper
	elseif strfind(tostring(x), "5F44F92F") ~= nil or strfind(tostring(x), "128ABF1") ~= nil or strfind(tostring(x), "E6E24EF7") ~= nil then
		ans = 6*delay2
	-- Fanatics
	elseif strfind(tostring(x), "BE7C389D") ~= nil or strfind(tostring(x), "8E0F9C9") ~= nil or strfind(tostring(x), "6093B1BE") ~= nil then
		ans = 5*delay2
	-- Enlightened/Awakened
	elseif strfind(tostring(x), "D5BE6F6C") ~= nil or strfind(tostring(x), "B27DDF67") ~= nil then
		ans = 3*delay2
	-- Concabs
	elseif strfind(tostring(x), "FDEF5E7") ~= nil then
		ans = 6*delay2		
	end
	
	return ans
	
end

-- When squad appears at rax
function OnSquadExitRax_103(self)	

	-- Get current frame and object desc
	local c = GetFrame()
	local a = ObjectDescription(self)
	
	--local s = "Unit leaving factory: " .. a
	--ExecuteAction("SHOW_MILITARY_CAPTION", s, 2)		
	
	-- Save current frame and object into table
	squadtable[a] = c
	
end

-- When squad finishes leaving rax
function OnSquadExitRax1_103(self)

	-- Get current frame and object desc
	local c = GetFrame()
	local a = ObjectDescription(self)

	if squadtable[a] ~= nil then
		
		-- Subtract current frame from saved frame in table to get time difference
		local diff = c - squadtable[a]
		
		--local s = "Factory exit time: " .. tostring(diff) .. ", Expected exit time: " .. tostring(SquadLookupTable(ObjectTemplateName(self)))
		--ExecuteAction("SHOW_MILITARY_CAPTION", s, 2)	

		-- If diff is less than time taken for full squad to exit, kill the squad
		if diff < SquadLookupTable(ObjectTemplateName(self)) then
			ExecuteAction("NAMED_DELETE", self);	
			
			--local s = "Unit destroyed to prevent exploit: " .. tostring(a)
			--ExecuteAction("SHOW_MILITARY_CAPTION", s, 2)				
		end

		-- To ensure this routine is never re-run (eg when garrisoning)
		squadtable[a] = nil
	end
	
end

function OnSquadDestroyed_103(self)
	local a = ObjectDescription(self)

	-- To ensure this routine is never re-run (eg when garrisoning)
	squadtable[a] = nil

end


-- How many frames (minimum) it takes for each squad to exit rax (No. members * rax exit delay)
function SquadLookupTable_R24(x)  -- x = object template
	
	local delay1 = 1 -- gdi rax delay
	local delay2 = 1 -- nod rax delay
	local delay3 = 5 -- scrin rax delay
	local ans = 0
	
	-- Disints
	if strfind(tostring(x), "2B9428D0") ~= nil or strfind(tostring(x), "240FB1") ~= nil then
		ans = 5*delay3
	-- Shocks
	elseif strfind(tostring(x), "4803957E") ~= nil or strfind(tostring(x), "6495F509") ~= nil or strfind(tostring(x), "40241AC3") ~= nil then
		ans = 3*delay3
	-- Ravs
	elseif strfind(tostring(x), "32EA13B3") ~= nil or strfind(tostring(x), "7F2D0EF5") ~= nil or strfind(tostring(x), "72A9F5D5") ~= nil then
		ans = 3*delay3
	-- Cults
	elseif strfind(tostring(x), "C46CECA2") ~= nil then
		ans = 5*delay3
	-- Rifles
	elseif strfind(tostring(x), "9096966E") ~= nil or strfind(tostring(x), "AC645E3") ~= nil or strfind(tostring(x), "CF35F1B4") ~= nil then
		ans = 6*delay1
	-- Missiles
	elseif strfind(tostring(x), "EF1252DB") ~= nil or strfind(tostring(x), "EA23C76F") ~= nil or strfind(tostring(x), "17A153BA") ~= nil then
		ans = 2*delay1
	-- Grenades
	elseif strfind(tostring(x), "42896060") ~= nil or strfind(tostring(x), "C43CF79F") ~= nil or strfind(tostring(x), "FC6A915") ~= nil then
		ans = 4*delay1
	-- Zones
	elseif strfind(tostring(x), "5D5E5931") ~= nil or strfind(tostring(x), "D213112") ~= nil or strfind(tostring(x), "7E8CB87C") ~= nil then
		ans = 4*delay1
	-- Militants
	elseif strfind(tostring(x), "BC36257A") ~= nil then
		ans = 9*delay2
	-- Rockets
	elseif strfind(tostring(x), "89C45844") ~= nil or strfind(tostring(x), "20126F6") ~= nil or strfind(tostring(x), "C3011861") ~= nil then
		ans = 2*delay2
	-- Shadows
	elseif strfind(tostring(x), "A6E10008") ~= nil or strfind(tostring(x), "6AEA240A") ~= nil then
		ans = 4*delay2
	-- Blackhands/Tibtrooper
	elseif strfind(tostring(x), "5F44F92F") ~= nil or strfind(tostring(x), "128ABF1") ~= nil or strfind(tostring(x), "E6E24EF7") ~= nil then
		ans = 6*delay2
	-- Fanatics
	elseif strfind(tostring(x), "BE7C389D") ~= nil or strfind(tostring(x), "8E0F9C9") ~= nil or strfind(tostring(x), "6093B1BE") ~= nil then
		ans = 5*delay2
	-- Enlightened/Awakened
	elseif strfind(tostring(x), "D5BE6F6C") ~= nil or strfind(tostring(x), "B27DDF67") ~= nil then
		ans = 3*delay2
	-- Concabs
	elseif strfind(tostring(x), "FDEF5E7") ~= nil then
		ans = 6*delay2		
	else 
		return nil
	end
	
	return ans
	
end

-- When squad appears at rax
function OnSquadExitRax_R24(self)	

	-- Get current frame and object desc
	local c = GetFrame()
	local a = ObjectDescription(self)
	
	--local s = "Unit leaving factory: " .. a
	--ExecuteAction("SHOW_MILITARY_CAPTION", s, 2)		
	
	-- Save current frame and object into table
	squadtable[a] = c
	
end

-- When squad finishes leaving rax
function OnSquadExitRax1_R24(self)

	-- Get current frame and object desc
	local c = GetFrame()
	local a = ObjectDescription(self)

	if squadtable[a] ~= nil then
		
		-- Subtract current frame from saved frame in table to get time difference
		local diff = c - squadtable[a]
		local squadLookUp = SquadLookupTable_R24(ObjectTemplateName(self))	
		--local s = "Factory exit time: " .. tostring(diff) .. ", Expected exit time: " .. tostring(squadLookUp)
		--ExecuteAction("SHOW_MILITARY_CAPTION", s, 2)	

		-- If diff is less than time taken for full squad to exit, kill the squad
		if squadLookUp ~= nil then
			if diff < squadLookUp then
				ExecuteAction("NAMED_DELETE", self);		
				--local s = "Unit destroyed to prevent exploit: " .. tostring(a)
				--ExecuteAction("SHOW_MILITARY_CAPTION", s, 2)				
			end
		end

		-- To ensure this routine is never re-run (eg when garrisoning)
		squadtable[a] = nil
	end
	
end

function OnSquadDestroyed_R24(self)
	local a = ObjectDescription(self)

	-- To ensure this routine is never re-run (eg when garrisoning)
	squadtable[a] = nil

end


-- ############################# MOBA FUNCTIONS ###################################

-- Randomly selects a hero to build
function PickRandHero_renwars(self)

	--local c = clock()
	--randomseed(c*p)
	--local a = GetRandomNumber()

	local a = GetRandomNumber()
	local n = 1/8 -- 1 divided by no. heroes
	
	if a <= n then
		ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY",self,"Command_ConstructGDICommandoHero")
	elseif a <= n*2 then
		ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY",self,"Command_ConstructNODCommandoHero")
	elseif a <= n*3 then
		ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY",self,"Command_ConstructSteelTalonsCombatEngineerHero")
	elseif a <= n*4 then
		ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY",self,"Command_ConstructNODBlackhandHero")
	elseif a <= n*5 then
		ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY",self,"Command_ConstructGDISniperHero")		
	elseif a <= n*6 then
		ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY",self,"Command_ConstructZOCOMZoneraiderHero")		
	elseif a <= n*7 then
		ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY",self,"Command_ConstructNODShadowHero")				
	else
		ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY",self,"Command_ConstructNODFanaticHero")
	end

end

function OnRandHero_renwars(self)
	-- if gdisurveyor (the 4th player selector), check if we have the init upgrade before we can use this randomizer
	if strfind(tostring(ObjectDescription(self)), "921C06CC") ~= nil then
		if ObjectTestModelCondition(self, "USER_5") then
			PickRandHero_renwars(self)
		end
	else
		PickRandHero_renwars(self)
	end		
end

function OnExtraSelectorUpgraded_renwars(self)
	local s = getPlayerName(self) -- Player full name
	
	ExecuteAction("DISPLAY_TEXT", "\t \t \t \t \t \t \t ************* PLayer " .. s .. " is now a HERO PLAYER! *************") 		
end

-- ================ QUERY FUNCTION =================

function OnHeroQuery1_renwars(self)
	local p = getPlayerId(self)
	
	local c = 0
	if mobatest[p] ~= nil then
		c = mobatest[p]
	end
		
	local c1 = tostring(c)
	
	ExecuteAction("DISPLAY_TEXT", "kills... " .. c1 )
end

function OnHeroQuery_renwars(self)
		
	if mobaquerycount < 6 then
		mobaquerycount = mobaquerycount + 1		

		local p = getPlayerName(self) -- Player name
		local p1 = getPlayerId(self) -- Player id
		
		local n = 0 -- upgrade count		

		local u = {} -- upgrades string lines
		u[0] = ""
		u[1] = ""
		u[2] = ""
		u[3] = ""
		u[4] = ""
		u[5] = ""
		
		local l = 1 -- level
		local h = "Stormhammer" -- hero type
		local c = 0 -- networth	
		local m = "> 5%" -- energy

		-- HERO TYPE
		if ObjectHasUpgrade(self, "Upgrade_GDISniperSelected") == 1 then
			h = "Sharpshooter"
		elseif ObjectHasUpgrade(self, "Upgrade_SteelTalonsCombatEngineerSelected") == 1 then
			h = "Patch"
		elseif ObjectHasUpgrade(self, "Upgrade_ZOCOMZoneraiderSelected") == 1 then
			h = "Zone Commander"
		elseif ObjectHasUpgrade(self, "Upgrade_GDIGrenadeSoldierSelected") == 1 then
			h = "Grenadier"				
		elseif ObjectHasUpgrade(self, "Upgrade_NODCommandoSelected") == 1 then
			h = "Red Widow"
		elseif ObjectHasUpgrade(self, "Upgrade_NODBlackhandSelected") == 1 then
			h = "Punisher"
		elseif ObjectHasUpgrade(self, "Upgrade_NODFanaticSelected") == 1 then
			h = "Fanatic Acolyte"
		elseif ObjectHasUpgrade(self, "Upgrade_NODShadowSelected") == 1 then
			h = "Silhouette Master"		
		elseif ObjectHasUpgrade(self, "Upgrade_MarkedOfKaneCommandoSelected") == 1 then
			h = "Sentinel"	
		elseif ObjectHasUpgrade(self, "Upgrade_T59ProdigySelected") == 1 then
			h = "Prodigy"				
		end
		
		-- LEVELS
		if ObjectHasUpgrade(self, "Upgrade_Hero_10") == 1 then		
			l = 10
		elseif ObjectHasUpgrade(self, "Upgrade_Hero_9") == 1 then
			l = 9
		elseif ObjectHasUpgrade(self, "Upgrade_Hero_8") == 1 then
			l = 8
		elseif ObjectHasUpgrade(self, "Upgrade_Hero_7") == 1 then
			l = 7
		elseif ObjectHasUpgrade(self, "Upgrade_Hero_6") == 1 then
			l = 6
		elseif ObjectHasUpgrade(self, "Upgrade_Hero_5") == 1 then
			l = 5
		elseif ObjectHasUpgrade(self, "Upgrade_Hero_4") == 1 then
			l = 4
		elseif ObjectHasUpgrade(self, "Upgrade_Hero_3") == 1 then
			l = 3
		elseif ObjectHasUpgrade(self, "Upgrade_Hero_2") == 1 then
			l = 2
		end
		
		p = p .. " [Level " .. l .. " " .. h .. "]"
		
		-- UPGRADES
		if mobaregenpods[p1] ~= nil and mobaregenpods[p1] > 0 then
		    local mobaregencount = mobaregenpods[p1]
			u[0] = u[0] .. "Regen Pods(" .. mobaregencount .. "), "
			n = n + 1
			c = c + 125 * mobaregencount -- must reflect cost		   
		end
		
		if mobaenergypods[p1] ~= nil and mobaenergypods[p1] > 0 then
		    local mobaenergycount = mobaenergypods[p1]
			u[0] = u[0] .. "Energy Pods(" .. mobaenergycount .. "), "
			n = n + 1
			c = c + 125 * mobaenergycount -- must reflect cost		   
		end		
		
		if ObjectHasUpgrade(self, "Upgrade_HeroUpgrade") == 1 then	
			u[0] = u[0] .. "Advanced Hero Upgrade, "
			n = n + 1
			c = c + 4000 -- must reflect cost
		end			
		
		if ObjectHasUpgrade(self, "Upgrade_Firepower2") == 1 then	
			u[0] = u[0] .. "Firepower 2, "	
			n = n + 2	
			c = c + 3000 -- must reflect cost		
		elseif ObjectHasUpgrade(self, "Upgrade_Firepower") == 1 then	
			u[0] = u[0] .. "Firepower 1, "
			n = n + 1
			c = c + 1500 -- must reflect cost		
		end

		if ObjectHasUpgrade(self, "Upgrade_CompArmor2") == 1 then	
			u[0] = u[0] .. "Composite Armor 2, "	
			n = n + 2		
			c = c + 2000 -- must reflect cost		
		elseif ObjectHasUpgrade(self, "Upgrade_CompArmor") == 1 then	
			u[0] = u[0] .. "Composite Armor 1, "
			n = n + 1
			c = c + 1000 -- must reflect cost		
		end		
		
		if ObjectHasUpgrade(self, "Upgrade_MarkedOfKaneCyberneticLegs2") == 1 then	
			u[0] = u[0] .. "Cybernetic Legs 2, "	
			n = n + 2
			c = c + 2000 -- must reflect cost		
		elseif ObjectHasUpgrade(self, "Upgrade_MarkedOfKaneCyberneticLegs") == 1 then	
			u[0] = u[0] .. "Cybernetic Legs 1, "
			n = n + 1	
			c = c + 1000 -- must reflect cost		
		end

		if ObjectHasUpgrade(self, "Upgrade_FuelCells2") == 1 then	
			u[0] = u[0] .. "Fuel Cells 2, "
			n = n + 2
			c = c + 2500 -- must reflect cost		
		elseif ObjectHasUpgrade(self, "Upgrade_FuelCells") == 1 then	
			u[0] = u[0] .. "Fuel Cells 1, "
			n = n + 1
			c = c + 1500 -- must reflect cost		
		end		
		
		if ObjectHasUpgrade(self, "Upgrade_RocketPods2") == 1 then	
			u[0] = u[0] .. "Rocket Pods 2, "	
			n = n + 2
			c = c + 2000 -- must reflect cost		
		elseif ObjectHasUpgrade(self, "Upgrade_RocketPods") == 1 then	
			u[0] = u[0] .. "Rocket Pods 1, "
			n = n + 1
			c = c + 500 -- must reflect cost		
		end

		if ObjectHasUpgrade(self, "Upgrade_ObeliskLaser2") == 1 then	
			u[0] = u[0] .. "Obelisk Laser 2, "	
			n = n + 2
			c = c + 3500 -- must reflect cost		
		elseif ObjectHasUpgrade(self, "Upgrade_ObeliskLaser") == 1 then	
			u[0] = u[0] .. "Obelisk Laser 1, "
			n = n + 1
			c = c + 2000 -- must reflect cost		
		end

		if ObjectHasUpgrade(self, "Upgrade_Microwave2") == 1 then	
			u[0] = u[0] .. "Microwave 2, "
			n = n + 1	
			c = c + 4500 -- must reflect cost		
		elseif ObjectHasUpgrade(self, "Upgrade_Microwave") == 1 then	
			u[0] = u[0] .. "Microwave 1, "	
			n = n + 1
			c = c + 2500 -- must reflect cost		
		end

		if ObjectHasUpgrade(self, "Upgrade_NodEMPBurst2") == 1 then	
			u[0] = u[0] .. "EMP Burst 2, "
			n = n + 1
			c = c + 3000 -- must reflect cost		
		elseif ObjectHasUpgrade(self, "Upgrade_NodEMPBurst") == 1 then	
			u[0] = u[0] .. "EMP Burst 1, "
			n = n + 1
			c = c + 1500 -- must reflect cost		
		end

		if ObjectHasUpgrade(self, "Upgrade_Powerpacks") == 1 then	
			u[0] = u[0] .. "Advanced Powerpacks, "	
			n = n + 1
			c = c + 2500 -- must reflect cost		
		end		
		
		if ObjectHasUpgrade(self, "Upgrade_ShockwaveCannon") == 1 then	
			u[0] = u[0] .. "Shockwave Cannon, "
			n = n + 1
			c = c + 1000 -- must reflect cost		
		end	
		
		if ObjectHasUpgrade(self, "Upgrade_DecoyArmy") == 1 then	
			u[0] = u[0] .. "Decoy Army, "	
			n = n + 1
			c = c + 1000 -- must reflect cost		
		end	

		if ObjectHasUpgrade(self, "Upgrade_RadarScan") == 1 then	
			u[0] = u[0] .. "Radar Scan, "
			n = n + 1
			c = c + 200 -- must reflect cost		
		end		

		if ObjectHasUpgrade(self, "Upgrade_HH") == 1 then	
			u[0] = u[0] .. "Summon Hammerhead, "
			n = n + 1
			c = c + 2000 -- must reflect cost		
		end		

		if ObjectHasUpgrade(self, "Upgrade_CFT") == 1 then	
			u[0] = u[0] .. "Call for Transport, "
			n = n + 1
			c = c + 500 -- must reflect cost		
		end		

		if ObjectHasUpgrade(self, "Upgrade_Mantis") == 1 then	
			u[0] = u[0] .. "Call Mantis, "
			n = n + 1
			c = c + 1000 -- must reflect cost		
		end		

		if ObjectHasUpgrade(self, "Upgrade_Flametank") == 1 then	
			u[0] = u[0] .. "Summon Flametank, "
			n = n + 1
			c = c + 2000 -- must reflect cost		
		end		

		if ObjectHasUpgrade(self, "Upgrade_Predator") == 1 then	
			u[0] = u[0] .. "Summon Predator, "
			n = n + 1
			c = c + 1500 -- must reflect cost		
		end		

		if ObjectHasUpgrade(self, "Upgrade_Devastator") == 1 then	
			u[0] = u[0] .. "Summon Devastator Warship, "
			n = n + 1
			c = c + 2500 -- must reflect cost		
		end				
		
		if ObjectHasUpgrade(self, "Upgrade_Cloak") == 1 then	
			u[0] = u[0] .. "Lazarus Cloak, "	
			n = n + 1
			c = c + 1500 -- must reflect cost		
		end		
			
		if ObjectHasUpgrade(self, "Upgrade_Blink") == 1 then	
			u[0] = u[0] .. "Blink, "
			n = n + 1
			c = c + 1500 -- must reflect cost		
		end	

		if ObjectHasUpgrade(self, "Upgrade_Lifesteal") == 1 then	
			u[0] = u[0] .. "Life Drain, "	
			n = n + 1
			c = c + 1500 -- must reflect cost		
		end		

		if ObjectHasUpgrade(self, "Upgrade_StasisShield") == 1 then	
			u[0] = u[0] .. "Stasis Shield, "
			n = n + 1
			c = c + 1500 -- must reflect cost		
		end	

		if ObjectHasUpgrade(self, "Upgrade_TemporalWormhole") == 1 then	
			u[0] = u[0] .. "Temporal Wormhole, "
			n = n + 1
			c = c + 2500 -- must reflect cost		
		end	
		
		if ObjectHasUpgrade(self, "Upgrade_IonStorm") == 1 then	
			u[0] = u[0] .. "Ion Storm, "	
			n = n + 1
			c = c + 2000 -- must reflect cost		
		end	
		
		if ObjectHasUpgrade(self, "Upgrade_Forcefield") == 1 then	
			u[0] = u[0] .. "Attenuated Forcefields, "
			n = n + 1
			c = c + 2000 -- must reflect cost		
		end			

		if ObjectHasUpgrade(self, "Upgrade_Dominator") == 1 then	
			u[0] = u[0] .. "Mind Dominator, "
			n = n + 1
			c = c + 2000 -- must reflect cost		
		end	

		if ObjectHasUpgrade(self, "Upgrade_AOEMC") == 1 then	
			u[0] = u[0] .. "AOE Mind Control, "
			n = n + 1
			c = c + 2000 -- must reflect cost		
		end		
			
		if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then	
			u[0] = u[0] .. "Fusion Core, "
			n = n + 1
			c = c + 2500 -- must reflect cost		
		end
		
		if ObjectHasUpgrade(self, "Upgrade_IonCannon") == 1 then	
			u[0] = u[0] .. "Ion Cannon, "
			n = n + 1
			c = c + 5000 -- must reflect cost		
		end	
		
		-- TEAM/KD
		local assists = mobaassists[p1] - mobakills[p1]
		p1 = "SIDE: " .. tostring(mobateam[p1]) .. ", KILLS: " .. tostring(mobakills[p1]) .. ", ASSISTS: " .. tostring(assists) .. ", DEATHS: " .. tostring(mobadeaths[p1])
		
		-- ENERGY
		if ObjectHasUpgrade(self, "Mana_35") == 1 then	
			m ="> 35%"
		elseif ObjectHasUpgrade(self, "Mana_30") == 1 then	
			m ="> 30%"
		elseif ObjectHasUpgrade(self, "Mana_25") == 1 then	
			m ="> 25%"
		elseif ObjectHasUpgrade(self, "Mana_20") == 1 then	
			m ="> 20%"
		elseif ObjectHasUpgrade(self, "Mana_15") == 1 then	
			m ="> 15%"
		elseif ObjectHasUpgrade(self, "Mana_10") == 1 then	
			m ="> 10%"		
		end		

		-- tabs for line splitting
		local t = "\t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t \t "
		if (mobaquerycount == 1 or mobaquerycount == 4) then
			t = t .. t -- as far right as possible
		--elseif (mobaquerycount == 2 or mobaquerycount == 5) then
			-- do nothing, stay middle
		elseif (mobaquerycount == 3 or mobaquerycount == 6) then
			t = "" -- as far left as possible
		end
		local tu = "\t \t \t \t" .. t
		
		-- need line splitting for DISPLAY_TEXT, upto 6 lines allowed
		if strlen(u[0]) > 375 then
			u[5] = strsub(u[0], 375)
			u[4] = strsub(u[0], 300, 374)
			u[3] = strsub(u[0], 225, 299)
			u[2] = strsub(u[0], 150, 224) 
			u[1]  = strsub(u[0], 75, 149)
			u[0] = strsub(u[0], 1, 74)
			p = t .. "Querying Player " .. tostring(p) .. "..." .. "\n" .. t .. tostring(p1) .. "\n" .. t .. "ENERGY: " .. tostring(m) .. "\n" .. t .. tostring(n) .. " UPGRADES: " .. "\n" .. tu .. tostring(u[0]) .. "\n" .. tu .. tostring(u[1]) .. "\n" .. tu .. tostring(u[2]) .. "\n" .. tu .. tostring(u[3]) .. "\n" .. tu .. tostring(u[4]) .. "\n" .. tu .. tostring(u[5])						
		elseif strlen(u[0]) > 300 then
			u[4] = strsub(u[0], 300)
			u[3] = strsub(u[0], 225, 299)
			u[2] = strsub(u[0], 150, 224) 
			u[1]  = strsub(u[0], 75, 149)
			u[0] = strsub(u[0], 1, 74)
			p = t .. "Querying Player " .. tostring(p) .. "..." .. "\n" .. t .. tostring(p1) .. "\n" .. t .. "ENERGY: " .. tostring(m) .. "\n" .. t .. tostring(n) .. " UPGRADES: " .. "\n" .. tu .. tostring(u[0]) .. "\n" .. tu .. tostring(u[1]) .. "\n" .. tu .. tostring(u[2]) .. "\n" .. tu .. tostring(u[3]) .. "\n" .. tu .. tostring(u[4])					
		elseif strlen(u[0]) > 225 then 
			u[3] = strsub(u[0], 225)
			u[2] = strsub(u[0], 150, 224) 
			u[1]  = strsub(u[0], 75, 149)
			u[0] = strsub(u[0], 1, 74)
			p = t .. "Querying Player " .. tostring(p) .. "..." .. "\n" .. t .. tostring(p1) .. "\n" .. t .. "ENERGY: " .. tostring(m) .. "\n" .. t .. tostring(n) .. " UPGRADES: " .. "\n" .. tu .. tostring(u[0]) .. "\n" .. tu .. tostring(u[1]) .. "\n" .. tu .. tostring(u[2]) .. "\n" .. tu .. tostring(u[3])				
		elseif strlen(u[0]) > 150 then 
			u[2] = strsub(u[0], 150) 
			u[1]  = strsub(u[0], 75, 149)
			u[0] = strsub(u[0], 1, 74)
			p = t .. "Querying Player " .. tostring(p) .. "..." .. "\n" .. t .. tostring(p1) .. "\n" .. t .. "ENERGY: " .. tostring(m) .. "\n" .. t .. tostring(n) .. " UPGRADES: " .. "\n" .. tu .. tostring(u[0]) .. "\n" .. tu .. tostring(u[1]) .. "\n" .. tu .. tostring(u[2])				
		elseif strlen(u[0]) > 75 then 
			u[1]  = strsub(u[0], 75)
			u[0] = strsub(u[0], 1, 74)
			p = t .. "Querying Player " .. tostring(p) .. "..." .. "\n" .. t .. tostring(p1) .. "\n" .. t .. "ENERGY: " .. tostring(m) .. "\n" .. t .. tostring(n) .. " UPGRADES: " .. "\n" .. tu .. tostring(u[0]) .. "\n" .. tu .. tostring(u[1])					
		else 
			p = t .. "Querying Player " .. tostring(p) .. "..." .. "\n" .. t .. tostring(p1) .. "\n" .. t .. "ENERGY: " .. tostring(m) .. "\n" .. t .. tostring(n) .. " UPGRADES: " .. "\n" .. tu  .. tostring(u[0])	
		end

		ExecuteAction("DISPLAY_TEXT", "\n" .. t .. "****************************\n" .. tostring(p) .. "\n" .. t .. "NET WORTH: $" .. tostring(c) .. "\n" .. t .. "****************************")	
	else
		ExecuteAction("DISPLAY_TEXT", "Query limit reached!")	
	end
end


function OnQueryEnd_renwars(self)
	if mobaquerycount > 0 then
		mobaquerycount = mobaquerycount - 1
	end
end

-- ============== SUMMONED UNIT FUNCTIONS ===========
function OnDecoyCreated_renwars(self)
	ObjectGrantUpgrade( self, "Upgrade_Decoy" )	
end

function OnSummonPodDecoy_renwars(self)
	ExecuteAction("NAMED_DELETE",self)			
end

-- Ox drop
function OnGDIV35Ox_Created_renwars(self)
	--ObjectForbidPlayerCommands( self, true )	
	ObjectSetObjectStatus( self, "UNSELECTABLE" )	
end

function OnGDIV35Ox1_Created_renwars(self)
	ObjectHideSubObjectPermanently( self, "LOADREF", true )
	--ObjectForbidPlayerCommands( self, true )
	ObjectSetObjectStatus( self, "UNSELECTABLE" )		
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Ox disabled...", 2)				
end

function OnGDIV35Ox_Carrying_renwars(self)
	ObjectGrantUpgrade( self, "Upgrade_Transporting" )
	--ObjectForbidPlayerCommands( self, false )
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Ox enabled...", 2)					
end

function OnGDIV35Ox_Rapelling_renwars(self)
	ExecuteAction("NAMED_EXIT_ALL", self)
	ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY", self, "Command_Evacuate")
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Ox enabled...", 2)			
end

-- Kill ox if apc destroyed before ox expires
function OnCallAPCCreated_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana30Trigger")
	ObjectHideSubObjectPermanently( self, "APC_UGAB", true )
	ObjectHideSubObjectPermanently( self, "APC_UGTURRET", true )
	ObjectHideSubObjectPermanently( self, "TURRET_PITCH", false )
end

-- Kill ox if apc destroyed before ox expires
function OnCallAPCDestroyed_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnCallAPCDestroyed", 99999)
end
function OnCallAPCDestroyed1_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ExecuteAction("NAMED_DELETE",self)
	end
end

-- Kill ox if mantis destroyed before ox expires
function OnCallMantisDestroyed_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnCallMantisDestroyed", 99999)
end
function OnCallMantisDestroyed1_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ExecuteAction("NAMED_DELETE",self)
	end
end

-- Kill ox if ftank destroyed before ox expires
function OnCallFlametankDestroyed_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnCallFlametankDestroyed", 99999)
end
function OnCallFlametankDestroyed1_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ExecuteAction("NAMED_DELETE",self)
	end
end

-- Kill ox if pred destroyed before ox expires
function OnCallPredatorDestroyed_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnCallPredatorDestroyed", 99999)
end
function OnCallPredatorDestroyed1_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ExecuteAction("NAMED_DELETE",self)
	end
end



-- Sniper/Spotter receive this event on sp trigger to reset cd
function OnBombardReset_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	local x = 1 -- fiddle factor
	
	if p1 == p2 then
		if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
			ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "JuggBombard", 3.75*x)
		else
			ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "JuggBombard", 5*x)
		end		
	end
end

function OnAirstrikeReset_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
			ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "FirehawkStrike_Dispatch", 15)
			ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "FirehawkStrike_Missile", 15)
			ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "FirehawkStrike_Bomb", 15)
			ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "FirehawkStrike_Bomb2", 15)			
		else
			ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "FirehawkStrike_Dispatch", 20)
			ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "FirehawkStrike_Missile", 20)
			ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "FirehawkStrike_Bomb", 20)
			ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "FirehawkStrike_Bomb2", 20)		
		end
	end
end

-- ********** Fiend reset **************
function OnFiendsReset_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallFiends", 15) -- not yet
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallFiends", 15)
	end
end

-- ********** Disint reset **************
function OnDisintsReset_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallDisints", 15) -- not yet
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallDisints", 15)
	end
end

-- ******* ShockPods reset ***********
function OnShockPodsReset_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "ShockPods", 15) -- not yet
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "ShockPods", 15)
	end
end
-- ************ APC reset *************
function OnCallAPCReset_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallAPC", 7.5)		
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallAPC", 10)		
	end
end
-- ************* Guardian turret reset **************
function OnDeployTurretReset_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "DeployTurret", 7.5)
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "DeployTurret", 10)
	end
end

-- ************** HH reset ***********
function OnCallHHReset_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallHH", 20)
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallHH", 20)
	end
end
-- ************ Carryall reset ***********
function OnCallCFTReset_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallCFT", 10)
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallCFT", 10)	
	end
end
-- ************ Mantis reset ***********
function OnCallMantisReset_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallMantis", 15)
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallMantis", 15)	
	end
end
-- ************ Predator reset ***********
function OnCallPredatorReset_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallPredator", 15)
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallPredator", 15)	
	end
end
-- ************ Flametank reset ***********
function OnCallFlametankReset_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallFlametank", 20)
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallFlametank", 20)	
	end
end
-- ************ Devastator reset ***********
function OnCallDevastatorReset_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallDevastator", 25)
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallDevastator", 25)	
	end
end
-- *************************************

function OnTibCharge_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_Default")
end
function OnTibChargeEnd_renwars(self)
	ObjectRemoveUpgrade(self, "Upgrade_Default")
end


-- When XPCrate item created, it broadcasts XP event to GRS
function OnXPCrateCreated_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnHeroXP",99999)
end

-- GRS receives XP events, checks team and gets XP
function OnHeroXPReceived_renwars(self,other)
	-- Dont use ObjectTeamName() command because it fails with AI players (units are auto assigned into new teams by AI)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		if ObjectTestModelCondition(self, "USER_27") == true then	
			ExecuteAction("UNIT_GIVE_EXPERIENCE_POINTS",self,9000)
		elseif ObjectTestModelCondition(self, "USER_24") == true then	
			ExecuteAction("UNIT_GIVE_EXPERIENCE_POINTS",self,4500)
		elseif ObjectTestModelCondition(self, "USER_21") == true then	
			ExecuteAction("UNIT_GIVE_EXPERIENCE_POINTS",self,1500)
		end
	end
end

-- Hero suicide
function OnRedemptionSuicide_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "RedemptionSuicideWeapon")	
end

-- When hero dies...
function OnHeroDestroyed_renwars(self)
	local p = getPlayerId(self) -- Player id
	local s = getPlayerName(self) -- Player full name
		
	-- For Cyborg Redemption...
	if strfind(tostring(ObjectDescription(self)), "406C94AC") ~= nil and ObjectTestModelCondition(self, "USER_59") == true then
		ObjectCreateAndFireTempWeapon(self, "DeployRedemptionHeroRespawner")
		mobaredemptionstatus[p] = 1
	-- For rest of us mere mortals...
	else			
		local x = mobadmgtracker[p] -- killer object (who was the last object to attack me?)
		local p1 = getPlayerId(x) -- killer's Player id
		local p2 = getPlayerName(x) -- killer's Player full name
		
		-- Any specific actions to do onDeath
		-- BH Firewall stop
		if strfind(tostring(ObjectDescription(self)), "89C62490") ~= nil then
			if ObjectTestModelCondition(self, "USER_31") == true then		
				ObjectBroadcastEventToAllies(self, "OnFirewallStop", 9999)
			end
		end
		-- MOK Comm drop crate ::: DOESNT WORK IN GARRISONED STATE, moved to RedemptionChecker
		--if strfind(tostring(ObjectDescription(self)), "406C94AC") ~= nil then
		--	ObjectCreateAndFireTempWeapon(self, "DeployMOKCommandoHeroCrate")
		--end
		
		-- If killer is enemy hero player (and is not a non-mindcontrolled unit), announce his name
		if mobaspawnreg[p1] ~= nil and mobateam[p] ~= mobateam[p1] and ObjectTestModelCondition(x, "USER_69") == false then
				
			if mobakillspree[p] < 3 then
				s = s .. " got pwnd by " .. tostring(p2) .. "!"
			elseif mobakillspree[p] == 3 then
				s = s .. "'s KILLING SPREE streak was ended by " .. tostring(p2) .. "!"
			elseif mobakillspree[p] == 4 then
				s = s .. "'s DOMINATING streak was ended by " .. tostring(p2) .. "!"
			elseif mobakillspree[p] == 5 then
				s = s .. "'s MEGA KILL streak was ended by " .. tostring(p2) .. "!"
			elseif mobakillspree[p] == 6 then
				s = s .. "'s UNSTOPPABLE streak was ended by " .. tostring(p2) .. "!"
			elseif mobakillspree[p] == 7 then
				s = s .. "'s WICKED SICK streak was ended by " .. tostring(p2) .. "!"
			elseif mobakillspree[p] == 8 then
				s = s .. "'s MONSTER KILL streak was ended by " .. tostring(p2) .. "!"
			elseif mobakillspree[p] == 9 then
				s = s .. "'s GODLIKE streak was ended by " .. tostring(p2) .. "!"
			elseif mobakillspree[p] == 10 then
				s = s .. "'s BEYOND GODLIKE streak was ended by " .. tostring(p2) .. "!"
			elseif mobakillspree[p] >= 11 then
				s = s .. "'s OWNAGE streak was ended by " .. tostring(p2) .. "!"
			end

			ExecuteAction("DISPLAY_TEXT", tostring(s))

			mobatotalkills = mobatotalkills + 1

			mobakillspree[p1] = mobakillspree[p1] + 1 -- increment counter for killer		
			mobakills[p1] = mobakills[p1] + 1 -- increment counter for killer
			
			-- the last object to deal dmg to me is passed to announcer...
			KillAnnounce_renwars(x)			
		
		-- If killer is non-hero player, show a more generic message
		else
			if mobakillspree[p] < 3 then
				s = s .. " was killed!"		
			elseif mobakillspree[p] == 3 then
				s = s .. "'s KILLING SPREE streak was ended!"	
			elseif mobakillspree[p] == 4 then
				s = s .. "'s DOMINATING streak was ended!"	
			elseif mobakillspree[p] == 5 then
				s = s .. "'s MEGA KILL streak was ended!"	
			elseif mobakillspree[p] == 6 then
				s = s .. "'s UNSTOPPABLE streak was ended!"	
			elseif mobakillspree[p] == 7 then
				s = s .. "'s WICKED SICK streak was ended!"	
			elseif mobakillspree[p] == 8 then
				s = s .. "'s MONSTER KILL streak was ended!"	
			elseif mobakillspree[p] == 9 then
				s = s .. "'s GODLIKE streak was ended!"	
			elseif mobakillspree[p] == 10 then
				s = s .. "'s BEYOND GODLIKE streak was ended!"	
			elseif mobakillspree[p] >= 11 then
				s = s .. "'s OWNAGE streak was ended!"	
			end	
			
			ExecuteAction("DISPLAY_TEXT", tostring(s)) 		
			
		end	
			
		-- for ctf mode
		if mobactfmode == 1 then
			if ObjectHasUpgrade(x, "Upgrade_TeamGDI") == 1 or ObjectHasUpgrade(x, "Upgrade_TeamNOD") == 1 then
				if ObjectTestModelCondition(self, "USER_55") == true then -- give enemy CTF pts if this guy was flag holder
					ObjectCreateAndFireTempWeapon(x, "CTF_ScoreKill")
				end
			end
		elseif mobaarenamode == 1 then
			if ObjectHasUpgrade(x, "Upgrade_TeamGDI") == 1 or ObjectHasUpgrade(x, "Upgrade_TeamNOD") == 1 then
				ObjectCreateAndFireTempWeapon(x, "Arena_ScoreKill")
			end	
		end	
		
		mobakillspree[p] = 0 -- reset counter for victim		
		mobadeaths[p] = mobadeaths[p] + 1 -- increment death counter for victim 	#
	end
end

function KillAnnounce_renwars(x1)

	local p = getPlayerId(x1) -- Player id
	local s = getPlayerName(x1) -- Full Player name
	
	local a = GetRandomNumber()
	
	if mobatotalkills == 1 then
		s = s .. " has drawn FIRST BLOOD!"
		ExecuteAction("DISPLAY_TEXT", tostring(s)) 
		ExecuteAction("PLAY_SOUND_EFFECT", "Announce_FB")				
		--ObjectCreateAndFireTempWeapon(xx, "Announce_FB")	
	elseif mobakillspree[p] == 2 then
		s = s .. " has claimed a DOUBLE KILL!"
		ExecuteAction("DISPLAY_TEXT", tostring(s)) 
		ExecuteAction("PLAY_SOUND_EFFECT", "Announce_DoubleKill")		
		--ObjectCreateAndFireTempWeapon(xx, "Announce_DoubleKill")	
	elseif mobakillspree[p] == 3 then
		if a <= 0.5 then
			s = s .. " is on a KILLING SPREE!"		
			ExecuteAction("PLAY_SOUND_EFFECT", "Announce_KillingSpree")
		else
			s = s .. " has claimed a TRIPLE KILL!"		
			ExecuteAction("PLAY_SOUND_EFFECT", "Announce_TripleKill")
		end		
		ExecuteAction("DISPLAY_TEXT", tostring(s)) 		
		--ObjectCreateAndFireTempWeapon(xx, "Announce_KillingSpree")	
	elseif mobakillspree[p] == 4 then
		s = s .. " is DOMINATING!"
		ExecuteAction("DISPLAY_TEXT", tostring(s))
		ExecuteAction("PLAY_SOUND_EFFECT", "Announce_Dominating")			
		--ObjectCreateAndFireTempWeapon(xx, "Announce_Ownage")		
	elseif mobakillspree[p] == 5 then
		s = s .. " is on a MEGA KILL!"
		ExecuteAction("DISPLAY_TEXT", tostring(s)) 
		ExecuteAction("PLAY_SOUND_EFFECT", "Announce_MegaKill")		
		--ObjectCreateAndFireTempWeapon(xx, "Announce_MegaKill")	
	elseif mobakillspree[p] == 6 then
		s = s .. " is UNSTOPPABLE!"
		ExecuteAction("DISPLAY_TEXT", tostring(s))
		ExecuteAction("PLAY_SOUND_EFFECT", "Announce_Unstoppable")			
		--ObjectCreateAndFireTempWeapon(xx, "Announce_Dominating")		
	elseif mobakillspree[p] == 7 then
		s = s .. " is WICKED SICK!"
		ExecuteAction("DISPLAY_TEXT", tostring(s))
		ExecuteAction("PLAY_SOUND_EFFECT", "Announce_WickedSick")			
		--ObjectCreateAndFireTempWeapon(xx, "Announce_Unstoppable")	
	elseif mobakillspree[p] == 8 then
		s = s .. " has claimed a MONSTER KILL!"
		ExecuteAction("DISPLAY_TEXT", tostring(s))
		ExecuteAction("PLAY_SOUND_EFFECT", "Announce_MonsterKill")			
		--ObjectCreateAndFireTempWeapon(xx, "Announce_WickedSick")				
	elseif mobakillspree[p] == 9 then
		s = s .. " is GODLIKE!"
		ExecuteAction("DISPLAY_TEXT", tostring(s))
		ExecuteAction("PLAY_SOUND_EFFECT", "Announce_GodLike")			
		--ObjectCreateAndFireTempWeapon(xx, "Announce_MonsterKill")			
	elseif mobakillspree[p] == 10 then
		s = s .. " is BEYOND GODLIKE! Someone stop them!"
		ExecuteAction("DISPLAY_TEXT", tostring(s)) 		
		ExecuteAction("PLAY_SOUND_EFFECT", "Announce_HolyShit")		
		--ObjectCreateAndFireTempWeapon(xx, "Announce_GodLike")	
	elseif mobakillspree[p] >= 11 then
		if a <= 1/3 then
			ExecuteAction("PLAY_SOUND_EFFECT", "Announce_Ownage")
			s = s .. " is OWNING! Someone stop them!"			
		elseif a <= 2/3 then
			ExecuteAction("PLAY_SOUND_EFFECT", "Announce_HolyShit")	
			s = s .. " is BEYOND GODLIKE! Someone stop them!"			
		else
			ExecuteAction("PLAY_SOUND_EFFECT", "Announce_Rampage")
			s = s .. " is ON RAMPAGE! Someone stop them!"			
		end
		ExecuteAction("DISPLAY_TEXT", tostring(s)) 
		--ObjectCreateAndFireTempWeapon(xx, "Announce_HolyShit")	
	end
end



-- Register respawntimer and its owner
function OnRespawnTimerCreated_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnHeroDeath",99999)
	
	local p = getPlayerId(self) -- Get Player id
	local a = getObjectId(self) -- Get Object id
	
	mobarespawntimerreg[p] = a
end
-- Register spotter respawntimer and its owner
function OnSpotterRespawnTimerCreated_renwars(self)
	
	local p = getPlayerId(self) -- Get Player id
	local a = getObjectId(self) -- Get Object id
	
	mobarespawntimerreg1[p] = a
end

-- Respawn timer set based on hero level
function OnRespawnTimerSet_renwars(self)

	local x = 60

	if ObjectTestModelCondition(self, "USER_30") == true then
		x = 45
	elseif ObjectTestModelCondition(self, "USER_29") == true then
		x = 41
	elseif ObjectTestModelCondition(self, "USER_28") == true then
		x = 37
	elseif ObjectTestModelCondition(self, "USER_27") == true then
		x = 33
	elseif ObjectTestModelCondition(self, "USER_26") == true then
		x = 29
	elseif ObjectTestModelCondition(self, "USER_25") == true then
		x = 25
	elseif ObjectTestModelCondition(self, "USER_24") == true then
		x = 21
	elseif ObjectTestModelCondition(self, "USER_23") == true then
		x = 17	
	elseif ObjectTestModelCondition(self, "USER_22") == true then
		x = 13	
	else
		x = 9	
	end		
	
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		x = x*0.75
	end

	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "NoBuyBack", x-1) -- prevent use of buyback just before timer expires	
	
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RespawnTimer_GDICommando", x)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RespawnTimer_GDISniper", x)	
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RespawnTimer_SteelTalonsCombatEngineer", x)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RespawnTimer_ZOCOMZoneraider", x)	
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RespawnTimer_GDIGrenadeSoldier", x)			
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RespawnTimer_NODCommando", x)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RespawnTimer_NODFanatic", x)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RespawnTimer_NODBlackhand", x)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RespawnTimer_NODShadow", x)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RespawnTimer_MarkedOfKaneCommando", x)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RespawnTimer_T59Prodigy", x)	
end

-- just before respawn timer expires, prevent buyback
function OnRespawnTimerNoBB_renwars(self)
	ObjectSetObjectStatus( self, "RIDER3" )
end

-- Tell hero spawners to spawn hero
function OnRespawnTimerKill_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnHeroRespawnReceived",99999)
	ExecuteAction("NAMED_KILL",self)		
end
-- ... for Spotter
function OnSpotterRespawnTimerKill_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnSpotterRespawnReceived",99999)
	ExecuteAction("NAMED_KILL",self)		
end


-- Wormhole created
function OnWormholeCreated_renwars(self)
	ExecuteAction("NAMED_USE_COMMANDBUTTON_ABILITY",self,"Command_WormholeDummy")
end

-- Mana Burn
function OnManaBurn2_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana2Trigger")
end


-- ========================== CRATE FUNCTIONS ===================================

-- For viceroid spawn, crates broadcast an event to TibGas object
-- which receives the event and fires a spawn weapon
function OnSpawnEventReceived_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ViceroidSpawnWeapon")	
end

-- These salvage crates broadcast spawn event to TibGas
function OnSalvageCrateCreated_renwars(self)	
	local a = getObjectId(self) -- Get Object id
	mobacratetable[a] = {} -- init crate claim array
	
	-- Send event to all nearby heroes
	ObjectBroadcastEventToEnemies(self,"OnSalvageCrateClaimed",300)
	
	-- For TibGas
	ObjectBroadcastEventToEnemies(self,"OnSpawnEventReceived",125)
end
-- ... and these dont
function OnSalvageCrateCreated2_renwars(self)
	local a = getObjectId(self) -- Get Object id
	mobacratetable[a] = {} -- init crate claim array
	
	-- Send event to all nearby heroes
	ObjectBroadcastEventToEnemies(self,"OnSalvageCrateClaimed",300)	
end


-- Hero Crate always gets its owner hero's XP level upon creation (handled in behaviors)
-- and stores this info in array
function OnHeroCrateCreated_renwars(self)
	local a = getObjectId(self) -- Get Object id
	mobacratetable[a] = {} -- init crate claim array
	
	-- Fire SP to lose money based on hero level, store Object id and current XP level in array
	if ObjectTestModelCondition(self, "USER_30") == true then
		ObjectDoSpecialPower(self, "HeroDie10")
		mobaherocratetable[a] = 10		
	elseif ObjectTestModelCondition(self, "USER_29") == true then
		ObjectDoSpecialPower(self, "HeroDie9")
		mobaherocratetable[a] = 9		
	elseif ObjectTestModelCondition(self, "USER_28") == true then
		ObjectDoSpecialPower(self, "HeroDie8")
		mobaherocratetable[a] = 8		
	elseif ObjectTestModelCondition(self, "USER_27") == true then
		ObjectDoSpecialPower(self, "HeroDie7")
		mobaherocratetable[a] = 7				
	elseif ObjectTestModelCondition(self, "USER_26") == true then
		ObjectDoSpecialPower(self, "HeroDie6")
		mobaherocratetable[a] = 6				
	elseif ObjectTestModelCondition(self, "USER_25") == true then
		ObjectDoSpecialPower(self, "HeroDie5")
		mobaherocratetable[a] = 5				
	elseif ObjectTestModelCondition(self, "USER_24") == true then
		ObjectDoSpecialPower(self, "HeroDie4")
		mobaherocratetable[a] = 4		
	elseif ObjectTestModelCondition(self, "USER_23") == true then
		ObjectDoSpecialPower(self, "HeroDie3")
		mobaherocratetable[a] = 3		
	elseif ObjectTestModelCondition(self, "USER_22") == true then
		ObjectDoSpecialPower(self, "HeroDie2")
		mobaherocratetable[a] = 2		
	elseif ObjectTestModelCondition(self, "USER_21") == true then
		ObjectDoSpecialPower(self, "HeroDie1")
		mobaherocratetable[a] = 1		
	end
	
	-- Send event to all nearby heroes
	ObjectBroadcastEventToEnemies(self,"OnSalvageCrateClaimed",300)	
	
	-- For TibGas
	ObjectBroadcastEventToEnemies(self,"OnSpawnEvent",125)	
end

-- CratePicker claims the crate
function OnSalvageCrateClaimed_renwars(self,other)
	local a = getObjectId(other)
	local p = getPlayerId(self)
	mobacratetable[a][p] = 1
end

-- Send event to GRS on crate expiry
function OnSalvageCrateDestroyed_renwars(self)
	local a = getObjectId(self) -- Get Object id
	
	local len = getSize(mobacratetable[a])
	mobacratetable[a]['len'] = len	
	-- If claimed atleast once, broadcast to all enemy GRS
	if len > 0 then
		ObjectBroadcastEventToEnemies(self,"OnSalvageCrateReceived",99999)
	else
		mobacratetable[a] = nil -- clear garbage
	end
end

-- GRS receives XP event from salvage crate and checks if this player is one of the claimants
function OnSalvageCrateReceived_renwars(self,other)
	
	local a = getObjectId(other) -- crate id
	local p = getPlayerId(self) -- this player id
	
	if mobacratetable[a][p] ~= nil then -- has this player claimed this crate?

		local num = mobacratetable[a]['len'] -- no. players who share this reward
		local xp = 0 -- xp reward
		local m = 0 -- money reward
	
		if mobaherocratetable[a] ~= nil then -- HERO CRATE

			local x = mobaherocratetable[a]	-- rewards based on hero xp level
						
			-- share XP/money among players
			m = floor((100+60*(x-1))/num/5)*5						
			xp = floor(100*x/num)
			
			mobaassists[p] = mobaassists[p] + 1 -- increment assists count
			
		else -- NON-HERO CRATE
		
			local o = ObjectDescription(other)	-- rewards based on unit cost
		
			-- name format for hashes: salvagecrate_x
			-- viceroid, razordrone, rifle
			if strfind(tostring(o), "E30D33F6") ~= nil or strfind(tostring(o), "8EBD81B9") ~= nil or strfind(tostring(o), "44021828") ~= nil then
				xp = 300
			-- missile
			elseif strfind(tostring(o), "B314218A") ~= nil then
				xp = 400
			-- carryall
			elseif strfind(tostring(o), "3EEDA99A") ~= nil then
				xp = 500
			-- shocktrooper
			elseif strfind(tostring(o), "B63896D") ~= nil then
				xp = 600			
			-- mutant
			elseif strfind(tostring(o), "F6CB10F9") ~= nil then
				xp = 800
			-- ravager
			elseif strfind(tostring(o), "341D24D6") ~= nil then
				xp = 900
			-- apc, corrupter, golemcannon, mantis
			elseif strfind(tostring(o), "388EA071") ~= nil or strfind(tostring(o), "A97D972D") ~= nil or strfind(tostring(o), "1F582437") ~= nil or strfind(tostring(o), "C13E25C7") ~= nil then
				xp = 1000
			-- predator
			elseif strfind(tostring(o), "9AA89B8") ~= nil then
				xp = 1100
			-- flametank
			elseif strfind(tostring(o), "D338D039") ~= nil then
				xp = 1200		
			-- zt
			elseif strfind(tostring(o), "B821E76D") ~= nil then
				xp = 1300	
			-- hh
			elseif strfind(tostring(o), "D274319E") ~= nil then
				xp = 1500
			-- devastator
			elseif strfind(tostring(o), "42E35730") ~= nil then
				xp = 2000	
			-- hexa
			elseif strfind(tostring(o), "9D1DC509") ~= nil then 
				xp = 5000/3
			end
			
			 -- share XP/money among players
			m = floor(xp/num*0.15/5)*5
			xp = floor(xp/num*0.2)
					
		end
			
		-- Give XP
		ExecuteAction("UNIT_GIVE_EXPERIENCE_POINTS",self,xp)
		
		-- Give money via $5/10/50/100 crates
		x1 = floor(m/100)
		m = m - x1*100
		
		x2 = floor(m/50)	
		m = m - x2*50
		
		x3 = floor(m/10)	
		m = m - x3*10

		x4 = floor(m/5)	
		m = m - x4*5

		for i=1,x1 do
			ObjectCreateAndFireTempWeapon(mobaspawnrego[p], "MoneyReward100")					
		end
		for i=1,x2 do
			ObjectCreateAndFireTempWeapon(mobaspawnrego[p], "MoneyReward50")					
		end		
		for i=1,x3 do
			ObjectCreateAndFireTempWeapon(mobaspawnrego[p], "MoneyReward10")					
		end		
		for i=1,x4 do
			ObjectCreateAndFireTempWeapon(mobaspawnrego[p], "MoneyReward5")					
		end
		
		mobacratetable[a][p] = nil -- clear garbage		
		
	end

end



--  ============= CHEAT CRATES ============
function OnMoneyCrateCreated_renwars(self)

	ObjectDoSpecialPower(self, "MoneyCrateReward")

	local p = getPlayerName(self) -- Get Player name
	ExecuteAction("SHOW_MILITARY_CAPTION", "Player " .. tostring(p) .. " has used a MONEY HACK CRATE!!!", 5)	
end

function OnUpgradeCrateCreated_renwars(self)
	local p = getPlayerName(self) -- Get Player name
	ExecuteAction("SHOW_MILITARY_CAPTION", "Player " .. tostring(p) .. " has used an UPGRADE HACK CRATE!!!", 5)		
end

function OnFFCrateCreated_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnFFCrateReceived",99999)
end
function OnFFCrateReceived_renwars(self, other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "FFCrateCounterWeapon")
		local p = getPlayerName(self) -- Get Player name
		ExecuteAction("SHOW_MILITARY_CAPTION", "Player " .. tostring(p) .. " has enabled FRIENDLY FIRE for their units!!!", 5)		
	end
end

-- When DetectionCrate item created, it broadcasts event to GRS to spawn the actual crate with infinite detection.
-- If crate already spawned, it broadcasts event to crate which kills itself on receiving the event.
function OnDetectionCrateCreated_renwars(self)
	local q = getPlayerName(self) -- Get Player name
    local p = getPlayerId(self) -- Player id
    if mobadetectionhackstatus[p] == nil then
	   mobadetectionhackstatus[p] = 1
	   ObjectBroadcastEventToAllies(self,"OnDetectionCrateEnableReceived",99999)
	   ExecuteAction("SHOW_MILITARY_CAPTION", "Player " .. tostring(q) .. " has enabled DETECTION HACK!!!", 5)	
	else
	   mobadetectionhackstatus[p] = nil
	   ObjectBroadcastEventToAllies(self,"OnDetectionCrateDisableReceived",99999)	
	   ExecuteAction("SHOW_MILITARY_CAPTION", "Player " .. tostring(q) .. " has disabled DETECTION HACK!!!", 5)		   
	end
end

function OnDetectionCrateEnableReceived_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "DeployDetectionCrateWeapon")	
end

function OnDetectionCrateKillerCreated_renwars(self)
	--ExecuteAction("SHOW_MILITARY_CAPTION", "DETECTION HACK ENABLED!!", 5)		
end

function OnDetectionCrateDisableReceived_renwars(self)
	--ExecuteAction("SHOW_MILITARY_CAPTION", "DETECTION HACK NOT ENABLED!!", 5)		
	ExecuteAction("NAMED_DELETE",self)
end

-- UNUSED FOR NOW, needs some thought
function OnHeroSpawnCrateReceived_renwars(self, other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "Respawn_GDIConYard")
		local p = getPlayerName(self) -- Get Player name
		ExecuteAction("SHOW_MILITARY_CAPTION", "Player " .. tostring(p) .. " has spawned an extra hero!!!", 5)		
	end
end

-- ==================== MISC ===========================

function OnImmortalCrateCreated_renwars(self)
	local p = getPlayerName(self)
	ExecuteAction("SHOW_MILITARY_CAPTION", "Player " .. tostring(p) .. " has received the power of invincibility!",5)		
end

function OnTelepowerCrateCreated_renwars(self)
	local p = getPlayerName(self)
	ExecuteAction("SHOW_MILITARY_CAPTION", "Player " .. tostring(p) .. " has received the power of global teleportation!",5)		
end


-- Bonus mana regen: currently only for Sniper
-- Updates every 2s (so adds 2s to timer everytime)
function OnManaBonus_renwars(self)
	local a = strsub(ObjectDescription(self),strfind(ObjectDescription(self),'t')+2,strfind(ObjectDescription(self),',')-4) -- Get Object id	
	
	if ObjectTestModelCondition(self, "USER_3") == true then

		if mobatimecount[a] == nil then
			mobatimecount[a] = 0
		end
		
		mobatimecount[a] = mobatimecount[a] + 1

		if ObjectTestModelCondition(self, "USER_30") == true and mod(mobatimecount[a],12) == 0 then
			ObjectCreateAndFireTempWeapon(self, "ManaBonusWeapon1")	
		end
		if ObjectTestModelCondition(self, "USER_28") == true and mod(mobatimecount[a],6) == 0 then
			ObjectCreateAndFireTempWeapon(self, "ManaBonusWeapon1")		
		end
		if ObjectTestModelCondition(self, "USER_26") == true and mod(mobatimecount[a],4) == 0 then
			ObjectCreateAndFireTempWeapon(self, "ManaBonusWeapon1")	
		end
		if ObjectTestModelCondition(self, "USER_24") == true and mod(mobatimecount[a],10) == 0 then	
			ObjectCreateAndFireTempWeapon(self, "ManaBonusWeapon1")	
		end
		if ObjectTestModelCondition(self, "USER_22") == true and mod(mobatimecount[a],20) == 0 then					
			ObjectCreateAndFireTempWeapon(self, "ManaBonusWeapon1")				
		end		
	end	
	
end

function OnHeroHeal_renwars(self)
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Healing power!",1)
	ObjectDoSpecialPower(self, "HealingPower")
end

-- ================ HERO CREATED/INIT FUNCTIONS =================

function OnHeroCreated_renwars(self)
	local p = getPlayerId(self) -- Get Player id
	local a = getObjectId(self) -- Get Object id
	mobaheroreg[p] = a	
	mobadmgtracker[p] = nil	-- reset attacker tracker
	
	ObjectBroadcastEventToAllies(self,"OnHeroCreated",99999) -- does nothing for now
	
	local x = ObjectDescription(self)		
	if strfind(tostring(x), "9036C4A9") ~= nil then	-- zoneraider
		ObjectHideSubObjectPermanently( self, "UGSCANNER", true )
		ObjectHideSubObjectPermanently( self, "UGJUMP", true )
		ObjectHideSubObjectPermanently( self, "UGINJECTOR", true )
	elseif strfind(tostring(x), "80DFF5D9") ~= nil then -- combat engi
		ObjectHideSubObjectPermanently( self, "MUZZLEFLASH", true )
		ObjectHideSubObjectPermanently( self, "LASER", true )		
	elseif strfind(tostring(x), "30D0C6EC") ~= nil then -- fanatic
		ObjectGrantUpgrade(self, "Upgrade_FanaticDisguiseNone")
	end
end


-- Cloned hero
function OnHeroCloneCreated_renwars(self)
	-- all hero specific stuff here
	ObjectGrantUpgrade(self, "Upgrade_FanaticDisguiseNone") -- fanatic no disguise	
	
	ObjectHideSubObjectPermanently( self, "MUZZLEFLASH", true )
	ObjectHideSubObjectPermanently( self, "LASER", true )	
	
	ObjectHideSubObjectPermanently( self, "UGSCANNER", true )
	ObjectHideSubObjectPermanently( self, "UGJUMP", true )
	ObjectHideSubObjectPermanently( self, "UGINJECTOR", true )		
end


-- SPOTTER
function OnSpotterCreated_renwars(self)
	local p = getPlayerId(self) -- Get Player id
	local a = getObjectId(self) -- Get Object id
	mobaheroreg1[p] = a		
end


-- Reset hero abilities when SPDrone attaches to hero
function OnHeroAbilityReset_renwars(self)

	local d = ObjectDescription(self)
			
	-- This function only needs to run once per spawn (incase SPDrone re-attaches to trigger this event again)
	if mobaheroreset[d] == nil then
		mobaheroreset[d] = 1
		
		local p = strsub(ObjectDescription(self),strfind(ObjectDescription(self), "owned by ") + 9) -- Player id
		
		local x = 1 -- upgrade reduction factor
		local y = 0.5 -- respawn reduction factor
		if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then	
			x = 0.75
		end
				
		--ExecuteAction("CREATE_OBJECT", "GDIMammothTank", GetTeamName(), "0,0,0", 0)
			
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "Hypercharge", 30*x*y)		
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "EMPLockdown", 35*x*y)		
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "FirehawkStrike_Dispatch", 20*x*y)		
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "CallDroppods", 30*x*y)	

		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "SpawnClones", 45*x*y)	
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "TibInfusion", 25*x*y)		
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "ConfessorAmbush", 55*x*y)		
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "SpecBombard", 15*x*y)		
			
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "SpecialPowerMastermindTeleportObjectSelect", 20*x*y)				
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "SpecialPowerMastermindTeleportObject", 20*x*y)
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "TeleportObjectsDummy", 20*x*y)		
			
		-- If this is a cyborg redemption respawn, no ability cd reduction and no energy regen	
		if strfind(tostring(d), "406C94AC") ~= nil then
			if mobaredemptionstatus[p] == nil or mobaredemptionstatus[p] == 0 then
				mobaredemptionstatus[p] = 0
				ObjectCreateAndFireTempWeapon(self, "EnergyPodInitialWeapon")
				ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "DeployRedemption", 80*x*y)		
				ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RedemptionSuicide", 5*x*y)
			elseif mobaredemptionstatus[p] == 1 then
				mobaredemptionstatus[p] = 0
				ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "DeployRedemption", 70*x)		
				ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RedemptionSuicide", 5*x)		
			end
		else
			ObjectCreateAndFireTempWeapon(self, "EnergyPodInitialWeapon")
		end

	end
end



-- GRS receives OnHeroCreated event
function OnHeroCreatedReceived_renwars(self,other)
	-- nothing
end
-- Spawner receives OnHeroCreated event
function OnHeroCreatedReceived1_renwars(self,other)
	-- nothing
end


-- Upgrade Spotter
function OnSpotterUpgrade_renwars(self)
	--if ObjectTestModelCondition(self, "USER_3") == true then
		ObjectCreateAndFireTempWeapon(self, "DeploySpotterPodWeapon")
	--end
end

-- Upgrade granted to GRS by GDI/Nod statue
function OnTeamGDI_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "TeamGDIUpgrade")

	local p1 = getPlayerId(self) -- Player name	
	mobateam[p1] = 'GDI'

	local s = getPlayerName(self) -- Player full name			
	if (strfind(tostring(s), "Easy AI") == nil and strfind(tostring(s), "Medium AI") == nil and strfind(tostring(s), "Hard AI") == nil and strfind(tostring(s), "Brutal AI") == nil) then
		ObjectSetObjectStatus( self, "RIDER_IS_PILOT" )
	end
end
function OnTeamNOD_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "TeamNODUpgrade")

	local p1 = getPlayerId(self) -- Player name	
	mobateam[p1] = 'NOD'	

	local s = getPlayerName(self) -- Player full name			
	if (strfind(tostring(s), "Easy AI") == nil and strfind(tostring(s), "Medium AI") == nil and strfind(tostring(s), "Hard AI") == nil and strfind(tostring(s), "Brutal AI") == nil) then
		ObjectSetObjectStatus( self, "RIDER_IS_PILOT" )
	end	
end

-- SW item broadcasts this event to GRS
function OnSWCreated1_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnSWCreated",99999)
end
-- GRS spawns actual SW
function OnSWCreated2_renwars(self,other)
	local p1 = strsub(ObjectDescription(other),strfind(ObjectDescription(other), "owned by ") + 9)
	local p2 = strsub(ObjectDescription(self),strfind(ObjectDescription(self), "owned by ") + 9)
	
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "IonCannonCounterWeapon")	
	end
end

mobasw1 = 150 -- half cd
mobasw2 = 300 -- full cd
-- SW init (for testing mostly)
function OnSWInit_renwars(self)
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "SpecialPowerIonCannonControlIonCannon", mobasw1)	
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "SpecialPowerIonCannonControlIonCannon_Charged", mobasw2)			
end
-- SW counter creates charge dummy when charged
function OnSWCharged_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "IonCannonChargeDummyWeapon")	
end
-- Send event to reset counter's dummy timer when SW activated
function OnSWUsed_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnSWFired",99999)	
end
-- Fire corresponding weapon based on charge status
function OnSWPicker_renwars(self)
	if ObjectTestModelCondition(self, "USER_2") == true then
		ObjectCreateAndFireTempWeapon(self, "IonCannonFireChargedWeapon") -- Full charge
	else
		ObjectCreateAndFireTempWeapon(self, "IonCannonFireWeakWeapon") -- Half charge			
	end
	-- Finally destroy the charge object after the weapon is fired
	ObjectBroadcastEventToAllies(self,"OnSWUncharged",99999)	
end
-- SW counter receives firer event and resets timers
function OnSWResetReceived_renwars(self, other)
	local p1 = strsub(ObjectDescription(other),strfind(ObjectDescription(other), "owned by ") + 9)
	local p2 = strsub(ObjectDescription(self),strfind(ObjectDescription(self), "owned by ") + 9)

	if p1 == p2 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "SpecialPowerIonCannonControlIonCannon", mobasw1)
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "SpecialPowerIonCannonControlIonCannon_Charged", mobasw2)	
	end
end
-- SW charge dummy dies if SW used or hero dies
function OnSWUncharged_renwars(self, other)
	local p1 = strsub(ObjectDescription(other),strfind(ObjectDescription(other), "owned by ") + 9)
	local p2 = strsub(ObjectDescription(self),strfind(ObjectDescription(self), "owned by ") + 9)

	if p1 == p2 then
		ExecuteAction("NAMED_KILL",self)		
	end
end

-- ========= GDI Commando ======
function OnReactiveArmor_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana15Trigger")
end

function OnFragMode_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana15Trigger")
end

function OnHyperjump_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_Hyperjump")
	--ExecuteAction("SHOW_MILITARY_CAPTION", "hyper...", 2)		
end

function OnHyperjumpEnd_renwars(self)
	ObjectRemoveUpgrade(self, "Upgrade_Hyperjump")
	--ExecuteAction("SHOW_MILITARY_CAPTION", "hyper end...", 2)		
end

function OnUpgradeLeadership_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "CommandoBuffPodWeapon")
end


-- ============ MOK CYBORG COMM ========

-- Adds a 'charge' and reduces cooldown with every use
function OnPlasmaBoltCharge_renwars(self)
	local a = ObjectDescription(self)
	
	x = 1
	if ObjectHasUpgrade(self, "Upgrade_FusionCore") == 1 then
		x = 0.75
	end
		
	delta = 1.5 -- time multiplier for some leeway in charge duration
		
	if mobachargestatus[a] == nil or mobachargestatus[a] == 0 then
		mobachargestatus[a] = 1
		ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", self, "USER_6", 8 * delta, 100)
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "PlasmaBolt", 8 * x)		
		--ExecuteAction("SHOW_MILITARY_CAPTION", "plasma bolt 1.0...", 2)		
	elseif mobachargestatus[a] == 1 then
		mobachargestatus[a] = 2
		ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", self, "USER_6", 6 * delta, 100)
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "PlasmaBolt", 6 * x)		
		--ExecuteAction("SHOW_MILITARY_CAPTION", "plasma bolt 0.66...", 2)			
	elseif mobachargestatus[a] == 2 then
		mobachargestatus[a] = 2
		ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", self, "USER_6", 4 * delta, 100)
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "PlasmaBolt", 4 * x)				
		--ExecuteAction("SHOW_MILITARY_CAPTION", "plasma bolt 0.33...", 2 )			
	end
end

function OnPlasmaBoltChargeEnd_renwars(self)
	local a = ObjectDescription(self)
	mobachargestatus[a] = 0
	--ExecuteAction("SHOW_MILITARY_CAPTION", "reset plasma bolt...", 2)					
end

function OnTibCannonMode_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana15Trigger")
end

-- Mag Mine stuff: If not attached within set duration, kill self
function OnMagMineAttached_renwars(self)
	if ObjectTestModelCondition(self, "ATTACHED") == false then
		ExecuteAction("NAMED_KILL", self)	
	end
end

-- Redemption stuff
function OnRedemptionChecker_renwars(self)
	local p = getPlayerId(self) -- Player id
	if mobaredemptionstatus[p] == nil or mobaredemptionstatus[p] == 0 then
		ObjectCreateAndFireTempWeapon(self, "DeployMOKCommandoHeroCrate")
	end
end

function OnRedemptionTrigger_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "DeployRedemption")
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RedemptionSuicide", 0.75)		
end

function OnRedemptionBuff_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_RedemptionSuicide")
end
function OnRedemptionBuffEnd_renwars(self)
	ObjectRemoveUpgrade(self, "Upgrade_RedemptionSuicide")
end

function OnRedemptionSuicide_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "RedemptionSuicideWeapon")	
end

function OnCyborgCreated_renwars(self)
	ObjectHideSubObjectPermanently( self, "WEAPON_PARTICLEBM", true )
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RedemptionSuicide", 6)	
end
function OnCyborgDeath_renwars(self)
	if ObjectTestModelCondition(self, "USER_59") == true then
		ObjectCreateAndFireTempWeapon(self, "DeployRedemptionCyborgRespawner")
	end
end
-- ===========================
-- Carryall Harvest Pod
function OnHarvestUpgrade_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "DeployHarvestPodWeapon")
end

-- ========== SHADOW BEACON ====

function OnShadowBeaconUpgraded_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "DeployShadowBeaconUpgradedWeapon")
	ExecuteAction("NAMED_DELETE",self)
end

-- ========== SNIPER =========
function OnSniperMode_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "SniperModeWeapon") -- mana use triggered in weapon
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "SniperMode", 12)	
end

function OnSniperNestDeploy_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_SniperNest")
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Sniper nest...",4)				
end
-- 'Sniper isnt affected by bonus anymore...'
function OnSniperNestUndeploy_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "SniperNestDestroyWeapon")
	ObjectRemoveUpgrade(self, "Upgrade_SniperNest")	
	ObjectBroadcastEventToAllies(self,"OnSniperNestDestroyed",99999)	
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Sniper nest end...",4)				
end

-- Sniper Nest: if any part is destroyed it kills the others
function OnSniperNestDestroyed1_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnSniperNestDestroyed",30)
end
function OnSniperNestDestroyed2_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)

	if p1 == p2 then
		ExecuteAction("NAMED_KILL",self)
	end
end

-- ======= JUGG/SPEC BOMBARD =========
function OnBombardTargetCreated_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnBombardTargetCreated",99999)
	ObjectCreateAndFireTempWeapon(self, "UseMana20Trigger")	
end
function OnBombardTargetSpotted_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
		
	if p1 == p2 then
		ExecuteAction("NAMED_ATTACK_NAMED", self, other)
	end
end

	
-- Spec bombard strike
function OnSpecBombardTargetCreated_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana30Trigger")
end
function OnSpecBombardTargetSpotted_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ExecuteAction("NAMED_ATTACK_NAMED", self, other)
	end
end

-- ============= FIREHAWK STRIKE ==================
-- set counter to 0 on beacon spawn
function OnAirstrikeTargetCreated_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana35Trigger")
	ObjectBroadcastEventToAllies(self,"OnAirstrikeTargetCreated",99999)
	local p = getPlayerId(self) -- player id
	mobastriketable[p] = 0	
end
-- Firehawks receive 'targetspotted' event from beacon, check team, ammo and then attack beacon
function OnAirstrikeTargetSpotted_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	-- when clip on weaponslot 1 is empty(?), weaponslotid_01 is internally triggered
	if p1 == p2 then
		ExecuteAction("NAMED_ATTACK_NAMED", self, other)	
	end
end
-- When ammo has been fired, beacon increases counter
function OnAirstrikeAmmoUsed_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
		
	if p1 == p2 then
		--if ObjectHasUpgrade(self, "Upgrade_SelectLoad_01") == 0 then
			mobastriketable[p2] = mobastriketable[p2] + 1 -- 1 from bomb because 2 bombs
		
		local x = 2
		if ObjectTestModelCondition(self, "USER_9") == true then
			x = 3 -- 1 more ammo if upgraded
		end	
		if mobastriketable[p2] >= x*2 then -- 2 or 3 events from each firehawk = 4 or 6
			ObjectBroadcastEventToAllies(self,"OnAirstrikeEnd",99999)	-- kill beacon if both firehawks are destroyed/out of ammo
		end
	end
end
-- When firehawk destroyed... increase counter
function OnAirstrikeDestroyed_renwars(self)
		
	local p = getPlayerId(self)		
		
	local x = 2
	if ObjectTestModelCondition(self, "USER_9") == true then
		x = 3 -- 1 more ammo if upgraded
	end
	mobastriketable[p] = mobastriketable[p] + x

	if mobastriketable[p] >= x*2 then -- 2 or 3 events from each firehawk = 4 or 6
		ObjectBroadcastEventToAllies(self,"OnAirstrikeEnd",99999)	-- kill beacon if both firehawks are destroyed/out of ammo
	end			
end
-- Beacon receives OnStrikeEnd, creates firehawk killer dummy, and expires
function OnAirstrikeEnd_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)

	if p1 == p2 then
		ExecuteAction("NAMED_KILL", self)
	end
end
-- Firehawk killer dummy triggers strato anim
function OnAirstrikeEndAnim1_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnAirstrikeEnd1",99999)
end
function OnAirstrikeEndAnim2_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnAirstrikeEnd2",99999)	
end
-- Firehawks receive strato anim event...
function OnAirstrikeEndAnimReceived1_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)

	if p1 == p2 then
		ObjectGrantUpgrade(self, "Upgrade_StructureLevel1")
	end
end
-- After playing anim for a while, Firehawks are deleted
function OnAirstrikeEndAnimReceived2_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)

	if p1 == p2 then
		ExecuteAction("NAMED_DELETE", self)
	end
end

-- =============== RESPAWN/REGISTRATION FUNCTIONS ======================

-- Register spawner and its owner
function OnHeroSpawnerCreated_renwars(self)
	local p = getPlayerId(self) -- Get Player id
	local a = getObjectId(self) -- Get Object id
	
	--ObjectCreateAndFireTempWeapon(self, "Respawn_DummyHero")			
	
	mobaspawnreg[p] = a -- register spawner to this player
	mobaspawnrego[p] = self -- reference to hero spawner
	mobakillspree[p] = 0 -- set kill spree counter
	mobakills[p] = 0 -- set kill counter
	mobaassists[p] = 0 -- set assist counter
	mobadeaths[p] = 0 -- set death counter
	

	-- Announce hero pick
	local s = getPlayerName(self) -- Player full name
	
	local h = "STORMHAMMER"	
	if strfind(tostring(ObjectDescription(self)), "4E380E3") ~= nil then
		h = "SHARPSHOOTER"
	elseif strfind(tostring(ObjectDescription(self)), "2ACFEFEE") ~= nil then
		h = "PATCH"
	elseif strfind(tostring(ObjectDescription(self)), "BED572B3") ~= nil then
		h = "ZONE COMMANDER"
	elseif strfind(tostring(ObjectDescription(self)), "F832E9CB") ~= nil then
		h = "GLADIATOR"			
	elseif strfind(tostring(ObjectDescription(self)), "C73350AA") ~= nil then
		h = "RED WIDOW"
	elseif strfind(tostring(ObjectDescription(self)), "9AED1CE5") ~= nil then
		h = "PUNISHER"
	elseif strfind(tostring(ObjectDescription(self)), "C89E8B6C") ~= nil then
		h = "FANATIC ACOLYTE"
	elseif strfind(tostring(ObjectDescription(self)), "25F09BF7") ~= nil then
		h = "SILHOUETTE MASTER"		
	elseif strfind(tostring(ObjectDescription(self)), "E3683DA3") ~= nil then
		h = "SENTINEL"			
	elseif strfind(tostring(ObjectDescription(self)), "C642D841") ~= nil then
		h = "PRODIGY"		
	end	
	
	ExecuteAction("DISPLAY_TEXT", "\t \t \t \t \t \t \t ************* Player " .. s .. " has picked " .. h .. " ! ************* " .. p) 	
	
end

-- Register player on side, add to team player count
function OnHeroSpawnerRegistered_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_TeamGDI") == 1 then
		if mobasideplayercount['GDI'] == nil then
			mobasideplayercount['GDI'] = 1
		else
			mobasideplayercount['GDI'] = mobasideplayercount['GDI'] + 1
		end
	elseif ObjectHasUpgrade(self, "Upgrade_TeamNOD") == 1 then
		if mobasideplayercount['NOD'] == nil then
			mobasideplayercount['NOD'] = 1
		else
			mobasideplayercount['NOD'] = mobasideplayercount['NOD'] + 1
		end
	end
end

-- ... for Spotter
function OnSpotterPodCreated_renwars(self)
	local p = getPlayerId(self) -- Get Player id
	local a = getObjectId(self) -- Get Object id
	
	mobaspawnreg1[p] = a
end

-- Respawn hero when event received by spawner from respawntimer expiration
function OnHeroRespawnReceived_renwars(self,other)
	local p = getPlayerId(other) -- Get Player id
	local a = getObjectId(self) -- Get Object id

	if mobaspawnreg[p] == a then -- is the player sending me this event my original owner?
		local x = ObjectDescription(self)		
		-- name format for hashes: xherospawner
		if strfind(tostring(x), "39AD8F99") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_GDICommando")		
		elseif strfind(tostring(x), "4E380E3") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_GDISniper")	
		elseif strfind(tostring(x), "2ACFEFEE") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_SteelTalonsCombatEngineer")
		elseif strfind(tostring(x), "BED572B3") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_ZOCOMZoneraider")		
		elseif strfind(tostring(x), "F832E9CB") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_GDIGrenadeSoldier")			
		elseif strfind(tostring(x), "C73350AA") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_NODCommando")			
		elseif strfind(tostring(x), "9AED1CE5") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_NODBlackhand")			
		elseif strfind(tostring(x), "C89E8B6C") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_NODFanatic")			
		elseif strfind(tostring(x), "25F09BF7") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_NODShadow")
		elseif strfind(tostring(x), "E3683DA3") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_MarkedOfKaneCommando")			
		elseif strfind(tostring(x), "C642D841") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_T59Prodigy")			
		end
	end
end

-- Respawn hero when buyback event received by spawner from respawntimer
function OnHeroBuyBackReceived_renwars(self,other)	
	local p = getPlayerId(other) -- Get Player id
	local a = getObjectId(self) -- Get Object id

	if mobaspawnreg[p] == a then -- is the player sending me this event my original owner?
		local p1 = getPlayerName(self) -- Get Player name
		ExecuteAction("SHOW_MILITARY_CAPTION", "**** Player " .. tostring(p1) .. " has used buyback! ****", 5)		

		local x = ObjectDescription(self)		
		-- name format for hashes: xherospawner
		if strfind(tostring(x), "39AD8F99") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_GDICommando")		
		elseif strfind(tostring(x), "4E380E3") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_GDISniper")	
		elseif strfind(tostring(x), "2ACFEFEE") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_SteelTalonsCombatEngineer")
		elseif strfind(tostring(x), "BED572B3") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_ZOCOMZoneraider")			
		elseif strfind(tostring(x), "F832E9CB") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_GDIGrenadeSoldier")			
		elseif strfind(tostring(x), "C73350AA") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_NODCommando")			
		elseif strfind(tostring(x), "9AED1CE5") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_NODBlackhand")			
		elseif strfind(tostring(x), "C89E8B6C") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_NODFanatic")			
		elseif strfind(tostring(x), "25F09BF7") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_NODShadow")
		elseif strfind(tostring(x), "E3683DA3") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_MarkedOfKaneCommando")
		elseif strfind(tostring(x), "C642D841") ~= nil then
			ObjectCreateAndFireTempWeapon(self, "Respawn_T59Prodigy")						
		end
	end
end

-- When spawner gets GRSDeath event, check ownership vs reg and delete self if different
function OnGRSDeathReceived1_renwars(self,other)
	local p = getPlayerId(other) -- Get Player id
	local a = getObjectId(self) -- Get Object id

	if mobaspawnreg[p] ~= a then -- is my current owner my original owner?
		ExecuteAction("SHOW_MILITARY_CAPTION", "Hero eliminated!",4)			
		ExecuteAction("NAMED_DELETE", self)	 		
	end
end
-- When hero gets GRSDeath event, check ownership vs reg and delete self if different
function OnGRSDeathReceived2_renwars(self,other)
	local p = getPlayerId(other) -- Get Player id
	local a = getObjectId(self) -- Get Object id

	if mobaheroreg[p] ~= a then -- is my current owner my original owner?
		ExecuteAction("SHOW_MILITARY_CAPTION", "Hero eliminated!",4)			
		ExecuteAction("NAMED_DELETE", self)	 		
	end
end
-- When respawntimer gets GRSDeath event, check ownership vs reg and delete self if different
function OnGRSDeathReceived3_renwars(self,other)
	local p = getPlayerId(other) -- Get Player id
	local a = getObjectId(self) -- Get Object id

	if mobarespawntimerreg[p] ~= a then -- is my current owner my original owner?
		ExecuteAction("SHOW_MILITARY_CAPTION", "Hero eliminated!",4)			
		ExecuteAction("NAMED_DELETE", self)	 		
	end
end

-- FOR SPOTTER
-- Respawn spotter when event received from respawntimer expiration
function OnSpotterRespawnReceived_renwars(self,other)
	local p = getPlayerId(other) -- Get Player id
	local a = getObjectId(self) -- Get Object id	

	if mobaspawnreg1[p] == a then -- is the player sending me this event my original owner?
		ObjectCreateAndFireTempWeapon(self, "Respawn_GDISpotter")				
	end
end


-- When spawner gets GRSDeath event, check ownership vs reg and delete self if different
function OnSpotterGRSDeathReceived1_renwars(self,other)
	local p = getPlayerId(other) -- Get Player id
	local a = getObjectId(self) -- Get Object id

	if mobaspawnreg1[p] ~= a then -- is my current owner my original owner?
		ExecuteAction("NAMED_DELETE", self)	 		
	end
end
-- When spotter gets GRSDeath event, check ownership vs reg and delete self if different
function OnSpotterGRSDeathReceived2_renwars(self,other)
	local p = getPlayerId(other) -- Get Player id
	local a = getObjectId(self) -- Get Object id

	if mobaheroreg1[p] ~= a then -- is my current owner my original owner?
		ExecuteAction("NAMED_DELETE", self)	 		
	end
end
-- When respawntimer gets GRSDeath event, check ownership vs reg and delete self if different
function OnSpotterGRSDeathReceived3_renwars(self,other)
	local p = getPlayerId(other) -- Get Player id
	local a = getObjectId(self) -- Get Object id

	if mobarespawntimerreg1[p] ~= a then -- is my current owner my original owner?
		ExecuteAction("NAMED_DELETE", self)	 		
	end
end

-- ====================== MARKET FUNCTIONS =================
function OnMarket1Enter_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "Market1SpawnWeapon")
end
function OnMarket1Exit_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "Market1KillWeapon")
end

function OnMarket2Enter_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "Market2SpawnWeapon")
end
function OnMarket2Exit_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "Market2KillWeapon")
end

function OnMarket3Enter_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "Market3SpawnWeapon")
end
function OnMarket3Exit_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "Market3KillWeapon")
end

-- ================= GAME MANAGER ============
function OnGameManagerCreated_renwars(self)
	ExecuteAction("SHOW_MILITARY_CAPTION", "Game Manager init...", 5)
	ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", self, "USER_7", 25, 100)	
end

function OnGameManagerTimerEnd_renwars(self)
	--ExecuteAction("SHOW_MILITARY_CAPTION", "GDI: " .. mobasideplayercount['GDI'] .. " NOD: " .. mobasideplayercount['NOD'], 5)		
end


function OnHeroSelectorDestroyed_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_HeroSelected") == 1 then
		ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy")		
	
		g = mobasideplayercount['GDI']
		n = mobasideplayercount['NOD']
		if ObjectHasUpgrade(self, "Upgrade_TeamGDI") == 1 then
			if n == 2 and g == 1 then
				ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy1v2")
				ObjectBroadcastEventToAllies(self,"OnTowerLevelUpgrade1",99999)				
			elseif n == 3 and g == 1 then
				ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy1v3")
				ObjectBroadcastEventToAllies(self,"OnTowerLevelUpgrade2",99999)				
			elseif n == 4 and g == 1 then
				ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy1v4")
				ObjectBroadcastEventToAllies(self,"OnTowerLevelUpgrade3",99999)				
			elseif n == 3 and g == 2 then
				ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy2v3")		
				ObjectBroadcastEventToAllies(self,"OnTowerLevelUpgrade1",99999)				
			elseif n == 4 and g == 2 then
				ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy2v4")
				ObjectBroadcastEventToAllies(self,"OnTowerLevelUpgrade2",99999)				
			elseif n == 4 and g == 3 then
				ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy3v4")
				ObjectBroadcastEventToAllies(self,"OnTowerLevelUpgrade1",99999)				
			end
		elseif ObjectHasUpgrade(self, "Upgrade_TeamNOD") == 1 then
			if g == 2 and n == 1 then
				ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy1v2")
				ObjectBroadcastEventToAllies(self,"OnTowerLevelUpgrade1",99999)				
			elseif g == 3 and n == 1 then
				ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy1v3")
				ObjectBroadcastEventToAllies(self,"OnTowerLevelUpgrade2",99999)				
			elseif g == 4 and n == 1 then
				ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy1v4")		
				ObjectBroadcastEventToAllies(self,"OnTowerLevelUpgrade3",99999)				
			elseif g == 3 and n == 2 then
				ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy2v3")		
				ObjectBroadcastEventToAllies(self,"OnTowerLevelUpgrade1",99999)				
			elseif g == 4 and n == 2 then
				ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy2v4")
				ObjectBroadcastEventToAllies(self,"OnTowerLevelUpgrade2",99999)				
			elseif g == 4 and n == 3 then
				ObjectCreateAndFireTempWeapon(self, "AutoDepositDummy3v4")
				ObjectBroadcastEventToAllies(self,"OnTowerLevelUpgrade1",99999)				
			end
		end	
	end
end

-- =================== GRS VETERANCY AND MISC =====================
-- Global hero upgrades granted on GRS veterancy
function OnGRS21_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "HeroUpgrade1")		
end
function OnGRS22_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "HeroUpgrade2")
end
function OnGRS23_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "HeroUpgrade3")
end
function OnGRS24_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "HeroUpgrade4")
end
function OnGRS25_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "HeroUpgrade5")
end
function OnGRS26_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "HeroUpgrade6")
end
function OnGRS27_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "HeroUpgrade7")		
end
function OnGRS28_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "HeroUpgrade8")	
end
function OnGRS29_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "HeroUpgrade9")	
end
function OnGRS30_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "HeroUpgrade10")	
end


-- Call HH, spawns HHCounter at GRS which controls the actual HH OCL SP
function OnCallHH_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "CallHHWeapon")			
end
function OnCallCFT_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "CallCFTWeapon")			
end
function OnCallMantis_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "CallMantisWeapon")			
end
function OnCallFlametank_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "CallFlametankWeapon")			
end
function OnCallPredator_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "CallPredatorWeapon")			
end
function OnCallDevastator_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "CallDevastatorWeapon")			
end


-- On GRS Death (player quit), broadcast event to heroes and spawners, 
-- triggering them to check their current ownership
function OnGRSDeath_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnGRSDeathReceived",99999)
end


-- Error checker
function OnErrorChecker_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ErrorCheckerWeapon")
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Hi, I'm a flying bird...",3)		
end
function OnErrorChecker1_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnErrorChecker",99999)
	--ObjectCreateAndFireTempWeapon(self, "ErrorCheckerWeapon1")		
end
-- ======================== MANA FUNCTIONS =====================
-- to subtract mana on ability use
function OnUseMana2_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "UseMana2")	
	end
end
function OnUseMana5_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "UseMana5")	
	end
end
function OnUseMana10_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "UseMana10")	
	end
end
function OnUseMana15_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "UseMana15")	
	end
end
function OnUseMana20_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "UseMana20")	
	end
end
function OnUseMana25_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "UseMana25")
	end
end
function OnUseMana30_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "UseMana30")
	end
end
function OnUseMana35_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "UseMana35")
	end
end

-- based on mana levels, grant/remove local upgrades for PowerManager
function OnMana5_renwars(self) -- "I have less <5 mana"
	ObjectGrantUpgrade(self, "Mana_5L")
	ObjectBroadcastEventToAllies(self,"OnSniperNestDestroyed",99999) -- kill sniper nest	
end
function OnMana5End_renwars(self) -- "I have >5 mana"
	ObjectRemoveUpgrade(self, "Mana_5L")
	ObjectCreateAndFireTempWeapon(self, "Mana5")	
end
function OnMana10_renwars(self)
	ObjectGrantUpgrade(self, "Mana_10L")	
end
function OnMana10End_renwars(self)
	ObjectRemoveUpgrade(self, "Mana_10L")
	ObjectCreateAndFireTempWeapon(self, "Mana10")			
end
function OnMana15_renwars(self)
	ObjectGrantUpgrade(self, "Mana_15L")	
end
function OnMana15End_renwars(self)
	ObjectRemoveUpgrade(self, "Mana_15L")
	ObjectCreateAndFireTempWeapon(self, "Mana15")	
end
function OnMana20_renwars(self)
	ObjectGrantUpgrade(self, "Mana_20L")	
end
function OnMana20End_renwars(self)
	ObjectRemoveUpgrade(self, "Mana_20L")	
	ObjectCreateAndFireTempWeapon(self, "Mana20")		
end
function OnMana25_renwars(self)
	ObjectGrantUpgrade(self, "Mana_25L")	
end
function OnMana25End_renwars(self)
	ObjectRemoveUpgrade(self, "Mana_25L")		
	ObjectCreateAndFireTempWeapon(self, "Mana25")		
end
function OnMana30_renwars(self)
	ObjectGrantUpgrade(self, "Mana_30L")	
end
function OnMana30End_renwars(self)
	ObjectRemoveUpgrade(self, "Mana_30L")
	ObjectCreateAndFireTempWeapon(self, "Mana30")	
end
function OnMana35_renwars(self)
	ObjectGrantUpgrade(self, "Mana_35L")	
end
function OnMana35End_renwars(self)
	ObjectRemoveUpgrade(self, "Mana_35L")
	ObjectCreateAndFireTempWeapon(self, "Mana35")			
end

-- Special case for negative mana
function OnManaNegative_renwars(self)
	ObjectGrantUpgrade(self, "Mana_0")				
end
function OnManaNegativeEnd_renwars(self)
	ObjectRemoveUpgrade(self, "Mana_0")
end


-- Update the power display by creating dummy units
function OnManaShow0_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow0")	
end
function OnManaShow5_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow5")	
end
function OnManaShow10_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow10")	
end
function OnManaShow15_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow15")	
end
function OnManaShow20_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow20")	
end
function OnManaShow25_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow25")	
end
function OnManaShow30_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow30")	
end
function OnManaShow35_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow35")	
end
function OnManaShow40_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow40")	
end
function OnManaShow45_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow45")	
end
function OnManaShow50_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow50")	
end
function OnManaShow55_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow55")	
end
function OnManaShow60_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow60")	
end
function OnManaShow65_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow65")	
end
function OnManaShow70_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow70")	
end
function OnManaShow75_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow75")	
end
function OnManaShow80_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow80")	
end
function OnManaShow85_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow85")	
end
function OnManaShow90_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow90")	
end
function OnManaShow95_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow95")	
end
function OnManaShow100_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ManaShow100")	
end


-- ================= HERO STATUS UPGRADES ================

-- Hero silenced
function OnHeroSilenced_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnSilencedReceived",11)
end
function OnHeroSilencedEnd_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnSilencedEndReceived",11)
end
-- SPDrone receive silence event
function OnSilencedReceived_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectGrantUpgrade(self, "Upgrade_StructureLevel1")
		--ExecuteAction("SHOW_MILITARY_CAPTION", "Silenced",3)			
	end
end
function OnSilencedEndReceived_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectRemoveUpgrade(self, "Upgrade_StructureLevel1")
		--ExecuteAction("SHOW_MILITARY_CAPTION", "Not Silenced",3)	
	end
end


-- Hero stealthed
function OnHeroStealthed_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnStealthedReceived",11)
end
function OnHeroStealthedEnd_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnStealthedEndReceived",11)
end
-- SPDrone receive stealth event
function OnStealthedReceived_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectGrantUpgrade(self, "Upgrade_CloakingFieldInvisibility")
		--ExecuteAction("SHOW_MILITARY_CAPTION", "Stealthed",3)			
	end
end
function OnStealthedEndReceived_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectRemoveUpgrade(self, "Upgrade_CloakingFieldInvisibility")
		--ExecuteAction("SHOW_MILITARY_CAPTION", "Not Stealthed",3)	
	end
end


-- SPDrone created...
function OnSPDroneCreated_renwars(self)
	-- nothing
end

-- SPDrone firing SP
function OnSPDroneFiring_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnSPDroneFiringReceived",11)
end
function OnSPDroneFiringEnd_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnSPDroneFiringEndReceived",11)
end
-- Hero receive SPDrone firing event
function OnSPDroneFiringReceived_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectGrantUpgrade(self, "Upgrade_UsingSPUpdate")
		--ExecuteAction("SHOW_MILITARY_CAPTION", "Silenced",3)			
	end
end
function OnSPDroneFiringEndReceived_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectRemoveUpgrade(self, "Upgrade_UsingSPUpdate")
		--ExecuteAction("SHOW_MILITARY_CAPTION", "Not Silenced",3)	
	end
end


-- When under tree cover
function OnCover_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_StructureLevel1")
end
-- When out of tree cover
function OnCoverEnd_renwars(self)
	ObjectRemoveUpgrade(self, "Upgrade_StructureLevel1")
end

-- Unselectable/garrisoned...
function OnUnselectable_renwars(self)
	ObjectRemoveUpgrade(self, "Upgrade_StructureLevel1")
	ExecuteAction("SHOW_MILITARY_CAPTION", "I am garrisoned...",3)	
end

-- Finding attacker/target
function OnHeroAttacked_renwars(self,other)
	local p = getPlayerId(self)
	mobadmgtracker[p] = other	-- store the current attacker
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Attacked by: " .. p2, 2)	
	
	ObjectBroadcastEventToAllies(self,"OnHeroAttacked",99999)
end

function OnHeroAttackedDoT_renwars(self,other)
	local p = getPlayerId(self)	
	mobadmgtracker[p] = other	-- store the current attacker

	--ObjectBroadcastEventToAllies(self,"OnHeroAttacked",99999)
end

-- When hero attacked while in transport (NOTE: for whatever stupid reason ObjectHasUpgrade not working!!?!)
function OnTransportAttacked_renwars(self,other)
	if ObjectTestModelCondition(self, "USER_2") == true then -- hero inside
		local p = getPlayerId(self)	
		mobadmgtracker[p] = other	-- store the current attacker
	
		ObjectBroadcastEventToAllies(self,"OnHeroAttacked",99999)
		--ExecuteAction("SHOW_MILITARY_CAPTION", ObjectDescription(self) .. " holding hero and under attack", 3)		
	end
end

function OnTransportAttackedDoT_renwars(self,other)
	if ObjectTestModelCondition(self, "USER_2") == true then -- hero inside
		local p = strsub(ObjectDescription(self),strfind(ObjectDescription(self), "owned by ") + 9)	
		mobadmgtracker[p] = other	-- store the current attacker
	
		--ObjectBroadcastEventToAllies(self,"OnHeroAttacked",99999)
		--ExecuteAction("SHOW_MILITARY_CAPTION", ObjectDescription(self) .. " holding hero and under attack", 3)		
	end
end

-- Transport upgrade when hero inside
function OnTransportHero_renwars(self)
	ObjectGrantUpgrade( self, "Upgrade_StructureLevel1")
	ObjectCreateAndFireTempWeapon(self, "DeployTransportHeroPodWeapon")	
	--ExecuteAction("SHOW_MILITARY_CAPTION", "transporting hero", 3)		
end
function OnTransportHeroEnd_renwars(self)
	ObjectRemoveUpgrade( self, "Upgrade_StructureLevel1")
	ObjectBroadcastEventToAllies(self,"OnTransportHeroEndReceived",20)	
	--ExecuteAction("SHOW_MILITARY_CAPTION", "not transporting hero", 3)			
end

-- remove the big radar dot dummy on transport
function OnTransportHeroEndReceived_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ExecuteAction("NAMED_KILL",self)
	end
end


-- Shadow glider upgrade
function OnShadowGlider_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_ShadowGlider")
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", x, "SpecialPower_GliderLand", 0.5)	
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", x, "SpecialPower_GliderTakeOff", 0.5)		
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Flying...",3)	
end
function OnShadowGliderEnd_renwars(self)
	ObjectRemoveUpgrade(self, "Upgrade_ShadowGlider")
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", x, "SpecialPower_GliderLand", 0.5)	
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", x, "SpecialPower_GliderTakeOff", 0.5)			
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Not Flying...",3)	
end

function OnShadowMastery_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_ShadowMastery")
	ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", self, "USER_5", 1.5, 100)
	--ExecuteAction("SHOW_MILITARY_CAPTION", "ShadowMastery...",3)	
end
function OnShadowMasteryEnd_renwars(self)
	ObjectRemoveUpgrade(self, "Upgrade_ShadowMastery")
	--ExecuteAction("SHOW_MILITARY_CAPTION", "ShadowMastery END...",3)	
end

-- Fanatic disguise trigger
function OnDisguiseTrigger_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana5") -- manacost
	ObjectGrantUpgrade(self, "Upgrade_FanaticDisguise")	
end
function OnDisguiseEndTrigger_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana5") -- manacost
	ObjectGrantUpgrade(self, "Upgrade_FanaticDisguiseNone")	
end

-- Fanatic disguise enable
function OnDisguise_renwars(self)
	if ObjectTestModelCondition(self, "USER_73") == true then -- If on teamGDI...
		ObjectGrantUpgrade(self, "Upgrade_FanaticDisguiseGDI") -- GDI Rifleman disguise	
	else -- If on teamNOD...
		ObjectGrantUpgrade(self, "Upgrade_FanaticDisguiseNOD") -- Nod Militant disguise
	end
	OnDisguiseReset_renwars(self)	
end
-- Fanatic disguise disable
function OnDisguiseEnd_renwars(self)
	ObjectRemoveUpgrade(self, "Upgrade_FanaticDisguiseGDI") -- Disable GDI disguise
	ObjectRemoveUpgrade(self, "Upgrade_FanaticDisguiseNOD") -- Disable NOD disguise	
	OnDisguiseReset_renwars(self)
	ExecuteAction("SOUND_PLAY_NAMED", "NOD_DisguiseEnd", self)	
end
-- reset cds
function OnDisguiseReset_renwars(x)
	if ObjectHasUpgrade(x, "Upgrade_FusionCore") == 1 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", x, "FanaticDisguise", 1.5)	
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", x, "FanaticDisguiseEnd", 1.5)			
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", x, "FanaticDisguise", 2)	
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", x, "FanaticDisguiseEnd", 2)			
	end
	
	if ObjectHasUpgrade(x, "Upgrade_HeroUpgrade") == 1 then
	
	end
end

-- Shield update
function OnShieldTrigger_renwars(self)
	ObjectRemoveUpgrade(self, "Upgrade_StructureLevel3")
	ObjectGrantUpgrade(self, "Upgrade_StructureLevel3")
end
function OnShieldBegin_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "ForcefieldDebufferWeapon")
end
function OnShieldEnd_renwars(self)
	ObjectRemoveUpgrade(self, "Upgrade_StructureLevel3")
	ObjectBroadcastEventToAllies(self,"OnForcefieldDestroyed",99999)	
end

-- CloakPod upgrade
function OnUpgradeCloak_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "DeployCloakPodWeapon")
end

-- Fanatic Tib infusion
function OnTibInfusion_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "TibInfPodWeapon")		

	if ObjectHasUpgrade( self, "Upgrade_HeroUpgrade" ) == 1 then	
		ObjectCreateAndFireTempWeapon(self, "TibInfPodWeapon_Upgraded")
	end
end

function OnTibInfusionAlly_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "TibInfPodAllyWeapon")
end
function OnTibInfusionAllyHero_renwars(self)
	local x = ObjectDescription(self)

	if  strfind(tostring(x), "30D0C6EC") ~= nil then
		-- do nothing if Fanatic
	else
		ObjectCreateAndFireTempWeapon(self, "TibInfPodAllyWeapon_Hero")
	end
end

-- Blackhand Hero
function OnCPBMode_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana15Trigger")
end

function OnWarcry_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "WarcryPodWeapon") -- mana use triggered in weapon
end

function OnConfessorAmbushTrigger_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana25Trigger")
	ObjectCreateAndFireTempWeapon(self, "ConfessorAmbushWeapon")
	ObjectCreateAndFireTempWeapon(self, "ConfessorAmbushVisionPodWeapon")	
	ExecuteAction("PLAY_SOUND_EFFECT", "NOD_SecretShrineSelect_new")	
end

-- Grant attach upgrade (and modelcondition) when attached to enemy hero
function OnConfessorAmbushPrep_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_StructureLevel1")
	ObjectCreateAndFireTempWeapon(self, "ConfessorAmbushPodKillWeapon")	
end
-- If pod expires and is attached, then spawn Confessor
function OnConfessorAmbush_renwars(self) 
	if ObjectTestModelCondition(self, "USER_20") == true then
		ObjectCreateAndFireTempWeapon(self, "ConfessorAmbushWarhead")
	end
end
function OnConfessorAmbushVision_renwars(self) 
	ObjectDoSpecialPower(self, "SpecialPower_PowerSignatureScan")
end


-- Zoneraider Hero
function OnMjolnirStrikeCreated_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana25Trigger")
end

function OnDropPodCreated_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "UseMana30Trigger")
end


-- Hero suicide (kill)
function OnHeroSuicide_renwars(self)
	ExecuteAction("NAMED_KILL", self)
end

-- Firewall 
function OnFirewallStart_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "FirewallEnergyDrainTriggerWeapon")		
end
function OnFirewallStop_renwars(self)
	ObjectBroadcastEventToAllies(self, "OnFirewallStop", 9999)
end
function OnFirewallDie_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)

	if p1 == p2 then
		ExecuteAction("NAMED_KILL", self)
		--ExecuteAction("SHOW_MILITARY_CAPTION", "Firewall stop...", 3)		
	end
end

-- Nod Commando Hero
function OnRangedMode_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "RangedModePodWeapon") -- mana use triggered in weapon
	ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RangedMode", 12)	
end

function OnFrenzyMode_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "FrenzyModePodWeapon") -- mana use triggered in weapon
end

function OnSpawnClones_renwars(self) 
	if ObjectHasUpgrade( self, "Upgrade_HeroUpgrade" ) == 1 then
		ObjectCreateAndFireTempWeapon(self, "SpawnClonesWeapon_Upgraded")
	else
		ObjectCreateAndFireTempWeapon(self, "SpawnClonesWeapon")	
	end
end

function OnSpawnClonesAlly_renwars(self)

	local x = ObjectDescription(self)

	if strfind(tostring(x), "DCB85878") ~= nil then
		ObjectCreateAndFireTempWeapon(self, "SpawnClonesWeapon_GDICommando")	
	elseif  strfind(tostring(x), "A8269A36") ~= nil then
		ObjectCreateAndFireTempWeapon(self, "SpawnClonesWeapon_GDISniper")	
	elseif  strfind(tostring(x), "80DFF5D9") ~= nil then
		ObjectCreateAndFireTempWeapon(self, "SpawnClonesWeapon_SteelTalonsCombatEngineer")	
	elseif  strfind(tostring(x), "9036C4A9") ~= nil then
		ObjectCreateAndFireTempWeapon(self, "SpawnClonesWeapon_ZOCOMZoneraider")	
	elseif  strfind(tostring(x), "89C62490") ~= nil then
		ObjectCreateAndFireTempWeapon(self, "SpawnClonesWeapon_NodBlackhand")	
	elseif  strfind(tostring(x), "30D0C6EC") ~= nil then
		ObjectCreateAndFireTempWeapon(self, "SpawnClonesWeapon_NodFanatic")	
	elseif  strfind(tostring(x), "8C67B9CE") ~= nil then
		ObjectCreateAndFireTempWeapon(self, "SpawnClonesWeapon_NodShadow")
	elseif strfind(tostring(x), "406C94AC") ~= nil then
		ObjectCreateAndFireTempWeapon(self, "SpawnClonesWeapon_MarkedOfKaneCommando")	
	end
end

function OnSpawnClonesDie_renwars(self, other) 
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ExecuteAction("NAMED_KILL", self)
	end
end

function OnDeceptionTrigger_renwars(self)
	ObjectDoSpecialPower(self, "SpawnDeception")
end

function OnSpawnDeception_renwars(self)
	--ExecuteAction("SHOW_MILITARY_CAPTION", "Spawn deception...", 5)			
	ObjectCreateAndFireTempWeapon(self, "SpawnDeceptionWeapon")
end


-- Guardian RGA self dmg weapon
function OnRGA_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "RGADamage")		
end


-- Radar scan upgrade
function OnUpgradeRadarScan_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "RadarScanCounterWeapon")
end

-- When upgraded, Pod created on hero via temp weapon
function OnUpgradeObelisk_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "DeployObeliskPodWeapon")
end

-- When upgraded, Pod created on hero via temp weapon
function OnUpgradeRocketBarrage_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "DeployRocketBarragePodWeapon")
end

-- When upgraded, Pod created on hero via temp weapon
function OnUpgradeShockwave_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "DeployShockwavePodWeapon")
end

-- When upgraded, Pod created on hero via temp weapon
function OnUpgradeLegsPod_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "DeployLegsPodWeapon")
end

-- When upgraded, Pod created on hero via temp weapon
function OnUpgradeArmorPod_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "DeployArmorPodWeapon")
end

-- EMPBurstDummy fires this weapon on death (essentially an unpack delay)
function OnFireEMPBurst_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "EMPBurst1")	
	if ObjectTestModelCondition(self, "USER_10") == true then	
		ObjectCreateAndFireTempWeapon(self, "EMPBurst2")	
	end
end


-- When upgraded, Radiance Pod created on hero via temp weapon
function OnUpgradeRadiance_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "DeployRadiancePodWeapon")
end
function OnUpgradeRadiance2_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "DeployRadiancePodUpgradedWeapon")
	ExecuteAction("NAMED_DELETE",self)
end

-- Pod receives hero moving events, and uses them for toggling weapon effects
function OnPodMoving_renwars(self,other)
	local p1 = strsub(ObjectDescription(other),strfind(ObjectDescription(other), "owned by ") + 9)
	local p2 = strsub(ObjectDescription(self),strfind(ObjectDescription(self), "owned by ") + 9)
	
	if p1 == p2 then
		ObjectRemoveUpgrade( self, "Upgrade_StructureLevel1" )	-- When moving, disable weapon effect
	end
end
function OnPodMovingEnd_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		ObjectGrantUpgrade( self, "Upgrade_StructureLevel1" )	-- When still, enable weapon effect
	end
end

-- Hero broadcasts this when moving
function OnHeroMoving_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnHeroMoving",20)
end
function OnHeroMovingEnd_renwars(self)
	ObjectBroadcastEventToAllies(self,"OnHeroMovingEnd",20)
end


-- ========== REGEN PODS =============
-- When regenpod purchased, send event to SPDrone
function OnRegenPodCreated_renwars(self)
	local p1 = getPlayerId(self)
	if mobaregenpods[p1] == nil then
	   mobaregenpods[p1] = 1
    else
       mobaregenpods[p1] = mobaregenpods[p1] + 1	
	end
	ObjectBroadcastEventToAllies(self, "OnRegenPodCreated", 99999)
end
-- SPDrone receive regenpodcreated event
function OnRegenPodCreatedReceived_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)

	-- Create a new caster object
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "RegenPodCounterWeapon")		
	end
end
-- When a pod is used, remaining casters receive event when main caster fires, adding to their cd
function OnRegenPodUsed_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	-- Add cd between uses
	if p1 == p2 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "RegenPod", 15.5)		
	end
end
-- If hero attacked, receive event from hero and kill pod
function OnRegenPodKill_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)

	if p1 == p2 then
		ExecuteAction("NAMED_KILL", self)
	end
end

function OnRegenPodDestroyed_renwars(self)
	local p1 = getPlayerId(self)
	if mobaregenpods[p1] == nil or mobaregenpods[p1] <= 0 then
	    mobaregenpods[p1] = 0
    else
        mobaregenpods[p1] = mobaregenpods[p1] - 1	
	end		
end

-- ============== ENERGY PODS =============
-- When Energypod purchased, send event to SPDrone
function OnEnergyPodCreated_renwars(self)
	local p1 = getPlayerId(self)
	if mobaenergypods[p1] == nil then
	   mobaenergypods[p1] = 1
    else
       mobaenergypods[p1] = mobaenergypods[p1] + 1	
	end
	ObjectBroadcastEventToAllies(self, "OnEnergyPodCreated", 99999)
end
-- SPDrone receive Energypodcreated event
function OnEnergyPodCreatedReceived_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)

	-- Create a new caster object
	if p1 == p2 then
		ObjectCreateAndFireTempWeapon(self, "EnergyPodCounterWeapon")		
	end
end
-- When a pod is used, remaining casters receive event when main caster fires, adding to their cd
function OnEnergyPodUsed_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)

	-- Add cd between uses
	if p1 == p2 then
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "EnergyPod", 20.5)		
	end
end
-- If hero attacked, receive event from hero and kill pod
function OnEnergyPodKill_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)

	if p1 == p2 then
		ExecuteAction("NAMED_KILL", self)
	end
end

function OnEnergyPodDestroyed_renwars(self)
	local p1 = getPlayerId(self)
	if mobaenergypods[p1] == nil or mobaenergypods[p1] <= 0 then
	    mobaenergypods[p1] = 0
    else
        mobaenergypods[p1] = mobaenergypods[p1] - 1	
	end		
end

-- ****************************
-- **** ARENA FUNCTIONS ***
function OnArenaInit_renwars(self)
	mobaarenamode = 1
end

-- *********** CTF FUNCTIONS ***********
-- Enable/Init CTF mode flag
function OnCTFInit_renwars(self)
	mobactfmode = 1
	local p1 = getPlayerId(self)
	mobactfbase[p1] = 1	
	mobactftimerteam[p1] = 0
end

-- When CTF in base, grant upgrade to say "My flag is in base"
function OnCTFBase_renwars(self)
	--ObjectRemoveUpgrade(self, "Upgrade_CTFBaseL")
	--ObjectCreateAndFireTempWeapon(self, "CTF_BaseDummy")
	local p1 = getPlayerId(self)
	mobactfbase[p1] = 1
end

-- When CTF out of base, remove upgrade to say "My flag is not in base"
function OnCTFBaseEnd_renwars(self)
	--ObjectGrantUpgrade(self, "Upgrade_CTFBaseL")
	--ExecuteAction("SHOW_MILITARY_CAPTION", "CTF NOT in base!", 5)		
	local p1 = getPlayerId(self)
	mobactfbase[p1] = 0	
	
	-- if out of base, create timer if it doesnt exist
	if mobactftimerteam[p1] == 0 then
		mobactftimerteam[p1] = 1
		ObjectBroadcastEventToAllies(self, "OnCTFTimerCreated", 99999)
	end
end

-- When event received, the timer dummy is created at dropzone
-- (so player can click on the public timer to see where he needs to drop the flag)
function OnCTFTimerCreated_renwars(self, other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)

	if p1 == p2 then	
		ObjectCreateAndFireTempWeapon(self, "CTF_TimerDummy")
	end
end

-- When CTF attached, spawn timer dummy
function OnCTFAttached_renwars(self)
	if ObjectHasUpgrade(self, "Upgrade_TeamGDI") == 1 then
		ExecuteAction("SHOW_MILITARY_CAPTION", "String:T1_CTF_Captured_MOBA", 5)
	elseif ObjectHasUpgrade(self, "Upgrade_TeamNOD") == 1 then
		ExecuteAction("SHOW_MILITARY_CAPTION", "String:T2_CTF_Captured_MOBA", 5)
	end	
end

-- When CTF detached/dropped
function OnCTFAttachedEnd_renwars(self)
	-- if CTF is still at base at time of detach, immediately return it
	if ObjectTestModelCondition(self, "USER_4") == true then
		if ObjectHasUpgrade(self, "Upgrade_TeamGDI") == 1 then
			ExecuteAction("SHOW_MILITARY_CAPTION", "String:T1_CTF_Returned_MOBA", 5)
		elseif ObjectHasUpgrade(self, "Upgrade_TeamNOD") == 1 then
			ExecuteAction("SHOW_MILITARY_CAPTION", "String:T2_CTF_Returned_MOBA", 5)
		end
		ExecuteAction("NAMED_KILL", self)
	-- otherwise, just show CTF dropped message (and wait for hero to return it via OnCTFReturn)
	else
		if ObjectHasUpgrade(self, "Upgrade_TeamGDI") == 1 then
			ExecuteAction("SHOW_MILITARY_CAPTION", "String:T1_CTF_Dropped_MOBA", 5)
		elseif ObjectHasUpgrade(self, "Upgrade_TeamNOD") == 1 then
			ExecuteAction("SHOW_MILITARY_CAPTION", "String:T2_CTF_Dropped_MOBA", 5)
		end
	end
end

-- When CTF expires/returns (only ways it can die), tell spawner to spawn new CTF
function OnCTFDestroyed_renwars(self)
	ObjectBroadcastEventToAllies(self, "OnCTFDestroyed", 99999)
	
	local p1 = getPlayerId(self)
	mobactftimer = mobactftimer - 1
	mobactftimerteam[p1] = 0
end

-- When CTF is at dropzone, check if scoring player has CTF at base, then update scoreboard and send event to kill flag 
function OnCTFScore_renwars(self)
	local p1 = getPlayerId(self)
	--if ObjectHasUpgrade(self, "Upgrade_CTFBase") == 1 then
	if mobactfbase[p1] == 1 then
		if ObjectHasUpgrade(self, "Upgrade_TeamGDI") == 1 then
			ExecuteAction("SHOW_MILITARY_CAPTION", "String:T1_CTF_Scored_MOBA", 5)
		elseif ObjectHasUpgrade(self, "Upgrade_TeamNOD") == 1 then
			ExecuteAction("SHOW_MILITARY_CAPTION", "String:T2_CTF_Scored_MOBA", 5)
		end	
		ObjectCreateAndFireTempWeapon(self, "CTF_ScoreFlag")		
		ObjectBroadcastEventToEnemies(self, "OnCTFScored", 99999)
	else
		--ExecuteAction("SHOW_MILITARY_CAPTION", "Your flag not in base...", 5)
	end
end

-- Kill ('return') CTF if not in base + unattached + near friendly hero
function OnCTFReturn_renwars(self)
	local p1 = getPlayerId(self)
	if ObjectTestModelCondition(self, "ATTACHED") == false and mobactfbase[p1] == 0 then	
		if ObjectHasUpgrade(self, "Upgrade_TeamGDI") == 1 then
			ExecuteAction("SHOW_MILITARY_CAPTION", "String:T1_CTF_Returned_MOBA", 5)
		elseif ObjectHasUpgrade(self, "Upgrade_TeamNOD") == 1 then
			ExecuteAction("SHOW_MILITARY_CAPTION", "String:T2_CTF_Returned_MOBA", 5)
		end			
		ExecuteAction("NAMED_KILL", self)
	end
end

-- If CTF destroyed (returned), timer dummy receives this event and dies.... or vice versa
function OnCTFKill_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)

	if p1 == p2 then	
		ExecuteAction("NAMED_KILL", self)
	end
end

-- CTF Timer set
function OnCTFTimerSet_renwars(self)
	mobactftimer = mobactftimer + 1	
	if mobactftimer > 1 then -- if other flag is already captured, grant less time for this flag
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "Timer_CTF", 120)
	else
		ExecuteAction("NAMED_SET_SPECIAL_POWER_COUNTDOWN", self, "Timer_CTF", 150)
	end
end

-- When CTF timer expires, send event to CTF to kill it, and also kill self
function OnCTFTimerExpired_renwars(self)
	local p1 = getPlayerId(self)

	if ObjectHasUpgrade(self, "Upgrade_TeamGDI") == 1 then
		ExecuteAction("SHOW_MILITARY_CAPTION", "String:T1_CTF_Returned_MOBA", 5)
	elseif ObjectHasUpgrade(self, "Upgrade_TeamNOD") == 1 then
		ExecuteAction("SHOW_MILITARY_CAPTION", "String:T2_CTF_Returned_MOBA", 5)
	end		
	ObjectBroadcastEventToAllies(self, "OnCTFTimerExpired", 99999)
	
	ExecuteAction("NAMED_KILL", self)	
end

-- Spawner spawns new CTF based on team
function OnCTFRespawn_renwars(self,other)
	local p1 = getPlayerId(other)
	local p2 = getPlayerId(self)
	
	if p1 == p2 then
		if ObjectHasUpgrade(self, "Upgrade_TeamGDI") == 1 then
			ObjectCreateAndFireTempWeapon(self, "Respawn_CTF_GDI")
		elseif ObjectHasUpgrade(self, "Upgrade_TeamNOD") == 1 then
			ObjectCreateAndFireTempWeapon(self, "Respawn_CTF_NOD")	
		end
	end
end

-- **************************

-- Nifty way of checking if a unit has changed teams (mindcontrolled)! An attached dummy is respawned whenever the parent changes sides,
-- thereby triggering this event.
function OnTeamSet_renwars(self)

	local a = getObjectId(self) -- Get Object id	

	if mobaunitteam[a] == nil then
		ObjectForbidPlayerCommands( self, true )	
		ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", self, "USER_69", 999999, 100)								
		
		mobaunitteam[a] = ObjectDescription(self)
		
		-- This is only checked the first time, because beyond that it gets unreliable...
		-- The modelconditions or team player upgrades are never cleared when the unit changes teams
		-- so we're better off tracking teams via variables here
		if ObjectTestModelCondition("USER_70", self) then
			mobaunitside[a] = 'GDI'
		elseif  ObjectTestModelCondition("USER_71", self) then
			mobaunitside[a] = 'NOD'		
		end
	else
		-- If we're mindcontrolled, allow player control
		if mobaunitteam[a] ~= ObjectDescription(self) then
			--ExecuteAction("SHOW_MILITARY_CAPTION", "team changed...", 2)
			ExecuteAction("UNIT_CLEAR_MODELCONDITION", self, "USER_69")				
			ObjectForbidPlayerCommands( self, false )
		else 
			-- If we're back on the original team, we should get back to doing our stuff
			if mobaunitside[a] == 'GDI' then
				ExecuteAction("UNIT_ATTACK_MOVE_TOWARDS_NEAREST_OBJECT_TYPE", self, "NOD_NBBHStatue" )			
			elseif mobaunitside[a] == 'NOD' then		
				ExecuteAction("UNIT_ATTACK_MOVE_TOWARDS_NEAREST_OBJECT_TYPE", self, "DCPHavoc01" )			
			end			
			--ExecuteAction("SHOW_MILITARY_CAPTION", "team reverted...", 2)		
			ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", self, "USER_69", 999999, 100)											
			ObjectForbidPlayerCommands( self, true )
		end
	end
end


-- Tower under attack: fires weapon which sends modifier to eva dummy
function OnTowerAttacked_renwars(self,other)
	ObjectCreateAndFireTempWeapon(self, "TowerAttackedWeapon")	
end
-- Tower destroyed: fires weapon which sends modifier to eva dummy
function OnTowerDestroyed_renwars(self)
	ObjectCreateAndFireTempWeapon(self, "TowerDestroyedWeapon")	
	
	-- Arena Mode: Watchtowers give pts when killed
	-- NOTE: Map object descriptions do NOT have hex names, they use actual gameobject names!!!!
	local x = ObjectDescription(self)
	if mobaarenamode == 1 then
		if strfind(tostring(x), "WatchTower") ~= nil then						
			ObjectCreateAndFireTempWeapon(self, "Arena_ScoreTower")		
		end
	end
end


function OnMOBAWatchTowerCreated_renwars(self)
	ObjectForbidPlayerCommands( self, true )
	ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", self, "USER_69", 999999, 100)
	
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_01", true )
	ObjectHideSubObjectPermanently( self, "MuzzleFlash_02", true )
	ObjectHideSubObjectPermanently( self, "UG_BASE", true )
	ObjectHideSubObjectPermanently( self, "B_UG_TURRET", true )
end

-- Tower disable player control
function OnTowerInit_renwars(self)
	ObjectForbidPlayerCommands( self, true )
	ExecuteAction("UNIT_SET_MODELCONDITION_FOR_DURATION", self, "USER_69", 999999, 100)
	--ExecuteAction("DISPLAY_TEXT", "Hi.......")
end

-- Tower immunity
function OnTowerImmunity_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_StructureLevel3")
end
function OnTowerImmunityEnd_renwars(self)
	ObjectRemoveUpgrade(self, "Upgrade_StructureLevel3")
end

-- Tower level upgrade
function OnTowerLevelUpgrade1_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_TowerLevel1")
end
function OnTowerLevelUpgrade2_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_TowerLevel1")
	ObjectGrantUpgrade(self, "Upgrade_TowerLevel2")	
end
function OnTowerLevelUpgrade3_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_TowerLevel1")
	ObjectGrantUpgrade(self, "Upgrade_TowerLevel2")
	ObjectGrantUpgrade(self, "Upgrade_TowerLevel3")
end

-- Boss creep invincibility
function OnBossSleep_renwars(self)
	ObjectGrantUpgrade(self, "Upgrade_StructureLevel3")
end
function OnBossAwake_renwars(self)
	ObjectRemoveUpgrade(self, "Upgrade_StructureLevel3")
end

function delete(self)
	ExecuteAction("NAMED_DELETE",self)
end

-- ################################################################

function print(output, display_time)
   if display_time == nil then display_time = 3 end
   output = tostring(output)
   ExecuteAction("SHOW_MILITARY_CAPTION", output, display_time)
end

function getSize(x)
	local len = 0
	for k,v in x do
		len = len + 1
	end	
	return len
end

function getPlayerId(x)
	return strsub(ObjectDescription(x),strfind(ObjectDescription(x), "owned by ") + 9) -- Player id
end

function getPlayerName(x)
	return strsub(ObjectDescription(x),strfind(ObjectDescription(x), "owned by ") + 16) -- Player full name
end

-- Extract just the player name from ObjectDescription output
-- Example: 'Object 3525 [(0,0)DCB85878, owned by player 3 (masterleaf)]' -> 'masterleaf'
function getPlayerNameExact(x)
	local desc = ObjectDescription(x)
	local startPos = strfind(desc, "%(")
	local endPos = strfind(desc, "%)")
	
	if startPos and endPos and endPos > startPos then
		-- Find the last occurrence of "(" before ")"
		local lastStartPos = startPos
		local nextPos = strfind(desc, "%(" , startPos + 1)
		while nextPos and nextPos < endPos do
			lastStartPos = nextPos
			nextPos = strfind(desc, "%(" , nextPos + 1)
		end
		
		-- Extract the name between the last "(" and ")"
		return strsub(desc, lastStartPos + 1, endPos - 1)
	end
	
	return nil
end

-- #################################################################

function startAIGDI(Object)
	--ExecuteAction("UNIT_GUARD_OBJECT", Object, "T1_TopTower1")
end

function startAINOD(Object)
	--ExecuteAction("UNIT_GUARD_OBJECT", Object, "T2_TopTower1")
end

-- ---------------------------------------------------------------
