/*
 * AI Saycode
 */


/mob/living/silicon/ai/handle_track(message, verb = "says", atom/movable/speaker = null, speaker_name, atom/follow_target, hard_to_hear)
	if(hard_to_hear)
		return

	var/jobname // the mob's "job"
	var/mob/living/carbon/human/impersonating //The crewmember being impersonated, if any.
	var/changed_voice

	if(ishuman(speaker))
		var/mob/living/carbon/human/H = speaker

		var/obj/item/card/id/id = H.wear_id
		if((istype(id) && id.is_untrackable()) && H.HasVoiceChanger())
			changed_voice = 1
			var/mob/living/carbon/human/I = locate(speaker_name)
			if(I)
				impersonating = I
				jobname = impersonating.get_assignment()
			else
				jobname = "Неизвестный"
		else
			jobname = H.get_assignment()

	else if(iscarbon(speaker)) // Nonhuman carbon mob
		jobname = "Без ID"
	else if(is_ai(speaker))
		jobname = "ИИ"
	else if(isrobot(speaker))
		jobname = "Киборг"
	else if(ispAI(speaker))
		jobname = "Персональный ИИ"
	else if(isradio(speaker))
		jobname = "Automated Announcement"
	else
		jobname = "Неизвестно"

	var/track = ""
	var/mob/mob_to_track = null
	if(changed_voice)
		if(impersonating)
			mob_to_track = impersonating
		else
			track = "[speaker_name] ([jobname])"
	else
		if(isbot(follow_target))
			track = "<a href='byond://?src=[UID()];trackbot=\ref[follow_target]'>[speaker_name] ([jobname])</a>"
		else
			mob_to_track = speaker

	if(mob_to_track)
		track = "<a href='byond://?src=[UID()];track=\ref[mob_to_track]'>[speaker_name] ([jobname])</a>"
		track += "&nbsp;<a href='byond://?src=[UID()];open=\ref[mob_to_track]'>\[Open\]</a>"

	return track



/*
 * AI VOX Announcements
 */

GLOBAL_VAR_INIT(announcing_vox, 0) // Stores the time of the last announcement
#define VOX_DELAY 100
#define VOX_PATH "sound/vox_fem/"

/mob/living/silicon/ai/verb/announcement_help()
	set name = "Справочник оповещений"
	set desc = "Показывает список слов для оповещения экипажа."
	set category = "Команды ИИ"

	if(!ai_announcement_string_menu)
		var/list/dat = list()

		dat += "Вот список слов, которые вы можете вписать в 'Оповещение' для создания предложений для звукового оповещения экипажа на том же Z-уровне, что и вы.<br> \
		<ul><li>Вы можете также кликать на слова для предпросмотра.</li>\
		<li>Вы можете использовать не более 30 слов в одном оповещении.</li>\
		<li>Не используйте пунктуацию как обычно, если вы хотите поставить паузу, используйте точку или запятую, отделяя их пробелами, как пример: 'Alpha . Test , Bravo'.</li></ul>\
		<font class='bad'>WARNING:</font><br>Misuse of the announcement system will get you job banned.<hr>"

		// Show alert and voice sounds separately
		var/vox_words = GLOB.vox_sounds - GLOB.vox_alerts
		dat += help_format(GLOB.vox_alerts)
		dat += "<hr>"
		dat += help_format(vox_words)

		ai_announcement_string_menu = dat.Join("")

	var/datum/browser/popup = new(src, "announce_help", "Справочник оповещений", 500, 400)
	popup.set_content(ai_announcement_string_menu)
	popup.open()

/mob/living/silicon/ai/proc/help_format(word_list)
	var/list/localdat = list()
	var/uid_cache = UID() // Saves proc jumping
	for(var/word in word_list)
		localdat += "<a href='byond://?src=[uid_cache];say_word=[word]'>[word]</a>"
	return localdat.Join(" / ")

/mob/living/silicon/ai/proc/ai_announcement()
	if(check_unable(AI_CHECK_WIRELESS | AI_CHECK_RADIO))
		return

	if(GLOB.announcing_vox > world.time)
		to_chat(src, "<span class='warning'>Пожалуйста подождите [round((GLOB.announcing_vox - world.time) / 10)] [declension_ru(round((GLOB.announcing_vox - world.time) / 10), "секунду", "секунды", "секунд")].</span>")
		return

	var/message = tgui_input_text(src, "Внимание: Неправильное использование этой системы может привести к джоббану. Для справки обращайтесь к 'Справочнику оповещений'", "Оповещение", last_announcement)

	last_announcement = message

	if(check_unable(AI_CHECK_WIRELESS | AI_CHECK_RADIO))
		return

	if(!message || GLOB.announcing_vox > world.time)
		return

	var/list/words = splittext(trim(message), " ")
	var/list/incorrect_words = list()

	if(length(words) > 30)
		words.Cut(31)

	for(var/word in words)
		word = lowertext(trim(word))
		if(!word)
			words -= word
			continue
		if(!GLOB.vox_sounds[word])
			incorrect_words += word

	if(length(incorrect_words))
		to_chat(src, "<span class='warning'>Эти слова недоступны в системе оповещений: [english_list(incorrect_words)].</span>")
		return

	GLOB.announcing_vox = world.time + VOX_DELAY

	log_game("[key_name(src)] сделал звуковое оповещение: [message].")
	message_admins("[key_name_admin(src)] made a vocal announcement: [message].")

	for(var/word in words)
		play_vox_word(word, z, null)

	ai_voice_announcement_to_text(words)

/mob/living/silicon/ai/proc/ai_voice_announcement_to_text(words)
	var/words_string = jointext(words, " ")
	// Don't go through .Announce because we need to filter by clients which have TTS enabled
	var/formatted_message = announcer.Format(words_string, "Оповещение ИИ")

	var/announce_sound = sound('sound/misc/notice2.ogg')
	for(var/player in GLOB.player_list)
		var/mob/M = player
		if(M.client && !(M.client.prefs.sound & SOUND_AI_VOICE))
			var/turf/T = get_turf(M)
			if(T && T.z == z && M.can_hear())
				SEND_SOUND(M, announce_sound)
				to_chat(M, formatted_message)

/proc/play_vox_word(word, z_level, mob/only_listener)

	word = lowertext(word)

	if(GLOB.vox_sounds[word])

		var/sound_file = GLOB.vox_sounds[word]
		var/sound/voice = sound(sound_file, wait = 1, channel = CHANNEL_VOX)
		voice.status = SOUND_STREAM

		// If there is no single listener, broadcast to everyone in the same z level
		if(!only_listener)
			// Play voice for all mobs in the z level
			for(var/mob/M in GLOB.player_list)
				if(M.client && M.client.prefs.sound & SOUND_AI_VOICE)
					var/turf/T = get_turf(M)
					if(T && T.z == z_level && M.can_hear())
						voice.volume = 100 * M.client.prefs.get_channel_volume(CHANNEL_VOX)
						M << voice
		else
			only_listener << voice
		return 1
	return 0

// VOX sounds moved to /code/defines/vox_sounds.dm

/client/proc/preload_vox()
	var/list/vox_files = flist(VOX_PATH)
	for(var/file in vox_files)
//	to_chat(src, "Downloading [file]")
		var/sound/S = sound("[VOX_PATH][file]")
		src << browse_rsc(S)

#undef VOX_DELAY
#undef VOX_PATH
