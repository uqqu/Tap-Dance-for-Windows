#ifndef JSON_PARSER_H
#define JSON_PARSER_H

#include "structures.h"
#include "cJSON.h"

char       *read_file(const char *path);
Triple     *parse_triple(cJSON *json);
ScancodeMapping *parse_scancode_map(cJSON *json, int chord_mode);
HexMapping *parse_hex_mapping(cJSON *json);
WorkingTable    *parse_working_table(cJSON *json);
RootDict        *load_root_dict(const char *path);

#endif /* JSON_PARSER_H */