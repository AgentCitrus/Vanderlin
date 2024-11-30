
SUBSYSTEM_DEF(death_arena)
	name = "Death Arena"
	wait = 2 SECONDS
	flags = SS_NO_INIT
	priority = 1

	var/turf/first_spawn
	var/turf/second_spawn
	var/list/waiting_fighters = list()
	///this is just so I can easily reference the head later
	var/list/fighters_heads = list()
	var/list/fighters = list()
	///we check if spirits here aswell
	var/list/tollless_clients = list()
	var/fighting = FALSE
	var/fight_force_end = null

/datum/controller/subsystem/death_arena/fire(resumed = 0)
	listclearnulls(waiting_fighters)
	listclearnulls(tollless_clients)

	for(var/client/client  as anything in tollless_clients)
		if(QDELETED(client))
			tollless_clients -= client
			continue
		if(world.time > tollless_clients[client])
			if(istype(client.mob, /mob/living/carbon/spirit))
				var/mob/living/carbon/spirit/spirit = client.mob
				spirit.give_patron_toll()
				remove_fighter(spirit)
				tollless_clients -= client

	if(fight_force_end)
		if(fight_force_end < world.time)
			force_end_fight()
	if(!first_spawn || !second_spawn)
		return
	if(fighting)
		return
	if(length(waiting_fighters) < 2)
		return
	start_fight()

/datum/controller/subsystem/death_arena/proc/add_fighter(mob/living/fighter)
	waiting_fighters += fighter
	tollless_clients[fighter.client] = world.time + 8 MINUTES
	RegisterSignal(fighter, COMSIG_PARENT_QDELETING, PROC_REF(remove_fighter), fighter)

/datum/controller/subsystem/death_arena/proc/remove_fighter(mob/living/fighter)
	waiting_fighters -= fighter

/datum/controller/subsystem/death_arena/proc/start_fight()
	fighting = TRUE

	var/mob/living/carbon/spirit/first = pick(waiting_fighters)
	remove_fighter(first)
	var/mob/living/carbon/human/species/skeleton/first_skeleton = new /mob/living/carbon/human/species/skeleton/death_arena(get_turf(first_spawn))
	first_skeleton.name = first.livingname
	first_skeleton.ckey = first.ckey
	RegisterSignal(first_skeleton, COMSIG_LIVING_DEATH, PROC_REF(open_death_gate))

	var/mob/living/carbon/spirit/second = pick(waiting_fighters)
	remove_fighter(second)
	var/mob/living/carbon/human/species/skeleton/second_skeleton = new /mob/living/carbon/human/species/skeleton/death_arena(get_turf(second_spawn))
	second_skeleton.name = second.livingname
	second_skeleton.ckey = second.ckey
	RegisterSignal(second_skeleton, COMSIG_LIVING_DEATH, PROC_REF(open_death_gate))

	fighters = list(first_skeleton, second_skeleton)

	fighters_heads = list(first_skeleton.get_bodypart(BODY_ZONE_HEAD), second_skeleton.get_bodypart(BODY_ZONE_HEAD))

	first_skeleton.forceMove(get_turf(first_spawn))
	second_skeleton.forceMove(get_turf(second_spawn))

	qdel(first)
	qdel(second)

	if(!first_skeleton.ckey && !second_skeleton.ckey)
		end_fight_no_client()

	fight_force_end = world.time + 10 MINUTES

/datum/controller/subsystem/death_arena/proc/try_end_fight(obj/item/bodypart/head/head, mob/living/carbon/user)
	if(!istype(head))
		return FALSE
	if(!(head in fighters_heads))
		return FALSE
	return TRUE

/datum/controller/subsystem/death_arena/proc/process_fight_end(obj/item/bodypart/head/head, mob/living/carbon/user)
	if(!try_end_fight(head, user))
		return

	fighters_heads = list()
	user.returntolobby()
	tollless_clients -= user.client

	for(var/mob/living/carbon/carbon in fighters)
		fighters -= carbon
		if(carbon != user)
			var/turf/spawn_loc = pick(GLOB.underworldcoinspawns)
			var/mob/living/carbon/spirit/O = new /mob/living/carbon/spirit(spawn_loc)
			O.livingname = carbon.name
			O.ckey = carbon.ckey
			ADD_TRAIT(O, TRAIT_PACIFISM, TRAIT_GENERIC)
			add_fighter(O)
		qdel(carbon)
	fighters = list()

	fighting = FALSE
	close_death_gate()
	fight_force_end = null

/datum/controller/subsystem/death_arena/proc/force_end_fight()
	fighters_heads = list()
	for(var/mob/living/carbon/carbon in fighters)
		fighters -= carbon
		carbon.returntolobby()
		qdel(carbon)
	fight_force_end = null
	fighting = FALSE

/datum/controller/subsystem/death_arena/proc/end_fight_no_client()
	fighters_heads = list()
	for(var/mob/living/carbon/carbon in fighters)
		fighters -= carbon
		qdel(carbon)
	fight_force_end = null
	fighting = FALSE

/datum/controller/subsystem/death_arena/proc/open_death_gate()
	for(var/obj/structure/gate/G in GLOB.biggates)
		if(G.gid != "death")
			continue
		G.open()

/datum/controller/subsystem/death_arena/proc/close_death_gate()
	for(var/obj/structure/gate/G in GLOB.biggates)
		if(G.gid != "death")
			continue
		G.close()

/datum/controller/subsystem/death_arena/proc/assign_death_spawn(atom/movable/movable)
	if(!first_spawn)
		first_spawn = get_turf(movable)
		return
	if(!second_spawn)
		second_spawn = get_turf(movable)
		return

/datum/outfit/job/roguetown/arena_skeleton/pre_equip(mob/living/carbon/human/H, visualsOnly)
	..()
	H.change_stat("strength", 1)
	H.change_stat("endurance", 1)

	H.mind?.adjust_skillrank(/datum/skill/combat/axesmaces, 2, TRUE)
	H.mind?.adjust_skillrank(/datum/skill/combat/swords, 2, TRUE)

	r_hand = /obj/item/rogueweapon/mace/steel
	l_hand = /obj/item/rogueweapon/shield/wood
	belt = /obj/item/storage/belt/rogue/leather
	beltr = /obj/item/rogueweapon/axe/iron


/obj/structure/table/wood/fine/altar
	name = "Ravox's sacrifical altar"
	desc = "It awaits an offering of your triumphs"
	icon = 'icons/roguetown/misc/structure.dmi'
	icon_state = "ravox_altar"

/obj/structure/table/wood/fine/altar/after_added_effects(obj/item/item, mob/user)
	if(!istype(item, /obj/item/bodypart/head))
		return
	SSdeath_arena.process_fight_end(item, user)

/obj/structure/underworld/ravox
	name = "Ravox"
	desc = "Ravox, God of Warfare, Justice, and Bravery. He finds solice in his friendship with Necra and his retreat to the Underworld. Upon your gaze, he gives you a respectful nod. Damn, he's cool.."
	icon = 'icons/roguetown/underworld/ravox.dmi'
	icon_state = "ravox"
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE_UPPER
	anchored = TRUE
	density = TRUE


/obj/structure/underworld/necra
	name = "Necra"
	desc = "The Undermaiden herself, in her true form. The most ancient of living gods. She observes your battles gleefully, gratitude in her eyes to be relieved from the arduousness of eternity. Her close friend and confidant, Ravox, sits by her side. The two must have worked hard to restructure the underworld like this. They seem pleased with their work."
	icon = 'icons/roguetown/underworld/necra.dmi'
	icon_state = "necra"
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE_UPPER
	anchored = TRUE
	density = TRUE

/obj/structure/underworld/necra/Initialize()
	. = ..()
	set_light(5, 4, 30, l_color = LIGHT_COLOR_BLUE)
