#include "clay/clay.h"
#include "clay/http.h"

#include <stdio.h>
#include <stdlib.h>

#define CLAY_VERSION "0.0.4"

int main(int argc, char **argv) {
    char *one_shot_prompt = NULL;
    int cli_status = clay_cli_startup_with_prompt(argc, argv, CLAY_VERSION,
                                                  &one_shot_prompt);
    if (cli_status != 0) return cli_status < 0 ? 1 : 0;

    if (!one_shot_prompt) {
        fprintf(stderr, "Usage: clay-worker --prompt \"task\"\n");
        return 2;
    }

    clay_term_init();
    clay_term_set_noninteractive(1);
    clay_term_set_color_enabled(0);

    if (clay_http_init() != 0) {
        fprintf(stderr, "Failed to initialize HTTP.\n");
        free(one_shot_prompt);
        return 1;
    }

    ClayApp *app = clay_app_create_with_io(clay_app_headless_io());
    if (!app) {
        fprintf(stderr, "Failed to initialize application.\n");
        clay_http_cleanup();
        free(one_shot_prompt);
        return 1;
    }

    ClayCommands *commands = clay_commands_create(app);
    if (!commands) {
        fprintf(stderr, "Failed to initialize commands.\n");
        clay_app_destroy(app);
        clay_http_cleanup();
        free(one_shot_prompt);
        return 1;
    }

    clay_commands_register(commands);

    if (!clay_commands_has_provider(commands)) {
        fprintf(stderr,
                "Error: no provider is configured for --prompt. "
                "Set provider credentials in the environment.\n");
        clay_commands_destroy(commands);
        clay_app_destroy(app);
        clay_http_cleanup();
        free(one_shot_prompt);
        return 1;
    }

    int ok = clay_commands_run_message(commands, one_shot_prompt);

    free(one_shot_prompt);
    clay_commands_destroy(commands);
    clay_app_destroy(app);
    clay_http_cleanup();
    return ok ? 0 : 1;
}
