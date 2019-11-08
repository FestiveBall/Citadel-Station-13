//Day/night subsystem ported from f13. Realistically, you need this to manipulate.
//Its own seperate lighting one day, something we discussed there and needed to do for... a year now, yeah?

/*  6:00 AM 	- 	21600
	6:45 AM 	- 	24300
	11:45 AM 	- 	42300
	4:45 PM 	- 	60300
	9:45 PM 	- 	78300
	10:30 PM 	- 	81000 */
#define CYCLE_SUNRISE 	216000
#define CYCLE_MORNING 	243000
#define CYCLE_DAYTIME 	423000
#define CYCLE_AFTERNOON 603000
#define CYCLE_SUNSET 	783000
#define CYCLE_NIGHTTIME 810000

GLOBAL_LIST_INIT(nightcycle_turfs, typecacheof(list(
	/turf/open/floor/plating/asteroid/snow/festivesnow,
	/turf/open/floor/plating/asteroid/snow/festivesnow/ice)))

SUBSYSTEM_DEF(nightcycle)
	name = "Day/Night Cycle"
	wait = 4
	//var/flags = 0			//see MC.dm in __DEFINES Most flags must be set on world start to take full effect. (You can also restart the mc to force them to process again
	can_fire = TRUE
	//var/list/timeBrackets = list("SUNRISE" = , "MORNING" = , "DAYTIME" = , "EVENING" = , "" = ,)
	var/currentTime
	var/sunColour
	var/sunPower
	var/sunRange
	var/currentColumn
	var/working = 3
	var/doColumns //number of columns to do at a time

/datum/controller/subsystem/nightcycle/fire(resumed = FALSE)
	if (working)
		doWork()
		return
	if (nextBracket())
		working = 1
		currentColumn = 1


/datum/controller/subsystem/nightcycle/proc/nextBracket()
	var/Time = STATION_TIME(FALSE)
	var/newTime

	switch (Time)
		if (CYCLE_SUNRISE 	to CYCLE_MORNING - 1)
			newTime = "SUNRISE"
		if (CYCLE_MORNING 	to CYCLE_DAYTIME 	- 1)
			newTime = "MORNING"
		if (CYCLE_DAYTIME 	to CYCLE_AFTERNOON	- 1)
			newTime = "DAYTIME"
		if (CYCLE_AFTERNOON to CYCLE_SUNSET 	- 1)
			newTime = "AFTERNOON"
		if (CYCLE_SUNSET 	to CYCLE_NIGHTTIME - 1)
			newTime = "SUNSET"
		else
			newTime = "NIGHTTIME"

	if (newTime != currentTime)
		currentTime = newTime
		updateLight(currentTime)
		. = TRUE

/datum/controller/subsystem/nightcycle/proc/doWork()
	var/list/currentTurfs = list()
	var/x = min(currentColumn + doColumns, world.maxx)
	for (var/z in SSmapping.levels_by_trait(ZTRAIT_STATION))
		currentTurfs += block(locate(currentColumn,1,z), locate(x,world.maxy,z))
	for (var/t in currentTurfs)
		var/turf/T = t
		if(T.type in GLOB.nightcycle_turfs)
			T.set_light(T.turf_light_range, sunPower, sunColour)

	currentColumn = x + 1
	if (currentColumn > world.maxx)
		currentColumn = 1
		working = 0
		return

/datum/controller/subsystem/nightcycle/proc/updateLight(newTime)
	switch (newTime)
		if ("SUNRISE")
			sunColour = "#ffd1b3"
			sunPower = 0.3
		if ("MORNING")
			sunColour = "#fff2e6"
			sunPower = 0.5
		if ("DAYTIME")
			sunColour = "#FFFFFF"
			sunPower = 0.75
		if ("AFTERNOON")
			sunColour = "#fff2e6"
			sunPower = 0.5
		if ("SUNSET")
			sunColour = "#ffcccc"
			sunPower = 0.3
		if("NIGHTTIME")
			sunColour = "#00111a"
			sunPower = 0.20



#undef CYCLE_SUNRISE
#undef CYCLE_MORNING
#undef CYCLE_DAYTIME
#undef CYCLE_AFTERNOON
#undef CYCLE_SUNSET
#undef CYCLE_NIGHTTIME

/turf
	var/turf_light_range = 0 //Nightcycle Subsystem
	var/turf_light_power = 0 //Nightcycle Subsystem

/turf/open/floor/plating/asteroid/snow/festivesnow
	gender = PLURAL
	name = "snow"
	desc = "Looks cold."
	icon = 'icons/turf/snow.dmi'
	baseturfs = /turf/open/floor/plating/asteroid/snow/festivesnow
	icon_state = "snow"
	icon_plating = "snow"
	initial_gas_mix = "o2=22;n2=82;TEMP=270"
	slowdown = 2
	environment_type = "snow"
	flags_1 = NONE
	planetary_atmos = TRUE
	turf_light_range = 3 //We set it
	turf_light_power = 0.75 //We set it
	burnt_states = list("snow_dug")
	bullet_sizzle = TRUE
	bullet_bounce_sound = null
	digResult = /obj/item/stack/sheet/mineral/snow

/turf/open/floor/plating/asteroid/snow/festivesnow/Initialize()
	. = ..()
	GLOB.nightcycle_turfs += src

/turf/open/floor/plating/asteroid/snow/festivesnow/Destroy()
	GLOB.nightcycle_turfs -= src
	. = ..()

/turf/open/floor/plating/asteroid/snow/festivesnow/burn_tile()
	if(!burnt)
		visible_message("<span class='danger'>[src] melts away!.</span>")
		slowdown = 0
		burnt = TRUE
		icon_state = "snow_dug"
		return TRUE
	return FALSE

/turf/open/floor/plating/asteroid/snow/festivesnow/ice
	name = "icy snow"
	desc = "Looks colder."
	baseturfs = /turf/open/floor/plating/asteroid/snow/festivesnow/ice
	initial_gas_mix = "o2=0;n2=82;plasma=24;TEMP=120"
	floor_variance = 0
	icon_state = "snow-ice"
	icon_plating = "snow-ice"
	environment_type = "snow_cavern"
	footstep = FOOTSTEP_FLOOR
	barefootstep = FOOTSTEP_HARD_BAREFOOT
	clawfootstep = FOOTSTEP_HARD_CLAW
	heavyfootstep = FOOTSTEP_GENERIC_HEAVY

/turf/open/floor/plating/asteroid/snow/festivesnow/ice/burn_tile()
	return FALSE
