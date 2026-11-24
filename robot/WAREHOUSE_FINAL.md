# Final custom warehouse world

This final revision removes the three visually dominant transverse ceiling beams and retains the six overhead light fixtures using thin, visual-only suspension rods.

## Architectural intent
- The south-side opening is an intentional loading bay linking the simulated inspection zone to a conceptual wider warehouse.
- The roof is omitted deliberately so the elevated Gazebo presentation camera can see the patrol and attack path.
- Full-height rear and side walls bound the navigation area.
- Low south-wall sections preserve the loading-bay cutaway view.
- Added suspension rods and all light fixtures are visual-only and do not alter the occupancy map or Nav2 collision geometry.

## Validation
```bash
python3 -c "import xml.etree.ElementTree as ET; ET.parse('/workspace/robot/worlds/warehouse_demo.sdf'); print('XML syntax: OK')"
gz sim -v 4 /workspace/robot/worlds/warehouse_demo.sdf
```

Confirm that no `ceiling_beam_*` entities appear, six `overhead_light_fixture_*` entities remain, and twelve `light_*_suspension_*` entities are visible.
