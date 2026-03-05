"""Tests for scorpius_injector.diagnostics – virtual instruments."""

import pytest
import numpy as np

from scorpius_injector.beam import BeamState
from scorpius_injector.config import DiagnosticConfig
from scorpius_injector.diagnostics import (
    BeamPositionMonitor,
    CurrentTransformer,
    FaradayCup,
    OpticalTransitionRadiationScreen,
    make_diagnostic,
)


@pytest.fixture
def beam():
    st = BeamState()
    st.position       = 1.0
    st.kinetic_energy = 3.0e6
    st.current        = 3000.0
    st.sigma_x        = 0.01
    st.sigma_y        = 0.010
    st.sigma_xp       = 0.005
    st.sigma_yp       = 0.005
    st.x_centroid     = 0.001
    st.y_centroid     = -0.001
    return st


@pytest.fixture
def rng():
    return np.random.default_rng(0)


class TestCurrentTransformer:
    def test_returns_dict(self, beam, rng):
        cfg  = DiagnosticConfig(position=0.5, device_type="FCT", name="FCT1")
        fct  = CurrentTransformer(cfg, rng=rng)
        meas = fct.measure(beam)
        assert isinstance(meas, dict)

    def test_required_keys(self, beam, rng):
        cfg  = DiagnosticConfig(position=0.5, device_type="FCT", name="FCT1")
        fct  = CurrentTransformer(cfg, rng=rng)
        meas = fct.measure(beam)
        for k in ("name", "device_type", "position", "current_A"):
            assert k in meas

    def test_current_close_to_beam_current(self, beam, rng):
        cfg  = DiagnosticConfig(position=0.5, device_type="FCT", name="FCT1")
        fct  = CurrentTransformer(cfg, noise_fraction=0.0, rng=rng)
        meas = fct.measure(beam)
        assert meas["current_A"] == pytest.approx(beam.current, rel=1e-9)


class TestBeamPositionMonitor:
    def test_returns_dict(self, beam, rng):
        cfg = DiagnosticConfig(position=0.5, device_type="BPM", name="BPM1")
        bpm = BeamPositionMonitor(cfg, rng=rng)
        assert isinstance(bpm.measure(beam), dict)

    def test_required_keys(self, beam, rng):
        cfg = DiagnosticConfig(position=0.5, device_type="BPM", name="BPM1")
        bpm = BeamPositionMonitor(cfg, rng=rng)
        meas = bpm.measure(beam)
        for k in ("name", "device_type", "position", "x_m", "y_m"):
            assert k in meas

    def test_zero_noise_returns_centroid(self, beam, rng):
        cfg = DiagnosticConfig(position=0.5, device_type="BPM", name="BPM1")
        bpm = BeamPositionMonitor(cfg, position_resolution=0.0, rng=rng)
        meas = bpm.measure(beam)
        assert meas["x_m"] == pytest.approx(beam.x_centroid, abs=1e-15)
        assert meas["y_m"] == pytest.approx(beam.y_centroid, abs=1e-15)


class TestOTRScreen:
    def test_returns_dict(self, beam, rng):
        cfg = DiagnosticConfig(position=1.5, device_type="OTR", name="OTR1")
        otr = OpticalTransitionRadiationScreen(cfg, n_pixels=32, rng=rng)
        assert isinstance(otr.measure(beam), dict)

    def test_image_shape(self, beam, rng):
        cfg = DiagnosticConfig(position=1.5, device_type="OTR", name="OTR1")
        otr = OpticalTransitionRadiationScreen(cfg, n_pixels=32, rng=rng)
        meas = otr.measure(beam)
        assert meas["image"].shape == (32, 32)

    def test_image_normalised(self, beam, rng):
        cfg = DiagnosticConfig(position=1.5, device_type="OTR", name="OTR1")
        otr = OpticalTransitionRadiationScreen(cfg, n_pixels=64, noise_fraction=0.0, rng=rng)
        meas = otr.measure(beam)
        assert meas["image"].max() == pytest.approx(1.0, rel=1e-6)

    def test_sigma_reported(self, beam, rng):
        cfg = DiagnosticConfig(position=1.5, device_type="OTR", name="OTR1")
        otr = OpticalTransitionRadiationScreen(cfg, n_pixels=64, noise_fraction=0.0, rng=rng)
        meas = otr.measure(beam)
        assert meas["sigma_x_m"] == pytest.approx(beam.sigma_x, rel=1e-9)
        assert meas["sigma_y_m"] == pytest.approx(beam.sigma_y, rel=1e-9)


class TestFaradayCup:
    def test_returns_dict(self, beam, rng):
        cfg = DiagnosticConfig(position=2.9, device_type="FC", name="FC1")
        fc  = FaradayCup(cfg, rng=rng)
        assert isinstance(fc.measure(beam), dict)

    def test_required_keys(self, beam, rng):
        cfg = DiagnosticConfig(position=2.9, device_type="FC", name="FC1")
        fc  = FaradayCup(cfg, rng=rng)
        meas = fc.measure(beam)
        for k in ("name", "device_type", "position", "current_A", "kinetic_energy_eV"):
            assert k in meas


class TestMakeDiagnostic:
    @pytest.mark.parametrize("device_type,expected_cls", [
        ("FCT", CurrentTransformer),
        ("BPM", BeamPositionMonitor),
        ("OTR", OpticalTransitionRadiationScreen),
        ("FC",  FaradayCup),
    ])
    def test_returns_correct_type(self, device_type, expected_cls, rng):
        cfg = DiagnosticConfig(position=1.0, device_type=device_type, name="D")
        d = make_diagnostic(cfg, rng=rng)
        assert isinstance(d, expected_cls)

    def test_unknown_type_raises(self):
        cfg = DiagnosticConfig(position=1.0, device_type="UNKNOWN", name="D")
        with pytest.raises(ValueError, match="Unknown diagnostic"):
            make_diagnostic(cfg)
