#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Robot Integration Demo - Reset Script
#
# Restores the demo to its initial state by:
#
#   1. Stopping the attacker process
#   2. Stopping the patrol node
#   3. Cancelling active Nav2 goals
#   4. Publishing a zero-velocity command
#   5. Physically restoring the robot pose in Gazebo
#   6. Waiting for fresh simulation and sensor data
#   7. Restoring the corresponding AMCL initial pose
#   8. Clearing the Nav2 costmaps
#   9. Publishing a final zero-velocity command
#
# Run from the repository root on the host:
#
#   ./scripts/reset_demo.sh
#
# =============================================================================


# -----------------------------------------------------------------------------
# Repository configuration
# -----------------------------------------------------------------------------

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"


# -----------------------------------------------------------------------------
# Docker Compose configuration
# -----------------------------------------------------------------------------

ROBOT_SERVICE="${ROBOT_SERVICE:-robot}"
ATTACKER_SERVICE="${ATTACKER_SERVICE:-attacker}"


# -----------------------------------------------------------------------------
# Gazebo configuration
# -----------------------------------------------------------------------------

# Gazebo CLI installed through the ROS Jazzy vendor packages inside the robot
# container.
GZ="${GZ:-/opt/ros/jazzy/opt/gz_tools_vendor/bin/gz}"

WORLD_NAME="${WORLD_NAME:-warehouse_demo}"
ROBOT_ENTITY="${ROBOT_ENTITY:-turtlebot3_waffle}"

GAZEBO_SET_POSE_SERVICE="/world/${WORLD_NAME}/set_pose"


# -----------------------------------------------------------------------------
# Gazebo physical reset pose
# -----------------------------------------------------------------------------
#
# These values must match the original physical spawn pose of the robot.
#
# Override them without editing this file if required:
#
#   RESET_X=-4.439 \
#   RESET_Y=2.815 \
#   RESET_Z=0.01 \
#   RESET_YAW=0.0 \
#   ./scripts/reset_demo.sh
#
# -----------------------------------------------------------------------------

RESET_X="${RESET_X:--4.439}"
RESET_Y="${RESET_Y:-2.815}"
RESET_Z="${RESET_Z:-0.01}"
RESET_YAW="${RESET_YAW:-0.0}"


# -----------------------------------------------------------------------------
# AMCL reset pose
# -----------------------------------------------------------------------------
#
# By default, the AMCL pose is numerically equal to the Gazebo pose.
#
# Keep these values separate because the occupancy-map coordinates and Gazebo
# world coordinates may not always be identical.
#
# Example override:
#
#   AMCL_X=-4.0 \
#   AMCL_Y=-2.0 \
#   AMCL_YAW=0.0 \
#   ./scripts/reset_demo.sh
#
# -----------------------------------------------------------------------------

AMCL_X="${AMCL_X:-${RESET_X}}"
AMCL_Y="${AMCL_Y:-${RESET_Y}}"
AMCL_YAW="${AMCL_YAW:-${RESET_YAW}}"


# -----------------------------------------------------------------------------
# Timing configuration
# -----------------------------------------------------------------------------

GAZEBO_UPDATE_WAIT="${GAZEBO_UPDATE_WAIT:-2}"
AMCL_STABILISATION_WAIT="${AMCL_STABILISATION_WAIT:-3}"


# -----------------------------------------------------------------------------
# Logging functions
# -----------------------------------------------------------------------------

log_info()
{
    printf '[INFO] %s\n' "$*"
}

log_ok()
{
    printf '[OK] %s\n' "$*"
}

log_warn()
{
    printf '[WARN] %s\n' "$*" >&2
}

log_error()
{
    printf '[ERROR] %s\n' "$*" >&2
}


# -----------------------------------------------------------------------------
# Container command helpers
# -----------------------------------------------------------------------------

robot_bash()
{
    docker compose exec -T "${ROBOT_SERVICE}" bash -lc "$1"
}


compose_service_is_running()
{
    local service="$1"

    docker compose ps --status running --services |
        grep -Fx "${service}" >/dev/null
}


# -----------------------------------------------------------------------------
# Convert yaw angles to quaternions
# -----------------------------------------------------------------------------

read -r RESET_QZ RESET_QW < <(
    python3 - "${RESET_YAW}" <<'PY'
import math
import sys

yaw = float(sys.argv[1])

print(
    math.sin(yaw / 2.0),
    math.cos(yaw / 2.0),
)
PY
)


read -r AMCL_QZ AMCL_QW < <(
    python3 - "${AMCL_YAW}" <<'PY'
import math
import sys

yaw = float(sys.argv[1])

print(
    math.sin(yaw / 2.0),
    math.cos(yaw / 2.0),
)
PY
)


# =============================================================================
# 1. Check the robot container
# =============================================================================

log_info "Checking that the ${ROBOT_SERVICE} container is running."

if ! compose_service_is_running "${ROBOT_SERVICE}"; then
    log_error "Docker Compose service '${ROBOT_SERVICE}' is not running."
    exit 1
fi

log_ok "Robot container is running."


# =============================================================================
# 2. Stop the attacker process
# =============================================================================

log_info "Stopping attacker process, if present."

if compose_service_is_running "${ATTACKER_SERVICE}"; then
    docker compose exec -T "${ATTACKER_SERVICE}" bash -lc "
        ATTACKER_PIDS=\$(pgrep -f '[a]ttacker/attack.py' || true)

        if [ -n \"\${ATTACKER_PIDS}\" ]; then
            echo \"[INFO] Attacker PID(s): \${ATTACKER_PIDS}\"

            for pid in \${ATTACKER_PIDS}; do
                kill -INT \"\${pid}\" 2>/dev/null || true
            done

            sleep 1
        else
            echo '[INFO] No attacker process found.'
        fi
    " || true
else
    log_info "Attacker container is not running."
fi


# =============================================================================
# 3. Stop the patrol node
# =============================================================================

log_info "Stopping patrol node."

robot_bash "
    PATROL_PIDS=\$(pgrep -f '[r]obot_patrol/patrol_node' || true)

    if [ -n \"\${PATROL_PIDS}\" ]; then
        echo \"[INFO] Patrol PID(s): \${PATROL_PIDS}\"

        for pid in \${PATROL_PIDS}; do
            kill -INT \"\${pid}\" 2>/dev/null || true
        done

        sleep 1

        REMAINING_PIDS=\$(pgrep -f '[r]obot_patrol/patrol_node' || true)

        if [ -n \"\${REMAINING_PIDS}\" ]; then
            echo \"[WARN] Patrol did not stop after SIGINT; sending SIGTERM.\"

            for pid in \${REMAINING_PIDS}; do
                kill -TERM \"\${pid}\" 2>/dev/null || true
            done

            sleep 1
        fi
    else
        echo '[INFO] No patrol process found.'
    fi
"


# =============================================================================
# 4. Cancel active Nav2 NavigateToPose goals
# =============================================================================

log_info "Cancelling active Nav2 NavigateToPose goals."

robot_bash "
    source /opt/ros/jazzy/setup.bash

    if ros2 service list --include-hidden-services |
        grep -Fx '/navigate_to_pose/_action/cancel_goal' >/dev/null
    then
        timeout 5 ros2 service call \
            /navigate_to_pose/_action/cancel_goal \
            action_msgs/srv/CancelGoal \
            '{
                goal_info: {
                    goal_id: {
                        uuid: [
                            0, 0, 0, 0,
                            0, 0, 0, 0,
                            0, 0, 0, 0,
                            0, 0, 0, 0
                        ]
                    },
                    stamp: {
                        sec: 0,
                        nanosec: 0
                    }
                }
            }' \
            >/dev/null 2>&1 || true
    else
        echo '[WARN] Nav2 cancel-goal service is not available.'
    fi
"


# =============================================================================
# 5. Publish zero velocity
# =============================================================================

publish_zero_velocity()
{
    robot_bash "
        source /opt/ros/jazzy/setup.bash

        timeout 1 ros2 topic pub \
            --rate 20 \
            /cmd_vel \
            geometry_msgs/msg/Twist \
            '{
                linear: {
                    x: 0.0,
                    y: 0.0,
                    z: 0.0
                },
                angular: {
                    x: 0.0,
                    y: 0.0,
                    z: 0.0
                }
            }' \
            >/dev/null 2>&1 || true
    "
}


log_info "Publishing zero velocity before physical reset."

publish_zero_velocity


# =============================================================================
# 6. Verify the Gazebo CLI
# =============================================================================

log_info "Checking Gazebo CLI."

if ! robot_bash "test -x '${GZ}'"; then
    log_error "Gazebo CLI was not found or is not executable:"
    log_error "${GZ}"
    exit 1
fi

log_ok "Gazebo CLI is available."


# =============================================================================
# 7. Physically restore the robot pose in Gazebo
# =============================================================================
#
# Do not perform a separate `gz service --list` check here.
#
# The actual set-pose request is authoritative. The operation is considered
# successful only when Gazebo returns:
#
#   data: true
#
# =============================================================================

log_info "Restoring '${ROBOT_ENTITY}' physical pose in Gazebo."

log_info \
    "Target Gazebo pose: x=${RESET_X}, y=${RESET_Y}, z=${RESET_Z}, yaw=${RESET_YAW}"


if ! SET_POSE_OUTPUT="$(
    robot_bash "
        source /opt/ros/jazzy/setup.bash

        '${GZ}' service \
            --service '${GAZEBO_SET_POSE_SERVICE}' \
            --reqtype gz.msgs.Pose \
            --reptype gz.msgs.Boolean \
            --timeout 5000 \
            --req 'name: \"${ROBOT_ENTITY}\",
                   position: {
                       x: ${RESET_X},
                       y: ${RESET_Y},
                       z: ${RESET_Z}
                   },
                   orientation: {
                       x: 0.0,
                       y: 0.0,
                       z: ${RESET_QZ},
                       w: ${RESET_QW}
                   }'
    "
)"; then
    log_error "Gazebo set-pose command failed."
    log_error "Service: ${GAZEBO_SET_POSE_SERVICE}"
    log_error "Entity: ${ROBOT_ENTITY}"
    exit 1
fi


printf '%s\n' "${SET_POSE_OUTPUT}"


if ! grep -Eq 'data:[[:space:]]*true' <<<"${SET_POSE_OUTPUT}"; then
    log_error "Gazebo did not confirm the physical pose reset."
    log_error "Expected response: data: true"
    log_error "Service: ${GAZEBO_SET_POSE_SERVICE}"
    log_error "Entity: ${ROBOT_ENTITY}"

    if [ -n "${SET_POSE_OUTPUT}" ]; then
        log_error "Gazebo response:"
        printf '%s\n' "${SET_POSE_OUTPUT}" >&2
    else
        log_error "Gazebo returned an empty response."
    fi

    exit 1
fi

log_ok "Gazebo physical pose restored."


# =============================================================================
# 8. Ensure that the robot remains stopped after teleportation
# =============================================================================

log_info "Publishing zero velocity after physical reset."

publish_zero_velocity


# =============================================================================
# 9. Wait for fresh simulation state and sensor data
# =============================================================================

log_info \
    "Waiting ${GAZEBO_UPDATE_WAIT} seconds for Gazebo sensors, odometry and TF."

sleep "${GAZEBO_UPDATE_WAIT}"


# =============================================================================
# 10. Restore AMCL localisation
# =============================================================================

log_info "Publishing the matching AMCL initial pose."

log_info \
    "Target AMCL pose: x=${AMCL_X}, y=${AMCL_Y}, yaw=${AMCL_YAW}"


robot_bash "
    source /opt/ros/jazzy/setup.bash

    ros2 topic pub \
        --once \
        /initialpose \
        geometry_msgs/msg/PoseWithCovarianceStamped \
        '{
            header: {
                frame_id: \"map\"
            },
            pose: {
                pose: {
                    position: {
                        x: ${AMCL_X},
                        y: ${AMCL_Y},
                        z: 0.0
                    },
                    orientation: {
                        x: 0.0,
                        y: 0.0,
                        z: ${AMCL_QZ},
                        w: ${AMCL_QW}
                    }
                },
                covariance: [
                    0.25, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.0, 0.25, 0.0, 0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0685
                ]
            }
        }'
"


# =============================================================================
# 11. Allow AMCL to stabilise
# =============================================================================

log_info \
    "Waiting ${AMCL_STABILISATION_WAIT} seconds for AMCL to stabilise."

sleep "${AMCL_STABILISATION_WAIT}"


# =============================================================================
# 12. Clear the Nav2 global costmap
# =============================================================================

log_info "Clearing Nav2 global costmap."

robot_bash "
    source /opt/ros/jazzy/setup.bash

    if ros2 service list |
        grep -Fx '/global_costmap/clear_entirely_global_costmap' >/dev/null
    then
        timeout 5 ros2 service call \
            /global_costmap/clear_entirely_global_costmap \
            nav2_msgs/srv/ClearEntireCostmap \
            '{}' \
            >/dev/null 2>&1 || true
    else
        echo '[WARN] Global costmap clear service is not available.'
    fi
"


# =============================================================================
# 13. Clear the Nav2 local costmap
# =============================================================================

log_info "Clearing Nav2 local costmap."

robot_bash "
    source /opt/ros/jazzy/setup.bash

    if ros2 service list |
        grep -Fx '/local_costmap/clear_entirely_local_costmap' >/dev/null
    then
        timeout 5 ros2 service call \
            /local_costmap/clear_entirely_local_costmap \
            nav2_msgs/srv/ClearEntireCostmap \
            '{}' \
            >/dev/null 2>&1 || true
    else
        echo '[WARN] Local costmap clear service is not available.'
    fi
"


# =============================================================================
# 14. Send a final zero-velocity command
# =============================================================================

log_info "Sending final zero-velocity command."

publish_zero_velocity


# =============================================================================
# Complete
# =============================================================================

printf '\n'

log_ok "Demo reset completed."

log_ok \
    "Gazebo pose: x=${RESET_X}, y=${RESET_Y}, z=${RESET_Z}, yaw=${RESET_YAW}"

log_ok \
    "AMCL pose: x=${AMCL_X}, y=${AMCL_Y}, yaw=${AMCL_YAW}"

log_info "The patrol node remains stopped."
log_info "The demo is ready to be started again."
