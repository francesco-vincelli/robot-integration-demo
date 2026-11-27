# ROS 2 Warehouse Security Demo

A repeatable robotics-integration demonstration built with ROS 2 Jazzy, Gazebo Harmonic, Nav2 and Docker Compose. A simulated TurtleBot3 Waffle patrols a custom warehouse while a separate container demonstrates how an untrusted participant on the same unprotected DDS domain can interrupt the mission through the exposed `NavigateToPose` cancellation interface.

> **Scope:** isolated simulation and authorised security demonstration only. The attacker is bounded, requires explicit operator confirmation, does not publish motor commands and leaves Nav2 Collision Monitor active.

## What the demo shows

1. A custom warehouse simulation with a mapped environment and visible TurtleBot3.
2. AMCL localisation, global planning, MPPI control, velocity smoothing and collision monitoring.
3. An autonomous eight-waypoint patrol validated over multiple loops.
4. Cross-container ROS 2 discovery on a shared DDS domain.
5. A bounded mission-cancellation intervention and automatic patrol recovery.
6. Concrete mitigations using DDS Security/SROS2, segmentation and least privilege.

## Architecture

```text
robot_patrol
    -> /navigate_to_pose
    -> bt_navigator
    -> planner_server + controller_server
    -> /cmd_vel_nav
    -> velocity_smoother
    -> /cmd_vel_smoothed
    -> collision_monitor
    -> /cmd_vel
    -> ros_gz_bridge
    -> Gazebo TurtleBot3

attacker container
    -> /navigate_to_pose/_action/cancel_goal
    -> active patrol goal canceled
```

The attacker never publishes to `/cmd_vel`, `/cmd_vel_nav` or `/cmd_vel_smoothed`.

## Repository layout

```text
attacker/                   bounded attacker, tests and component notes
docker/                     robot and attacker container images
docs/                       architecture, setup, runbooks and troubleshooting
robot/config/               bridge, Nav2, RViz and patrol configuration
robot/launch/               warehouse simulation launcher
robot/maps/                 warehouse occupancy map
robot/models/               TurtleBot3 SDF/Xacro and URDF
robot/patrol_ws/            ROS 2 patrol and visualisation package
robot/worlds/               custom Gazebo warehouse
scripts/                    operator, test, evidence and reset wrappers
compose.yaml                multi-container environment
```

## Requirements

- Ubuntu host with Docker Engine and Docker Compose v2
- X11 display access for Gazebo and RViz
- Git
- Approximately 8 GB RAM recommended for software-rendered Gazebo and RViz
- No host ROS 2 installation is required

## Quick start

```bash
git clone <repository-url>
cd robot-integration-demo
xhost +SI:localuser:root
docker compose build
docker compose up -d robot attacker
```

Follow [docs/SETUP.md](docs/SETUP.md) for the complete build and environment checks, then [docs/DEMO_RUNBOOK.md](docs/DEMO_RUNBOOK.md) for the normal patrol and security demonstration.

## Validated patrol route

The patrol uses eight tested map-frame poses:

```text
Home -> West Centre -> South West -> South Centre
     -> South East -> East Centre -> North East
     -> North Centre -> Home
```

Runtime configuration:

```text
robot/config/patrol_warehouse.yaml
```

Human-readable record:

```text
robot/config/warehouse_waypoints_recorded.yaml
```

## Safety controls

- Attack duration is bounded to a maximum of 15 seconds.
- The default intervention is 3 seconds with a 0.5-second period.
- Operator confirmation is required.
- `scripts/stop_attack.sh` interrupts the attacker cleanly.
- Collision Monitor remains active.
- `scripts/reset_demo.sh` requests a controlled reset.

## Testing

```bash
./scripts/test_attacker.sh
./scripts/test_attacker.sh --with-ros
```

See [docs/TESTING.md](docs/TESTING.md) for acceptance criteria and repeatability trials.

## Documentation

- [Setup](docs/SETUP.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Demo runbook](docs/DEMO_RUNBOOK.md)
- [Security model and mitigations](docs/SECURITY.md)
- [Testing](docs/TESTING.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Development](docs/DEVELOPMENT.md)
- [Attacker component](attacker/README.md)

## Current status

- Warehouse and robot simulation: validated
- AMCL and Nav2: validated
- Collision Monitor: validated
- Eight-waypoint autonomous patrol: validated over multiple loops
- Cross-container DDS visibility: validated
- Bounded cancellation attacker: implementation and test tooling included

## Licence

No licence is granted unless a `LICENSE` file is added. Keep the repository private until ownership, third-party assets and disclosure constraints have been reviewed.
