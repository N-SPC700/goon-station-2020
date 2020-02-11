/obj/item/clothing
	name = "clothing"
	//var/obj/item/clothing/master = null
	w_class = 2.0

	var/see_face = 1

	var/body_parts_covered = 0 //see setup.dm for appropriate bit flags
	//var/c_flags = null // these don't need to be in the general flags when they only apply to clothes  :I
	// mbc moived c flags up to item bewcause some wearaables things are items and not clothign :)

	var/color_r = 1 // used for vision stuff, see human/handle_regular_hud_updates()
	var/color_g = 1 // (why were these only on crafted glasses?  they could have just been used on the parent like this from the start  :V)
	var/color_b = 1

	var/protective_temperature = 0
	var/permeability_coefficient = 1 // for chemicals/diseases
	var/magical = 0 // for wizard item spell power check
	var/chemicalprotection = 0 //chemsuit and chemhood in combination grant this

	var/list/compatible_species = list("human") // allow monkeys/mutantraces to wear certain garments

	var/fallen_offset_x = 1
	var/fallen_offset_z = -6
	/// we want to use Z rather than Y incase anything gets rotated, it would look all jank
	var/monkey_clothes = 0
	// it's clothes specifically for monkeys please don't plaster it to their chest with an offset

	stamina_damage = 1
	stamina_cost = 1
	stamina_crit_chance = 0

	flags = FPRINT | TABLEPASS
	var/can_stain = 1
	var/list/stains = null

	New()
		..()
		src.real_name = src.name // meh will probably grab any custom names like this

	onMaterialChanged()
		..()
		if(istype(src.material))
			protective_temperature = (material.getProperty("flammable") - 50) * (-1)
			setProperty("meleeprot", material.hasProperty("hard") ? round(min(max((material.getProperty("hard") - 50) / 15.25, 0), 3)) : getProperty("meleeprot"))
		return

	UpdateName()
		src.name = "[name_prefix(null, 1)][src.get_stains()][src.real_name ? src.real_name : initial(src.name)][name_suffix(null, 1)]"

	proc/add_stain(var/stn)
		if (!stn || !src.can_stain)
			return
		if (!islist(src.stains))
			src.stains = list()
		else if (src.stains.Find(stn))
			return
		src.stains += stn
		src.UpdateName()

	proc/get_stains()
		if (src.can_stain && islist(src.stains) && src.stains.len)
			for (var/i in src.stains)
				. += i + " "

/obj/item/clothing/under
	equipped(var/mob/user, var/slot)
		..()
		playsound(src.loc, 'sound/items/zipper.ogg', 30, 0.2, pitch = 2)

/*
/obj/item/clothing/fire_burn(obj/fire/raging_fire, datum/air_group/environment)
	if(raging_fire.internal_temperature > src.s_fire)
		SPAWN_DBG( 0 )
			var/t = src.icon_state
			src.icon_state = ""
			src.icon = 'b_items.dmi'
			flick(text("[]", t), src)
			SPAWN_DBG(14)
				qdel(src)
				return
			return
		return 0
	return 1
*/ //TODO FIX