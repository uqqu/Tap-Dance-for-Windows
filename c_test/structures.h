#ifndef STRUCTURES_H
#define STRUCTURES_H

#include <stddef.h>

struct WorkingTable;  /* forward */

typedef struct Triple {
    int    anchor;
    int    mod_id;
    char  *text;
    struct WorkingTable *nested;
} Triple;

typedef struct ScancodeMapping {
    Triple **mapping;
    size_t  count;
} ScancodeMapping;

typedef struct HexPair {
    char            *key;
    ScancodeMapping *mapping;
} HexPair;

typedef struct HexMapping {
    HexPair *pairs;
    size_t   count;
} HexMapping;

typedef struct WorkingEntry {
    int             scancode;
    ScancodeMapping *mod_mapping;
} WorkingEntry;

typedef struct WorkingTable {
    WorkingEntry **entries;
    size_t         count;
    HexMapping    *chord_mapping;
} WorkingTable;

typedef struct RootEntry {
    int           key;
    WorkingTable *table;
} RootEntry;

typedef struct RootDict {
    RootEntry *entries;
    size_t     count;
} RootDict;

typedef struct Waiting {
    Triple *t0;
    Triple *t1;
} Waiting;

Triple *find_triple(ScancodeMapping *map, int mod_id);
WorkingEntry *find_entry(WorkingTable *table, int scancode);

#endif /* STRUCTURES_H */