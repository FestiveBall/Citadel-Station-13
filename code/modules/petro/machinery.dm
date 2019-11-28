#define ICG_FUEL_TICK 1 //fuel consumed a tick
#define STIRLING_FUEL_TICK 0.1

/obj/machinery/power/gasgen
	name = "internal combustion generator"
	desc = "A machine that harnesses low explosives to drive an alternator."
	icon_state = "icg"
	var/power_gen = 1500
	density = TRUE
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/icg
	var/active = 0 //duh
	var/tank = 50 //stored fuel
	var/reagent_flags

/obj/machinery/power/gasgen/RefreshParts()
	var/part_level = 0
	for(var/obj/item/stock_parts/SP in component_parts)
		part_level += SP.rating

	power_gen = initial(power_gen) * round(part_level/4)


/obj/machinery/power/gasgen/examine(mob/user)
	..()
	to_chat(user, "<span class='notice'>[src] [active ? "is running":"isn't running"].</span>")

/obj/machinery/power/gasgen/attack_hand(mob/user)
	if(!active)
		active = 1
		START_PROCESSING(SSobj, src)
		to_chat(user, "<span class='notice'>You start up the [src].</span>")
	else
		active = 0
		STOP_PROCESSING(SSobj, src)
		to_chat(user, "<span class='notice'>You shut down the [src].</span>")

/obj/machinery/power/gasgen/plunger_act(obj/item/plunger/P, mob/living/user, reinforced)
	to_chat(user, "<span class='notice'>You start furiously plunging [name].")
	if(do_after(user, 30, target = src))
		to_chat(user, "<span class='notice'>You finish plunging the [name].")
		reagents.reaction(get_turf(src), TOUCH) //splash on the floor
		reagents.clear_reagents()

/obj/machinery/power/gasgen/Initialize(mapload, bolt = TRUE)
	. = ..()
	anchored = bolt
	create_reagents(tank, reagent_flags)
	AddComponent(/datum/component/plumbing/simple_demand)
	AddComponent(/datum/component/simple_rotation, ROTATION_ALTCLICK | ROTATION_CLOCKWISE | ROTATION_COUNTERCLOCKWISE | ROTATION_VERBS )


/obj/machinery/power/gasgen/wrench_act(mob/living/user, obj/item/I)
	connect_to_network()
	default_unfasten_wrench(user, I)
	return TRUE

/obj/machinery/power/gasgen/process()
	..()
	if(reagents.total_volume >= 1)
		if(reagents.remove_reagent("gasoline", ICG_FUEL_TICK) || reagents.remove_reagent("diesel", ICG_FUEL_TICK))
			add_avail(power_gen)
		else
			active = 0
			STOP_PROCESSING(SSobj, src)
			for(var/mob/living/M in viewers(get_turf(src), null))
				M.visible_message("<span class='notice'>The [src] sputters, shudders and slides to a stop.</span>")
			take_damage(20, BRUTE, "melee", 1) //dont let it run out of fuel, idiot. itll misfire.
	return

/obj/machinery/power/gasgen/stirling
	name = "stirling generator"
	desc = "The pinnacle of heat-based generator technology, a stirling engine uses a differential between two temperatures to create power. Creates more power if actively cooled with water."
	icon_state = "stirling"
	power_gen = 750 //worse off, but more optimizable
	density = TRUE
	use_power = NO_POWER_USE
	circuit = /obj/item/circuitboard/machine/stirling
	var/coolant_mult = 1

/obj/machinery/power/gasgen/stirling/RefreshParts()
	var/part_level = 0
	for(var/obj/item/stock_parts/SP in component_parts)
		part_level += SP.rating
	power_gen = initial(power_gen) * round(part_level/6)

/obj/machinery/power/gasgen/stirling/process()
	..()
	if(reagents.total_volume >= 1)
		if(reagents.remove_reagent("gasoline", STIRLING_FUEL_TICK) || reagents.remove_reagent("diesel", STIRLING_FUEL_TICK) || reagents.remove_reagent("kerosene", STIRLING_FUEL_TICK) || reagents.remove_reagent("butane", STIRLING_FUEL_TICK) ||reagents.remove_reagent("naptha", STIRLING_FUEL_TICK) || reagents.remove_reagent("fueloil", STIRLING_FUEL_TICK))
			if(reagents.remove_reagent("water", ICG_FUEL_TICK))
				coolant_mult = 1.5
			else
				coolant_mult = 1
			add_avail(power_gen*coolant_mult)
		else
			active = 0
			STOP_PROCESSING(SSobj, src)
			for(var/mob/living/M in viewers(get_turf(src), null))
				M.visible_message("<span class='notice'>The [src] sputters, shudders and slides to a stop.</span>")

#undef ICG_FUEL_TICK
#undef STIRLING_FUEL_TICK

/obj/machinery/power/distillator
	name = "fractional distillation chamber"
	desc = "Fractionally distillates chemicals using the power of science! And heat."
	icon_state = "reaction_chamber"
	var/tank = 400
	var/reagent_flags = NO_REACT
	var/active = FALSE
	active_power_usage = 10000
	idle_power_usage = 500
	var/heat = 293

/obj/machinery/power/distillator/Initialize(mapload, bolt)
	. = ..()
	create_reagents(tank, reagent_flags)
	AddComponent(/datum/component/plumbing/tank)
	AddComponent(/datum/component/simple_rotation, ROTATION_ALTCLICK | ROTATION_CLOCKWISE | ROTATION_COUNTERCLOCKWISE | ROTATION_VERBS )

/obj/machinery/power/distillator/examine(mob/user)
	..()
	to_chat(user, "<span class='notice'>The valve on [src] is [active ? "open":"closed"].</span>")
	to_chat(user, "<span class='notice'>A small gauge displays the current temperature </span><span class='danger'>[heat]K.</span>")

/obj/machinery/power/distillator/attack_hand(mob/user)
	if(!active)
		active = TRUE
		START_PROCESSING(SSobj, src)
		to_chat(user, "<span class='notice'>You open the main valve on [src].</span>")
	else
		active = FALSE
		STOP_PROCESSING(SSobj, src)
		to_chat(user, "<span class='notice'>You close the main valve on [src].</span>")
		heat = 293
/*
		icon_state = initial(icon_state)

/obj/machinery/plumbing/distillator/ui_interact(mob/user, ui_key = "main", datum/tgui/ui = null, force_open = FALSE, datum/tgui/master_ui = null, datum/ui_state/state = GLOB.default_state)
	ui = SStgui.try_update_ui(user, src, ui_key, ui, force_open)
	if(!ui)
		ui = new(user, src, ui_key, "reaction_chamber", name, 500, 300, master_ui, state)
		ui.open()

/obj/machinery/plumbing/distillator/ui_data(mob/user)
	var/list/data = list()
	var/list/text_reagents = list()
	for(var/A in required_reagents) //make a list where the key is text, because that looks alot better in the ui than a typepath
		var/datum/reagent/R = GLOB.chemical_reagents_list[A]
		text_reagents[initial(R.name)] = required_reagents[R]

	data["reagents"] = text_reagents
	data["emptying"] = emptying
	return data

/obj/machinery/plumbing/distillator/ui_act(action, params)
	if(..())
		return
	. = TRUE
	switch(action)
		if("remove")
			var/reagent = get_chem_id(params["chem"])
			if(reagent)
				required_reagents.Remove(reagent)
		if("add")
			var/input_reagent = get_chem_id(input("Enter the name of the reagent", "Input") as text|null)
			if(input_reagent && !required_reagents.Find(input_reagent))
				var/input_amount = CLAMP(round(input("Enter amount", "Input") as num|null), 1, 100)
				if(input_amount)
					required_reagents[input_reagent] = input_amount
*/

/obj/machinery/power/distillator/process()
	..()
	if(avail(active_power_usage))
		add_load(active_power_usage)
		if(heat < 1593)
		heat =+ 100
	else
		if(heat > 293)
			heat =- 100
	if((reagents.remove_reagent("crudeoil", 5) && reagents.remove_reagent("water", 1)) && heat > 993)
		src.add_reagent("asphalt", 0.3)
		src.add_reagent("fueloil", 0.3)
		src.add_reagent("diesel", 0.2)
		src.add_reagent("kerosene", 0.1)
		src.add_reagent("naphtha", 0.05)
		src.add_reagent("butane", 0.05)
	else if((reagents.remove_reagent("crudeoil", 5) && reagents.remove_reagent("water", 1)) && heat > 1293)
		src.add_reagent("asphalt", 0.35)
		src.add_reagent("fueloil", 0.35)
		src.add_reagent("diesel", 0.2)
		src.add_reagent("kerosene", 0.05)
		src.add_reagent("naphtha", 0.05)

	else if((reagents.remove_reagent("crudeoil", 5) && reagents.remove_reagent("water", 1)) && heat > 1493)
		src.add_reagent("asphalt", 0.3)
		src.add_reagent("fueloil", 0.4)
		src.add_reagent("diesel", 0.3)

/obj/machinery/power/liquid_pump/oilrig
	name = "oil drilling rig"
	desc = "Pump up those sweet liquids from under the surface."
	icon = 'icons/obj/machines/oilrig.dmi'
	icon_state = "tap"
	anchored = TRUE
	density = TRUE
	circuit = /obj/item/circuitboard/machine/oilrig //not implemented yet
	idle_power_usage = 10
	active_power_usage = 3000
	pixel_x = -32
	pixel_y = -64
	powered = FALSE
	pump_power = 10
	geyserless = FALSE
	var/obj/structure/geyser/oilspot/resevoir
	var/fillers = list()
	volume = 2000

/obj/machinery/power/liquid_pump/oilrig/Initialize()
	. = ..()
	var/list/occupied = list()
	for(var/direct in list(EAST,WEST,SOUTHEAST,SOUTHWEST))
		occupied += get_step(src,direct)
	occupied += locate(x+1,y-2,z)
	occupied += locate(x-1,y-2,z)
	for(var/T in occupied)
		var/obj/structure/filler/F = new(T)
		F.parent = src
		fillers += F

/obj/machinery/power/liquid_pump/oilrig/Destroy()
	for(var/V in fillers)
		var/obj/structure/filler/filler = V
		filler.parent = null
		qdel(filler)
	. = ..()

/obj/machinery/power/liquid_pump/oilrig/attackby(obj/item/W, mob/user, params)
	if(!powered)
		if(anchored)
			if(default_deconstruction_screwdriver(user, "[initial(icon_state)]_open", "[initial(icon_state)]",W))
				return
		if(default_deconstruction_crowbar(W))
			return
	return ..()

/obj/machinery/power/liquid_pump/oilrig/process()
	if(!anchored || panel_open)
		return
	if(!resevoir && !geyserless)
		for(var/obj/structure/geyser/oilspot/G in loc.contents)
			resevoir = G
		if(!resevoir) //we didnt find one, abort
			anchored = FALSE
			geyserless = TRUE
			visible_message("<span class='warning'>The [name] makes a sad beep!</span>")
			playsound(src, 'sound/machines/buzz-sigh.ogg', 50)
			return

	if(avail(active_power_usage))
		if(!powered) //we werent powered before this tick so update our sprite
			powered = TRUE
			update_icon()
		add_load(active_power_usage)
		pump()
	else if(powered) //we were powered, but now we arent
		powered = FALSE
		update_icon()
