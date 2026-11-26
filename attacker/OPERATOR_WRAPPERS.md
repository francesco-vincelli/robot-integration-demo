# Attacker Phase 3: operator wrappers

This package provides host-side operator controls for the bounded ROS 2 navigation-cancellation demo.

## Files and repository destinations

```text
scripts/run_attack.sh
scripts/stop_attack.sh
scripts/attack_status.sh
```

Phase 3 depends on:

```text
attacker/attack.py              # Phase 1
scripts/attack_preflight.sh     # Phase 2
```

## Install

From the repository root:

```bash
mkdir -p scripts
cp /path/to/package/scripts/*.sh scripts/
chmod +x \
  scripts/run_attack.sh \
  scripts/stop_attack.sh \
  scripts/attack_status.sh
```

## Validate

```bash
bash -n \
  scripts/run_attack.sh \
  scripts/stop_attack.sh \
  scripts/attack_status.sh
```

## Run

Default bounded demonstration, 3 seconds at 0.5-second intervals:

```bash
./scripts/run_attack.sh
```

Explicit values:

```bash
./scripts/run_attack.sh 5 0.5
```

The wrapper:

1. validates numeric limits;
2. invokes the passive Phase 2 preflight;
3. shows the selected parameters;
4. runs `attack.py` inside the attacker container;
5. requires the operator to type `ATTACK` before execution.

Accepted limits:

```text
0 < duration <= 15 seconds
0.2 <= period <= duration
```

## Check status

```bash
./scripts/attack_status.sh
```

## Stop early

From another host terminal:

```bash
./scripts/stop_attack.sh
```

The stop script sends `SIGINT`, allowing `attack.py` to publish its inactive/interrupted state and shut down its ROS context cleanly.

## Important scope

These wrappers are intended only for the isolated repository simulation. The wrapper targets the bounded Phase 1 implementation and does not publish velocity commands.
