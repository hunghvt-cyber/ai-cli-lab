#ifndef CLAY_APP_H
#define CLAY_APP_H

#include "clay/app_io.h"
#include "clay/command.h"

#include <stdarg.h>

typedef enum {
    CLAY_APP_IDLE,
    CLAY_APP_BUSY,
    CLAY_APP_PROMPTING,
    CLAY_APP_EXITING
} ClayAppState;

typedef struct ClayApp ClayApp;

typedef void (*ClayAppStateListener)(ClayApp *app, ClayAppState old_state,
                                     ClayAppState new_state, void *ctx);

ClayApp *clay_app_create(void);
ClayApp *clay_app_create_with_io(const ClayAppIO *io);
void clay_app_destroy(ClayApp *app);

ClayCommandRegistry *clay_app_commands(ClayApp *app);

ClayAppState clay_app_state(const ClayApp *app);
void clay_app_set_state(ClayApp *app, ClayAppState state);
void clay_app_on_state_change(ClayApp *app, ClayAppStateListener listener, void *ctx);

void *clay_app_get_data(const ClayApp *app);
void clay_app_set_data(ClayApp *app, void *data);

void clay_app_say(ClayApp *app, const char *fmt, ...);
void clay_app_list_header(ClayApp *app, const char *fmt, ...);
void clay_app_list_step(ClayApp *app, int index, const char *verb, const char *target,
                        const char *info, int link);

ClayTask *clay_app_task_start(ClayApp *app, const char *fmt, ...);
void clay_app_task_success(ClayApp *app, ClayTask *task, const char *fmt, ...);
void clay_app_task_fail(ClayApp *app, ClayTask *task, const char *fmt, ...);

int clay_app_select(ClayApp *app, const char *question, const ClayChoice *options, int count,
                    int default_index);
int clay_app_confirm(ClayApp *app, const char *question, int default_yes);
int clay_app_choice(ClayApp *app, const char *question, const ClayChoice *choices, int count,
                    int allow_custom, char **custom_out);

#endif /* CLAY_APP_H */
