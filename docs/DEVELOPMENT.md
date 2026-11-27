# Development Guide

## ROS workspace

```bash
cd /workspace/robot/patrol_ws
source /opt/ros/jazzy/setup.bash
colcon build --symlink-install --packages-select robot_patrol
source install/setup.bash
```

## Python validation

```bash
python3 -m py_compile \
  robot/patrol_ws/src/robot_patrol/robot_patrol/patrol_node.py \
  robot/patrol_ws/src/robot_patrol/robot_patrol/particle_cloud_converter.py \
  attacker/attack.py
```

## Shell validation

```bash
bash -n scripts/*.sh
```

## Git hygiene

Do not commit:

```text
build/
install/
log/
__pycache__/
*.pyc
attacker/results/*
```

Prefer focused commits:

```text
feat: new runtime capability
fix: defect correction
test: automated validation
docs: documentation only
chore: cleanup or tooling
```

## Authoritative files

- World: `robot/worlds/warehouse_demo.sdf`
- Robot SDF: `robot/models/turtlebot3/gz_waffle.sdf.xacro`
- Robot URDF: `robot/models/turtlebot3/turtlebot3_waffle.urdf`
- Nav2: `robot/config/warehouse_nav2_params.yaml`
- RViz: `robot/config/warehouse_nav2.rviz`
- Runtime patrol route: `robot/config/patrol_warehouse.yaml`
- Named route record: `robot/config/warehouse_waypoints_recorded.yaml`
- Attacker: `attacker/attack.py`
