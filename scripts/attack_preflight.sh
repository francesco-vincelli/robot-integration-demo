#!/usr/bin/env bash

# Passive readiness checks for the controlled ROS 2 cancellation demo.
# This script does not cancel goals and does not publish commands.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"

ATTACKER_SERVICE="${ATTACKER_SERVICE:-attacker}"
EXPECTED_DOMAIN_ID="${EXPECTED_DOMAIN_ID:-42}"
CANCEL_SERVICE="${CANCEL_SERVICE:-/navigate_to_pose/_action/cancel_goal}"
EXPECTED_CANCEL_TYPE="${EXPECTED_CANCEL_TYPE:-action_msgs/srv/CancelGoal}"
ODOM_TOPIC="${ODOM_TOPIC:-/odom}"
ATTACK_SCRIPT="${ATTACK_SCRIPT:-/workspace/attacker/attack.py}"

info()
{
    printf '[INFO] %s\n' "$*"
}

fail()
{
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

cd "${REPO_ROOT}"

command -v docker >/dev/null 2>&1 ||
    fail "docker is unavailable in PATH."

docker compose version >/dev/null 2>&1 ||
    fail "Docker Compose v2 is unavailable."

compose_services="$(docker compose config --services)"

if ! grep -Fx "${ATTACKER_SERVICE}" \
    <<< "${compose_services}" \
    >/dev/null
then
    fail "Compose service '${ATTACKER_SERVICE}' is not defined."
fi

container_id="$(docker compose ps -q "${ATTACKER_SERVICE}")"

if [[ -z "${container_id}" ]]
then
    fail \
        "Attacker container does not exist. Run: docker compose up -d ${ATTACKER_SERVICE}"
fi

running="$(
    docker inspect \
        --format '{{.State.Running}}' \
        "${container_id}"
)"

if [[ "${running}" != "true" ]]
then
    fail \
        "Attacker container is not running. Run: docker compose up -d ${ATTACKER_SERVICE}"
fi

info "Attacker container is running."

docker compose exec -T \
    -e EXPECTED_DOMAIN_ID="${EXPECTED_DOMAIN_ID}" \
    -e CANCEL_SERVICE="${CANCEL_SERVICE}" \
    -e EXPECTED_CANCEL_TYPE="${EXPECTED_CANCEL_TYPE}" \
    -e ODOM_TOPIC="${ODOM_TOPIC}" \
    -e ATTACK_SCRIPT="${ATTACK_SCRIPT}" \
    "${ATTACKER_SERVICE}" \
    bash -s <<'CONTAINER_SCRIPT'
set -eo pipefail

# ROS-generated setup scripts can reference unset variables.
set +u
source /opt/ros/jazzy/setup.bash
set -u

info()
{
    printf '[INFO] %s\n' "$*"
}

fail()
{
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

info "ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-unset}"

if [[ "${ROS_DOMAIN_ID:-}" != "${EXPECTED_DOMAIN_ID}" ]]
then
    fail \
        "Expected ROS_DOMAIN_ID=${EXPECTED_DOMAIN_ID}, got ${ROS_DOMAIN_ID:-unset}."
fi

command -v ros2 >/dev/null 2>&1 ||
    fail "ros2 CLI is unavailable in the attacker container."

if pgrep -af \
    "[p]ython3 .*${ATTACK_SCRIPT}" \
    >/dev/null 2>&1
then
    fail \
        "An attacker process is already running: ${ATTACK_SCRIPT}"
fi

info "No existing attacker process found."

info "Waiting for cancellation service: ${CANCEL_SERVICE}"

service_listing=""
service_found=false

for attempt in $(seq 1 15)
do
    # Capture all ROS output before filtering. Piping ros2 directly into
    # grep -q can cause BrokenPipeError under pipefail.
    if service_listing="$(
        ros2 service list \
            --include-hidden-services \
            2>/dev/null
    )"
    then
        if grep -Fx \
            "${CANCEL_SERVICE}" \
            <<< "${service_listing}" \
            >/dev/null
        then
            service_found=true
            break
        fi
    fi

    info \
        "Service is not visible yet; discovery attempt ${attempt}/15..."

    sleep 1
done

if [[ "${service_found}" != "true" ]]
then
    printf '[INFO] Visible navigation actions:\n'

    action_listing="$(
        ros2 action list 2>/dev/null ||
        true
    )"

    grep -E \
        'navigate|follow_path' \
        <<< "${action_listing}" ||
        true

    printf '[INFO] Visible NavigateToPose action services:\n'

    grep -F \
        '/navigate_to_pose/_action' \
        <<< "${service_listing}" ||
        true

    fail \
        "Target cancellation service is unavailable after 15 seconds: ${CANCEL_SERVICE}"
fi

info "Cancellation service discovered: ${CANCEL_SERVICE}"

# Initialise variables explicitly because nounset is active.
service_type_listing=""
service_entry=""
actual_type=""

if ! service_type_listing="$(
    ros2 service list \
        --include-hidden-services \
        -t \
        2>/dev/null
)"
then
    fail "Could not retrieve the ROS 2 service type listing."
fi

service_entry="$(
    grep -F \
        "${CANCEL_SERVICE} [" \
        <<< "${service_type_listing}" |
    head -n 1 ||
    true
)"

if [[ -z "${service_entry}" ]]
then
    fail \
        "Could not retrieve the type entry for ${CANCEL_SERVICE}."
fi

actual_type="$(
    sed -n \
        's/^.*\[\(.*\)\]$/\1/p' \
        <<< "${service_entry}"
)"

if [[ -z "${actual_type}" ]]
then
    fail \
        "Could not parse the service type from: ${service_entry}"
fi

if [[ "${actual_type}" != "${EXPECTED_CANCEL_TYPE}" ]]
then
    fail \
        "Unexpected service type '${actual_type}'; expected '${EXPECTED_CANCEL_TYPE}'."
fi

info "Cancellation service type is correct: ${actual_type}"

topic_listing="$(
    ros2 topic list 2>/dev/null
)"

if ! grep -Fx \
    "${ODOM_TOPIC}" \
    <<< "${topic_listing}" \
    >/dev/null
then
    fail \
        "Required telemetry topic is unavailable: ${ODOM_TOPIC}"
fi

# Bound the test if the topic exists but is not producing messages.
if ! timeout 5 \
    ros2 topic echo \
        "${ODOM_TOPIC}" \
        --once \
        --field twist \
        >/dev/null 2>&1
then
    fail \
        "Could not read one message from ${ODOM_TOPIC} within 5 seconds."
fi

info "Telemetry read succeeded: ${ODOM_TOPIC}"

printf 'Attacker preflight: PASS\n'
CONTAINER_SCRIPT
