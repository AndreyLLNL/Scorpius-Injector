"""Tests for scorpius_injector.focusing – solenoid magnet model."""

import math
import pytest
import numpy as np

from scorpius_injector.config import SolenoidConfig
from scorpius_injector.focusing import Solenoid


@pytest.fixture
def sol():
    cfg = SolenoidConfig(
        position=0.5,
        length=0.25,
        bore_radius=0.05,
        peak_field=0.10,
        name="TEST_SOL",
    )
    return Solenoid(cfg)


class TestOnAxisField:
    def test_peak_at_centre(self, sol):
        """Field at the geometric centre should be close to peak_field."""
        B_centre = sol.on_axis_field(sol.centre)
        assert B_centre == pytest.approx(sol.config.peak_field, rel=0.01)

    def test_field_vanishes_far_upstream(self, sol):
        B = sol.on_axis_field(sol.config.position - 5 * sol.config.bore_radius)
        assert B < 1e-4 * sol.config.peak_field

    def test_field_vanishes_far_downstream(self, sol):
        z_exit = sol.config.position + sol.config.length
        B = sol.on_axis_field(z_exit + 5 * sol.config.bore_radius)
        assert B < 1e-4 * sol.config.peak_field

    def test_field_non_negative(self, sol):
        z_arr = np.linspace(0.0, 2.0, 500)
        B_arr = np.array([sol.on_axis_field(z) for z in z_arr])
        assert np.all(B_arr >= 0.0)

    def test_field_bounded_by_peak(self, sol):
        z_arr = np.linspace(0.0, 2.0, 500)
        B_arr = np.array([sol.on_axis_field(z) for z in z_arr])
        assert np.all(B_arr <= sol.config.peak_field + 1e-10)

    def test_field_array_consistent(self, sol):
        z_arr = np.linspace(0.0, 2.0, 50)
        B_arr = sol.field_array(z_arr)
        for i, z in enumerate(z_arr):
            assert B_arr[i] == pytest.approx(sol.on_axis_field(float(z)), rel=1e-9)


class TestLarmorWavenumber:
    def test_zero_outside_solenoid(self, sol):
        kappa = sol.larmor_wavenumber(10.0, beta_gamma=6.8)
        assert kappa < 1e-20

    def test_positive_inside(self, sol):
        kappa = sol.larmor_wavenumber(sol.centre, beta_gamma=6.8)
        assert kappa > 0.0

    def test_scales_with_field_squared(self, sol):
        bg = 6.8
        kappa1 = sol.larmor_wavenumber(sol.centre, bg)
        # Double the field → 4× the focusing
        sol2 = Solenoid(SolenoidConfig(
            position=sol.config.position,
            length=sol.config.length,
            bore_radius=sol.config.bore_radius,
            peak_field=2.0 * sol.config.peak_field,
        ))
        kappa2 = sol2.larmor_wavenumber(sol2.centre, bg)
        assert kappa2 == pytest.approx(4.0 * kappa1, rel=0.01)


class TestFocalLength:
    def test_focal_length_positive(self, sol):
        assert sol.focal_length(beta_gamma=6.8) > 0.0

    def test_longer_solenoid_shorter_focal_length(self):
        base = SolenoidConfig(position=0.5, length=0.25, bore_radius=0.05, peak_field=0.10)
        long = SolenoidConfig(position=0.5, length=0.50, bore_radius=0.05, peak_field=0.10)
        f_short = Solenoid(base).focal_length(6.8)
        f_long  = Solenoid(long).focal_length(6.8)
        assert f_long < f_short

    def test_stronger_field_shorter_focal_length(self):
        cfg1 = SolenoidConfig(position=0.5, length=0.25, bore_radius=0.05, peak_field=0.10)
        cfg2 = SolenoidConfig(position=0.5, length=0.25, bore_radius=0.05, peak_field=0.20)
        f1 = Solenoid(cfg1).focal_length(6.8)
        f2 = Solenoid(cfg2).focal_length(6.8)
        assert f2 < f1

    def test_higher_momentum_longer_focal_length(self, sol):
        """Higher momentum → harder to focus."""
        f_low  = sol.focal_length(beta_gamma=3.0)
        f_high = sol.focal_length(beta_gamma=7.0)
        assert f_high > f_low


class TestCentre:
    def test_centre_value(self, sol):
        expected = sol.config.position + sol.config.length / 2.0
        assert sol.centre == pytest.approx(expected, rel=1e-9)
