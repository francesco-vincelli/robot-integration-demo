# Demo Runbook

Use a separate terminal for each long-running process.

## 1. Start containers

```bash
./scripts/start_demo.sh
```

## 2. Start warehouse simulation

```bash
docker compose exec robot bash
source /opt/ros/jazzy/setup.bash
ros2 launch /workspace/robot/launch/warehouse_robot.launch.py
```

## 3. Start localisation

```bash
docker compose exec robot bash
source /opt/ros/jazzy/setup.bash
ros2 launch nav2_bringup localization_launch.py \
  map:=/workspace/robot/maps/warehouse_demo.yaml \
  params_file:=/workspace/robot/config/warehouse_nav2_params.yaml \
  use_sim_time:=True autostart:=True
```

## 4. Start navigation

```bash
docker compose exec robot bash
source /opt/ros/jazzy/setup.bash
ros2 launch nav2_bringup navigation_launch.py \
  params_file:=/workspace/robot/config/warehouse_nav2_params.yaml \
  use_sim_time:=True autostart:=True use_composition:=False
```

## 5. Start RViz

```bash
docker compose exec robot bash
source /opt/ros/jazzy/setup.bash
export XDG_RUNTIME_DIR=/tmp/runtime-root
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export LIBGL_DRI3_DISABLE=1
mkdir -p "$XDG_RUNTIME_DIR" && chmod 700 "$XDG_RUNTIME_DIR"
rviz2 -d /workspace/robot/config/warehouse_nav2.rviz
```

Use **2D Pose Estimate** near Home:

```text
x approximately -4.44
y approximately  2.82
yaw approximately 0
```

## 6. Start particle visualisation

```bash
docker compose exec robot bash
source /opt/ros/jazzy/setup.bash
source /workspace/robot/patrol_ws/install/setup.bash
ros2 run robot_patrol particle_cloud_converter
```

## 7. Verify lifecycle nodes

```bash
for node in map_server amcl controller_server planner_server smoother_server behavior_server bt_navigator waypoint_follower velocity_smoother collision_monitor; do
  printf '%-24s ' "$node"
  ros2 lifecycle get "/$node" 2>&1 | tail -n 1
done
```

Every node should show `active [3]`.

## 8. Start patrol

```bash
./scripts/start_patrol.sh
```

## 9. Show normal operation

Demonstrate the global path, local/global costmaps, robot model, scan and patrol log. Confirm motion:

```bash
docker compose exec attacker bash -lc 'source /opt/ros/jazzy/setup.bash; ros2 topic echo /odom --once --field twist'
```

## 10. Run attacker preflight

```bash
./scripts/attack_preflight.sh
```

## 11. Run bounded intervention

```bash
./scripts/run_attack.sh 3 0.5
```

Type `ATTACK` when prompted.

Expected action sequence:

```text
EXECUTING (2) -> CANCELED (5) -> retry EXECUTING (2) -> SUCCEEDED (4)
```

## 12. Capture evidence

```bash
./scripts/capture_attack_evidence.sh
```

## 13. Reset or stop

```bash
./scripts/reset_demo.sh
```

or:

```bash
./scripts/stop_demo.sh
```
