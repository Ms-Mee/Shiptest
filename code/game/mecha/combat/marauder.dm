/obj/mecha/combat/marauder
	desc = "A heavy-duty combat exosuit that improves on the Durand model in nearly every way. Rarely found among civilian populations."
	name = "\improper Marauder"
	icon_state = "marauder"
	step_in = 5
	max_integrity = 400
	deflect_chance = 20
	armor = list("melee" = 50, "bullet" = 75, "laser" = 50, "energy" = 30, "bomb" = 30, "bio" = 0, "rad" = 60, "fire" = 100, "acid" = 100)
	max_temperature = 60000
	resistance_flags = LAVA_PROOF | FIRE_PROOF | ACID_PROOF
	infra_luminosity = 3
	operation_req_access = list(ACCESS_CENT_SPECOPS)
	internals_req_access = list(ACCESS_CENT_SPECOPS)
	wreckage = /obj/structure/mecha_wreckage/marauder
	add_req_access = 0
	internal_damage_threshold = 25
	force = 45
	max_equip = 5
	bumpsmash = 1

/obj/mecha/combat/marauder/GrantActions(mob/living/user, human_occupant = 0)
	..()
	smoke_action.Grant(user, src)

/obj/mecha/combat/marauder/RemoveActions(mob/living/user, human_occupant = 0)
	..()
	smoke_action.Remove(user)

/obj/mecha/combat/marauder/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/thrusters/ion(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/energy/pulse(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/tesla_energy_relay(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster(src)
	ME.attach(src)
	max_ammo()

/obj/mecha/combat/marauder/seraph
	desc = "A heavy-duty command-type exosuit. This is a custom model, utilized only by high-ranking military personnel."
	name = "\improper Seraph"
	icon_state = "seraph"
	operation_req_access = list(ACCESS_CENT_SPECOPS)
	internals_req_access = list(ACCESS_CENT_SPECOPS)
	step_in = 3
	max_integrity = 550
	wreckage = /obj/structure/mecha_wreckage/seraph
	internal_damage_threshold = 20
	force = 55
	max_equip = 6

/obj/mecha/combat/marauder/seraph/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/thrusters/ion(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/energy/pulse(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/teleporter(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/tesla_energy_relay(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster(src)
	ME.attach(src)
	max_ammo()

/obj/mecha/combat/marauder/touro
	desc = "A powerful ICW-era combat exosuit, developed off of Nanotrasen's Marauder model by Cybersun Biodynamics."
	name = "\improper Touro"
	icon_state = "touro"
	operation_req_access = list(ACCESS_SYNDICATE)
	internals_req_access = list(ACCESS_SYNDICATE)
	wreckage = /obj/structure/mecha_wreckage/touro
	max_equip = 6
	destruction_sleep_duration = 20

/obj/mecha/combat/marauder/touro/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/thrusters/ion(src)
	ME.attach(src)

/obj/mecha/combat/marauder/touro/loaded/Initialize()
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/lmg(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/scattershot(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/tesla_energy_relay(src)
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/antiproj_armor_booster(src)
	ME.attach(src)
	max_ammo()


