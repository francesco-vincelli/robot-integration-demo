# Controlled ROS 2 Mission-Cancellation Demonstration

## Scope
This runbook applies only to the isolated Gazebo warehouse simulation. The attacker shares ROS domain `42` and demonstrates missing action-level access control. It does not publish motor commands.

## Architecture
Normal: `robot_patrol -> NavigateToPose -> Nav2 -> velocity_smoother -> collision_monitor -> robot`.

Intervention: `attacker -> /navigate_to_pose/_action/cancel_goal -> active goal canceled`.

## Start
```bash
./scripts/start_demo.sh
```
Start warehouse simulation, localization, navigation, RViz and the converter in separate terminals. Set the AMCL initial pose. Then:
```bash
./scripts/start_patrol.sh
```

## Preflight and dry run
```bash
./scripts/attack_preflight.sh
./scripts/test_attacker.sh --with-ros
```

## Run bounded intervention
```bash
./scripts/run_attack.sh 3 0.5
```
Type `ATTACK` when prompted.

## Monitor
```bash
ros2 topic echo /security_demo/attack_status
ros2 topic echo /navigate_to_pose/_action/status
ros2 topic echo /odom --field twist
ros2 lifecycle get /collision_monitor
```
Expected action sequence: EXECUTING `2`, CANCELED `5`, retry EXECUTING `2`, SUCCEEDED `4`.

## Evidence
```bash
./scripts/capture_attack_evidence.sh
```
Generated evidence under `attacker/results/` is ignored by Git by default.

## Repeatability
```bash
./scripts/run_repeatability_trials.sh 5 3 0.5
```
Acceptance target: 5/5 bounded runs, no Nav2 restart, Collision Monitor active, no attacker velocity publisher.

## Reset and stop
```bash
./scripts/reset_demo.sh
./scripts/stop_demo.sh
```

## Mitigations
- SROS2 identities, governance and DDS permissions.
- Separate networks and ROS domain IDs.
- Authenticated mission-control gateway.
- Allow-list action clients allowed to cancel missions.
- Monitoring and audit alerts for unexpected action clients and cancellations.
