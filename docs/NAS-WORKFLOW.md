# NAS Workflow

AI CLI tools may need legitimate operational visibility on the NAS.

Examples:

- system status;
- RAM/swap/disk state;
- Docker state;
- systemd services;
- recording files;
- explicitly authorized maintenance.

The access model should expose only the capabilities required for the task.

Default behavior:

AUDIT → OBSERVE → REPORT → STOP

Any modification or broader operation requires explicit authorization.
