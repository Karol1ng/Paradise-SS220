/obj/mecha/combat/honker
	desc = "Созданный компанией \"Tyranny of Honk, INC\", этот экзокостюм предназначен для мощной поддержки клоунов. Используется для распространения веселья и радости жизни. ХОНК!"
	name = "H.O.N.K"
	icon_state = "honker"
	initial_icon = "honker"
	step_in = 3
	max_integrity = 140
	deflect_chance = 60
	internal_damage_threshold = 60
	armor = list(MELEE = -20, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, RAD = 0, FIRE = 100, ACID = 100)
	max_temperature = 25000
	infra_luminosity = 5
	operation_req_access = list(ACCESS_CLOWN)
	wreckage = /obj/structure/mecha_wreckage/honker
	add_req_access = 0
	max_equip = 3
	starting_voice = /obj/item/mecha_modkit/voice/honk

/obj/mecha/combat/honker/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/squeak, list('sound/effects/clownstep1.ogg' = 1, 'sound/effects/clownstep2.ogg' = 1), 50, falloff_exponent = 20, squeak_on_move = TRUE) //die off quick please

/obj/mecha/combat/honker/loaded/Initialize(mapload)
	. = ..()
	var/obj/item/mecha_parts/mecha_equipment/ME = new /obj/item/mecha_parts/mecha_equipment/weapon/honker
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/banana_mortar
	ME.attach(src)
	ME = new /obj/item/mecha_parts/mecha_equipment/weapon/ballistic/missile_rack/mousetrap_mortar
	ME.attach(src)

/obj/mecha/combat/honker/get_stats_part()
	var/integrity = obj_integrity/max_integrity*100
	var/cell_charge = get_charge()
	var/tank_pressure = internal_tank ? round(internal_tank.return_pressure(),0.01) : "None"
	var/tank_temperature = internal_tank ? internal_tank.return_temperature() : "Unknown"
	var/cabin_pressure = round(cabin_air.return_pressure(),0.01)
	var/output = {"[report_internal_damage()]
						[integrity<30?"<font color='red'><b>DAMAGE LEVEL CRITICAL</b></font><br>":null]
						[internal_damage&MECHA_INT_TEMP_CONTROL?"<font color='red'><b>CLOWN SUPPORT SYSTEM MALFUNCTION</b></font><br>":null]
						[internal_damage&MECHA_INT_TANK_BREACH?"<font color='red'><b>GAS TANK HONK</b></font><br>":null]
						[internal_damage&MECHA_INT_CONTROL_LOST?"<font color='red'><b>HONK-A-DOODLE</b></font> - <a href='byond://?src=[UID()];repair_int_control_lost=1'>Recalibrate</a><br>":null]
						<b>IntegriHONK: </b> [integrity]%<br>
						<b>PowerHONK charge: </b>[isnull(cell_charge)?"No powercell installed":"[cell.percent()]%"]<br>
						<b>Air source: </b>[use_internal_tank?"Internal Airtank":"Environment"]<br>
						<b>AirHONK pressure: </b>[tank_pressure]kPa<br>
						<b>AirHONK temperature: </b>[tank_temperature]&deg;K|[tank_temperature - T0C]&deg;C<br>
						<b>HONK pressure: </b>[cabin_pressure>WARNING_HIGH_PRESSURE ? "<font color='red'>[cabin_pressure]</font>": cabin_pressure]kPa<br>
						<b>HONK temperature: </b> [cabin_air.temperature()]&deg;K|[cabin_air.temperature() - T0C]&deg;C<br>
						<b>Lights: </b>[lights?"on":"off"]<br>
						[dna?"<b>DNA-locked:</b><br> <span style='font-size:10px;letter-spacing:-1px;'>[dna]</span> \[<a href='byond://?src=[UID()];reset_dna=1'>Reset</a>\]<br>":null]
					"}
	return output

/obj/mecha/combat/honker/get_stats_html()
	var/output = {"<html><meta charset='utf-8'>
						<head><title>[name] data</title>
						<style>
						body {color: #00ff00; background: #32CD32; font-family:"Courier",monospace; font-size: 12px;}
						hr {border: 1px solid #0f0; color: #fff; background-color: #000;}
						a {padding:2px 5px;;color:#0f0;}
						.wr {margin-bottom: 5px;}
						.header {cursor:pointer;}
						.open, .closed {background: #32CD32; color:#000; padding:1px 2px;}
						.links a {margin-bottom: 2px;padding-top:3px;}
						.visible {display: block;}
						.hidden {display: none;}
						</style>
						<script language='javascript' type='text/javascript'>
						[JS_BYJAX]
						[JS_DROPDOWNS]
						function ticker() {
							setInterval(function(){
								window.location='byond://?src=[UID()]&update_content=1';
								document.body.style.color = get_rand_color_string();
								document.body.style.background = get_rand_color_string();
							}, 1000);
						}

						function get_rand_color_string() {
							var color = new Array;
							for(var i=0;i<3;i++){
								color.push(Math.floor(Math.random()*255));
							}
							return "rgb("+color.toString()+")";
						}

						window.onload = function() {
							dropdowns();
							ticker();
						}
						</script>
						</head>
						<body>
						<div id='content'>
						[get_stats_part()]
						</div>
						<div id='eq_list'>
						[get_equipment_list()]
						</div>
						<hr>
						<div id='commands'>
						[get_commands()]
						</div>
						</body>
						</html>
					"}
	return output

/obj/mecha/combat/honker/get_commands()
	var/output = {"<div class='wr'>
						<div class='header'>Sounds of HONK:</div>
						<div class='links'>
						<a href='byond://?src=[UID()];play_sound=sadtrombone'>Sad Trombone</a>
						</div>
						</div>
						"}
	output += ..()
	return output


/obj/mecha/combat/honker/get_equipment_list()
	if(!length(equipment))
		return
	var/output = "<b>Honk-ON-Systems:</b><div style=\"margin-left: 15px;\">"
	for(var/obj/item/mecha_parts/mecha_equipment/MT in equipment)
		output += "<div id='\ref[MT]'>[MT.get_equip_info()]</div>"
	output += "</div>"
	return output

/obj/mecha/combat/honker/Topic(href, href_list)
	..()
	if(href_list["play_sound"])
		if(usr != occupant)
			return
		switch(href_list["play_sound"])
			if("sadtrombone")
				playsound(src, 'sound/misc/sadtrombone.ogg', 50)
	return

/obj/mecha/combat/honker/examine_more(mob/user)
	. = ..()
	. += "<i>Веселая и яркая модификация Дюранда Х.О.Н.К. спроектирована для поддержки весёлой атмосферы. \
	Построенный и усовершенствованный одними из самых опытных клоунов, когда-либо известных в галактике, с использованием материалов и рабочей силы, предоставленных Donk Co, Х.О.Н.К. каким-то образом удалось проникнуть на борт почти каждой станции Nanotrasen, для распространения неминуемого смеха (крика) и радости (страданий) всему экипажу!</i>"
	. += ""
	. += "<i>Оборудованный массивным гудком ХоНКоВзРыВ 5000 и минометами дальнего действия, способными стрелять как скользкими банановыми кожурами, так и опасными мышеловками, Х.О.Н.К. хорошо оснащен для обеспечения клоуна всем необходимым, чтобы «развлечь» экипаж станции и вызвать гнев сотрудников службы безопасности. \
	ХОНК!</i>"
