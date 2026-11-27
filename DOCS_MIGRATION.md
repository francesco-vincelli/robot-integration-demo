# Documentation migration

The bundle is intended to replace scattered intermediate development notes with authoritative documents.

Recommended removals after review:

```text
robot/CUSTOM_WAREHOUSE.md
robot/WAREHOUSE_FINAL.md
robot/TURTLEBOT3_SENSOR_DECK_FINAL.md
attacker/PREFLIGHT.md
attacker/OPERATOR_WRAPPERS.md
attacker/TESTING.md
```

The information is consolidated into:

```text
README.md
docs/ARCHITECTURE.md
docs/SETUP.md
docs/DEMO_RUNBOOK.md
docs/SECURITY.md
docs/TESTING.md
docs/TROUBLESHOOTING.md
docs/DEVELOPMENT.md
attacker/README.md
robot/README.md
```

Do not delete an old document until `git diff` confirms no unique project information would be lost.
