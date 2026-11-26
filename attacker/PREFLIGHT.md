# Attacker Phase 2: passive preflight

This package contains the Phase 2 preflight script for the controlled ROS 2 security demonstration.

## Repository destination

Copy the file to:

```text
scripts/attack_preflight.sh
```

The expected repository layout is:

```text
robot-integration-demo/
├── attacker/
│   └── attack.py
├── compose.yaml
└── scripts/
    └── attack_preflight.sh
```

## Install

From the repository root:

```bash
mkdir -p scripts
cp /path/to/downloaded/scripts/attack_preflight.sh scripts/attack_preflight.sh
chmod +x scripts/attack_preflight.sh
```

## Run

Make sure the robot/Nav2 stack and attacker container are running:

```bash
docker compose up -d attacker
./scripts/attack_preflight.sh
```

Expected successful result:

```text
[INFO] Attacker container is running.
[INFO] ROS_DOMAIN_ID=42
[INFO] No existing attacker process found.
[INFO] Cancellation service discovered: /navigate_to_pose/_action/cancel_goal
[INFO] Cancellation service type is correct: action_msgs/srv/CancelGoal
[INFO] Telemetry read succeeded: /odom
Attacker preflight: PASS
```

## What it checks

- Docker and Docker Compose v2 are available on the host.
- The `attacker` Compose service exists and its container is running.
- The attacker container uses `ROS_DOMAIN_ID=42`.
- No existing `attack.py` process is running.
- `/navigate_to_pose/_action/cancel_goal` is discoverable.
- The service type is `action_msgs/srv/CancelGoal`.
- `/odom` exists and produces a message within five seconds.

The script is passive. It does not cancel goals and does not publish velocity commands.

## Optional overrides

```bash
EXPECTED_DOMAIN_ID=42 \
CANCEL_SERVICE=/navigate_to_pose/_action/cancel_goal \
ODOM_TOPIC=/odom \
./scripts/attack_preflight.sh
```

## Validate shell syntax

```bash
bash -n scripts/attack_preflight.sh
```
