#!/usr/bin/env python3

import math
from enum import Enum, auto

import rclpy
from action_msgs.msg import GoalStatus
from geometry_msgs.msg import PoseStamped
from nav2_msgs.action import NavigateToPose
from rclpy.action import ActionClient
from rclpy.node import Node


class PatrolState(Enum):
    WAITING_FOR_NAV2 = auto()
    READY = auto()
    SENDING_GOAL = auto()
    NAVIGATING = auto()
    WAITING_AT_WAYPOINT = auto()
    RETRY_WAIT = auto()
    STOPPED = auto()


class RobotPatrol(Node):

    def __init__(self):
        super().__init__('robot_patrol')

        self.declare_parameter('frame_id', 'map')
        self.declare_parameter(
            'waypoints',
            [
                1.0, 1.0, 0.0,
                2.0, 1.0, 0.0,
                2.0, -1.0, 0.0,
                1.0, -1.0, 0.0,
            ],
        )
        self.declare_parameter('pause_at_waypoint', 1.0)
        self.declare_parameter('retry_delay', 2.0)
        self.declare_parameter('max_retries', 3)
        self.declare_parameter('loop_forever', True)

        self.frame_id = (
            self.get_parameter('frame_id')
            .get_parameter_value()
            .string_value
        )

        raw_waypoints = (
            self.get_parameter('waypoints')
            .get_parameter_value()
            .double_array_value
        )

        self.pause_at_waypoint = (
            self.get_parameter('pause_at_waypoint')
            .get_parameter_value()
            .double_value
        )

        self.retry_delay = (
            self.get_parameter('retry_delay')
            .get_parameter_value()
            .double_value
        )

        self.max_retries = (
            self.get_parameter('max_retries')
            .get_parameter_value()
            .integer_value
        )

        self.loop_forever = (
            self.get_parameter('loop_forever')
            .get_parameter_value()
            .bool_value
        )

        if len(raw_waypoints) == 0 or len(raw_waypoints) % 3 != 0:
            raise ValueError(
                'The waypoints parameter must contain x, y, yaw triples.'
            )

        self.waypoints = [
            (
                float(raw_waypoints[index]),
                float(raw_waypoints[index + 1]),
                float(raw_waypoints[index + 2]),
            )
            for index in range(0, len(raw_waypoints), 3)
        ]

        self.navigate_client = ActionClient(
            self,
            NavigateToPose,
            'navigate_to_pose',
        )

        self.state = PatrolState.WAITING_FOR_NAV2
        self.current_waypoint = 0
        self.retry_count = 0
        self.goal_handle = None
        self.wait_timer = None

        self.server_timer = self.create_timer(
            1.0,
            self.wait_for_navigation_server,
        )

        self.get_logger().info(
            f'Loaded {len(self.waypoints)} patrol waypoints.'
        )
        self.get_logger().info(
            'Waiting for the NavigateToPose action server...'
        )

    def wait_for_navigation_server(self):
        if not self.navigate_client.server_is_ready():
            self.get_logger().info(
                'NavigateToPose is not ready; waiting...'
            )
            return

        self.server_timer.cancel()
        self.state = PatrolState.READY

        self.get_logger().info(
            'NavigateToPose is ready. Starting patrol.'
        )

        self.send_current_waypoint()

    def send_current_waypoint(self):
        if self.state == PatrolState.STOPPED:
            return

        x, y, yaw = self.waypoints[self.current_waypoint]

        goal = NavigateToPose.Goal()
        goal.pose = self.create_pose(x, y, yaw)

        self.state = PatrolState.SENDING_GOAL

        self.get_logger().info(
            f'Sending waypoint {self.current_waypoint + 1}/'
            f'{len(self.waypoints)}: '
            f'x={x:.2f}, y={y:.2f}, yaw={yaw:.2f}'
        )

        send_future = self.navigate_client.send_goal_async(
            goal,
            feedback_callback=self.feedback_callback,
        )

        send_future.add_done_callback(
            self.goal_response_callback
        )

    def goal_response_callback(self, future):
        try:
            self.goal_handle = future.result()
        except Exception as exception:
            self.get_logger().error(
                f'Failed to send navigation goal: {exception}'
            )
            self.schedule_retry()
            return

        if not self.goal_handle.accepted:
            self.get_logger().warning(
                f'Waypoint {self.current_waypoint + 1} was rejected.'
            )
            self.schedule_retry()
            return

        self.state = PatrolState.NAVIGATING

        self.get_logger().info(
            f'Waypoint {self.current_waypoint + 1} accepted.'
        )

        result_future = self.goal_handle.get_result_async()
        result_future.add_done_callback(
            self.navigation_result_callback
        )

    def navigation_result_callback(self, future):
        try:
            wrapped_result = future.result()
            status = wrapped_result.status
        except Exception as exception:
            self.get_logger().error(
                f'Navigation result failed: {exception}'
            )
            self.schedule_retry()
            return

        if status == GoalStatus.STATUS_SUCCEEDED:
            reached_waypoint = self.current_waypoint + 1

            self.get_logger().info(
                f'Reached waypoint {reached_waypoint}.'
            )

            self.retry_count = 0
            self.advance_waypoint()
            return

        status_name = self.goal_status_name(status)

        self.get_logger().warning(
            f'Navigation to waypoint '
            f'{self.current_waypoint + 1} ended with '
            f'status {status_name}.'
        )

        self.schedule_retry()

    def advance_waypoint(self):
        is_last_waypoint = (
            self.current_waypoint == len(self.waypoints) - 1
        )

        if is_last_waypoint and not self.loop_forever:
            self.state = PatrolState.STOPPED
            self.get_logger().info(
                'Final waypoint reached. Patrol complete.'
            )
            return

        self.current_waypoint = (
            self.current_waypoint + 1
        ) % len(self.waypoints)

        self.state = PatrolState.WAITING_AT_WAYPOINT

        self.get_logger().info(
            f'Waiting {self.pause_at_waypoint:.1f} seconds '
            'before the next waypoint.'
        )

        self.create_one_shot_timer(
            self.pause_at_waypoint,
            self.send_current_waypoint,
        )

    def schedule_retry(self):
        self.retry_count += 1

        if self.retry_count > self.max_retries:
            self.get_logger().error(
                f'Waypoint {self.current_waypoint + 1} failed '
                f'after {self.max_retries} retries. '
                'Skipping to the next waypoint.'
            )

            self.retry_count = 0
            self.advance_waypoint()
            return

        self.state = PatrolState.RETRY_WAIT

        self.get_logger().warning(
            f'Retrying waypoint {self.current_waypoint + 1} '
            f'in {self.retry_delay:.1f} seconds '
            f'({self.retry_count}/{self.max_retries}).'
        )

        self.create_one_shot_timer(
            self.retry_delay,
            self.send_current_waypoint,
        )

    def create_one_shot_timer(self, delay, callback):
        if self.wait_timer is not None:
            self.wait_timer.cancel()
            self.destroy_timer(self.wait_timer)
            self.wait_timer = None

        def timer_callback():
            if self.wait_timer is not None:
                self.wait_timer.cancel()
                self.destroy_timer(self.wait_timer)
                self.wait_timer = None

            callback()

        self.wait_timer = self.create_timer(
            max(delay, 0.01),
            timer_callback,
        )

    def create_pose(self, x, y, yaw):
        pose = PoseStamped()

        pose.header.frame_id = self.frame_id
        pose.header.stamp = self.get_clock().now().to_msg()

        pose.pose.position.x = x
        pose.pose.position.y = y
        pose.pose.position.z = 0.0

        pose.pose.orientation.x = 0.0
        pose.pose.orientation.y = 0.0
        pose.pose.orientation.z = math.sin(yaw / 2.0)
        pose.pose.orientation.w = math.cos(yaw / 2.0)

        return pose

    def feedback_callback(self, feedback_message):
        feedback = feedback_message.feedback
        distance = feedback.distance_remaining

        self.get_logger().debug(
            f'Waypoint {self.current_waypoint + 1}: '
            f'{distance:.2f} m remaining.'
        )

    @staticmethod
    def goal_status_name(status):
        names = {
            GoalStatus.STATUS_UNKNOWN: 'UNKNOWN',
            GoalStatus.STATUS_ACCEPTED: 'ACCEPTED',
            GoalStatus.STATUS_EXECUTING: 'EXECUTING',
            GoalStatus.STATUS_CANCELING: 'CANCELING',
            GoalStatus.STATUS_SUCCEEDED: 'SUCCEEDED',
            GoalStatus.STATUS_CANCELED: 'CANCELED',
            GoalStatus.STATUS_ABORTED: 'ABORTED',
        }

        return names.get(status, f'UNRECOGNISED({status})')


def main(args=None):
    rclpy.init(args=args)

    node = RobotPatrol()

    try:
        rclpy.spin(node)
    except KeyboardInterrupt:
        node.get_logger().info('Patrol interrupted by operator.')
    finally:
        node.destroy_node()

        if rclpy.ok():
            rclpy.shutdown()


if __name__ == '__main__':
    main()
