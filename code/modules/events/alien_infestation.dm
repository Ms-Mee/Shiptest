/datum/round_event_control/alien_infestation
	name = "Alien Infestation"
	typepath = /datum/round_event/ghost_role/alien_infestation
	weight = 10
	max_occurrences = 1
	min_players = 20

/datum/round_event/ghost_role/alien_infestation
	announce_when	= 400

	minimum_required = 1
	role_name = "alien larva"

	fakeable = TRUE

	/// How many alien larva to spawn
	var/spawncount = 2

/datum/round_event/ghost_role/alien_infestation/setup()
	announce_when = rand(announce_when, announce_when + 50)

/datum/round_event/ghost_role/alien_infestation/announce(fake)
	var/living_aliens = FALSE
	for(var/mob/living/carbon/alien/A in GLOB.player_list)
		if(A.stat != DEAD)
			living_aliens = TRUE
	if(living_aliens || fake)
		priority_announce("Scanners show that a very rare royal larva has been found in [station_name()]. Because of this, we have valid reason to suspect that a Xenomorph hive has manifested itself. Secure any exterior access, including ducting and ventilation. Beware of very strange looking dogs.", "Lifesign Alert", 'sound/ai/aliens.ogg', sender_override = "CLIP-BARD")

/datum/round_event/ghost_role/alien_infestation/spawn_role()
	var/list/vents = list()
	for(var/obj/machinery/atmospherics/components/unary/vent_pump/temp_vent in GLOB.machines)
		if(QDELETED(temp_vent))
			continue
		if(temp_vent.welded)
			continue
		var/datum/pipeline/temp_vent_parent = temp_vent.parents[1]
		if(!temp_vent_parent)
			continue//no parent vent
		//Stops Aliens getting stuck in small networks.
		//See: Security, Virology
		if(temp_vent_parent.other_atmosmch.len > 20)
			vents += temp_vent

	if(!vents.len)
		message_admins("An event attempted to spawn an alien but no suitable vents were found. Shutting down.")
		return MAP_ERROR

	var/list/candidates = get_candidates(ROLE_ALIEN, null, ROLE_ALIEN)

	if(!candidates.len)
		return NOT_ENOUGH_PLAYERS

	while(spawncount > 0 && vents.len && candidates.len)
		var/obj/vent = pick_n_take(vents)
		var/client/C = pick_n_take(candidates)

		var/mob/living/carbon/alien/larva/new_xeno = new(vent.loc)
		new_xeno.key = C.key

		spawncount--
		message_admins("[ADMIN_LOOKUPFLW(new_xeno)] has been made into an alien by an event.")
		log_game("[key_name(new_xeno)] was spawned as an alien by an event.")
		spawned_mobs += new_xeno

	return SUCCESSFUL_SPAWN
