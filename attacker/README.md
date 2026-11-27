# Attacker Component

The attacker is a bounded ROS 2 mission-cancellation demonstrator for the isolated warehouse simulation.

## Behaviour

- discovers `/navigate_to_pose/_action/cancel_goal`;
- requests cancellation of eligible goals for a bounded duration;
- requires explicit operator confirmation;
- publishes attack activity/status topics;
- stops automatically;
- never publishes velocity commands.

## Passive checks

```bash
./scripts/attack_preflight.sh
./scripts/test_attacker.sh --with-ros
```

## Run

```bash
./scripts/run_attack.sh 3 0.5
```

## Status and stop

```bash
./scripts/attack_status.sh
./scripts/stop_attack.sh
```

## Safety bounds

```text
maximum duration: 15 seconds
minimum period:   0.2 seconds
default duration: 3 seconds
default period:   0.5 seconds
```

For architecture, monitoring, recovery and mitigations, see [the security demo runbook](../docs/DEMO_RUNBOOK.md) and [security model](../docs/SECURITY.md).
