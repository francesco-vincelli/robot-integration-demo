# Contributing

## Workflow

1. Create a focused branch.
2. Keep generated ROS, Python and evidence files untracked.
3. Validate Python and shell syntax.
4. Run relevant unit and live tests.
5. Document behavioural or interface changes.
6. Submit focused commits with clear messages.

## Validation checklist

```bash
python3 -m py_compile attacker/attack.py
bash -n scripts/*.sh
./scripts/test_attacker.sh
```

For robot changes, also build the ROS workspace and complete at least one patrol loop.

## Safety

Do not extend the attacker to production systems, external networks or direct motor-command bypasses. Keep interventions bounded and preserve Collision Monitor.
