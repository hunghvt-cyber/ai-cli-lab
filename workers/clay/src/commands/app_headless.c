#include "clay/app_io.h"

#include <stdio.h>

static void headless_say(const char *text) {
    printf("%s\n", text);
}

static void headless_list_header(const char *text) {
    printf("%s\n", text);
}

static void headless_list_step(int index, const char *verb, const char *target,
                               const char *info, int link) {
    (void)link;
    if (info && *info)
        printf("%d. %s %s (%s)\n", index, verb, target, info);
    else
        printf("%d. %s %s\n", index, verb, target);
}

static ClayTask *headless_task_start(const char *label) {
    printf("$ %s\n", label);
    return NULL;
}

static void headless_task_success(ClayTask *task, const char *result) {
    (void)task;
    printf("ok: %s\n", result);
}

static void headless_task_fail(ClayTask *task, const char *result) {
    (void)task;
    printf("error: %s\n", result);
}

static int headless_select(const char *question, const ClayChoice *options, int count,
                           int default_index) {
    (void)question;
    (void)options;
    (void)count;
    return default_index;
}

static int headless_confirm(const char *question, int default_yes) {
    (void)question;
    return default_yes;
}

static int headless_choice(const char *question, const ClayChoice *choices, int count,
                           int allow_custom, char **custom_out) {
    (void)question;
    (void)choices;
    (void)count;
    (void)allow_custom;
    if (custom_out) *custom_out = NULL;
    return count > 0 ? 0 : -1;
}

static const ClayAppIO HEADLESS_IO = {
    .say = headless_say,
    .list_header = headless_list_header,
    .list_step = headless_list_step,
    .task_start = headless_task_start,
    .task_success = headless_task_success,
    .task_fail = headless_task_fail,
    .select = headless_select,
    .confirm = headless_confirm,
    .choice = headless_choice,
};

const ClayAppIO *clay_app_headless_io(void) {
    return &HEADLESS_IO;
}
