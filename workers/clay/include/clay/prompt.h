#ifndef CLAY_PROMPT_H
#define CLAY_PROMPT_H

#include "clay/choice.h"

#include <stddef.h>

typedef struct ClayCommandRegistry ClayCommandRegistry;

char *clay_prompt_line(ClayCommandRegistry *commands);
int clay_prompt_was_interrupted(void);
char *clay_prompt_secret(const char *question);

size_t clay_prompt_history_count(void);
const char *clay_prompt_history_get(size_t index);
void clay_prompt_history_clear(void);

int clay_prompt_select(const char *question, const ClayChoice *options, int count,
                       int default_index);
int clay_prompt_confirm(const char *question, int default_yes);
int clay_prompt_choice(const char *question, const ClayChoice *choices, int count,
                       int allow_custom, char **custom_out);

void clay_prompt_choice_compact_result(const char *result, int count, int allow_custom);

#endif /* CLAY_PROMPT_H */
