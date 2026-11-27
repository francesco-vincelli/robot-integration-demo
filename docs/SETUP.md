# Setup

## 1. Prepare the host

```bash
cd ~/robot-integration-demo
xhost +SI:localuser:root
docker compose build
docker compose up -d robot attacker
docker compose ps
```

The runtime uses the Compose bridge network `robot-security-net` and ROS domain `42`.

## 2. Build the patrol workspace

```bash
docker compose exec robot bash
source /opt/ros/jazzy/setup.bash
cd /workspace/robot/patrol_ws
colcon build --symlink-install --packages-select robot_patrol
source install/setup.bash
ros2 pkg executables robot_patrol
```

Expected executables:

```text
robot_patrol patrol_node
robot_patrol particle_cloud_converter
```

## 3. X11/software rendering

Inside the robot container:

```bash
mkdir -p /tmp/runtime-root
chmod 700 /tmp/runtime-root
export XDG_RUNTIME_DIR=/tmp/runtime-root
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export LIBGL_DRI3_DISABLE=1
```

These settings are appropriate for hosts where direct GPU rendering is unavailable.

## 4. Verify container networking

On the host:

```bash
docker inspect robot-demo --format '{{json .HostConfig.NetworkMode}}'
docker inspect attacker-demo --format '{{json .HostConfig.NetworkMode}}'
docker compose exec robot hostname -I
docker compose exec attacker hostname -I
```

Both containers should use `robot-security-net` and have distinct bridge addresses.

## 5. Verify ROS discovery

Inside the attacker container:

```bash
source /opt/ros/jazzy/setup.bash
echo "$ROS_DOMAIN_ID"
ros2 node list
ros2 topic list
ros2 action list
```

Expected domain:

```text
42
```

## 6. Build changes

Rebuild only the attacker image:

```bash
docker compose build attacker
docker compose up -d attacker
```

Rebuild only the robot image:

```bash
docker compose build robot
docker compose up -d robot
```

## 7. Shutdown

```bash
docker compose down
xhost -SI:localuser:root
```
