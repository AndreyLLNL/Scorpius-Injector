"""Tests for scorpius_injector.transport – KV envelope integration."""

import pytest
import numpy as np

from scorpius_injector.beam import BeamState
from scorpius_injector.config import InjectorConfig, SolenoidConfig
from scorpius_injector.transport import BeamTransport


@pytest.fixture
def config_no_solenoids():
    cfg = InjectorConfig(
        total_length=1.0,
        n_steps=200,
        solenoids=[],
    )
    return cfg


@pytest.fixture
def initial_state():
    st = BeamState()
    st.position       = 0.1
    st.kinetic_energy = 3.0e6
    st.current        = 3000.0
    st.sigma_x        = 0.0125
    st.sigma_y        = 0.0125
    st.sigma_xp       = 0.002
    st.sigma_yp       = 0.002
    st.sigma_xxp      = 0.0
    st.sigma_yyp      = 0.0
    return st


class TestTransportReturnShape:
    def test_returns_list(self, config_no_solenoids, initial_state):
        tr = BeamTransport(config_no_solenoids)
        states = tr.transport(initial_state)
        assert isinstance(states, list)

    def test_length_equals_n_steps(self, config_no_solenoids, initial_state):
        tr = BeamTransport(config_no_solenoids)
        states = tr.transport(initial_state)
        assert len(states) == config_no_solenoids.n_steps

    def test_first_position_is_initial(self, config_no_solenoids, initial_state):
        tr = BeamTransport(config_no_solenoids)
        states = tr.transport(initial_state)
        assert states[0].position == pytest.approx(initial_state.position, rel=1e-9)

    def test_last_position_is_total_length(self, config_no_solenoids, initial_state):
        tr = BeamTransport(config_no_solenoids)
        states = tr.transport(initial_state)
        assert states[-1].position == pytest.approx(config_no_solenoids.total_length, rel=1e-6)

    def test_positions_monotonically_increasing(self, config_no_solenoids, initial_state):
        tr = BeamTransport(config_no_solenoids)
        states = tr.transport(initial_state)
        z_arr = [s.position for s in states]
        assert all(z_arr[i] < z_arr[i + 1] for i in range(len(z_arr) - 1))


class TestDriftExpansion:
    """Free drift (no solenoids, low current) → beam diverges."""

    def test_beam_grows_in_drift(self):
        cfg = InjectorConfig(total_length=2.0, n_steps=300, solenoids=[])
        # Low current → mostly emittance-driven expansion
        st = BeamState()
        st.position       = 0.0
        st.kinetic_energy = 3.0e6
        st.current        = 1.0     # nearly zero space charge
        st.sigma_x        = 0.01
        st.sigma_y        = 0.01
        st.sigma_xp       = 0.005
        st.sigma_yp       = 0.005
        tr = BeamTransport(cfg)
        states = tr.transport(st)
        assert states[-1].sigma_x > st.sigma_x

    def test_sigma_remains_positive(self, config_no_solenoids, initial_state):
        tr = BeamTransport(config_no_solenoids)
        states = tr.transport(initial_state)
        for s in states:
            assert s.sigma_x > 0.0
            assert s.sigma_y > 0.0


class TestSolenoidFocusing:
    """With a solenoid, beam should converge and then diverge (waist)."""

    def test_beam_has_waist_with_solenoid(self):
        sol = SolenoidConfig(position=0.3, length=0.25, bore_radius=0.05, peak_field=0.25)
        cfg = InjectorConfig(total_length=1.5, n_steps=500, solenoids=[sol])
        st = BeamState()
        st.position       = 0.0
        st.kinetic_energy = 3.0e6
        st.current        = 100.0
        st.sigma_x        = 0.02
        st.sigma_y        = 0.02
        st.sigma_xp       = 0.001
        st.sigma_yp       = 0.001
        tr = BeamTransport(cfg)
        states = tr.transport(st)
        sizes = [s.sigma_x for s in states]
        # The minimum beam size should be smaller than the initial size
        # (demonstrating that focusing occurs)
        assert min(sizes) < st.sigma_x


class TestEnergyAndCurrentPreserved:
    def test_kinetic_energy_constant(self, config_no_solenoids, initial_state):
        tr = BeamTransport(config_no_solenoids)
        states = tr.transport(initial_state)
        for s in states:
            assert s.kinetic_energy == pytest.approx(initial_state.kinetic_energy, rel=1e-9)

    def test_current_constant(self, config_no_solenoids, initial_state):
        tr = BeamTransport(config_no_solenoids)
        states = tr.transport(initial_state)
        for s in states:
            assert s.current == pytest.approx(initial_state.current, rel=1e-9)


class TestEmittanceConservation:
    def test_geometric_emittance_conserved_in_drift(self, config_no_solenoids, initial_state):
        """Geometric emittance must be conserved (no acceleration, no damping)."""
        tr     = BeamTransport(config_no_solenoids)
        states = tr.transport(initial_state)
        eps0   = initial_state.emittance_x
        for s in states:
            assert s.emittance_x == pytest.approx(eps0, rel=1e-6)

    def test_normalized_emittance_conserved_with_solenoid(self):
        """Emittance must also be conserved in presence of solenoid focusing."""
        sol = SolenoidConfig(position=0.3, length=0.25, bore_radius=0.05, peak_field=0.20)
        cfg = InjectorConfig(total_length=1.5, n_steps=400, solenoids=[sol])
        st  = BeamState()
        st.position       = 0.0
        st.kinetic_energy = 3.0e6
        st.current        = 100.0
        st.sigma_x        = 0.015
        st.sigma_y        = 0.015
        st.sigma_xp       = 0.003
        st.sigma_yp       = 0.003
        st.sigma_xxp      = 0.0
        st.sigma_yyp      = 0.0
        tr     = BeamTransport(cfg)
        states = tr.transport(st)
        eps0   = st.emittance_x
        for s in states:
            assert s.emittance_x == pytest.approx(eps0, rel=1e-5)
