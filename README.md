# 1.02+ XML files
Due to the amount of time and effort I’ve invested in R24, I’m asking that other patches do not use or incorporate my work for the next few months. I’d like the focus to remain on 1.02+ during this period.
In the future, I’m open to sharing, but I want to avoid situations where my work is reused immediately after release. Given the level of investment involved, I believe this is a reasonable request.

This cannot be compiled as a standalone mod as it does not contain all of the 1.02+ files, only the ones I have modified or added over the years.

# R24q Changelog

## Balance Changes

* Shock Trooper hp reduced from 400 to 360.
* Scrin, Reaper-17 Shock Trooper/Ravager speed increased by 10%~.
* Storm Columns now one shot Firehawks again but no longer deal splash damage to aircraft.
* Infestation Hives are now sellable, hp increased by 10%.
* Wormhole cost increased from 2000$ to 3500$.

## Bug Fixes

* Traveler Engines are no longer visible on damaged unupgraded Scrin warships, it now also shows when buffed by an Ion Storm.
* Minor audio issues have been fixed.

## Reverse Move Fix Improvements

* Doing reverse move commands in quick succession will no longer prevent the reverse move fix from taking place.
* Changes have been made to reduce the likelihood of a desync occurring.

## R24p Changelog

### Balance Changes

* Shock Trooper Plasma Disc Launcher upgrade cost increased from $1000 to $1500. Upgrade research time increased from 30s to 45s.
* Storm Columns no longer one shots non ceramic armour Firehawks.
* Ravager gun armor increased by 25%.
* Grenadier damage increased by 10%, projectile speed increased by 5%.
* MARV grenade hardpoint damage increased by 10%.

### Bug Fixes

* Fixed an issue where many objects had missing death sounds.

### Reverse Move Fix Improvements

* Units that stop before receiving a move command followed by a reverse move now properly detect reverse bugs.
* Bugged units will stop upon reaching their leader instead of continuing to chase.
* Added a new false-positive detector that prevents units from being flagged for reverse-move bugs when reversing in their current movement direction.
* Units that attack before reverse-moving will no longer be incorrectly flagged as bugging if given another reverse command.
* Fixed an issue where units pending a fix were delayed by units stuck in turn events.
* Fixed units now move 5% faster after correction.
* Improved detection parameters for:

  * Stealth Tank
  * Shatterer
  * APC
  * Pitbull
* Cleaned up group ID tables and improved desync handling.

## R24m Changelog

* Fixed a desync caused by players who played games and then switched to Observer/Commentator.
* Unit anchor assignment improvements. Now checks for a nearby unit in the same group and if none is found, selects a random unit from that group. This prevents units moving towards enemy units if situated at the back of a group.
* Fixed an issue where units that never reverse bugged were incorrectly detected as such.
* Small group selections are no longer aggressively canceled by the reverse move fix.
* Other small tweaks and optimizations have been made to the reverse move workaround.

## R24k Changelog

* Fixed a desync caused by players switching to maps with a different player count than previously.
* Fixed an issue causing some units such as the GDI Predator Tank to not receive reverse bug fixes on certain maps.

## R24j Changelog

* Fixed a desync caused by players switching to maps with a different player count than previously.
* Fixed an issue in R24 causing harvesters to sometimes follow other units on the map.

## R24i Changelog

* Fixed an issue causing single unit selections to stop moving.
* Fixed another desync caused by Carryalls leaving the map, resulting in cleanup never happening.
* Fixed an R24 issue which resulted in Dozer Blade Scorpion Tanks having no immunity to mine damage.
* Crane cost has been increased from 1300$ to 1500$.
* Prodigy Area Mind Control max leash range increased from 300 to 350.
* APCs, Raider Buggies, Gunwalkers and Pitbulls have been optimized further for the reverse move fix.
* Fixed Reaper-17 Stormrider taxiing locomotor.

## R24h Changelog

* Desyncs have finally been fixed. Tested with 8 players to verify the fix.
* Addressed an issue causing units to behave erratically when reverse moved while standing still.

## R24g Changelog

* Fixed a desync issue caused by Engineer capturing, epic unit garrisoning.
* Fixed a desync issue caused by garrisoning the Eradicator Hexapod with a Mastermind/Prodigy.

## R24f Changelog

* Fixed an issue causing Sniper Teams and Mutant Marauders to be deleted straight away.
* Fixed an issue causing unit groups leaking if a unit recently came out of a War Factory or barracks.
* Fixed an issue causing unit groups to occasionally not be deleted if destroyed whilst reverse moving.
* Selected unit tables now get deleted from memory if a players unit selection count is 0.
* General cleanup and optimizations.
* The installer now properly ensures old patches files are cleaned up and that the game closes properly before installation.

## R24e Changelog

* Fixed a desync issue caused by squad based infantry not properly cleaning up after being destroyed.
* Improved reverse move behavior: units that hadn’t attempted to move after the last unit in the group is checked will now function correctly.
* Fixed an issue where reverse move groups did not clear properly when issuing a new reverse move command to a group already reversing.
* Units affected by the reverse move bug will now correctly stop in place if all units in the group are impacted.
* General cleanup and optimizations.
* The MARV no longer will exhibit strange turn behaviour.

## R24d Changelog

* Fixed a desync issue caused a typo made in R24c.

## R24c Changelog

* Fixed a desync issue caused by the MCV and Rig ReplaceSelf code deleting the unit before Lua can clean up.
* Fixed an issue causing Harvesters to attempt reverse bug detection while waiting to dock, caused by an uninitialized table.
* Added additional safety checks for unit anchors to ensure a nil value can never be used as a candidate (likely desync or crash cause).
* Additional clean up done to the reverse move script.

## R24b Changelog

* Units that are not moving or Harvesters that are docking will no longer attempt reverse bug detection.
* Seeker reverse bug detection sensitivity increased.
* The Fuel Depot on the map “Discovery” now explodes for 9000 grenade damage.
* Target Adjustments for AI usage of Stasis shield / Temporal Wormhole, Shockwave & Orbital Strike.
* The bridges now work properly on the “Arctic Circle”.
* The maps “Tournament Island II” and “Islands Temple” have been moved from the Legacy map pack to the 1vs1 map pack.
* Script date set in Command Post to prevent one player having a different version of the file, triggering a desync.

## R24 Changelog

* Reverse move bugging is now detected, affected units will automatically path toward another unit in the group. A modest speed boost is applied to affected units for 1.5s as they are being fixed.
* Stormriders now deal 25% additional damage against Mechapedes.
* Prodigy AOE Mind Control max cast range has been reduced from 400 to 300.
* Drone Ships can now crush Motherships again, formation preview fixed (R23 issue).
* Kane Edition Stormriders now show the correct damaged skin.
* An exploit involving the EMP Control Center has been fixed.
* Temporal Wormhole fire rate reduction reduced from 50% to 40%.
* Improvements have been implemented to enhance overall game stability and minimize the risk of crashes.
* Unit abilities and Support Powers for Skirmish AI that haven't been implemented since Tiberium Wars have been added for AI use.
* Titan geometry has been reduced slightly to fix a repeating error.

# R23x Changelog
* Mammoth Tank rockets now deal 300 damage vs all targets.
* Laser Scorpion Tanks now deal 10% less damage against Scorpion Tanks.
* Signature generator ability duration increased from 20s to 60s, cooldown increased from 1s to 60s. false positives doubled, radius doubled.
* Nod/BH/MoK Rocket Squad decoys no longer deal full damage sometimes.
* Temporal Wormhole duration reduced from 30s to 25s.
* Mechapede target priorities reverted to vanilla.
* Cannon damage taken by Ravagers reduced by 50%, Gun damage taken increased by 50%.
* Ravagers can no longer use Tiberium Agitation on other Ravagers.
* Ravager Tiberium Agitation damage vs Reaper Tripods, Devourer Tanks reduced by 50%.
* T59 Shock Trooper speed decreased by 15% 76.5 -> 65.
* Infestation hive hp increased by 50% 1000 -> 1500.
* Stasis Shield no longer tints phased units for a longer than expected duration.
* A new map made by UnderworldFox “Tournament Eclipse” has been added to the 1v1 map pack.
* Ranked support added for when Shatabrick returns.


# R23g Changelog
* Tiberium type detection while harvesting has been improved significantly. [Video Link](https://youtu.be/sA016u1djmI)  
* Ceramic Armor Hammerheads no longer show an extra model while dying.
* Nod factions Commando target selection changed to match the GDI Commando.
* Husks now play a notification to the owner of the player whose husk has been captured.
* An exploit resulting in Tiberium Crystals being harvestable indefinitely without depleting value has been fixed.

# R23f Changelog
* Husks no longer will play the sound “unit lost” when captured.
* Avatars and Purifiers will no longer become uncapturable for enemies.
* Cyborgs no longer take Tiberium exposure from Blue Tiberium.
* The map Dried Strait will no longer crash (applies to new R23f downloads only).

# R23e Changelog
* A crash caused by capturing husks has been fixed. [Video Link](https://youtu.be/fg4lEkjFOwI)
* A crash caused by garrisoning Hammerheads and Behemoths has been fixed.
* Husks will no longer exhibit a bug where they appear uncapturable.

# R23d Changelog
* Locomotors are no longer vanilla locomotors (R23 issue).

# R23c Changelog
* Zone Raiders can now kill friendly husks.
* Flame pilot fx is no longer visible on stealthed avatars.
* A mod specific bug related to Mechapedes being unaffected by the Rage Generator has been fixed.
* Geometry from the multiplayer beacon has been removed.
* Mechapede stealth detection range increased from 100 to 125.
* Redeemer Tiberium Trooper damage vs structures, husks increased from 100 to 144 per shot. Damage vs husks increased a further 250%.
* A bug, exploit involving GDI faction refineries has been fixed. [Video Link](https://www.youtube.com/watch?v=HRStmMIen38)
* Shard Photon Cannon damage scaler vs infantry increased from 50% to 75%.
* More unnecessary code removed.
* Nod Avatar stealth detection spotlight now displays properly.

# R23b Changelog
* A desync caused by garrisoning Rocket Squads into the Redeemer has been fixed.
* Players can no longer force fire an object to permanently deploy Specter Artillery and Juggernauts.
* Forcefields will no longer visually disappear at the edge of the screen.
* The maps Sands of Time, Bluezone Rampage, Bordertown Showdown have been fixed in this version.

# R23a Changelog
* The game should no longer exhibit frame drops whilst selecting Juggernauts, Specter Artillery or Beam Cannons, performance improved substantially compared to any version of Kane’s Wrath.
* Juggernauts, really damaged Specters now stealth again with Disruption Towers, Vertigo Disruption Pods.
* Stealth Tanks and Specter artillery can now be stealthed using the Cloaking Field support power (useful for when really damaged).
* The maps Wicked Ways, Bluezone Rampage, Bordertown Showdown, Desolated Resistance and Sands of Time have been updated by DesolatorTrooper.

# R23 Release Changelog

## General Changes

* Crane cost reduced from 1500$ to 1300$.
* Tweaks made to harvesters to increase health bar size have been made.
* Repair drone speed reduced from 100 to 75 (as it was in vanilla).
* Outpost unpack duration decreased from 20s to 15s. Outpost speed increased by 10%.
* EVA commands for all infantry squads should work properly now.
* Unwanted AI code removed from all missile and rocket squads.
* Tweaks made to reduce the chance of desyncs occurring vs AI skirmish online.
* Harvester locomotor turn radius increased from 15 to 25.
* A shader provided by theHostileNegotiator to restore Tiberium Wars muzzle flash fx and Scrin plasma disc launcher fx has been included.
* New maps made by DesolatorTrooper have been added:
    * **1vs1 Maps**
        * Deadweight
        * Wicked Ways
        * Sands of time
    * **2vs2 Maps**
        * BlueZone Rampage
        * Permafrost
    * **3v3/4v4 Maps**
        * Bordertown Showdown
        * Bordertown Beatdown Redux
        * Desolated Resistance
* The maps “Southland Shores”, “Purification Point”, “Maverick”, “Hell Bastion” and “Jade Gauntlet” have been updated by Aquatech.

## GDI

* Fixed shatterers being unable to kill allied husks.
* Fixed Juggernauts and Behemoths randomly un-deploying while using force fire.
* Increased the cooldown of Adaptive Armour from 10s to 15s so that players may have the opportunity to EMP enemy units once the effect wears off.
* The MARV now benefits from AP Ammo, increasing attack damage from 35 to 43 per shot (a 25% increase). [Video Link](https://youtu.be/FIiviegDRvI)
* MARV grenade launcher damage vs structures increased by 25%.
* The MARV Zone Trooper turret while railgun accelerated and grenadier turret now rotate towards the enemy whilst engaged.
* MARV sniper range increased from 450 to 470, reload time reduced by 10%.
* Railgun Accelerated Guardian Cannons no longer deal bonus damage on top of the RoF bonus.
* Titans now play the predator railgun attack sound while using railgun accelerators (R22 issue).
* The MARV now turns smoothly like in vanilla.

## Nod

* The damage dealt to husks from the Tiberium Trooper Redeemer hardpoint has been increased from 75 to 100.
* Tiberium Trooper damage against structures increased from 20 to 25 (25% increase).
* Fixed Specter Artillery randomly un-deploying while using force fire. [Video Link](https://youtu.be/_1s-9OmdYQE)
* Reckoners, after given an attack command will now reacquire targets if the target moves out of range.
* Tiberium Trooper Redeemer hardpoint damage to structures increased from 75 to 100.
* The Redeemer now benefits from Charged Particle Beam and Super Charged Particle Beam upgrade, dealing 80 damage per shot. The Super Charged Particle Beam also benefits from a 25% bonus against vehicles. [Video Link](https://youtu.be/h2K14Hf8g44)
* Redeemer rocket garrison damage against vehicles and structures increased by 35%.
* CRUSH damage now applies normally to Cyborg infantry.
* The Specter Artillery should no longer un-deploy after firing once using its bombard beacon special ability.

## Scrin

* Cultist capture range reduced from 250 to 235 (6% reduction).
* Players can no longer abuse an exploit to get multiple Cultist mind controls from a singular squad.
* Infestation hive hp increased by 60%, rocket armor doubled, survivability against gun damage decreased by 50% compared to the pre hp buff.
* Infestation hive cost increased from 800$ to 1000$.
* Infestation hive weapons now activate when any unit enters a Tiberium field.
* Infestation hives can no longer be sold but spawn a buzzer when destroyed.
* The Eradicator Hexapod attack animation will only play while using its main weapon.
* Shock Trooper speed increased by 10% (Advanced Articulators unaffected).
* Ravager speed increased by 10% (Advanced Articulators unaffected).
* Mastermind/Prodigy garrisons now scale for a cooldown reduction.
    * 1 Mastermind provides a 30s cooldown.
    * 2 Masterminds provides a 17s cooldown.
    * 3 Masterminds provides a 10s cooldown.
    * [Video Link](https://youtu.be/1RI0LLSKfx8)

## Neutral

* Viceroid veterancy added.
