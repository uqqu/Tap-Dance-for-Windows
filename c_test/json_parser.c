#include "json_parser.h"
#include "cJSON.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

char *read_file(const char *filename) {
    FILE *fp = fopen(filename, "rb");
    if (!fp) {
        perror("open");
        return NULL;
    }
    fseek(fp, 0, SEEK_END);
    long sz = ftell(fp);
    rewind(fp);
    char *buf = malloc(sz + 1);
    if (!buf) {
        fclose(fp);
        return NULL;
    }
    size_t r = fread(buf, 1, sz, fp);
    buf[r] = '\0';
    fclose(fp);
    return buf;
}

Triple *parse_triple(cJSON *json) {
    if (!cJSON_IsArray(json)) return NULL;
    cJSON *type = cJSON_GetArrayItem(json, 0);
    cJSON *text = cJSON_GetArrayItem(json, 1);
    cJSON *nest = cJSON_GetArrayItem(json, 2);
    Triple *tr = calloc(1, sizeof(*tr));
    tr->anchor = (type && cJSON_IsNumber(type)) ? type->valueint : 0;
    if (text && cJSON_IsString(text)) {
        tr->text = strdup(text->valuestring);
    } else if (text && cJSON_IsNumber(text)) {
        char tmp[64];
        snprintf(tmp, sizeof(tmp), "%g", text->valuedouble);
        tr->text = strdup(tmp);
    } else {
        tr->text = strdup("");
    }
    tr->nested = (nest && cJSON_IsObject(nest)) ? parse_working_table(nest) : NULL;
    return tr;
}

ScancodeMapping *parse_scancode_map(cJSON *json, int chord_mode) {
    if (!cJSON_IsObject(json)) return NULL;
    int cnt = cJSON_GetArraySize(json);
    ScancodeMapping *sm = calloc(1, sizeof(*sm));
    sm->count = cnt;
    sm->mapping = calloc(cnt, sizeof(Triple*));
    cJSON *ch = json->child;
    int i = 0;
    while (ch) {
        Triple *tr = parse_triple(ch);
        tr->mod_id = chord_mode ? (int)strtol(ch->string, NULL, 16) : atoi(ch->string);
        sm->mapping[i++] = tr;
        ch = ch->next;
    }
    return sm;
}

HexMapping *parse_hex_mapping(cJSON *json) {
    if (!cJSON_IsObject(json)) return NULL;
    int cnt = cJSON_GetArraySize(json);
    HexMapping *hm = calloc(1, sizeof(*hm));
    hm->count = cnt;
    hm->pairs = calloc(cnt, sizeof(HexPair));
    cJSON *ch = json->child;
    int i = 0;
    while (ch) {
        hm->pairs[i].key = strdup(ch->string);
        hm->pairs[i].mapping = parse_scancode_map(ch, 1);
        i++;
        ch = ch->next;
    }
    return hm;
}

WorkingTable *parse_working_table(cJSON *json) {
    if (!cJSON_IsObject(json)) return NULL;
    int cnt = 0;
    cJSON *ch = json->child;
    while (ch) {
        if (strcmp(ch->string, "-1") != 0) cnt++;
        ch = ch->next;
    }
    WorkingTable *wt = calloc(1, sizeof(*wt));
    wt->count = cnt;
    wt->entries = calloc(cnt, sizeof(WorkingEntry*));
    wt->chord_mapping = NULL;
    ch = json->child;
    int i = 0;
    while (ch) {
        if (strcmp(ch->string, "-1") == 0) {
            wt->chord_mapping = parse_hex_mapping(ch);
        } else {
            WorkingEntry *we = calloc(1, sizeof(*we));
            we->scancode = atoi(ch->string);
            we->mod_mapping = parse_scancode_map(ch, 0);
            wt->entries[i++] = we;
        }
        ch = ch->next;
    }
    return wt;
}

RootDict *load_root_dict(const char *path) {
    char *data = read_file(path);
    if (!data) return NULL;
    cJSON *j = cJSON_Parse(data);
    free(data);
    if (!j) return NULL;
    int cnt = cJSON_GetArraySize(j);
    RootDict *rd = calloc(1, sizeof(*rd));
    rd->count = cnt;
    rd->entries = calloc(cnt, sizeof(RootEntry));
    cJSON *ch = j->child;
    int i = 0;
    while (ch) {
        rd->entries[i].key = atoi(ch->string);
        rd->entries[i].table = parse_working_table(ch);
        i++;
        ch = ch->next;
    }
    cJSON_Delete(j);
    return rd;
}