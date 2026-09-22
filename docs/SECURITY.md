# Security

AI CLI permissions and approval prompts are behavioral controls, not automatically a security boundary.

When stronger isolation is required, evaluate established mechanisms first:

- container isolation;
- namespaces;
- VMs;
- restricted users/accounts;
- capability-based host access;
- the separate Ai-guard enforcement layer.

Do not grant unrestricted host mounts, Docker sockets, SSH credentials, or root access merely because an AI CLI needs operational access.
