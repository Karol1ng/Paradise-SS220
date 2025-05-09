/// This bot is powerful. If you managed to get 4 eswords somehow, you deserve this horror. Emag him for best results.
/mob/living/simple_animal/bot/secbot/griefsky
	name = "\improper General Griefsky"
	desc = "Is that a secbot with four eswords in its arms...?"
	icon_state = "griefsky0"
	health = 100
	maxHealth = 100
	base_icon = "griefsky"
	window_name = "Automatic Security Unit v3.0"
	bot_type = GRIEF_BOT
	model = "Griefsky"
	var/spin_icon = "griefsky-c"  // griefsky and griefsky junior have dif icons
	var/weapon = /obj/item/melee/energy/sword/saber
	var/block_chance = 50   //block attacks
	var/reflect_chance = 80 // chance to reflect projectiles
	var/dmg = 30 //esword dmg
	var/block_chance_melee = 50
	var/block_chance_ranged = 90
	var/stun_chance = 50
	var/spam_flag = 0
	var/frustration_number = 15

/// A toy version of general griefsky!
/mob/living/simple_animal/bot/secbot/griefsky/toy
	name = "Genewul Giftskee"
	desc = "An adorable looking secbot with four toy swords taped to its arms."
	spin_icon = "griefskyj-c"
	health = 50
	maxHealth = 50
	radio_channel = "Service" //we dont report sec anymore!
	dmg = 0
	block_chance_melee = 1
	block_chance_ranged = 1
	stun_chance = 0
	req_access = list(ACCESS_MAINT_TUNNELS, ACCESS_THEATRE, ACCESS_ROBOTICS)
	weapon = /obj/item/toy/sword
	frustration_number = 5
	locked = FALSE

/mob/living/simple_animal/bot/secbot/griefsky/proc/spam_flag_false() //used for addtimer to not spam comms
	spam_flag = 0

/mob/living/simple_animal/bot/secbot/griefsky/back_to_idle()
	..()
	playsound(loc, 'sound/weapons/saberoff.ogg', 50, TRUE, -1)

/mob/living/simple_animal/bot/secbot/griefsky/emag_act(mob/user)
	..()
	light_color = LIGHT_COLOR_PURE_RED //if you see a red one. RUN!!

/mob/living/simple_animal/bot/secbot/griefsky/on_atom_entered(datum/source, atom/movable/entered)
	if(iscarbon(entered) && entered == target)
		var/mob/living/carbon/C = entered
		visible_message("[src] flails his swords and pushes [C] out of it's way!" )
		C.KnockDown(4 SECONDS)

/mob/living/simple_animal/bot/secbot/griefsky/Initialize(mapload)
	. = ..()
	icon_state = "[base_icon][on]"
	var/datum/job/detective/J = new/datum/job/detective
	access_card.access += J.get_access()
	prev_access = access_card.access


/mob/living/simple_animal/bot/secbot/griefsky/UnarmedAttack(atom/A) //like secbots its only possible with admin intervention
	if(!on)
		return
	if(iscarbon(A))
		var/mob/living/carbon/C = A
		sword_attack(C)

/mob/living/simple_animal/bot/secbot/griefsky/bullet_act(obj/item/projectile/P) //so uncivilized
	retaliate(P.firer)
	if((icon_state == spin_icon) && (prob(block_chance_ranged))) //only when the eswords are on
		visible_message("[src] deflects [P] with its energy swords!")
		playsound(loc, 'sound/weapons/blade1.ogg', 50, TRUE, 0)
	else
		..()

/mob/living/simple_animal/bot/secbot/griefsky/proc/sword_attack(mob/living/carbon/C)     // esword attack
	do_attack_animation(C)
	playsound(loc, 'sound/weapons/blade1.ogg', 50, TRUE, -1)
	addtimer(CALLBACK(src, PROC_REF(do_sword_attack), C), 2)

/mob/living/simple_animal/bot/secbot/griefsky/proc/do_sword_attack(mob/living/carbon/C)
	icon_state = spin_icon
	var/threat = C.assess_threat(src)
	if(ishuman(C))
		C.apply_damage(dmg, BRUTE)
		if(prob(stun_chance))
			C.Weaken(10 SECONDS)
	if(dmg)
		add_attack_logs(src, C, "sliced")
	if(declare_arrests)
		var/area/location = get_area(src)
		if(!spam_flag)
			speak("Назад! Я сам разберусь со свиньей <b>[C]</b> с уровнем угрозы [threat] в [location]!.", radio_channel)
			spam_flag = 1
			addtimer(CALLBACK(src, PROC_REF(spam_flag_false)), 100) //to avoid spamming comms of sec for each hit
			visible_message("[src] flails his swords and cuts [C]!")


/mob/living/simple_animal/bot/secbot/griefsky/handle_automated_action()
	if(!on)
		return

	if(hijacked)
		return // is there a good reason this override doesn't call its parent?

	switch(mode)
		if(BOT_IDLE)		// idle
			icon_state = "griefsky1"
			GLOB.move_manager.stop_looping(src)
			set_path(null)
			if(find_new_target())
				return	// see if any criminals are in range
			if(!mode && auto_patrol)	// still idle, and set to patrol
				set_mode(BOT_START_PATROL)	// switch to patrol mode
		if(BOT_HUNT)		// hunting for perp
			icon_state = spin_icon
			playsound(loc,'sound/effects/spinsabre.ogg',50, TRUE,-1)
			if(frustration >= frustration_number) // general beepsky doesn't give up so easily, jedi scum
				GLOB.move_manager.stop_looping(src)
				set_path(null)
				back_to_idle()
				return

			if(!target)		// make sure target exists
				back_to_idle()
				speak("Неудачник")
				return

			if(target.stat == DEAD)
				back_to_idle()
				return

			if(Adjacent(target) && isturf(target.loc))	// if right next to perp
				target_lastloc = target.loc
				sword_attack(target)
				anchored = TRUE
				frustration++
				return							// not next to perp

			try_chasing_target(target)

		if(BOT_START_PATROL)
			if(find_new_target())
				return
			start_patrol()

		if(BOT_PATROL)
			icon_state = "griefsky1"
			if(find_new_target())
				return
			bot_patrol()
	return

/mob/living/simple_animal/bot/secbot/griefsky/find_new_target()
	anchored = FALSE
	for(var/mob/living/carbon/C in view(7,src)) //Let's find us a criminal
		if((C.stat) || (C.handcuffed))
			continue

		if((C.name == oldtarget_name) && (world.time < last_found + 100))
			continue

		threatlevel = C.assess_threat(src)

		if(!threatlevel || threatlevel < 4)
			continue

		target = C
		oldtarget_name = C.name
		speak("Смелый дохуя?")
		playsound(src,'sound/weapons/saberon.ogg', 50, TRUE, -1)
		visible_message("[src] ignites his energy swords!")
		icon_state = "griefsky-c"
		visible_message("<b>[src]</b> points at [C.name]!")
		set_mode(BOT_HUNT)
		INVOKE_ASYNC(src, PROC_REF(handle_automated_action))
		return TRUE
	return FALSE

/mob/living/simple_animal/bot/secbot/griefsky/explode()
	GLOB.move_manager.stop_looping(src)
	visible_message("<span class='boldannounceic'>[src] lets out a huge cough as it blows apart!</span>")
	var/turf/Tsec = get_turf(src)
	new /obj/item/assembly/prox_sensor(Tsec)
	var/obj/item/secbot_assembly/Sa = new /obj/item/secbot_assembly(Tsec)
	Sa.build_step = 1
	Sa.overlays += "hs_hole"
	Sa.created_name = name
	if(prob(50))
		new /obj/item/robot_parts/r_arm(Tsec)
	if(prob(50)) //most of the time weapon will be destroyed
		new weapon(Tsec)
	if(prob(25))
		new weapon(Tsec)
	if(prob(10))
		new weapon(Tsec)
	if(prob(5))
		new weapon(Tsec)
	do_sparks(3, 1, src)
	new /obj/effect/decal/cleanable/blood/oil(loc)
	..()

//this section is blocking attack

/mob/living/simple_animal/bot/secbot/griefsky/proc/special_retaliate_after_attack(mob/user)
	if(icon_state != spin_icon)
		return
	if(prob(block_chance_melee))
		visible_message("[src] deflects [user]'s attack with his energy swords!")
		playsound(loc, 'sound/weapons/blade1.ogg', 50, TRUE, -1)
		return TRUE

/mob/living/simple_animal/bot/secbot/griefsky/attack_hand(mob/living/carbon/human/H)
	if((H.a_intent == INTENT_HARM) || (H.a_intent == INTENT_DISARM))
		retaliate(H)
		if(special_retaliate_after_attack(H))
			return
	return ..()

// cant touch or attack him while spinning
/mob/living/simple_animal/bot/secbot/griefsky/attack_by(obj/item/W, mob/living/user, params)
	if(..())
		return FINISH_ATTACK

	if(src.icon_state == spin_icon)
		if(prob(block_chance_melee))
			user.changeNext_move(CLICK_CD_MELEE)
			user.do_attack_animation(src)
			visible_message("[src] deflects [user]'s move with his energy swords!")
			playsound(loc, 'sound/weapons/blade1.ogg', 50, TRUE, -1)
			return FINISH_ATTACK
