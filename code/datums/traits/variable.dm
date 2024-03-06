// This file has quirks with variable values, their value varies based on which options the user has taken.
// Value for each option will default to the quirk's base value if none is specified. I am a clown and a fool, no more regex nightmare

/datum/quirk/phobia
	name = "Phobia"
	value = 0
	desc = "You are irrationally afraid of something."
	medical_record_text = "Patient has an irrational fear of something."

/datum/quirk/phobia/post_add()
	var/mob/living/carbon/human/H = quirk_holder
	for(var/phobia_type in H?.client?.prefs.quirk_preferences["Phobia"]["Phobia"])
		H.gain_trauma(new /datum/brain_trauma/mild/phobia(phobia_type), TRAUMA_RESILIENCE_ABSOLUTE)

/datum/quirk/phobia/remove()
	var/mob/living/carbon/human/H = quirk_holder
	if(H)
		H.cure_trauma_type(/datum/brain_trauma/mild/phobia, TRAUMA_RESILIENCE_ABSOLUTE)



/datum/quirk/addicted
	name = "Addicted"
	desc = "You have a deep addiction to one or more substances. <b>You can get a bottle of pills for free on the loadout menu if you have the matching addiction.</b>"
	gain_text = "<span class='danger'>Your addiction is already acting up again...</span>"
	lose_text = "<span class='notice'>Maybe this time you kicked them for good.</span>"
	medical_record_text = "Patient has a history of hard drugs."
	var/reagent_types = list()
	var/datum/reagent/reagent_instance //! actual instanced version of the reagent
	var/drug_list = list("Crank" = /datum/reagent/drug/crank,
		"Happiness" = /datum/reagent/drug/happiness,
		"Krokodil" = /datum/reagent/drug/krokodil,
		"Methamphetamine" = /datum/reagent/drug/methamphetamine,
		"Morphine" = /datum/reagent/medicine/morphine
		) //List of possible IDs
	var/where_drug //! Where the drug spawned
	var/obj/item/drug_container_type //! If this is defined before pill generation, pill generation will be skipped. This is the type of the pill bottle.
	var/process_interval = 30 SECONDS //! how frequently the quirk processes
	var/next_process = 0 //! ticker for processing
	var/containers = list()

/datum/quirk/addicted/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	if(length(reagent_types) == 0)
		for(var/reagent_addicted in H?.client?.prefs.quirk_preferences["Addicted"]["Addiction"])
			reagent_types += drug_list[reagent_addicted]
	for(var/reagent_type in reagent_types)
		reagent_instance = new reagent_type()
		H.reagents.addiction_list.Add(reagent_instance)
	var/current_turf = get_turf(quirk_holder)
	if(!drug_container_type)
		drug_container_type = /obj/item/storage/pill_bottle
	for(var/reagent_type_path in reagent_types)
		var/datum/reagent/reagent_type = reagent_type_path
		var/obj/item/drug_instance = new drug_container_type(current_turf)
		if(istype(drug_instance, /obj/item/storage/pill_bottle))
			var/pill_state = "pill[rand(1,20)]"
			for(var/i in 1 to 7)
				var/obj/item/reagent_containers/pill/P = new(drug_instance)
				P.icon_state = pill_state
				P.reagents.add_reagent(reagent_type, 1)
				P.name = "[initial(reagent_type.name)] [P.name]"

		var/list/slots = list(
			"in your left pocket" = ITEM_SLOT_LPOCKET,
			"in your right pocket" = ITEM_SLOT_RPOCKET,
			"in your backpack" = ITEM_SLOT_BACKPACK
		)
		where_drug = H.equip_in_one_of_slots(drug_instance, slots, FALSE) || "at your feet"
		to_chat(quirk_holder, "<span class='boldnotice'>There is a [reagent_type == /datum/reagent/drug/nicotine ? "" : "[initial(reagent_type.name)] "][initial(drug_container_type.name)] [where_drug].</span>")



/datum/quirk/addicted/on_process()
	var/mob/living/carbon/human/H = quirk_holder
	for(var/datum/reagent/reagent_type in reagent_types)
		if(world.time > next_process)
			next_process = world.time + process_interval
			if(!(reagent_instance in H.reagents.addiction_list))
				if(QDELETED(reagent_instance))
					reagent_instance = new reagent_type()
				else
					reagent_instance.addiction_stage = 0
				H.reagents.addiction_list += reagent_instance
				to_chat(quirk_holder, "<span class='danger'>You thought you kicked it, but you suddenly feel like you need [reagent_instance.name] again...</span>")

/datum/quirk/addicted/smoker
	name = "Smoker"
	desc = "Sometimes you just really want a smoke. Probably not great for your lungs. <b>You can get a packet of your favorite brand and a cheap lighter for free on the loadout menu.</b>"
	value = -1
	gain_text = "<span class='danger'>You could really go for a smoke right about now.</span>"
	lose_text = "<span class='notice'>You feel like you should quit smoking.</span>"
	medical_record_text = "Patient is a current smoker."
	reagent_types = list(/datum/reagent/drug/nicotine)
	var/brands_list = list("Carp Classic" = /obj/item/storage/fancy/cigarettes/cigpack_carp,
		"Midori Tabako" = /obj/item/storage/fancy/cigarettes/cigpack_midori,
		"Robust" = /obj/item/storage/fancy/cigarettes/cigpack_robust,
		"Robust Gold" = /obj/item/storage/fancy/cigarettes/cigpack_robustgold,
		"Space Cigarettes" = /obj/item/storage/fancy/cigarettes,
		"Uplift Smooth" = /obj/item/storage/fancy/cigarettes/cigpack_uplift
		)

/datum/quirk/addicted/smoker/on_spawn()
	var/mob/living/carbon/human/H = quirk_holder
	drug_container_type = brands_list[H?.client?.prefs.quirk_preferences["Smoker"]["Favorite Brand"][1]]
	. = ..()

/datum/quirk/addicted/smoker/on_process()
	. = ..()
	var/mob/living/carbon/human/H = quirk_holder
	var/obj/item/I = H.get_item_by_slot(ITEM_SLOT_MASK)
	if (istype(I, /obj/item/clothing/mask/cigarette))
		var/obj/item/storage/fancy/cigarettes/C = drug_container_type
		if(istype(I, initial(C.spawn_type)))
			SEND_SIGNAL(quirk_holder, COMSIG_CLEAR_MOOD_EVENT, "wrong_cigs")
			return
		SEND_SIGNAL(quirk_holder, COMSIG_ADD_MOOD_EVENT, "wrong_cigs", /datum/mood_event/wrong_brand)

