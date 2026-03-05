"""
Configuration dataclasses for every subsystem of the E-Beam Injector.

Each dataclass carries the physical and operational parameters that define
a particular hardware component or operational scenario.  The factory method
``InjectorConfig.default_scorpius()`` returns a fully-populated configuration
representative of a Scorpius-class Linear Inductive Accelerator injector.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import List


@dataclass
class CathodeConfig:
    """Configuration for the electron-gun cathode.

    Attributes
    ----------
    radius :
        Emission-surface radius (m).
    work_function :
        Cathode work function (eV); used by the Richardson-Dushman model.
    temperature :
        Operating temperature (K).
    emission_type :
        ``"thermionic"`` or ``"field"``; determines which emission model is
        the primary limit.
    """

    radius: float = 0.025
    work_function: float = 2.0
    temperature: float = 1400.0
    emission_type: str = "thermionic"


@dataclass
class DiodeConfig:
    """Configuration for the accelerating diode (cathode-anode gap).

    Attributes
    ----------
    voltage :
        Applied accelerating voltage (V).
    gap_spacing :
        Cathode-to-anode gap distance (m).
    anode_radius :
        Radius of the anode aperture (m).
    """

    voltage: float = 3.0e6
    gap_spacing: float = 0.10
    anode_radius: float = 0.045


@dataclass
class PulseConfig:
    """Configuration for the voltage/current pulse waveform.

    The pulse is modelled as a trapezoidal shape with a cosine-smoothed
    rise and fall.

    Attributes
    ----------
    pulse_duration :
        Total pulse length from start to end (s).
    rise_time :
        Time from 0 % to 100 % amplitude (s).
    fall_time :
        Time from 100 % to 0 % amplitude (s).
    flat_top_voltage :
        Peak (flat-top) voltage (V).
    repetition_rate :
        Shot repetition rate (Hz).
    """

    pulse_duration: float = 100e-9
    rise_time: float = 15e-9
    fall_time: float = 15e-9
    flat_top_voltage: float = 3.0e6
    repetition_rate: float = 1.0


@dataclass
class SolenoidConfig:
    """Configuration for a single focusing solenoid.

    Attributes
    ----------
    position :
        Axial position of the solenoid entrance (m).
    length :
        Physical length of the solenoid (m).
    bore_radius :
        Inner bore radius (m).
    peak_field :
        Peak on-axis magnetic field (T).
    name :
        Human-readable label used in output and plots.
    """

    position: float = 0.0
    length: float = 0.25
    bore_radius: float = 0.05
    peak_field: float = 0.10
    name: str = "SOL"


@dataclass
class DiagnosticConfig:
    """Configuration for a single virtual diagnostic device.

    Attributes
    ----------
    position :
        Axial position of the diagnostic (m).
    device_type :
        One of ``"FCT"``, ``"BPM"``, ``"OTR"``, ``"FC"``.
    name :
        Human-readable label.
    """

    position: float = 0.0
    device_type: str = "BPM"
    name: str = "DIAG"


@dataclass
class InjectorConfig:
    """Master configuration for the complete E-Beam Injector.

    Attributes
    ----------
    name :
        Descriptive name for this configuration.
    total_length :
        Total modelled beamline length (m).
    n_steps :
        Number of longitudinal integration steps for the transport solver.
    cathode :
        Cathode subsystem parameters.
    diode :
        Diode subsystem parameters.
    pulse :
        Voltage-pulse waveform parameters.
    solenoids :
        Ordered list of focusing solenoids along the beamline.
    diagnostics :
        Ordered list of virtual diagnostic stations.
    """

    name: str = "Scorpius Injector"
    total_length: float = 3.0
    n_steps: int = 1000
    cathode: CathodeConfig = field(default_factory=CathodeConfig)
    diode: DiodeConfig = field(default_factory=DiodeConfig)
    pulse: PulseConfig = field(default_factory=PulseConfig)
    solenoids: List[SolenoidConfig] = field(default_factory=list)
    diagnostics: List[DiagnosticConfig] = field(default_factory=list)

    @classmethod
    def default_scorpius(cls) -> "InjectorConfig":
        """Return a default Scorpius-class injector configuration.

        The layout mirrors the typical structure of a Linear Inductive
        Accelerator injector:  a thermionic Pierce gun followed by a series
        of transport solenoids and inline diagnostics over ~3 m of beamline.
        """
        cfg = cls()

        cfg.solenoids = [
            SolenoidConfig(position=0.20, peak_field=0.18, name="SOL1"),
            SolenoidConfig(position=0.65, peak_field=0.14, name="SOL2"),
            SolenoidConfig(position=1.10, peak_field=0.11, name="SOL3"),
            SolenoidConfig(position=1.55, peak_field=0.10, name="SOL4"),
            SolenoidConfig(position=2.00, peak_field=0.10, name="SOL5"),
            SolenoidConfig(position=2.45, peak_field=0.10, name="SOL6"),
        ]

        cfg.diagnostics = [
            DiagnosticConfig(position=0.10, device_type="FCT", name="FCT1"),
            DiagnosticConfig(position=0.45, device_type="BPM", name="BPM1"),
            DiagnosticConfig(position=0.90, device_type="BPM", name="BPM2"),
            DiagnosticConfig(position=1.35, device_type="OTR", name="OTR1"),
            DiagnosticConfig(position=1.80, device_type="BPM", name="BPM3"),
            DiagnosticConfig(position=2.25, device_type="OTR", name="OTR2"),
            DiagnosticConfig(position=2.70, device_type="BPM", name="BPM4"),
            DiagnosticConfig(position=2.95, device_type="FC",  name="FC1"),
        ]

        return cfg
