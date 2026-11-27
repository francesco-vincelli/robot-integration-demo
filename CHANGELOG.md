# Changelog

## Unreleased

### Added

- Custom Gazebo warehouse and occupancy map.
- TurtleBot3 Waffle simulation, ROS-Gazebo bridges and visible sensor deck.
- AMCL, Nav2 MPPI controller, costmaps, velocity smoother and Collision Monitor.
- Eight validated autonomous patrol waypoints.
- ParticleCloud-to-PoseArray converter for RViz.
- Separate attacker container on the shared ROS 2 domain.
- Bounded `NavigateToPose` cancellation demonstration.
- Preflight, operator, testing, evidence, repeatability and reset scripts.

### Fixed

- URDF package mesh paths.
- Gazebo IMU system integration.
- Particle-cloud subscription QoS.
- LiDAR self-detection by setting the minimum simulated range to `0.25 m`.
