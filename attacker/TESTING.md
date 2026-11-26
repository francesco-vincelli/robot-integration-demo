# Attacker Phase 4 tests

## Files

Copy these files into the repository:

```text
attacker/test_attack.py
scripts/test_attacker.sh
```

## Dependencies

The tests expect these earlier-phase files:

```text
attacker/attack.py
scripts/attack_preflight.sh
scripts/run_attack.sh
scripts/stop_attack.sh
scripts/attack_status.sh   # optional
```

The `attack.py` module must expose:

```python
validate(args)
```

where `args` has `duration`, `period`, `discovery_timeout`, and `request_timeout` attributes.

## Install

```bash
cp attacker/test_attack.py ~/task/robot-integration-demo/attacker/
cp scripts/test_attacker.sh ~/task/robot-integration-demo/scripts/
chmod +x ~/task/robot-integration-demo/scripts/test_attacker.sh
```

## Run offline/static tests

The attacker container must be running, but the robot/Nav2 stack is not required:

```bash
docker compose up -d attacker
./scripts/test_attacker.sh
```

## Run live ROS dry-run tests

The complete robot/Nav2 stack must be active:

```bash
./scripts/test_attacker.sh --with-ros
```

The live mode performs discovery and a dry-run only. It sends no goal-cancellation request and creates no velocity publisher.

## Expected final line

```text
Attacker Phase 4 tests: PASS
```
