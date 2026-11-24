# Final TurtleBot3 sensor-deck visuals

This update converts the raised orange part into an intentional sensor deck.

## Changes

- Keeps the safety-orange deck at `z = 0.145 m`.
- Keeps the cyan beacon at `z = 0.185 m`.
- Removes `demo_graphite_front_panel`, which appeared as a hanging black piece.
- Adds four compact graphite mounting posts beneath the deck.
- Adds no collision, inertia, joint, sensor, TF, or plugin changes.

## Apply inside `robot-demo`

```bash
source /opt/ros/jazzy/setup.bash
python3 /workspace/robot/tools/finalize_turtlebot3_sensor_deck.py
```

The script creates this backup if it does not already exist:

```text
robot/models/turtlebot3/gz_waffle_before_sensor_deck.sdf.xacro
```

## Validate

```bash
xacro \
  /workspace/robot/models/turtlebot3/gz_waffle.sdf.xacro \
  namespace:= \
  > /tmp/turtlebot3_sensor_deck_final.sdf

grep -nE \
  'demo_safety_orange_top_cover|demo_cyan_status_beacon|demo_mount_(front|rear)_(left|right)' \
  /tmp/turtlebot3_sensor_deck_final.sdf

if grep -q 'demo_graphite_front_panel' /tmp/turtlebot3_sensor_deck_final.sdf; then
  echo 'ERROR: old graphite panel is still present'
else
  echo 'Old graphite panel removed: OK'
fi

python3 -c "import xml.etree.ElementTree as ET; ET.parse('/tmp/turtlebot3_sensor_deck_final.sdf'); print('Generated SDF: OK')"
```

Expected: six named visuals in the first `grep`: orange deck, cyan beacon, and four mounts.

## Relaunch

Stop the running launch completely, then:

```bash
ros2 launch /workspace/robot/launch/warehouse_robot.launch.py
```

## Roll back

```bash
cp \
  /workspace/robot/models/turtlebot3/gz_waffle_before_sensor_deck.sdf.xacro \
  /workspace/robot/models/turtlebot3/gz_waffle.sdf.xacro
```
