#define AUTOLATHE_MAIN_MENU 1
#define AUTOLATHE_CATEGORY_MENU 2
#define AUTOLATHE_SEARCH_MENU 3

/obj/machinery/autolathe
	name = "autolathe"
	desc = "It produces items using metal and glass and maybe other materials, can take design disks."
	icon = 'icons/obj/machines/autolathe.dmi'
	icon_state = "autolathe"
	density = TRUE
	use_power = IDLE_POWER_USE
	idle_power_usage = IDLE_DRAW_LOW
	active_power_usage = ACTIVE_DRAW_HIGH
	power_channel = AREA_USAGE_EQUIP
	circuit = /obj/item/circuitboard/machine/autolathe
	layer = BELOW_OBJ_LAYER

	var/operating = FALSE
	var/list/L = list()
	var/list/LL = list()
	var/hacked = FALSE
	var/disabled = FALSE
	var/shocked = FALSE
	var/hack_wire
	var/disable_wire
	var/shock_wire
	var/obj/item/disk/design_disk/d_disk    //Stores the design disk.

	var/busy = FALSE

	///the multiplier for how much materials the created object takes from this machines stored materials
	var/creation_efficiency = 1.6

	var/datum/design/being_built
	var/datum/techweb/stored_research
	var/list/datum/design/matching_designs
	var/selected_category = "None"
	var/base_price = 25
	var/hacked_price = 50

	var/list/categories = list(
							"Tools",
							"Electronics",
							"Construction",
							"T-Comm",
							"Security",
							"Machinery",
							"Medical",
							"Misc",
							"Dinnerware"
							)

/obj/machinery/autolathe/Initialize()
	AddComponent(/datum/component/material_container,list(/datum/material/iron, /datum/material/copper, /datum/material/glass, /datum/material/plastic, /datum/material/silver, /datum/material/gold, /datum/material/plasma, /datum/material/uranium, /datum/material/titanium, /datum/material/carbon, /datum/material/sulfur, /datum/material/lead, /datum/material/quartz, /datum/material/hellstone, /datum/material/silicon), 0, TRUE, null, null, CALLBACK(src, PROC_REF(AfterMaterialInsert)))
	. = ..()

	wires = new /datum/wires/autolathe(src)
	stored_research = new /datum/techweb/specialized/autounlocking/autolathe
	matching_designs = list()

/obj/machinery/autolathe/Destroy()
	QDEL_NULL(d_disk)
	QDEL_NULL(wires)
	return ..()

/obj/machinery/autolathe/ui_interact(mob/user, datum/tgui/ui)
	if(!is_operational)
		return

	if(shocked && !(machine_stat & NOPOWER))
		shock(user,50)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Autolathe")
		ui.open()

/obj/machinery/autolathe/ui_data(mob/user)
	var/list/data = list()
	data["materials"] = list()
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	data["materialtotal"] = materials.total_amount
	data["materialsmax"] = materials.max_amount
	data["categories"] = categories
	data["designs"] = list()
	data["active"] = busy
	data["hasDisk"] = d_disk ? TRUE : FALSE
	for(var/mat_id in materials.materials)
		var/datum/material/M = mat_id
		var/mineral_count = materials.materials[mat_id]
		var/sheets_count = CEILING(mineral_count / MINERAL_MATERIAL_AMOUNT, 0.1)
		var/list/material_data = list(
			name = M.name,
			mineral_amount = mineral_count,
			sheets_amount = sheets_count,
			matcolour = M.color,
		)
		data["materials"] += list(material_data)
	if(selected_category != "None" && !length(matching_designs))
		data["designs"] = handle_designs(stored_research.researched_designs, TRUE)
	else
		data["designs"] = handle_designs(matching_designs, FALSE)
	return data

/obj/machinery/autolathe/proc/handle_designs(list/researched_designs, categorycheck)
	var/list/output = list()
	var/list/blueprints = list()
	if (d_disk && selected_category == d_disk?.name)
		for(var/datum/design/w in d_disk.blueprints)
			if(!(w.build_type & AUTOLATHE)) // Only list if it has the autolathe build_type
				continue
			blueprints += w
	else
		for(var/w in researched_designs)
			var/datum/design/d = categorycheck ? SSresearch.techweb_design_by_id(w) : w
			if(categorycheck)
				if(!(selected_category in d.category))
					continue
			blueprints += d
	for(var/datum/design/D in blueprints)
		var/unbuildable = FALSE // we can't build the design currently
		var/m10 = FALSE // 10x mult
		var/m25 = FALSE // 25x mult
		var/m50 = FALSE // 50x mult
		var/m5 = FALSE // 5x mult
		var/sheets = FALSE // sheets or no?
		if(disabled || !can_build(D))
			unbuildable = TRUE
		var/max_multiplier = unbuildable ? 0 : 1
		if(ispath(D.build_path, /obj/item/stack))
			sheets = TRUE
			if(!unbuildable)
				var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
				for(var/datum/material/mat in D.materials)
					max_multiplier = min(D.maxstack, round(mats.get_material_amount(mat)/D.materials[mat]))
				if (max_multiplier>10 && !disabled)
					m10 = TRUE
				if (max_multiplier>25 && !disabled)
					m25 = TRUE
		else
			if(!unbuildable)
				if(!disabled && can_build(D, 5))
					m5 = TRUE
				if(!disabled && can_build(D, 10))
					m10 = TRUE
				var/datum/component/material_container/mats = GetComponent(/datum/component/material_container)
				for(var/datum/material/mat in D.materials)
					max_multiplier = min(50, round(mats.get_material_amount(mat)/(D.materials[mat] * creation_efficiency)))

		var/list/design = list(
			name = D.name,
			id = D.id,
			ref = REF(src),
			cost = get_design_cost(D),
			buildable = unbuildable,
			mult5 = m5,
			mult10 = m10,
			mult25 = m25,
			mult50 = m50,
			sheet = sheets,
			maxmult = max_multiplier,
		)
		output += list(design)
	return output

/obj/machinery/autolathe/ui_act(action, params)
	. = ..()
	if(.)
		return
	if(action == "menu")
		selected_category = null
		matching_designs.Cut()
		. = TRUE

	if(action == "category")
		selected_category = params["selectedCategory"]
		matching_designs.Cut()
		. = TRUE

	if(action == "search")
		matching_designs.Cut()

		for(var/v in stored_research.researched_designs)
			var/datum/design/D = SSresearch.techweb_design_by_id(v)
			if(findtext(D.name,params["to_search"]))
				matching_designs.Add(D)
		. = TRUE
	if(action == "diskEject")
		eject(usr)

	if(action == "materialEject")
		var/material_name = params["materialName"]
		var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
		var/amount = text2num(params["amount"])
		if(amount <= 0 || amount > 50)
			return

		for(var/mat in materials.materials)
			var/datum/material/M = mat
			if("[M]" == material_name)
				materials.retrieve_sheets(amount, M, get_turf(src))
				. = TRUE
				break

	if(action == "make")
		if (!busy)
			/////////////////
			//href protection
			being_built = SSresearch.techweb_design_by_id(params["id"]) // Search for ID within all research, who cares if its researched
			if(!being_built)
				return

			var/multiplier = text2num(params["multiplier"])
			if(!multiplier)
				to_chat(usr, "<span class=\"alert\">[src] only accepts a numerical multiplier!</span>")
				return
			var/is_stack = ispath(being_built.build_path, /obj/item/stack)
			multiplier = clamp(round(multiplier),1,50)

			/////////////////

			var/coeff = (is_stack ? 1 : creation_efficiency) //stacks are unaffected by production coefficient
			var/total_amount = 0

			for(var/MAT in being_built.materials)
				total_amount += being_built.materials[MAT]

			var/power = max(active_power_usage, total_amount) //Change this to use all materials

			var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)

			var/list/materials_used = list()
			var/list/custom_materials = list() //These will apply their material effect, This should usually only be one.

			for(var/MAT in being_built.materials)
				var/datum/material/used_material = MAT
				var/amount_needed = being_built.materials[MAT] * coeff * multiplier
				if(istext(used_material)) //This means its a category
					var/list/list_to_show = list()
					for(var/i in SSmaterials.materials_by_category[used_material])
						if(materials.materials[i] > 0)
							list_to_show += i

					used_material = input("Choose [used_material]", "Custom Material") as null|anything in sortList(list_to_show, /proc/cmp_typepaths_asc)
					if(!used_material)
						return //Didn't pick any material, so you can't build shit either.
					custom_materials[used_material] += amount_needed

				materials_used[used_material] = amount_needed

			if(materials.has_materials(materials_used))
				busy = TRUE
				to_chat(usr, "<span class=\"notice\">You print [multiplier] item(s) from the [src]</span>")
				use_power(power)
				icon_state = "autolathe_n"
				var/time = is_stack ? 32 : (32 * coeff * multiplier) ** 0.8
				set_active_power()
				addtimer(CALLBACK(src, PROC_REF(make_item), power, materials_used, custom_materials, multiplier, coeff, is_stack, usr), time)
				. = TRUE
			else
				to_chat(usr, "<span class=\"alert\">Not enough materials for this operation.</span>")
		else
			to_chat(usr, "<span class=\"alert\">The autolathe is busy. Please wait for completion of previous operation.</span>")

/obj/machinery/autolathe/on_deconstruction()
	if(d_disk) // Drops the design disk on the floor when destroyed
		d_disk.forceMove(get_turf(src))
		d_disk = null
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	materials.retrieve_all()

/obj/machinery/autolathe/attackby(obj/item/O, mob/living/user, params)
	if (busy)
		to_chat(user, "<span class=\"alert\">The autolathe is busy. Please wait for completion of previous operation.</span>")
		return TRUE

	if(default_deconstruction_screwdriver(user, "autolathe_t", "autolathe", O))
		return TRUE

	if(default_deconstruction_crowbar(O))
		return TRUE

	if(panel_open && is_wire_tool(O))
		wires.interact(user)
		return TRUE

	if(user.a_intent == INTENT_HARM) //so we can hit the machine
		return ..()

	if(machine_stat)
		return TRUE

	if(istype(O, /obj/item/disk/design_disk))
		if(d_disk)
			to_chat(user, span_warning("A design disk is already loaded!"))
			return TRUE
		if(!user.transferItemToLoc(O, src))
			to_chat(user, span_warning("[O] is stuck to your hand!"))
			return TRUE
		to_chat(user, span_notice("You insert [O] into \the [src]!"))
		playsound(src, 'sound/machines/terminal_insert_disc.ogg', 50, FALSE)
		d_disk = O
		categories += d_disk.name
		return TRUE

	return ..()

/obj/machinery/autolathe/proc/eject(mob/living/user)
	if(!d_disk)
		return
	if(!istype(user) || !Adjacent(user) || !user.put_in_active_hand(d_disk))
		d_disk.forceMove(drop_location())
	categories -= d_disk.name
	d_disk = null

/obj/machinery/autolathe/AltClick(mob/user)
	if(d_disk && user.canUseTopic(src, !issilicon(user)))
		to_chat(user, span_notice("You take out [d_disk] from [src]."))
		playsound(src, 'sound/machines/click.ogg', 50, FALSE)
		eject(user)
	return


/obj/machinery/autolathe/proc/AfterMaterialInsert(obj/item/item_inserted, id_inserted, amount_inserted)
	if(istype(item_inserted, /obj/item/stack/ore/bluespace_crystal))
		use_power(MINERAL_MATERIAL_AMOUNT / 10)
	else if(custom_materials && custom_materials.len && custom_materials[SSmaterials.GetMaterialRef(/datum/material/glass)])
		flick("autolathe_r", src) //plays glass insertion animation by default otherwise
	else
		flick("autolathe_o", src) //plays metal insertion animation

		use_power(min(active_power_usage, amount_inserted))

/obj/machinery/autolathe/proc/make_item(power, list/materials_used, list/picked_materials, multiplier, coeff, is_stack, mob/user)
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	var/atom/A = drop_location()
	use_power(power)
	set_idle_power()

	materials.use_materials(materials_used)

	if(is_stack)
		var/obj/item/stack/new_item = new being_built.build_path(A, multiplier, FALSE)
		new_item.update_appearance()
		new_item.autolathe_crafted(src)
		SSblackbox.record_feedback("nested tally", "item_printed", 1, list("[type]", "[new_item.type]"))
	else
		for(var/i=1, i<=multiplier, i++)
			var/obj/item/new_item = new being_built.build_path(A)
			new_item.autolathe_crafted(src)
			SSblackbox.record_feedback("nested tally", "item_printed", 1, list("[type]", "[new_item.type]"))
			if(length(picked_materials))
				new_item.set_custom_materials(picked_materials, 1 / multiplier) //Ensure we get the non multiplied amount
				for(var/x in picked_materials)
					var/datum/material/M = x
					if(!istype(M, /datum/material/glass) && !istype(M, /datum/material/iron))
						user.client.give_award(/datum/award/achievement/misc/getting_an_upgrade, user)


	icon_state = "autolathe"
	busy = FALSE

/obj/machinery/autolathe/RefreshParts()
	var/mat_capacity = 0
	for(var/obj/item/stock_parts/matter_bin/new_matter_bin in component_parts)
		mat_capacity += new_matter_bin.rating*75000
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	materials.max_amount = mat_capacity

	var/efficiency=1.8
	for(var/obj/item/stock_parts/manipulator/new_manipulator in component_parts)
		efficiency -= new_manipulator.rating*0.2
	creation_efficiency = max(1,efficiency) // creation_efficiency goes 1.6 -> 1.4 -> 1.2 -> 1 per level of manipulator efficiency

/obj/machinery/autolathe/examine(mob/user)
	. += ..()
	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)
	if(in_range(user, src) || isobserver(user))
		. += span_notice("The status display reads: Storing up to <b>[materials.max_amount]</b> material units.<br>Material consumption at <b>[creation_efficiency*100]%</b>.")
		if (d_disk)
			. += span_notice("[d_disk.name] is loaded, Alt-Click to remove.")

/obj/machinery/autolathe/proc/can_build(datum/design/D, amount = 1)
	if(D.make_reagents.len)
		return FALSE

	var/coeff = (ispath(D.build_path, /obj/item/stack) ? 1 : creation_efficiency)

	var/list/required_materials = list()

	for(var/i in D.materials)
		required_materials[i] = D.materials[i] * coeff * amount

	var/datum/component/material_container/materials = GetComponent(/datum/component/material_container)

	return materials.has_materials(required_materials)


/obj/machinery/autolathe/proc/get_design_cost(datum/design/D)
	var/coeff = (ispath(D.build_path, /obj/item/stack) ? 1 : creation_efficiency)
	var/dat
	for(var/i in D.materials)
		if(istext(i)) //Category handling
			dat += "[D.materials[i] * coeff] [i]"
		else
			var/datum/material/M = i
			dat += "[D.materials[i] * coeff] [initial(M.name)] "
	return dat

/obj/machinery/autolathe/proc/reset(wire)
	switch(wire)
		if(WIRE_HACK)
			if(!wires.is_cut(wire))
				adjust_hacked(FALSE)
		if(WIRE_SHOCK)
			if(!wires.is_cut(wire))
				shocked = FALSE
		if(WIRE_DISABLE)
			if(!wires.is_cut(wire))
				disabled = FALSE

/obj/machinery/autolathe/proc/shock(mob/user, prb)
	if(machine_stat & (BROKEN|NOPOWER)) // unpowered, no shock
		return FALSE
	if(!prob(prb))
		return FALSE
	var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
	s.set_up(5, 1, src)
	s.start()
	if (electrocute_mob(user, get_area(src), src, 0.7, TRUE))
		return TRUE
	else
		return FALSE

/obj/machinery/autolathe/proc/adjust_hacked(state)
	hacked = state
	for(var/id in SSresearch.techweb_designs)
		var/datum/design/D = SSresearch.techweb_design_by_id(id)
		if((D.build_type & AUTOLATHE) && ("hacked" in D.category))
			if(hacked)
				stored_research.add_design(D)
			else
				stored_research.remove_design(D)

/obj/machinery/autolathe/hacked/Initialize()
	. = ..()
	adjust_hacked(TRUE)

//Called when the object is constructed by an autolathe
//Has a reference to the autolathe so you can do !!FUN!! things with hacked lathes
/obj/item/proc/autolathe_crafted(obj/machinery/autolathe/lathe)
	return

/obj/machinery/autolathe/connect_to_shuttle(obj/docking_port/mobile/port, obj/docking_port/stationary/dock)
	var/datum/overmap/ship/controlled/current_ship = port.current_ship
	if(!istype(current_ship))
		return
	if(current_ship.matbundle_spawned)
		return
	new /obj/effect/spawner/random/test_ship_matspawn(get_turf(src))
	current_ship.matbundle_spawned = TRUE
