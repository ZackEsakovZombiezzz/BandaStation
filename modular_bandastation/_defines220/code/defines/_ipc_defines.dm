#define COMSIG_IPC_BATTERY_UPDATED "ipc_battery_updated"

/// HUD slot key for the IPC battery indicator
#define HUD_MOB_IPC_BATTERY "mob_ipc_battery"

/// Returns TRUE if H is a living IPC
#define IS_IPC(H) (istype(H.dna?.species, /datum/species/ipc))

/// Trait applied when IPC chassis is breached (used by pressure damage override)
#define TRAIT_IPC_CHASSIS_BREACHED "ipc_chassis_breached"

/// Доля брут-урона от max_damage, при которой корпус считается вскрытым
#define IPC_CHASSIS_BREACH_THRESHOLD 0.5
/// Источник трейта защиты от давления — интактный корпус КПБ
#define TRAIT_SOURCE_IPC_CHASSIS "ipc_chassis_intact"
