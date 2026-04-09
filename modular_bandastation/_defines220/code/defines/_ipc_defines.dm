
#define COMSIG_IPC_BATTERY_UPDATED "ipc_battery_updated"

/// Доля брут-урона от max_damage, при которой корпус считается вскрытым
#define IPC_CHASSIS_BREACH_THRESHOLD 0.25
/// Источник трейта защиты от давления — интактный корпус КПБ
#define TRAIT_SOURCE_IPC_CHASSIS "ipc_chassis_intact"

#define HUD_MOB_IPC_BATTERY "mob_ipc_battery"

// ============================================
// ТИПЫ ЯДРА IPC
// ============================================

#define IPC_BRAIN_POSITRONIC "positronic"
#define IPC_BRAIN_MMI "mmi"
#define IPC_BRAIN_BORG "borg_module"

// ============================================
// ТЕМПЕРАТУРНЫЕ КОНСТАНТЫ
// ============================================

#define IPC_TEMP_CRITICAL_LOW 20
#define IPC_TEMP_OPTIMAL_LOW 20
#define IPC_TEMP_OPTIMAL_HIGH 40
#define IPC_TEMP_NEUTRAL_HIGH 80
#define IPC_TEMP_OVERHEAT_LOW 80
#define IPC_TEMP_OVERHEAT_MID 90
#define IPC_TEMP_OVERHEAT_HIGH 120
#define IPC_TEMP_CRITICAL_HIGH 130

// Состояния температуры
#define IPC_TEMP_STATE_COLD "cold"
#define IPC_TEMP_STATE_OPTIMAL "optimal"
#define IPC_TEMP_STATE_NEUTRAL "neutral"
#define IPC_TEMP_STATE_WARM "warm"
#define IPC_TEMP_STATE_HOT "hot"
#define IPC_TEMP_STATE_CRITICAL "critical"
#define IPC_TEMP_STATE_BURNING "burning"

#define BODYTYPE_IPC (1<<9)

// ============================================
// КАТЕГОРИИ ФАБРИКАТОРА ДЛЯ КПБ
// ============================================

#define RND_CATEGORY_IPC "/КПБ"
#define RND_SUBCATEGORY_IPC_BODYPARTS "/Части тела"
#define RND_SUBCATEGORY_IPC_ORGANS "/Органы"
#define RND_SUBCATEGORY_IPC_IMPLANTS "/Импланты"
#define RND_SUBCATEGORY_IPC_EQUIPMENT "/Оборудование"
