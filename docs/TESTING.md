# Testing

## Static and unit tests

```bash
docker compose up -d attacker
./scripts/test_attacker.sh
```

## Live passive tests

With Nav2 running:

```bash
./scripts/test_attacker.sh --with-ros
```

This runs preflight and `--dry-run` only.

## Navigation baseline

Acceptance criteria:

- all Nav2 lifecycle nodes are active;
- `map -> base_footprint` is available;
- eight waypoints complete;
- at least two continuous loops succeed;
- Collision Monitor does not deadlock;
- robot stops after goal completion.

## Attacker trial

```bash
./scripts/run_attack.sh 3 0.5
```

Acceptance criteria:

- active goal is canceled;
- robot decelerates within approximately 1-2 seconds;
- patrol retries within approximately 2-5 seconds;
- no Nav2 restart is required;
- AMCL remains localised;
- Collision Monitor remains active;
- no attacker velocity publisher appears.

## Repeatability

```bash
./scripts/run_repeatability_trials.sh 5 3 0.5
```

Run trials across west, south, east, north and return-to-home segments.

## Evidence

```bash
./scripts/capture_attack_evidence.sh
```

Generated evidence is written under `attacker/results/` and ignored by Git.
