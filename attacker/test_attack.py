#!/usr/bin/env python3
"""Unit tests for the bounded attacker argument validation.

These tests do not initialise ROS, call services, cancel goals, or publish topics.
"""

import unittest
from types import SimpleNamespace

import attack


def arguments(
    *,
    duration=3.0,
    period=0.5,
    discovery_timeout=10.0,
    request_timeout=1.0,
):
    """Create the argument object expected by attack.validate()."""
    return SimpleNamespace(
        duration=duration,
        period=period,
        discovery_timeout=discovery_timeout,
        request_timeout=request_timeout,
    )


class ValidationTests(unittest.TestCase):
    """Verify the bounded timing and timeout constraints."""

    def assert_valid(self, **overrides):
        values = arguments(**overrides)
        try:
            attack.validate(values)
        except SystemExit as exception:
            self.fail(f'Expected values to be accepted, got: {exception}')

    def assert_invalid(self, **overrides):
        with self.assertRaises(SystemExit):
            attack.validate(arguments(**overrides))

    def test_default_like_values_are_valid(self):
        self.assert_valid(
            duration=3.0,
            period=0.5,
            discovery_timeout=10.0,
            request_timeout=1.0,
        )

    def test_boundary_values_are_valid(self):
        self.assert_valid(
            duration=15.0,
            period=0.2,
            discovery_timeout=0.001,
            request_timeout=0.001,
        )

    def test_period_equal_to_duration_is_valid(self):
        self.assert_valid(duration=0.2, period=0.2)

    def test_zero_duration_is_rejected(self):
        self.assert_invalid(duration=0.0)

    def test_negative_duration_is_rejected(self):
        self.assert_invalid(duration=-1.0)

    def test_duration_above_limit_is_rejected(self):
        self.assert_invalid(duration=15.001)

    def test_period_below_minimum_is_rejected(self):
        self.assert_invalid(period=0.199)

    def test_period_greater_than_duration_is_rejected(self):
        self.assert_invalid(duration=1.0, period=1.1)

    def test_zero_discovery_timeout_is_rejected(self):
        self.assert_invalid(discovery_timeout=0.0)

    def test_negative_discovery_timeout_is_rejected(self):
        self.assert_invalid(discovery_timeout=-1.0)

    def test_zero_request_timeout_is_rejected(self):
        self.assert_invalid(request_timeout=0.0)

    def test_negative_request_timeout_is_rejected(self):
        self.assert_invalid(request_timeout=-1.0)


if __name__ == '__main__':
    unittest.main(verbosity=2)
