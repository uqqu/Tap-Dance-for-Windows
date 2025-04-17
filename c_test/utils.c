#include "structures.h"
#include <stddef.h>

/**
 * Find a Triple by mod_id in a ScancodeMapping.
 */
Triple *find_triple(ScancodeMapping *map, int mod_id) {
    if (!map || !map->mapping) return NULL;
    for (size_t i = 0; i < map->count; i++) {
        Triple *tr = map->mapping[i];
        if (tr && tr->mod_id == mod_id) {
            return tr;
        }
    }
    return NULL;
}

/**
 * Find a WorkingEntry by scancode in a WorkingTable.
 */
WorkingEntry *find_entry(WorkingTable *table, int scancode) {
    if (!table || !table->entries) return NULL;
    for (size_t i = 0; i < table->count; i++) {
        WorkingEntry *we = table->entries[i];
        if (we && we->scancode == scancode) {
            return we;
        }
    }
    return NULL;
}
