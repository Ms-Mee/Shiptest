/obj/machinery/portable_atmospherics/scrubber
	name = "portable air scrubber"
	icon_state = "pscrubber:0"
	density = TRUE
	volume = 1000

	var/on = FALSE
	var/volume_rate = 1000
	var/overpressure_m = 80
	var/use_overlays = TRUE
	var/list/scrubbing = list(GAS_PLASMA, GAS_CO2, GAS_NITROUS, GAS_BZ, GAS_TRITIUM, GAS_H2O, GAS_FREON, GAS_HYDROGEN, GAS_CO)

/obj/machinery/portable_atmospherics/scrubber/Destroy()
	var/turf/T = get_turf(src)
	T.assume_air(air_contents)
	air_update_turf()
	return ..()

/obj/machinery/portable_atmospherics/scrubber/update_icon_state()
	icon_state = "pscrubber:[on]"
	return ..()

/obj/machinery/portable_atmospherics/scrubber/update_overlays()
	. = ..()
	if(!use_overlays)
		return
	if(holding)
		. += "scrubber-open"
	if(connected_port)
		. += "scrubber-connector"

/obj/machinery/portable_atmospherics/scrubber/process_atmos(seconds_per_tick)
	..()
	if(!on)
		return

	if(holding)
		scrub(holding.air_contents)
	else
		var/turf/T = get_turf(src)
		scrub(T.return_air())

/obj/machinery/portable_atmospherics/scrubber/proc/scrub(datum/gas_mixture/mixture, seconds_per_tick = 2)
	if(air_contents.return_pressure() >= overpressure_m * ONE_ATMOSPHERE)
		return

	mixture.scrub_into(air_contents, volume_rate / mixture.return_volume(), scrubbing)
	if(!holding)
		air_update_turf()

/obj/machinery/portable_atmospherics/scrubber/emp_act(severity)
	. = ..()
	if(. & EMP_PROTECT_SELF)
		return
	if(is_operational)
		if(prob(50 / severity))
			on = !on
		update_appearance()

/obj/machinery/portable_atmospherics/scrubber/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "PortableScrubber", name)
		ui.open()

/obj/machinery/portable_atmospherics/scrubber/ui_data()
	var/data = list()
	data["on"] = on
	data["connected"] = connected_port ? 1 : 0
	data["pressure"] = round(air_contents.return_pressure() ? air_contents.return_pressure() : 0)

	data["id_tag"] = -1 //must be defined in order to reuse code between portable and vent scrubbers
	data["filter_types"] = list()
	for(var/id in GLOB.gas_data.ids)
		data["filter_types"] += list(list("gas_id" = id, "gas_name" = GLOB.gas_data.names[id], "enabled" = (id in scrubbing)))

	if(holding)
		data["holding"] = list()
		data["holding"]["name"] = holding.name
		data["holding"]["pressure"] = round(holding.air_contents.return_pressure())
	else
		data["holding"] = null
	return data

/obj/machinery/portable_atmospherics/scrubber/replace_tank(mob/living/user, close_valve)
	. = ..()
	if(.)
		if(close_valve)
			if(on)
				on = FALSE
				update_appearance()
		else if(on && holding)
			investigate_log("[key_name(user)] started a transfer into [holding].", INVESTIGATE_ATMOS)

/obj/machinery/portable_atmospherics/scrubber/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		if("power")
			on = !on
			. = TRUE
		if("eject")
			if(holding)
				replace_tank(usr, FALSE)
				. = TRUE
		if("toggle_filter")
			scrubbing ^= params["val"]
			. = TRUE
	update_appearance()

/obj/machinery/portable_atmospherics/scrubber/huge
	name = "huge air scrubber"
	icon_state = "scrubber:0"
	anchored = TRUE
	idle_power_usage = IDLE_DRAW_MINIMAL
	active_power_usage = ACTIVE_DRAW_MEDIUM

	overpressure_m = 200
	volume_rate = 1500
	volume = 50000

	var/movable = FALSE
	use_overlays = FALSE

/obj/machinery/portable_atmospherics/scrubber/huge/movable
	movable = TRUE

/obj/machinery/portable_atmospherics/scrubber/huge/movable/cargo
	anchored = FALSE

/obj/machinery/portable_atmospherics/scrubber/huge/update_icon_state()
	icon_state = "scrubber:[on]"
	return ..()

/obj/machinery/portable_atmospherics/scrubber/huge/process_atmos(seconds_per_tick)
	if((!anchored && !movable) || !is_operational)
		on = FALSE
		update_appearance()
	if(on)
		set_active_power()
	else
		set_idle_power()
		return

	..()
	if(!holding)
		var/turf/T = get_turf(src)
		for(var/turf/AT as anything in T.get_atmos_all_adjacent_turfs())
			scrub(AT.return_air(), seconds_per_tick)

/obj/machinery/portable_atmospherics/scrubber/huge/attackby(obj/item/W, mob/user)
	if(default_unfasten_wrench(user, W))
		if(!movable)
			on = FALSE
	else
		return ..()
