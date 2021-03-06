var/datum/telescope_manager/tele_man
var/list/special_places = list() //associative List of name=/datum/computer/file/coords that can not be reached normally. For use with the telescope

var/list/magnet_locations = list()

/obj/lrteleporter
	name = "Experimental long-range teleporter"
	desc = "Well this looks somewhat unsafe."
	icon = 'icons/misc/32x64.dmi'
	icon_state = "lrport"
	density = 0
	anchored = 1
	var/busy = 0
	layer = 2

	attack_ai(mob/user as mob)
		return attack_hand(user)

	attack_hand(mob/user as mob)
		var/link_html = "<br>"

		if(special_places.len)
			for(var/A in special_places)
				link_html += {"[A] <a href='?src=\ref[src];send=\ref[special_places[A]]'><small>(Send)</small></a> <a href='?src=\ref[src];recieve=\ref[special_places[A]]'><small>(Recieve)</small></a><br>"}
		else
			link_html = "<br>No co-ordinates available.<br>"

		var/html = {"<!doctype html>
			<meta http-equiv="X-UA-Compatible" content="IE=edge,chrome=1">
			<html>
			<head>
			<title>Long-range teleporter</title>
			</head>
			<body style="overflow:auto;background-color: #eeeeee;">
			<p>Long-range destinations:</p><br>
			[link_html]
			</body>
			"}

		user.machine = src
		add_fingerprint(user)
		user.Browse(html, "window=lrporter;size=250x380;can_resize=0;can_minimize=0;can_close=1;override_setting=1")
		onclose(user, "lrporter", src)

	proc/is_good_location(var/datum/computer/file/coords/C)
		if(special_places.len)
			for(var/A in special_places)
				if (C == special_places[A])
					return 1

			return 0
		else
			return 0

	Topic(href, href_list)
		if(busy) return
		if(get_dist(usr, src) > 1 || usr.z != src.z) return

		if(href_list["send"])
			var/datum/computer/file/coords/C = locate(href_list["send"])
			if(!C)
				boutput(usr, "DEBUG: C=[C], Name=[href_list["send"]], len=[special_places.len], inplaces=[(href_list["send"] in special_places)]")
			var/turf/target = locate(C.destx, C.desty, C.destz)
			if(target && is_good_location(C))
				busy = 1
				flick("lrport1", src)
				playsound(src, 'sound/machines/lrteleport.ogg', 60, 1)
				for(var/atom/movable/M in src.loc)
					if(M.anchored) continue
					animate_teleport(M)
					if(ismob(M))
						var/mob/O = M
						O.changeStatus("stunned", 2 SECONDS)
					SPAWN_DBG(6) M.set_loc(target)
				SPAWN_DBG(10) busy = 0

		if(href_list["recieve"])
			var/datum/computer/file/coords/C = locate(href_list["recieve"])
			var/turf/target = locate(C.destx, C.desty, C.destz)
			if(target && is_good_location(C))
				busy = 1
				flick("lrport1", src)
				playsound(src, 'sound/machines/lrteleport.ogg', 60, 1)
				for(var/atom/movable/M in target)
					if(M.anchored) continue
					animate_teleport(M)
					if(ismob(M))
						var/mob/O = M
						O.changeStatus("stunned", 2 SECONDS)
					SPAWN_DBG(6) M.set_loc(src.loc)
				SPAWN_DBG(10) busy = 0

//////////////////////////////////////////////////
/datum/telescope_manager
	var/list/events_inactive = list() //Events that are currently not visible but might show up.
	var/list/events_active = list()	  //Events that are currently visible but not found.
	var/list/events_found = list()    //Events that are currently visible AND found.

	proc/setup()
		var/types = childrentypesof(/datum/telescope_event)
		for(var/x in types)
			var/datum/telescope_event/R = new x(src)
			if(R.manual) continue
			events_inactive.Add(R.id)
			events_inactive[R.id] = R
			if(!R.fixed_location)
				R.loc_x = rand(0, 640)
				R.loc_y = rand(0, 431)
		return

	proc/tick()
		if(events_active.len < 3)

			var/can_spawn = 0 //If there's only events with less than 100% rarity left, we don't spawn anything.
			//This is to stop the system from spawning only rare events when there's few left.

			for(var/I in events_inactive)
				var/datum/telescope_event/EI = events_inactive[I]
				if(EI.disabled) continue
				if(EI.rarity >= 100)
					can_spawn = 1
					break

			if(can_spawn && events_inactive.len && prob(33))

				var/list/choices = list()
				var/list/weights = list()

				for(var/A in events_inactive)
					var/datum/telescope_event/E = events_inactive[A]
					if(E.disabled) continue
					choices.Add(A)
					weights.Add(E.rarity)

				var/chosen_id = weightedprob(choices, weights)
				var/datum/telescope_event/T = events_inactive[chosen_id]

				if(T)
					events_active.Add(T.id)
					events_active[T.id] = T
					events_inactive.Remove(T.id)
		return

	proc/addManualEvent(var/eventType = null, var/active=1)
		if(ispath(eventType, /datum/telescope_event))
			var/datum/telescope_event/E = new eventType(src)
			if(!E.fixed_location)
				E.loc_x = rand(0, 640)
				E.loc_y = rand(0, 431)
			if(active)
				if(!events_active.Find(E.id))
					events_active.Add(E.id)
					events_active[E.id] = E
			else
				if(!events_inactive.Find(E.id))
					events_inactive.Add(E.id)
					events_inactive[E.id] = E
			return E
		else
			return null


///MISC EVENT ETC RELATED BELOW
/obj/critter/gunbot/drone/buzzdrone/naniteswarm
	name = "nanite swarm"
	desc = "A swarm of angry nanites."
	icon_state = "nanites"
	dead_state = "nanites-dead"
	icon = 'icons/misc/critter.dmi'
	health = 30
	maxhealth = 30
	score = 1
	projectile_type = /datum/projectile/laser/drill/cutter
	current_projectile = new/datum/projectile/laser/drill/cutter
	droploot = null
	smashes_shit = 1

	ChaseAttack(atom/M)
		if(target && !attacking)
			attacking = 1
			src.visible_message("<span style=\"color:red\"><b>[src]</b> floats towards [M]!</span>")
			walk_to(src, src.target,1,4)
			var/tturf = get_turf(M)
			Shoot(tturf, src.loc, src)
			SPAWN_DBG(attack_cooldown)
				attacking = 0
		return

	CritterAttack(atom/M)
		if(target && !attacking)
			attacking = 1
			//playsound(src.loc, "sound/machines/whistlebeep.ogg", 55, 1)
			src.visible_message("<span style=\"color:red\"><b>[src]</b> shreds [M]!</span>")

			var/tturf = get_turf(M)
			Shoot(tturf, src.loc, src)
			SPAWN_DBG(attack_cooldown)
				attacking = 0
		return

	New()
		..()
		name = "Nanite Swarm Cluster NN-[rand(1,999)]"
		return

	CritterDeath()
		if(prob(20) && alive)
			src.visible_message("<span style=\"color:red\"><b>[src]</b> begins to reassemble!</span>")
			var/turf/T = src.loc
			SPAWN_DBG(50)
				new/obj/critter/gunbot/drone/buzzdrone/naniteswarm(T)
				if(src)
					qdel(src)

		if(prob(1) && alive)
			new/obj/item/material_piece/iridiumalloy(src.loc)

		..()
