#include "context.h"

void clay_commands_register(ClayCommands *commands) {
    ClayCommandRegistry *registry = clay_app_commands(commands->app);
    clay_command_register(registry, "help", "Show available commands", clay_cmd_help, commands);
    clay_command_register(registry, "exit", "Quit clay", clay_cmd_exit, commands);
    clay_command_register(registry, "model", "Pick a model from a connected provider", clay_cmd_model, commands);
    clay_command_register_alias(registry, "models", clay_cmd_model, commands);
    clay_command_register_alias(registry, "provider", clay_cmd_connect, commands);
    clay_command_register_alias(registry, "providers", clay_cmd_connect, commands);
    clay_command_register(registry, "effort", "Set reasoning effort for supported models", clay_cmd_effort, commands);
    clay_command_register(registry, "resume", "Resume a saved chat", clay_cmd_resume, commands);
    clay_command_register(registry, "history", "Show recent messages from the active chat", clay_cmd_history, commands);
    clay_command_register(registry, "memory", "Browse long-term memory, or /memory <slug> / /memory forget <slug>",
                          clay_cmd_memory, commands);
    clay_command_register(registry, "new", "Start a new empty chat", clay_cmd_new, commands);
    clay_command_register_alias(registry, "clear", clay_cmd_new, commands);
    clay_command_register(registry, "connect", "Connect a provider, or /connect <id> directly", clay_cmd_connect, commands);
    clay_command_register_alias(registry, "login", clay_cmd_connect, commands);
    clay_command_register(registry, "logout", "Log out from a connected provider", clay_cmd_logout, commands);
    clay_command_register(registry, "sandbox", "Configure the shell sandbox (mode, outside-workspace access)",
                          clay_cmd_sandbox, commands);
    clay_command_register_alias(registry, "__cycle_sandbox", clay_cmd_cycle_sandbox, commands);
    clay_command_register(registry, "exec", "Run a shell command through the sandbox directly", clay_cmd_exec,
                          commands);
    clay_command_register(registry, "checkpoints", "Browse and restore this chat's workspace checkpoints",
                          clay_cmd_checkpoints, commands);
    clay_command_register(registry, "undo", "Undo the last successful write or edit",
                          clay_cmd_undo, commands);
    clay_command_register(registry, "permissions", "Toggle auto-approval for read/edit/exec tool calls",
                          clay_cmd_permissions, commands);
    clay_command_register(registry, "plan", "Toggle Plan mode (blocks mutating tool calls) vs. Act mode",
                          clay_cmd_plan, commands);
    clay_command_register(registry, "autotest",
                          "Set the command to run after edits (/autotest <command>, /autotest clear)",
                          clay_cmd_autotest, commands);
    clay_command_register(registry, "compact", "Replace the conversation with an LLM-written summary",
                          clay_cmd_compact, commands);
}
