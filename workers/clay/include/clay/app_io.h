#ifndef CLAY_APP_IO_H
#define CLAY_APP_IO_H

#include "clay/choice.h"

typedef struct ClayApp ClayApp;
typedef struct ClayTask ClayTask;

/*
 * Presentation/input boundary for ClayApp.
 *
 * The agent/application state machine depends only on these callbacks.
 * Interactive terminal rendering lives in app_tui.c; headless execution
 * can use app_headless.c without linking the TUI implementation.
 */
typedef struct {
    void (*say)(const char *text);
    void (*list_header)(const char *text);
    void (*list_step)(int index, const char *verb, const char *target,
                      const char *info, int link);

    ClayTask *(*task_start)(const char *label);
    void (*task_success)(ClayTask *task, const char *result);
    void (*task_fail)(ClayTask *task, const char *result);

    int (*select)(const char *question, const ClayChoice *options, int count,
                  int default_index);
    int (*confirm)(const char *question, int default_yes);
    int (*choice)(const char *question, const ClayChoice *choices, int count,
                  int allow_custom, char **custom_out);
} ClayAppIO;

const ClayAppIO *clay_app_tui_io(void);
const ClayAppIO *clay_app_headless_io(void);

#endif /* CLAY_APP_IO_H */
