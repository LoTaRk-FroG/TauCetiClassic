// Pretty much everything here is stolen from the dna scanner FYI


/obj/machinery/bodyscanner
	var/locked
	name = "Body Scanner"
	desc = "Used for a more detailed analysis of the patient."
	icon = 'icons/obj/Cryogenic3.dmi'
	icon_state = "body_scanner_0"
	density = TRUE
	anchored = TRUE
	light_color = "#00ff00"
	required_skills = list(/datum/skill/medical = SKILL_LEVEL_NOVICE)

/obj/machinery/bodyscanner/power_change()
	..()
	if(!(stat & (BROKEN|NOPOWER)))
		set_light(2)
	else
		set_light(0)

/obj/machinery/bodyscanner/relaymove(mob/user)
	if(!user.incapacitated())
		open_machine()

/obj/machinery/bodyscanner/verb/eject()
	set src in oview(1)
	set category = "Object"
	set name = "Eject Body Scanner"

	if (usr.incapacitated())
		return
	open_machine()
	add_fingerprint(usr)
	return

/obj/machinery/bodyscanner/verb/move_inside()
	set src in oview(1)
	set category = "Object"
	set name = "Enter Body Scanner"

	if (usr.incapacitated())
		return
	if(!move_inside_checks(usr, usr))
		return
	close_machine(usr, usr)

/obj/machinery/bodyscanner/proc/move_inside_checks(mob/target, mob/user)
	if(occupant)
		to_chat(user, "<span class='userdanger'>The scanner is already occupied!</span>")
		return FALSE
	if(!iscarbon(target))
		return FALSE
	if(target.abiotic())
		to_chat(user, "<span class='userdanger'>Subject cannot have abiotic items on.</span>")
		return FALSE
	if(!do_skill_checks(user))
		return
	return TRUE

/obj/machinery/bodyscanner/attackby(obj/item/weapon/grab/G, mob/user)
	if(!istype(G))
		return
	if(!move_inside_checks(G.affecting, user))
		return
	add_fingerprint(user)
	close_machine(G.affecting)
	playsound(src, 'sound/machines/analysis.ogg', VOL_EFFECTS_MASTER, null, FALSE)
	qdel(G)

/obj/machinery/bodyscanner/update_icon()
	icon_state = "body_scanner_[occupant ? "1" : "0"]"

/obj/machinery/bodyscanner/MouseDrop_T(mob/target, mob/user)
	if(user.incapacitated())
		return
	if(!user.IsAdvancedToolUser())
		to_chat(user, "<span class='warning'>You can not comprehend what to do with this.</span>")
		return
	if(!move_inside_checks(target, user))
		return
	add_fingerprint(user)
	close_machine(target)
	playsound(src, 'sound/machines/analysis.ogg', VOL_EFFECTS_MASTER, null, FALSE)

/obj/machinery/bodyscanner/AltClick(mob/user)
	if(user.incapacitated() || !Adjacent(user))
		return
	if(!user.IsAdvancedToolUser())
		to_chat(user, "<span class='warning'>You can not comprehend what to do with this.</span>")
		return
	if(occupant)
		open_machine()
		add_fingerprint(user)
		return
	var/mob/living/carbon/target = locate() in loc
	if(!target)
		return
	if(!move_inside_checks(target, user))
		return
	add_fingerprint(user)
	close_machine(target)
	playsound(src, 'sound/machines/analysis.ogg', VOL_EFFECTS_MASTER, null, FALSE)

/obj/machinery/bodyscanner/ex_act(severity)
	switch(severity)
		if(EXPLODE_HEAVY)
			if(prob(50))
				return
		if(EXPLODE_LIGHT)
			if(prob(75))
				return
	for(var/atom/movable/A in src)
		A.forceMove(loc)
		ex_act(severity)
	qdel(src)

/obj/machinery/bodyscanner/deconstruct(disassembled)
	for(var/atom/movable/A in src)
		A.forceMove(loc)
	..()

/obj/machinery/body_scanconsole/power_change()
	if(stat & BROKEN)
		icon_state = "body_scannerconsole-p"
	else if(powered())
		icon_state = initial(icon_state)
		stat &= ~NOPOWER
	else
		spawn(rand(0, 15))
			src.icon_state = "body_scannerconsole-p"
			stat |= NOPOWER
			update_power_use()
	update_power_use()

/obj/machinery/body_scanconsole
	var/obj/machinery/bodyscanner/connected
	var/known_implants = list(/obj/item/weapon/implant/chem, /obj/item/weapon/implant/death_alarm, /obj/item/weapon/implant/mind_protect/mindshield, /obj/item/weapon/implant/tracking, /obj/item/weapon/implant/mind_protect/loyalty, /obj/item/weapon/implant/obedience, /obj/item/weapon/implant/skill)
	var/delete
	name = "Body Scanner Console"
	icon = 'icons/obj/Cryogenic3.dmi'
	icon_state = "body_scannerconsole"
	anchored = TRUE
	var/next_print = 0
	var/storedinfo = null
	required_skills = list(/datum/skill/medical = SKILL_LEVEL_TRAINED)

/obj/machinery/body_scanconsole/atom_init()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/body_scanconsole/atom_init_late()
	connected = locate(/obj/machinery/bodyscanner) in orange(1, src)

/obj/machinery/body_scanconsole/ui_interact(mob/user)
	if(!ishuman(connected.occupant))
		to_chat(user, "<span class='warning'>This device can only scan compatible lifeforms.</span>")
		return
	if(!do_skill_checks(user))
		return
	var/dat

	if (src.connected) //Is something connected?
		var/mob/living/carbon/human/occupant = src.connected.occupant
		dat = "<font color='blue'><B>Occupant Statistics:</B></FONT><BR>" //Blah obvious
		if (istype(occupant)) //is there REALLY someone in there?
			var/t1
			switch(occupant.stat) // obvious, see what their status is
				if(0)
					t1 = "Conscious"
				if(1)
					t1 = "Unconscious"
				else
					t1 = "*dead*"
			if (!ishuman(occupant))
				dat += "<font color='red'>This device can only scan human occupants.</font>"
			else
				dat += text("<font color='[]'>\tHealth %: [] ([])</font><BR>", (occupant.health > 50 ? "blue" : "red"), occupant.health, t1)

				if(ischangeling(occupant) && occupant.fake_death)
					dat += text("<font color='red'>Abnormal bio-chemical activity detected!</font><BR>")

				if(occupant.virus2.len)
					dat += text("<font color='red'>Viral pathogen detected in blood stream.</font><BR>")

				dat += text("<font color='[]'>\t-Brute Damage %: []</font><BR>", (occupant.getBruteLoss() < 60 ? "blue" : "red"), occupant.getBruteLoss())
				dat += text("<font color='[]'>\t-Respiratory Damage %: []</font><BR>", (occupant.getOxyLoss() < 60 ? "blue" : "red"), occupant.getOxyLoss())
				dat += text("<font color='[]'>\t-Toxin Content %: []</font><BR>", (occupant.getToxLoss() < 60 ? "blue" : "red"), occupant.getToxLoss())
				dat += text("<font color='[]'>\t-Burn Severity %: []</font><BR><BR>", (occupant.getFireLoss() < 60 ? "blue" : "red"), occupant.getFireLoss())

				dat += text("<font color='[]'>\tRadiation Level %: []</font><BR>", (occupant.radiation < 10 ?"blue" : "red"), occupant.radiation)
				dat += text("<font color='[]'>\tGenetic Tissue Damage %: []</font><BR>", (occupant.getCloneLoss() < 1 ?"blue" : "red"), occupant.getCloneLoss())
				dat += text("<font color='[]'>\tApprox. Brain Damage %: []</font><BR>", (occupant.getBrainLoss() < 1 ?"blue" : "red"), occupant.getBrainLoss())
				var/occupant_paralysis = occupant.AmountParalyzed()
				dat += text("Paralysis Summary %: [] ([] seconds left!)<BR>", occupant_paralysis, round(occupant_paralysis / 4))
				dat += text("Body Temperature: [occupant.bodytemperature-T0C]&deg;C ([occupant.bodytemperature*1.8-459.67]&deg;F)<BR><HR>")

				if(occupant.has_brain_worms())
					dat += "Large growth detected in frontal lobe, possibly cancerous. Surgical removal is recommended.<BR/>"

				var/blood_volume = occupant.blood_amount()
				var/blood_percent =  100.0 * blood_volume / BLOOD_VOLUME_NORMAL
				dat += text("<font color='[]'>\tBlood Level %: [] ([] units)</font><BR>", (blood_volume >= BLOOD_VOLUME_SAFE ? "blue" : "red"), blood_percent, blood_volume)

				if(occupant.reagents)
					dat += text("Inaprovaline units: [] units<BR>", occupant.reagents.get_reagent_amount("inaprovaline"))
					dat += text("Soporific (Sleep Toxin): [] units<BR>", occupant.reagents.get_reagent_amount("stoxin"))
					dat += text("<font color='[]'>\tDermaline: [] units</font><BR>", (occupant.reagents.get_reagent_amount("dermaline") < 30 ? "black" : "red"), occupant.reagents.get_reagent_amount("dermaline"))
					dat += text("<font color='[]'>\tBicaridine: [] units</font><BR>", (occupant.reagents.get_reagent_amount("bicaridine") < 30 ? "black" : "red"), occupant.reagents.get_reagent_amount("bicaridine"))
					dat += text("<font color='[]'>\tDexalin: [] units</font><BR>", (occupant.reagents.get_reagent_amount("dexalin") < 30 ? "black" : "red"), occupant.reagents.get_reagent_amount("dexalin"))

				dat += "<HR><A href='?src=\ref[src];print=1'>Print body parts report</A><BR>"
				storedinfo = null
				dat += "<HR><table border='1'>"
				dat += "<tr>"
				dat += "<th>Body Part</th>"
				dat += "<th>Burn Damage</th>"
				dat += "<th>Brute Damage</th>"
				dat += "<th>Other Wounds</th>"
				dat += "</tr>"
				storedinfo += "<HR><table border='1'>"
				storedinfo += "<tr>"
				storedinfo += "<th>Body Part</th>"
				storedinfo += "<th>Burn Damage</th>"
				storedinfo += "<th>Brute Damage</th>"
				storedinfo += "<th>Other Wounds</th>"
				storedinfo += "</tr>"

				for(var/obj/item/organ/external/BP in occupant.bodyparts)

					dat += "<tr>"
					storedinfo += "<tr>"
					var/AN = ""
					var/open = ""
					var/infected = ""
					var/imp = ""
					var/bled = ""
					var/robot = ""
					var/splint = ""
					var/arterial_bleeding = ""
					var/rejecting = ""
					if(BP.status & ORGAN_ARTERY_CUT)
						arterial_bleeding = "<br>Arterial bleeding"
					if(BP.status & ORGAN_SPLINTED)
						splint = "Splinted:"
					if(BP.status & ORGAN_BLEEDING)
						bled = "Bleeding:"
					if(BP.status & ORGAN_BROKEN)
						AN = "[BP.broken_description]:"
					if(BP.is_robotic())
						robot = "Prosthetic:"
					if(BP.open)
						open = "Open:"
					if(BP.is_rejecting)
						rejecting = "Genetic Rejection:"
					switch (BP.germ_level)
						if (INFECTION_LEVEL_ONE to INFECTION_LEVEL_ONE_PLUS)
							infected = "Mild Infection:"
						if (INFECTION_LEVEL_ONE_PLUS to INFECTION_LEVEL_ONE_PLUS_PLUS)
							infected = "Mild Infection+:"
						if (INFECTION_LEVEL_ONE_PLUS_PLUS to INFECTION_LEVEL_TWO)
							infected = "Mild Infection++:"
						if (INFECTION_LEVEL_TWO to INFECTION_LEVEL_TWO_PLUS)
							infected = "Acute Infection:"
						if (INFECTION_LEVEL_TWO_PLUS to INFECTION_LEVEL_TWO_PLUS_PLUS)
							infected = "Acute Infection+:"
						if (INFECTION_LEVEL_TWO_PLUS_PLUS to INFECTION_LEVEL_THREE)
							infected = "Acute Infection++:"
						if (INFECTION_LEVEL_THREE to INFINITY)
							infected = "Septic:"

					var/unknown_body = 0
					for(var/I in BP.implants)
						if(is_type_in_list(I,known_implants))
							imp += "[I] implanted:"
						else
							unknown_body++

					if(unknown_body || BP.hidden)
						imp += "Unknown body present:"
					if(!AN && !open && !infected && !imp)
						AN = "None:"
					if(!(BP.is_stump))
						dat += "<td>[BP.name]</td><td>[BP.burn_dam]</td><td>[BP.brute_dam]</td><td>[robot][bled][AN][splint][open][infected][imp][arterial_bleeding][rejecting]</td>"
						storedinfo += "<td>[BP.name]</td><td>[BP.burn_dam]</td><td>[BP.brute_dam]</td><td>[robot][bled][AN][splint][open][infected][imp][arterial_bleeding][rejecting]</td>"
					else
						dat += "<td>[parse_zone(BP.body_zone)]</td><td>-</td><td>-</td><td>Not Found</td>"
						storedinfo += "<td>[parse_zone(BP.body_zone)]</td><td>-</td><td>-</td><td>Not Found</td>"
					dat += "</tr>"
					storedinfo += "</tr>"
				for(var/missing_zone in occupant.get_missing_bodyparts())
					dat += "<tr>"
					storedinfo += "<tr>"
					dat += "<td>[parse_zone(missing_zone)]</td><td>-</td><td>-</td><td>Not Found</td>"
					storedinfo += "<td>[parse_zone(missing_zone)]</td><td>-</td><td>-</td><td>Not Found</td>"
					dat += "</tr>"
					storedinfo += "</tr>"
				for(var/obj/item/organ/internal/IO in occupant.organs)
					var/mech = "Native:"
					var/organ_status = ""
					var/infection = ""
					if(IO.robotic == 1)
						mech = "Assisted:"
					if(IO.robotic == 2)
						mech = "Mechanical:"

					if(istype(IO, /obj/item/organ/internal/heart))
						var/obj/item/organ/internal/heart/Heart = IO
						if(Heart.heart_status == HEART_FAILURE)
							organ_status = "Heart Failure:"
						else if(Heart.heart_status == HEART_FIBR)
							organ_status = "Heart Fibrillation:"

					if(istype(IO, /obj/item/organ/internal/lungs))
						if(occupant.is_lung_ruptured())
							organ_status = "Lung ruptured:"

					switch (IO.germ_level)
						if (INFECTION_LEVEL_ONE to INFECTION_LEVEL_ONE_PLUS)
							infection = "Mild Infection:"
						if (INFECTION_LEVEL_ONE_PLUS to INFECTION_LEVEL_ONE_PLUS_PLUS)
							infection = "Mild Infection+:"
						if (INFECTION_LEVEL_ONE_PLUS_PLUS to INFECTION_LEVEL_TWO)
							infection = "Mild Infection++:"
						if (INFECTION_LEVEL_TWO to INFECTION_LEVEL_TWO_PLUS)
							infection = "Acute Infection:"
						if (INFECTION_LEVEL_TWO_PLUS to INFECTION_LEVEL_TWO_PLUS_PLUS)
							infection = "Acute Infection+:"
						if (INFECTION_LEVEL_TWO_PLUS_PLUS to INFECTION_LEVEL_THREE)
							infection = "Acute Infection++:"
						if (INFECTION_LEVEL_THREE to INFINITY)
							infection = "Necrotic:"

					if(!organ_status && !infection)
						infection = "None:"
					dat += "<tr>"
					dat += "<td>[IO.name]</td><td>N/A</td><td>[IO.damage]</td><td>[infection][organ_status]|[mech]</td><td></td>"
					dat += "</tr>"
					storedinfo += "<tr>"
					storedinfo += "<td>[IO.name]</td><td>N/A</td><td>[IO.damage]</td><td>[infection][organ_status]|[mech]</td><td></td>"
					storedinfo += "</tr>"
				dat += "</table>"
				storedinfo += "</table>"
				if(occupant.sdisabilities & BLIND)
					dat += text("<font color='red'>Cataracts detected.</font><BR>")
					storedinfo += text("<font color='red'>Cataracts detected.</font><BR>")
				if(HAS_TRAIT(occupant, TRAIT_NEARSIGHT))
					dat += text("<font color='red'>Retinal misalignment detected.</font><BR>")
					storedinfo += text("<font color='red'>Retinal misalignment detected.</font><BR>")
		else
			dat += "\The [src] is empty."
	else
		dat = "<font color='red'> Error: No Body Scanner connected.</font>"

	var/datum/browser/popup = new(user, "window=scanconsole", src.name, 430, 600, ntheme = CSS_THEME_LIGHT)
	popup.set_content(dat)
	popup.open()

/obj/machinery/body_scanconsole/Topic(href, href_list)
	. = ..()
	if(!.)
		return
	if(href_list["print"])
		if (next_print < world.time) //10 sec cooldown
			next_print = world.time + 10 SECONDS
			to_chat(usr, "<span class='notice'>Printing... Please wait.</span>")
			playsound(src, 'sound/items/polaroid1.ogg', VOL_EFFECTS_MASTER, 20, FALSE)
			addtimer(CALLBACK(src, .proc/print_scan, storedinfo), 1 SECOND)
		else
			to_chat(usr, "<span class='notice'>The console can't print that fast!</span>")

/obj/machinery/body_scanconsole/proc/print_scan(additional_info)
	var/obj/item/weapon/paper/P = new(loc)
	if(!connected || !connected.occupant) // If while we were printing the occupant got out or our thingy did a boom.
		return
	var/mob/living/carbon/human/occupant = connected.occupant
	var/t1 = "<B>[occupant ? occupant.name : "Unknown"]'s</B> advanced scanner report.<BR>"
	t1 += "Station Time: <B>[worldtime2text()]</B><BR>"
	switch(occupant.stat) // obvious, see what their status is
		if(CONSCIOUS)
			t1 += "Status: <B>Conscious</B>"
		if(UNCONSCIOUS)
			t1 += "Status: <B>Unconscious</B>"
		else
			t1 += "Status: <B><span class='warning'>*dead*</span></B>"
	t1 += additional_info
	P.info = t1
	P.name = "[occupant.name]'s scanner report"
	P.update_icon()
