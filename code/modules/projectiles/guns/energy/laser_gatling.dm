

//The ammo/gun is stored in a back slot item
/obj/item/minigunpack
	name = "backpack power source"
	desc = "The massive external power source for the laser gatling gun."
	icon = 'icons/obj/guns/minigun.dmi'
	icon_state = "holstered"
	item_state = "backpack"
	lefthand_file = 'icons/mob/inhands/equipment/backpack_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/backpack_righthand.dmi'
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_HUGE
	var/obj/item/gun/energy/minigun/gun
	var/obj/item/stock_parts/cell/minigun/battery
	var/armed = 0 //whether the gun is attached, 0 is attached, 1 is the gun is wielded.
	var/overheat = 0
	var/overheat_max = 40
	var/heat_diffusion = 1
	var/spawn_with_gun = TRUE

/obj/item/minigunpack/Initialize()
	. = ..()
	battery = new(src)
	if(spawn_with_gun)
		gun = new(src)
		gun.cell = battery
	START_PROCESSING(SSobj, src)

/obj/item/minigunpack/Destroy()
	if(!QDELETED(gun))
		qdel(gun)
	gun = null
	QDEL_NULL(battery)
	STOP_PROCESSING(SSobj, src)
	return ..()

/obj/item/minigunpack/process(seconds_per_tick)
	overheat = max(0, overheat - heat_diffusion)

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/item/minigunpack/attack_hand(mob/living/carbon/user)
	if(src.loc == user)
		if(!armed)
			if(user.get_item_by_slot(ITEM_SLOT_BACK) == src)
				armed = 1
				if(!user.put_in_hands(gun))
					armed = 0
					to_chat(user, span_warning("You need a free hand to hold the gun!"))
					return
				update_appearance()
				user.update_inv_back()
		else
			to_chat(user, span_warning("You are already holding the gun!"))
	else
		..()

/obj/item/minigunpack/attackby(obj/item/W, mob/user, params)
	if(W == gun) //Don't need armed check, because if you have the gun assume its armed.
		user.dropItemToGround(gun, TRUE)
	else
		..()

/obj/item/minigunpack/dropped(mob/user)
	. = ..()
	if(armed)
		user.dropItemToGround(gun, TRUE)

/obj/item/minigunpack/MouseDrop(atom/over_object)
	. = ..()
	if(armed)
		return
	if(iscarbon(usr))
		var/mob/M = usr

		if(!over_object)
			return

		if(!M.incapacitated())

			if(istype(over_object, /atom/movable/screen/inventory/hand))
				var/atom/movable/screen/inventory/hand/H = over_object
				M.putItemFromInventoryInHandIfPossible(src, H.held_index)


/obj/item/minigunpack/update_icon_state()
	icon_state = "[(armed ? "not" : "")]holstered"
	return ..()

/obj/item/minigunpack/proc/attach_gun(mob/user)
	if(!gun)
		gun = new(src)
	gun.forceMove(src)
	armed = 0
	if(user)
		to_chat(user, span_notice("You attach the [gun.name] to the [name]."))
	else
		src.visible_message(span_warning("The [gun.name] snaps back onto the [name]!"))
	update_appearance()
	user.update_inv_back()

/obj/item/minigunpack/no_gun
	spawn_with_gun = FALSE

/obj/item/gun/energy/minigun
	name = "laser gatling gun"
	desc = "An advanced laser cannon with an incredible rate of fire. Requires a bulky backpack power source to use."
	icon = 'icons/obj/guns/minigun.dmi'
	icon_state = "minigun_spin"
	item_state = "minigun"
	slowdown = 1

	fire_delay = 0.1 SECONDS

	gun_firemodes = list(FIREMODE_FULLAUTO)
	default_firemode = FIREMODE_FULLAUTO

	slot_flags = null
	w_class = WEIGHT_CLASS_HUGE
	custom_materials = null
	weapon_weight = WEAPON_MEDIUM
	ammo_type = list(/obj/item/ammo_casing/energy/laser/minigun)
	default_ammo_type = /obj/item/stock_parts/cell/crap
	allowed_ammo_types = list(
		/obj/item/stock_parts/cell/crap,
	)
	item_flags = NEEDS_PERMIT | SLOWS_WHILE_IN_HAND
	can_charge = FALSE
	var/obj/item/minigunpack/ammo_pack

/obj/item/gun/energy/minigun/Initialize()
	if(!istype(loc, /obj/item/minigunpack)) //We should spawn inside an ammo pack so let's use that one.
		return INITIALIZE_HINT_QDEL //No pack, no gun

	ammo_pack = loc
	AddElement(/datum/element/update_icon_blocker)
	return ..()

/obj/item/gun/energy/minigun/Destroy()
	if(!QDELETED(ammo_pack))
		qdel(ammo_pack)
	ammo_pack = null
	return ..()

/obj/item/gun/energy/minigun/attack_self(mob/living/user)
	return

/obj/item/gun/energy/minigun/dropped(mob/user)
	SHOULD_CALL_PARENT(0)
	if(ammo_pack)
		ammo_pack.attach_gun(user)
	else
		qdel(src)

/obj/item/gun/energy/minigun/process_fire(atom/target, mob/living/user, message = TRUE, params = null, zone_override = "", bonus_spread = 0)
	if(ammo_pack && ammo_pack.overheat >= ammo_pack.overheat_max)
		to_chat(user, span_warning("The gun's heat sensor locked the trigger to prevent lens damage!"))
		return
	..()
	ammo_pack.overheat += burst_size
	if(ammo_pack.battery)
		var/totransfer = min(100, ammo_pack.battery.charge)
		var/transferred = cell.give(totransfer)
		ammo_pack.battery.use(transferred)

/obj/item/gun/energy/minigun/afterattack(atom/target, mob/living/user, flag, params)
	if(!ammo_pack || ammo_pack.loc != user)
		to_chat(user, span_warning("You need the backpack power source to fire the gun!"))
	. = ..()


/obj/item/stock_parts/cell/minigun
	name = "gatling gun fusion core"
	desc = "Where did these come from?"
	icon_state = "h+cell"
	maxcharge = 500000
	chargerate = 5000
