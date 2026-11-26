#!/usr/bin/env bash
# Validate the bounded attacker implementation without executing an attack.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
ATTACKER_SERVICE="${ATTACKER_SERVICE:-attacker}"
WITH_ROS=false

usage() {
    cat <<'EOF'
Usage: ./scripts/test_attacker.sh [--with-ros]

Default mode:
  - validates Python and shell syntax
  - runs unit tests inside the attacker container
  - checks attack.py --help

--with-ros additionally:
  - runs the passive Phase 2 preflight
  - runs attack.py --dry-run
  - confirms Collision Monitor remains active
  - confirms the attack node does not publish on velocity topics
EOF
}

case "${1:-}" in
    '') ;;
    --with-ros) WITH_ROS=true ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; exit 2 ;;
esac

cd "${REPO_ROOT}"

fail() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

info() {
    printf '[INFO] %s\n' "$*"
}

command -v docker >/dev/null 2>&1 || fail 'docker is unavailable.'
docker compose version >/dev/null 2>&1 || fail 'Docker Compose v2 is unavailable.'
[[ -f attacker/attack.py ]] || fail 'Missing attacker/attack.py.'
[[ -f attacker/test_attack.py ]] || fail 'Missing attacker/test_attack.py.'

info 'Checking shell syntax.'
for script in \
    scripts/attack_preflight.sh \
    scripts/run_attack.sh \
    scripts/stop_attack.sh \
    scripts/attack_status.sh \
    scripts/test_attacker.sh
do
    if [[ -f "${script}" ]]; then
        bash -n "${script}"
    elif [[ "${script}" == 'scripts/attack_status.sh' ]]; then
        info 'Optional attack_status.sh is absent; skipping.'
    else
        fail "Required script is missing: ${script}"
    fi
done

container_id="$(docker compose ps -q "${ATTACKER_SERVICE}")"
[[ -n "${container_id}" ]] || fail "Attacker container is absent. Run: docker compose up -d ${ATTACKER_SERVICE}"
[[ "$(docker inspect --format '{{.State.Running}}' "${container_id}")" == true ]] || \
    fail "Attacker container is not running."

info 'Checking Python syntax, CLI help, and unit tests inside the attacker container.'
docker compose exec -T "${ATTACKER_SERVICE}" bash -lc '
set -euo pipefail
source /opt/ros/jazzy/setup.bash
cd /workspace/attacker
python3 -m py_compile attack.py test_attack.py
python3 attack.py --help >/dev/null
python3 -m unittest -v test_attack.py
find . -type d -name __pycache__ -prune -exec rm -rf {} +
'

if [[ "${WITH_ROS}" == true ]]; then
    info 'Running passive live-ROS checks.'
    [[ -x scripts/attack_preflight.sh ]] || fail 'Phase 2 preflight is missing or not executable.'
    ./scripts/attack_preflight.sh

    docker compose exec -T "${ATTACKER_SERVICE}" bash -lc '
set -euo pipefail
source /opt/ros/jazzy/setup.bash
python3 /workspace/attacker/attack.py --dry-run
'

    state="$(docker compose exec -T "${ATTACKER_SERVICE}" bash -lc '
source /opt/ros/jazzy/setup.bash
ros2 lifecycle get /collision_monitor
')"
    grep -Fq 'active [3]' <<<"${state}" || fail "Collision Monitor is not active: ${state}"

    for topic in /cmd_vel /cmd_vel_nav /cmd_vel_smoothed; do
        publishers="$(docker compose exec -T "${ATTACKER_SERVICE}" bash -lc "
source /opt/ros/jazzy/setup.bash
ros2 topic info '${topic}' --verbose
")"
        if grep -Eq 'Node name: (navigation_cancel_attack|attack|attacker)' <<<"${publishers}"; then
            fail "Unexpected attacker publisher found on ${topic}."
        fi
    done

    info 'Live ROS dry-run checks passed.'
fi

printf 'Attacker Phase 4 tests: PASS\n'
