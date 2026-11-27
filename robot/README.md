# Robot Simulation

This directory contains the custom warehouse, TurtleBot3 model, ROS-Gazebo interfaces, Nav2 configuration, RViz layout and patrol workspace.

## Key files

```text
worlds/warehouse_demo.sdf
maps/warehouse_demo.yaml
launch/warehouse_robot.launch.py
config/turtlebot3_waffle_bridge.yaml
config/warehouse_nav2_params.yaml
config/warehouse_nav2.rviz
config/patrol_warehouse.yaml
models/turtlebot3/gz_waffle.sdf.xacro
models/turtlebot3/turtlebot3_waffle.urdf
patrol_ws/src/robot_patrol/
```

## Important simulation choices

- TurtleBot3 Waffle model
- GPU LiDAR minimum range `0.25 m`
- map resolution `0.05 m/cell`
- circular Nav2 footprint approximately `0.22 m`
- MPPI controller
- Collision Monitor retained in the final velocity path

For startup commands, see [the repository demo runbook](../docs/DEMO_RUNBOOK.md).
