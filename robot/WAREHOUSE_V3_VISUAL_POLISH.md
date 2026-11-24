# Warehouse v3 safe visual polish

This update adds only visual-only geometry. Collision geometry and the Nav2 occupancy map are unchanged from v2.

## Added
- Restricted-zone hazard hatching and stop bars
- Directional floor arrows
- Charging plate, contacts, marker panel, and status light
- Office monitors, chair, and window panel
- Additional asymmetric rack loads
- Overhead beams and light-fixture visuals without a roof

## Validation
Run the standard warehouse Gazebo command and confirm that the existing aisles remain clear. The occupancy map does not need regeneration because the new elements have no collision definitions.
