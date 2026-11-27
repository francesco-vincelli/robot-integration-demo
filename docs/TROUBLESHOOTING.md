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

## GitHub push uses the wrong account

Use separate SSH aliases with `IdentitiesOnly yes`, then set the remote to the personal alias.
