

/obj/machinery/computer/upload
	var/mob/living/silicon/current = null //The target of future law uploads
	icon_screen = "command"
	time_to_screwdrive = 60

/obj/machinery/computer/upload/Initialize()
	. = ..()
	AddComponent(/datum/component/gps, "Encrypted Upload")

/obj/machinery/computer/upload/attackby(obj/item/O, mob/user, params)
	if(istype(O, /obj/item/aiModule))
		var/obj/item/aiModule/M = O
		if(machine_stat & (NOPOWER|BROKEN|MAINT))
			return
		if(!current)
			to_chat(user, span_alert("You haven't selected anything to transmit laws to!"))
			return
		if(!can_upload_to(current))
			to_chat(user, span_alert("Upload failed! Check to make sure [current.name] is functioning properly."))
			current = null
			return
		var/turf/currentloc = get_turf(current)
		if(currentloc && user.virtual_z() != currentloc.virtual_z())
			to_chat(user, span_alert("Upload failed! Unable to establish a connection to [current.name]. You're too far away!"))
			current = null
			return
		M.install(current.laws, user)
	else
		return ..()

/obj/machinery/computer/upload/proc/can_upload_to(mob/living/silicon/S)
	if(S.stat == DEAD)
		return FALSE
	return TRUE

/obj/machinery/computer/upload/ai
	name = "\improper AI upload console"
	desc = "Used to upload laws to the AI."
	circuit = /obj/item/circuitboard/computer/aiupload
	icon_screen = "ai_upload"

/obj/machinery/computer/upload/ai/interact(mob/user)
	current = select_active_ai(user, z)

	if (!current)
		to_chat(user, span_alert("No active AIs detected!"))
	else
		to_chat(user, span_notice("[current.name] selected for law changes."))

/obj/machinery/computer/upload/ai/can_upload_to(mob/living/silicon/ai/A)
	if(!A || !isAI(A))
		return FALSE
	if(A.control_disabled)
		return FALSE
	return ..()


/obj/machinery/computer/upload/borg
	name = "cyborg upload console"
	desc = "Used to upload laws to Cyborgs."
	circuit = /obj/item/circuitboard/computer/borgupload

/obj/machinery/computer/upload/borg/interact(mob/user)
	current = select_active_free_borg(user)

	if(!current)
		to_chat(user, span_alert("No active unslaved cyborgs detected."))
	else
		to_chat(user, span_notice("[current.name] selected for law changes."))

/obj/machinery/computer/upload/borg/can_upload_to(mob/living/silicon/robot/B)
	if(!B || !iscyborg(B))
		return FALSE
	if(B.scrambledcodes || B.emagged)
		return FALSE
	return ..()
