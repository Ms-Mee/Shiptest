/datum/surgery/advanced/lobotomy
	name = "Lobotomy"
	desc = "An invasive surgical procedure which guarantees removal of almost all brain traumas, but might cause another permanent trauma in return."
	steps = list(
	/datum/surgery_step/incise,
	/datum/surgery_step/retract_skin,
	/datum/surgery_step/saw,
	/datum/surgery_step/clamp_bleeders,
	/datum/surgery_step/lobotomize,
	/datum/surgery_step/close)

	target_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)
	possible_locs = list(BODY_ZONE_HEAD)
	requires_bodypart_type = 0

/datum/surgery/advanced/lobotomy/can_start(mob/user, mob/living/carbon/target)
	if(!..())
		return FALSE
	var/obj/item/organ/brain/B = target.getorganslot(ORGAN_SLOT_BRAIN)
	if(!B)
		return FALSE
	return TRUE

/datum/surgery_step/lobotomize
	name = "perform lobotomy"
	implements = list(
		TOOL_SCALPEL = 85, // there is no way this should be reasonable to do basically at all without a real surgery. ghetto lobotomy, for real?
		/obj/item/melee/energy/sword = 25,
		/obj/item/melee/knife = 15,
		/obj/item/shard = 10,
		/obj/item = 5)
	time = 10 SECONDS
	preop_sound = 'sound/surgery/scalpel1.ogg'
	success_sound = 'sound/surgery/scalpel2.ogg'
	failure_sound = 'sound/surgery/organ2.ogg'
	experience_given = MEDICAL_SKILL_ADVANCED //lose XP if you end up giving them bad traumas

/datum/surgery_step/lobotomize/tool_check(mob/user, obj/item/tool)
	if(implement_type == /obj/item && !tool.get_sharpness())
		return FALSE
	return TRUE

/datum/surgery_step/lobotomize/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	display_results(user, target, span_notice("You begin to perform a lobotomy on [target]'s brain..."),
		span_notice("[user] begins to perform a lobotomy on [target]'s brain."),
		span_notice("[user] begins to perform surgery on [target]'s brain."))

/datum/surgery_step/lobotomize/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results = FALSE)
	display_results(user, target, span_notice("You succeed in lobotomizing [target]."),
			span_notice("[user] successfully lobotomizes [target]!"),
			span_notice("[user] completes the surgery on [target]'s brain."))
	target.cure_all_traumas(TRAUMA_RESILIENCE_LOBOTOMY)
	if(target.mind && target.mind.has_antag_datum(/datum/antagonist/brainwashed))
		target.mind.remove_antag_datum(/datum/antagonist/brainwashed)
	switch(rand(1,3))//Now let's see what hopefully-not-important part of the brain we cut off
		if(1)
			target.gain_trauma_type(BRAIN_TRAUMA_MILD, TRAUMA_RESILIENCE_MAGIC)
			experience_given = MEDICAL_SKILL_ADVANCED*0.9
		if(2)
			if(HAS_TRAIT(target, TRAIT_SPECIAL_TRAUMA_BOOST) && prob(50))
				target.gain_trauma_type(BRAIN_TRAUMA_SPECIAL, TRAUMA_RESILIENCE_MAGIC)
			else
				target.gain_trauma_type(BRAIN_TRAUMA_SEVERE, TRAUMA_RESILIENCE_MAGIC)
			experience_given = MEDICAL_SKILL_ADVANCED*0.8
		if(3)
			target.gain_trauma_type(BRAIN_TRAUMA_SPECIAL, TRAUMA_RESILIENCE_MAGIC)
			experience_given = MEDICAL_SKILL_ADVANCED*0.5
	return ..()

/datum/surgery_step/lobotomize/failure(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	var/obj/item/organ/brain/B = target.getorganslot(ORGAN_SLOT_BRAIN)
	if(B)
		display_results(user, target, span_warning("You remove the wrong part, causing more damage!"),
			span_notice("[user] successfully lobotomizes [target]!"),
			span_notice("[user] completes the surgery on [target]'s brain."))
		B.applyOrganDamage(80)
		switch(rand(1,3))
			if(1)
				target.gain_trauma_type(BRAIN_TRAUMA_MILD, TRAUMA_RESILIENCE_MAGIC)
			if(2)
				if(HAS_TRAIT(target, TRAIT_SPECIAL_TRAUMA_BOOST) && prob(50))
					target.gain_trauma_type(BRAIN_TRAUMA_SPECIAL, TRAUMA_RESILIENCE_MAGIC)
				else
					target.gain_trauma_type(BRAIN_TRAUMA_SEVERE, TRAUMA_RESILIENCE_MAGIC)
			if(3)
				target.gain_trauma_type(BRAIN_TRAUMA_SPECIAL, TRAUMA_RESILIENCE_MAGIC)
	else
		user.visible_message(span_warning("[user] suddenly notices that the brain [user.p_they()] [user.p_were()] working on is not there anymore."), span_warning("You suddenly notice that the brain you were working on is not there anymore."))
	return FALSE
