# Warehouse world v2

This revision prioritises stable TurtleBot3 / Nav2 navigation and a professional visual layout.

## Main changes
- Expanded footprint to 12 m x 9 m.
- Clear side aisles and cross-aisles around three shorter racks.
- Detailed visual shelving with one simple collision volume per rack.
- Split, low south wall with a 2.2 m loading-bay opening.
- Larger Home, Inspection, Storage and Shipping zones.
- Asymmetric office, cabinet, columns and pallet placement for AMCL.
- Clear east-side attack corridor and restricted target.
- Occupancy map regenerated from the same collision dimensions.

## Test
```bash
xhost +SI:localuser:root
docker compose up -d robot
docker compose exec robot bash
source /opt/ros/jazzy/setup.bash
gz sim -v 4 /workspace/robot/worlds/warehouse_demo.sdf
```

## Expected world
Three industrial shelf rows, clear cross-aisles, a low front wall with loading-bay opening, office corner, charging dock, inspection panel, shipping pallets, support columns, enlarged coloured stations, and red restricted target.

## Before Nav2
- Confirm all primary corridors are visibly continuous.
- Confirm the loading bay and attack target are in frame from the intended camera.
- Keep `warehouse_demo_v1_rendering_ok.sdf` as rollback.

## Nav2 integration caveat
The coordinates in `config/patrol_warehouse.yaml` are design values. Record final points from RViz after the robot, costmaps and inflation layer are active.
