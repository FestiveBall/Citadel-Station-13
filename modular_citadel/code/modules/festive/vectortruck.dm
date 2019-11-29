/obj/vehicle/sealed/vectorcraft/boot
	name = "Hovertruck"
	desc = "An all-terrain vehicle built for traversing rough terrain with ease. This one comes equipt with a sizeable boot that can store up to 3 items!"
	icon_state = "zoomscoot"
	max_integrity = 150
	var/obj/structure/boot = list()//Trunkspace of craft
	var/boot_size = 3
	max_acceleration = 3
	accel_step = 0.15
	acceleration = 0.3
	max_deceleration = 5
	max_velocity = 80
	boost_power = 20
	enginesound_delay = 0
	var/static/radial_heal = image(icon = 'icons/mob/radial.dmi', icon_state = "radial_heal")
	var/static/radial_eject_car = image(icon = 'icons/mob/radial.dmi', icon_state = "radial_eject_car")
	var/static/radial_eject_key = image(icon = 'icons/mob/radial.dmi', icon_state = "radial_eject_key")
	var/static/radial_eject_boot = image(icon = 'icons/mob/radial.dmi', icon_state = "radial_eject_boot")

/obj/vehicle/sealed/vectorcraft/boot/MouseDrop_T(atom/dropping, mob/user)
	if(istype(dropping, /obj/))
		if(LAZYLEN(boot) < boot_size)
			boot += dropping
			to_chat(user, "<span class='notice'>You add the [dropping] to the [src]'s boot!</span>")
			return TRUE
	if(iscarbon(dropping))
		var/mob/living/carbon/M = dropping
		mob_try_enter(mob/M)
		to_chat(user, "<span class='notice'>You put [M] into the [src]!</span>")
		return TRUE

/obj/vehicle/sealed/vectorcraft/boot/ambulance
	var/obj/machinery/sleeper/ambulance/Sl
	max_acceleration = 3
	accel_step = 0.15
	acceleration = 0.3
	max_deceleration = 5
	max_velocity = 100
	boost_power = 25
	enginesound_delay = 0

/obj/vehicle/sealed/vectorcraft/boot/ambulance/Initialize()
	new var/obj/machinery/sleeper/ambulance

/obj/vehicle/sealed/vectorcraft/boot/ambulance/MouseDrop_T(mob/living/L, mob/user)
	if(isliving(L))
		Sl.close_machine(L)
		to_chat(user, "<span class='notice'>You put [M] into the [src]'s emergency sleeper!</span>")
		return TRUE
	..()


/obj/machinery/reagentgrinder/ui_interact(mob/user) // taken from the microwave/grinder
	. = ..()

	var/list/options = list()

	if(isAI(user))
		if(stat & NOPOWER)
			return
		options["radial_eject_car"] = radial_eject_car
	else
		if(vector["y"] == 0 && vector["x"] == 0)
			options["radial_eject_car"] = radial_eject_car
		if(Sl.occupant)
			options["radial_heal"] = radial_heal
		if(inserted_key)
			options["radial_eject_key"] = radial_eject_key
		if(length(boot))
			options["radial_eject_boot"] = radial_eject_boot

	var/choice

	if(length(options) < 1)
		return
	if(length(options) == 1)
		for(var/key in options)
			choice = key
	else
		choice = show_radial_menu(user, src, options, require_near = !issilicon(user))

	// post choice verification
	if(operating || (isAI(user) && stat & NOPOWER) || !user.canUseTopic(src, !issilicon(user)))
		return

	switch(choice)
		if("eject_car")
			if(driver)
				remove_occupant(driver)
			else
				for(var/mob/m in occupants)
					remove_occupant(m)
		if("grind")
			grind(user)
		if("juice")
			juice(user)
		if("mix")
			mix(user)
		if("examine")
			examine(user)
