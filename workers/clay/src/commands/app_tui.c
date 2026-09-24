#include "clay/app_io.h"

#include "clay/list.h"
#include "clay/prompt.h"
#include "clay/task.h"

#include <stdio.h>

static void tui_say(const char *text) {
    clay_say("%s", text);
}

static void tui_list_header(const char *text) {
    clay_list_header("%s", text);
}

static void tui_list_step(int index, const char *verb, const char *target,
                          const char *info, int link) {
    clay_list_step(index, verb, target, info, link);
}

static ClayTask *tui_task_start(const char *label) {
    return clay_task_start("%s", label);
}

static void tui_task_success(ClayTask *task, const char *result) {
    clay_task_success(task, "%s", result);
}

static void tui_task_fail(ClayTask *task, const char *result) {
    clay_task_fail(task, "%s", result);
}

static int tui_select(const char *question, const ClayChoice *options, int count,
                      int default_index) {
    return clay_prompt_select(question, options, count, default_index);
}

static int tui_confirm(const char *question, int default_yes) {
    return clay_prompt_confirm(question, default_yes);
}

static int tui_choice(const char *question, const ClayChoice *choices, int count,
                      int allow_custom, char **custom_out) {
    return clay_prompt_choice(question, choices, count, allow_custom, custom_out);
}

static const ClayAppIO TUI_IO = {
    .say = tui_say,
    .list_header = tui_list_header,
    .list_step = tui_list_step,
    .task_start = tui_task_start,
    .task_success = tui_task_success,
    .task_fail = tui_task_fail,
    .select = tui_select,
    .confirm = tui_confirm,
    .choice = tui_choice,
};

const ClayAppIO *clay_app_tui_io(void) {
    return &TUI_IO;
}
