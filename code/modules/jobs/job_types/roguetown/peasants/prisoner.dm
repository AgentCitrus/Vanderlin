/datum/job/roguetown/prisoner
	title = "Prisoner"
	flag = GRAVEDIGGER
	department_flag = PEASANTS
	faction = "Station"
	total_positions = 0
	spawn_positions = 2

	allowed_sexes = list(MALE, FEMALE)
	allowed_races = list(
		"Humen",
		"Elf",
		"Half-Elf",
		"Dwarf",
		"Tiefling",
		"Dark Elf",
		"Aasimar"
	)
	tutorial = "For a crime, or false allegation; as a hostage against another, or held for ransom: your fate until this day has been ill-starred save its first. You are of noble birth. Perhaps your story, which none but you recall, will move some pity from callous hearts or promises of riches parole your release. Maybe your old associates conspire now to release you in a daring rescue. Yet it is far surer that your tears will rust this cursed mask than the sun shine upon your face a freed soul once more." // changed to reduce dictation of character. Nikov.

	outfit = /datum/outfit/job/roguetown/prisoner
	bypass_jobban = TRUE
	display_order = JDO_PRISONER
	give_bank_account = 173
	can_random = FALSE
	bypass_lastclass = TRUE

/datum/outfit/job/roguetown/prisoner/pre_equip(mob/living/carbon/human/H)
	..()
	pants = /obj/item/clothing/under/roguetown/loincloth/brown
	mask = /obj/item/clothing/mask/rogue/facemask/prisoner
	if(H.wear_mask)
		var/obj/I = H.wear_mask
		H.dropItemToGround(H.wear_mask, TRUE)
		qdel(I)
	if(H.mind)
		H.mind.adjust_skillrank(/datum/skill/combat/wrestling, 1, TRUE)
		H.mind.adjust_skillrank(/datum/skill/combat/knives, 2, TRUE) // given Noble trait it was this or sword. N.
		H.mind.adjust_skillrank(/datum/skill/combat/unarmed, 1, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/swimming, 2, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/reading, 2, TRUE) // given Noble trait it makes no sense they were illiterate. N.
		H.mind.adjust_skillrank(/datum/skill/misc/climbing, 2, TRUE)
		H.mind.adjust_skillrank(/datum/skill/misc/sneaking, 3, TRUE)
		H.change_stat("strength", -1) // Malnutrition. N.
		H.change_stat("perception", 2) // Few distractions, idle mind, focused senses. N.
		H.change_stat("intelligence", 2) // Given Noble trait it makes no sense they are idiots. N.
		H.change_stat("speed", -1)
		H.change_stat("constitution", -1)
		H.change_stat("endurance", -1)
		var/datum/antagonist/new_antag = new /datum/antagonist/prisoner()
		H.mind.add_antag_datum(new_antag)
		ADD_TRAIT(H, TRAIT_BANDITCAMP, TRAIT_GENERIC)
	ADD_TRAIT(H, TRAIT_NOBLE, TRAIT_GENERIC)
