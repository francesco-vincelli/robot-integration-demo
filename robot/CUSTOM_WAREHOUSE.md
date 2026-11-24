# Custom warehouse scenario

## Included files
- `worlds/warehouse_demo.sdf`: self-contained Gazebo Harmonic world, no Fuel dependency.
- `maps/warehouse_demo.pgm` and `.yaml`: occupancy map generated from collision geometry.
- `launch/warehouse_world.launch.py`: standalone world launch.
- `config/patrol_warehouse.yaml`: initial design waypoints, to validate after Nav2 integration.

## Test
From the host, copy the generated `robot/` content into the repository's existing `robot/` directory. Then:

```bash
xhost +SI:localuser:root
docker compose up -d robot
docker compose exec robot bash
source /opt/ros/jazzy/setup.bash
gz sim -v 4 /workspace/robot/worlds/warehouse_demo.sdf
```

Expected: a 10 m x 8 m warehouse with three rack rows, an office corner, charging/home zone, shipping pallets, floor markings, and a red restricted attack target.

## Next integration work
1. Spawn TurtleBot3 and bridge `/cmd_vel`, `/odom`, `/scan`, `/tf`, and `/clock`.
2. Load `maps/warehouse_demo.yaml` with Nav2.
3. Validate AMCL alignment and inflation clearance.
4. Replace design waypoints with RViz-recorded safe coordinates.
5. Test two patrol loops before attack work.
