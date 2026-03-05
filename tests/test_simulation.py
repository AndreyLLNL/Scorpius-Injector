"""Tests for scorpius_injector.simulation – end-to-end simulation."""

import pytest
import numpy as np

from scorpius_injector import InjectorSimulation, SimulationResult, InjectorConfig
from scorpius_injector.config import DiodeConfig


class TestDefaultSimulationRuns:
    def test_run_returns_result(self):
        sim = InjectorSimulation()
        result = sim.run()
        assert isinstance(result, SimulationResult)

    def test_beam_states_not_empty(self):
        sim = InjectorSimulation()
        result = sim.run()
        assert len(result.beam_states) > 0

    def test_measurements_count_equals_diagnostics(self):
        sim = InjectorSimulation()
        result = sim.run()
        assert len(result.measurements) == len(sim.config.diagnostics)


class TestSummary:
    def test_summary_returns_dict(self):
        sim    = InjectorSimulation()
        result = sim.run()
        s      = result.summary()
        assert isinstance(s, dict)

    def test_summary_energy_matches_voltage(self):
        sim    = InjectorSimulation()
        result = sim.run()
        s      = result.summary()
        expected_MeV = sim.config.diode.voltage * 1e-6
        assert s["beam_energy_MeV"] == pytest.approx(expected_MeV, rel=1e-6)

    def test_summary_current_positive(self):
        sim    = InjectorSimulation()
        result = sim.run()
        assert result.summary()["beam_current_kA"] > 0.0

    def test_summary_sigma_positive(self):
        result = InjectorSimulation().run()
        s = result.summary()
        assert s["final_sigma_x_mm"] > 0.0
        assert s["final_sigma_y_mm"] > 0.0


class TestEnvelopeArrays:
    def test_keys_present(self):
        result = InjectorSimulation().run()
        arrs = result.envelope_arrays()
        for k in ("z", "sigma_x", "sigma_y", "eps_nx", "eps_ny"):
            assert k in arrs

    def test_z_array_length(self):
        sim    = InjectorSimulation()
        result = sim.run()
        arrs   = result.envelope_arrays()
        assert len(arrs["z"]) == sim.config.n_steps

    def test_sigma_non_negative(self):
        result = InjectorSimulation().run()
        arrs   = result.envelope_arrays()
        assert np.all(arrs["sigma_x"] >= 0.0)
        assert np.all(arrs["sigma_y"] >= 0.0)


class TestReproducibility:
    def test_same_seed_same_result(self):
        s1 = InjectorSimulation(rng_seed=7).run()
        s2 = InjectorSimulation(rng_seed=7).run()
        assert s1.summary()["final_sigma_x_mm"] == pytest.approx(
            s2.summary()["final_sigma_x_mm"], rel=1e-9
        )


class TestCustomConfig:
    def test_lower_voltage_lower_energy(self):
        cfg_lo = InjectorConfig.default_scorpius()
        cfg_lo.diode.voltage = 2.0e6
        cfg_hi = InjectorConfig.default_scorpius()
        cfg_hi.diode.voltage = 3.0e6

        s_lo = InjectorSimulation(cfg_lo).run().summary()
        s_hi = InjectorSimulation(cfg_hi).run().summary()

        assert s_lo["beam_energy_MeV"] < s_hi["beam_energy_MeV"]

    def test_no_solenoids_beam_diverges(self):
        """Without focusing, the beam should grow larger."""
        cfg_with = InjectorConfig.default_scorpius()
        cfg_none = InjectorConfig.default_scorpius()
        cfg_none.solenoids = []

        r_with = InjectorSimulation(cfg_with, rng_seed=0).run()
        r_none = InjectorSimulation(cfg_none, rng_seed=0).run()

        sz_with = r_with.summary()["final_sigma_x_mm"]
        sz_none = r_none.summary()["final_sigma_x_mm"]

        assert sz_none > sz_with


class TestMeasurementTypes:
    def test_all_device_types_present(self):
        sim    = InjectorSimulation()
        result = sim.run()
        types  = {m["device_type"] for m in result.measurements}
        assert "FCT" in types
        assert "BPM" in types
        assert "OTR" in types
        assert "FC"  in types
