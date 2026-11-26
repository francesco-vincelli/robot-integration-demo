# Attacker component
The attacker is a bounded ROS 2 `NavigateToPose` cancellation demonstrator for the isolated warehouse simulation.

- It does not publish to velocity topics.
- Default run time is 3 seconds.
- Maximum allowed duration is 15 seconds.
- Use `--dry-run` or `scripts/test_attacker.sh --with-ros` for passive validation.

See `docs/security_demo.md` for the complete operator runbook.
