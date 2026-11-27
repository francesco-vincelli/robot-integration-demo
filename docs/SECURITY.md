# Security Model

## Demonstrated condition

The baseline intentionally places the robot and attacker containers on the same unprotected ROS 2 DDS domain. The attacker can discover nodes, topics, actions and services without authentication.

## Demonstrated impact

An untrusted participant can invoke the public `NavigateToPose` cancellation service and interrupt the autonomous mission without publishing motor commands.

## Explicit non-goals

- No external or production system is targeted.
- No credential theft, persistence or destructive payload is implemented.
- No direct `/cmd_vel` injection is used.
- Collision Monitor remains active.
- Runtime and request frequency are bounded.

## Risks represented

- Flat robot networks
- Unauthenticated DDS discovery
- Excessive action/service permissions
- Missing mission-control allow-lists
- Insufficient monitoring of cancellation and preemption

## Mitigations

### DDS Security and SROS2

Create per-node identities and governance/permissions files. Allow the patrol/mission gateway to send goals while restricting cancellation to authorised operator identities.

### Network segmentation

Separate operator, robot and untrusted workloads using distinct container networks, VLANs and firewall policy. Do not expose ROS DDS broadly across user subnets.

### ROS domain separation

Different `ROS_DOMAIN_ID` values reduce accidental discovery but are not authentication. Use domain separation together with DDS Security and network controls.

### Authenticated gateway

Expose a narrow mission API rather than raw ROS interfaces. Authenticate users and validate allowed commands, duration and state transitions.

### Monitoring

Alert on:

- unexpected action clients;
- repeated cancellation requests;
- new DDS participants;
- goal preemption outside planned workflows;
- velocity publishers outside the approved chain.

## Responsible operation

Keep the repository private until proprietary content, third-party assets and disclosure obligations have been reviewed. Run the attacker only in the isolated simulation environment.
