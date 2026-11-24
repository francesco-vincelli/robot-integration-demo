# TurtleBot3 demo visibility update

This update adds three **visual-only** primitives to `base_link` in the repository-owned Waffle SDF Xacro:

- safety-orange top cover;
- dark graphite front panel;
- cyan status beacon.

It does not change collision geometry, inertia, wheels, sensors, joints, TF frames, or Gazebo plugins.

## Apply

After merging this bundle into the repository, enter `robot-demo` and run:

```bash
source /opt/ros/jazzy/setup.bash
python3 /workspace/robot/tools/apply_turtlebot3_visibility.py
```

The tool creates this backup once:

```text
robot/models/turtlebot3/gz_waffle_before_visibility.sdf.xacro
```

## Validate

```bash
xacro \
  /workspace/robot/models/turtlebot3/gz_waffle.sdf.xacro \
  namespace:= \
  > /tmp/turtlebot3_visible.sdf

grep -nE \
  'demo_safety_orange_top_cover|demo_graphite_front_panel|demo_cyan_status_beacon' \
  /tmp/turtlebot3_visible.sdf

python3 -c "import xml.etree.ElementTree as ET; ET.parse('/tmp/turtlebot3_visible.sdf'); print('Generated SDF: OK')"
```

## Test

Stop the current launch and start it again so Gazebo creates a fresh entity from the edited model:

```bash
ros2 launch /workspace/robot/launch/warehouse_robot.launch.py
```

## Roll back

```bash
cp \
  /workspace/robot/models/turtlebot3/gz_waffle_before_visibility.sdf.xacro \
  /workspace/robot/models/turtlebot3/gz_waffle.sdf.xacro
```
