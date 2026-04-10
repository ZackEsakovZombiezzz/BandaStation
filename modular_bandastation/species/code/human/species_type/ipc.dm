// ============================================
// ХЕЛПЕР
// ============================================
/mob/living/carbon/human/proc/is_ipc()
	return istype(dna?.species, /datum/species/ipc)

/datum/species/ipc
	name = "IPC"
	id = SPECIES_IPC
	sexes = TRUE

	meat = null
	inherent_biotypes = MOB_ROBOTIC
	exotic_bloodtype = BLOOD_TYPE_OIL
	species_language_holder = /datum/language_holder/synthetic
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_MAGIC | MIRROR_PRIDE | ERT_SPAWN

	mutantstomach = null
	mutantliver = null
	mutantlungs = /obj/item/organ/lungs/ipc
	mutantbrain = /obj/item/organ/brain/positronic
	mutantheart = /obj/item/organ/heart/ipc_battery
	mutanteyes = /obj/item/organ/eyes/robotic/ipc
	mutanttongue = /obj/item/organ/tongue/robot/ipc
	mutantears = /obj/item/organ/ears/robot/ipc

	bodypart_overrides = list(
		BODY_ZONE_HEAD = /obj/item/bodypart/head/ipc,
		BODY_ZONE_CHEST = /obj/item/bodypart/chest/ipc,
		BODY_ZONE_L_ARM = /obj/item/bodypart/arm/left/ipc,
		BODY_ZONE_R_ARM = /obj/item/bodypart/arm/right/ipc,
		BODY_ZONE_L_LEG = /obj/item/bodypart/leg/left/ipc,
		BODY_ZONE_R_LEG = /obj/item/bodypart/leg/right/ipc,
	)

	inherent_traits = list(
		TRAIT_RESISTCOLD,
		TRAIT_NOBREATH,
		TRAIT_RADIMMUNE,
		TRAIT_LIVERLESS_METABOLISM,
		TRAIT_GENELESS,
		TRAIT_NOCRITDAMAGE,
		TRAIT_VIRUSIMMUNE,
		TRAIT_PIERCEIMMUNE,
		TRAIT_TOXIMMUNE,
		TRAIT_LIMBATTACHMENT,
		TRAIT_EASYDISMEMBER,
		TRAIT_NOHUNGER,
		TRAIT_NOBLOOD,
	)

	// ЭМП уязвимость
	var/emp_vulnerability = 2

	// Переменные для температурной системы
	var/cpu_temperature = 30
	var/cpu_temp_optimal_min = 20
	var/cpu_temp_optimal_max = 40
	var/cpu_temp_critical = 130
	var/cpu_cooling_rate = 0.1

	// Модификатор скорости взаимодействия от температуры
	var/temp_interaction_speed_mod = 1.0

	// Таймеры для урона от перегрева
	var/last_overheat_damage_time = 0
	var/last_critical_damage_time = 0
	var/last_extreme_damage_time = 0

	// Системы охлаждения
	var/thermal_paste_active = FALSE
	var/thermal_paste_end_time = 0
	var/improved_cooling_installed = FALSE
	var/cooling_block_active = FALSE
	var/cooling_block_end_time = 0

	// Разгон системы
	var/overclock_active = FALSE
	var/overclock_speed_bonus = 0.4

	// Лечение
	var/self_repair_enabled = TRUE
	var/self_repair_amount = 0.5
	var/self_repair_delay = 100
	var/last_repair_time = 0

	// Ключ выбранного бренда из фичи (morpheus, etamin, bishop, ...)
	var/ipc_brand_key = "unbranded"
	// Ключ визуального бренда (используется только для HEF, иначе = ipc_brand_key)
	var/ipc_visual_brand_key = "unbranded"

	// HEF: поштучный выбор бренда для каждой части тела.
	var/hef_head = "unbranded"
	var/hef_chest = "unbranded"
	var/hef_l_arm = "unbranded"
	var/hef_r_arm = "unbranded"
	var/hef_l_leg = "unbranded"
	var/hef_r_leg = "unbranded"

	// Модификаторы шасси
	var/ipc_thermal_relaxation_mod = 0
	var/ipc_overheat_rate_mod = 1.0
	var/ipc_repair_cost_mod = 1.0
	var/ipc_extra_implant_slots = 0
	var/list/ipc_chassis_modifiers = list()

	// Косметика
	var/ipc_face_state = ""
	var/ipc_charger_arm_zone = BODY_ZONE_L_ARM
	var/ipc_head_type = "monitor"

	// Поколение КПБ (только косметическое)
	var/ipc_generation = IPC_GEN_STANDARD
	var/ipc_gen1_module = IPC_MODULE_SECURITY

/datum/species/ipc/get_species_description()
	return "IPC (Integrated Positronic Construct) — синтетические гуманоидные формы жизни, управляемые позитронным вычислительным блоком (КПБ). \
	В отличие от обычных роботов, КПБ способны обеспечивать различный уровень автономии и самосознания, \
	благодаря чему IPC занимают промежуточное положение между машиной и личностью."

/datum/species/ipc/get_species_lore()
	return list(
		"Хотя крупнейшие корпорации остаются основными производителями позитронных процессоров и шасси, технология создания КПБ со временем \
		распространилась далеко за пределы корпоративных лабораторий. Сегодня такие системы могут быть собраны не только промышленными предприятиями, \
		но и независимыми инженерами, на частных верфях и даже в небольших мастерских. IPC широко используются в космической индустрии — \
		от технического персонала станций до экипажей кораблей и автономных экспедиционных групп.",
	)

/datum/species/ipc/on_species_gain(mob/living/carbon/human/H, datum/species/old_species, pref_load)
	. = ..()
	replace_body(H, src)
	H.update_body()
	H.update_body_parts()

	// Защита от давления
	ADD_TRAIT(H, TRAIT_RESISTHIGHPRESSURE, TRAIT_SOURCE_IPC_CHASSIS)
	ADD_TRAIT(H, TRAIT_RESISTLOWPRESSURE, TRAIT_SOURCE_IPC_CHASSIS)

	// Зарядка на станции боргов
	RegisterSignal(H, COMSIG_PROCESS_BORGCHARGER_OCCUPANT, PROC_REF(on_borg_charge))
	// Обновление HUD при изменении заряда батареи
	RegisterSignal(H, COMSIG_IPC_BATTERY_UPDATED, PROC_REF(on_battery_updated), override = TRUE)
	// Отслеживание повреждений корпуса для снятия/восстановления защиты от давления
	RegisterSignal(H, COMSIG_CARBON_LIMB_DAMAGED, PROC_REF(on_limb_damaged), override = TRUE)

	// Даем IPC абилки
	var/datum/action/cooldown/ipc_overclock/overclock = new()
	overclock.Grant(H)

	// Выдаём встроенный зарядный порт в левую руку по умолчанию
	var/obj/item/implant/ipc/charger/charger_impl = new()
	charger_impl.implant(H, BODY_ZONE_L_ARM, null, TRUE, TRUE)

	// Регистрируем обработчики
	RegisterSignal(H, COMSIG_HUMAN_PREFS_APPLIED, PROC_REF(on_prefs_applied))
	RegisterSignal(H, COMSIG_LIVING_ELECTROCUTE_ACT, PROC_REF(on_electrocute))

	// Абилка смены экрана — только для брендов, поддерживающих экраны
	if(ipc_brand_key != "zeng_hu" && ipc_brand_key != "cybersun")
		var/datum/action/innate/ipc_change_face/face_action = new()
		face_action.Grant(H)

	// Нейтральный муд
	if(H.mob_mood)
		QDEL_NULL(H.mob_mood)
	H.mob_mood = new /datum/mood/ipc_neutral(H)

	// HUD: регистрируем сигнал и добавляем элементы если HUD уже есть
	RegisterSignal(H, COMSIG_MOB_HUD_CREATED, PROC_REF(on_hud_created))
	if(H.hud_used)
		on_hud_created(H)

/datum/species/ipc/on_species_loss(mob/living/carbon/human/H, datum/species/new_species, pref_load)
	. = ..()

	// Удаляем IPC абилки
	var/datum/action/cooldown/ipc_overclock/overclock = locate(/datum/action/cooldown/ipc_overclock) in H.actions
	if(overclock)
		overclock.Remove(H)

	var/datum/action/cooldown/ipc_hack/hack = locate(/datum/action/cooldown/ipc_hack) in H.actions
	if(hack)
		hack.Remove(H)

	var/datum/action/innate/ipc_change_face/face_action = locate() in H.actions
	if(face_action)
		face_action.Remove(H)

	// Снимаем сигналы
	UnregisterSignal(H, list(
		COMSIG_PROCESS_BORGCHARGER_OCCUPANT,
		COMSIG_MOB_HUD_CREATED,
		COMSIG_IPC_BATTERY_UPDATED,
		COMSIG_CARBON_LIMB_DAMAGED,
		COMSIG_LIVING_ELECTROCUTE_ACT,
		COMSIG_HUMAN_PREFS_APPLIED,
		COMSIG_MOB_SAY,
	))

	// Удаляем трейты от брендов
	REMOVE_TRAIT(H, TRAIT_RESISTHIGHPRESSURE, TRAIT_SOURCE_IPC_CHASSIS)
	REMOVE_TRAIT(H, TRAIT_RESISTLOWPRESSURE, TRAIT_SOURCE_IPC_CHASSIS)
	REMOVE_TRAIT(H, TRAIT_SILENT_FOOTSTEPS, "cybersun_brand")

	// HUD: удаляем элементы и восстанавливаем муд
	remove_ipc_hud_elements(H, new_species)
	if(istype(H.mob_mood, /datum/mood/ipc_neutral))
		QDEL_NULL(H.mob_mood)
		H.setup_mood()

/// Зарядка IPC на станции боргов — аналог зарядки борга.
/datum/species/ipc/proc/on_borg_charge(mob/living/carbon/human/H, datum/callback/charge_cell, seconds_per_tick)
	SIGNAL_HANDLER
	var/obj/item/organ/heart/ipc_battery/bat = H.get_organ_slot(ORGAN_SLOT_HEART)
	if(!bat || !bat.proxy_cell)
		return
	charge_cell.Invoke(bat.proxy_cell, seconds_per_tick)

/datum/species/ipc/proc/handle_emp(mob/living/carbon/human/H, severity)
	var/emp_damage = 0
	switch(severity)
		if(EMP_HEAVY)
			emp_damage = rand(20, 40) * emp_vulnerability
			to_chat(H, span_userdanger("КРИТИЧЕСКАЯ ОШИБКА: Электромагнитный импульс обнаружен! Системы повреждены!"))
			H.Paralyze(6 SECONDS)
		if(EMP_LIGHT)
			emp_damage = rand(10, 20) * emp_vulnerability
			to_chat(H, span_danger("ПРЕДУПРЕЖДЕНИЕ: Обнаружен электромагнитный импульс!"))
			H.Paralyze(3 SECONDS)

	H.apply_damage(emp_damage * 0.5, BRUTE, forced = TRUE)
	H.apply_damage(emp_damage * 0.5, BURN, forced = TRUE)
	cpu_temperature = min(cpu_temperature + (emp_damage * 0.5), cpu_temp_critical)

/obj/item/organ/brain/positronic/emp_act(severity)
	. = ..()
	if(owner && istype(owner.dna.species, /datum/species/ipc))
		var/datum/species/ipc/S = owner.dna.species
		S.handle_emp(owner, severity)

// Разрешаем цифры в именах для IPC (типа ARC-908), не затрагивая остальные расы
/datum/preference/name/real_name/deserialize(input, datum/preferences/preferences)
	if(preferences?.read_preference(/datum/preference/choiced/species) == /datum/species/ipc)
		return reject_bad_name(input, TRUE)
	return ..()

/datum/preference/name/real_name/create_informed_default_value(datum/preferences/preferences)
	if(preferences.read_preference(/datum/preference/choiced/species) == /datum/species/ipc)
		return pick(GLOB.ipc_names)
	return ..()

// СОВМЕСТИМОСТЬ С АНТАГОНИСТАМИ

/datum/dynamic_ruleset/roundstart/changeling/is_valid_candidate(mob/living/candidate, client/candidate_client)
	if(!..())
		return FALSE
	var/species_type = candidate_client.prefs.read_preference(/datum/preference/choiced/species)
	var/datum/species/species = GLOB.species_prototypes[species_type]
	if(species?.inherent_biotypes & MOB_ROBOTIC)
		return FALSE
	return TRUE

/datum/component/cult_ritual_item/can_scribe_rune(obj/item/tool, mob/living/cultist)
	if(ishuman(cultist))
		var/mob/living/carbon/human/H = cultist
		if(istype(H.dna?.species, /datum/species/ipc))
			to_chat(cultist, span_warning("Масло КПБ не является жертвенной субстанцией — руна не может быть начертана."))
			return FALSE
	return ..()

/datum/component/cult_ritual_item/do_scribe_rune(obj/item/tool, mob/living/cultist)
	if(HAS_TRAIT(cultist, TRAIT_NOBLOOD))
		to_chat(cultist, span_warning("Масло КПБ не является жертвенной субстанцией — руна не может быть начертана."))
		return FALSE
	return ..()

// УПРАВЛЕНИЕ БАТАРЕЕЙ IPC

/// Вызывается по COMSIG_IPC_BATTERY_UPDATED — орган сообщает об изменении заряда.
/// Вид обновляет HUD и проверяет целостность корпуса (для отслеживания восстановления).
/datum/species/ipc/proc/on_battery_updated(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	update_ipc_battery_icon(H)
	check_chassis_integrity(H)

/// Вызывается по COMSIG_CARBON_LIMB_DAMAGED — любая часть тела получила урон.
/// Проверяет, не был ли вскрыт корпус, и немедленно снимает защиту от давления.
/datum/species/ipc/proc/on_limb_damaged(mob/living/carbon/human/H, obj/item/bodypart/limb, brute, burn)
	SIGNAL_HANDLER
	if(limb.limb_id != SPECIES_IPC)
		return
	check_chassis_integrity(H)

/// Проверяет целостность всех частей тела КПБ.
/// Если любая превышает порог брут-повреждений — снимает защиту от давления.
/// Если все ниже порога — восстанавливает защиту.
/datum/species/ipc/proc/check_chassis_integrity(mob/living/carbon/human/H)
	var/any_breached = FALSE
	for(var/obj/item/bodypart/BP in H.bodyparts)
		if(BP.limb_id != SPECIES_IPC)
			continue
		if(BP.brute_dam >= BP.max_damage * IPC_CHASSIS_BREACH_THRESHOLD)
			any_breached = TRUE
			break

	var/currently_intact = HAS_TRAIT_FROM(H, TRAIT_RESISTLOWPRESSURE, TRAIT_SOURCE_IPC_CHASSIS)
	if(any_breached && currently_intact)
		REMOVE_TRAIT(H, TRAIT_RESISTHIGHPRESSURE, TRAIT_SOURCE_IPC_CHASSIS)
		REMOVE_TRAIT(H, TRAIT_RESISTLOWPRESSURE, TRAIT_SOURCE_IPC_CHASSIS)
		to_chat(H, span_warning("СИСТЕМНОЕ ПРЕДУПРЕЖДЕНИЕ: Целостность корпуса нарушена. Внешняя среда может повредить внутренние компоненты."))
	else if(!any_breached && !currently_intact)
		ADD_TRAIT(H, TRAIT_RESISTHIGHPRESSURE, TRAIT_SOURCE_IPC_CHASSIS)
		ADD_TRAIT(H, TRAIT_RESISTLOWPRESSURE, TRAIT_SOURCE_IPC_CHASSIS)
		to_chat(H, span_notice("Системная диагностика: Целостность корпуса восстановлена. Защита от давления активна."))

//Квирки
/datum/quirk/is_species_appropriate(datum/species/mob_species)
	if(mob_species == /datum/species/ipc)
		return FALSE
	return ..()

// ============================================
// ЖИЗНЕННЫЙ ЦИКЛ — spec_life
// ============================================

/datum/species/ipc/spec_life(mob/living/carbon/human/H, seconds_per_tick, times_fired)
	. = ..()
	handle_self_repair(H)
	handle_temperature(H, seconds_per_tick)
	handle_temperature_effects(H)
	handle_battery(H)
	update_action_speed(H)
	update_ipc_temperature_icon(H)

// ============================================
// САМОРЕМОНТ
// ============================================

/datum/species/ipc/proc/handle_self_repair(mob/living/carbon/human/H)
	if(!self_repair_enabled)
		return

	if(world.time < last_repair_time + self_repair_delay)
		return

	if(H.get_brute_loss() > 0)
		H.heal_overall_damage(brute = self_repair_amount, forced = TRUE)
		last_repair_time = world.time

	if(H.get_fire_loss() > 0)
		H.heal_overall_damage(burn = self_repair_amount * 0.5, forced = TRUE)
		last_repair_time = world.time

// ============================================
// ТЕМПЕРАТУРНАЯ СИСТЕМА
// ============================================

/datum/species/ipc/proc/handle_temperature(mob/living/carbon/human/H, seconds_per_tick)
	if(thermal_paste_active && world.time > thermal_paste_end_time)
		thermal_paste_active = FALSE
		to_chat(H, span_warning("Эффект термопасты закончился."))

	if(cooling_block_active && world.time > cooling_block_end_time)
		cooling_block_active = FALSE
		to_chat(H, span_warning("Охладительный блок перестал действовать."))

	var/turf/T = get_turf(H)
	if(T)
		var/datum/gas_mixture/environment = T.return_air()
		if(environment)
			var/env_temp = environment.temperature - T0C
			if(env_temp < cpu_temperature)
				var/cooling_amount = min((cpu_temperature - env_temp) * 0.01, cpu_cooling_rate * 2)
				cpu_temperature = max(cpu_temperature - cooling_amount, env_temp)
			else if(env_temp > cpu_temperature)
				var/heating_amount = min((env_temp - cpu_temperature) * 0.005, cpu_cooling_rate)
				cpu_temperature = min(cpu_temperature + heating_amount, env_temp)

	if(cooling_block_active)
		cpu_temperature = max(cpu_temperature - 1 * seconds_per_tick, 0)

	var/passive_cooling_rate = 0
	if(thermal_paste_active)
		passive_cooling_rate += 1
	if(improved_cooling_installed)
		passive_cooling_rate += 1

	if(passive_cooling_rate > 0)
		var/cooling_mult = 1 + ipc_thermal_relaxation_mod
		cpu_temperature = max(cpu_temperature - (passive_cooling_rate * cooling_mult * seconds_per_tick), 0)

	if(H.internal && istype(H.internal, /obj/item/tank))
		var/obj/item/tank/gas_tank = H.internal
		var/datum/gas_mixture/gas = gas_tank.return_air()
		if(gas && gas.total_moles() > 0.05)
			var/gas_temp = gas.temperature - T0C
			var/total_heat_capacity = 0
			var/total_moles = gas.total_moles()
			for(var/gas_id in gas.gases)
				var/list/cached_gas = gas.gases[gas_id]
				var/gas_moles = cached_gas[MOLES]
				if(gas_moles > 0)
					var/datum/gas/gas_datum = gas_id2path(gas_id)
					var/list/gas_info = GLOB.meta_gas_info[gas_datum]
					if(gas_info)
						total_heat_capacity += gas_info[META_GAS_SPECIFIC_HEAT] * (gas_moles / total_moles)
			var/heat_capacity_multiplier = total_heat_capacity / 20
			var/cooling_from_gas = 0
			if(gas_temp < cpu_temperature)
				var/temp_diff = cpu_temperature - gas_temp
				cooling_from_gas = min(temp_diff * 0.01 * heat_capacity_multiplier, heat_capacity_multiplier * 2)
			if(cooling_from_gas > 0)
				cpu_temperature = max(cpu_temperature - (cooling_from_gas * seconds_per_tick), 0)
				var/gas_consumption = 0.01 * (cooling_from_gas / 2)
				if(gas.total_moles() > gas_consumption)
					gas.remove(gas_consumption * seconds_per_tick)

	if(overclock_active)
		cpu_temperature += 2 * seconds_per_tick

	if(H.client)
		var/activity_heating = 0.05
		if(H.move_intent == MOVE_INTENT_RUN)
			activity_heating += 0.02
		if(H.health < H.maxHealth * 0.5)
			activity_heating += 0.03
		cpu_temperature += activity_heating * seconds_per_tick

	cpu_temperature = clamp(cpu_temperature, 0, 200)

/datum/species/ipc/proc/handle_temperature_effects(mob/living/carbon/human/H)
	switch(cpu_temperature)
		if(-INFINITY to 20)
			temp_interaction_speed_mod = 1.1
		if(20 to 40)
			temp_interaction_speed_mod = 0.9
		if(40 to 80)
			temp_interaction_speed_mod = 1.0
		if(80 to 90)
			temp_interaction_speed_mod = 1.1
		if(90 to 120)
			temp_interaction_speed_mod = 1.1
			if(world.time > last_overheat_damage_time + 30 SECONDS)
				var/obj/item/organ/brain/positronic/brain = H.get_organ_slot(ORGAN_SLOT_BRAIN)
				if(brain)
					brain.apply_organ_damage(1)
					to_chat(H, span_danger("ПРЕДУПРЕЖДЕНИЕ: Перегрев процессора! Температура: [round(cpu_temperature)]°C"))
				last_overheat_damage_time = world.time
		if(120 to 130)
			temp_interaction_speed_mod = 1.1
			if(world.time > last_critical_damage_time + 15 SECONDS)
				var/obj/item/organ/brain/positronic/brain = H.get_organ_slot(ORGAN_SLOT_BRAIN)
				if(brain)
					brain.apply_organ_damage(2)
					to_chat(H, span_userdanger("КРИТИЧЕСКОЕ ПРЕДУПРЕЖДЕНИЕ: Процессор горит! Температура: [round(cpu_temperature)]°C"))
				last_critical_damage_time = world.time
				if(prob(10))
					H.adjust_stamina_loss(H.max_stamina * 0.2)
					to_chat(H, span_danger("Системы управления перегружены! Потеряна стамина."))
		if(130 to INFINITY)
			temp_interaction_speed_mod = 1.1
			if(world.time > last_extreme_damage_time + 10 SECONDS)
				var/obj/item/organ/brain/positronic/brain = H.get_organ_slot(ORGAN_SLOT_BRAIN)
				if(brain)
					brain.apply_organ_damage(3)
					to_chat(H, span_boldwarning("!!! АВАРИЙНОЕ ОТКЛЮЧЕНИЕ !!! Процессор расплавляется! Температура: [round(cpu_temperature)]°C !!!"))
				last_extreme_damage_time = world.time
				if(prob(50))
					H.adjust_stamina_loss(H.max_stamina * 0.5)
					to_chat(H, span_userdanger("КРИТИЧЕСКИЙ ОТКАЗ СИСТЕМЫ! Стамина критически низкая!"))

/datum/species/ipc/proc/update_action_speed(mob/living/carbon/human/H)
	var/total_modifier = temp_interaction_speed_mod
	if(overclock_active)
		total_modifier *= (1 - overclock_speed_bonus)
	H.add_or_update_variable_actionspeed_modifier(/datum/actionspeed_modifier/ipc_temperature, multiplicative_slowdown = (total_modifier - 1))

/datum/species/ipc/proc/handle_battery(mob/living/carbon/human/H)
	var/obj/item/organ/heart/heart = H.get_organ_slot(ORGAN_SLOT_HEART)
	if(!heart || !heart.ipc_max_charge)
		to_chat(H, span_userdanger("КРИТИЧЕСКАЯ ОШИБКА: Источник питания не обнаружен!"))
		H.apply_damage(2, OXY, forced = TRUE)
		return

	if(heart.get_ipc_charge() <= 0)
		to_chat(H, span_danger("ПРЕДУПРЕЖДЕНИЕ: Источник питания разряжен. Требуется подзарядка."))
		H.Unconscious(2 SECONDS)

// ============================================
// СИГНАЛЫ
// ============================================

/datum/species/ipc/proc/on_electrocute(mob/living/carbon/human/source, shock_damage, siemens_coeff, flags)
	SIGNAL_HANDLER
	cpu_temperature = min(cpu_temperature + 10, 200)
	to_chat(source, span_warning("Удар током повысил температуру процессора на 10°C!"))

/// Вызывается после загрузки всех настроек персонажа.
/datum/species/ipc/proc/on_prefs_applied(mob/living/carbon/human/H)
	SIGNAL_HANDLER
	if(ipc_brand_key == "shellguard")
		if(!(locate(/obj/item/implant/ipc/force_shield) in H.implants))
			var/charger_zone = ipc_charger_arm_zone
			var/obj/item/implant/ipc/charger/charger_impl = locate(/obj/item/implant/ipc/charger) in H.implants
			if(charger_impl)
				charger_zone = charger_impl.installed_in_zone
			var/shield_zone = (charger_zone == BODY_ZONE_L_ARM) ? BODY_ZONE_R_ARM : BODY_ZONE_L_ARM
			var/obj/item/implant/ipc/force_shield/shield_impl = new()
			shield_impl.implant(H, shield_zone, null, TRUE, TRUE)

// ============================================
// РЕМОНТ
// ============================================

/datum/species/ipc/proc/try_repair_brute(mob/living/carbon/human/H, obj/item/tool, mob/user)
	if(!istype(tool, /obj/item/weldingtool))
		return FALSE
	var/obj/item/weldingtool/welder = tool
	if(!welder.isOn())
		to_chat(user, span_warning("[welder] не включен!"))
		return FALSE
	if(H.get_brute_loss() <= 0)
		to_chat(user, span_notice("[H] не имеет механических повреждений."))
		return FALSE
	if(!welder.use_tool(H, user, 0, volume = 50, amount = 1))
		return FALSE
	user.visible_message(
		span_notice("[user] начинает заваривать повреждения [H] с помощью [welder]."),
		span_notice("Вы начинаете заваривать повреждения [H].")
	)
	if(!do_after(user, 3 SECONDS, target = H))
		return FALSE
	if(!welder.use_tool(H, user, 0, volume = 50, amount = ipc_repair_cost_mod))
		return FALSE
	var/heal_amount = rand(15, 25)
	H.heal_overall_damage(brute = heal_amount, forced = TRUE)
	user.visible_message(
		span_notice("[user] заваривает повреждения [H]."),
		span_notice("Вы заварили повреждения [H]. Восстановлено [heal_amount] HP.")
	)
	to_chat(H, span_notice("Системная диагностика: Механические повреждения частично восстановлены."))
	return TRUE

/datum/species/ipc/proc/try_repair_burn(mob/living/carbon/human/H, obj/item/tool, mob/user)
	if(!istype(tool, /obj/item/stack/cable_coil))
		return FALSE
	var/obj/item/stack/cable_coil/cable = tool
	if(H.get_fire_loss() <= 0)
		to_chat(user, span_notice("[H] не имеет электрических повреждений."))
		return FALSE
	var/cable_cost = max(1, round(ipc_repair_cost_mod))
	if(cable.get_amount() < cable_cost)
		to_chat(user, span_warning("Недостаточно кабеля! Нужно [cable_cost] ед."))
		return FALSE
	user.visible_message(
		span_notice("[user] начинает чинить проводку [H] с помощью [cable]."),
		span_notice("Вы начинаете чинить проводку [H].")
	)
	if(!do_after(user, 3 SECONDS, target = H))
		return FALSE
	if(!cable.use(cable_cost))
		return FALSE
	var/heal_amount = rand(10, 20)
	H.heal_overall_damage(burn = heal_amount, forced = TRUE)
	user.visible_message(
		span_notice("[user] чинит проводку [H]."),
		span_notice("Вы починили проводку [H]. Восстановлено [heal_amount] HP.")
	)
	to_chat(H, span_notice("Системная диагностика: Электрические системы частично восстановлены."))
	return TRUE

/datum/species/ipc/proc/toggle_self_repair(mob/living/carbon/human/H)
	self_repair_enabled = !self_repair_enabled
	to_chat(H, span_notice("Саморемонт [self_repair_enabled ? "включен" : "выключен"]."))

/mob/living/carbon/human/verb/toggle_ipc_self_repair()
	set name = "Toggle Self-Repair"
	set category = "IC"
	set desc = "Включить или выключить систему саморемонта."
	if(!istype(dna.species, /datum/species/ipc))
		to_chat(src, span_warning("Эта функция доступна только для IPC!"))
		return
	var/datum/species/ipc/S = dna.species
	S.toggle_self_repair(src)

/mob/living/carbon/human/verb/ipc_weld_repair()
	set name = "Repair with Welder"
	set category = "IC"
	set desc = "Починить себя сваркой."
	if(!istype(dna.species, /datum/species/ipc))
		return
	var/obj/item/held = get_active_held_item()
	if(!istype(held, /obj/item/weldingtool))
		to_chat(src, span_warning("Вам нужна сварка!"))
		return
	var/datum/species/ipc/S = dna.species
	S.try_repair_brute(src, held, src)

/mob/living/carbon/human/verb/ipc_cable_repair()
	set name = "Repair with Cable"
	set category = "IC"
	set desc = "Починить себя кабелем."
	if(!istype(dna.species, /datum/species/ipc))
		return
	var/obj/item/held = get_active_held_item()
	if(!istype(held, /obj/item/stack/cable_coil))
		to_chat(src, span_warning("Вам нужен кабель!"))
		return
	var/datum/species/ipc/S = dna.species
	S.try_repair_burn(src, held, src)

// ============================================
// FEATURE VALUES (для preferences сохранения)
// ============================================

/datum/species/ipc/proc/ipc_get_feature_values()
	var/list/features = list()
	features["ipc_chassis_brand"] = ipc_brand_key
	if(ipc_brand_key == "hef")
		features["ipc_hef_visual"] = ipc_visual_brand_key
	return features

/datum/species/ipc/proc/ipc_set_feature_values(list/features)
	if(features["ipc_chassis_brand"])
		ipc_brand_key = features["ipc_chassis_brand"]
	if(ipc_brand_key == "hef" && features["ipc_hef_visual"])
		ipc_visual_brand_key = features["ipc_hef_visual"]
	else
		ipc_visual_brand_key = ipc_brand_key

// ============================================
// ITEM INTERACTION — ВНЕШНИЙ РЕМОНТ
// ============================================

/mob/living/carbon/human/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(dna?.species, /datum/species/ipc))
		var/datum/species/ipc/S = dna.species
		var/obj/item/bodypart/target_part = get_bodypart(check_zone(user.zone_selected))
		if(target_part)
			var/datum/component/ipc_panel/panel = target_part.GetComponent(/datum/component/ipc_panel)
			if(panel && panel.is_panel_open())
				var/surgery_ret = user.perform_surgery(src, tool, LAZYACCESS(modifiers, RIGHT_CLICK))
				if(surgery_ret)
					return surgery_ret
		if(istype(tool, /obj/item/weldingtool))
			if(S.try_repair_brute(src, tool, user))
				return ITEM_INTERACT_SUCCESS
		else if(istype(tool, /obj/item/stack/cable_coil))
			if(S.try_repair_burn(src, tool, user))
				return ITEM_INTERACT_SUCCESS
	return ..()
