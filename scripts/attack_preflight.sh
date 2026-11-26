#!/usr/bin/env bash
# Passive preflight for the controlled ROS 2 attacker demonstration.
# This script performs discovery/readiness checks only. It does not send
# cancellation requests and does not publish movement commands.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ATTACKER_SERVICE="${ATTACKER_SERVICE:-attacker}"
EXPECTED_DOMAIN_ID="${EXPECTED_DOMAIN_ID:-42}"
CANCEL_SERVICE="${CANCEL_SERVICE:-/navigate_to_pose/_action/cancel_goal}"
EXPECTED_CANCEL_TYPE="action_msgs/srv/CancelGoal"
ODOM_TOPIC="${ODOM_TOPIC:-/odom}"
ATTACK_SCRIPT="/workspace/attacker/attack.py"

info() {
    printf '[INFO] %s\n' "$*"
}

fail() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

cd "${REPO_ROOT}"

command -v docker >/dev/null 2>&1 || fail "docker is not installed or not available in PATH."
docker compose version >/dev/null 2>&1 || fail "Docker Compose v2 is unavailable."

if ! docker compose config --services | grep -Fxq "${ATTACKER_SERVICE}"; then
    fail "Compose service '${ATTACKER_SERVICE}' is not defined."
fi

container_id="$(docker compose ps -q "${ATTACKER_SERVICE}")"
[[ -n "${container_id}" ]] || fail "Attacker container has not been created. Run: docker compose up -d ${ATTACKER_SERVICE}"

running="$(docker inspect --format '{{.State.Running}}' "${container_id}")"
[[ "${running}" == "true" ]] || fail "Attacker container is not running. Run: docker compose up -d ${ATTACKER_SERVICE}"

info "Attacker container is running."

# All ROS checks execute inside the attacker container, where ROS 2 Jazzy is installed.
docker compose exec -T \
    -e EXPECTED_DOMAIN_ID="${EXPECTED_DOMAIN_ID}" \
    -e CANCEL_SERVICE="${CANCEL_SERVICE}" \
    -e EXPECTED_CANCEL_TYPE="${EXPECTED_CANCEL_TYPE}" \
    -e ODOM_TOPIC="${ODOM_TOPIC}" \
    -e ATTACK_SCRIPT="${ATTACK_SCRIPT}" \
    "${ATTACKER_SERVICE}" bash -lc '
set -euo pipefail
source /opt/ros/jazzy/setup.bash

fail() {
    printf "[ERROR] %s\n" "$*" >&2
    exit 1
}

printf "[INFO] ROS_DOMAIN_ID=%s\n" "${ROS_DOMAIN_ID:-unset}"
[[ "${ROS_DOMAIN_ID:-}" == "${EXPECTED_DOMAIN_ID}" ]] || \
    fail "Expected ROS_DOMAIN_ID=${EXPECTED_DOMAIN_ID}, got ${ROS_DOMAIN_ID:-unset}."

command -v ros2 >/dev/null 2>&1 || fail "ros2 CLI is unavailable in the attacker container."

if pgrep -af "[p]ython3 .*${ATTACK_SCRIPT}" >/dev/null 2>&1; then
    fail "An attacker process is already running: ${ATTACK_SCRIPT}"
fi
printf "[INFO] No existing attacker process found.\n"

ros2 service list | grep -Fxq "${CANCEL_SERVICE}" || \
    fail "Target cancellation service is unavailable: ${CANCEL_SERVICE}"
printf "[INFO] Cancellation service discovered: %s\n" "${CANCEL_SERVICE}"

actual_type="$(ros2 service type "${CANCEL_SERVICE}")"
[[ "${actual_type}" == "${EXPECTED_CANCEL_TYPE}" ]] || \
    fail "Unexpected service type: ${actual_type}; expected ${EXPECTED_CANCEL_TYPE}."
printf "[INFO] Cancellation service type is correct: %s\n" "${actual_type}"

ros2 topic list | grep -Fxq "${ODOM_TOPIC}" || \
    fail "Required telemetry topic is unavailable: ${ODOM_TOPIC}"

# timeout bounds the check if the topic exists but is not producing messages.
if ! timeout 5 ros2 topic echo "${ODOM_TOPIC}" --once --field twist >/dev/null 2>&1; then
    fail "Could not read one message from ${ODOM_TOPIC} within 5 seconds."
fi
printf "[INFO] Telemetry read succeeded: %s\n" "${ODOM_TOPIC}"

printf "Attacker preflight: PASS\n"
'
