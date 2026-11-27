# Troubleshooting

## RViz cannot display the robot

Verify `/robot_description`, one `robot_state_publisher`, and corrected mesh URIs containing:

```text
models/turtlebot3_model/meshes/
```

## `map` frame does not exist

Check `map_server` and AMCL are active, then use RViz **2D Pose Estimate**. Verify:

```bash
ros2 run tf2_ros tf2_echo map odom
```

## Robot does not move despite a global plan

Inspect:

```bash
ros2 topic echo /cmd_vel_nav
ros2 topic echo /cmd_vel_smoothed
ros2 topic echo /cmd_vel
ros2 topic echo /collision_monitor_state
```

The simulated LiDAR must report `range_min: 0.25` to reject robot self-returns.

## Particle cloud is absent in RViz

Run the converter and display `/particle_cloud_pose_array` as `PoseArray`. The converter subscription must use Best Effort QoS.

## Robot continues moving after manual velocity

Stop every existing publisher before sending zero:

```bash
pkill -f 'ros2 topic pub.*cmd_vel' || true
timeout 2 ros2 topic pub -r 20 /cmd_vel geometry_msgs/msg/Twist '{}'
```

## Attacker cannot discover Nav2

Confirm both containers use `ROS_DOMAIN_ID=42`, `ROS_AUTOMATIC_DISCOVERY_RANGE=SUBNET`, and `robot-security-net`.

## Python validation fails

Determine ownership and permissions for every parent directory:

```bash
namei -l \
  robot/patrol_ws/src/robot_patrol/robot_patrol/__pycache__
```

If __pycache__ does not currently exist:

```bash
namei -l \
  robot/patrol_ws/src/robot_patrol/robot_patrol
```

Then run:
```bash
ls -ld \
  robot \
  robot/patrol_ws \
  robot/patrol_ws/src \
  robot/patrol_ws/src/robot_patrol \
  robot/patrol_ws/src/robot_patrol/robot_patrol \
  robot/patrol_ws/src/robot_patrol/robot_patrol/__pycache__ \
  2>/dev/null
```

Remove the cache as root:

```bash
sudo rm -rf \
  robot/patrol_ws/src/robot_patrol/robot_patrol/__pycache__
```

Restore ownership on the exact source tree:

```bash
sudo chown -R \
  "$(id -un):$(id -gn)" \
  robot/patrol_ws/src/robot_patrol
```

Restore directory permissions:

```bash
find \
  robot/patrol_ws/src/robot_patrol \
  -type d \
  -exec chmod u+rwx {} +
```

Restore file permissions:

```bash
find \
  robot/patrol_ws/src/robot_patrol \
  -type f \
  -exec chmod u+rw {} +
```

Finally, run:

```bash
python3 -m py_compile \
  robot/patrol_ws/src/robot_patrol/robot_patrol/patrol_node.py \
  robot/patrol_ws/src/robot_patrol/robot_patrol/particle_cloud_converter.py
```