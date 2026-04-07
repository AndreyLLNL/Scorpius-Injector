%% Pierce_Gun_PIC_V3_MP.m
%% Multi-Pulse extension of V3 — created 2026-04-06
%% Based on Pierce_Gun_PIC_v8_Integrated_SC_Extended_V3_04012026.m
%% Adds support for 1, 2, 3, or 4 pulse operation modes
%% All V3 fixes retained:
%%   [FIX-11] Single position update, all crossing detection inside push block
%%   [FIX-10] particle_KE recorded at crossing, exited particles removed immediately
%%   gamma_particles updated inside push block

clear all; close all; clc;

fprintf('\n=== Pierce_Gun_PIC_v8_Integrated_SC_Extended_V3_04012026_MP.m ===\n');
%fprintf('Multi-pulse mode, PRODUCTION, SC enabled\n\n');

%% ==================== MASTER SWITCHES ====================
simulation_mode      = 'PRODUCTION';
ENABLE_SPACE_CHARGE  = true;
ENABLE_MULTIPULSE           = true;   % Master: true = multi-pulse, false = single-pulse
%ENABLE_INTERPULSE_SNAPSHOT  = true;   % Inter-pulse electron cloud capture
ENABLE_BETATRON_AVERAGING   = true;
ENABLE_GAS_SCATTERING       = true;
ENABLE_ION_ACCUMULATION     = true;
ENABLE_SNAPSHOTS            = true;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== MULTI-PULSE COUNT CONTROL ====================
%% Set n_pulses_config to 1, 2, 3, or 4 to select operating mode
n_pulses_config = 2;   % OPTIONS: 1 | 2 | 3 | 4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ENABLE_MULTIPULSE == true
    fprintf('  PIERCE GUN PIC V3  MULTI-PULSE (n=%d), SC ENABLED\n', n_pulses_config);
    ENABLE_INTERPULSE_SNAPSHOT  = true;   % Inter-pulse electron cloud capture
else
    fprintf('  PIERCE GUN PIC V3  SINGLE PULSE, SC ENABLED\n');
    ENABLE_INTERPULSE_SNAPSHOT  = false;   % Inter-pulse electron cloud capture
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== DIAGNOSTIC TRACKING VARIABLES ====================
step_history      = [];
wall_loss_history = [];
fprintf('Diagnostic tracking initialized.\n');

%% ==================== SOLENOID FIELD STRENGTHS ====================
solenoid1_field  = -0.0450;
solenoid2_field  =  0.0185;
solenoid3_field  =  0.0070;
solenoid4_field  =  0.0050;
solenoid5_field  =  0.0020;
solenoid7_field  =  0.0015;
solenoid8_field  =  0.0013;
solenoid9_field  =  0.0012;
solenoid10_field =  0.0012;
solenoid11_field =  0.0012;
solenoid12_field =  0.0012;
solenoid14_field =  0.0012;
solenoid15_field =  0.0012;
solenoid16_field =  0.0012;
solenoid17_field =  0.0012;
solenoid18_field =  0.0012;
solenoid19_field =  0.0012;
solenoid20_field =  0.0012;
solenoid21_field =  0.0012;
solenoid22_field =  0.0012;
solenoid23_field =  0.0012;
solenoid24_field =  0.0012;
solenoid25_field =  0.0012;
solenoid26_field =  0.0012;
solenoid27_field =  0.0012;
solenoid28_field =  0.0012;
solenoid29_field =  0.0012;
solenoid30_field =  0.0012;
solenoid31_field =  0.0012;
solenoid32_field =  0.0012;
solenoid33_field =  0.0012;
solenoid34_field =  0.0012;
solenoid35_field =  0.0012;
solenoid36_field =  0.0012;
solenoid38_field =  0.0012;
solenoid39_field =  0.0012;
solenoid40_field =  0.0012;
solenoid41_field =  0.0015;
solenoid42_field =  0.0015;
solenoid43_field =  0.0015;
solenoid45_field =  0.0015;
solenoid46_field =  0.0015;
solenoid47_field =  0.0020;
solenoid48_field =  0.0035;
solenoid49_field =  0.0075;

%% ==================== SNAPSHOT TIMING ====================
TWISS_PULSE1_TIME = 205e-9;
TWISS_PULSE2_TIME = 405e-9;

if ENABLE_MULTIPULSE == true
    SNAPSHOT_P1_TIMES = [195e-9,200e-9,205e-9,210e-9,215e-9,220e-9,225e-9];
    SNAPSHOT_P2_TIMES = [395e-9,400e-9,405e-9,410e-9,415e-9,420e-9,425e-9];
    SNAPSHOT_P3_TIMES = [570e-9,575e-9,580e-9,585e-9,590e-9,595e-9,600e-9];
    SNAPSHOT_P4_TIMES = [770e-9,775e-9,780e-9,785e-9,790e-9,795e-9,800e-9];
    N_SNAPSHOTS       = 7;
    N_SNAPSHOTS_EARLY = N_SNAPSHOTS;
    N_SNAPSHOTS_LATE  = N_SNAPSHOTS;
    SNAPSHOT_EARLY_TIMES = [190e-9,195e-9,200e-9,205e-9,210e-9,215e-9,220e-9];
    SNAPSHOT_LATE_TIMES  = [220e-9,225e-9,230e-9,235e-9,240e-9,245e-9,250e-9];
    fprintf('=== BETATRON AVERAGING MODE (MULTI-PULSE) ===\n');
    fprintf('Snapshots per pulse: %d\n', N_SNAPSHOTS);
    fprintf('Temporal spacing: %.1f ns\n', (SNAPSHOT_P1_TIMES(2)-SNAPSHOT_P1_TIMES(1))*1e9);
else
    SNAPSHOT_EARLY_TIMES = [190e-9,193e-9,196e-9,199e-9,202e-9, ...
                            205e-9,208e-9,211e-9,214e-9,217e-9,220e-9];
    SNAPSHOT_LATE_TIMES  = [220e-9,223e-9,226e-9,229e-9,232e-9, ...
                            235e-9,238e-9,241e-9,244e-9,247e-9,250e-9];
    SNAPSHOT_P1_TIMES    = [205e-9,208e-9,211e-9,214e-9,217e-9, ...
                            220e-9,223e-9,226e-9,229e-9,232e-9,235e-9];
    N_SNAPSHOTS       = 11;
    N_SNAPSHOTS_EARLY = length(SNAPSHOT_EARLY_TIMES);
    N_SNAPSHOTS_LATE  = length(SNAPSHOT_LATE_TIMES);
    fprintf('=== INTRA-PULSE ION FOCUSING MODE ===\n');
    fprintf('Early snapshots: %d  (t=%.0f-%.0f ns)\n', ...
            N_SNAPSHOTS_EARLY, SNAPSHOT_EARLY_TIMES(1)*1e9, SNAPSHOT_EARLY_TIMES(end)*1e9);
    fprintf('Late  snapshots: %d  (t=%.0f-%.0f ns)\n', ...
            N_SNAPSHOTS_LATE, SNAPSHOT_LATE_TIMES(1)*1e9, SNAPSHOT_LATE_TIMES(end)*1e9);
end

%% ==================== LOAD RESOURCES ====================
fprintf('\n================================================================\n');
fprintf('  PIERCE GUN PIC V3 — SINGLE PULSE, SC ENABLED\n');
fprintf('================================================================\n\n');

if ~exist('pierce_gun_lego_theta68_gap0_recess0.mat','file')
    error('Geometry file not found.');
end
if ~exist('pierce_gun_field_solution_ready.mat','file')
    error('Field solution not found.');
end

fprintf('Loading resources...\n');
load('pierce_gun_lego_theta68_gap0_recess0.mat');
load('pierce_gun_field_solution_ready.mat');
fprintf('  Geometry loaded (mesh: %dx%d)\n', nz, nr);
fprintf('  Fields loaded   (max E: %.1f MV/m)\n', max(abs(Ez_capped(:)))/1e6);

%% ==================== VOLTAGE BOUNDARY CHECK ====================
fprintf('\n=== Voltage boundary conditions ===\n');
fprintf('  V_cathode    = %.0f V  (%.0f kV)\n', V_cathode, V_cathode/1e3);
fprintf('  V_anode      = %.0f V  (%.0f kV)\n', V_anode,   V_anode/1e3);
fprintf('  V_total      = %.0f V  (%.0f kV)\n', ...
        V_anode-V_cathode, (V_anode-V_cathode)/1e3);
fprintf('  gap_distance = %.1f mm\n', gap_distance*1000);
fprintf('  E_analytical = %.3f MV/m\n', ...
        abs(V_anode-V_cathode)/gap_distance/1e6);
fprintf('  Expected: V_cathode=-850000, V_anode=+850000, V_total=1700000\n');

%% ==================== CATHODE FIELD DIAGNOSTIC ====================
fprintf('\n=== Cathode Field Analysis ===\n');
iz_cath_search = find(z >= 0 & z <= 0.010);
if ~isempty(iz_cath_search)
    Ez_cath_profile = abs(Ez_capped(1, iz_cath_search));
    [E_peak_cath, peak_idx] = max(Ez_cath_profile);
    z_peak_cath = z(iz_cath_search(peak_idx));
    fprintf('  Peak cathode field : %.2f MV/m at z=%.1f mm\n', ...
            E_peak_cath/1e6, z_peak_cath*1000);
    fprintf('  Analytical gap field: %.2f MV/m\n', ...
            abs(V_anode-V_cathode)/gap_distance/1e6);
    E_CATHODE_BASE_DETECTED = E_peak_cath;
else
    E_CATHODE_BASE_DETECTED = 5.37e6;
    fprintf('  WARNING: cathode region not found — using fallback %.2f MV/m\n', ...
            E_CATHODE_BASE_DETECTED/1e6);
end

%% ==================== FIELD ARRAY DIAGNOSTICS ====================
fprintf('\n=== Field Array Diagnostics ===\n');
fprintf('  z: %.1f to %.1f mm  (%d pts)\n', z(1)*1000, z(end)*1000, length(z));
fprintf('  r: %.1f to %.1f mm  (%d pts)\n', r(1)*1000, r(end)*1000, length(r));
fprintf('  Ez_capped: %dx%d\n', size(Ez_capped,1), size(Ez_capped,2));
fprintf('  Er_capped: %dx%d\n', size(Er_capped,1), size(Er_capped,2));

Ez_axis = Ez_capped(1,:);
for zc = [250,350,500,1000,2000,4000,8000]
    [~,iz] = min(abs(z*1000 - zc));
    fprintf('  Ez at z=%4d mm: %+.3e V/m\n', zc, Ez_axis(iz));
end

%% On-axis potential integral (field normalization check)
iz0 = find(z >= 0.0,   1,'first');
izD = find(z >= 0.500, 1,'first');
V_integral = -trapz(z(iz0:izD), Ez_capped(1,iz0:izD));
fprintf('  Potential rise z=0→500mm: %+.4f MV  (expected +1.694 MV)\n', ...
        V_integral/1e6);

%% ==================== PHYSICAL CONSTANTS ====================
c        = 299792458;
e_charge = 1.602176634e-19;
m_e      = 9.10938356e-31;
eps0     = 8.854187817e-12;
k_B      = 1.380649e-23;

%% ==================== MODE CONFIGURATION ====================
switch simulation_mode
    case 'QUICK_TEST'
        dt             = 10e-12;
        base_particles = 20;
        base_weight    = 5e9;
        sc_interval    = 50;
        diag_interval  = 500;
    case 'OPTIMIZATION'
        dt             = 10e-12;
        base_particles = 50;
        base_weight    = 7e8;
        sc_interval    = 25;
        diag_interval  = 100;
    case 'PRODUCTION'
        dt             = 10e-12;
        base_particles = 100;
        base_weight    = 1e9;
        sc_interval    = 50;
        diag_interval  = 100;
end
fprintf('\nMode: %s  |  dt=%.0f ps  |  %d particles/step  |  weight=%.1e\n', ...
        simulation_mode, dt*1e12, base_particles, base_weight);

%% ==================== SIMULATION TIME REFERENCE (t_flight pre-computation) ====================
E_beam_ref    = 1.70e6;
gamma_ref     = 1 + E_beam_ref / (m_e*c^2/e_charge);
beta_ref      = sqrt(1 - 1/gamma_ref^2);
v_ref         = beta_ref * c;
t_flight      = 8.305 / v_ref;

%% ==================== PULSE CONFIGURATION ====================
if ENABLE_MULTIPULSE == true

    pulse_config             = struct();
    pulse_config.n_pulses    = n_pulses_config;

    %% Pulse start times — automatically sized to n_pulses_config
    all_pulse_starts = [150e-9, 350e-9, 550e-9, 750e-9];
    pulse_config.pulse_starts = all_pulse_starts(1:pulse_config.n_pulses);

    pulse_config.rise_time   = 15e-9;
    pulse_config.flat_time   = 80e-9;
    pulse_config.fall_time   = 25e-9;

    %% Inter-pulse snapshot configuration
    ENABLE_INTERPULSE_SNAPSHOT  = true;
    all_interpulse_times = [349e-9, 549e-9, 749e-9];
    n_interpulse_snapshots      = pulse_config.n_pulses - 1;
    INTERPULSE_SNAPSHOT_TIMES   = all_interpulse_times(1:n_interpulse_snapshots);
    interpulse_clouds           = cell(n_interpulse_snapshots, 1);
    interpulse_capture_count    = 0;

    %% Timing window
    last_pulse_end = pulse_config.pulse_starts(end) + ...
                     pulse_config.rise_time + pulse_config.flat_time + pulse_config.fall_time;
    t_start        = pulse_config.pulse_starts(1) - 1e-9;
    margin_time    = 40e-9;
    t_end          = last_pulse_end + t_flight + margin_time;
    t_plot_min     = 145;
    t_plot_max     = t_end * 1e9;

    pulse_shape = @(t_curr) pulse_shape_multipulse(t_curr, pulse_config);

    fprintf('\n=== MULTI-PULSE MODE (n=%d) ===\n', pulse_config.n_pulses);
    fprintf('  Pulse starts: ');
    fprintf('%.0f ns  ', pulse_config.pulse_starts*1e9);
    fprintf('\n');
    fprintf('  Last pulse ends:   %.1f ns\n', last_pulse_end*1e9);
    fprintf('  Flight time:       %.1f ns  (beta=%.4f)\n', t_flight*1e9, beta_ref);
    fprintf('  Simulation end:    %.1f ns\n', t_end*1e9);

else

    pulse_config              = struct();
    pulse_config.n_pulses     = 1;
    pulse_config.pulse_starts = 150e-9;
    pulse_config.rise_time    = 15e-9;
    pulse_config.flat_time    = 80e-9;
    pulse_config.fall_time    = 25e-9;

    n_interpulse_snapshots    = 0;
    interpulse_clouds         = cell(0,1);
    interpulse_capture_count  = 0;

    pulse_end  = pulse_config.pulse_starts + pulse_config.rise_time + ...
                 pulse_config.flat_time    + pulse_config.fall_time;
    t_start    = pulse_config.pulse_starts - 1e-9;
    margin_time = 40e-9;
    t_end       = pulse_end + t_flight + margin_time;
    t_plot_min  = 149;
    t_plot_max  = t_end * 1e9;

    pulse_shape = @(t_curr) pulse_shape_func(t_curr, ...
                      pulse_config.pulse_starts, ...
                      pulse_config.rise_time, ...
                      pulse_config.flat_time, ...
                      pulse_config.fall_time);

    fprintf('\n=== SINGLE PULSE MODE ===\n');
    fprintf('  Pulse ends:      %.1f ns\n', pulse_end*1e9);
    fprintf('  Simulation end:  %.1f ns\n', t_end*1e9);

end

fprintf('\n=== Timing Summary ===\n');
fprintf('  t_start: %.1f ns\n', t_start*1e9);
fprintf('  t_end:   %.1f ns\n', t_end*1e9);

t  = t_start : dt : t_end;
nt = length(t);
fprintf('  Time steps: %d  (dt=%.0f ps)\n', nt, dt*1e12);

%t_plot_min = t_plot_min;  %% already set above
%t_plot_max = t_plot_max;  %% already set above

%% ==================== SPACE CHARGE SETUP ====================
if ENABLE_SPACE_CHARGE
    sc_nz    = 1500;
    sc_nr    = 100;
    sc_z_min = -0.05;
    sc_z_max =  8.31;
    sc_r_max =  0.080;

    sc_z  = linspace(sc_z_min, sc_z_max, sc_nz);
    sc_r  = linspace(0,        sc_r_max, sc_nr);
    sc_dz = sc_z(2) - sc_z(1);
    sc_dr = sc_r(2) - sc_r(1);

    rho_grid = zeros(sc_nr, sc_nz);
    phi_grid = zeros(sc_nr, sc_nz);
    Ez_sc    = zeros(sc_nr, sc_nz);
    Er_sc    = zeros(sc_nr, sc_nz);

    sc_omega      = 1.2; % was 1.2 used before
    sc_iterations = 100; % was 100 applied before

    fprintf('\nSC grid: %dx%d  dz=%.1f mm  dr=%.2f mm\n', ...
            sc_nz, sc_nr, sc_dz*1000, sc_dr*1000);

    %% Meshgrids for applied-field interpolation
    [Z_grid, R_grid] = meshgrid(z, r);
    fprintf('Applied-field meshgrid: %dx%d\n', size(Z_grid,1), size(Z_grid,2));
else
    fprintf('\nSpace charge DISABLED\n');
    %% Still need Z_grid / R_grid for applied-field interpolation
    [Z_grid, R_grid] = meshgrid(z, r);
end
%%%%%%%%%%%%%%%%%%%%%%%% Added 03.30.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== FIELD INTERPOLATION PRE-COMPUTATION ====================
%% Step 1 — Add to Block 1 (once, after [Z_grid, R_grid] = meshgrid(z, r))
%% Replaces interp2 with direct index arithmetic — computed once at startup
app_nz = length(z);
app_nr = length(r);
app_dz = z(2) - z(1);
app_dr = r(2) - r(1);
app_z0 = z(1);
app_r0 = r(1);
fprintf('Field interp pre-computed: nz=%d  nr=%d  dz=%.4f mm  dr=%.4f mm\n', ...
        app_nz, app_nr, app_dz*1000, app_dr*1000);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== GAS SCATTERING ====================
if ENABLE_GAS_SCATTERING
    gas_params = struct();
    gas_params.P          = 1e-7 * 133.322;
    gas_params.T          = 300;
    gas_params.n_gas      = gas_params.P / (k_B * gas_params.T);
    sigma_N2              = 2.0e-20;
    sigma_O2              = 2.2e-20;
    gas_params.sigma_elastic = 0.78*sigma_N2 + 0.21*sigma_O2;
    gas_params.lambda_mfp = 1 / (gas_params.n_gas * gas_params.sigma_elastic);

    scatter_cal = struct();
    scatter_cal.strength_factor = 1.0;
    scatter_cal.rare_fraction   = 0.01;
    scatter_cal.theta_rare_max  = 10e-3;
    scatter_cal.check_interval  = 10;

    scatter_diag = struct();
    scatter_diag.event_count = 0;
    scatter_diag.rare_count  = 0;
    scatter_diag.theta_history        = [];
    scatter_diag.z_scatter_positions  = [];

    SCATTERING_METHOD = 'HYBRID';
    fprintf('\nGas scattering: %s  P=%.1e mbar  λ=%.1f km\n', ...
            SCATTERING_METHOD, gas_params.P/133.322, gas_params.lambda_mfp/1000);
end

%% ==================== ION ACCUMULATION ====================
if ENABLE_ION_ACCUMULATION && ENABLE_SPACE_CHARGE
    ion_physics = struct();
    ion_physics.sigma_ionization    = 3.5e-21;
    ion_physics.mass_ion_avg        = 29 * 1.66054e-27;
    ion_physics.charge_ion          = e_charge;
    ion_physics.mobility            = 2.5e-4;
    ion_physics.t_recomb_effective  = 10e-6;
    ion_physics.superparticle_weight = 1000;

    ion_density_grid     = zeros(sc_nr, sc_nz);
    ion_density_by_pulse = zeros(sc_nr, sc_nz, pulse_config.n_pulses);
    ion_vz_grid          = zeros(sc_nr, sc_nz);

    ion_diag = struct();
    ion_diag.creation_history      = zeros(nt, 1);
    ion_diag.total_ions_vs_time    = zeros(nt, 1);
    ion_diag.peak_density_vs_time  = zeros(nt, 1);
    ion_diag.ions_per_pulse        = zeros(pulse_config.n_pulses, 1);

    fprintf('Ion accumulation enabled  (weight=%d ions/super-particle)\n', ...
            ion_physics.superparticle_weight);
end

%% ==================== PARTICLE POOL ====================
length_factor = 8.305 / 2.760;
base_single   = 1.05e6;

if ENABLE_MULTIPULSE == true
    expected_parts = base_single * length_factor * pulse_config.n_pulses;
    safety_factor  = 1.25;
else
    expected_parts = base_single * length_factor;
    safety_factor  = 1.15;
end

max_particles = ceil(expected_parts * safety_factor);

fprintf('\nParticle pool: %.2e  (safety=%.2f  pulses=%d  %.1f MB)\n', ...
        max_particles, safety_factor, pulse_config.n_pulses, ...
        max_particles*8*10/1024^2);

if max_particles > 20e6
    fprintf('  WARNING: Very large particle pool (>20M). Consider reducing base_particles.\n');
end

z_particles       = NaN(max_particles, 1);
r_particles       = NaN(max_particles, 1);
pz_particles      = zeros(max_particles, 1);
pr_particles      = zeros(max_particles, 1);
ptheta_particles  = zeros(max_particles, 1);
weight_particles  = zeros(max_particles, 1);
gamma_particles   = ones(max_particles,  1);
active_particles  = false(max_particles, 1);

%% ==================== COUNTERS ====================
n_active                  = 0;
n_created                 = 0;
particles_at_anode        = 0;
particles_transmitted     = 0;
particles_lost_to_cathode = 0;
particles_lost_to_walls   = 0;
particles_out_of_bounds   = 0;

%% ==================== PARTICLE TRACKING ARRAYS ====================
particle_crossed_anode   = false(max_particles, 1);
particle_crossed_exit    = false(max_particles, 1);
particle_t_at_anode      = NaN(max_particles, 1);
particle_t_at_exit       = NaN(max_particles, 1);
particle_KE_at_anode     = zeros(max_particles, 1);   % eV
particle_KE_at_exit      = zeros(max_particles, 1);   % eV
particle_r_at_anode      = NaN(max_particles, 1);
particle_counted_as_return     = false(max_particles, 1);
particle_counted_as_violation  = false(max_particles, 1);

%% ==================== CURRENT ACCUMULATORS ====================
I_anode_accumulator = 0;
I_exit_accumulator  = 0;
I_anode_count       = 0;
I_exit_count        = 0;

%% ==================== MONITOR POSITIONS ====================
monitor_positions = [0.001; 0.254; 0.600; 1.000; 1.700; ...
                     2.760; 3.964; 6.4018; 6.8276; 8.305];
monitor_names     = ["Cathode","Anode","Trans1","Trans2","Trans3", ...
                     "BPM1","BPM2","BPM3","BPM4","BPM5"];
n_monitors        = length(monitor_positions);
I_monitor         = zeros(nt, n_monitors);
particles_through = zeros(n_monitors, 1);
particle_counted_at_monitor = false(max_particles, n_monitors);

fprintf('\nMonitors: %d positions (%.0f mm to %.0f mm)\n', ...
        n_monitors, monitor_positions(1)*1000, monitor_positions(end)*1000);

%% ==================== ANALYSIS PLANES ====================
ANALYSIS_LOCATIONS = [254;600;1000;1500;1700;2200;2700; ...
                      3400;3964;4600;5400;6402;6828;7450;8305];
ANALYSIS_LOCATION_NAMES = {'Anode','Early_Drift','Mid_Drift1','Trans1','Trans2', ...
    'Mid_Drift2','BPM1','Extension1','BPM2','Extension2', ...
    'Late_Drift','BPM3','BPM4','Sol49','Exit'};
N_ANALYSIS_PLANES = length(ANALYSIS_LOCATIONS);
twiss_locations   = ANALYSIS_LOCATIONS;
location_names    = ANALYSIS_LOCATION_NAMES;
n_locations       = N_ANALYSIS_PLANES;
n_twiss_planes    = N_ANALYSIS_PLANES;

%% ==================== DIAGNOSTIC ARRAYS ====================
I_emit                = zeros(nt, 1);
I_anode               = zeros(nt, 1);
I_exit                = zeros(nt, 1);
I_cathode             = zeros(nt, 1);
I_drift_exit          = zeros(nt, 1);
collection_efficiency = zeros(nt, 1);
n_active_history      = zeros(nt, 1);

J_thermionic  = zeros(nt, 1);
J_space_charge = zeros(nt, 1);
J_actual      = zeros(nt, 1);

sc_field_cathode      = zeros(nt, 1);
sc_field_max          = zeros(nt, 1);
sc_field_distribution = zeros(nt, 1);
particle_weight_history = zeros(nt, 1);
max_sc_field_recorded = 0;

n_z_diagnostic   = 480;
z_diagnostic     = linspace(0, 8.31, n_z_diagnostic);
r_rms_history    = zeros(nt, n_z_diagnostic);
n_particles_vs_z = zeros(nt, n_z_diagnostic);
r_wall           = 0.075;

snapshot_times = [165e-9, 185e-9, 205e-9, 225e-9];
snapshot_data  = struct();
snapshot_count = 0;

%% ==================== SNAPSHOT STORAGE ====================
if ENABLE_MULTIPULSE == true
    snapshot_p1 = cell(N_SNAPSHOTS, 1);
    snapshot_p2 = cell(N_SNAPSHOTS, 1);
    snapshot_p3 = cell(N_SNAPSHOTS, 1);
    snapshot_p4 = cell(N_SNAPSHOTS, 1);
    snapshot_p1_count = 0;
    snapshot_p2_count = 0;
    snapshot_p3_count = 0;
    snapshot_p4_count = 0;
    fprintf('Snapshot storage: %d per pulse (P1-P4)\n', N_SNAPSHOTS);
else
    snapshot_early = cell(N_SNAPSHOTS_EARLY, 1);
    snapshot_late  = cell(N_SNAPSHOTS_LATE,  1);
    snapshot_p1    = cell(N_SNAPSHOTS, 1);
    snapshot_early_count = 0;
    snapshot_late_count  = 0;
    snapshot_p1_count    = 0;
    fprintf('Snapshot storage: %d early, %d late, %d P1\n', ...
            N_SNAPSHOTS_EARLY, N_SNAPSHOTS_LATE, N_SNAPSHOTS);
end

%% ==================== MULTI-PULSE DIAGNOSTICS ====================
if ENABLE_MULTIPULSE == true
    particle_source_pulse = zeros(max_particles, 1);

    pulse_diagnostics = struct();
    for ip = 1:pulse_config.n_pulses
        pulse_diagnostics(ip).particles_emitted     = 0;
        pulse_diagnostics(ip).particles_at_anode    = 0;
        pulse_diagnostics(ip).particles_transmitted = 0;
        pulse_diagnostics(ip).charge_emitted        = 0;
        pulse_diagnostics(ip).charge_transmitted    = 0;
        pulse_diagnostics(ip).I_peak                = 0;
    end
    fprintf('Multi-pulse diagnostics initialized (%d pulses)\n', pulse_config.n_pulses);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HANDOFF ARRAYS %%%%%%%%%%%%%%%%%%%%%%%%%%
%% If the debug line prints length = 1 for particle_t_at_exit then the 
% Block 1 initialization needs:
    %% In Block 1 — ensure full pre-allocation (R2025b compatible)
     particle_t_at_exit  = zeros(max_particles, 1, 'double');   %% explicit type
     particle_KE_at_exit = zeros(max_particles, 1, 'double');
     particle_t_at_anode  = zeros(max_particles, 1, 'double');
     particle_KE_at_anode = zeros(max_particles, 1, 'double');
     particle_crossed_exit  = false(max_particles, 1);
     particle_crossed_anode = false(max_particles, 1);
     n_max = max_particles; %just to make clear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of first section %%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== SOLENOID STRUCTURES ====================
solenoid1  = struct('B', solenoid1_field,  'z_c', -0.279,  'L', 0.106, 'R', 0.451);
solenoid2  = struct('B', solenoid2_field,  'z_c',  0.372,  'L', 0.195, 'R', 0.245);
solenoid3  = struct('B', solenoid3_field,  'z_c',  1.14461,'L', 0.120, 'R', 0.245);
solenoid4  = struct('B', solenoid4_field,  'z_c',  1.26757,'L', 0.120, 'R', 0.245);
solenoid5  = struct('B', solenoid5_field,  'z_c',  1.36927,'L', 0.120, 'R', 0.245);
solenoid7  = struct('B', solenoid7_field,  'z_c',  1.49223,'L', 0.100, 'R', 0.245);
solenoid8  = struct('B', solenoid8_field,  'z_c',  1.59393,'L', 0.100, 'R', 0.245);
solenoid9  = struct('B', solenoid9_field,  'z_c',  1.71689,'L', 0.100, 'R', 0.245);
solenoid10 = struct('B', solenoid10_field, 'z_c',  1.81860,'L', 0.090, 'R', 0.245);
solenoid11 = struct('B', solenoid11_field, 'z_c',  1.94156,'L', 0.110, 'R', 0.245);
solenoid12 = struct('B', solenoid12_field, 'z_c',  2.04326,'L', 0.110, 'R', 0.245);
solenoid14 = struct('B', solenoid14_field, 'z_c',  2.16622,'L', 0.090, 'R', 0.245);
solenoid15 = struct('B', solenoid15_field, 'z_c',  2.26793,'L', 0.100, 'R', 0.245);
solenoid16 = struct('B', solenoid16_field, 'z_c',  2.39089,'L', 0.110, 'R', 0.245);
solenoid17 = struct('B', solenoid17_field, 'z_c',  2.49259,'L', 0.110, 'R', 0.245);
solenoid18 = struct('B', solenoid18_field, 'z_c',  2.61555,'L', 0.090, 'R', 0.245);
solenoid19 = struct('B', solenoid19_field, 'z_c',  2.71726,'L', 0.090, 'R', 0.245);
solenoid20 = struct('B', solenoid20_field, 'z_c',  2.84022,'L', 0.100, 'R', 0.245);
solenoid21 = struct('B', solenoid21_field, 'z_c',  2.94192,'L', 0.100, 'R', 0.245);
solenoid22 = struct('B', solenoid22_field, 'z_c',  3.06488,'L', 0.100, 'R', 0.245);
solenoid23 = struct('B', solenoid23_field, 'z_c',  3.16658,'L', 0.100, 'R', 0.245);
solenoid24 = struct('B', solenoid24_field, 'z_c',  3.28954,'L', 0.100, 'R', 0.245);
solenoid25 = struct('B', solenoid25_field, 'z_c',  3.39125,'L', 0.100, 'R', 0.245);
solenoid26 = struct('B', solenoid26_field, 'z_c',  3.51421,'L', 0.100, 'R', 0.245);
solenoid27 = struct('B', solenoid27_field, 'z_c',  3.61591,'L', 0.100, 'R', 0.245);
solenoid28 = struct('B', solenoid28_field, 'z_c',  3.73887,'L', 0.100, 'R', 0.245);
solenoid29 = struct('B', solenoid29_field, 'z_c',  3.84058,'L', 0.100, 'R', 0.245);
solenoid30 = struct('B', solenoid30_field, 'z_c',  3.96354,'L', 0.100, 'R', 0.245);
solenoid31 = struct('B', solenoid31_field, 'z_c',  4.06524,'L', 0.100, 'R', 0.245);
solenoid32 = struct('B', solenoid32_field, 'z_c',  4.18820,'L', 0.100, 'R', 0.245);
solenoid33 = struct('B', solenoid33_field, 'z_c',  4.28993,'L', 0.100, 'R', 0.245);
solenoid34 = struct('B', solenoid34_field, 'z_c',  4.41289,'L', 0.100, 'R', 0.245);
solenoid35 = struct('B', solenoid35_field, 'z_c',  4.51459,'L', 0.100, 'R', 0.245);
solenoid36 = struct('B', solenoid36_field, 'z_c',  4.63755,'L', 0.100, 'R', 0.245);
solenoid38 = struct('B', solenoid38_field, 'z_c',  4.73925,'L', 0.100, 'R', 0.245);
solenoid39 = struct('B', solenoid39_field, 'z_c',  4.86221,'L', 0.100, 'R', 0.245);
solenoid40 = struct('B', solenoid40_field, 'z_c',  4.96392,'L', 0.100, 'R', 0.245);
solenoid41 = struct('B', solenoid41_field, 'z_c',  5.08688,'L', 0.100, 'R', 0.245);
solenoid42 = struct('B', solenoid42_field, 'z_c',  5.18858,'L', 0.100, 'R', 0.245);
solenoid43 = struct('B', solenoid43_field, 'z_c',  5.31154,'L', 0.100, 'R', 0.245);
solenoid45 = struct('B', solenoid45_field, 'z_c',  5.41324,'L', 0.100, 'R', 0.245);
solenoid46 = struct('B', solenoid46_field, 'z_c',  5.53620,'L', 0.100, 'R', 0.245);
solenoid47 = struct('B', solenoid47_field, 'z_c',  5.63791,'L', 0.100, 'R', 0.245);
solenoid48 = struct('B', solenoid48_field, 'z_c',  5.76087,'L', 0.100, 'R', 0.245);
solenoid49 = struct('B', solenoid49_field, 'z_c',  7.44800,'L', 0.100, 'R', 0.245);

fprintf('\nSolenoid configuration: 43 active solenoids (6,13,37,44 are steering — OFF)\n');
fprintf('  Sol1:  %+.0f G at z=%.0f mm  (cathode)\n', solenoid1.B*1e4,  solenoid1.z_c*1000);
fprintf('  Sol2:  %+.0f G at z=%.0f mm  (anode)\n',   solenoid2.B*1e4,  solenoid2.z_c*1000);
fprintf('  Sol49: %+.0f G at z=%.0f mm  (last)\n',    solenoid49.B*1e4, solenoid49.z_c*1000);

%% ==================== MAGNETIC FIELD FUNCTIONS ====================
SOLENOID_ARGS = {solenoid1,solenoid2,solenoid3,solenoid4,solenoid5, ...
    solenoid7,solenoid8,solenoid9,solenoid10,solenoid11,solenoid12, ...
    solenoid14,solenoid15,solenoid16,solenoid17,solenoid18,solenoid19, ...
    solenoid20,solenoid21,solenoid22,solenoid23,solenoid24,solenoid25, ...
    solenoid26,solenoid27,solenoid28,solenoid29,solenoid30,solenoid31, ...
    solenoid32,solenoid33,solenoid34,solenoid35,solenoid36, ...
    solenoid38,solenoid39,solenoid40,solenoid41,solenoid42,solenoid43, ...
    solenoid45,solenoid46,solenoid47,solenoid48,solenoid49};

Bz_func = @(z_pos, r_pos, t_curr) ...
    calculate_Bz_solenoid(z_pos, r_pos, t_curr, SOLENOID_ARGS{:});

Br_func = @(z_pos, r_pos, t_curr) ...
    calculate_Br_solenoid(z_pos, r_pos, t_curr, SOLENOID_ARGS{:});

%% Quick solenoid function test
fprintf('\n=== Solenoid Function Test (t=200ns) ===\n');
for z_test = [0.5, 1.0, 2.0, 4.0, 6.0]
    Bz_t = Bz_func(z_test, 0.04, 200e-9);
    fprintf('  z=%.1f m:  Bz=%.2e T  (%.1f G)\n', z_test, Bz_t, Bz_t*1e4);
end

%% ==================== SCHOTTKY DIAGNOSTICS STRUCT ====================
schottky_diagnostics = struct();
schottky_diagnostics.E_cathode  = zeros(nt, 1);
schottky_diagnostics.delta_phi  = zeros(nt, 1);
schottky_diagnostics.phi_eff    = zeros(nt, 1);
schottky_diagnostics.T_cathode  = zeros(nt, 1);
schottky_diagnostics.T_required = zeros(nt, 1);

%% ==================== MAIN TIME LOOP ====================
fprintf('\nStarting simulation...\n');
fprintf('  nt=%d steps  |  dt=%.0f ps  |  t=%.1f→%.1f ns\n', ...
        nt, dt*1e12, t_start*1e9, t_end*1e9);
tic_start = tic;
fprintf('Progress: ');

for it = 1:nt
    current_t = t(it);

    %% Reset accumulators on first step
    if it == 1
        I_anode_accumulator = 0;
        I_exit_accumulator  = 0;
        I_anode_count       = 0;
        I_exit_count        = 0;
    end

    %% Progress reporting
    if mod(it, 1000) == 0
        elapsed = toc(tic_start);
        rate    = it / elapsed;
        eta     = (nt - it) / rate;
        fprintf('\n  Step %d/%d (%.1f%%) | %.0f steps/s | ETA %.1f min', ...
                it, nt, 100*it/nt, rate, eta/60);
        fprintf('\n  Active:%d  Created:%d  At_anode:%d  Transmitted:%d', ...
                n_active, n_created, particles_at_anode, particles_transmitted);
        fprintf('\n  ');
    elseif mod(it, round(nt/20)) == 0
        fprintf('.');
    end

    %% Refresh active index once per timestep
    active_idx = find(active_particles); 
    active_idx = active_idx(:);  %% added 04.07.2026
    n_active   = length(active_idx);

    %% ==================== PULSE FACTOR ====================
    pulse_factor  = pulse_shape(current_t);
    %% ==================== CURRENT PULSE DETECTION ====================
    if ENABLE_MULTIPULSE == true
        current_pulse = pulse_config.n_pulses;  % default to last pulse (inter-pulse coast)
        for ip = 1:pulse_config.n_pulses
            p_start = pulse_config.pulse_starts(ip);
            p_end   = p_start + pulse_config.rise_time + ...
                      pulse_config.flat_time + pulse_config.fall_time;
            if current_t >= p_start && current_t <= p_end
                current_pulse = ip;
                break;
            end
        end
    else
        current_pulse = 1;
    end

    %% ==================== EMISSION ====================
    if pulse_factor > 0.01

        %% --- Dynamic cathode field extraction ---
        iz_search = find(z >= 0.000 & z <= 0.010);
        if ~isempty(iz_search)
            E_cathode_base = max(abs(Ez_capped(1:3, iz_search(:)')), [], 'all');
        else
            E_cathode_base = E_CATHODE_BASE_DETECTED;
        end
        E_cathode = E_cathode_base * pulse_factor;

        %% Add space-charge contribution at cathode
        if ENABLE_SPACE_CHARGE && exist('Ez_sc','var') && any(Ez_sc(:) ~= 0)
            [~, iz_sc_cath] = min(abs(sc_z - 0.001));
            E_cathode = E_cathode + abs(mean(Ez_sc(:, iz_sc_cath)));
        end

        %% Schottky barrier reduction
        schottky_constant = sqrt(e_charge^3 / (4*pi*eps0));
        delta_phi = schottky_constant * sqrt(E_cathode) / e_charge;  % eV
        phi_0     = 1.8;    % base work function (eV)
        phi_eff   = phi_0 - delta_phi;
        
        %% Thermionic emission (Richardson-Dushman)
        A_RD       = 1.20173e6;   % A/m²/K²
        T_cathode  = 1200;        % K
        J_thermionic_current = A_RD * T_cathode^2 * ...
                               exp(-phi_eff * e_charge / (k_B * T_cathode));
        %%%%%%%%% Add In Block 1 Schottky setup %%%%%%%%%%%% 
        %% T_required: temperature needed WITHOUT Schottky enhancement
        %% to achieve the same emission current density J_emit
        %% Uses approximation T_req ≈ T_actual × (phi_0 / phi_eff)
        %% Valid for delta_phi << phi_0 (here delta_phi/phi_0 ≈ 5%)
        if phi_eff > 0.01   % guard against divide-by-zero at pulse edges
            schottky_diagnostics.T_required(it) = T_cathode * (phi_0 / phi_eff);
        else
            schottky_diagnostics.T_required(it) = T_cathode;
        end
        schottky_diagnostics.T_cathode(it) = T_cathode;
        schottky_diagnostics.delta_phi(it) = delta_phi;
        schottky_diagnostics.phi_eff(it)   = phi_eff;
        schottky_diagnostics.E_cathode(it) = E_cathode;

        %% Child-Langmuir space-charge limit (relativistic)
        V_gap    = 1.70e6 * pulse_factor;
        d_gap    = 0.254;
        gamma_exit = 1 + V_gap * e_charge / (m_e * c^2);
        beta_exit  = sqrt(1 - 1/gamma_exit^2);
        rel_factor = gamma_exit^(3/2) * (1 + 2*log(gamma_exit));
        emp_factor = 1.75;
        J_CL = emp_factor * (4/9) * eps0 * sqrt(2*e_charge/m_e) * ...
               V_gap^(3/2) / d_gap^2 * sqrt(rel_factor);

        %% Operational limit
        J_SPECIFICATION = 11e4;   % A/m²
        A_emit          = pi * 0.065^2;

        %% Three-way minimum
        J_emit         = min([J_SPECIFICATION, J_thermionic_current, J_CL]);
        I_emit_current = J_emit * A_emit;

        I_emit(it)    = I_emit_current;
        I_cathode(it) = I_emit_current;

        J_thermionic(it)   = J_thermionic_current;
        J_space_charge(it) = J_CL;
        J_actual(it)       = J_emit;

        schottky_diagnostics.E_cathode(it) = E_cathode;
        schottky_diagnostics.delta_phi(it) = delta_phi;
        schottky_diagnostics.phi_eff(it)   = phi_eff;
        schottky_diagnostics.T_cathode(it) = T_cathode;

        %% Adaptive particle count
        if pulse_factor < 0.95
            n_emit = ceil(base_particles * pulse_factor);
        else
            n_emit = base_particles;
        end

        charge_to_emit  = I_emit_current * dt;
        particle_weight = charge_to_emit / (n_emit * e_charge);

        if n_emit > 0
            particle_weight_history(it) = particle_weight;
        end

        %% Emit particles
        v_thermal = sqrt(2 * k_B * T_cathode / m_e);

        for ip = 1:n_emit
            if n_created < max_particles
                n_created = n_created + 1;
                idx       = n_created;

                r_emit = sqrt(rand()) * 0.065;

                z_particles(idx)      = 0.001;
                r_particles(idx)      = r_emit;
                weight_particles(idx) = particle_weight;
                active_particles(idx) = true;
                if ENABLE_MULTIPULSE == true
                    particle_source_pulse(idx) = current_pulse;
                end

                pz_particles(idx)     = m_e * abs(randn()) * v_thermal * 0.1;
                pr_particles(idx)     = m_e * randn()      * v_thermal * 0.01;
                ptheta_particles(idx) = m_e * randn()      * v_thermal * 0.01;

                n_active = n_active + 1;
            end
        end

        %% Emission diagnostic (every 1000 steps)
        if mod(it, 1000) == 0
            fprintf('\n  [EMISSION] t=%.1f ns  E_cath=%.2f MV/m  phi_eff=%.3f eV', ...
                    current_t*1e9, E_cathode/1e6, phi_eff);
            fprintf('\n             J=%.1f A/cm²  I=%.1f A  n_emit=%d', ...
                    J_emit/1e4, I_emit_current, n_emit);
        end

    end  %% pulse_factor > 0.01
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of the section 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Start of new third section %%%%%%%%%%%%%%%%%%%%%%%%%
    %% ==================== SC FIELD MONITOR ====================
    %% [CHANGED] — correctly zeros between solves and after beam off
    if ENABLE_SPACE_CHARGE && exist('Ez_sc','var')
        if mod(it, sc_interval) == 0 && n_active > 100
            %% SC solve just ran — record fresh values
            [~, iz_cath_sc] = min(abs(sc_z - 0.001));
            sc_field_cathode(it)      = mean(abs(Ez_sc(:, iz_cath_sc)));
            sc_field_max(it)          = max(abs(Ez_sc(:)));
            sc_field_distribution(it) = sqrt(mean(Ez_sc(:).^2));
        elseif n_active > 100 && it > 1
            %% Between SC solves — carry forward previous value
            sc_field_cathode(it)      = sc_field_cathode(it-1);
            sc_field_max(it)          = sc_field_max(it-1);
            sc_field_distribution(it) = sc_field_distribution(it-1);
        else
            %% Beam off (n_active <= 100) — zero the monitor
            sc_field_cathode(it)      = 0;
            sc_field_max(it)          = 0;
            sc_field_distribution(it) = 0;
        end
    end
    %% ==================== END SC FIELD MONITOR ====================

    %% ==================== ION DRIFT AND RECOMBINATION ====================
    total_ions_on_grid = 0;

    if ENABLE_ION_ACCUMULATION && ENABLE_SPACE_CHARGE
        total_ions_on_grid = sum(ion_density_grid(:));
    end
 %%%%%%%%%%%%%%%%%%%%%%%%% Replaced section    %%%%%%%%%%%%%%%%%%%%%%%%%%%
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       if ENABLE_ION_ACCUMULATION && ENABLE_SPACE_CHARGE && ...
       mod(it, sc_interval) == 0 && total_ions_on_grid > 0.1

        [ir_ion, jz_ion] = find(ion_density_grid > 0.01);
        valid_ion = ir_ion > 1 & ir_ion < sc_nr & ...
                    jz_ion > 1 & jz_ion < sc_nz;
        ir_ion = ir_ion(valid_ion);
        jz_ion = jz_ion(valid_ion);

        if ~isempty(ir_ion)
            z_pts = sc_z(jz_ion(:));   % column vector
            r_pts = sc_r(ir_ion(:));   % column vector

            E_z_local = interp2(z, r, Ez_capped, ...
                                z_pts, r_pts, 'linear', 0);
            E_z_local = E_z_local(:);  % ← force column vector

            if exist('Ez_sc','var')
                lin_idx   = sub2ind(size(Ez_sc), ir_ion, jz_ion);
                E_z_local = E_z_local + Ez_sc(lin_idx(:));
            end

            lin_idx_vz = sub2ind(size(ion_vz_grid), ir_ion, jz_ion);
            ion_vz_grid(lin_idx_vz) = ion_physics.mobility * E_z_local;
        end

        if mod(it, 100) == 0
            decay_factor     = exp(-dt * 100 / ion_physics.t_recomb_effective);
            ion_density_grid = ion_density_grid * decay_factor;
        end
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% ==================== SPACE CHARGE SOLVER ====================
    if ENABLE_SPACE_CHARGE && mod(it, sc_interval) == 0 && n_active > 100

        %% Reset SC arrays
        rho_grid(:) = 0;
        phi_grid(:) = 0;
        Ez_sc(:)    = 0;
        Er_sc(:)    = 0;

        active_idx = find(active_particles);
        n_dep      = length(active_idx);

        z_dep = z_particles(active_idx);
        r_dep = r_particles(active_idx);

        sc_enhancement_scale = 0.25;
        enhancement_gap      = 1.050 * sc_enhancement_scale;
        enhancement_drift    = 0.950 * sc_enhancement_scale;

%%%%%%%%%%%%%%%%%%%%%% Corrected Charge Deposition block %%%%%%%%%%%%%%%%%%%
%% ==================== SC CHARGE DEPOSITION — BILINEAR ====================
rho_grid(:) = 0;

if n_dep > 0
    z_dep = z_dep(:);
    r_dep = r_dep(:);
    w_col = weight_particles(active_idx(:));
    w_col = w_col(:);

    %% Enhancement vector
    in_gap  = (z_dep < 0.254);
    enh_vec = enhancement_drift * ones(n_dep, 1);
    enh_vec(in_gap) = enhancement_gap;

    %% Charge per super-particle
    q_vec = -enh_vec .* e_charge .* w_col;   %% (n_dep×1)

    %% Lower-left cell indices
    iz0 = max(1, min(sc_nz-1, floor((z_dep - sc_z(1)) / sc_dz) + 1));
    ir0 = max(1, min(sc_nr-1, floor((r_dep - sc_r(1)) / sc_dr) + 1));
    iz1 = iz0 + 1;
    ir1 = ir0 + 1;

    %% Force all index arrays to column vectors
    iz0 = iz0(:);  iz1 = iz1(:);
    ir0 = ir0(:);  ir1 = ir1(:);

    %% Bilinear weights — all column vectors
    %% Bilinear weights — sc_z and sc_r must be indexed as column vectors
    sc_z_col = sc_z(:);   %% force sc_z to column vector once
    sc_r_col = sc_r(:);   %% force sc_r to column vector once

    dz_frac = (z_dep - (sc_z(1) + (iz0-1).*sc_dz)) ./ sc_dz;
    dr_frac = (r_dep - (sc_r(1) + (ir0-1).*sc_dr)) ./ sc_dr;
    dz_frac = max(0, min(1, dz_frac(:)));
    dr_frac = max(0, min(1, dr_frac(:)));

    w00 = (1 - dz_frac) .* (1 - dr_frac);
    w01 = (1 - dz_frac) .*      dr_frac;
    w10 =      dz_frac  .* (1 - dr_frac);
    w11 =      dz_frac  .*      dr_frac;

    %% Cell volumes — annular rings, all column vectors
    vol_ir0 = pi .* ((ir0.*sc_dr).^2 - ((ir0-1).*sc_dr).^2) .* sc_dz;
    vol_ir1 = pi .* ((ir1.*sc_dr).^2 - ((ir1-1).*sc_dr).^2) .* sc_dz;
    vol_ir0(ir0 == 1) = pi * sc_dr^2 * sc_dz;
    vol_ir1(ir1 == 1) = pi * sc_dr^2 * sc_dz;

    %% Charge density contributions — all column vectors
    c00 = q_vec .* w00 ./ vol_ir0;  c00 = c00(:);
    c01 = q_vec .* w01 ./ vol_ir1;  c01 = c01(:);
    c10 = q_vec .* w10 ./ vol_ir0;  c10 = c10(:);
    c11 = q_vec .* w11 ./ vol_ir1;  c11 = c11(:);

    %% Linear indices — all column vectors
    idx00 = sub2ind([sc_nr, sc_nz], ir0, iz0);
    idx01 = sub2ind([sc_nr, sc_nz], ir1, iz0);
    idx10 = sub2ind([sc_nr, sc_nz], ir0, iz1);
    idx11 = sub2ind([sc_nr, sc_nz], ir1, iz1);

    %% Accumulate — guaranteed column vectors, same length
    all_idx = [idx00; idx01; idx10; idx11];
    all_c   = [c00;   c01;   c10;   c11];

    %% Safety check
    assert(numel(all_idx) == numel(all_c), ...
           'Size mismatch: idx=%d  c=%d', numel(all_idx), numel(all_c));

    rho_grid = reshape( ...
        accumarray(all_idx, all_c, [sc_nr*sc_nz, 1], @sum, 0), ...
        sc_nr, sc_nz);
end
%% ======================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% Verification script 
%% Add immediately after rho_grid = reshape(accumarray(...))
if it <= sc_interval * 2
    fprintf('  [SC verify] n_dep=%d  rho_max=%.3e  rho_nnz=%d\n', ...
            n_dep, max(abs(rho_grid(:))), sum(rho_grid(:)~=0));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Ion contribution
        if ENABLE_ION_ACCUMULATION && total_ions_on_grid > 0
            ion_cell_vol       = zeros(sc_nr, sc_nz);
            ion_cell_vol(1, :) = pi * (sc_dr/2)^2 * sc_dz;
            r_i = sc_r(2:end)';
            ion_cell_vol(2:end, :) = repmat( ...
                pi * ((r_i + sc_dr/2).^2 - (r_i - sc_dr/2).^2) * sc_dz, 1, sc_nz);

            in_gap_cells = repmat((sc_z(:)' < 0.254), sc_nr, 1);
            enh_ion                = zeros(sc_nr, sc_nz);
            enh_ion( in_gap_cells) = enhancement_gap;
            enh_ion(~in_gap_cells) = enhancement_drift;

            real_ion_density = ion_density_grid * ion_physics.superparticle_weight;
            sig_ions         = (ion_density_grid > 0.01);
            ion_rho          = enh_ion .* e_charge .* real_ion_density ./ ion_cell_vol;
            rho_grid         = rho_grid + ion_rho .* sig_ions;
        end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %% Clamp rho before Poisson solve
        rho_cap  = 3.0 * eps0 * 7.5e6 / sc_dz;
        rho_grid = max(-rho_cap, min(rho_cap, rho_grid));

        %% SOR Poisson solver
        dz2    = sc_dz^2;
        dr2    = sc_dr^2;
        denom  = 2.0 * (dr2 + dz2);
        rhs_fac = dr2 * dz2 / (denom * eps0);

        ir_int = 2:(sc_nr - 1);
        jz_int = 2:(sc_nz - 1);

        for iter = 1:sc_iterations

            phi_new = (dr2 * (phi_grid(ir_int+1, jz_int) + ...
                               phi_grid(ir_int-1, jz_int)) + ...
                       dz2 * (phi_grid(ir_int, jz_int+1) + ...
                               phi_grid(ir_int, jz_int-1))) / denom ...
                      - rho_grid(ir_int, jz_int) * rhs_fac;

            phi_grid(ir_int, jz_int) = (1 - sc_omega) * phi_grid(ir_int, jz_int) + ...
                                        sc_omega * phi_new;

            axis_denom   = 4*dz2 + 2*dr2;
            phi_axis_new = ((4*dz2) * phi_grid(2, jz_int) + ...
                             dr2    * (phi_grid(1, jz_int+1) + ...
                                       phi_grid(1, jz_int-1))) / axis_denom ...
                           - rho_grid(1, jz_int) * (dr2*dz2) / (axis_denom * eps0);

            phi_grid(1, jz_int) = (1 - sc_omega) * phi_grid(1, jz_int) + ...
                                   sc_omega * phi_axis_new;

            phi_grid(sc_nr, :) = phi_grid(sc_nr-1, :);
            phi_grid(:,    1)  = 0;
            phi_grid(:, sc_nz) = 0;
        end

        %% Electric field from potential
        Ez_sc(ir_int, jz_int) = -(phi_grid(ir_int, jz_int+1) - ...
                                   phi_grid(ir_int, jz_int-1)) / (2*sc_dz);
        Er_sc(ir_int, jz_int) = -(phi_grid(ir_int+1, jz_int) - ...
                                   phi_grid(ir_int-1, jz_int)) / (2*sc_dr);

        Ez_sc(1, jz_int) = -(phi_grid(1, jz_int+1) - ...
                              phi_grid(1, jz_int-1)) / (2*sc_dz);
        Er_sc(1, :)      = 0;

        %% Inf/NaN guard
        if any(~isfinite(Ez_sc(:))) || any(~isfinite(Er_sc(:)))
            Ez_sc(~isfinite(Ez_sc)) = 0;
            Er_sc(~isfinite(Er_sc)) = 0;
        end

        %% SC field cap
        max_sc   = 3.0 * 7.5e6;
        E_sc_mag = max(max(abs(Ez_sc(:))), max(abs(Er_sc(:))));
        if E_sc_mag > max_sc
            scale = max_sc / E_sc_mag;
            Ez_sc = Ez_sc * scale;
            Er_sc = Er_sc * scale;
        end

        max_sc_field_recorded = max(max_sc_field_recorded, max(abs(Ez_sc(:))));

        if mod(it, 1000) == 0
            fprintf('\n  [SC] rho_max=%.2e C/m³ | Ez_max=%.3f MV/m | Er_max=%.3f MV/m', ...
                    max(abs(rho_grid(:))), max(abs(Ez_sc(:)))/1e6, max(abs(Er_sc(:)))/1e6);
        end

    end  %% SC solver

    %% ==================== ION CREATION ====================
    if ENABLE_ION_ACCUMULATION && ENABLE_SPACE_CHARGE && ...
       mod(it, scatter_cal.check_interval) == 0

        active_idx = find(active_particles);
        n_check    = length(active_idx);

        if n_check > 0
            p_total_ion  = sqrt(pz_particles(active_idx).^2 + ...
                                pr_particles(active_idx).^2 + ...
                                ptheta_particles(active_idx).^2);
            gamma_ion    = gamma_particles(active_idx);
            beta_ion     = sqrt(1 - 1./gamma_ion.^2);
            ds_ion       = c * beta_ion * dt * scatter_cal.check_interval;

            p_ionize     = 1 - exp(-ion_physics.sigma_ionization * ...
                                    gas_params.n_gas .* ds_ion);

            real_ions_pp   = weight_particles(active_idx) .* p_ionize;
            superions_pp   = real_ions_pp / ion_physics.superparticle_weight;
            total_superions = sum(superions_pp);

            if total_superions > 0.01
                for i = 1:n_check
                    if superions_pp(i) > 0.01
                        idx_g = active_idx(i);
                        [~, iz_ion] = min(abs(sc_z - z_particles(idx_g)));
                        [~, ir_ion] = min(abs(sc_r - r_particles(idx_g)));
                        if iz_ion >= 1 && iz_ion <= sc_nz && ...
                           ir_ion >= 1 && ir_ion <= sc_nr
                            ion_density_grid(ir_ion, iz_ion) = ...
                                ion_density_grid(ir_ion, iz_ion) + superions_pp(i);
                            ion_density_by_pulse(ir_ion, iz_ion, current_pulse) = ...
                                ion_density_by_pulse(ir_ion, iz_ion, current_pulse) + ...
                                superions_pp(i);
                        end
                    end
                end

                real_ions_created = total_superions * ion_physics.superparticle_weight;
                ion_diag.creation_history(it)       = real_ions_created;
                ion_diag.ions_per_pulse(current_pulse) = ...
                    ion_diag.ions_per_pulse(current_pulse) + real_ions_created;
            end
        end
    end

    %% ==================== ION DIAGNOSTICS ====================
    if ENABLE_ION_ACCUMULATION && ENABLE_SPACE_CHARGE
        ion_diag.total_ions_vs_time(it)   = total_ions_on_grid * ...
                                             ion_physics.superparticle_weight;
        ion_diag.peak_density_vs_time(it) = max(ion_density_grid(:)) * ...
                                             ion_physics.superparticle_weight;
    end

    %% ==================== GAS SCATTERING ====================
    if ENABLE_GAS_SCATTERING && mod(it, scatter_cal.check_interval) == 0

        active_idx      = find(active_particles);
        n_scatter_check = length(active_idx);

        if n_scatter_check > 0
            p_total_sc = sqrt(pz_particles(active_idx).^2 + ...
                              pr_particles(active_idx).^2 + ...
                              ptheta_particles(active_idx).^2);
            gamma_sc   = gamma_particles(active_idx);
            beta_sc    = sqrt(1 - 1./gamma_sc.^2);
            ds_sc      = c * beta_sc * dt * scatter_cal.check_interval;

            sigma_tuned = gas_params.sigma_elastic * scatter_cal.strength_factor;
            p_scatter   = 1 - exp(-sigma_tuned * gas_params.n_gas .* ds_sc);
            p_scatter = p_scatter(:); % added 04.07.2026
            scatter_mask = rand(n_scatter_check, 1) < p_scatter;

            if any(scatter_mask)
                scatter_idx = active_idx(scatter_mask);
                n_scattered = length(scatter_idx);
                p_sc        = p_total_sc(scatter_mask);
                ds_s        = ds_sc(scatter_mask);

                Z_eff = 7.4;
                b_min = 1e-10;
                is_rare = rand(n_scattered, 1) < scatter_cal.rare_fraction;

                %% Typical small-angle scatters
                typical_idx = scatter_idx(~is_rare);
                if ~isempty(typical_idx)
                    p_typ  = p_sc(~is_rare);
                    ds_typ = ds_s(~is_rare);
                    theta_char = Z_eff * e_charge^2 ./ ...
                                 (4*pi*eps0 * p_typ * c * b_min);
                    n_scat_avg = gas_params.n_gas * sigma_tuned * ds_typ;
                    theta_0    = theta_char .* sqrt(n_scat_avg);
                    theta_typ  = randn(length(typical_idx), 1) .* theta_0;
                    phi_typ    = 2*pi * rand(length(typical_idx), 1);
                    pr_particles(typical_idx) = pr_particles(typical_idx) + ...
                                                p_typ .* theta_typ .* cos(phi_typ);
                    ptheta_particles(typical_idx) = ptheta_particles(typical_idx) + ...
                                                    p_typ .* theta_typ .* sin(phi_typ);
                end

                %% Rare large-angle scatters
                rare_idx = scatter_idx(is_rare);
                if ~isempty(rare_idx)
                    n_rare     = length(rare_idx);
                    p_rare     = p_sc(is_rare);
                    theta_min  = 0.1e-3;
                    theta_max  = scatter_cal.theta_rare_max;
                    u          = rand(n_rare, 1);
                    theta_rare = theta_min * (theta_max/theta_min).^u;
                    phi_rare   = 2*pi * rand(n_rare, 1);
                    pr_particles(rare_idx) = pr_particles(rare_idx) + ...
                                             p_rare .* theta_rare .* cos(phi_rare);
                    ptheta_particles(rare_idx) = ptheta_particles(rare_idx) + ...
                                                 p_rare .* theta_rare .* sin(phi_rare);

                    %% Store rare angles for diagnostics
                    scatter_diag.theta_history = [scatter_diag.theta_history; ...
                                                  theta_rare];
                    scatter_diag.rare_count = scatter_diag.rare_count + n_rare;
                end

                %% Store typical angles for diagnostics
                if ~isempty(typical_idx)
                    scatter_diag.theta_history = [scatter_diag.theta_history; ...
                                                  theta_typ];
                end

                %% Store scatter positions (z coordinates of scattered particles)
                scatter_diag.z_scatter_positions = [ ...
                    scatter_diag.z_scatter_positions; ...
                    z_active(scatter_mask)];

                scatter_diag.event_count = scatter_diag.event_count + n_scattered;
            end
        end
    end  %% gas scattering

    %% ==================== PARTICLE PUSH ====================
    %%  Single position update — no second update anywhere in the loop.
    %%  All crossing detection runs here, immediately after z_particles
    %%  is written, using z_active (pre-step) and z_new (post-step).

    if n_active > 0

        active_idx = find(active_particles);
        z_active   = z_particles(active_idx);
        r_active   = r_particles(active_idx);

        %% --- Geometry loss classification ---
        r_cathode_gap       = 0.075;
        r_drift_tube        = 0.075;
        r_max_computational = 0.450;

        back_to_cathode      = (z_active < 0);
        in_gap               = (z_active >= 0)     & (z_active < 0.254);
        gap_wall_loss        = in_gap  & (r_active > r_cathode_gap);
        in_drift             = (z_active >= 0.500);
        drift_wall_loss      = in_drift & (r_active > r_drift_tube);
        in_transition        = (z_active >= 0.254) & (z_active < 0.500);
        r_transition         = r_cathode_gap + ...
                               (r_drift_tube - r_cathode_gap) .* ...
                               (z_active - 0.254) / (0.500 - 0.254);
        transition_wall_loss = in_transition & (r_active > r_transition);
        out_of_domain        = (z_active > 8.350) | ...
                               (r_active > r_max_computational) | ...
                               (z_active < -0.5);

        lost_mask = back_to_cathode | gap_wall_loss | drift_wall_loss | ...
                    transition_wall_loss | out_of_domain;

        %% --- Loss accounting ---
        if any(lost_mask)
            n_back   = sum(back_to_cathode);
            n_gwall  = sum(gap_wall_loss);
            n_dwall  = sum(drift_wall_loss);
            n_twall  = sum(transition_wall_loss);
            n_oob    = sum(out_of_domain & ~back_to_cathode & ...
                           ~gap_wall_loss & ~drift_wall_loss & ...
                           ~transition_wall_loss);

            lost_idx = active_idx(lost_mask);
            particles_lost_to_cathode = particles_lost_to_cathode + n_back;
            particles_lost_to_walls   = particles_lost_to_walls   + ...
                                        n_gwall + n_dwall + n_twall;
            particles_out_of_bounds   = particles_out_of_bounds   + n_oob;

            active_particles(lost_idx) = false;
            n_active = n_active - sum(lost_mask);

            if mod(it, 1000) == 0 && sum(lost_mask) > 0
                fprintf('\n  [LOSS] Cathode:%d  Walls:%d  OOB:%d', ...
                        n_back, n_gwall+n_dwall+n_twall, n_oob);
            end
        end

        %% --- Surviving particles ---
        valid      = ~lost_mask;
        active_idx = active_idx(valid);
        z_active   = z_active(valid);
        r_active   = r_active(valid);

        if ~isempty(active_idx)

            %% --- Grid clamps ---
            z_clamp_app = max(z(1),    min(z(end)    - 1e-6, z_active));
            r_clamp_app = max(r(1),    min(r(end)    - 1e-6, r_active));
            z_clamp_sc  = max(sc_z(1), min(sc_z(end) - 1e-6, z_active));
            r_clamp_sc  = max(sc_r(1), min(sc_r(end) - 1e-6, r_active));

            %% --- Applied field ---
            %Ez_local = interp2(Z_grid, R_grid, Ez_capped, ...
            %                    z_clamp_app, r_clamp_app, 'linear', 0) * pulse_factor;
            % Er_local = interp2(Z_grid, R_grid, Er_capped, ...
            %                   z_clamp_app, r_clamp_app, 'linear', 0) * pulse_factor;
%%%%%%%%%%%%%%%%%%%%%%%%%% Replacement for Ez Er interp2() %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% --- Applied field --- FAST BILINEAR (replaces interp2)
%% Step 2 — Replace in Main Loop (find the interp2 block and swap it out)
%% z_clamp_app and r_clamp_app already clamped — use directly

%% Cell indices (1-based)
iz_a = floor((z_clamp_app - app_z0) / app_dz) + 1;
ir_a = floor((r_clamp_app - app_r0) / app_dr) + 1;

%% Clamp to valid range
iz_a = max(1, min(app_nz-1, iz_a));
ir_a = max(1, min(app_nr-1, ir_a));

%% Fractional weights
wz_a = (z_clamp_app - (app_z0 + (iz_a-1)*app_dz)) / app_dz;
wr_a = (r_clamp_app - (app_r0 + (ir_a-1)*app_dr)) / app_dr;

%% Linear indices — Ez_capped is 500 rows (r) × 11000 cols (z)
idx_a   = ir_a   + (iz_a-1) * app_nr;
idx_az  = ir_a   + (iz_a  ) * app_nr;
idx_ar  = ir_a+1 + (iz_a-1) * app_nr;
idx_azr = ir_a+1 + (iz_a  ) * app_nr;

%% Bilinear interpolation — Ez
Ez_local = ( (1-wz_a).*(1-wr_a) .* Ez_capped(idx_a  ) + ...
                wz_a .*(1-wr_a) .* Ez_capped(idx_az ) + ...
             (1-wz_a).*   wr_a  .* Ez_capped(idx_ar  ) + ...
                wz_a .*   wr_a  .* Ez_capped(idx_azr ) ) * pulse_factor;

%% Bilinear interpolation — Er
Er_local = ( (1-wz_a).*(1-wr_a) .* Er_capped(idx_a  ) + ...
                wz_a .*(1-wr_a) .* Er_capped(idx_az ) + ...
             (1-wz_a).*   wr_a  .* Er_capped(idx_ar  ) + ...
                wz_a .*   wr_a  .* Er_capped(idx_azr ) ) * pulse_factor;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Add this one-time check immediately after the replacement block, 
% inside the loop but only at step == 1:
%% ONE-TIME VERIFICATION — remove after Test 30 confirms correctness
if it == 1
    Ez_ref = interp2(Z_grid, R_grid, Ez_capped, ...
                     z_clamp_app, r_clamp_app, 'linear', 0) * pulse_factor;
    Er_ref = interp2(Z_grid, R_grid, Er_capped, ...
                     z_clamp_app, r_clamp_app, 'linear', 0) * pulse_factor;
    ez_err = max(abs(Ez_local - Ez_ref));
    er_err = max(abs(Er_local - Er_ref));
    fprintf('INTERP CHECK step 1: Ez_max_err=%.2e  Er_max_err=%.2e\n', ...
            ez_err, er_err);
    %% Both should be < 1e-6 V/m — essentially machine precision
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %% --- Space charge field ---
            if ENABLE_SPACE_CHARGE && exist('Ez_sc','var') && any(Ez_sc(:) ~= 0)
                Ez_sc_local = interp2(sc_z, sc_r, Ez_sc, ...
                                      z_clamp_sc, r_clamp_sc, 'linear', 0);
                Er_sc_local = interp2(sc_z, sc_r, Er_sc, ...
                                      z_clamp_sc, r_clamp_sc, 'linear', 0);
                Ez_local = Ez_local + Ez_sc_local;
                Er_local = Er_local + Er_sc_local;
            end

            %% --- Boris push: first half electric kick ---
            pz_minus     = pz_particles(active_idx)    - 0.5*e_charge*Ez_local*dt;
            pr_minus     = pr_particles(active_idx)    - 0.5*e_charge*Er_local*dt;
            ptheta_minus = ptheta_particles(active_idx);

            %% --- Magnetic field ---
            Bz_local = calculate_Bz_solenoid(z_active, r_active, current_t, ...
                SOLENOID_ARGS{:});
            Br_local = calculate_Br_solenoid(z_active, r_active, current_t, ...
                SOLENOID_ARGS{:});

            %% --- Boris magnetic rotation ---
            p_mag_minus = sqrt(pz_minus.^2 + pr_minus.^2 + ptheta_minus.^2);
            gamma_minus = sqrt(1 + (p_mag_minus / (m_e*c)).^2);

            t_factor = -e_charge * dt ./ (2 * gamma_minus * m_e);
            tz = t_factor .* Bz_local;
            tr = t_factor .* Br_local;

            pr_prime     = pr_minus     + ptheta_minus .* tz;
            ptheta_prime = ptheta_minus + (pz_minus .* tr - pr_minus .* tz);
            pz_prime     = pz_minus     - ptheta_minus .* tr;

            s_denom = 1 + tz.^2 + tr.^2;
            sz = 2*tz ./ s_denom;
            sr = 2*tr ./ s_denom;

            pz_plus     = pz_minus     - ptheta_prime .* sr;
            pr_plus     = pr_minus     + ptheta_prime .* sz;
            ptheta_plus = ptheta_minus + pz_prime .* sr - pr_prime .* sz;

            %% --- Second half electric kick ---
            pz_particles(active_idx)     = pz_plus     - 0.5*e_charge*Ez_local*dt;
            pr_particles(active_idx)     = pr_plus     - 0.5*e_charge*Er_local*dt;
            ptheta_particles(active_idx) = ptheta_plus;

            %% --- Position update (THE ONLY position update in the loop) ---
            p_mag_new = sqrt(pz_particles(active_idx).^2 + ...
                             pr_particles(active_idx).^2 + ...
                             ptheta_particles(active_idx).^2);
            gamma_new = sqrt(1 + (p_mag_new / (m_e*c)).^2);

            %% Update gamma_particles here — used by ion creation & scattering
            gamma_particles(active_idx) = gamma_new;

            vz_new = pz_particles(active_idx) ./ (gamma_new * m_e);
            vr_new = pr_particles(active_idx) ./ (gamma_new * m_e);

            z_particles(active_idx) = z_active + vz_new * dt;
            r_particles(active_idx) = r_active + vr_new * dt;

            %% Enforce r >= 0
            neg_r = r_particles(active_idx) < 0;
            if any(neg_r)
                neg_g = active_idx(neg_r);
                r_particles(neg_g)      = abs(r_particles(neg_g));
                pr_particles(neg_g)     = -pr_particles(neg_g);
                ptheta_particles(neg_g) = -ptheta_particles(neg_g);
            end

            %% ============================================================
            %% [FIX-11] CROSSING DETECTION
            %%   z_active = pre-push positions  (assigned above, before losses)
            %%   z_new    = post-push positions  (just written to z_particles)
            %%   This block is the ONLY place crossings are detected.
            %% ============================================================
            z_new = z_particles(active_idx);

            %% --- Monitor crossings ---
            for mon = 1:n_monitors
                z_mon    = monitor_positions(mon);
                crossing = (z_active < z_mon) & (z_new >= z_mon);
                if any(crossing)
                    for ci = find(crossing)'
                        idx_g = active_idx(ci);
                        if ~particle_counted_at_monitor(idx_g, mon)
                            I_monitor(it, mon) = I_monitor(it, mon) + ...
                                weight_particles(idx_g) * e_charge / dt;
                            particles_through(mon) = particles_through(mon) + 1;
                            particle_counted_at_monitor(idx_g, mon) = true;
                        end
                    end
                end
            end

            %% --- Anode crossing (z = 0.254 m) ---
            at_anode = (z_active < 0.254) & (z_new >= 0.254);
            if any(at_anode)
                for ii = find(at_anode)'
                    g = active_idx(ii);
                    if ~particle_crossed_anode(g)
                        particle_crossed_anode(g) = true;
                        particle_t_at_anode(g)    = current_t;
                        particle_r_at_anode(g)    = r_particles(g);
                        particles_at_anode        = particles_at_anode + 1;
                        I_anode_accumulator       = I_anode_accumulator + ...
                                                    weight_particles(g) * e_charge;
                        pm_c  = sqrt(pz_particles(g)^2 + ...
                                     pr_particles(g)^2 + ...
                                     ptheta_particles(g)^2);
                        gam_c = sqrt(1 + (pm_c/(m_e*c))^2);
                        particle_KE_at_anode(g) = (gam_c - 1) * m_e * c^2 / e_charge;
                    end
                end
            end

            %% --- Exit crossing (z = 8.305 m) ---
            at_exit = (z_active < 8.305) & (z_new >= 8.305);
            if any(at_exit)
                for ii = find(at_exit)'
                    g = active_idx(ii);
                    if ~particle_crossed_exit(g)
                        particle_crossed_exit(g) = true;
                        particle_t_at_exit(g)    = current_t;
                        particles_transmitted    = particles_transmitted + 1;
                        I_exit_accumulator       = I_exit_accumulator + ...
                                                   weight_particles(g) * e_charge;
                        pm_e  = sqrt(pz_particles(g)^2 + ...
                                     pr_particles(g)^2 + ...
                                     ptheta_particles(g)^2);
                        gam_e = sqrt(1 + (pm_e/(m_e*c))^2);
                        particle_KE_at_exit(g) = (gam_e - 1) * m_e * c^2 / e_charge;
                        %% Remove immediately — prevents out-of-domain trap
                        active_particles(g) = false;
                        n_active = n_active - 1;
                    end
                end
            end
            %% ============================================================
            %% END [FIX-11] CROSSING DETECTION
            %% ============================================================

        end  %% ~isempty(active_idx)
    end  %% n_active > 0
    %% ==================== END PARTICLE PUSH ====================

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of new third section %%%%%%%%%%%%%%%%%%%%%
    %% ==================== CURRENT CONVERSION ====================
    %%  Runs every timestep. Accumulator → current array every 10 steps.

    if mod(it, 10) == 0
        I_anode(it)         = I_anode_accumulator / (10 * dt);
        I_anode_accumulator = 0;
    else
        if it > 1, I_anode(it) = I_anode(it-1); end
    end

    if mod(it, 10) == 0
        I_exit(it)         = I_exit_accumulator / (10 * dt);
        I_exit_accumulator = 0;
    else
        if it > 1, I_exit(it) = I_exit(it-1); end
    end

    %% Collection efficiency
    if I_cathode(it) > 0
        collection_efficiency(it) = 100 * I_anode(it) / I_cathode(it);
    end

    %% ==================== OUT-OF-BOUNDS SAFETY NET ====================
    %%  Catches any particle that slipped past the exit trap
    %%  (e.g. emitted at z>8.305 in a single step at very high energy).
    %%  Does NOT count as transmitted — these are numerical artefacts.

    if n_active > 0
        active_idx_chk = find(active_particles);
        z_chk = z_particles(active_idx_chk);
        r_chk = r_particles(active_idx_chk);
        oob   = (z_chk > 8.31) | (r_chk > 0.5) | (z_chk < -0.5);
        if any(oob)
            active_particles(active_idx_chk(oob)) = false;
            n_active = n_active - sum(oob);
            particles_out_of_bounds = particles_out_of_bounds + sum(oob);
        end
    end

    %% ==================== STORE ACTIVE COUNT ====================
    n_active_history(it) = n_active;

    %% ==================== RMS RADIUS VS Z ====================
    if mod(it, diag_interval) == 0 && n_active > 0
        active_idx = find(active_particles);
        z_diag     = z_particles(active_idx);
        r_diag     = r_particles(active_idx);
        for iz = 1:n_z_diagnostic
            in_sl = abs(z_diag - z_diagnostic(iz)) < 0.005;
            if sum(in_sl) > 10
                r_rms_history(it, iz)    = sqrt(mean(r_diag(in_sl).^2));
                n_particles_vs_z(it, iz) = sum(in_sl);
            end
        end
    end

    %% ==================== PER-1000-STEP DIAGNOSTICS ====================
    if mod(it, 1000) == 0

        active_idx = find(active_particles);
        n_active   = length(active_idx);

        %% --- Wall loss rate ---
        step_history(end+1)      = it;
        wall_loss_history(end+1) = particles_lost_to_walls;

        if length(step_history) >= 2
            d_steps  = step_history(end)      - step_history(end-1);
            d_losses = wall_loss_history(end)  - wall_loss_history(end-1);
            loss_rate = d_losses / max(d_steps, 1);
            fprintf('\n  [WALL LOSS] total=%d  last_1000=%d  rate=%.2e/step', ...
                    particles_lost_to_walls, d_losses, loss_rate);
        end

        %% --- Accounting closure ---
        active_idx_all = find(active_particles);
        total_accounted = particles_lost_to_cathode + ...
                          particles_lost_to_walls   + ...
                          particles_out_of_bounds   + ...
                          particles_transmitted     + ...
                          length(active_idx_all);
        unaccounted = n_created - total_accounted;
        if unaccounted ~= 0
            fprintf('\n  [ACCT WARN] unaccounted=%d  created=%d  accounted=%d', ...
                    unaccounted, n_created, total_accounted);
        else
            fprintf('\n  [ACCT OK]   closure=0  created=%d', n_created);
        end

        %% --- Transmission projection ---
        if it > 2000
            n_crossed_anode = sum(particle_crossed_anode(1:n_created));
            n1 = sum(active_particles(1:n_created));
            n2 = sum(particle_crossed_anode(1:n_created));
            n_in_drift = n1 + n2;
            %n_in_drift      = sum(active_particles(1:n_created) & ...
            %                     particle_crossed_anode(1:n_created));

            fprintf('\n  [TRANS] anode=%d  transmitted=%d  in_drift=%d', ...
                    n_crossed_anode, particles_transmitted, n_in_drift);

            if n_crossed_anode > 0
                fprintf('  eff=%.1f%%', ...
                        100*particles_transmitted/n_crossed_anode);
            end

            if current_t > 270e-9 && length(wall_loss_history) >= 2
                steps_rem  = nt - it;
                d_steps    = step_history(end)     - step_history(end-1);
                d_losses   = wall_loss_history(end) - wall_loss_history(end-1);
                rate       = d_losses / max(d_steps, 1);
                proj_exit  = particles_transmitted + ...
                             max(0, n_in_drift - rate*steps_rem);
                if n_crossed_anode > 0
                    fprintf('  proj_final=%.1f%%', ...
                            100*proj_exit/n_crossed_anode);
                end
            end
        end

        %% --- Energy distribution ---
        if n_active > 100
            pz_d  = pz_particles(active_idx);
            pr_d  = pr_particles(active_idx);
            pt_d  = ptheta_particles(active_idx);
            pm_d  = sqrt(pz_d.^2 + pr_d.^2 + pt_d.^2);
            gam_d = sqrt(1 + (pm_d/(m_e*c)).^2);
            KE_d  = (gam_d - 1) * 0.511;   % MeV

            %% Drift-tube particles only (z > 0.254 m) for meaningful mean
            in_dt  = z_particles(active_idx) > 0.254;
            if sum(in_dt) > 50
                KE_dt = KE_d(in_dt);
                fprintf('\n  [KE drift] mean=%.4f MeV  std=%.4f MeV  min=%.4f  max=%.4f', ...
                        mean(KE_dt), std(KE_dt), min(KE_dt), max(KE_dt));
            end
        end

        %% --- Beam radial distribution ---
        if n_active > 0
            z_act = z_particles(active_idx);
            r_act = r_particles(active_idx);
            in_dr = z_act > 0.500;
            if any(in_dr)
                r_dr = r_act(in_dr);
                fprintf('\n  [BEAM r] drift RMS=%.1fmm  max=%.1fmm  >75mm=%d(%.1f%%)', ...
                        sqrt(mean(r_dr.^2))*1000, max(r_dr)*1000, ...
                        sum(r_dr > 0.075), ...
                        100*sum(r_dr > 0.075)/length(r_dr));
            end
        end

        %% --- Current summary ---
        fprintf('\n  [CURRENT] cathode=%.1fA  anode=%.1fA  exit=%.1fA', ...
                I_cathode(it), I_anode(it), I_exit(it));

        %% --- SC summary ---
        %if ENABLE_SPACE_CHARGE && exist('Ez_sc','var')
        %   fprintf('\n  [SC] Ez_max=%.3f MV/m  Er_max=%.3f MV/m', ...
        %            max(abs(Ez_sc(:)))/1e6, max(abs(Er_sc(:)))/1e6);
        % end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% New SC Monitor %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       %% In Block 3, replace the SC field monitor block with this:

        %% --- KE at crossings (once enough data) ---
        n_anode_rec = sum(particle_KE_at_anode(1:n_created) > 0);
        n_exit_rec  = sum(particle_KE_at_exit(1:n_created)  > 0);
        if n_anode_rec > 100
            KE_an_MeV = particle_KE_at_anode(1:n_created);
            KE_an_MeV = KE_an_MeV(KE_an_MeV > 0) / 1e6;
            fprintf('\n  [KE@anode] mean=%.4f MeV  n=%d', mean(KE_an_MeV), n_anode_rec);
        end
        if n_exit_rec > 100
            KE_ex_MeV = particle_KE_at_exit(1:n_created);
            KE_ex_MeV = KE_ex_MeV(KE_ex_MeV > 0) / 1e6;
            fprintf('\n  [KE@exit]  mean=%.4f MeV  n=%d', mean(KE_ex_MeV), n_exit_rec);
        end

        fprintf('\n');

    end  %% mod(it,1000)==0

    %% ==================== SNAPSHOT CAPTURE ====================
    %%  Four fixed-time snapshots during pulse flat-top.
    if ENABLE_SNAPSHOTS && any(abs(current_t - snapshot_times) < dt/2)
        snapshot_count = snapshot_count + 1;
        active_idx     = find(active_particles);
        drift_idx      = active_idx(z_particles(active_idx) > 0.254);

        snapshot_data(snapshot_count).time       = current_t;
        snapshot_data(snapshot_count).z          = z_particles(drift_idx);
        snapshot_data(snapshot_count).r          = r_particles(drift_idx);
        snapshot_data(snapshot_count).pz         = pz_particles(drift_idx);
        snapshot_data(snapshot_count).pr         = pr_particles(drift_idx);
        snapshot_data(snapshot_count).ptheta     = ptheta_particles(drift_idx);
        snapshot_data(snapshot_count).gamma      = gamma_particles(drift_idx);
        snapshot_data(snapshot_count).weight     = weight_particles(drift_idx);
        snapshot_data(snapshot_count).n_particles = length(drift_idx);

        fprintf('\n  [SNAPSHOT %d] t=%.1f ns  %d drift particles\n', ...
                snapshot_count, current_t*1e9, length(drift_idx));
    end

    %% ==================== BETATRON AVERAGING SNAPSHOTS ====================
    %%  Early, late, and P1 mid-pulse snapshot arrays.
    if ENABLE_BETATRON_AVERAGING

        if ENABLE_MULTIPULSE == true

            %% Multi-pulse snapshot capture
            if ENABLE_SNAPSHOTS
                active_snap = find(active_particles);
                if ~isempty(active_snap)
                    snap_data.z = z_particles(active_snap);
                    snap_data.r = r_particles(active_snap);
                    snap_data.pz = pz_particles(active_snap);
                    snap_data.pr = pr_particles(active_snap);
                    snap_data.ptheta = ptheta_particles(active_snap);
                    snap_data.gamma = gamma_particles(active_snap);
                    snap_data.weight = weight_particles(active_snap);
                    snap_data.t = current_t;

                    %% P1 snapshots
                    if snapshot_p1_count < N_SNAPSHOTS
                        for ks = 1:N_SNAPSHOTS
                            if abs(current_t - SNAPSHOT_P1_TIMES(ks)) < dt*0.51 && ...
                               isempty(snapshot_p1{ks})
                                snapshot_p1{ks} = snap_data;
                                snapshot_p1_count = snapshot_p1_count + 1;
                            end
                        end
                    end
                    %% P2 snapshots
                    if snapshot_p2_count < N_SNAPSHOTS
                        for ks = 1:N_SNAPSHOTS
                            if abs(current_t - SNAPSHOT_P2_TIMES(ks)) < dt*0.51 && ...
                               isempty(snapshot_p2{ks})
                                snapshot_p2{ks} = snap_data;
                                snapshot_p2_count = snapshot_p2_count + 1;
                            end
                        end
                    end
                    %% P3 snapshots (only if n_pulses >= 3)
                    if pulse_config.n_pulses >= 3 && snapshot_p3_count < N_SNAPSHOTS
                        for ks = 1:N_SNAPSHOTS
                            if abs(current_t - SNAPSHOT_P3_TIMES(ks)) < dt*0.51 && ...
                               isempty(snapshot_p3{ks})
                                snapshot_p3{ks} = snap_data;
                                snapshot_p3_count = snapshot_p3_count + 1;
                            end
                        end
                    end
                    %% P4 snapshots (only if n_pulses >= 4)
                    if pulse_config.n_pulses >= 4 && snapshot_p4_count < N_SNAPSHOTS
                        for ks = 1:N_SNAPSHOTS
                            if abs(current_t - SNAPSHOT_P4_TIMES(ks)) < dt*0.51 && ...
                               isempty(snapshot_p4{ks})
                                snapshot_p4{ks} = snap_data;
                                snapshot_p4_count = snapshot_p4_count + 1;
                            end
                        end
                    end
                end
            end

        else

            %% Single-pulse snapshot capture (V3 existing logic)
            %% Early beam snapshots
            for is = 1:N_SNAPSHOTS_EARLY
                if abs(current_t - SNAPSHOT_EARLY_TIMES(is)) < dt/2
                    if isempty(snapshot_early{is})
                        active_idx = find(active_particles);
                        snapshot_early{is} = struct( ...
                            'z',       z_particles(active_idx), ...
                            'r',       r_particles(active_idx), ...
                            'pr',      pr_particles(active_idx), ...
                            'pz',      pz_particles(active_idx), ...
                            'ptheta',  ptheta_particles(active_idx), ...
                            'gamma',   gamma_particles(active_idx), ...
                            'weight',  weight_particles(active_idx), ...
                            'time',    current_t, ...
                            'n_total', length(active_idx));
                        snapshot_early_count = snapshot_early_count + 1;
                        current_ions = 0;
                        if ENABLE_ION_ACCUMULATION && ENABLE_SPACE_CHARGE
                            current_ions = sum(ion_density_grid(:)) * ...
                                           ion_physics.superparticle_weight;
                        end
                        fprintf('\n  [EARLY snap %d/%d] t=%.1f ns  n=%d  ions=%.1e\n', ...
                                snapshot_early_count, N_SNAPSHOTS_EARLY, ...
                                current_t*1e9, length(active_idx), current_ions);
                    end
                end
            end

            %% Late beam snapshots
            for is = 1:N_SNAPSHOTS_LATE
                if abs(current_t - SNAPSHOT_LATE_TIMES(is)) < dt/2
                    if isempty(snapshot_late{is})
                        active_idx = find(active_particles);
                        snapshot_late{is} = struct( ...
                            'z',       z_particles(active_idx), ...
                            'r',       r_particles(active_idx), ...
                            'pr',      pr_particles(active_idx), ...
                            'pz',      pz_particles(active_idx), ...
                            'ptheta',  ptheta_particles(active_idx), ...
                            'gamma',   gamma_particles(active_idx), ...
                            'weight',  weight_particles(active_idx), ...
                            'time',    current_t, ...
                            'n_total', length(active_idx));
                        snapshot_late_count = snapshot_late_count + 1;
                        current_ions = 0;
                        if ENABLE_ION_ACCUMULATION && ENABLE_SPACE_CHARGE
                            current_ions = sum(ion_density_grid(:)) * ...
                                           ion_physics.superparticle_weight;
                        end
                        fprintf('\n  [LATE snap %d/%d] t=%.1f ns  n=%d  ions=%.1e\n', ...
                                snapshot_late_count, N_SNAPSHOTS_LATE, ...
                                current_t*1e9, length(active_idx), current_ions);
                    end
                end
            end

            %% P1 mid-pulse snapshots
            for is = 1:N_SNAPSHOTS
                if abs(current_t - SNAPSHOT_P1_TIMES(is)) < dt/2
                    if isempty(snapshot_p1{is})
                        active_idx = find(active_particles);
                        snapshot_p1{is} = struct( ...
                            'z',       z_particles(active_idx), ...
                            'r',       r_particles(active_idx), ...
                            'pr',      pr_particles(active_idx), ...
                            'pz',      pz_particles(active_idx), ...
                            'ptheta',  ptheta_particles(active_idx), ...
                            'gamma',   gamma_particles(active_idx), ...
                            'weight',  weight_particles(active_idx), ...
                            'time',    current_t, ...
                            'n_total', length(active_idx));
                        snapshot_p1_count = snapshot_p1_count + 1;
                        fprintf('\n  [P1 snap %d/%d] t=%.1f ns  n=%d\n', ...
                                snapshot_p1_count, N_SNAPSHOTS, ...
                                current_t*1e9, length(active_idx));
                    end
                end
            end

        end  %% ENABLE_MULTIPULSE

    end  %% ENABLE_BETATRON_AVERAGING

    %% ==================== STEADY-STATE BEAM CAPTURE (it=6000) ====================
    if it == 6000
        fprintf('\n=== Steady-state beam capture at t=%.1f ns ===\n', current_t*1e9);
        active_idx = find(active_particles);
        steady_state_beam = struct( ...
            'z',       z_particles(active_idx), ...
            'r',       r_particles(active_idx), ...
            'pr',      pr_particles(active_idx), ...
            'pz',      pz_particles(active_idx), ...
            'ptheta',  ptheta_particles(active_idx), ...
            'gamma',   gamma_particles(active_idx), ...
            'weight',  weight_particles(active_idx), ...
            'vz',      pz_particles(active_idx) ./ ...
                       (gamma_particles(active_idx) * m_e), ...
            'time',    current_t, ...
            'n_total', length(active_idx));
        fprintf('  Captured %d particles  z=%.1f–%.1f mm\n', ...
                steady_state_beam.n_total, ...
                min(steady_state_beam.z)*1000, ...
                max(steady_state_beam.z)*1000);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%% End of the secton four %%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%% Fifth section start %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end  %% for it = 1:nt
%% =====================================================================
%% ==================== END OF MAIN TIME LOOP =========================
%% =====================================================================

fprintf('\n\nSimulation complete.\n');
fprintf('Total wall time: %.1f min\n', toc(tic_start)/60);

%% ==================== FINAL ACCOUNTING REPORT ====================
fprintf('\n');
fprintf('================================================================\n');
fprintf('  FINAL PARTICLE ACCOUNTING\n');
fprintf('================================================================\n');
fprintf('  Created:              %d\n', n_created);
fprintf('  Transmitted (exit):   %d\n', particles_transmitted);
fprintf('  Lost to cathode:      %d\n', particles_lost_to_cathode);
fprintf('  Lost to walls:        %d\n', particles_lost_to_walls);
fprintf('  Out of bounds:        %d\n', particles_out_of_bounds);
fprintf('  Still active:         %d\n', sum(active_particles));

total_accounted = particles_lost_to_cathode + ...
                  particles_lost_to_walls   + ...
                  particles_out_of_bounds   + ...
                  particles_transmitted     + ...
                  sum(active_particles);
unaccounted = n_created - total_accounted;
fprintf('  Total accounted:      %d\n', total_accounted);
fprintf('  UNACCOUNTED:          %d  ', unaccounted);
if unaccounted == 0
    fprintf('<-- CLOSED\n');
else
    fprintf('<-- WARNING: non-zero!\n');
end
fprintf('================================================================\n');

%% ==================== KE AT CROSSING SUMMARY ====================
fprintf('\n');
fprintf('================================================================\n');
fprintf('  KINETIC ENERGY AT CROSSING PLANES\n');
fprintf('================================================================\n');

mask_anode = particle_KE_at_anode(1:n_created) > 0;
mask_exit  = particle_KE_at_exit(1:n_created)  > 0;

if sum(mask_anode) > 10
    KE_an = particle_KE_at_anode(1:n_created);
    KE_an = KE_an(mask_anode) / 1e6;   % MeV
    fprintf('  KE at anode  (z=254mm):\n');
    fprintf('    n = %d particles\n',   length(KE_an));
    fprintf('    mean = %.4f MeV\n',    mean(KE_an));
    fprintf('    std  = %.4f MeV\n',    std(KE_an));
    fprintf('    min  = %.4f MeV\n',    min(KE_an));
    fprintf('    max  = %.4f MeV\n',    max(KE_an));
else
    fprintf('  KE at anode: insufficient data (%d recorded)\n', sum(mask_anode));
end

if sum(mask_exit) > 10
    KE_ex = particle_KE_at_exit(1:n_created);
    KE_ex = KE_ex(mask_exit) / 1e6;    % MeV
    fprintf('  KE at exit   (z=8305mm):\n');
    fprintf('    n = %d particles\n',   length(KE_ex));
    fprintf('    mean = %.4f MeV\n',    mean(KE_ex));
    fprintf('    std  = %.4f MeV\n',    std(KE_ex));
    fprintf('    min  = %.4f MeV\n',    min(KE_ex));
    fprintf('    max  = %.4f MeV\n',    max(KE_ex));
    fprintf('  Energy retained anode→exit: %.2f%%\n', ...
            100 * mean(KE_ex) / max(mean(KE_an), 1e-9));
else
    fprintf('  KE at exit: insufficient data (%d recorded)\n', sum(mask_exit));
end
fprintf('================================================================\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== STEADY-STATE CURRENT METRICS ====================
%%  Use flat-top window t = 190–260 ns

t_ns       = t * 1e9;
flat_mask  = (t_ns >= 190) & (t_ns <= 245);

I_cath_ss  = mean(I_cathode(flat_mask));
I_anode_ss = mean(I_anode(flat_mask));
I_exit_ss  = mean(I_exit(flat_mask));

anode_eff  = 0;
exit_eff   = 0;
if I_cath_ss > 1
    anode_eff = 100 * I_anode_ss / I_cath_ss;
    exit_eff  = 100 * I_exit_ss  / I_cath_ss;
end

transmission_pct = 0;
if particles_at_anode > 0
    transmission_pct = 100 * particles_transmitted / particles_at_anode;
end

fprintf('\n');
fprintf('================================================================\n');
fprintf('  STEADY-STATE METRICS  (t = 190-260 ns)\n');
fprintf('================================================================\n');
fprintf('  Emission current:     %.1f A\n',  I_cath_ss);
fprintf('  Anode current:        %.1f A\n',  I_anode_ss);
fprintf('  Exit current:         %.1f A\n',  I_exit_ss);
fprintf('  Anode efficiency:     %.1f %%\n', anode_eff);
fprintf('  Exit efficiency:      %.1f %%\n', exit_eff);
fprintf('  Particle transmission:%.1f %%\n', transmission_pct);
fprintf('  Peak SC field:        %.3f MV/m\n', max_sc_field_recorded/1e6);
fprintf('================================================================\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== CORRECTED TRANSMISSION REPORT ====================
fprintf('\n================================================================\n');
fprintf('  TRANSMISSION ANALYSIS — CORRECT INTERPRETATION\n');
fprintf('================================================================\n');

%% Flat-top window (190-260 ns)
t_ns       = t * 1e9;
flat_mask  = (t_ns >= 190) & (t_ns <= 245); %  flat top overlap for all signals
I_cath_ss  = mean(I_cathode(flat_mask));
I_anode_ss = mean(I_anode(flat_mask));
I_exit_ss  = mean(I_exit(flat_mask));

fprintf('  CURRENT-BASED (flat-top t=190-260ns):\n');
fprintf('    Cathode:          %.1f A\n', I_cath_ss);
fprintf('    Anode:            %.1f A\n', I_anode_ss);
fprintf('    Drift exit:       %.1f A\n', I_exit_ss);
fprintf('    Anode eff:        %.1f%%\n', 100*I_anode_ss/max(I_cath_ss,1));
fprintf('    Exit eff:         %.1f%%  <- OPERATIONAL number\n', ...
        100*I_exit_ss/max(I_cath_ss,1));

fprintf('\n  PARTICLE-BASED (entire run including rise/fall):\n');
fprintf('    Created:          %d\n', n_created);
fprintf('    Reached anode:    %d  (%.1f%%)\n', ...
        particles_at_anode, 100*particles_at_anode/max(n_created,1));
fprintf('    Transmitted:      %d  (%.1f%% of created)\n', ...
        particles_transmitted, 100*particles_transmitted/max(n_created,1));
fprintf('    Wall losses:      %d  (%.1f%%)\n', ...
        particles_lost_to_walls, 100*particles_lost_to_walls/max(n_created,1));

fprintf('\n  NOTE: Current-based and particle-based differ because:\n');
fprintf('    - Current metric uses flat-top only (best focus, lowest losses)\n');
fprintf('    - Particle metric includes rise/fall where halo losses are higher\n');
fprintf('    - Operational transmission = %.1f%% (current-based flat-top)\n', ...
        100*I_exit_ss/max(I_cath_ss,1));
fprintf('================================================================\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Correct efficiency: normalize by cathode current at same timestep
%% Avoids any hardcoded scaling factor
%collection_efficiency_correct = zeros(nt, 1);
%for it_eff = 1:nt
%    if I_cathode(it_eff) > 10   % only when beam is on
%        collection_efficiency_correct(it_eff) = ...
%            100 * I_exit(it_eff) / I_cathode(it_eff);
%    end
%end
%% Then plot collection_efficiency_correct instead of collection_efficiency_2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== PLOT 1: CURRENT TRANSPORT ====================
figure('Name','Current Transport and Collection Efficiency', ...
       'Position',[50 50 1200 600]);
     
collection_efficiency_2 = 100*(I_exit./I_cath_ss);
colororder({'b','m'})

yyaxis left
plot(t_ns, I_cathode, 'r-',  'LineWidth', 2.0, 'DisplayName', 'Cathode');  hold on;
plot(t_ns, I_anode,   'b-',  'LineWidth', 1.5, 'DisplayName', 'Anode');
plot(t_ns, I_exit,    'g-',  'LineWidth', 1.5, 'DisplayName', 'Drift Exit');
ylabel('Current (A)');
ylim([0, max(max(I_cathode), 10) * 1.15]);

yyaxis right

plot(t_ns, collection_efficiency_2, 'm-', 'LineWidth', 1.0, ...
     'DisplayName', 'Efficiency');
ylabel('Drift Exit Efficiency (%)');
ylim([0, 120]);

xlabel('Time (ns)');
xlim([t_plot_min, t_plot_max]);
title('Current Transport and Collection Efficiency');
legend('Location','northeast');
grid on;

% Add text annotation with key metrics
text(0.30, 0.65, sprintf('Steady-state Metrics:'), ...
     'Units', 'normalized', 'VerticalAlignment', 'top', 'FontWeight', 'bold');
text(0.30, 0.60, sprintf('  I Cathode Steady : %.1f A', I_cath_ss), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');
text(0.30, 0.55, sprintf('  I Anode Steady  : %.1f A', I_anode_ss), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');
text(0.30, 0.50, sprintf('  Anode Efficiency : %.1f%%', anode_eff), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');
text(0.30, 0.45, sprintf('  I Exit Steady State: %.1f A', I_exit_ss), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');
text(0.30, 0.40, sprintf('  Transmission Steady: %.1f%%', exit_eff), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');

%% Annotation box
ann_x = t_plot_min + 0.35*(t_plot_max - t_plot_min);
ann_y = max(I_cathode) * 0.72;
text(ann_x, ann_y, ...
    sprintf('Steady-state Metrics:\nEmission: %.1f A\nAnode Eff: %.1f%%\nDrift Exit Eff: %.1f%%\nTransmission: %.1f%%', ...
            I_cath_ss, I_anode_ss, I_exit_ss, transmission_pct), ...
    'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black');

%% ==================== PLOT 2: BEAM DIAGNOSTICS AT SNAPSHOT ====================
%%  Uses the last available steady-state beam snapshot.

if exist('steady_state_beam','var') && steady_state_beam.n_total > 100

    z_ss  = steady_state_beam.z;
    r_ss  = steady_state_beam.r;
    pz_ss = steady_state_beam.pz;
    pr_ss = steady_state_beam.pr;
    pt_ss = steady_state_beam.ptheta;
    gm_ss = steady_state_beam.gamma;
    t_ss  = steady_state_beam.time;

    pm_ss  = sqrt(pz_ss.^2 + pr_ss.^2 + pt_ss.^2);
    KE_ss  = (gm_ss - 1) * 0.511;   % MeV

    figure('Name','Beam Diagnostics', ...
           'Position',[100 100 1400 800]);

    %% --- Beam envelope (RMS radius vs z) ---
    subplot(2,3,1);
    n_env_bins = 90;
    z_edges    = linspace(0, 8.31, n_env_bins+1);
    z_centers  = 0.5*(z_edges(1:end-1) + z_edges(2:end));
    r_rms_env  = zeros(n_env_bins, 1);
    for ib = 1:n_env_bins
        in_b = z_ss >= z_edges(ib) & z_ss < z_edges(ib+1);
        if sum(in_b) > 5
            r_rms_env(ib) = sqrt(mean(r_ss(in_b).^2)) * 1000;  % mm
        end
    end
    r_rms_env(r_rms_env == 0) = NaN;
    plot(z_centers*1000, r_rms_env, 'bo-', 'MarkerSize', 3, 'LineWidth', 1);
    hold on;
    yline(75,  'k--', 'Wall',   'LabelHorizontalAlignment','left');
    yline(50,  'r--', 'Target 50mm', 'LabelHorizontalAlignment','left');
    xlabel('z position (mm)');  ylabel('RMS radius (mm)');
    title(sprintf('Beam Envelope at t=%.1f ns', t_ss*1e9));
    xlim([0, 8310]);  ylim([0, 80]);  grid on;
    
    %% --- Longitudinal particle distribution ---
    subplot(2,3,2);
    histogram(z_ss*1000, 90, 'FaceColor', [0.2 0.4 0.8]);
    xlabel('z position (mm)');
    ylabel('Particles per 90mm slice');
    title('Longitudinal Particle Distribution');
    xlim([0, 8310]);  grid on;

    %% --- Beam current along z ---
    subplot(2,3,3);
    vz_ss      = pz_ss ./ (gm_ss * m_e);
    dz_bin     = (8.310 - 0) / 90;
    [n_z, ~]   = histcounts(z_ss, linspace(0, 8.31, 91));
    I_along_z  = n_z * mean(weight_particles(weight_particles>0)) * ...
                  e_charge .* (vz_ss(1) / dz_bin);  % approximate
    %% More accurate: weight-sum per bin
    I_z_wt = zeros(90,1);
    z_bin_edges = linspace(0, 8.31, 91);
    for ib = 1:90
        in_b = z_ss >= z_bin_edges(ib) & z_ss < z_bin_edges(ib+1);
        if any(in_b)
            vz_b     = abs(pz_ss(in_b) ./ (gm_ss(in_b) * m_e));
            I_z_wt(ib) = sum(weight_particles( ...
                find(active_particles,1):end) * 0 ) ;
            %% Use direct weight sum
            w_b = weight_particles(1:n_created);
            w_b = w_b(w_b > 0);
            w_mean = mean(w_b);
            I_z_wt(ib) = sum(in_b) * w_mean * e_charge .* ...
                          mean(vz_b) / (z_bin_edges(ib+1) - z_bin_edges(ib));
        end
    end
    z_bin_centers = 0.5*(z_bin_edges(1:end-1) + z_bin_edges(2:end));
    plot(z_bin_centers*1000, I_z_wt, 'gs-', 'MarkerSize', 3, 'LineWidth', 1);
    xlabel('z position (mm)');  ylabel('Current (A)');
    title('Beam Current Along z');
    xlim([0 8310]);  grid on;

    %% --- Energy vs position ---
    subplot(2,3,4);
    n_e_bins   = 90;
    KE_vs_z    = zeros(n_e_bins, 1);
    for ib = 1:n_e_bins
        in_b = z_ss >= z_edges(ib) & z_ss < z_edges(ib+1);
        if sum(in_b) > 5
            KE_vs_z(ib) = mean(KE_ss(in_b));
        end
    end
    KE_vs_z(KE_vs_z == 0) = NaN;
    plot(z_centers*1000, KE_vs_z, 'r^-', 'MarkerSize', 3, 'LineWidth', 1);
    hold on;
    yline(1.70, 'k--', 'Expected 1.7 MeV', 'LabelHorizontalAlignment','left');
    xlabel('z position (mm)');  ylabel('Mean Energy (MeV)');
    title('Energy vs Position');
    xlim([0 8310]);  ylim([0 2.0]);  grid on;

    %% --- Slice emittance ---
    subplot(2,3,5);
    emit_vs_z  = zeros(n_env_bins, 1);
    for ib = 1:n_env_bins
        in_b = z_ss >= z_edges(ib) & z_ss < z_edges(ib+1);
        if sum(in_b) > 20
            r_b  = r_ss(in_b);
            pr_b = pr_ss(in_b) ./ (gm_ss(in_b) * m_e * c);
            r_b  = r_b  - mean(r_b);
            pr_b = pr_b - mean(pr_b);
            emit_vs_z(ib) = sqrt(max(0, mean(r_b.^2)*mean(pr_b.^2) - ...
                                        mean(r_b.*pr_b)^2)) * 1e6;  % mm-mrad
        end
    end
    emit_vs_z(emit_vs_z == 0) = NaN;
    plot(z_centers*1000, emit_vs_z, 'm^-', 'MarkerSize', 3, 'LineWidth', 1);
    xlabel('z position (mm)');
    ylabel('Geometric Emittance (mm-mrad)');
    title('Slice Emittance');
    xlim([0 8310]);  grid on;

    %% --- 2D particle density ---
    subplot(2,3,6);
    z_edges_2d = linspace(0, 8.31, 100);
    r_edges_2d = linspace(0, 0.080, 50);
    density_2d = histcounts2(z_ss, r_ss, z_edges_2d, r_edges_2d);
    z_c2d = 0.5*(z_edges_2d(1:end-1) + z_edges_2d(2:end)) * 1000;
    r_c2d = 0.5*(r_edges_2d(1:end-1) + r_edges_2d(2:end)) * 1000;
    imagesc(z_c2d, r_c2d, log10(density_2d' + 1));
    set(gca,'YDir','normal');
    colorbar;  colormap(gca, 'jet');
    hold on;
    yline(75, 'w--', 'Wall',  'LineWidth', 1.5);
    xline(254, 'w:', 'Anode', 'LineWidth', 1.0);
    xlabel('z (mm)');  ylabel('r (mm)');
    title('2D Particle Density (Log Scale)', 'FontSize', 14, 'FontWeight', 'bold');
    clabel_str = 'log_{10}(Particle Count +1)';
    cb = colorbar;  cb.Label.String = clabel_str;

    sgtitle(sprintf('Pierce Gun PIC V3 — t = %.1f ns', t_ss*1e9), ...
            'FontSize', 14, 'FontWeight', 'bold');

end  %% steady_state_beam exists
%%%%%%%%%%%%%%%%%%%%%%%% Stand alone plot 2,3,6 %%%%%%%%%%%%%%%%%%%%%%
    figure('Name','Beam Diagnostics', ...
           'Position',[100 100 1800 400]);
        z_edges_2d = linspace(0, 8.31, 100);
    r_edges_2d = linspace(0, 0.080, 50);
    density_2d = histcounts2(z_ss, r_ss, z_edges_2d, r_edges_2d);
    z_c2d = 0.5*(z_edges_2d(1:end-1) + z_edges_2d(2:end)) * 1000;
    r_c2d = 0.5*(r_edges_2d(1:end-1) + r_edges_2d(2:end)) * 1000;
    imagesc(z_c2d, r_c2d, log10(density_2d' + 1));
    set(gca,'YDir','normal');
    colorbar;  colormap(gca, 'jet');
    hold on;
    yline(75, 'w--', 'Wall',  'LineWidth', 1.5);
    xline(254, 'w--', 'Anode', 'LineWidth', 1.5);
    xlabel('z (mm)');  ylabel('r (mm)');
    title('2D Particle Density (Log Scale)','FontSize', 14, 'FontWeight', 'bold');
    clabel_str = 'log_{10}(Particle Count +1)';
    cb = colorbar;  cb.Label.String = clabel_str;

    %sgtitle(sprintf('Pierce Gun PIC V3 — t = %.1f ns', t_ss*1e9), ...
    %        'FontSize', 14, 'FontWeight', 'bold');
%%%%%%%%%%%%%%%%%%%%%%%% ^ Stand alone plot 2,3,6 ^ %%%%%%%%%%%%%%%%%%%%%%

%% ==================== PLOT 3: KE HISTOGRAMS AT CROSSINGS ====================
if sum(mask_anode) > 10 || sum(mask_exit) > 10
    figure('Name','KE at Crossing Planes','Position',[150 150 900 400]);

    subplot(1,2,1);
    if sum(mask_anode) > 10
        histogram(KE_an, 50, 'FaceColor', [0.2 0.5 0.9]);
        xline(mean(KE_an), 'r--', sprintf('mean=%.3f MeV', mean(KE_an)), ...
              'LineWidth', 1.5);
        xline(1.694, 'k--', 'Expected 1.694 MeV', 'LineWidth', 1.0);
    end
    %% Add spread annotation
    sigma_an = std(KE_an);
    FWHM_an  = 2.355 * sigma_an;
    text(0.05, 0.90, ...
         sprintf('σ = %.4f MeV\nFWHM = %.4f MeV\nΔE/E = %.2f%%', ...
                 sigma_an, FWHM_an, 100*sigma_an/mean(KE_an)), ...
         'Units','normalized', 'FontSize', 10, ...
         'BackgroundColor','white', 'EdgeColor','black');
    xlabel('KE (MeV)');  ylabel('Count');
    title('KE at Anode (z=254mm)');  grid on;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% NEW_SUBPLOT (1,2,2) %%%%%%%%%%%%%%%%%%%%%%%%%
    %% Enhanced KE at exit annotation
  subplot(1,2,2);
  if sum(mask_exit) > 10
    histogram(KE_ex, 50, 'FaceColor', [0.2 0.8 0.4]);
    xline(mean(KE_ex), 'r--', ...
          sprintf('mean=%.4f MeV', mean(KE_ex)), 'LineWidth', 1.5);
    xline(1.694, 'k--', 'Expected 1.694 MeV', 'LineWidth', 1.0);

    %% Add spread annotation
    sigma_ex = std(KE_ex);
    FWHM_ex  = 2.355 * sigma_ex;
    text(0.05, 0.90, ...
         sprintf('σ = %.4f MeV\nFWHM = %.4f MeV\nΔE/E = %.2f%%', ...
                 sigma_ex, FWHM_ex, 100*sigma_ex/mean(KE_ex)), ...
         'Units','normalized', 'FontSize', 10, ...
         'BackgroundColor','white', 'EdgeColor','black');
   end
   xlabel('KE (MeV)');  ylabel('Count');
   title('KE at Exit (z=8305mm)');  grid on;
end

%%%%%%%%%%%%%%%%%%%%%%%%%% NEW SAVE WORKSPACE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== SAVE WORKSPACE ====================
fprintf('\nSaving results...\n');
save_fname = sprintf('Pierce_Gun_V3_results_%s.mat', ...
                     datestr(now,'yyyymmdd_HHMMSS'));

if ENABLE_MULTIPULSE == false
save(save_fname, ...
    'I_cathode', 'I_anode', 'I_exit', 'I_monitor', ...
    'collection_efficiency', 'n_active_history', ...
    'particle_crossed_anode', 'particle_crossed_exit', ...
    'particle_t_at_anode',    'particle_t_at_exit', ...
    'particle_KE_at_anode',   'particle_KE_at_exit', ...
    'particle_r_at_anode', ...
    'particles_at_anode', 'particles_transmitted', ...
    'particles_lost_to_cathode', 'particles_lost_to_walls', ...
    'particles_out_of_bounds',   'n_created', ...
    'r_rms_history', 'n_particles_vs_z', 'z_diagnostic', ...
    'snapshot_data', 'snapshot_early', 'snapshot_late', 'snapshot_p1', ...
    'schottky_diagnostics', 'ion_diag', 'ion_density_grid', ...
    'ANALYSIS_LOCATIONS', 'ANALYSIS_LOCATION_NAMES', ...
    't', 'dt', 'nt', 't_start', 't_end', ...
    'max_sc_field_recorded', '-v7.3');
else
    save(save_fname, ...
    'I_cathode', 'I_anode', 'I_exit', 'I_monitor', ...
    'collection_efficiency', 'n_active_history', ...
    'particle_crossed_anode', 'particle_crossed_exit', ...
    'particle_t_at_anode',    'particle_t_at_exit', ...
    'particle_KE_at_anode',   'particle_KE_at_exit', ...
    'particle_r_at_anode', ...
    'particles_at_anode', 'particles_transmitted', ...
    'particles_lost_to_cathode', 'particles_lost_to_walls', ...
    'particles_out_of_bounds',   'n_created', ...
    'r_rms_history', 'n_particles_vs_z', 'z_diagnostic', ...
    'snapshot_data', 'snapshot_p1', 'snapshot_p2', ...
    'schottky_diagnostics', 'ion_diag', 'ion_density_grid', ...
    'ANALYSIS_LOCATIONS', 'ANALYSIS_LOCATION_NAMES', ...
    't', 'dt', 'nt', 't_start', 't_end', ...
    'max_sc_field_recorded', '-v7.3');
end

%% Save steady_state_beam separately if it exists
if exist('steady_state_beam','var')
    save(save_fname, 'steady_state_beam', '-append');
end

fprintf('Saved to: %s\n', save_fname);
%%%%%%%%%%%%%%%%%%%%%%%%%% Fifth section end %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%% Updated Validation Block 01.28.2026 %%%%%%%%%%%%%%%%%
%% ==================== POST-PROCESSING VALIDATION ====================
fprintf('\n=================================================================\n');
fprintf('  POST-PROCESSING VALIDATION                                     \n');
fprintf('=================================================================\n');

% ... validation code ...

% SINGLE corrected block for PLOTS_AVAILABLE
PLOTS_AVAILABLE = struct();
PLOTS_AVAILABLE.pulse1_snapshot = exist('steady_state_beam', 'var');
PLOTS_AVAILABLE.pulse1_twiss = exist('twiss_results', 'var');
PLOTS_AVAILABLE.pulse1_slices = exist('slice_data', 'var');
PLOTS_AVAILABLE.schottky_diag = exist('schottky_diagnostics', 'var');

if ENABLE_MULTIPULSE == true
    PLOTS_AVAILABLE.pulse2_snapshot = exist('steady_state_beam_pulse2', 'var');
    PLOTS_AVAILABLE.pulse2_twiss = exist('twiss_results_pulse2', 'var');
    PLOTS_AVAILABLE.interpulse_cloud = exist('interpulse_electron_cloud', 'var');
    PLOTS_AVAILABLE.betatron_averaging = (snapshot_p1_count == N_SNAPSHOTS) && ...
                                         (snapshot_p2_count == N_SNAPSHOTS);
    
    % Validate Pulse 2 was actually simulated
    if t(end) < 400e-9
        fprintf('\nWARNING: Simulation ended before Pulse 2 completed!\n');
        PLOTS_AVAILABLE.pulse2_snapshot = false;
        PLOTS_AVAILABLE.pulse2_twiss = false;
    end
else
    % Single-pulse mode
    PLOTS_AVAILABLE.pulse2_snapshot = false;
    PLOTS_AVAILABLE.pulse2_twiss = false;
    PLOTS_AVAILABLE.interpulse_cloud = false;
    % ✅ Use the CORRECT counters for single-pulse mode
    PLOTS_AVAILABLE.betatron_averaging = (snapshot_early_count == N_SNAPSHOTS_EARLY) && ...
                                         (snapshot_late_count == N_SNAPSHOTS_LATE);
end

if ENABLE_ION_ACCUMULATION == true
    PLOTS_AVAILABLE.ion_data = exist('ion_diag', 'var');
else
    PLOTS_AVAILABLE.ion_data = false;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ================= ELASTIC GAS SCATTERING DIAGNOSTICS ====================
if ENABLE_GAS_SCATTERING && scatter_diag.event_count > 0
    fprintf('\n=== GAS SCATTERING SUMMARY ===\n');
    fprintf('Method: %s\n', SCATTERING_METHOD);
    fprintf('Total scatter events: %d\n', scatter_diag.event_count);
    fprintf('Scattering rate: %.2f events/electron\n', ...
            scatter_diag.event_count/n_created);
    
    if strcmp(SCATTERING_METHOD, 'HYBRID')
        fprintf('Large-angle events: %d (%.1f%%)\n', ...
                scatter_diag.rare_count, ...
                100*scatter_diag.rare_count/scatter_diag.event_count);
    end
    
    % Analyze angle distribution
    if ~isempty(scatter_diag.theta_history)
        theta_abs = abs(scatter_diag.theta_history);
        fprintf('\nScattering angle distribution:\n');
        fprintf('  Mean: %.3f µrad\n', mean(theta_abs)*1e6);
        fprintf('  RMS: %.3f µrad\n', std(theta_abs)*1e6);
        fprintf('  Max: %.3f mrad\n', max(theta_abs)*1e3);
        fprintf('  Median: %.3f µrad\n', median(theta_abs)*1e6);
        
        % Check for large deflections
        large_deflections = theta_abs > 1e-3;  % > 1 mrad
        if any(large_deflections)
            fprintf('  Events >1 mrad: %d (%.2f%%)\n', ...
                    sum(large_deflections), ...
                    100*sum(large_deflections)/length(theta_abs));
        end
    end
    
    % Spatial distribution of scattering
    if ~isempty(scatter_diag.z_scatter_positions)
        fprintf('\nScattering spatial distribution:\n');
        fprintf('  First event at z=%.1f mm\n', min(scatter_diag.z_scatter_positions)*1000);
        fprintf('  Last event at z=%.1f mm\n', max(scatter_diag.z_scatter_positions)*1000);
        fprintf('  Mean position z=%.1f mm\n', mean(scatter_diag.z_scatter_positions)*1000);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FIGURE 1 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % Create scattering diagnostics figure
    figure('Position', [100, 100, 1400, 600], 'Name', 'Gas Scattering Diagnostics');
    
    % Angle distribution
    subplot(1,3,1);
    histogram(scatter_diag.theta_history*1e6, 50, 'EdgeColor', 'none');
    xlabel('Scattering Angle (µrad)');
    ylabel('Frequency');
    title('Scattering Angle Distribution');
    grid on;
    
    % Spatial distribution
    subplot(1,3,2);
    histogram(scatter_diag.z_scatter_positions*1000, 30, 'EdgeColor', 'none');
    xlabel('z position (mm)');
    ylabel('Scatter Events');
    title('Scattering Event Locations');
    grid on;
    xlim([0 8310]);
    
    % Cumulative scattering probability

    %%%%%%%%%%%%%%%%%%%%% Fixed Summary for the plot 1 %%%%%%%%%%%%%%%%%%%%%%%%
    %% Fix the Summary in the plot
     subplot(1,3,3);
    axis off;
    text(0.1, 0.90, 'SCATTERING SUMMARY', 'FontWeight','bold','FontSize',14);
    text(0.1, 0.76, sprintf('Method: %s', SCATTERING_METHOD));
    text(0.1, 0.66, sprintf('Total events: %d', scatter_diag.event_count));
    text(0.1, 0.56, sprintf('Events/electron: %.4f', ...
                             scatter_diag.event_count / max(n_created,1)));

    if ~isempty(scatter_diag.theta_history)
        th = scatter_diag.theta_history;
        text(0.1, 0.46, sprintf('Mean angle: %.2f µrad',  mean(abs(th))*1e6));
        text(0.1, 0.36, sprintf('RMS angle:  %.2f µrad',  std(th)*1e6));
        text(0.1, 0.26, sprintf('Max angle:  %.2f mrad',  max(abs(th))*1e3));
        large_th = sum(abs(th) > 1e-3);
        text(0.1, 0.16, sprintf('Events >1 mrad: %d (%.2f%%)', ...
                                 large_th, 100*large_th/max(length(th),1)));
    else
        text(0.1, 0.46, 'Mean angle: no data', 'Color','red');
        text(0.1, 0.36, 'RMS angle:  no data', 'Color','red');
    end

    expected_loss = scatter_diag.event_count / max(n_created,1) * 0.1;
    text(0.1, 0.08, sprintf('Expected loss: ~%.2f%%', expected_loss*100));
    text(0.1, 0.02, sprintf('Actual transmission: %.1f%%', ...
                             100*particles_transmitted/max(n_created,1)), ...
         'FontWeight','bold');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== SCATTERING HALO ANALYSIS ====================
if ENABLE_GAS_SCATTERING && scatter_diag.event_count > 0
    % Estimate halo contribution from scattering
    % Assume large-angle scatters (>100 µrad) reach halo region
    large_angle_threshold = 100e-6;  % 100 µrad
    halo_scatters = sum(abs(scatter_diag.theta_history) > large_angle_threshold);
    
    fprintf('\n=== SCATTERING HALO CONTRIBUTION ===\n');
    fprintf('Large-angle scatters (>100µrad): %d\n', halo_scatters);
    fprintf('Potential halo particles: %d (%.2f%% of scattered)\n', ...
            halo_scatters, 100*halo_scatters/scatter_diag.event_count);
    fprintf('Fraction of total beam: %.3f%%\n', ...
            100*halo_scatters/n_created);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\n*** NOTE: Elevated pressure for demonstration ***\n');
fprintf('Operational accelerators run at 1e-9 to 1e-7 mbar\n');
fprintf('This %e mbar demonstrates scattering physics\n', gas_params.P/133.322);
fprintf('At operational pressure, scattering contributes ~0.01%% to halo\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Add after line 500 (after main loop ends)
fprintf('\n=== Diagnostic Data Check ===\n');
total_rms_points = sum(r_rms_history(:) > 0);
fprintf('Total RMS data points collected: %d\n', total_rms_points);
if total_rms_points == 0
    fprintf('WARNING: No RMS radius data was collected!\n');
    fprintf('Check that diag_interval (%d) matches data collection\n', diag_interval);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== ANALYSIS ====================
computation_time = toc(tic_start);
fprintf('\nDone!\n');
fprintf('\n=== Performance ===\n');
fprintf('  Runtime: %.1f seconds (%.2f min)\n', computation_time, computation_time/60);
fprintf('  Speed: %.1f steps/sec\n', nt/computation_time);

fprintf('\n=== Results ===\n');
fprintf('  Particles created: %d\n', n_created);
fprintf('  At anode: %d (%.1f%%)\n', particles_at_anode, ...
        100*particles_at_anode/max(1, n_created));
fprintf('  Transmitted to 2760mm: %d (%.1f%%)\n', particles_transmitted, ...
        100*particles_transmitted/max(1, particles_at_anode));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% added 11.11.2025 %%%%%%%%%%%%%%%%%%%%5%%%%%%%%%%%%%%%
% ===== ADD THIS BLOCK HERE =====
%% ==================== MULTI-PULSE ANALYSIS ====================
if ENABLE_MULTIPULSE == true
    fprintf('\n=== PER-PULSE ANALYSIS ===\n');
    
    for ip = 1:pulse_config.n_pulses
        % Find particles from this pulse
        from_this_pulse = (particle_source_pulse(:) == ip);
        
        % Count emitted
        pulse_diagnostics(ip).particles_emitted = sum(from_this_pulse);
        
        % Count transmitted (crossed exit at z=8.310m)
        transmitted_this_pulse = from_this_pulse & particle_crossed_exit(:);
        pulse_diagnostics(ip).particles_transmitted = sum(transmitted_this_pulse);
        
        % Count at anode
        at_anode_this_pulse = from_this_pulse & particle_crossed_anode(:);
        pulse_diagnostics(ip).particles_at_anode = sum(at_anode_this_pulse);
        
        % Calculate efficiencies
        if pulse_diagnostics(ip).particles_emitted > 0
            efficiency_anode = 100 * pulse_diagnostics(ip).particles_at_anode / ...
                              pulse_diagnostics(ip).particles_emitted;
            efficiency_exit = 100 * pulse_diagnostics(ip).particles_transmitted / ...
                             pulse_diagnostics(ip).particles_emitted;
        else
            efficiency_anode = 0;
            efficiency_exit = 0;
        end
        
        % Print results
        fprintf('\nPulse %d (t = %.1f ns):\n', ip, pulse_config.pulse_starts(ip)*1e9);
        fprintf('  Emitted: %d particles\n', pulse_diagnostics(ip).particles_emitted);
        fprintf('  Reached anode: %d (%.1f%%)\n', ...
                pulse_diagnostics(ip).particles_at_anode, efficiency_anode);
        fprintf('  Transmitted to exit: %d (%.1f%%)\n', ...
                pulse_diagnostics(ip).particles_transmitted, efficiency_exit);
    end
    
    % Pulse-to-pulse comparison
    if pulse_config.n_pulses >= 2
        fprintf('\n=== PULSE-TO-PULSE COMPARISON ===\n');
        eff1 = 100 * pulse_diagnostics(1).particles_transmitted / ...
               pulse_diagnostics(1).particles_emitted;
        eff2 = 100 * pulse_diagnostics(2).particles_transmitted / ...
               pulse_diagnostics(2).particles_emitted;
        
        fprintf('  Pulse 1 efficiency: %.2f%%\n', eff1);
        fprintf('  Pulse 2 efficiency: %.2f%%\n', eff2);
        fprintf('  Difference: %.2f%% (pulse 2 - pulse 1)\n', eff2 - eff1);
        
        if abs(eff2 - eff1) > 1.0
            fprintf('  WARNING: Significant pulse-to-pulse variation!\n');
            if eff2 > eff1
                fprintf('  Suggestion: Reduce pulse 2 voltage to equalize\n');
            else
                fprintf('  Suggestion: Increase pulse 2 voltage to equalize\n');
            end
        end
    end
end
% ===== END OF ADDITION =====
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% added 10.16.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== LONGITUDINAL SLICE ANALYSIS (AT STEADY STATE) ====================
% Place this AFTER the main loop ends, using the saved steady_state_beam data

if exist('steady_state_beam', 'var') && steady_state_beam.n_total > 1000
    fprintf('\n=== LONGITUDINAL BEAM SLICE ANALYSIS (STEADY STATE) ===\n');
    fprintf('Analyzing beam captured at t=%.1f ns (mid-pulse)\n', steady_state_beam.time*1e9);
    
    % Use steady state data instead of final beam state
    z_beam = steady_state_beam.z;
    r_beam = steady_state_beam.r;
    pr_beam = steady_state_beam.pr;
    pz_beam = steady_state_beam.pz;
    gamma_beam = steady_state_beam.gamma;
    weight_beam = steady_state_beam.weight;
    vz_beam = steady_state_beam.vz;
    
    % Debug: Show actual particle distribution
    fprintf('\n=== Particle Distribution at Steady State ===\n');
    z_bins = 0:0.1:8.3;  % 100mm bins
    [n_hist, edges] = histcounts(z_beam, z_bins);
    fprintf('First 10 bins (0-1000mm):\n');
    for i = 1:10
        fprintf('  z=%d-%d mm: %d particles\n', ...
                edges(i)*1000, edges(i+1)*1000, n_hist(i));
    end
    fprintf('  Total particles in analysis: %d\n', length(z_beam));
    
    % Define slices covering the full beamline
    slice_width = 0.090;  % 90mm slices
    slice_edges = 0:slice_width:8.3;  % 0 to 2700mm
    n_slices = length(slice_edges) - 1;
    
    % Initialize slice data structure
    clear slice_data;
    
    % Analyze each slice
    for is = 1:n_slices
        z_min = slice_edges(is);
        z_max = slice_edges(is+1);
        z_center = (z_min + z_max) / 2;
        
        % Find particles in this slice
        in_slice = z_beam >= z_min & z_beam < z_max;
        n_in_slice = sum(in_slice);
        
        slice_data(is).z_center = z_center;
        slice_data(is).z_range = [z_min, z_max];
        slice_data(is).n_particles = n_in_slice;
        
        if n_in_slice > 20  % Need minimum particles for statistics
            r_slice = r_beam(in_slice);
            pz_slice = pz_beam(in_slice);
            pr_slice = pr_beam(in_slice);
            gamma_slice = gamma_beam(in_slice);
            weight_slice = weight_beam(in_slice);
            vz_slice = vz_beam(in_slice);
            
            % Beam envelope
            slice_data(is).r_rms = sqrt(mean(r_slice.^2));
            slice_data(is).r_mean = mean(r_slice);
            slice_data(is).r_max = max(r_slice);
            
            % Energy (CORRECTED calculation)
            % Relativistic kinetic energy: E = (gamma-1)*m*c^2
            energy_joules = (gamma_slice - 1) * m_e * c^2;
            energy_MeV = energy_joules / (e_charge * 1e6);  % Convert to MeV
            slice_data(is).E_mean = mean(energy_MeV);
            slice_data(is).E_spread = std(energy_MeV);
            
            % Current calculation using actual velocities
            mean_vz = mean(abs(vz_slice));
            if mean_vz > 0
                transit_time = slice_width / mean_vz;
                total_charge = sum(weight_slice) * e_charge;
                slice_data(is).current = total_charge / transit_time;
            else
                slice_data(is).current = 0;
            end
            
            % Emittance calculation for this slice
            pr_norm = pr_slice ./ (gamma_slice * m_e * c);
            r_centered = r_slice - mean(r_slice);
            pr_centered = pr_norm - mean(pr_norm);
            
            r2_avg = mean(r_centered.^2);
            pr2_avg = mean(pr_centered.^2);
            r_pr_avg = mean(r_centered .* pr_centered);
            
            emit_rms = sqrt(r2_avg * pr2_avg - r_pr_avg^2);
            slice_data(is).emittance = emit_rms * 1e6;  % mm-mrad
            
            % Normalized emittance
            gamma_avg = mean(gamma_slice);
            beta_rel = sqrt(1 - 1/gamma_avg^2);
            slice_data(is).emittance_norm = emit_rms * gamma_avg * beta_rel * 1e6;
            
        else
            % Insufficient particles - mark as NaN
            slice_data(is).r_rms = NaN;
            slice_data(is).r_mean = NaN;
            slice_data(is).r_max = NaN;
            slice_data(is).E_mean = NaN;
            slice_data(is).E_spread = NaN;
            slice_data(is).current = 0;
            slice_data(is).emittance = NaN;
            slice_data(is).emittance_norm = NaN;
        end
        
        % Progress report for debugging
        if mod(is, 5) == 0
            fprintf('  Processed slice %d/%d: z=%.0f-%.0f mm, %d particles\n', ...
                    is, n_slices, z_min*1000, z_max*1000, n_in_slice);
        end
    end

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  FIGURE 2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 11.20.2025  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== ION ACCUMULATION DIAGNOSTICS ====================
if ENABLE_ION_ACCUMULATION
    fprintf('\n=== ION ACCUMULATION ANALYSIS ===\n');
    
    % Total ions created
    total_ions_created = sum(ion_diag.creation_history);
    fprintf('Total ionization events: %d\n', total_ions_created);
    fprintf('Ionization rate: %.4f ions/electron\n', total_ions_created/n_created);
    
    % Per-pulse breakdown
    fprintf('\nIons created per pulse:\n');
    for ip = 1:pulse_config.n_pulses
        fprintf('  Pulse %d: %d ions (%.1f%% of total)\n', ...
                ip, ion_diag.ions_per_pulse(ip), ...
                100*ion_diag.ions_per_pulse(ip)/max(1,total_ions_created));
    end
    
    % Peak metrics
    max_ion_density = max(ion_diag.peak_density_vs_time);
    max_ion_count = max(ion_diag.total_ions_vs_time);
    fprintf('\nPeak ion count in system: %d ions\n', round(max_ion_count));
    fprintf('Peak local density: %.2e ions/m³\n', max_ion_density);
    fprintf('Ratio to neutral gas density: %.2e\n', max_ion_density/gas_params.n_gas);

 %%%%%%%%%%%%%%%%%%%%%%%%  Added 01.22.2026  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
    %% QUICK FIX: Add this at the END of your V3.4 code 
%  RIGHT BEFORE the ion plotting section (around line 1050)
%  This ensures pulse_config.pulse_starts exists even in single-pulse mode

% ========== PATCH: Fix pulse_starts for single-pulse mode ==========
if ENABLE_MULTIPULSE == false
    % In single-pulse mode, ensure pulse_config has the correct structure
    if ~isfield(pulse_config, 'pulse_starts')
        fprintf('\n*** APPLYING PULSE_STARTS FIX FOR SINGLE-PULSE MODE ***\n');
        
        % Check if the old variable exists
        if exist('pulse_starts', 'var')
            pulse_config.pulse_starts = pulse_starts;
        else
            % Use default value
            pulse_config.pulse_starts = 150e-9;
        end
        
        fprintf('  Set pulse_config.pulse_starts = %.1f ns\n', ...
                pulse_config.pulse_starts*1e9);
    end
    
    % Also ensure pulse timing parameters exist
    if ~exist('pulse_rise', 'var')
        pulse_rise = 15e-9;
        pulse_flat = 80e-9;
        pulse_fall = 25e-9;
    end
end
% ========== END OF PATCH ==========

fprintf('\nPulse configuration verified for plotting:\n');
fprintf('  n_pulses: %d\n', pulse_config.n_pulses);
fprintf('  pulse_starts: ');
disp(pulse_config.pulse_starts*1e9);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Update 01.23.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== ION DATA VERIFICATION ====================
fprintf('\n=== Ion Diagnostic Data Quality Check ===\n');
fprintf('Total timesteps: %d\n', nt);
fprintf('Timesteps with ion data: %d (%.1f%%)\n', ...
        sum(ion_diag.total_ions_vs_time > 0), ...
        100*sum(ion_diag.total_ions_vs_time > 0)/nt);
fprintf('Update interval: every %d timesteps\n', sc_interval);
fprintf('Expected data points: ~%d\n', floor(nt/sc_interval));

% Check for data gaps
nonzero_idx = find(ion_diag.total_ions_vs_time > 0);
if length(nonzero_idx) > 1
    gaps = diff(nonzero_idx);
    fprintf('Time between updates: %d timesteps (%.1f ps)\n', ...
            mode(gaps), mode(gaps)*dt*1e12);
    fprintf('Data continuity: %s\n', ...
            ternary(all(gaps <= sc_interval*1.5), 'Good', 'Has large gaps'));
end

fprintf('Ion data range: %.1e to %.1e ions\n', ...
        min(ion_diag.total_ions_vs_time(ion_diag.total_ions_vs_time>0)), ...
        max(ion_diag.total_ions_vs_time));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% ==================== Figure 2 ION VISUALIZATION ====================
    figure('Position', [100, 100, 1800, 1000], 'Name', 'Ion Accumulation Diagnostics');
    
    % Plot 1: Ion creation rate vs time
    subplot(3,3,1);
    plot(t*1e9, ion_diag.creation_history, 'b-', 'LineWidth', 1.5);
    xlabel('Time (ns)');
    ylabel('Ions Created per Timestep');
    title('Ionization Rate');
    grid on;
    %xlim([145 900]);
    xlim([t_plot_min t_plot_max]);
    hold on;
    % Mark pulse boundaries
    for ip = 1:pulse_config.n_pulses
        t_p = pulse_config.pulse_starts(ip)*1e9;
        xline(t_p, 'r--', sprintf('P%d', ip), 'LineWidth', 1.5);
    end  

%%%%%%%%%%%%%%%%%%%%%%%%%% Updated Plot (3,3,2) V1 01.23.2026 %%%%%%%%%%%%%%%%%%%
%% ==================== FIXED ION ACCUMULATION PLOT ====================
% Plot 2: Total ions in system (accumulation + recombination)
subplot(3,3,2);

% METHOD 1: Filter to non-zero values only
nonzero_idx = ion_diag.total_ions_vs_time > 0;

if sum(nonzero_idx) > 2  % Need at least a few points to plot
    t_nonzero = t(nonzero_idx) * 1e9;  % ns
    ions_nonzero = ion_diag.total_ions_vs_time(nonzero_idx);
    
    % Plot with markers to show actual data points
    semilogy(t_nonzero, ions_nonzero, 'r-o', 'LineWidth', 2, 'MarkerSize', 4);
    
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('Total Ions in System', 'FontSize', 12);
    title('Ion Accumulation with Recombination', 'FontSize', 14);
    grid on;
    %xlim([145 900]);
    xlim([t_plot_min t_plot_max]);
    % Set explicit y-limits based on actual data
    ylim([min(ions_nonzero(ions_nonzero>0))*0.5, max(ions_nonzero)*2]);
    
    hold on;
    
    % Add pulse markers
    for ip = 1:pulse_config.n_pulses
        t_p = pulse_config.pulse_starts(ip)*1e9;
        xline(t_p, 'k--', 'LineWidth', 1.5);
    end
    
    % Add annotation showing data sparsity
    text(0.6, 0.95, sprintf('%d data points', sum(nonzero_idx)), ...
         'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
    text(0.6, 0.88, sprintf('Update interval: %d steps', sc_interval), ...
         'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
    
else
    % No ion data available
    text(0.5, 0.5, 'No ion accumulation data', 'FontSize', 14, ...
         'HorizontalAlignment', 'center');
    axis off;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot 3: Peak local ion density
    subplot(3,3,3);
    plot(t*1e9, ion_diag.peak_density_vs_time, 'm-', 'LineWidth', 1.5);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('Peak Ion Density (ions/m³)', 'FontSize', 12);
    title('Peak Local Ion Density', 'FontSize', 14);
    grid on;
    %xlim([145 900]);
    xlim([t_plot_min t_plot_max]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot 4: Ion spatial distribution at Pulse 1 end (t=270ns)
    subplot(3,3,4);
    [~, it_p1_end] = min(abs(t - 270e-9));
    % Extract ion distribution from history
    % Since we don't save full grid history, use final distribution
    % For better diagnostics, we should save snapshots
    
    % Show final ion distribution
    imagesc(sc_z*1000, sc_r*1000, log10(ion_density_grid + 1));
    axis xy;
    colorbar;
    xlabel('z (mm)');
    ylabel('r (mm)');
    title('Final Ion Distribution (log scale)');
    hold on;
    plot([254 254], [0 sc_r_max*1000], 'w--', 'LineWidth', 1.5);
    plot([0 8310], [75 75], 'w--', 'LineWidth', 1.5);  % White line for better contrast
    text(800, 70, 'Wall', 'Color', 'white', 'FontSize', 8);
    text(280, 62, 'Anode', 'Color', 'white', 'FontSize', 8);
    xlim([0 8310]);
    ylim([0 80]);

    % Plot 5: Longitudinal ion profile
    subplot(3,3,5);
    ion_longitudinal = sum(ion_density_grid, 1);  % Sum over r
    plot(sc_z*1000, ion_longitudinal, 'b-', 'LineWidth', 2);
    xlabel('z (mm)');
    ylabel('Ions (summed over r)');
    title('Longitudinal Ion Distribution');
    grid on;
    xlim([0 8310]);
    hold on;
    xline(254, 'r--', 'Anode', 'LineWidth', 1.5);
    
    % Plot 6: Radial ion profile (at peak density location)
    subplot(3,3,6);
    [~, iz_peak] = max(ion_longitudinal);
    ion_radial = ion_density_grid(:, iz_peak);
    plot(sc_r*1000, ion_radial, 'r-', 'LineWidth', 2);
    xlabel('r (mm)');
    ylabel('Ion Count');
    title(sprintf('Radial Profile at z=%.0f mm', sc_z(iz_peak)*1000));
    grid on;
    xlim([0 75]);
    
    % Plot 7: Ion contribution to space charge field
    subplot(3,3,7);
    % Calculate ion-only SC field (approximate)
    ion_charge_density_max = max(ion_density_grid(:)) * e_charge / ...
                             (pi * (sc_dr)^2 * sc_dz);  % Rough estimate
    ion_field_estimate = ion_charge_density_max / (2*eps0) * 0.05;  % Characteristic field
    
    bar([1 2], [max(sc_field_max)/1e6, ion_field_estimate/1e3]);
    set(gca, 'XTickLabel', {'Electron SC (MV/m)', 'Ion SC (kV/m)'});
    ylabel('Peak Field Magnitude');
    title('Space Charge Field Comparison');
    grid on;
    
    % Plot 8: Per-pulse ion contributions
    subplot(3,3,8);
    bar(1:pulse_config.n_pulses, ion_diag.ions_per_pulse);
    xlabel('Pulse Number');
    ylabel('Ions Created');
    title('Ionization by Source Pulse');
    grid on;
    
    % Plot 9: Summary text
    subplot(3,3,9);
    axis off;
    text(0.1, 0.9, 'ION SUMMARY', 'FontWeight', 'bold', 'FontSize', 14);
    text(0.1, 0.75, sprintf('Total ionizations: %d', total_ions_created));
    text(0.1, 0.65, sprintf('Rate: %.4f ions/e⁻', total_ions_created/n_created));
    text(0.1, 0.55, sprintf('Peak count: %d ions', round(max_ion_count)));
    text(0.1, 0.45, sprintf('Peak density: %.2e /m³', max_ion_density));
    
    text(0.1, 0.30, 'Expected focusing effect:', 'FontWeight', 'bold');
    % Estimate ion lens strength
    ion_lens_strength = ion_field_estimate / 1.7e6;  % Ratio to beam energy
    text(0.1, 0.20, sprintf('Ion field/Beam energy: %.2e', ion_lens_strength));
    text(0.1, 0.10, sprintf('Expected Δr: ~%.2f mm', ion_lens_strength*50*1000), ...
         'Color', 'red');
    
    sgtitle('Ion Accumulation and Space Charge Effects', 'FontSize', 16);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 3 updated 11.24.2025 %%%%%%%%%%%%%%%%%%%%%%%%%
%% Enhanced Ion Accumulation Diagnostics - FIXED VERSION
% Replace the ion visualization figure (around line 1025) with this corrected version
% This fixes empty plots and improves contrast

if ENABLE_ION_ACCUMULATION
    fprintf('\n=== ION ACCUMULATION ANALYSIS ===\n');
    
    % Total ions created
    total_ions_created = sum(ion_diag.creation_history);
    fprintf('Total ionization events: %d\n', total_ions_created);
    fprintf('Ionization rate: %.4f ions/electron\n', total_ions_created/n_created);
    
    % Per-pulse breakdown
    fprintf('\nIons created per pulse:\n');
    for ip = 1:pulse_config.n_pulses
        fprintf('  Pulse %d: %d ions (%.1f%% of total)\n', ...
                ip, ion_diag.ions_per_pulse(ip), ...
                100*ion_diag.ions_per_pulse(ip)/max(1,total_ions_created));
    end
    
    % Peak metrics
    max_ion_density = max(ion_diag.peak_density_vs_time);
    max_ion_count = max(ion_diag.total_ions_vs_time);
    fprintf('\nPeak ion count in system: %d ions\n', round(max_ion_count));
    fprintf('Peak local density: %.2e ions/m³\n', max_ion_density);
    fprintf('Ratio to neutral gas density: %.2e\n', max_ion_density/gas_params.n_gas);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% ========================= ENHANCED ION VISUALIZATION =============================
    figure('Position', [100, 100, 1800, 1200], 'Name', 'Ion Accumulation Diagnostics - Enhanced');
    
    % Plot 1: Ion creation rate vs time
    subplot(3,3,1);
    plot(t*1e9, ion_diag.creation_history, 'b-', 'LineWidth', 1.5);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('Ions Created per Timestep', 'FontSize', 12);
    title('Ionization Rate', 'FontSize', 14);
    grid on;
    %xlim([145 900]);
    xlim([t_plot_min t_plot_max]);
    hold on;
    for ip = 1:pulse_config.n_pulses
        t_p = pulse_config.pulse_starts(ip)*1e9;
       xline(t_p, 'r--', sprintf('P%d', ip), 'LineWidth', 1.5);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%% Updated Plot (3,3,2) V3 01.23.2026 %%%%%%%%%%%%%%%%%%%%    
%% ==================== FIXED ION ACCUMULATION PLOT ====================
% Plot 2: Total ions in system (accumulation + recombination) - FIXED
    subplot(3,3,2);
    
    % Filter out zeros for clean semilogy plot
    nonzero_mask = ion_diag.total_ions_vs_time > 0;
    
    if sum(nonzero_mask) > 2
        % Plot smooth curve (now that we update every timestep)
        semilogy(t(nonzero_mask)*1e9, ion_diag.total_ions_vs_time(nonzero_mask), ...
                 'r-', 'LineWidth', 2.5);
        
        xlabel('Time (ns)', 'FontSize', 12);
        ylabel('Total Ions in System', 'FontSize', 12);
        title('Ion Accumulation with Recombination', 'FontSize', 14);
        grid on;
        %xlim([145 900]);
        xlim([t_plot_min t_plot_max]);
        % Set intelligent y-limits
        min_ions = min(ion_diag.total_ions_vs_time(nonzero_mask));
        max_ions = max(ion_diag.total_ions_vs_time(nonzero_mask));
        ylim([min_ions*0.3, max_ions*3]);
        
        hold on;
        
        % Add pulse markers
        for ip = 1:pulse_config.n_pulses
            t_p = pulse_config.pulse_starts(ip)*1e9;
            xline(t_p, 'k--', 'LineWidth', 1.5, 'Alpha', 0.7);
        end
        
        % Add annotations
        text(0.05, 0.95, sprintf('Peak: %.1e ions', max_ions), ...
             'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
        text(0.05, 0.88, sprintf('Final: %.1e ions', ...
             ion_diag.total_ions_vs_time(find(nonzero_mask, 1, 'last'))), ...
             'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
        
        % Show recombination time constant
        text(0.55, 0.15, sprintf('τ_{recomb} = %.0f µs', ion_physics.t_recomb_effective*1e6), ...
             'Units', 'normalized', 'FontSize', 9, 'Color', [0.5 0.5 0.5]);
        
    else
        % Fallback: no ion data
        text(0.5, 0.5, 'No ion accumulation detected', ...
             'HorizontalAlignment', 'center', 'FontSize', 14, 'Color', 'red');
        text(0.5, 0.4, sprintf('(Pressure: %.1e mbar)', gas_params.P/133.322), ...
             'HorizontalAlignment', 'center', 'FontSize', 11);
        axis([145 500 0 1]);
    end
   
%%%%%%%%%%%%%%%%%%%%%%%%% Updated 01.23.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   % Plot 3: Peak local ion density - FIXED
    subplot(3,3,3);
    
    nonzero_mask_peak = ion_diag.peak_density_vs_time > 0;
    
    if sum(nonzero_mask_peak) > 2
        semilogy(t(nonzero_mask_peak)*1e9, ion_diag.peak_density_vs_time(nonzero_mask_peak), ...
                 'm-', 'LineWidth', 2.5);
        
        xlabel('Time (ns)', 'FontSize', 12);
        ylabel('Peak Ion Density (ions/m³)', 'FontSize', 12);
        title('Peak Local Ion Density', 'FontSize', 14);
        grid on;
        %xlim([145 900]);
        xlim([t_plot_min t_plot_max]);
        % Set reasonable y-limits
        min_density = min(ion_diag.peak_density_vs_time(nonzero_mask_peak));
        max_density = max(ion_diag.peak_density_vs_time(nonzero_mask_peak));
        ylim([min_density*0.3, max_density*3]);
        
        % Add reference line for gas density
        hold on;
        yline(gas_params.n_gas, 'b--', 'LineWidth', 1.5, 'Alpha', 0.5, ...
              'Label', 'Neutral gas density');
        
    else
        text(0.5, 0.5, 'No peak density data', 'HorizontalAlignment', 'center', ...
             'FontSize', 14, 'Color', 'red');
        axis([145 500 0 1]);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % Plot 4: IMPROVED Final ion distribution with better contrast
    subplot(3,3,4);
    
    % Create custom colormap with better contrast for low values
    custom_cmap = [
        0 0 0.2;         % Dark blue for zero
        0 0 0.5;         % Blue
        0 0.3 0.8;       % Lighter blue
        0 0.6 1;         % Cyan-blue
        0 0.9 0.9;       % Cyan
        0.3 1 0.3;       % Light green
        0.8 1 0;         % Yellow-green
        1 0.8 0;         % Yellow
        1 0.5 0;         % Orange
        1 0.2 0;         % Red-orange
        0.8 0 0];        % Red
    colormap_interp = interp1(linspace(0,1,11), custom_cmap, linspace(0,1,256));
    
    % Use sqrt scaling for better contrast at low ion counts
    ion_plot_data = sqrt(ion_density_grid + 1);  % sqrt instead of log10
    
    imagesc(sc_z*1000, sc_r*1000, ion_plot_data);
    axis xy;
    colormap(gca, colormap_interp);
    h = colorbar;
    ylabel(h, 'sqrt(Ion Count + 1)', 'FontSize', 10);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    title('Final Ion Distribution (sqrt scale)', 'FontSize', 14);
    hold on;
    plot([254 254], [0 sc_r_max*1000], 'w--', 'LineWidth', 1.5);
    plot([0 8310], [75 75], 'w-', 'LineWidth', 2);
    text(280, 10, 'Anode', 'Color', 'white', 'FontSize', 10, 'FontWeight', 'bold');
    text(400, 70, 'Wall', 'Color', 'white', 'FontSize', 10);
    xlim([0 8310]);
    ylim([0 80]);
    
    % Plot 5: FIXED Longitudinal ion profile
    subplot(3,3,5);
    ion_longitudinal = sum(ion_density_grid, 1);  % Sum over r
    
    % Check if we have any ions
    if max(ion_longitudinal) > 0
        bar(sc_z*1000, ion_longitudinal, 'FaceColor', [0.2 0.5 0.8], 'EdgeColor', 'none');
        xlabel('z (mm)', 'FontSize', 12);
        ylabel('Ions (summed over r)', 'FontSize', 12);
        title(sprintf('Longitudinal Ion Profile (Total: %d)', round(sum(ion_longitudinal))), ...
              'FontSize', 14);
        grid on;
        xlim([0 8310]);
        hold on;
        xline(254, 'r--', 'Anode', 'LineWidth', 1.5);
        
        % Add statistics
        [max_val, max_idx] = max(ion_longitudinal);
        text(0.6, 0.9, sprintf('Peak: %d ions at z=%.0f mm', round(max_val), sc_z(max_idx)*1000), ...
             'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
    else
        text(0.5, 0.5, 'No ions detected', 'HorizontalAlignment', 'center', ...
             'FontSize', 14, 'Color', 'red');
    end
    
    % Plot 6: FIXED Radial ion profile at peak location
    subplot(3,3,6);
    [~, iz_peak] = max(ion_longitudinal);
    ion_radial = ion_density_grid(:, iz_peak);
    
    if max(ion_radial) > 0
        plot(sc_r*1000, ion_radial, 'r-', 'LineWidth', 2);
        xlabel('r (mm)', 'FontSize', 12);
        ylabel('Ion Count', 'FontSize', 12);
        title(sprintf('Radial Profile at z=%.0f mm (Peak)', sc_z(iz_peak)*1000), ...
              'FontSize', 14);
        grid on;
        xlim([0 75]);
        
        % Calculate and display centroid
        if sum(ion_radial) > 0
            r_centroid = sum(sc_r' .* ion_radial) / sum(ion_radial);
            xline(r_centroid*1000, 'b--', sprintf('Centroid: %.1f mm', r_centroid*1000), ...
                  'LineWidth', 1.5);
        end
    else
        text(0.5, 0.5, 'No ions at peak location', 'HorizontalAlignment', 'center', ...
             'FontSize', 14, 'Color', 'red');
    end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Plot (3,3,7) update 01.26.2026 %%%%%%%%%%%%%%%%%%%%%%%
% Plot 7: IMPROVED Space charge field comparison (LOG SCALE)
subplot(3,3,7);

% Calculate ion SC field estimate
ion_charge_density_max = max(ion_density_grid(:)) * e_charge / ...
                         (pi * (sc_dr)^2 * sc_dz);
ion_field_estimate = ion_charge_density_max / (2*eps0) * 0.05;  % kV/m

electron_sc_max = max(sc_field_max);

% Use log scale bar plot - CORRECTED
bar_data = [electron_sc_max/1e6, ion_field_estimate/1e3];
bar_pos = categorical({'Electron SC (MV/m)', 'Ion SC (kV/m)'});

% Create bar plot FIRST, then set y-axis to log scale
b = bar(bar_pos, bar_data, 'FaceColor', [0.3 0.6 0.9], 'BarWidth', 0.6);
set(gca, 'YScale', 'log');  % Set y-axis to log scale AFTER creating bar plot

ylabel('Field Magnitude (log scale)', 'FontSize', 12);
title('Space Charge Field Comparison', 'FontSize', 14);
grid on;
ylim([1e-2 1e2]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Chaged Annotation %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ===== ADD ORDER-OF-MAGNITUDE ANNOTATIONS =====
    % Get bar x-positions
    x_electron = 1;
    x_ion = 2;
    
    % Add order-of-magnitude markers ABOVE each bar
    text(x_electron, bar_data(1)*2, sprintf('10^{%.1f}', log10(bar_data(1))), ...
         'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', ...
         'Color', 'blue', 'BackgroundColor', 'white');
    
    text(x_ion, bar_data(2)*2, sprintf('10^{%.1f}', log10(bar_data(2))), ...
         'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', ...
         'Color', 'red', 'BackgroundColor', 'white');

    % Enhanced ratio annotation with order-of-magnitude difference
    ratio = electron_sc_max / (ion_field_estimate * 1e3);
    order_diff = log10(ratio);
    text(0.5, 0.05, sprintf('Electron/Ion ratio: %.0f:1 (%.1f orders of magnitude)', ...
         ratio, order_diff), ...
         'Units', 'normalized', 'HorizontalAlignment', 'center', ...
         'FontSize', 12, 'FontWeight', 'bold', 'BackgroundColor', 'yellow', ...
         'EdgeColor', 'black', 'LineWidth', 1.5);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Plot 8: Per-pulse ion contributions
    subplot(3,3,8);
    bar(1:pulse_config.n_pulses, ion_diag.ions_per_pulse, ...
        'FaceColor', [0.8 0.4 0.2], 'BarWidth', 0.6);
    xlabel('Pulse Number', 'FontSize', 12);
    ylabel('Ions Created', 'FontSize', 12);
    title('Ionization by Source Pulse', 'FontSize', 14);
    grid on;
    set(gca, 'XTick', 1:pulse_config.n_pulses);
    
    % Add values on bars
    for ip = 1:pulse_config.n_pulses
        text(ip, ion_diag.ions_per_pulse(ip), ...
             sprintf('%d', ion_diag.ions_per_pulse(ip)), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
             'FontSize', 11, 'FontWeight', 'bold');
    end
    
    % Plot 9: Enhanced summary text
    subplot(3,3,9);
    axis off;
    
    text(0.1, 0.99, 'ION SUMMARY', 'FontWeight', 'bold', 'FontSize', 16);
    text(0.1, 0.85, sprintf('Total ionizations: %d', total_ions_created), 'FontSize', 11);
    text(0.1, 0.75, sprintf('Rate: %.4f ions/e⁻', total_ions_created/n_created), 'FontSize', 11);
    text(0.1, 0.65, sprintf('Peak count: %d ions', round(max_ion_count)), 'FontSize', 11);
    text(0.1, 0.55, sprintf('Peak density: %.2e /m³', max_ion_density), 'FontSize', 11);
    
    text(0.1, 0.45, 'Expected focusing effect:', 'FontWeight', 'bold', 'FontSize', 11);
    
    % Estimate ion lens strength
    ion_lens_strength = ion_field_estimate / 1.7e6;  % Ratio to beam energy
    focal_length_estimate = 1 / (ion_lens_strength / 2);  % Rough thin lens approx
    
    text(0.1, 0.35, sprintf('Ion field/Beam energy: %.2e', ion_lens_strength), 'FontSize', 10);
    text(0.1, 0.27, sprintf('Estimated focal length: ~%.0f m', focal_length_estimate), 'FontSize', 10);
    text(0.1, 0.19, sprintf('Expected Δr at exit: ~%.2f mm', ion_lens_strength*50*1000), ...
         'Color', 'red', 'FontWeight', 'bold', 'FontSize', 11);
    
    % Add pressure info
    text(0.1, 0.10, sprintf('Pressure: %.1e mbar', gas_params.P/133.322), ...
         'FontSize', 10, 'Color', [0.3 0.3 0.3]);
    text(0.1, 0.00, sprintf('Mean free path: %.1f km', gas_params.lambda_mfp/1000), ...
         'FontSize', 10, 'Color', [0.3 0.3 0.3]);
    
    sgtitle(sprintf('Ion Accumulation and Space Charge Effects (P=%.1e mbar)', gas_params.P/133.322), ...
            'FontSize', 16);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Stand Alone Plot 3,3,4 Figure 3 %%%%%%%%%%%%%%%%%%%%%%%
      figure('Position', [100, 100, 1800, 400], 'Name', 'Ion Accumulation Diagnostics - Enhanced');
         % Create custom colormap with better contrast for low values
        custom_cmap = [
        0 0 0.2;         % Dark blue for zero
        0 0 0.5;         % Blue
        0 0.3 0.8;       % Lighter blue
        0 0.6 1;         % Cyan-blue
        0 0.9 0.9;       % Cyan
        0.3 1 0.3;       % Light green
        0.8 1 0;         % Yellow-green
        1 0.8 0;         % Yellow
        1 0.5 0;         % Orange
        1 0.2 0;         % Red-orange
        0.8 0 0];        % Red
    colormap_interp = interp1(linspace(0,1,11), custom_cmap, linspace(0,1,256));
    
    % Use sqrt scaling for better contrast at low ion counts
    ion_plot_data = sqrt(ion_density_grid + 1);  % sqrt instead of log10
    
    imagesc(sc_z*1000, sc_r*1000, ion_plot_data);
    axis xy;
    colormap(gca, colormap_interp);
    h = colorbar;
    ylabel(h, 'sqrt(Ion Count + 1)', 'FontSize', 10);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    title('Final Ion Distribution (sqrt scale)', 'FontSize', 14);
    hold on;
    plot([254 254], [0 sc_r_max*1000], 'w--', 'LineWidth', 1.5);
    plot([0 8310], [75 75], 'w-', 'LineWidth', 2);
    text(280, 10, 'Anode', 'Color', 'white', 'FontSize', 10, 'FontWeight', 'bold');
    text(400, 70, 'Wall', 'Color', 'white', 'FontSize', 10);
    xlim([0 8310]);
    ylim([0 80]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% ^^ Stand Alone Plot 3,3,4 Figure 3 ^^ %%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== STANDALONE ION SPATIAL DISTRIBUTION FIGURE ====================
% Create a dedicated high-contrast figure for ion distribution analysis

if ENABLE_ION_ACCUMULATION && sum(ion_density_grid(:)) > 10
    
    figure('Position', [100, 100, 1600, 900], 'Name', 'Ion Spatial Distribution - High Contrast');
    
    % Main plot: 2D distribution with enhanced contrast
    subplot(2,2,[1,3]);
    
    % Apply adaptive scaling for better visualization
    ion_data_plot = ion_density_grid;
    
    % Option 1: Power-law scaling for better mid-range contrast
    ion_scaled = (ion_data_plot).^0.5;  % Square root scaling
    
    % Create enhanced colormap (dark blue → cyan → yellow → red)
    enhanced_cmap = [
        0 0 0.3;         % Very dark blue (zero/low)
        0 0 0.6;         % Dark blue
        0 0.2 0.9;       % Blue
        0 0.5 1;         % Light blue
        0 0.8 1;         % Cyan
        0.2 1 0.8;       % Cyan-green
        0.5 1 0.5;       % Light green
        0.8 1 0;         % Yellow-green
        1 0.9 0;         % Yellow
        1 0.6 0;         % Orange
        1 0.3 0;         % Red-orange
        0.9 0 0];        % Red (high)
    
    cmap_fine = interp1(linspace(0,1,12), enhanced_cmap, linspace(0,1,256));
    
    imagesc(sc_z*1000, sc_r*1000, ion_scaled);
    axis xy;
    colormap(gca, cmap_fine);
    h = colorbar;
    ylabel(h, 'sqrt(Ion Count)', 'FontSize', 14);
    
    xlabel('z position (mm)', 'FontSize', 14);
    ylabel('r (mm)', 'FontSize', 14);
    title('Ion Density Distribution (Enhanced Contrast)', 'FontSize', 16);
    
    hold on;
    % Overlay geometry
    plot([254 254], [0 80], 'w:', 'LineWidth', 2);
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    plot([0 8310], [50 50], 'm--', 'LineWidth', 1.5);
    
    text(267, 5, 'Anode', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
    text(6400, 72, 'Wall (75mm)', 'Color', 'white', 'FontSize', 12);
    text(1400, 47, 'Target (50mm)', 'Color', 'magenta', 'FontSize', 10);
    
    xlim([0 8310]);
    ylim([0 80]);
    
    % Inset: Zoom on peak density region
    axes('Position', [0.15, 0.72, 0.15, 0.15]);
    [~, iz_peak] = max(sum(ion_density_grid, 1));
    z_zoom_range = max(1, iz_peak-50):min(sc_nz, iz_peak+50);
    imagesc(sc_z(z_zoom_range)*1000, sc_r*1000, ion_scaled(:, z_zoom_range));
    axis xy;
    colormap(gca, cmap_fine);
    title(sprintf('Zoom: z≈%.0f mm', sc_z(iz_peak)*1000), 'FontSize', 10, 'Color', 'white');
    set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');
    
    % Subplot: Longitudinal profile with better scaling
    subplot(2,2,2);
    ion_long = sum(ion_density_grid, 1);
    
    if max(ion_long) > 0
        % Use area plot for better visibility
        area(sc_z*1000, ion_long, 'FaceColor', [0.2 0.6 0.9], 'EdgeColor', 'b', 'LineWidth', 1.5);
        xlabel('z (mm)', 'FontSize', 14);
        ylabel('Total Ions (summed over r)', 'FontSize', 14);
        title('Longitudinal Ion Distribution', 'FontSize', 16);
        grid on;
        xlim([0 8310]);
        ylim([0 max(ion_long)*1.1]);
        
        hold on;
        xline(254, 'r--', 'LineWidth', 1.5);
        
        % Mark peak
        [max_long, idx_max] = max(ion_long);
        plot(sc_z(idx_max)*1000, max_long, 'ro', 'MarkerSize', 12, 'LineWidth', 2);
        text(sc_z(idx_max)*1000, max_long*1.05, ...
             sprintf('Peak: %d ions\nat z=%.0f mm', round(max_long), sc_z(idx_max)*1000), ...
             'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    end
    
    % Subplot: Radial profile at peak
    subplot(2,2,4);
    [~, iz_peak_radial] = max(ion_longitudinal);
    ion_radial = ion_density_grid(:, iz_peak_radial);
    
    if max(ion_radial) > 0
        % Area plot with fill
        area(sc_r*1000, ion_radial, 'FaceColor', [0.9 0.3 0.2], 'EdgeColor', 'r', 'LineWidth', 1.5);
        xlabel('r (mm)', 'FontSize', 14);
        ylabel('Ion Count', 'FontSize', 14);
        title(sprintf('Radial Profile at z=%.0f mm', sc_z(iz_peak_radial)*1000), ...
              'FontSize', 16);
        grid on;
        xlim([0 75]);
        ylim([0 max(ion_radial)*1.2]);
        
        % Calculate RMS radius of ion cloud
        if sum(ion_radial) > 0
            r_mean_ion = sum(sc_r' .* ion_radial) / sum(ion_radial);
            r_rms_ion = sqrt(sum(sc_r'.^2 .* ion_radial) / sum(ion_radial));
            
            xline(r_mean_ion*1000, 'b--', sprintf('Mean: %.1f mm', r_mean_ion*1000), ...
                  'LineWidth', 1.5, 'FontSize', 10);
            xline(r_rms_ion*1000, 'g--', sprintf('RMS: %.1f mm', r_rms_ion*1000), ...
                  'LineWidth', 1.5, 'FontSize', 10);
            
            % Add beam radius for comparison
            xline(50, 'm:', 'Beam target', 'LineWidth', 2);
        end
    end
    
    sgtitle(sprintf('Ion Spatial Distribution Analysis (%.0f total ions, P=%.1e mbar)', ...
                    round(sum(ion_density_grid(:))), gas_params.P/133.322), ...
            'FontSize', 18, 'FontWeight', 'bold');
end

fprintf('\nEnhanced ion diagnostics complete!\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 4.2 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
if ENABLE_ION_ACCUMULATION && sum(ion_density_grid(:)) > 10
    
    figure('Position', [100, 100, 1600, 900], 'Name', 'Ion Spatial Distribution - High Contrast');
    
    % Main plot: 2D distribution with enhanced contrast
    subplot(2,1,[1,2]);
    
    % Apply adaptive scaling for better visualization
    ion_data_plot = ion_density_grid;
    
    % Option 1: Power-law scaling for better mid-range contrast
    ion_scaled = (ion_data_plot).^0.5;  % Square root scaling
    
    % Create enhanced colormap (dark blue → cyan → yellow → red)
    enhanced_cmap = [
        0 0 0.3;         % Very dark blue (zero/low)
        0 0 0.6;         % Dark blue
        0 0.2 0.9;       % Blue
        0 0.5 1;         % Light blue
        0 0.8 1;         % Cyan
        0.2 1 0.8;       % Cyan-green
        0.5 1 0.5;       % Light green
        0.8 1 0;         % Yellow-green
        1 0.9 0;         % Yellow
        1 0.6 0;         % Orange
        1 0.3 0;         % Red-orange
        0.9 0 0];        % Red (high)
    
    cmap_fine = interp1(linspace(0,1,12), enhanced_cmap, linspace(0,1,256));
    
    imagesc(sc_z*1000, sc_r*1000, ion_scaled);
    axis xy;
    colormap(gca, cmap_fine);
    h = colorbar;
    ylabel(h, 'sqrt(Ion Count)', 'FontSize', 14);
    
    xlabel('z position (mm)', 'FontSize', 14);
    ylabel('r (mm)', 'FontSize', 14);
    title('Ion Density Distribution (Enhanced Contrast)', 'FontSize', 16);
    
    hold on;
    % Overlay geometry
    plot([254 254], [0 80], 'w:', 'LineWidth', 2);
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    plot([0 8310], [50 50], 'm--', 'LineWidth', 1.5);
    
    text(267, 5, 'Anode', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
    text(6400, 72, 'Wall (75mm)', 'Color', 'white', 'FontSize', 12);
    text(1400, 47, 'Target (50mm)', 'Color', 'magenta', 'FontSize', 10);
    
    xlim([0 8310]);
    ylim([0 80]);
    
    % Inset: Zoom on peak density region
    axes('Position', [0.15, 0.72, 0.15, 0.15]);
    [~, iz_peak] = max(sum(ion_density_grid, 1));
    z_zoom_range = max(1, iz_peak-50):min(sc_nz, iz_peak+50);
    imagesc(sc_z(z_zoom_range)*1000, sc_r*1000, ion_scaled(:, z_zoom_range));
    axis xy;
    colormap(gca, cmap_fine);
    title(sprintf('Zoom: z≈%.0f mm', sc_z(iz_peak)*1000), 'FontSize', 10, 'Color', 'white');
    set(gca, 'Color', 'k', 'XColor', 'w', 'YColor', 'w');
    
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Additional Figure 4.3 %%%%%%%%%%%%%%%%%%%%%%%%%%%
if ENABLE_ION_ACCUMULATION && sum(ion_density_grid(:)) > 10
 figure('Position', [100, 100, 1600, 400], 'Name', 'Ion Spatial Distribution - High Contrast');
    
    % Main plot: 2D distribution with enhanced contrast
    %subplot(2,1,[1,2]);
    
    % Apply adaptive scaling for better visualization
    ion_data_plot = ion_density_grid;
    
    % Option 1: Power-law scaling for better mid-range contrast
    ion_scaled = (ion_data_plot).^0.5;  % Square root scaling
    
    % Create enhanced colormap (dark blue → cyan → yellow → red)
    enhanced_cmap = [
        0 0 0.3;         % Very dark blue (zero/low)
        0 0 0.6;         % Dark blue
        0 0.2 0.9;       % Blue
        0 0.5 1;         % Light blue
        0 0.8 1;         % Cyan
        0.2 1 0.8;       % Cyan-green
        0.5 1 0.5;       % Light green
        0.8 1 0;         % Yellow-green
        1 0.9 0;         % Yellow
        1 0.6 0;         % Orange
        1 0.3 0;         % Red-orange
        0.9 0 0];        % Red (high)
    
    cmap_fine = interp1(linspace(0,1,12), enhanced_cmap, linspace(0,1,256));
    
    imagesc(sc_z*1000, sc_r*1000, ion_scaled);
    axis xy;
    colormap(gca, cmap_fine);
    h = colorbar;
    ylabel(h, 'sqrt(Ion Count)', 'FontSize', 14);
    
    xlabel('z position (mm)', 'FontSize', 14);
    ylabel('r (mm)', 'FontSize', 14);
    title('Ion Density Distribution (Enhanced Contrast)', 'FontSize', 16);
    
    hold on;
    % Overlay geometry
    plot([254 254], [0 80], 'w:', 'LineWidth', 2);
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    plot([0 8310], [50 50], 'm--', 'LineWidth', 1.5);
    
    text(267, 5, 'Anode', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
    text(6400, 72, 'Wall (75mm)', 'Color', 'white', 'FontSize', 12);
    text(1400, 47, 'Target (50mm)', 'Color', 'magenta', 'FontSize', 10);
    
    xlim([0 8310]);
    ylim([0 80]);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Figure 5 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %% Create improved visualization
    figure('Position', [100, 100, 1600, 900], 'Name', 'Longitudinal Beam Analysis (Steady State)');
    
    % Extract data for plotting
    z_centers = [slice_data.z_center] * 1000;  % mm
    valid_slices = ~isnan([slice_data.r_rms]);
    
    % Plot 1: Beam envelope
    subplot(2,3,1);
    r_rms_values = [slice_data.r_rms] * 1000;  % mm
    plot(z_centers(valid_slices), r_rms_values(valid_slices), 'b-o', 'LineWidth', 2);
    hold on;
    yline(50, 'r--', 'LineWidth', 2, 'Label', 'Target 50mm');
    yline(67, 'k--', 'LineWidth', 1, 'Label', 'Wall');
    xlabel('z position (mm)');
    ylabel('RMS radius (mm)');
    title(sprintf('Beam Envelope at t=%.1f ns', steady_state_beam.time*1e9));
    grid on;
    xlim([0 8310]);
    ylim([0 80]);
    
    % Plot 2: Particle density
    subplot(2,3,2);
    n_particles = [slice_data.n_particles];
    bar(z_centers, n_particles, 'FaceColor', [0.3 0.6 0.9]);
    xlabel('z position (mm)');
    ylabel('Particles per 90mm slice');
    title('Longitudinal Particle Distribution');
    grid on;
    xlim([0 8310]);
    
    % Plot 3: Current distribution
    subplot(2,3,3);
    current_values = [slice_data.current];
    valid_current = current_values > 0;
    plot(z_centers(valid_current), current_values(valid_current), 'g-s', 'LineWidth', 2);
    xlabel('z position (mm)');
    ylabel('Current (A)');
    title('Beam Current Along z');
    grid on;
    xlim([0 8310]);
    ylim([0 max(current_values)*1.2]);
    
    % Plot 4: Energy profile
    subplot(2,3,4);
    E_mean_values = [slice_data.E_mean];
    valid_energy = ~isnan(E_mean_values);
    plot(z_centers(valid_energy), E_mean_values(valid_energy), 'r-^', 'LineWidth', 2);
    hold on;
    yline(1.7, 'k--', 'Label', 'Expected 1.7 MeV');
    xlabel('z position (mm)');
    ylabel('Mean Energy (MeV)');
    title('Energy vs Position');
    grid on;
    xlim([0 8310]);
    ylim([0 2.0]);
    
    % Plot 5: Emittance evolution
    subplot(2,3,5);
    emit_values = [slice_data.emittance];
    valid_emit = ~isnan(emit_values);
    plot(z_centers(valid_emit), emit_values(valid_emit), 'm-d', 'LineWidth', 2);
    xlabel('z position (mm)');
    ylabel('Geometric Emittance (mm-mrad)');
    title('Slice Emittance');
    grid on;
    xlim([0 8310]);
    
    % Plot 6: 2D density map
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ENHANCED 2D DENSITY PLOT WITH BETTER CONTRAST
% Replace subplot(2,3,6) in your slice analysis with one of these options

%% OPTION 1: Logarithmic Scale with Custom Colormap
subplot(2,3,6);
[N, z_edges, r_edges] = histcounts2(z_beam*1000, r_beam*1000, ...
                                     0:25:8300, 0:1:80);  % Finer binning
                                     
% Apply logarithmic scaling for better contrast
N_log = log10(N + 1);  % Add 1 to avoid log(0)

% Create custom colormap for better contrast
cmap = [0 0 0;           % Black for zero counts
        0 0 0.5;         % Dark blue
        0 0 1;           % Blue
        0 0.5 1;         % Cyan-blue
        0 1 1;           % Cyan
        0.5 1 0.5;       % Light green
        1 1 0;           % Yellow
        1 0.5 0;         % Orange
        1 0 0];          % Red
colormap(gca, interp1(linspace(0,1,9), cmap, linspace(0,1,256)));

imagesc(z_edges(1:end-1)+12.5, r_edges(1:end-1)+0.5, N_log');
axis xy;
h = colorbar;
ylabel(h, 'log_{10}(Particle Count + 1)');
xlabel('z (mm)');
ylabel('r (mm)');
title('2D Particle Density (Log Scale)');
hold on;
plot([0 8310], [75 75], 'w--', 'LineWidth', 2);  % White line for better contrast
plot([254 254], [0 80], 'w:', 'LineWidth', 1.5); % Anode position
text(264, 5, 'Anode', 'Color', 'white', 'FontSize', 10);
text(500, 70, 'Wall', 'Color', 'white', 'FontSize', 10);
xlim([0 8310]);
ylim([0 80]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 6 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Position', [100, 100, 1800, 400], 'Name', 'Longitudinal Beam Analysis (Steady State)');
%subplot(2,3,6);
[N, z_edges, r_edges] = histcounts2(z_beam*1000, r_beam*1000, ...
                                     0:25:8300, 0:1:80);  % Finer binning
                                     
% Apply logarithmic scaling for better contrast
N_log = log10(N + 1);  % Add 1 to avoid log(0)

% Create custom colormap for better contrast
cmap = [0 0 0;           % Black for zero counts
        0 0 0.5;         % Dark blue
        0 0 1;           % Blue
        0 0.5 1;         % Cyan-blue
        0 1 1;           % Cyan
        0.5 1 0.5;       % Light green
        1 1 0;           % Yellow
        1 0.5 0;         % Orange
        1 0 0];          % Red
colormap(gca, interp1(linspace(0,1,9), cmap, linspace(0,1,256)));

imagesc(z_edges(1:end-1)+12.5, r_edges(1:end-1)+0.5, N_log');
axis xy;
h = colorbar;
ylabel(h, 'log_{10}(Particle Count + 1)','FontSize',18);
xlabel('z (mm)','FontSize',18);
ylabel('r (mm)','FontSize',18);
title('2D Particle Density (Log Scale)','FontSize',18);
hold on;
plot([0 8310], [75 75], 'w--', 'LineWidth', 2);  % White line for better contrast
plot([254 254], [0 80], 'w:', 'LineWidth', 2); % Anode position
plot([0 8310], [50 50], 'm--', 'LineWidth', 2);  % White line for better contrast
text(269, 7, 'Anode', 'Color', 'white', 'FontSize', 18);
text(600, 71, 'Wall', 'Color', 'white', 'FontSize', 18);
text(430, 54, 'Target beam radius', 'Color', 'white', 'FontSize', 18);
xlim([0 8310]);
ylim([0 80]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %% Print summary statistics
    fprintf('\n=== SLICE ANALYSIS SUMMARY (STEADY STATE) ===\n');
    fprintf('Analysis time point: %.1f ns (mid-pulse)\n', steady_state_beam.time*1e9);
    fprintf('Total particles analyzed: %d\n', steady_state_beam.n_total);
    fprintf('Total slices with data: %d/%d\n', sum(valid_slices), n_slices);
    
    % RMS radius statistics
    fprintf('\nBeam Envelope:\n');
    fprintf('  Average RMS radius: %.2f mm\n', mean(r_rms_values(valid_slices)));
    fprintf('  Maximum RMS radius: %.2f mm (at z=%.0f mm)\n', ...
            max(r_rms_values(valid_slices)), ...
            z_centers(r_rms_values == max(r_rms_values(valid_slices))));
    fprintf('  Minimum RMS radius: %.2f mm (at z=%.0f mm)\n', ...
            min(r_rms_values(valid_slices)), ...
            z_centers(r_rms_values == min(r_rms_values(valid_slices))));
    
    % Energy statistics
    fprintf('\nEnergy Distribution:\n');
    fprintf('  At cathode (z<100mm): %.3f MeV\n', mean(E_mean_values(z_centers<100 & valid_energy)));
    fprintf('  After anode (z>300mm): %.3f MeV\n', mean(E_mean_values(z_centers>300 & valid_energy)));
    fprintf('  At drift exit (z>1600mm): %.3f MeV\n', mean(E_mean_values(z_centers>1600 & valid_energy)));
    
    % Current statistics
    fprintf('\nCurrent Distribution:\n');
    fprintf('  Average current: %.2f A\n', mean(current_values(valid_current)));
    fprintf('  Peak current: %.2f A\n', max(current_values));
    
    % Check for sausage modulation
    r_variation = std(r_rms_values(valid_slices)) / mean(r_rms_values(valid_slices));
    fprintf('\nBeam Quality:\n');
    fprintf('  Radius variation coefficient: %.1f%%\n', r_variation*100);
    if r_variation > 0.15
        fprintf('  WARNING: Significant "sausage" modulation detected (>15%% variation)\n');
    else
        fprintf('  Beam envelope is relatively uniform (<15%% variation)\n');
    end
    
    % Save the steady-state slice data
    save('steady_state_slice_analysis.mat', 'slice_data', 'steady_state_beam', 'slice_width');
    fprintf('\nSteady-state analysis saved to steady_state_slice_analysis.mat\n');
    
else
    fprintf('\nERROR: No steady-state beam data captured or insufficient particles\n');
    fprintf('Make sure the beam snapshot is captured at it=4000 in the main loop\n');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% added 10.07.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== ENHANCED RESULTS REPORTING ====================
% Add this after the main simulation loop completes

% Calculate loss percentages
total_created = n_created;
total_lost = particles_lost_to_cathode + particles_lost_to_walls + particles_out_of_bounds;
actual_transmitted = particles_transmitted;
actual_at_anode = particles_at_anode;

% Verify particle conservation
particles_unaccounted = total_created - actual_transmitted - total_lost - n_active;

fprintf('\n=== DETAILED PARTICLE ACCOUNTING ===\n');
fprintf('  Total particles created:        %d\n', total_created);
fprintf('  Successfully transmitted:       %d (%.1f%%)\n', ...
        actual_transmitted, 100*actual_transmitted/max(1,total_created));
fprintf('  Currently active (in flight):   %d (%.1f%%)\n', ...
        n_active, 100*n_active/max(1,total_created));

fprintf('\n  PARTICLE LOSSES:\n');
fprintf('  Lost to cathode (backstream):   %d (%.1f%%)\n', ...
        particles_lost_to_cathode, 100*particles_lost_to_cathode/max(1,total_created));
fprintf('  Lost to walls (total):          %d (%.1f%%)\n', ...
        particles_lost_to_walls, 100*particles_lost_to_walls/max(1,total_created));
fprintf('  Lost to boundaries:             %d (%.1f%%)\n', ...
        particles_out_of_bounds, 100*particles_out_of_bounds/max(1,total_created));
fprintf('  ----------------------------------------\n');
fprintf('  Total losses:                   %d (%.1f%%)\n', ...
        total_lost, 100*total_lost/max(1,total_created));

% Calculate true transmission efficiency
true_efficiency_created = 100 * actual_transmitted / max(1, total_created);
true_efficiency_anode = 100 * actual_transmitted / max(1, actual_at_anode);

fprintf('\n=== TRUE TRANSMISSION EFFICIENCY ===\n');
fprintf('  From creation:    %.1f%%\n', true_efficiency_created);
fprintf('  From anode:       %.1f%%\n', true_efficiency_anode);

% Particle conservation check
if abs(particles_unaccounted) > 10
    fprintf('\n  WARNING: %d particles unaccounted for!\n', particles_unaccounted);
    fprintf('  Check particle tracking logic.\n');
end

% Space charge diagnostic


if ENABLE_SPACE_CHARGE
     enhancement1 = enhancement_gap * sc_enhancement_scale; %
     enhancement2 = enhancement_drift * sc_enhancement_scale;

    fprintf('\n=== SPACE CHARGE PARAMETERS ===\n');
    fprintf('  Enhancement (gap):    %.3f\n', enhancement1);  % Update with your value
    fprintf('  Enhancement (drift):  %.3f\n', enhancement2);  % Update with your value
    fprintf('  Peak SC field:        %.2f MV/m\n', max_sc_field_recorded/1e6);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%% added 10.17.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% COLLECTION EFFICIENCY FIX
% Place this section in your main code AFTER the main loop ends
% This replaces the existing efficiency calculation
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Second Correction to remove spike %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== COLLECTION EFFICIENCY FIX ============================
% Place this section in your main code AFTER the main loop ends

%% Find steady-state emission for both pulses
if ENABLE_MULTIPULSE == 1
    pulse1_flat = find(t >= 165e-9 & t <= 245e-9);
    pulse2_flat = find(t >= 365e-9 & t <= 445e-9);
    pulse3_flat = find(t >= 565e-9 & t <= 645e-9);
    pulse4_flat = find(t >= 765e-9 & t <= 845e-9);
    
    I_emit_steady_p1 = mean(I_cathode(pulse1_flat));
    I_emit_steady_p2 = mean(I_cathode(pulse2_flat));
    I_emit_steady_p3 = mean(I_cathode(pulse3_flat));
    I_emit_steady_p4 = mean(I_cathode(pulse4_flat));
    I_emit_steady = mean([I_emit_steady_p1, I_emit_steady_p2, I_emit_steady_p3, ...
        I_emit_steady_p4]);
    
    fprintf('\n=== Collection Efficiency Correction ===\n');
    fprintf('Pulse 1 steady emission: %.2f A\n', I_emit_steady_p1);
    fprintf('Pulse 2 steady emission: %.2f A\n', I_emit_steady_p2);
    fprintf('Pulse 3 steady emission: %.2f A\n', I_emit_steady_p3);
    fprintf('Pulse 4 steady emission: %.2f A\n', I_emit_steady_p4);
    fprintf('Average steady emission: %.2f A\n', I_emit_steady);
else
    pulse_flat = find(t >= 165e-9 & t <= 245e-9);
    I_emit_steady = mean(I_cathode(pulse_flat));
    
    fprintf('\n=== Collection Efficiency Correction ===\n');
    fprintf('Steady-state emission current: %.2f A\n', I_emit_steady);
end

% Initialize efficiency arrays
collection_efficiency_corrected = NaN(nt, 1);
drift_exit_efficiency = NaN(nt, 1);
%%================= Collection Efficiency ==================================
%% COLLECTION EFFICIENCY FIX
% Place this section in your main code AFTER the main loop ends
% This replaces the existing efficiency calculation

%% ==================== CORRECTED COLLECTION EFFICIENCY ====================
% Find the steady-state emission current value
pulse_flat_start = find(t >= 165e-9, 1);
pulse_flat_end = find(t >= 245e-9, 1);

fprintf('\n=== Collection Efficiency Correction ===\n');
fprintf('Steady-state emission current: %.2f A\n', I_emit_steady);

% Define pulse window for meaningful efficiency calculation
pulse_window_P1 = t >= 150e-9 & t <= 285e-9;  % Slightly beyond pulse end
pulse_window_P2 = t >= 350e-9 & t <= 485e-9;
pulse_window_P3 = t >= 550e-9 & t <= 685e-9;
pulse_window_P4 = t >= 750e-9 & t <= 885e-9;  % ADD THIS
pulse_window = pulse_window_P1 | pulse_window_P2 | pulse_window_P3 | pulse_window_P4;

% Steady-state indices for averaging
steady_indices_p1 = (t >= 180e-9 & t <= 245e-9);
steady_indices_p2 = (t >= 380e-9 & t <= 445e-9);
steady_indices_p3 = (t >= 580e-9 & t <= 645e-9);
steady_indices_p4 = (t >= 780e-9 & t <= 845e-9);  % ADD THIS

for it = 1:nt
    if pulse_window(it) && I_emit_steady > 1e-6 % Threshold forstability changed from 0
        % Anode efficiency relative to steady emission
       % Drift exit efficiency (most meaningful metric)
        drift_exit_efficiency(it) = 100 * I_drift_exit(it) / I_emit_steady;

     else
        % Outside pulse window - set to NaN to avoid plotting
        
        drift_exit_efficiency(it) = NaN;
    end
end  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Time-averaged metrics
if ENABLE_MULTIPULSE == true
    steady_indices_p1 = (t >= 180e-9 & t <= 245e-9);
    steady_indices_p2 = (t >= 380e-9 & t <= 445e-9);
    steady_indices_p3 = (t >= 580e-9 & t <= 645e-9);
    steady_indices_p4 = (t >= 780e-9 & t <= 845e-9);  % ADD THIS
    
    % NEW METHOD - Use actual particle counts (RELIABLE)
    avg_anode_efficiency = 100 * particles_at_anode / max(1, n_created);
    avg_drift_efficiency = 100 * particles_transmitted / max(1, n_created);
    
    % OLD current-based method - COMMENTED OUT (has timing issues)
    % avg_I_anode_p1 = mean(I_anode(steady_indices_p1), 'omitnan');
    % avg_I_anode_p2 = mean(I_anode(steady_indices_p2), 'omitnan');
    % avg_I_drift_p1 = mean(I_drift_exit(steady_indices_p1), 'omitnan');
    % avg_I_drift_p2 = mean(I_drift_exit(steady_indices_p2), 'omitnan');
    % avg_anode_efficiency = ((avg_I_anode_p1 + avg_I_anode_p2)/2) / I_emit_steady * 100;
    % avg_drift_efficiency = ((avg_I_drift_p1 + avg_I_drift_p2)/2) / I_emit_steady * 100;
    
else
    steady_indices = t >= 180e-9 & t <= 245e-9;
    % Particle-based for single pulse mode
    avg_anode_efficiency = 100 * particles_at_anode / max(1, n_created);
    avg_drift_efficiency = 100 * particles_transmitted / max(1, n_created);
end

fprintf('\nParticle-based transmission efficiencies:\n');
fprintf('  Anode efficiency: %.1f%%\n', avg_anode_efficiency);
fprintf('  Drift exit efficiency: %.1f%%\n', avg_drift_efficiency);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 7 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== UPDATED PLOTTING SECTION ====================
% Replace the existing Figure with collection efficiency (subplot 2,3,5)
% This creates the corrected efficiency plot
I_drift_exit = I_exit;
figure('Position', [50, 50, 1600, 900], 'Name', 'Emission System Diagnostics v8 - Corrected');

% Copy your existing subplots 1-4 here (Current density, Weight, SC field, Currents)
% ... [Keep your existing subplot code for positions 1-4] ...

% 1. Current density components
subplot(2,3,1);
%plot(t*1e9, J_thermionic/1e4, 'b-', 'LineWidth', 2, 'DisplayName', 'Thermionic');
semilogy(t*1e9, J_thermionic/1e4, 'b-', 'LineWidth', 2, 'DisplayName', 'Thermionic');
hold on;
%plot(t*1e9, J_space_charge/1e4, 'r--', 'LineWidth', 2, 'DisplayName', 'Space-charge');
%plot(t*1e9, J_actual/1e4, 'k-', 'LineWidth', 1.5, 'DisplayName', 'Actual');
semilogy(t*1e9, J_space_charge/1e4, 'r--', 'LineWidth', 2, 'DisplayName', 'Space-charge');
semilogy(t*1e9, J_actual/1e4, 'k-', 'LineWidth', 1.5, 'DisplayName', 'Actual');
xlabel('Time (ns)');
ylabel('J (A/cm²)');
title('Current Density Components');
legend('Location', 'best');
grid on;
xlim([t_plot_min t_plot_max]); % Time line for four pulses

% 2. Adaptive weight evolution
subplot(2,3,2);
semilogy(t*1e9, particle_weight_history, 'b-', 'LineWidth', 2);
xlabel('Time (ns)');
ylabel('Particle Weight');
title('Adaptive Weight Evolution');
grid on;
xlim([t_plot_min t_plot_max]);
ylim([1e7 1e10]);

% 3. Space charge field magnitude
subplot(2,3,3);
plot(t*1e9, sc_field_max/1e6, 'b-', 'LineWidth', 1);
xlabel('Time (ns)');
ylabel('Space Charge Field (MV/m)');
title('Space Charge Field Magnitude');
grid on;
xlim([t_plot_min t_plot_max]);
%ylim([0  (sc_field_max/1e6)*1.1]);
if ENABLE_SPACE_CHARGE == true
sc_lim = (max(sc_field_max/1e6))*1.5;
ylim([0 sc_lim]);
else
ylim([0 1]);
end

%%%%%%%%%%%%%%%%%%%%%%%%%% New Subplot (2,3,4) %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== Subplot 4: Emission and Collection Currents ====================
subplot(2,3,4);
%% V3 currents are in Amperes — plot directly, no ×1e6 scaling
plot(t_ns, I_cathode, 'r-', 'LineWidth', 2, 'DisplayName', 'Cathode');
hold on;
plot(t_ns, I_anode,   'b-', 'LineWidth', 1.5, 'DisplayName', 'Anode');
plot(t_ns, I_exit,    'g-', 'LineWidth', 1.5, 'DisplayName', 'Drift Exit');
xlabel('Time (ns)');
ylabel('Current (A)');
title('Emission and Collection Currents');
legend('Location', 'best');
grid on;
xlim([t_plot_min t_plot_max]);
ylim([0, max(max(I_cathode), 10) * 1.15]);

%%%%%%%%%%%%%%%%%%%%%%%%%%% NEW SUBPLOT (2,3,5) %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== Subplot 5: Collection Efficiency ====================
subplot(2,3,5);

collection_efficiency_2 = 100*(I_exit./I_cath_ss);
anode_efficiency = 100*(I_anode./I_cath_ss);
hold on;
plot(t_ns, collection_efficiency_2, 'm-', 'LineWidth', 1.0, ...
     'DisplayName', 'Exit');
plot(t_ns, anode_efficiency, 'b-', 'LineWidth', 1, 'DisplayName', 'Anode');
yline(100, 'k--', 'LineWidth', 1, 'DisplayName', '100% Reference');
ylabel('Drift Exit Efficiency (%)');
ylim([0, 120]);

xlabel('Time (ns)');
xlim([t_plot_min, t_plot_max]);
title('Current Transport Collection Efficiency');
legend('Exit','Anode','100% Reference','Location','northeast');
%legend('Location','northeast');
grid on;
hold off;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. Space charge distribution histogram
subplot(2,3,6);
% 6. Space charge distribution histogram
subplot(2,3,6);
sc_factors = sc_field_distribution(sc_field_distribution > 0);
if ~isempty(sc_factors)
    histogram(sc_factors/1e6, 30, 'FaceColor', 'b', 'EdgeColor', 'none');
    xlabel('Space Charge Factor (MV/m)');
    ylabel('Frequency');
    title('Space Charge Distribution');
    text(0.2, 0.9, sprintf('SC updates: %d', sum(sc_field_distribution > 0)), ...
         'Units', 'normalized');
    text(0.2, 0.80, sprintf('Limited: %d', sum(sc_field_max >= 15e6*0.99)), ...
         'Units', 'normalized', 'Color', 'red');
    %text(0.6, 0.85, sprintf('Limited: %d', sum(sc_field_max >= max_sc*0.99)), ...
    %     'Units', 'normalized', 'Color', 'red');
end
grid on;

% Print summary statistics
fprintf('\n=== EMISSION DIAGNOSTICS SUMMARY ===\n');
fprintf('Peak emission current: %.2f A\n', max(I_cathode));
fprintf('Anode Steady State Efficiency: %.1f%%\n', anode_eff);
fprintf('Peak space charge field: %.2f MV/m\n', max(sc_field_max)/1e6);
fprintf('Exit Steady State Transmission: %.1f%%\n', exit_eff);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 8 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== STANDALONE EFFICIENCY FIGURE ====================
% Create a dedicated figure just for efficiency analysis
figure('Position', [100, 100, 1200, 600], 'Name', 'Collection Efficiency Analysis');

collection_efficiency_2 = 100*(I_exit./I_cath_ss);
colororder({'b','m'})

% Main plot
yyaxis left
hold on;

plot(t*1e9, I_anode, 'b-', 'LineWidth', 2, 'DisplayName', 'Anode');
plot(t*1e9, I_drift_exit, 'g-', 'LineWidth', 2, 'DisplayName', 'Drift Exit');
plot(t*1e9, I_cathode, 'r-', 'LineWidth', 2, 'DisplayName', 'Cathode');
ylabel('Current (A)');
ylim([0 1700]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
yyaxis right

plot(t_ns, collection_efficiency_2, 'm-', 'LineWidth', 1.0, ...
     'DisplayName', 'Efficiency');
ylabel('Drift Exit Efficiency (%)');
ylim([0, 120]);

xlabel('Time (ns)');
xlim([t_plot_min, t_plot_max]);
title('Current Transport and Collection Efficiency');
legend('Location','northeast');
grid on;

% Add text annotation with key metrics
text(0.30, 0.65, sprintf('Steady-state Metrics:'), ...
     'Units', 'normalized', 'VerticalAlignment', 'top', 'FontWeight', 'bold');
text(0.30, 0.60, sprintf('  I Cathode Steady : %.1f A', I_cath_ss), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');
text(0.30, 0.55, sprintf('  I Anode Steady  : %.1f A', I_anode_ss), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');
text(0.30, 0.50, sprintf('  Anode Efficiency : %.1f%%', anode_eff), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');
text(0.30, 0.45, sprintf('  I Exit Steady State: %.1f A', I_exit_ss), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');
text(0.30, 0.40, sprintf('  Transmission Steady: %.1f%%', exit_eff), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');

%% Annotation box
ann_x = t_plot_min + 0.35*(t_plot_max - t_plot_min);
ann_y = max(I_cathode) * 0.72;
text(ann_x, ann_y, ...
    sprintf('Steady-state Metrics:\nEmission: %.1f A\nAnode Eff: %.1f%%\nDrift Exit Eff: %.1f%%\nTransmission: %.1f%%', ...
            I_cath_ss, I_anode_ss, I_exit_ss, transmission_pct), ...
    'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 9 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== R STANDALONE EFFICIENCY FIGURE R ====================
% Create a dedicated figure just for efficiency analysis
figure('Position', [100, 100, 1200, 600], 'Name', 'Collection Efficiency Analysis');

% Main plot
yyaxis left
hold on;
plot(t*1e9, I_cathode, 'r-', 'LineWidth', 2, 'DisplayName', 'Cathode');
plot(t*1e9, I_anode, 'b-', 'LineWidth', 2, 'DisplayName', 'Anode');
plot(t*1e9, I_drift_exit, 'g-', 'LineWidth', 2, 'DisplayName', 'Drift Exit');
ylabel('Current (A)');
ylim([0 1700]);


xlabel('Time (ns)');
title('Current Emission and Transport','FontSize' ,18);
legend('Location', 'northeast');
grid on;
xlim([t_plot_min t_plot_max]);

% Add text annotation with key metrics
text(0.35, 0.65, sprintf('Steady-state Metrics:'), ...
     'Units', 'normalized', 'VerticalAlignment', 'top', 'FontWeight', 'bold');
text(0.35, 0.55, sprintf('  Emission: %.1f A', I_emit_steady), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');
text(0.35, 0.50, sprintf('  Anode Eff: %.1f%%', avg_anode_efficiency), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');
text(0.35, 0.45, sprintf('  Drift Exit Eff: %.1f%%', avg_drift_efficiency), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');
text(0.35, 0.40, sprintf('  Transmission: %.1f%%', avg_drift_efficiency), ...
     'Units', 'normalized', 'VerticalAlignment', 'top');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 10  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%% SCHOTTKY EFFECT VISUALIZATION FIXED %%%%%%%%%%%%%%%%%%%%%%%
%% ==================== SCHOTTKY EFFECT VISUALIZATION (FIXED) ====================
fprintf('\n=== Generating Schottky Effect Analysis Figure ===\n');

if exist('schottky_diagnostics', 'var')
    
    % SAFETY CHECK: Verify array sizes
    fprintf('Array size check:\n');
    fprintf('  t: %d elements\n', length(t));
    fprintf('  E_cathode: %d elements\n', length(schottky_diagnostics.E_cathode));
    fprintf('  phi_eff: %d elements\n', length(schottky_diagnostics.phi_eff));
    
    % Use index-based selection instead of logical indexing
    it_start = find(t >= 150e-9, 1);
    it_end = find(t <= 870e-9, 1, 'last');
    
    if isempty(it_start), it_start = 1; end
    if isempty(it_end), it_end = length(t); end
    
    plot_indices = it_start:it_end;
    t_plot = t(plot_indices);
    
    fprintf('  Plotting timesteps %d to %d (%d points)\n', it_start, it_end, length(plot_indices));
  
    figure('Position', [100, 100, 1400, 800], 'Name', 'Test 82: Schottky Effect Analysis');
    
    % Plot 1: Cathode surface field
    subplot(2,3,1);
    plot(t_plot*1e9, schottky_diagnostics.E_cathode(plot_indices)/1e6, 'b-', 'LineWidth', 2);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('E_{cathode} (MV/m)', 'FontSize', 12);
    title('Cathode Surface Electric Field', 'FontSize', 14);
    grid on;
    xlim([t_plot_min t_plot_max]);
    % Plot 2: Work function
    subplot(2,3,2);
    hold on;
    
    phi_0 = 1.8;
    phi_eff_plot = schottky_diagnostics.phi_eff(plot_indices);
    
    plot(t_plot*1e9, phi_eff_plot, 'r-', 'LineWidth', 2);
    plot(t_plot*1e9, ones(size(t_plot))*phi_0, 'k--', 'LineWidth', 1);
    
    % Add shaded region showing reduction
    E_plot = schottky_diagnostics.E_cathode(plot_indices);
    field_active = E_plot > 0.5e6;  % When field > 0.5 MV/m
    if any(field_active)
        idx_active = find(field_active);
        if length(idx_active) > 2
            area(t_plot(field_active)*1e9, phi_eff_plot(field_active), phi_0, ...
                 'FaceColor', 'g', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        end
    end
    
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('Work Function (eV)', 'FontSize', 12);
    title('Schottky-Reduced Work Function', 'FontSize', 14);
    legend('\phi_{eff}', '\phi_0', 'Reduction', 'Location', 'best');
    grid on;
    xlim([t_plot_min t_plot_max]);
    % Plot 3: Temperature comparison
    subplot(2,3,3);
    hold on;
    plot(t_plot*1e9, schottky_diagnostics.T_cathode(plot_indices), 'b-', 'LineWidth', 2);
    plot(t_plot*1e9, schottky_diagnostics.T_required(plot_indices), 'r--', 'LineWidth', 2);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('Temperature (K)', 'FontSize', 12);
    title('Operating Temperature', 'FontSize', 14);
    legend('With Schottky', 'Without Schottky', 'Location', 'best');
    grid on;
    xlim([t_plot_min t_plot_max]);
    % Plot 4: Current density
    subplot(2,3,4);
    semilogy(t_plot*1e9, J_thermionic(plot_indices)/1e4, 'b-', 'LineWidth', 2);
    hold on;
    semilogy(t_plot*1e9, J_space_charge(plot_indices)/1e4, 'r-', 'LineWidth', 2);
    semilogy(t_plot*1e9, J_actual(plot_indices)/1e4, 'k-', 'LineWidth', 2);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('J (A/cm²)', 'FontSize', 12);
    title('Current Density Limits', 'FontSize', 14);
    legend('Thermionic', 'Child-Langmuir', 'Actual', 'Location', 'best');
    grid on;
    xlim([t_plot_min t_plot_max]);
    % Plot 5: Temperature saving
    subplot(2,3,5);
    temp_saving = schottky_diagnostics.T_required(plot_indices) - ...
                  schottky_diagnostics.T_cathode(plot_indices);
    area(t_plot*1e9, temp_saving, 'FaceColor', [0.3 0.7 0.3], 'EdgeColor', 'none');
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('Temperature Saving (K)', 'FontSize', 12);
    title('Cathode Temperature Reduction', 'FontSize', 14);
    grid on;
    xlim([t_plot_min t_plot_max]);
 
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% Schottky summary fixed %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% ==================== Plot 6: Summary ====================
    subplot(2,3,6);
    axis off;

    %% Steady-state window — use pulse flat-top
    steady_start = find(t >= 165e-9, 1);
    steady_end   = find(t <= 245e-9, 1, 'last');
    if isempty(steady_start), steady_start = 1; end
    if isempty(steady_end),   steady_end   = length(t); end
    steady_range = steady_start:steady_end;

    %% Only average over timesteps where emission was active
    active_ss = schottky_diagnostics.E_cathode(steady_range) > 0.5e6;

    if sum(active_ss) > 10
        avg_E       = mean(schottky_diagnostics.E_cathode(steady_range(active_ss)));
        avg_dphi    = mean(schottky_diagnostics.delta_phi(steady_range(active_ss)));
        avg_T       = mean(schottky_diagnostics.T_cathode(steady_range(active_ss)));
        avg_T_req   = mean(schottky_diagnostics.T_required(steady_range(active_ss)));
        avg_T_saved = avg_T_req - avg_T;
    else
        avg_E = 0; avg_dphi = 0; avg_T = 1200;
        avg_T_req = 1200; avg_T_saved = 0;
    end

    lifetime_factor = 2^(max(avg_T_saved, 0) / 50);

    text(0.1, 0.90, 'SCHOTTKY SUMMARY', 'FontWeight','bold','FontSize',14);
    text(0.1, 0.76, 'Steady-State:', 'FontWeight','bold');
    text(0.1, 0.65, sprintf('E_{cathode}: %.2f MV/m',     avg_E/1e6),      'FontSize',11);
    text(0.1, 0.54, sprintf('Δφ: %.3f eV (%.1f%%)',        avg_dphi, ...
                             100*avg_dphi/phi_0),                           'FontSize',11);
    text(0.1, 0.43, sprintf('T_{op}: %.0f K',              avg_T),          'FontSize',11);
    text(0.1, 0.32, sprintf('T_{required} (no Schottky): %.0f K', avg_T_req), 'FontSize',11);
    text(0.1, 0.21, sprintf('T saved: %.0f K',             avg_T_saved),    'FontSize',11);
    text(0.1, 0.10, 'Lifetime Extension:', 'FontWeight','bold','FontSize',11);
    text(0.1, 0.02, sprintf('~%.1fx longer life',          lifetime_factor), 'FontSize',11);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%% Updated 02.25.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================================================================================
%% FIX 2: CORRECTED P1 POST-SIMULATION ANALYSIS (15 PLANES)
%% Replace the existing P1 analysis block (~lines 4734-4966)
%% ==================================================================================

if exist('steady_state_beam', 'var') && steady_state_beam.n_total > 1000
    fprintf('\n=== ENHANCED POST-SIMULATION BEAM ANALYSIS - PULSE 1 ===\n');
    fprintf('Analyzing beam at %d locations along 8.3m beamline\n', N_ANALYSIS_PLANES);
    
    for ip = 1:N_ANALYSIS_PLANES
        z_plane = ANALYSIS_LOCATIONS(ip) / 1000;  % Convert to meters
        plane_name = sprintf('%s (%dmm)', ANALYSIS_LOCATION_NAMES{ip}, ANALYSIS_LOCATIONS(ip));
        
        % Time-based selection using steady_state_beam (NOT beam_snapshot)
        dz_window = abs(steady_state_beam.vz * dt * 30);
        in_plane = abs(steady_state_beam.z - z_plane) < abs(dz_window);
        
        % Fallback to spatial window (wider for sparser extended regions)
        if sum(in_plane) < 100
            in_plane = abs(steady_state_beam.z - z_plane) < 0.020;  % 20mm window
        end
        
        n_selected = sum(in_plane);
        
        if n_selected > 50
            % FIX: Use steady_state_beam consistently (was beam_snapshot)
            r_sel = steady_state_beam.r(in_plane);
            pr_sel = steady_state_beam.pr(in_plane);
            pz_sel = steady_state_beam.pz(in_plane);
            ptheta_sel = steady_state_beam.ptheta(in_plane);
            gamma_sel = steady_state_beam.gamma(in_plane);
            
            % Calculate parameters
            r_mean = mean(r_sel);
            r_rms = sqrt(mean((r_sel - r_mean).^2));
            energy_MeV = (gamma_sel - 1) * m_e * c^2 / e_charge / 1e6;
            energy_mean = mean(energy_MeV);
            energy_spread = std(energy_MeV);
            
            % Clean energy data before plotting
            valid_energy = isfinite(energy_MeV) & energy_MeV > 0;
            if sum(~valid_energy) > 0
                fprintf('  [%s] Removing %d particles with bad energy\n', ...
                        ANALYSIS_LOCATION_NAMES{ip}, sum(~valid_energy));
            end
            
            % CREATE FIGURE FOR THIS LOCATION
            figure('Position', [100+ip*30, 100+ip*30, 1400, 800], ...
                   'Name', sprintf('P1 Beam: %s', plane_name));
            
            % --- Subplot 1: Beam cross-section ---
            subplot(2,3,1);
            theta_random = 2*pi*rand(n_selected, 1);
            x_sel = r_sel .* cos(theta_random);
            y_sel = r_sel .* sin(theta_random);
            
            try
                e_min = min(energy_MeV(valid_energy));
                e_max = max(energy_MeV(valid_energy));
                if (e_max - e_min) < 0.005
                    e_center = mean(energy_MeV(valid_energy));
                    e_min = e_center - 0.005;
                    e_max = e_center + 0.005;
                end
                scatter(x_sel(valid_energy)*1000, y_sel(valid_energy)*1000, ...
                        10, energy_MeV(valid_energy), 'filled');
                caxis([e_min e_max]);
                colorbar;
                colormap(gca, 'jet');
            catch
                scatter(x_sel*1000, y_sel*1000, 10, 'b', 'filled');
                colorbar;
            end
            xlabel('x (mm)', 'FontSize', 12);
            ylabel('y (mm)', 'FontSize', 12);
            title(sprintf('Beam Cross-Section'), 'FontSize', 14);
            axis equal; grid on;
            xlim([-65 65]); ylim([-65 65]);
            
            % --- Subplot 2: r-r' phase space ---
            subplot(2,3,2);
            pr_norm = pr_sel ./ (gamma_sel * m_e * c);
            scatter(r_sel*1000, pr_norm*1000, 10, 'b.');
            hold on;
            
            r_centered = r_sel - r_mean;
            pr_centered = pr_norm - mean(pr_norm);
            r2_avg = mean(r_centered.^2);
            pr2_avg = mean(pr_centered.^2);
            r_pr_avg = mean(r_centered .* pr_centered);
            emit_rms = sqrt(r2_avg * pr2_avg - r_pr_avg^2);
            
            if emit_rms > 1e-10
                beta_twiss = r2_avg / emit_rms;
                alpha_twiss = -r_pr_avg / emit_rms;
                
                theta_ellipse = linspace(0, 2*pi, 100);
                ellipse_r = sqrt(emit_rms * beta_twiss) * cos(theta_ellipse);
                ellipse_pr = sqrt(emit_rms / beta_twiss) * ...
                            (-alpha_twiss * cos(theta_ellipse) - sin(theta_ellipse));
                plot(ellipse_r*1000 + r_mean*1000, ellipse_pr*1000, 'r-', 'LineWidth', 2);
                
                if alpha_twiss > 0.1
                    text(0.05, 0.95, 'Converging', 'Units', 'normalized', ...
                         'Color', 'red', 'FontWeight', 'bold');
                elseif alpha_twiss < -0.1
                    text(0.05, 0.95, 'Diverging', 'Units', 'normalized', ...
                         'Color', 'blue', 'FontWeight', 'bold');
                else
                    text(0.05, 0.95, 'Collimated', 'Units', 'normalized', ...
                         'Color', 'green', 'FontWeight', 'bold');
                end
            end
            xlabel('r (mm)', 'FontSize', 12);
            ylabel('r'' (mrad)', 'FontSize', 12);
            title('r-r'' Phase Space', 'FontSize', 14);
            legend('Particles', 'RMS Ellipse', 'Location', 'best');
            grid on;
            
            % --- Subplot 3: Radial distribution ---
            subplot(2,3,3);
            histogram(r_sel*1000, 20, 'FaceColor', 'g', 'EdgeColor', 'none');
            xlabel('r (mm)', 'FontSize', 12);
            ylabel('Count', 'FontSize', 12);
            title('Radial Distribution', 'FontSize', 14);
            grid on; xlim([0 65]);
            
            % --- Subplot 4: Angular momentum ---
            subplot(2,3,4);
            Lz_sel = r_sel .* ptheta_sel;
            Lz_normalized = Lz_sel / (m_e * c);
            scatter(r_sel*1000, Lz_normalized, 10, 'b.');
            xlabel('r (mm)', 'FontSize', 12);
            ylabel('L_z/(m_e c) (m)', 'FontSize', 12);
            title('     Angular Momentum vs Radius', 'FontSize', 14);
            grid on;
            
            % --- Subplot 5: Lz histogram ---
            subplot(2,3,5);
            histogram(Lz_normalized, 30, 'FaceColor', 'c', 'EdgeColor', 'none');
            xlabel('L_z/(m_e c) (m)', 'FontSize', 12);
            ylabel('Count', 'FontSize', 12);
            title('Angular Momentum Distribution', 'FontSize', 14);
            grid on;
            
            % --- Subplot 6: Energy vs radius ---
            subplot(2,3,6);
            scatter(r_sel(valid_energy)*1000, energy_MeV(valid_energy), 10, ...
                    energy_MeV(valid_energy), 'filled');
            colormap(gca, 'hot'); colorbar;
            xlabel('r (mm)', 'FontSize', 12);
            ylabel('Energy (MeV)', 'FontSize', 12);
            title('Energy vs Radius', 'FontSize', 14);
            grid on;
            
            sgtitle(sprintf('PULSE 1: %s — %d particles, r_{rms}=%.1f mm, E=%.3f±%.3f MeV', ...
                    plane_name, n_selected, r_rms*1000, energy_mean, energy_spread), ...
                    'FontSize', 16);
        else
            fprintf('  Skipping %s: only %d particles\n', ...
                    ANALYSIS_LOCATION_NAMES{ip}, n_selected);
        end
    end
    fprintf('P1 analysis complete: %d locations processed\n', N_ANALYSIS_PLANES);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% updated 02.25.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%% ==================================================================================
%% FIX 3: EXPANDED P2 POST-SIMULATION ANALYSIS (5 → 15 PLANES)
%% Replace the existing P2 analysis block (~lines 4968-5187)
%% ==================================================================================

if exist('steady_state_beam_pulse2', 'var') && steady_state_beam_pulse2.n_total > 1000
    fprintf('\n=== ENHANCED POST-SIMULATION BEAM ANALYSIS - PULSE 2 ===\n');
    fprintf('Analyzing beam at %d locations along 8.3m beamline\n', N_ANALYSIS_PLANES);
    
    for ip = 1:N_ANALYSIS_PLANES
        z_plane = ANALYSIS_LOCATIONS(ip) / 1000;
        plane_name = sprintf('%s (%dmm) - P2', ANALYSIS_LOCATION_NAMES{ip}, ANALYSIS_LOCATIONS(ip));
        
        % Selection from P2 data
        dz_window = steady_state_beam_pulse2.vz * dt * 30;
        in_plane = abs(steady_state_beam_pulse2.z - z_plane) < abs(dz_window);
        
        if sum(in_plane) < 100
            in_plane = abs(steady_state_beam_pulse2.z - z_plane) < 0.020;
        end
        
        n_selected = sum(in_plane);
        
        if n_selected > 50
            r_sel = steady_state_beam_pulse2.r(in_plane);
            pr_sel = steady_state_beam_pulse2.pr(in_plane);
            pz_sel = steady_state_beam_pulse2.pz(in_plane);
            ptheta_sel = steady_state_beam_pulse2.ptheta(in_plane);
            gamma_sel = steady_state_beam_pulse2.gamma(in_plane);
            
            r_mean = mean(r_sel);
            r_rms = sqrt(mean((r_sel - r_mean).^2));
            energy_MeV = (gamma_sel - 1) * m_e * c^2 / e_charge / 1e6;
            energy_mean = mean(energy_MeV);
            energy_spread = std(energy_MeV);
            
            % Clean energy data
            valid_energy = isfinite(energy_MeV) & energy_MeV > 0;
            
            figure('Position', [150+ip*30, 150+ip*30, 1400, 800], ...
                   'Name', sprintf('P2 Beam: %s', plane_name));
            
            % --- Subplot 1: Cross-section ---
            subplot(2,3,1);
            theta_random = 2*pi*rand(n_selected, 1);
            x_sel = r_sel .* cos(theta_random);
            y_sel = r_sel .* sin(theta_random);
            
            try
                e_min = min(energy_MeV(valid_energy));
                e_max = max(energy_MeV(valid_energy));
                if (e_max - e_min) < 0.005
                    e_center = mean(energy_MeV(valid_energy));
                    e_min = e_center - 0.005;
                    e_max = e_center + 0.005;
                end
                scatter(x_sel(valid_energy)*1000, y_sel(valid_energy)*1000, ...
                        10, energy_MeV(valid_energy), 'filled');
                caxis([e_min e_max]);
                colorbar; colormap(gca, 'jet');
            catch
                scatter(x_sel*1000, y_sel*1000, 10, 'b', 'filled');
                colorbar;
            end
            xlabel('x (mm)'); ylabel('y (mm)');
            title('Beam Cross-Section', 'FontSize', 14);
            axis equal; grid on;
            xlim([-65 65]); ylim([-65 65]);
            
            % --- Subplot 2: Phase space ---
            subplot(2,3,2);
            pr_norm = pr_sel ./ (gamma_sel * m_e * c);
            scatter(r_sel*1000, pr_norm*1000, 10, 'b.');
            hold on;
            r_centered = r_sel - r_mean;
            pr_centered = pr_norm - mean(pr_norm);
            r2_avg = mean(r_centered.^2);
            pr2_avg = mean(pr_centered.^2);
            r_pr_avg = mean(r_centered .* pr_centered);
            emit_rms = sqrt(r2_avg * pr2_avg - r_pr_avg^2);
            if emit_rms > 1e-10
                beta_twiss = r2_avg / emit_rms;
                alpha_twiss = -r_pr_avg / emit_rms;
                theta_ellipse = linspace(0, 2*pi, 100);
                ellipse_r = sqrt(emit_rms * beta_twiss) * cos(theta_ellipse);
                ellipse_pr = sqrt(emit_rms / beta_twiss) * ...
                            (-alpha_twiss * cos(theta_ellipse) - sin(theta_ellipse));
                plot(ellipse_r*1000 + r_mean*1000, ellipse_pr*1000, 'r-', 'LineWidth', 2);
                if alpha_twiss > 0.1
                    text(0.05, 0.95, 'Converging', 'Units', 'normalized', 'Color', 'red', 'FontWeight', 'bold');
                elseif alpha_twiss < -0.1
                    text(0.05, 0.95, 'Diverging', 'Units', 'normalized', 'Color', 'blue', 'FontWeight', 'bold');
                else
                    text(0.05, 0.95, 'Collimated', 'Units', 'normalized', 'Color', 'green', 'FontWeight', 'bold');
                end
            end
            xlabel('r (mm)'); ylabel('r'' (mrad)');
            title('r-r'' Phase Space', 'FontSize', 14);
            legend('Particles', 'RMS Ellipse', 'Location', 'best'); grid on;
            
            % --- Subplot 3: Radial distribution ---
            subplot(2,3,3);
            histogram(r_sel*1000, 20, 'FaceColor', 'g', 'EdgeColor', 'none');
            xlabel('r (mm)'); ylabel('Count');
            title('Radial Distribution', 'FontSize', 14);
            grid on; xlim([0 65]);
            
            % --- Subplot 4: Angular momentum ---
            subplot(2,3,4);
            Lz_sel = r_sel .* ptheta_sel;
            Lz_normalized = Lz_sel / (m_e * c);
            scatter(r_sel*1000, Lz_normalized, 10, 'b.');
            xlabel('r (mm)'); ylabel('L_z/(m_e c) (m)');
            title('     Angular Momentum vs Radius', 'FontSize', 14); grid on;
            % Have reserved space in the Title for exponential decade 
            % --- Subplot 5: Lz histogram ---
            subplot(2,3,5);
            histogram(Lz_normalized, 30, 'FaceColor', 'c', 'EdgeColor', 'none');
            xlabel('L_z/(m_e c) (m)'); ylabel('Count');
            title('     Angular Momentum Distribution', 'FontSize', 14); grid on;
            
            % --- Subplot 6: Energy vs radius ---
            subplot(2,3,6);
            scatter(r_sel(valid_energy)*1000, energy_MeV(valid_energy), 10, ...
                    energy_MeV(valid_energy), 'filled');
            colormap(gca, 'hot'); colorbar;
            xlabel('r (mm)'); ylabel('Energy (MeV)');
            title('Energy vs Radius', 'FontSize', 14); grid on;
            
            sgtitle(sprintf('PULSE 2: %s — %d particles, r_{rms}=%.1f mm, E=%.3f±%.3f MeV', ...
                    plane_name, n_selected, r_rms*1000, energy_mean, energy_spread), 'FontSize', 16);
        else
            fprintf('  Skipping %s (P2): only %d particles\n', ...
                    ANALYSIS_LOCATION_NAMES{ip}, n_selected);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%% updated 02.25.2026  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================================================================================
%% FIX 4: EXPANDED P3 POST-SIMULATION ANALYSIS (5 → 15 PLANES)
%% Replace the existing P3 analysis block (~lines 7530-7900)
%% ==================================================================================

if exist('steady_state_beam_pulse3', 'var') && steady_state_beam_pulse3.n_total > 1000
    fprintf('\n=== ENHANCED POST-SIMULATION BEAM ANALYSIS - PULSE 3 ===\n');
    fprintf('Analyzing beam at %d locations along 8.3m beamline\n', N_ANALYSIS_PLANES);
    
    for ip = 1:N_ANALYSIS_PLANES
        z_plane = ANALYSIS_LOCATIONS(ip) / 1000;
        plane_name = sprintf('%s (%dmm) - P3', ANALYSIS_LOCATION_NAMES{ip}, ANALYSIS_LOCATIONS(ip));
        
        dz_window = steady_state_beam_pulse3.vz * dt * 30;
        in_plane = abs(steady_state_beam_pulse3.z - z_plane) < abs(dz_window);
        
        if sum(in_plane) < 100
            in_plane = abs(steady_state_beam_pulse3.z - z_plane) < 0.020;
        end
        
        n_selected = sum(in_plane);
        
        if n_selected > 50
            r_sel = steady_state_beam_pulse3.r(in_plane);
            pr_sel = steady_state_beam_pulse3.pr(in_plane);
            pz_sel = steady_state_beam_pulse3.pz(in_plane);
            ptheta_sel = steady_state_beam_pulse3.ptheta(in_plane);
            gamma_sel = steady_state_beam_pulse3.gamma(in_plane);
            
            r_mean = mean(r_sel);
            r_rms = sqrt(mean((r_sel - r_mean).^2));
            energy_MeV = (gamma_sel - 1) * m_e * c^2 / e_charge / 1e6;
            energy_mean = mean(energy_MeV);
            energy_spread = std(energy_MeV);
            valid_energy = isfinite(energy_MeV) & energy_MeV > 0;
            
            figure('Position', [200+ip*30, 200+ip*30, 1400, 800], ...
                   'Name', sprintf('P3 Beam: %s', plane_name));
            
            % [IDENTICAL 6-subplot structure as P1 and P2 above]
            % Subplot 1: Cross-section with energy color
            subplot(2,3,1);
            theta_random = 2*pi*rand(n_selected, 1);
            x_sel = r_sel .* cos(theta_random);
            y_sel = r_sel .* sin(theta_random);
            try
                e_min = min(energy_MeV(valid_energy));
                e_max = max(energy_MeV(valid_energy));
                if (e_max - e_min) < 0.005
                    e_center = mean(energy_MeV(valid_energy));
                    e_min = e_center - 0.005; e_max = e_center + 0.005;
                end
                scatter(x_sel(valid_energy)*1000, y_sel(valid_energy)*1000, 10, energy_MeV(valid_energy), 'filled');
                caxis([e_min e_max]); colorbar; colormap(gca, 'jet');
            catch
                scatter(x_sel*1000, y_sel*1000, 10, 'b', 'filled'); colorbar;
            end
            xlabel('x (mm)'); ylabel('y (mm)');
            title('Beam Cross-Section', 'FontSize', 14);
            axis equal; grid on; xlim([-65 65]); ylim([-65 65]);
            
            % Subplot 2: Phase space
            subplot(2,3,2);
            pr_norm = pr_sel ./ (gamma_sel * m_e * c);
            scatter(r_sel*1000, pr_norm*1000, 10, 'b.'); hold on;
            r_centered = r_sel - r_mean;
            pr_centered = pr_norm - mean(pr_norm);
            r2_avg = mean(r_centered.^2); pr2_avg = mean(pr_centered.^2);
            r_pr_avg = mean(r_centered .* pr_centered);
            emit_rms = sqrt(r2_avg * pr2_avg - r_pr_avg^2);
            if emit_rms > 1e-10
                beta_twiss = r2_avg / emit_rms; alpha_twiss = -r_pr_avg / emit_rms;
                theta_e = linspace(0, 2*pi, 100);
                el_r = sqrt(emit_rms * beta_twiss) * cos(theta_e);
                el_pr = sqrt(emit_rms / beta_twiss) * (-alpha_twiss * cos(theta_e) - sin(theta_e));
                plot(el_r*1000 + r_mean*1000, el_pr*1000, 'r-', 'LineWidth', 2);
                if alpha_twiss > 0.1, cond_str = 'Converging'; cond_col = 'red';
                elseif alpha_twiss < -0.1, cond_str = 'Diverging'; cond_col = 'blue';
                else, cond_str = 'Collimated'; cond_col = 'green'; 
                end
                text(0.05, 0.95, cond_str, 'Units', 'normalized', 'Color', cond_col, 'FontWeight', 'bold');
            end
            xlabel('r (mm)'); ylabel('r'' (mrad)');
            title('r-r'' Phase Space', 'FontSize', 14);
            legend('Particles', 'RMS Ellipse', 'Location', 'best'); grid on;
            
            subplot(2,3,3);
            histogram(r_sel*1000, 20, 'FaceColor', 'g', 'EdgeColor', 'none');
            xlabel('r (mm)'); ylabel('Count'); title('Radial Distribution'); 
            grid on; xlim([0 65]);
            
            subplot(2,3,4);
            Lz_sel = r_sel .* ptheta_sel; Lz_normalized = Lz_sel / (m_e * c);
            scatter(r_sel*1000, Lz_normalized, 10, 'b.');
            xlabel('r (mm)'); ylabel('L_z/(m_e c) (m)'); 
            title('     Angular Momentum vs Radius'); grid on;
            
            subplot(2,3,5);
            histogram(Lz_normalized, 30, 'FaceColor', 'c', 'EdgeColor', 'none');
            xlabel('L_z/(m_e c) (m)'); ylabel('Count'); 
            title('Ang. Mom. Distribution'); grid on;
            
            subplot(2,3,6);
            scatter(r_sel(valid_energy)*1000, energy_MeV(valid_energy), 10, energy_MeV(valid_energy), 'filled');
            colormap(gca, 'hot'); colorbar;
            xlabel('r (mm)'); ylabel('Energy (MeV)'); 
            title('Energy vs Radius'); grid on;
            
            sgtitle(sprintf('PULSE 3: %s — %d particles, r_{rms}=%.1f mm, E=%.3f±%.3f MeV', ...
                    plane_name, n_selected, r_rms*1000, energy_mean, energy_spread), 'FontSize', 16);
        else
            fprintf('  Skipping %s (P3): only %d particles\n', ANALYSIS_LOCATION_NAMES{ip}, n_selected);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%% updated 02.25.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================================================================================
%% FIX 5: EXPANDED P4 POST-SIMULATION ANALYSIS (5 → 15 PLANES)
%% Replace the existing P4 analysis block
%% ==================================================================================

if exist('steady_state_beam_pulse4', 'var') && steady_state_beam_pulse4.n_total > 1000
    fprintf('\n=== ENHANCED POST-SIMULATION BEAM ANALYSIS - PULSE 4 ===\n');
    fprintf('Analyzing beam at %d locations along 8.3m beamline\n', N_ANALYSIS_PLANES);
    
    for ip = 1:N_ANALYSIS_PLANES
        z_plane = ANALYSIS_LOCATIONS(ip) / 1000;
        plane_name = sprintf('%s (%dmm) - P4', ANALYSIS_LOCATION_NAMES{ip}, ANALYSIS_LOCATIONS(ip));
        
        dz_window = steady_state_beam_pulse4.vz * dt * 30;
        in_plane = abs(steady_state_beam_pulse4.z - z_plane) < abs(dz_window);
        
        if sum(in_plane) < 100
            in_plane = abs(steady_state_beam_pulse4.z - z_plane) < 0.020;
        end
        
        n_selected = sum(in_plane);
        
        if n_selected > 50
            r_sel = steady_state_beam_pulse4.r(in_plane);
            pr_sel = steady_state_beam_pulse4.pr(in_plane);
            pz_sel = steady_state_beam_pulse4.pz(in_plane);
            ptheta_sel = steady_state_beam_pulse4.ptheta(in_plane);
            gamma_sel = steady_state_beam_pulse4.gamma(in_plane);
            
            r_mean = mean(r_sel);
            r_rms = sqrt(mean((r_sel - r_mean).^2));
            energy_MeV = (gamma_sel - 1) * m_e * c^2 / e_charge / 1e6;
            energy_mean = mean(energy_MeV);
            energy_spread = std(energy_MeV);
            valid_energy = isfinite(energy_MeV) & energy_MeV > 0;
            
            figure('Position', [250+ip*30, 250+ip*30, 1400, 800], ...
                   'Name', sprintf('P4 Beam: %s', plane_name));
            
            % [IDENTICAL 6-subplot structure]
            subplot(2,3,1);
            theta_random = 2*pi*rand(n_selected, 1);
            x_sel = r_sel .* cos(theta_random);
            y_sel = r_sel .* sin(theta_random);
            try
                e_min = min(energy_MeV(valid_energy)); e_max = max(energy_MeV(valid_energy));
                if (e_max - e_min) < 0.005
                    e_center = mean(energy_MeV(valid_energy));
                    e_min = e_center - 0.005; e_max = e_center + 0.005;
                end
                scatter(x_sel(valid_energy)*1000, y_sel(valid_energy)*1000, 10, energy_MeV(valid_energy), 'filled');
                caxis([e_min e_max]); colorbar; colormap(gca, 'jet');
            catch
                scatter(x_sel*1000, y_sel*1000, 10, 'b', 'filled'); colorbar;
            end
            xlabel('x (mm)'); ylabel('y (mm)'); title('Beam Cross-Section');
            axis equal; grid on; xlim([-65 65]); ylim([-65 65]);
            
            subplot(2,3,2);
            pr_norm = pr_sel ./ (gamma_sel * m_e * c);
            scatter(r_sel*1000, pr_norm*1000, 10, 'b.'); hold on;
            r_centered = r_sel - r_mean; pr_centered = pr_norm - mean(pr_norm);
            r2_avg = mean(r_centered.^2); pr2_avg = mean(pr_centered.^2);
            r_pr_avg = mean(r_centered .* pr_centered);
            emit_rms = sqrt(r2_avg * pr2_avg - r_pr_avg^2);
            if emit_rms > 1e-10
                beta_twiss = r2_avg / emit_rms; alpha_twiss = -r_pr_avg / emit_rms;
                theta_e = linspace(0, 2*pi, 100);
                el_r = sqrt(emit_rms * beta_twiss) * cos(theta_e);
                el_pr = sqrt(emit_rms / beta_twiss) * (-alpha_twiss * cos(theta_e) - sin(theta_e));
                plot(el_r*1000 + r_mean*1000, el_pr*1000, 'r-', 'LineWidth', 2);
                if alpha_twiss > 0.1, cond_str = 'Converging'; cond_col = 'red';
                elseif alpha_twiss < -0.1, cond_str = 'Diverging'; cond_col = 'blue';
                else, cond_str = 'Collimated'; cond_col = 'green'; 
                end
                text(0.05, 0.95, cond_str, 'Units', 'normalized', 'Color', cond_col, 'FontWeight', 'bold');
            end
            xlabel('r (mm)'); ylabel('r'' (mrad)'); title('r-r'' Phase Space');
            legend('Particles', 'RMS Ellipse', 'Location', 'best'); grid on;
            
            subplot(2,3,3);
            histogram(r_sel*1000, 20, 'FaceColor', 'g', 'EdgeColor', 'none');
            xlabel('r (mm)'); ylabel('Count'); title('Radial Distribution'); 
            grid on; 
            xlim([0 65]);
            
            subplot(2,3,4);
            Lz_sel = r_sel .* ptheta_sel; Lz_normalized = Lz_sel / (m_e * c);
            scatter(r_sel*1000, Lz_normalized, 10, 'b.');
            xlabel('r (mm)'); ylabel('L_z/(m_e c) (m)'); 
            title('     Angular Momentum vs Radius'); grid on;
            
            subplot(2,3,5);
            histogram(Lz_normalized, 30, 'FaceColor', 'c', 'EdgeColor', 'none');
            xlabel('L_z/(m_e c) (m)'); ylabel('Count'); title('Ang. Mom. Distribution'); grid on;
            
            subplot(2,3,6);
            scatter(r_sel(valid_energy)*1000, energy_MeV(valid_energy), 10, energy_MeV(valid_energy), 'filled');
            colormap(gca, 'hot'); colorbar;
            xlabel('r (mm)'); ylabel('Energy (MeV)'); title('Energy vs Radius'); grid on;
            
            sgtitle(sprintf('PULSE 4: %s — %d particles, r_{rms}=%.1f mm, E=%.3f±%.3f MeV', ...
                    plane_name, n_selected, r_rms*1000, energy_mean, energy_spread), 'FontSize', 16);
        else
            fprintf('  Skipping %s (P4): only %d particles\n', ANALYSIS_LOCATION_NAMES{ip}, n_selected);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%% NEW TWISS ANALYSIS PARAMETR PULSE 1 %%%%%%%%%%%%%%%%%%
%% ==================== TWISS PARAMETER ANALYSIS ====================
%%  V3 compatible — uses steady_state_beam (captured at it=6000)

%% Resolve correct snapshot variable name
if exist('steady_state_beam','var') && steady_state_beam.n_total > 100
    beam_snap = steady_state_beam;
    fprintf('\n=== TWISS ANALYSIS using steady_state_beam (t=%.1f ns) ===\n', ...
            beam_snap.time*1e9);
elseif exist('beam_snapshot','var')
    beam_snap = beam_snapshot;
    fprintf('\n=== TWISS ANALYSIS using beam_snapshot ===\n');
else
    fprintf('\nWARNING: No beam snapshot found — Twiss analysis skipped.\n');
    beam_snap = [];
end

if ~isempty(beam_snap)

    twiss_locations = [254; 600; 1000; 1500; 1700; 2200; 2700; ...
                       3400; 3964; 4600; 5400; 6402; 6828; 7450; 8305];
    location_names  = {'Anode','Early_Drift','Mid_Drift1','Trans1','Trans2', ...
                       'Mid_Drift2','BPM1','Extension1','BPM2','Extension2', ...
                       'Late_Drift','BPM3','BPM4','Sol49','Exit'};
    n_twiss_planes  = length(twiss_locations);

    fprintf('  Planes: %d  |  z = %.0f – %.0f mm\n', ...
            n_twiss_planes, twiss_locations(1), twiss_locations(end));

    %% Pre-initialize struct array with NaN sentinels
    twiss_results = struct( ...
        'location', location_names, ...
        'z',        num2cell(twiss_locations'), ...
        'n_particles', num2cell(zeros(1,n_twiss_planes)), ...
        'r_rms',    num2cell(NaN(1,n_twiss_planes)), ...
        'div_rms',  num2cell(NaN(1,n_twiss_planes)), ...
        'emit_geo', num2cell(NaN(1,n_twiss_planes)), ...
        'emit_norm',num2cell(NaN(1,n_twiss_planes)), ...
        'beta',     num2cell(NaN(1,n_twiss_planes)), ...
        'alpha',    num2cell(NaN(1,n_twiss_planes)), ...
        'gamma_tw', num2cell(NaN(1,n_twiss_planes)), ...
        'condition',repmat({'Unknown'},1,n_twiss_planes));

    for ip = 1:n_twiss_planes

        %% [BUG2 FIX] Use z_target consistently — no z_plane reference
        z_target   = twiss_locations(ip) / 1000;   % metres
        dz_window  = 0.045;                         % ±45mm spatial window

        in_plane = abs(beam_snap.z - z_target) < dz_window;

        %% Fallback: widen window if too few particles
        if sum(in_plane) < 100
            in_plane = abs(beam_snap.z - z_target) < 0.090;
        end
        if sum(in_plane) < 50
            in_plane = abs(beam_snap.z - z_target) < 0.150;
        end

        n_sel = sum(in_plane);
        twiss_results(ip).n_particles = n_sel;

        if n_sel < 50
            fprintf('  %-12s z=%4.0fmm: only %d particles — skipped\n', ...
                    location_names{ip}, twiss_locations(ip), n_sel);
            continue
        end

        %% Extract phase space
        r_sel     = beam_snap.r(in_plane);
        pr_sel    = beam_snap.pr(in_plane);
        pz_sel    = beam_snap.pz(in_plane);
        gam_sel   = beam_snap.gamma(in_plane);

        %% Normalised transverse divergence r' = pr/(γ m_e c)
        pr_norm   = pr_sel ./ (gam_sel * m_e * c);

        %% Centre
        r_c  = r_sel  - mean(r_sel);
        pr_c = pr_norm - mean(pr_norm);

        %% Second moments
        r2   = mean(r_c.^2);
        pr2  = mean(pr_c.^2);
        rpr  = mean(r_c .* pr_c);

        %% Geometric RMS emittance
        emit_geo = sqrt(max(r2*pr2 - rpr^2, 0));

        if emit_geo < 1e-12
            fprintf('  %-12s z=%4.0fmm: emittance ~0 — skipped\n', ...
                    location_names{ip}, twiss_locations(ip));
            continue
        end

        %% Twiss parameters
        beta_tw  =  r2  / emit_geo;
        alpha_tw = -rpr / emit_geo;
        gamma_tw =  pr2 / emit_geo;
        twiss_check = beta_tw * gamma_tw - alpha_tw^2;

        %% Normalised emittance
        gam_avg  = mean(gam_sel);
        beta_rel = sqrt(1 - 1/gam_avg^2);
        emit_norm = emit_geo * gam_avg * beta_rel;

        %% Beam condition
        if     alpha_tw >  0.1,  cond_str = 'Converging';
        elseif alpha_tw < -0.1,  cond_str = 'Diverging';
        else,                    cond_str = 'Collimated';
        end

        %% Store
        twiss_results(ip).r_rms     = sqrt(r2)   * 1000;   % mm
        twiss_results(ip).div_rms   = sqrt(pr2)  * 1000;   % mrad
        twiss_results(ip).emit_geo  = emit_geo   * 1e6;    % mm-mrad
        twiss_results(ip).emit_norm = emit_norm  * 1e6;    % mm-mrad
        twiss_results(ip).beta      = beta_tw;             % m
        twiss_results(ip).alpha     = alpha_tw;
        twiss_results(ip).gamma_tw  = gamma_tw;            % 1/m
        twiss_results(ip).condition = cond_str;

        fprintf('  %-12s z=%4.0fmm: n=%5d  r=%5.2fmm  β=%5.3fm  α=%+6.3f  ε_n=%6.1f mm-mrad  %s\n', ...
                location_names{ip}, twiss_locations(ip), n_sel, ...
                twiss_results(ip).r_rms, beta_tw, alpha_tw, ...
                emit_norm*1e6, cond_str);
    end

    %% ============================================================
    %% PLOTTING — only planes with valid data
    %% ============================================================
    valid = ~cellfun(@(x) isnan(x), {twiss_results.beta});
    n_valid = sum(valid);

    fprintf('\n  Valid Twiss planes: %d / %d\n', n_valid, n_twiss_planes);

    if n_valid >= 2

        z_plot   = twiss_locations(valid);
        beta_pl  = cell2mat({twiss_results(valid).beta});
        alpha_pl = cell2mat({twiss_results(valid).alpha});
        gamma_pl = cell2mat({twiss_results(valid).gamma_tw});
        emit_pl  = cell2mat({twiss_results(valid).emit_norm});
        cond_pl  = {twiss_results(valid).condition};

        figure('Name','Twiss Parameter Analysis Along Beamline Pulse 1', ...
               'Position',[50 50 1600 900]);

        %% --- Beta function ---
        subplot(2,3,1);
        plot(z_plot, beta_pl, 'bo-', 'MarkerSize', 8, 'LineWidth', 2);
        xlabel('z (mm)');  ylabel('β (m)');
        title('Beta Function');
        xlim([0 8500]);  grid on;
        for i = 1:n_valid
            text(z_plot(i), beta_pl(i)*1.04, ...
                 sprintf('%.2f', beta_pl(i)), ...
                 'FontSize',7, 'HorizontalAlignment','center');
        end

        %% --- Alpha parameter ---
        subplot(2,3,2);
        plot(z_plot, alpha_pl, 'rs-', 'MarkerSize', 8, 'LineWidth', 2);
        hold on;
        yline(0,'k--','LineWidth',1);
        xlabel('z (mm)');  ylabel('α');
        title('Alpha Parameter (Convergence/Divergence)');
        xlim([0 8500]);  grid on;
        for i = 1:n_valid
            text(z_plot(i), alpha_pl(i) + 0.03*range(alpha_pl), ...
                 cond_pl{i}, 'FontSize', 7, 'HorizontalAlignment','center');
        end

        %% --- Gamma parameter ---
        subplot(2,3,3);
        plot(z_plot, gamma_pl, 'g^-', 'MarkerSize', 8, 'LineWidth', 2);
        xlabel('z (mm)');  ylabel('γ (1/m)');
        title('Gamma Parameter');
        xlim([0 8500]);  grid on;

        %% --- Normalised emittance ---
        subplot(2,3,4);
        plot(z_plot, emit_pl, 'md-', 'MarkerSize', 8, 'LineWidth', 2);
        xlabel('z (mm)');  ylabel('ε_n (mm-mrad)');
        title('Normalised Emittance');
        xlim([0 8500]);  grid on;
        for i = 1:n_valid
            text(z_plot(i), emit_pl(i)*1.02, ...
                 sprintf('%.0f', emit_pl(i)), ...
                 'FontSize', 7, 'HorizontalAlignment','center');
        end

        %% --- Phase advance ---
        subplot(2,3,5);
        if n_valid >= 2
            phase_adv = zeros(n_valid-1, 1);
            section_labels = cell(n_valid-1, 1);
            for i = 1:n_valid-1
                dz  = (z_plot(i+1) - z_plot(i)) / 1000;  % m
                b_m = 0.5*(beta_pl(i) + beta_pl(i+1));    % mean beta
                beta_rel_avg = sqrt(1 - 1/mean(gam_avg)^2);
                phase_adv(i) = dz / b_m;
                section_labels{i} = sprintf('%d-%d', ...
                    round(z_plot(i)), round(z_plot(i+1)));
            end
            bar(1:n_valid-1, phase_adv, 'FaceColor',[0.3 0.6 0.9]);
            set(gca,'XTick',1:n_valid-1,'XTickLabel',section_labels, ...
                'XTickLabelRotation',45);
            xlabel('Section');  ylabel('Phase Advance (rad)');
            title('Estimated Phase Advance per Section');
            grid on;
        end

        %% --- Summary text ---
        subplot(2,3,6);
        axis off;
        text(0.02, 0.97, 'TWISS PARAMETER SUMMARY PULSE 1', ...
             'FontWeight','bold','FontSize',12,'Units','normalized', ...
             'VerticalAlignment','top');
        y_pos = 0.99;
        dy    = 0.08;
        for i = 1:min(n_valid, 12)   % max 12 entries fit
            idx = find(valid);
            ii  = idx(i);
            line1 = sprintf('%s (z=%dmm):', ...
                            twiss_results(ii).location, twiss_locations(ii));
            line2 = sprintf('  β=%.3fm  α=%+.3f  ε_n=%.1f mm-mrad  %s', ...
                            twiss_results(ii).beta, twiss_results(ii).alpha, ...
                            twiss_results(ii).emit_norm, twiss_results(ii).condition);
            text(0.02, y_pos, line1, 'FontSize',8,'FontWeight','bold', ...
                 'Units','normalized','VerticalAlignment','top');
            text(0.02, y_pos-0.028, line2, 'FontSize',7, ...
                 'Units','normalized','VerticalAlignment','top');
            y_pos = y_pos - dy;
        end

        sgtitle(sprintf('Twiss Parameter Analysis Along Beamline — t=%.1f ns', ...
                        beam_snap.time*1e9), ...
                'FontSize',14,'FontWeight','bold');

        fprintf('  Twiss figure generated with %d planes.\n', n_valid);

    else
        fprintf('  WARNING: Only %d valid planes — need ≥2 to plot.\n', n_valid);
    end

end  %% ~isempty(beam_snap)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 72 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== POST-PROCESSING VISUALIZATION Pulse 1 Envelope====================
% Add after simulation completes (after line 415)
% Plot beam envelope evolution
figure('Position', [100 100 1400 800]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,1,1);
% Find time indices with good statistics
time_indices = 5000:500:10000;  % Sample every 1000 steps
colors = jet(length(time_indices));
hold on;

plot_count = 0;
for idx = 1:length(time_indices)
    it = time_indices(idx);
    r_valid = r_rms_history(it, :);
    
    % Find where we actually have data (non-zero values)
    has_data = r_valid > 0;
    if sum(has_data) > 10  % Need at least 10 points to plot
        z_plot = z_diagnostic(has_data);
        r_plot = r_valid(has_data);
        plot(z_plot*1000, r_plot*1000, 'o-', 'LineWidth', 2, ...
             'Color', colors(idx,:), 'DisplayName', sprintf('t=%.0f ns', t(it)*1e9));
        plot_count = plot_count + 1;
    end
end

if plot_count == 0
    fprintf('WARNING: No RMS radius data found in time indices\n');
    % Try to plot the last timestep with any data
    for it = nt:-100:1
        r_test = r_rms_history(it, :);
        if any(r_test > 0)
            has_data = r_test > 0;
            plot(z_diagnostic(has_data)*1000, r_test(has_data)*1000, 'b-', 'LineWidth', 2);
            fprintf('Plotted data from timestep %d\n', it);
            break;
        end
    end
end

plot([0 8310], [r_wall r_wall]*1000, 'r--', 'LineWidth', 2, 'DisplayName', 'Wall');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% Mark solenoid positions
%sol_positions = [372, 1145, 1268, 1369, 1492, 1594, 1717, 1819, 1942, 2043, 2166, ...
%    2268, 2391, 2493, 2616, 2717];  % mm
%for sp = sol_positions
%    plot([sp sp], [0 r_wall*1000], 'k:', 'LineWidth', 1.5);
%end
%%%%%%%%%%%%%%%%%%%% Updated sol positions 02.13.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define ALL 49 solenoid positions (z_c values from your solenoid definitions)
all_solenoid_positions = [
    -279;   % Sol 1 (cathode)
    372;    % Sol 2 (anode)
    1144.61; 1267.57; 1369.27;  % Sol 3-5
    % Sol 6 is steering (not plotted)
    1492.23; 1593.93; 1716.89; 1818.60;  % Sol 7-10
    1941.56; 2043.26;  % Sol 11-12
    % Sol 13 is steering
    2166.22; 2267.93; 2390.89; 2492.59; 2615.55; 2717.26;  % Sol 14-19
    % Extended solenoids 20-49
    2840.22; 2941.92; 3064.88; 3166.58; 3289.54; 3391.25;  % Sol 20-25
    3514.21; 3615.91; 3738.87; 3840.58; 3963.54; 4065.24;  % Sol 26-31
    4188.20; 4289.93; 4412.89; 4514.59; 4637.55;  % Sol 32-36
    % Sol 37 steering
    4739.25; 4862.21; 4963.92; 5086.88; 5188.58; 5311.54;  % Sol 38-43
    % Sol 44 steering
    5413.24; 5536.20; 5637.91; 5760.87;  % Sol 45-48
    7448.00];  % Sol 49 (final)

% Plot solenoid markers (vertical lines)
for sp = all_solenoid_positions
    plot([sp sp], [0 r_wall*1000], 'k:', 'LineWidth', 0.8, 'HandleVisibility', 'off');
end

% Highlight key solenoids with labels
key_solenoids = struct();
key_solenoids(1).z = -279; key_solenoids(1).name = 'S1';
key_solenoids(2).z = 372; key_solenoids(2).name = 'S2';
key_solenoids(3).z = 2717; key_solenoids(3).name = 'S19';
key_solenoids(4).z = 3964; key_solenoids(4).name = 'S30';
key_solenoids(5).z = 5413; key_solenoids(5).name = 'S45';
key_solenoids(6).z = 7448; key_solenoids(6).name = 'S49';

for ks = 1:length(key_solenoids)
    plot([key_solenoids(ks).z key_solenoids(ks).z], [0 r_wall*1000], ...
         'b:', 'LineWidth', 1, 'HandleVisibility', 'off');
    text(key_solenoids(ks).z, r_wall*1000*1.05, key_solenoids(ks).name, ...
         'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'blue', ...
         'FontWeight', 'bold');
end

% Add BPM markers (distinct from solenoids)
bpm_positions = [2760, 3964, 6401.8, 6827.6, 8305];
for bp = bpm_positions
    plot([bp bp], [0 r_wall*1000], 'm:', 'LineWidth', 1, 'HandleVisibility', 'off');
end

% Legend entry for solenoids
plot(NaN, NaN, 'k:', 'LineWidth', 1, 'DisplayName', 'Solenoids');
plot(NaN, NaN, 'm:', 'LineWidth', 1, 'DisplayName', 'BPMs');

xlabel('z position (mm)', 'FontSize', 14);
ylabel('RMS Radius (mm)', 'FontSize', 14);
title('Beam Envelope Evolution with Hardware Overlay - Pulse 1', 'FontSize', 16);
legend('Location', 'best');
xlim([0 8310]);
ylim([0 80]);
grid on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%xlabel('z position (mm)');
%ylabel('RMS Radius (mm)');
%title('Beam Envelope Evolution Pulse 1', 'FontSize', 18);
%legend('Location', 'best');
%xlim([-400 8310]);
%ylim([0 80]);
%grid on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Replace the subplot(2,1,2) section with:
subplot(2,1,2);
% Plot particle survival vs z at end of flat-top
it_steady = 6000;  % During steady state
% Find non-zero data
valid_data = n_particles_vs_z(it_steady, :) > 0;
if any(valid_data)
    z_valid = z_diagnostic(valid_data);
    n_valid = n_particles_vs_z(it_steady, valid_data);
    n_normalized = n_valid / max(n_valid);
    plot(z_valid*1000, n_normalized, 'b-', 'LineWidth', 2);
else
    fprintf('WARNING: No particle count data at timestep %d\n', it_steady);
end
xlabel('z position (mm)');
ylabel('Normalized Particle Count');
title('Particle Survival Along Beamline Pulse 1', 'FontSize', 18);
xlim([0 8310]);  % Force correct axis limits
grid on;

%%%%%%%%%%%%%%%%%%%%%% Additional Figure for Pulse 1 %%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== POST-PROCESSING VISUALIZATION Pulse 1 Envelope====================
% Add after simulation completes (after line 415)
% Plot beam envelope evolution
figure('Position', [100 100 1400 800]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,1,1);
% Find time indices with good statistics
time_indices = 5000:1000:10000;  % Sample every 1000 steps
colors = jet(length(time_indices));
hold on;

plot_count = 0;
for idx = 1:length(time_indices)
    it = time_indices(idx);
    r_valid = r_rms_history(it, :);
    
    % Find where we actually have data (non-zero values)
    has_data = r_valid > 0;
    if sum(has_data) > 10  % Need at least 10 points to plot
        z_plot = z_diagnostic(has_data);
        r_plot = r_valid(has_data);
        plot(z_plot*1000, r_plot*1000, 'o-', 'LineWidth', 2, ...
             'Color', colors(idx,:), 'DisplayName', sprintf('t=%.0f ns', t(it)*1e9));
        plot_count = plot_count + 1;
    end
end

if plot_count == 0
    fprintf('WARNING: No RMS radius data found in time indices\n');
    % Try to plot the last timestep with any data
    for it = nt:-100:1
        r_test = r_rms_history(it, :);
        if any(r_test > 0)
            has_data = r_test > 0;
            plot(z_diagnostic(has_data)*1000, r_test(has_data)*1000, 'b-', 'LineWidth', 2);
            fprintf('Plotted data from timestep %d\n', it);
            break;
        end
    end
end

plot([0 8310], [r_wall r_wall]*1000, 'r--', 'LineWidth', 2, 'DisplayName', 'Wall');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
% Mark solenoid positions
%sol_positions = [372, 1145, 1268, 1369, 1492, 1594, 1717, 1819, 1942, 2043, 2166, ...
%    2268, 2391, 2493, 2616, 2717];  % mm
%for sp = sol_positions
%    plot([sp sp], [0 r_wall*1000], 'k:', 'LineWidth', 1.5);
%end
%%%%%%%%%%%%%%%%%%%% Updated sol positions 02.13.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define ALL 49 solenoid positions (z_c values from your solenoid definitions)
all_solenoid_positions = [
    -279;   % Sol 1 (cathode)
    372;    % Sol 2 (anode)
    1144.61; 1267.57; 1369.27;  % Sol 3-5
    % Sol 6 is steering (not plotted)
    1492.23; 1593.93; 1716.89; 1818.60;  % Sol 7-10
    1941.56; 2043.26;  % Sol 11-12
    % Sol 13 is steering
    2166.22; 2267.93; 2390.89; 2492.59; 2615.55; 2717.26;  % Sol 14-19
    % Extended solenoids 20-49
    2840.22; 2941.92; 3064.88; 3166.58; 3289.54; 3391.25;  % Sol 20-25
    3514.21; 3615.91; 3738.87; 3840.58; 3963.54; 4065.24;  % Sol 26-31
    4188.20; 4289.93; 4412.89; 4514.59; 4637.55;  % Sol 32-36
    % Sol 37 steering
    4739.25; 4862.21; 4963.92; 5086.88; 5188.58; 5311.54;  % Sol 38-43
    % Sol 44 steering
    5413.24; 5536.20; 5637.91; 5760.87;  % Sol 45-48
    7448.00];  % Sol 49 (final)

% Plot solenoid markers (vertical lines)
for sp = all_solenoid_positions
    plot([sp sp], [0 r_wall*1000], 'k:', 'LineWidth', 0.8, 'HandleVisibility', 'off');
end

% Highlight key solenoids with labels
key_solenoids = struct();
key_solenoids(1).z = -279; key_solenoids(1).name = 'S1';
key_solenoids(2).z = 372; key_solenoids(2).name = 'S2';
key_solenoids(3).z = 2717; key_solenoids(3).name = 'S19';
key_solenoids(4).z = 3964; key_solenoids(4).name = 'S30';
key_solenoids(5).z = 5413; key_solenoids(5).name = 'S45';
key_solenoids(6).z = 7448; key_solenoids(6).name = 'S49';

for ks = 1:length(key_solenoids)
    plot([key_solenoids(ks).z key_solenoids(ks).z], [0 r_wall*1000], ...
         'b:', 'LineWidth', 1, 'HandleVisibility', 'off');
    text(key_solenoids(ks).z, r_wall*1000*1.05, key_solenoids(ks).name, ...
         'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'blue', ...
         'FontWeight', 'bold');
end

% Add BPM markers (distinct from solenoids)
bpm_positions = [2760, 3964, 6401.8, 6827.6, 8305];
for bp = bpm_positions
    plot([bp bp], [0 r_wall*1000], 'm:', 'LineWidth', 1, 'HandleVisibility', 'off');
end

% Legend entry for solenoids
plot(NaN, NaN, 'k:', 'LineWidth', 1, 'DisplayName', 'Solenoids');
plot(NaN, NaN, 'm:', 'LineWidth', 1, 'DisplayName', 'BPMs');

xlabel('z position (mm)', 'FontSize', 14);
ylabel('RMS Radius (mm)', 'FontSize', 14);
title('Beam Envelope Evolution with Hardware Overlay - Pulse 1', 'FontSize', 16);
legend('Location', 'best');
xlim([0 8310]);
ylim([0 80]);
grid on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%xlabel('z position (mm)');
%ylabel('RMS Radius (mm)');
%title('Beam Envelope Evolution Pulse 1', 'FontSize', 18);
%legend('Location', 'best');
%xlim([-400 8310]);
%ylim([0 80]);
%grid on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Replace the subplot(2,1,2) section with:
subplot(2,1,2);
% Plot particle survival vs z at end of flat-top
it_steady = 6000;  % During steady state
% Find non-zero data
valid_data = n_particles_vs_z(it_steady, :) > 0;
if any(valid_data)
    z_valid = z_diagnostic(valid_data);
    n_valid = n_particles_vs_z(it_steady, valid_data);
    n_normalized = n_valid / max(n_valid);
    plot(z_valid*1000, n_normalized, 'b-', 'LineWidth', 2);
else
    fprintf('WARNING: No particle count data at timestep %d\n', it_steady);
end
xlabel('z position (mm)');
ylabel('Normalized Particle Count');
title('Particle Survival Along Beamline Pulse 1', 'FontSize', 18);
xlim([0 8310]);  % Force correct axis limits
grid on;

%%%%%%%%%%%%%%%%%%%%%% Second Pulse Envelope Figure 23 %%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== POST-PROCESSING VISUALIZATION ====================
% Add after simulation completes (after line 415)
% Plot beam envelope evolution
if exist('steady_state_beam', 'var') && exist('steady_state_beam_pulse2', 'var')

figure('Position', [100 100 1400 800]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,1,1);
% Find time indices with good statistics
time_indices = 24500:500:29500;  % +20000 Sample every 1000 steps
colors = jet(length(time_indices));
hold on;

plot_count = 0;
for idx = 1:length(time_indices)
    it = time_indices(idx);
    r_valid = r_rms_history(it, :);
    
    % Find where we actually have data (non-zero values)
    has_data = r_valid > 0;
    if sum(has_data) > 10  % Need at least 10 points to plot
        z_plot = z_diagnostic(has_data);
        r_plot = r_valid(has_data);
        plot(z_plot*1000, r_plot*1000, 'o-', 'LineWidth', 2, ...
             'Color', colors(idx,:), 'DisplayName', sprintf('t=%.0f ns', t(it)*1e9));
        plot_count = plot_count + 1;
    end
end

if plot_count == 0
    fprintf('WARNING: No RMS radius data found in time indices\n');
    % Try to plot the last timestep with any data
    for it = nt:-100:1
        r_test = r_rms_history(it, :);
        if any(r_test > 0)
            has_data = r_test > 0;
            plot(z_diagnostic(has_data)*1000, r_test(has_data)*1000, 'b-', 'LineWidth', 2);
            fprintf('Plotted data from timestep %d\n', it);
            break;
        end
    end
end

plot([0 8310], [r_wall r_wall]*1000, 'r--', 'LineWidth', 2, 'DisplayName', 'Wall');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mark solenoid positions
%sol_positions = [372, 1145, 1268, 1369, 1492, 1594, 1717, 1819, 1942, 2043, 2166, ...
%   2268, 2391, 2493, 2616, 2717];  % mm
%for sp = sol_positions
%    plot([sp sp], [0 r_wall*1000], 'k:', 'LineWidth', 1.5);
%end
%%%%%%%%%%%%%%%%%%% Updated solenoids positions 02.13.2026 %%%%%%%%%%%%%%%%%%%%%%%%%
% Define ALL 49 solenoid positions (z_c values from your solenoid definitions)
all_solenoid_positions = [
    -279;   % Sol 1 (cathode)
    372;    % Sol 2 (anode)
    1144.61; 1267.57; 1369.27;  % Sol 3-5
    % Sol 6 is steering (not plotted)
    1492.23; 1593.93; 1716.89; 1818.60;  % Sol 7-10
    1941.56; 2043.26;  % Sol 11-12
    % Sol 13 is steering
    2166.22; 2267.93; 2390.89; 2492.59; 2615.55; 2717.26;  % Sol 14-19
    % Extended solenoids 20-49
    2840.22; 2941.92; 3064.88; 3166.58; 3289.54; 3391.25;  % Sol 20-25
    3514.21; 3615.91; 3738.87; 3840.58; 3963.54; 4065.24;  % Sol 26-31
    4188.20; 4289.93; 4412.89; 4514.59; 4637.55;  % Sol 32-36
    % Sol 37 steering
    4739.25; 4862.21; 4963.92; 5086.88; 5188.58; 5311.54;  % Sol 38-43
    % Sol 44 steering
    5413.24; 5536.20; 5637.91; 5760.87;  % Sol 45-48
    7448.00];  % Sol 49 (final)

% Plot solenoid markers (vertical lines)
for sp = all_solenoid_positions
    plot([sp sp], [0 r_wall*1000], 'k:', 'LineWidth', 0.8, 'HandleVisibility', 'off');
end

% Highlight key solenoids with labels
key_solenoids = struct();
key_solenoids(1).z = -279; key_solenoids(1).name = 'S1';
key_solenoids(2).z = 372; key_solenoids(2).name = 'S2';
key_solenoids(3).z = 2717; key_solenoids(3).name = 'S19';
key_solenoids(4).z = 3964; key_solenoids(4).name = 'S30';
key_solenoids(5).z = 5413; key_solenoids(5).name = 'S45';
key_solenoids(6).z = 7448; key_solenoids(6).name = 'S49';

for ks = 1:length(key_solenoids)
    plot([key_solenoids(ks).z key_solenoids(ks).z], [0 r_wall*1000], ...
         'b:', 'LineWidth', 1, 'HandleVisibility', 'off');
    text(key_solenoids(ks).z, r_wall*1000*1.05, key_solenoids(ks).name, ...
         'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'blue', ...
         'FontWeight', 'bold');
end

% Add BPM markers (distinct from solenoids)
bpm_positions = [2760, 3964, 6401.8, 6827.6, 8305];
for bp = bpm_positions
    plot([bp bp], [0 r_wall*1000], 'm:', 'LineWidth', 1, 'HandleVisibility', 'off');
end

% Legend entry for solenoids
plot(NaN, NaN, 'k:', 'LineWidth', 1, 'DisplayName', 'Solenoids');
plot(NaN, NaN, 'm:', 'LineWidth', 1, 'DisplayName', 'BPMs');

xlabel('z position (mm)', 'FontSize', 14);
ylabel('RMS Radius (mm)', 'FontSize', 14);
title('Beam Envelope Evolution with Hardware Overlay_Pulse 2', 'FontSize', 16);
legend('Location', 'best');
xlim([0 8310]);
ylim([0 80]);
grid on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%xlabel('z position (mm)');
%ylabel('RMS Radius (mm)');
%title('Beam Envelope Evolution Pulse 2', 'FontSize', 18);
%legend('Location', 'best');
%xlim([0 8310]);
%ylim([0 80]);
%grid on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Replace the subplot(2,1,2) section with:
subplot(2,1,2);
% Plot particle survival vs z at end of flat-top
it_steady = 27000;  % During steady state
% Find non-zero data
valid_data = n_particles_vs_z(it_steady, :) > 0;
if any(valid_data)
    z_valid = z_diagnostic(valid_data);
    n_valid = n_particles_vs_z(it_steady, valid_data);
    n_normalized = n_valid / max(n_valid);
    plot(z_valid*1000, n_normalized, 'b-', 'LineWidth', 2);
else
    fprintf('WARNING: No particle count data at timestep %d\n', it_steady);
end
xlabel('z position (mm)');
ylabel('Normalized Particle Count');
title('Particle Survival Along Beamline','FontSize', 18);
xlim([0 8310]);  % Force correct axis limits
grid on;
end
%%%%%%%%%%%%%%%%%%%%%% Third Pulse Envelope Figure 73 %%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== POST-PROCESSING VISUALIZATION ====================
% Add after simulation completes (after line 415)
% Plot beam envelope evolution
if exist('steady_state_beam', 'var') && exist('steady_state_beam_pulse3', 'var')

figure('Position', [100 100 1400 800]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,1,1);
% Find time indices with good statistics
time_indices = 44500:500:49500;  % +20000 Sample every 1000 steps
colors = jet(length(time_indices));
hold on;

plot_count = 0;
for idx = 1:length(time_indices)
    it = time_indices(idx);
    r_valid = r_rms_history(it, :);
    
    % Find where we actually have data (non-zero values)
    has_data = r_valid > 0;
    if sum(has_data) > 10  % Need at least 10 points to plot
        z_plot = z_diagnostic(has_data);
        r_plot = r_valid(has_data);
        plot(z_plot*1000, r_plot*1000, 'o-', 'LineWidth', 2, ...
             'Color', colors(idx,:), 'DisplayName', sprintf('t=%.0f ns', t(it)*1e9));
        plot_count = plot_count + 1;
    end
end

if plot_count == 0
    fprintf('WARNING: No RMS radius data found in time indices\n');
    % Try to plot the last timestep with any data
    for it = nt:-100:1
        r_test = r_rms_history(it, :);
        if any(r_test > 0)
            has_data = r_test > 0;
            plot(z_diagnostic(has_data)*1000, r_test(has_data)*1000, 'b-', 'LineWidth', 2);
            fprintf('Plotted data from timestep %d\n', it);
            break;
        end
    end
end

plot([0 8310], [r_wall r_wall]*1000, 'r--', 'LineWidth', 2, 'DisplayName', 'Wall');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Mark solenoid positions
%sol_positions = [372, 1145, 1268, 1369, 1492, 1594, 1717, 1819, 1942, 2043, 2166, ...
%   2268, 2391, 2493, 2616, 2717];  % mm
%for sp = sol_positions
%    plot([sp sp], [0 r_wall*1000], 'k:', 'LineWidth', 1.5);
%end
%%%%%%%%%%%%%%%%%%% Updated solenoids positions 02.13.2026 %%%%%%%%%%%%%%%%%%%%%%%%%
% Define ALL 49 solenoid positions (z_c values from your solenoid definitions)
all_solenoid_positions = [
    -279;   % Sol 1 (cathode)
    372;    % Sol 2 (anode)
    1144.61; 1267.57; 1369.27;  % Sol 3-5
    % Sol 6 is steering (not plotted)
    1492.23; 1593.93; 1716.89; 1818.60;  % Sol 7-10
    1941.56; 2043.26;  % Sol 11-12
    % Sol 13 is steering
    2166.22; 2267.93; 2390.89; 2492.59; 2615.55; 2717.26;  % Sol 14-19
    % Extended solenoids 20-49
    2840.22; 2941.92; 3064.88; 3166.58; 3289.54; 3391.25;  % Sol 20-25
    3514.21; 3615.91; 3738.87; 3840.58; 3963.54; 4065.24;  % Sol 26-31
    4188.20; 4289.93; 4412.89; 4514.59; 4637.55;  % Sol 32-36
    % Sol 37 steering
    4739.25; 4862.21; 4963.92; 5086.88; 5188.58; 5311.54;  % Sol 38-43
    % Sol 44 steering
    5413.24; 5536.20; 5637.91; 5760.87;  % Sol 45-48
    7448.00];  % Sol 49 (final)

% Plot solenoid markers (vertical lines)
for sp = all_solenoid_positions
    plot([sp sp], [0 r_wall*1000], 'k:', 'LineWidth', 0.8, 'HandleVisibility', 'off');
end

% Highlight key solenoids with labels
key_solenoids = struct();
key_solenoids(1).z = -279; key_solenoids(1).name = 'S1';
key_solenoids(2).z = 372; key_solenoids(2).name = 'S2';
key_solenoids(3).z = 2717; key_solenoids(3).name = 'S19';
key_solenoids(4).z = 3964; key_solenoids(4).name = 'S30';
key_solenoids(5).z = 5413; key_solenoids(5).name = 'S45';
key_solenoids(6).z = 7448; key_solenoids(6).name = 'S49';

for ks = 1:length(key_solenoids)
    plot([key_solenoids(ks).z key_solenoids(ks).z], [0 r_wall*1000], ...
         'b:', 'LineWidth', 1, 'HandleVisibility', 'off');
    text(key_solenoids(ks).z, r_wall*1000*1.05, key_solenoids(ks).name, ...
         'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'blue', ...
         'FontWeight', 'bold');
end

% Add BPM markers (distinct from solenoids)
bpm_positions = [2760, 3964, 6401.8, 6827.6, 8305];
for bp = bpm_positions
    plot([bp bp], [0 r_wall*1000], 'm:', 'LineWidth', 1, 'HandleVisibility', 'off');
end

% Legend entry for solenoids
plot(NaN, NaN, 'k:', 'LineWidth', 1, 'DisplayName', 'Solenoids (45 total)');
plot(NaN, NaN, 'm:', 'LineWidth', 1, 'DisplayName', 'BPMs (5 total)');

xlabel('z position (mm)', 'FontSize', 14);
ylabel('RMS Radius (mm)', 'FontSize', 14);
title('Beam Envelope Evolution with Hardware Overlay_Pulse 3', 'FontSize', 16);
legend('Location', 'best');
xlim([0 8310]);
ylim([0 80]);
grid on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%xlabel('z position (mm)');
%ylabel('RMS Radius (mm)');
%title('Beam Envelope Evolution Pulse 2', 'FontSize', 18);
%legend('Location', 'best');
%xlim([0 8310]);
%ylim([0 80]);
%grid on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Replace the subplot(2,1,2) section with:
subplot(2,1,2);
% Plot particle survival vs z at end of flat-top
it_steady = 47000;  % During steady state
% Find non-zero data
valid_data = n_particles_vs_z(it_steady, :) > 0;
if any(valid_data)
    z_valid = z_diagnostic(valid_data);
    n_valid = n_particles_vs_z(it_steady, valid_data);
    n_normalized = n_valid / max(n_valid);
    plot(z_valid*1000, n_normalized, 'b-', 'LineWidth', 2);
else
    fprintf('WARNING: No particle count data at timestep %d\n', it_steady);
end
xlabel('z position (mm)');
ylabel('Normalized Particle Count');
title('Particle Survival Along Beamline','FontSize', 18);
xlim([0 8310]);  % Force correct axis limits
grid on;
end

%%%%%%%%%%%%%%%%%%%%%% Fourth Pulse Envelope Figure 25 %%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== POST-PROCESSING VISUALIZATION Pulse 4 =================
% Add after simulation completes (after line 415)
% Plot beam envelope evolution
if exist('steady_state_beam', 'var') && exist('steady_state_beam_pulse4', 'var')

figure('Position', [100 100 1400 800]);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
subplot(2,1,1);
% Find time indices with good statistics
time_indices = 64500:500:69500;  % +60000 Sample every 1000 steps
colors = jet(length(time_indices));
hold on;

plot_count = 0;
for idx = 1:length(time_indices)
    it = time_indices(idx);
    r_valid = r_rms_history(it, :);
    
    % Find where we actually have data (non-zero values)
    has_data = r_valid > 0;
    if sum(has_data) > 10  % Need at least 10 points to plot
        z_plot = z_diagnostic(has_data);
        r_plot = r_valid(has_data);
        plot(z_plot*1000, r_plot*1000, 'o-', 'LineWidth', 2, ...
             'Color', colors(idx,:), 'DisplayName', sprintf('t=%.0f ns', t(it)*1e9));
        plot_count = plot_count + 1;
    end
end

if plot_count == 0
    fprintf('WARNING: No RMS radius data found in time indices\n');
    % Try to plot the last timestep with any data
    for it = nt:-100:1
        r_test = r_rms_history(it, :);
        if any(r_test > 0)
            has_data = r_test > 0;
            plot(z_diagnostic(has_data)*1000, r_test(has_data)*1000, 'b-', 'LineWidth', 2);
            fprintf('Plotted data from timestep %d\n', it);
            break;
        end
    end
end

plot([0 8310], [r_wall r_wall]*1000, 'r--', 'LineWidth', 2, 'DisplayName', 'Wall');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Added all solenoids %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Define ALL 49 solenoid positions (z_c values from your solenoid definitions)
all_solenoid_positions = [
    -279;   % Sol 1 (cathode)
    372;    % Sol 2 (anode)
    1144.61; 1267.57; 1369.27;  % Sol 3-5
    % Sol 6 is steering (not plotted)
    1492.23; 1593.93; 1716.89; 1818.60;  % Sol 7-10
    1941.56; 2043.26;  % Sol 11-12
    % Sol 13 is steering
    2166.22; 2267.93; 2390.89; 2492.59; 2615.55; 2717.26;  % Sol 14-19
    % Extended solenoids 20-49
    2840.22; 2941.92; 3064.88; 3166.58; 3289.54; 3391.25;  % Sol 20-25
    3514.21; 3615.91; 3738.87; 3840.58; 3963.54; 4065.24;  % Sol 26-31
    4188.20; 4289.93; 4412.89; 4514.59; 4637.55;  % Sol 32-36
    % Sol 37 steering
    4739.25; 4862.21; 4963.92; 5086.88; 5188.58; 5311.54;  % Sol 38-43
    % Sol 44 steering
    5413.24; 5536.20; 5637.91; 5760.87;  % Sol 45-48
    7448.00];  % Sol 49 (final)

% Plot solenoid markers (vertical lines)
for sp = all_solenoid_positions
    plot([sp sp], [0 r_wall*1000], 'k:', 'LineWidth', 0.8, 'HandleVisibility', 'off');
end

% Highlight key solenoids with labels
key_solenoids = struct();
key_solenoids(1).z = -279; key_solenoids(1).name = 'S1';
key_solenoids(2).z = 372; key_solenoids(2).name = 'S2';
key_solenoids(3).z = 2717; key_solenoids(3).name = 'S19';
key_solenoids(4).z = 3964; key_solenoids(4).name = 'S30';
key_solenoids(5).z = 5413; key_solenoids(5).name = 'S45';
key_solenoids(6).z = 7448; key_solenoids(6).name = 'S49';

for ks = 1:length(key_solenoids)
    plot([key_solenoids(ks).z key_solenoids(ks).z], [0 r_wall*1000], ...
         'b-', 'LineWidth', 2, 'HandleVisibility', 'off');
    text(key_solenoids(ks).z, r_wall*1000*1.05, key_solenoids(ks).name, ...
         'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', 'blue', ...
         'FontWeight', 'bold');
end

% Add BPM markers (distinct from solenoids)
bpm_positions = [2760, 3964, 6401.8, 6827.6, 8305];
for bp = bpm_positions
    plot([bp bp], [0 r_wall*1000], 'm-', 'LineWidth', 2.5, 'HandleVisibility', 'off');
end

% Legend entry for solenoids
plot(NaN, NaN, 'k:', 'LineWidth', 1, 'DisplayName', 'Solenoids (45 total)');
plot(NaN, NaN, 'm-', 'LineWidth', 2.5, 'DisplayName', 'BPMs (5 total)');

xlabel('z position (mm)', 'FontSize', 14);
ylabel('RMS Radius (mm)', 'FontSize', 14);
title('Beam Envelope Evolution with Hardware Overlay_Pulse 4', 'FontSize', 16);
legend('Location', 'best');
xlim([0 8310]);
ylim([0 80]);
grid on;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Replace the subplot(2,1,2) section with:
subplot(2,1,2);
% Plot particle survival vs z at end of flat-top
it_steady = 67000;  % During steady state
% Find non-zero data
valid_data = n_particles_vs_z(it_steady, :) > 0;
if any(valid_data)
    z_valid = z_diagnostic(valid_data);
    n_valid = n_particles_vs_z(it_steady, valid_data);
    n_normalized = n_valid / max(n_valid);
    plot(z_valid*1000, n_normalized, 'b-', 'LineWidth', 2);
else
    fprintf('WARNING: No particle count data at timestep %d\n', it_steady);
end
xlabel('z position (mm)');
ylabel('Normalized Particle Count');
title('Particle Survival Along Beamline pulse 4','FontSize', 18);
xlim([0 8310]);  % Force correct axis limits
grid on;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 26 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== PULSE 1 vs PULSE 2 COMPARISON FIGURE ====================
%% Location ~3360: Pulse 1 vs Pulse 2 Comparison
if PLOTS_AVAILABLE.pulse2_snapshot
 %   figure('Position', [100, 100, 1600, 900], 'Name', 'Pulse 1 vs Pulse 2 Comparison');
if exist('steady_state_beam', 'var') && exist('steady_state_beam_pulse2', 'var')
    
    figure('Position', [100, 100, 1600, 900], 'Name', 'Pulse 1 vs Pulse 2 Comparison');
    
    % Extract Pulse 1 data
    z1 = steady_state_beam.z * 1000;  % mm
    r1 = steady_state_beam.r * 1000;
    
    % Extract Pulse 2 data
    z2 = steady_state_beam_pulse2.z * 1000;
    r2 = steady_state_beam_pulse2.r * 1000;
    
    % Plot 1: RMS radius comparison
    subplot(2,3,1);
    
    % Bin both pulses
    z_bins = 0:50:8300;
    r1_rms = zeros(length(z_bins)-1, 1);
    r2_rms = zeros(length(z_bins)-1, 1);
    z_centers = zeros(length(z_bins)-1, 1);
    
    for ib = 1:length(z_bins)-1
        z_centers(ib) = (z_bins(ib) + z_bins(ib+1))/2;
        
        % Pulse 1
        in_bin = z1 >= z_bins(ib) & z1 < z_bins(ib+1);
        if sum(in_bin) > 20
            r1_rms(ib) = sqrt(mean(r1(in_bin).^2));
        else
            r1_rms(ib) = NaN;
        end
        
        % Pulse 2
        in_bin = z2 >= z_bins(ib) & z2 < z_bins(ib+1);
        if sum(in_bin) > 20
            r2_rms(ib) = sqrt(mean(r2(in_bin).^2));
        else
            r2_rms(ib) = NaN;
        end
    end
    
    hold on;
    plot(z_centers, r1_rms, 'b-o', 'LineWidth', 2, 'DisplayName', 'Pulse 1');
    plot(z_centers, r2_rms, 'r-s', 'LineWidth', 2, 'DisplayName', 'Pulse 2');
    yline(50, 'm--', 'LineWidth', 2, 'DisplayName', 'Target');
    xlabel('z (mm)');
    ylabel('RMS Radius (mm)');
    title('Beam Envelope: Pulse 1 vs Pulse 2');
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    ylim([0 80]);
    
    % Plot 2: Particle count comparison
    subplot(2,3,2);
    [n1, edges] = histcounts(z1, z_bins);
    [n2, ~] = histcounts(z2, z_bins);
    
    bar(z_centers, [n1; n2]', 'grouped');
    legend('Pulse 1', 'Pulse 2');
    xlabel('z (mm)');
    ylabel('Particles per bin');
    title('Longitudinal Distribution Comparison');
    grid on;
    
    % Plot 3: Radial distribution comparison
    subplot(2,3,3);
    histogram(r1, 30, 'FaceAlpha', 0.5, 'DisplayName', 'Pulse 1');
    hold on;
    histogram(r2, 30, 'FaceAlpha', 0.5, 'DisplayName', 'Pulse 2');
    xlabel('r (mm)');
    ylabel('Count');
    title('Radial Distribution Comparison');
    legend;
    grid on;
    
    % Plot 4: 2D density comparison - Pulse 1
    subplot(2,3,4);
    [N1, ze, re] = histcounts2(z1, r1, 0:25:8300, 0:1:80);
    imagesc(ze(1:end-1)+12.5, re(1:end-1)+0.5, log10(N1'+1));
    axis xy;
    colorbar;
    title('Pulse 1: 2D Density (t=194ns)');
    xlabel('z (mm)');
    ylabel('r (mm)');
    
    % Plot 5: 2D density - Pulse 2
    subplot(2,3,5);
    [N2, ~, ~] = histcounts2(z2, r2, 0:25:8300, 0:1:80);
    imagesc(ze(1:end-1)+12.5, re(1:end-1)+0.5, log10(N2'+1));
    axis xy;
    colorbar;
    title('Pulse 2: 2D Density (t=394ns)');
    xlabel('z (mm)');
    ylabel('r (mm)');
    
    % Plot 6: Difference map
    subplot(2,3,6);
    diff_map = N2 - N1;
    imagesc(ze(1:end-1)+12.5, re(1:end-1)+0.5, diff_map');
    axis xy;
    colorbar;
    title('Difference: Pulse 2 - Pulse 1');
    xlabel('z (mm)');
    ylabel('r (mm)');
    clim([-max(abs(diff_map(:))) max(abs(diff_map(:)))]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %colormap(gca, 'redblue');
    % Replace with:
    cmap_redblue = [linspace(0,1,128)', linspace(0,1,128)', ones(128,1); ...
                ones(128,1), linspace(1,0,128)', linspace(1,0,128)'];
    colormap(gca, cmap_redblue);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %sgtitle(sprintf('Pulse Comparison: Δ Transmission = %.2f%%', ...
    %      eff2 - eff1, 'FontSize', 14));
    %        pulse_diagnostics(2).efficiency - pulse_diagnostics(1).efficiency), ...
    sgtitle(sprintf('Pulse 1 vs Pulse 2 Comparison','FontSize', 18,'Bold'));        
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 11.20.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Fogure 25 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== ION FOCUSING SIGNATURE ANALYSIS ====================
%% Location ~3560: Ion Focusing Signature
if PLOTS_AVAILABLE.ion_data && PLOTS_AVAILABLE.pulse2_snapshot
    fprintf('\n=== ION-INDUCED FOCUSING ANALYSIS ===\n');

if ENABLE_ION_ACCUMULATION == true && ENABLE_MULTIPULSE == true && ...
   exist('steady_state_beam', 'var') && exist('steady_state_beam_pulse2', 'var')
    
    % Extract beam data
    z1 = steady_state_beam.z * 1000;
    r1 = steady_state_beam.r * 1000;
    z2 = steady_state_beam_pulse2.z * 1000;
    r2 = steady_state_beam_pulse2.r * 1000;
    
    % Calculate RMS radius in bins
    z_bins = 0:100:8300;  % 100mm bins for smooth comparison
    r1_rms_fine = zeros(length(z_bins)-1, 1);
    r2_rms_fine = zeros(length(z_bins)-1, 1);
    z_centers_fine = zeros(length(z_bins)-1, 1);
    
    for ib = 1:length(z_bins)-1
        z_centers_fine(ib) = (z_bins(ib) + z_bins(ib+1))/2;
        
        % Pulse 1
        in_bin = z1 >= z_bins(ib) & z1 < z_bins(ib+1);
        if sum(in_bin) > 30
            r1_rms_fine(ib) = sqrt(mean(r1(in_bin).^2));
        else
            r1_rms_fine(ib) = NaN;
        end
        
        % Pulse 2
        in_bin = z2 >= z_bins(ib) & z2 < z_bins(ib+1);
        if sum(in_bin) > 30
            r2_rms_fine(ib) = sqrt(mean(r2(in_bin).^2));
        else
            r2_rms_fine(ib) = NaN;
        end
    end
    
    % Calculate focusing signature
    r_diff = r2_rms_fine - r1_rms_fine;
    
    % Find regions of significant difference
    sig_diff = abs(r_diff) > 0.5;  % >0.5mm difference
    if any(sig_diff)
        fprintf('Regions with >0.5mm RMS radius difference:\n');
        z_sig = z_centers_fine(sig_diff);
        r_sig = r_diff(sig_diff);
        for i = 1:length(z_sig)
            fprintf('  z=%.0f mm: Δr=%.2f mm ', z_sig(i), r_sig(i));
            if r_sig(i) < 0
                fprintf('(P2 TIGHTER - ion focusing!)\n');
            else
                fprintf('(P2 WIDER - ion defocusing)\n');
            end
        end
    else
        fprintf('No significant ion-induced focusing detected\n');
        fprintf('(Maximum difference: %.3f mm - within noise)\n', max(abs(r_diff)));
    end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% FIGURE 25 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    %% Create focused comparison figure
    figure('Position', [100, 100, 1600, 900], 'Name', 'Ion Focusing Signature');
    
    % Plot 1: Envelope comparison with difference highlighted
    subplot(2,2,1);
    hold on;
    plot(z_centers_fine, r1_rms_fine, 'b-o', 'LineWidth', 2, ...
         'MarkerSize', 6, 'DisplayName', 'Pulse 1 (no ions)');
    plot(z_centers_fine, r2_rms_fine, 'r-s', 'LineWidth', 2, ...
         'MarkerSize', 6, 'DisplayName', 'Pulse 2 (with ions)');
    yline(50, 'm--', 'LineWidth', 2, 'DisplayName', 'Target');
    xlabel('z (mm)');
    ylabel('RMS Radius (mm)');
    title('Beam Envelope: Ion Focusing Effect');
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    ylim([0 80]);
    
    % Plot 2: Difference (Pulse 2 - Pulse 1)
    subplot(2,2,2);
    plot(z_centers_fine, r_diff, 'k-', 'LineWidth', 2);
    hold on;
    yline(0, 'r--', 'LineWidth', 1);
    % Highlight focusing regions
    focusing = r_diff < -0.2;  % P2 tighter by >0.2mm
    if any(focusing)
        scatter(z_centers_fine(focusing), r_diff(focusing), 50, 'g', 'filled');
    end
    defocusing = r_diff > 0.2;
    if any(defocusing)
        scatter(z_centers_fine(defocusing), r_diff(defocusing), 50, 'r', 'filled');
    end
    xlabel('z (mm)');
    ylabel('Δr_{rms} = r₂ - r₁ (mm)');
    title('Ion-Induced Radius Change');
    grid on;
    xlim([0 8310]);
    legend('Difference', 'Zero line', 'Focusing', 'Defocusing', ...
           'Location', 'best');
    
    % Plot 3: Ion density overlaid with beam envelope
    subplot(2,2,3);
yyaxis right
    ion_longitudinal = sum(ion_density_grid, 1);
    plot(sc_z*1000, ion_longitudinal, 'g-', 'LineWidth', 2);
    ylabel('Ion Line Density');   
 hold on;
    yyaxis left
    plot(z_centers_fine, r1_rms_fine, 'b-', 'LineWidth', 2); 
    plot(z_centers_fine, r2_rms_fine, 'r-', 'LineWidth', 2);
    ylabel('RMS Radius (mm)');
    ylim([0 80]);
    
    xlabel('z (mm)');
    title('Beam Envelope vs Ion Distribution');
    legend('Ion density','P1 envelope', 'P2 envelope',  'Location', 'best');
    grid on;
    xlim([0 8310]);
    
    % Plot 4: Ion space charge field profile
    subplot(2,2,4);
    % Calculate approximate ion SC field along axis
    ion_field_z = zeros(size(sc_z));
    for j = 1:length(sc_z)
        if sum(ion_density_grid(:, j)) > 0
            % Rough estimate: E = ρ*r/(2ε₀) for cylindrical distribution
            ion_charge = sum(ion_density_grid(:, j)) * e_charge;
            typical_r = 0.04;  % 40mm typical beam radius
            ion_field_z(j) = ion_charge / (2*pi*eps0*typical_r*sc_dz);
        end
    end
    
    plot(sc_z*1000, ion_field_z/1e3, 'g-', 'LineWidth', 2);
    xlabel('z (mm)');
    ylabel('Ion SC Field (kV/m)');
    title('Ion Space Charge Field Along Beamline');
    grid on;
    xlim([0 8310]);
    hold on;
    xline(254, 'r--', 'Anode', 'LineWidth', 1.5);
    
    sgtitle(sprintf('Ion-Induced Focusing: P2 vs P1 (%.0f total ions)', ...
                    round(max_ion_count)), 'FontSize', 16);
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 11.20.2025 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== QUANTIFY ION FOCUSING EFFECT ====================
%% Location ~3730: Quantify Ion Focusing Effect
if PLOTS_AVAILABLE.ion_data && PLOTS_AVAILABLE.pulse2_snapshot
    fprintf('\n=== QUANTITATIVE ION FOCUSING METRICS ===\n');
   if ENABLE_ION_ACCUMULATION && ENABLE_MULTIPULSE && ...
   exist('steady_state_beam', 'var') && exist('steady_state_beam_pulse2', 'var')
    
    fprintf('\n=== QUANTITATIVE ION FOCUSING METRICS ===\n');
    
    % Compare at key locations
    test_locations = [600, 1000, 1700, 2700];  % mm
    
    for loc = test_locations
        % Find particles near this location for both pulses
        tol = 50;  % ±50mm window
        
        % Pulse 1
        in_region_p1 = abs(steady_state_beam.z*1000 - loc) < tol;
        if sum(in_region_p1) > 100
            r1_loc = steady_state_beam.r(in_region_p1) * 1000;
            r1_rms_loc = sqrt(mean(r1_loc.^2));
        else
            r1_rms_loc = NaN;
        end
        
        % Pulse 2
        in_region_p2 = abs(steady_state_beam_pulse2.z*1000 - loc) < tol;
        if sum(in_region_p2) > 100
            r2_loc = steady_state_beam_pulse2.r(in_region_p2) * 1000;
            r2_rms_loc = sqrt(mean(r2_loc.^2));
        else
            r2_rms_loc = NaN;
        end
        
        % Calculate difference
        if ~isnan(r1_rms_loc) && ~isnan(r2_rms_loc)
            delta_r = r2_rms_loc - r1_rms_loc;
            percent_change = 100 * delta_r / r1_rms_loc;
            
            fprintf('\nAt z=%d mm:\n', loc);
            fprintf('  P1 RMS radius: %.2f mm\n', r1_rms_loc);
            fprintf('  P2 RMS radius: %.2f mm\n', r2_rms_loc);
            fprintf('  Difference: %.3f mm (%.2f%%)\n', delta_r, percent_change);
            
            if abs(percent_change) > 2
                if delta_r < 0
                    fprintf('  *** FOCUSING from ions detected! ***\n');
                else
                    fprintf('  *** DEFOCUSING from ions detected! ***\n');
                end
            else
                fprintf('  (Within statistical noise)\n');
            end
        end
    end
    
    % Overall transmission comparison
    fprintf('\n=== ION IMPACT ON TRANSMISSION ===\n');
    eff1 = 100 * pulse_diagnostics(1).particles_transmitted / ...
           pulse_diagnostics(1).particles_emitted;
    eff2 = 100 * pulse_diagnostics(2).particles_transmitted / ...
           pulse_diagnostics(2).particles_emitted;
    
    fprintf('Pulse 1 efficiency: %.3f%% (clean vacuum)\n', eff1);
    fprintf('Pulse 2 efficiency: %.3f%% (with ~%d ions)\n', ...
            eff2, round(max_ion_count));
    fprintf('Difference: %.3f%%\n', eff2 - eff1);
    
    if abs(eff2 - eff1) > 0.1
        if eff2 > eff1
            fprintf('*** Ion focusing is IMPROVING transmission! ***\n');
        else
            fprintf('*** Ion defocusing is DEGRADING transmission! ***\n');
        end
    else
        fprintf('Ion effect on transmission: negligible (<0.1%%)\n');
    end
   end
end
%%%%%%%%%%%%%%%%%%%%%%%%% Updaed WORKSPACE SAVE 01.23.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== FIX #3: CONDITIONAL WORKSPACE SAVE ====================
%% LOCATION: Around line 3800-3850
%% REPLACE both workspace save blocks with this single robust version:

%% ==================== SAVE COMPLETE WORKSPACE (ROBUST) ====================
workspace_filename = sprintf('PIC_v8_workspace_%s.mat', datestr(now, 'yyyymmdd_HHMMSS'));

fprintf('\n=== Preparing workspace save ===\n');
%%%%%%%%%%%%%%%%%%%%%%% Debagging script if pulse_diagnostics not exist %%%%%%%%%%%%%%%%%%%% 
%% Add immediately before the workspace save block
if ~exist('pulse_diagnostics', 'var')
    pulse_diagnostics = struct();
    pulse_diagnostics.note = 'Not available in this run mode';
    pulse_diagnostics.n_pulses = 1;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Always save these base variables
base_vars = {'I_cathode', 'I_anode', 'I_drift_exit', 'I_emit', ...
             'n_active_history', 'J_thermionic', 'J_space_charge', 'J_actual', ...
             'particle_weight_history', 'sc_field_max', 'sc_field_distribution', ...
             'collection_efficiency_corrected', 'drift_exit_efficiency', ...
             'pulse_diagnostics', 'pulse_config', ...
             'r_rms_history', 'n_particles_vs_z', 'z_diagnostic', ...
             't', 'z', 'r', 'sc_z', 'sc_r', ...
             'n_created', 'particles_at_anode', 'particles_transmitted', ...
             'computation_time', 'simulation_mode', ...
             'ENABLE_SPACE_CHARGE', 'ENABLE_MULTIPULSE'};

vars_to_save = base_vars;

% Conditionally add optional variables
if exist('schottky_diagnostics', 'var')
    vars_to_save{end+1} = 'schottky_diagnostics';
end

if exist('gas_params', 'var')
    vars_to_save{end+1} = 'gas_params';
end

% Pulse 1 data (should always exist in both modes)
if exist('steady_state_beam', 'var')
    vars_to_save{end+1} = 'steady_state_beam';
    fprintf('  Including Pulse 1 snapshot\n');
end

if exist('twiss_results', 'var')
    vars_to_save{end+1} = 'twiss_results';
    vars_to_save{end+1} = 'analysis_planes';
    fprintf('  Including Pulse 1 Twiss analysis\n');
end

if exist('slice_data', 'var')
    vars_to_save{end+1} = 'slice_data';
    fprintf('  Including slice analysis\n');
end

% Pulse 2 data (multi-pulse mode only)
if ENABLE_MULTIPULSE == true
    if exist('steady_state_beam_pulse2', 'var')
        vars_to_save{end+1} = 'steady_state_beam_pulse2';
        fprintf('  Including Pulse 2 snapshot\n');
    end
    
    if exist('twiss_results_pulse2', 'var')
        vars_to_save{end+1} = 'twiss_results_pulse2';
        fprintf('  Including Pulse 2 Twiss analysis\n');
    end
    
    if exist('interpulse_electron_cloud', 'var')
        vars_to_save{end+1} = 'interpulse_electron_cloud';
        fprintf('  Including inter-pulse cloud data\n');
    end
%%%%%%%%%%%%%%%%%%%%%%%  Added 02.03.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Pulse 3 data (NEW - add after P2)
    if exist('steady_state_beam_pulse3', 'var')
        vars_to_save{end+1} = 'steady_state_beam_pulse3';
        fprintf('  Including Pulse 3 snapshot\n');
    end
    
    if exist('twiss_results_pulse3', 'var')
        vars_to_save{end+1} = 'twiss_results_pulse3';
        fprintf('  Including Pulse 3 Twiss analysis\n');
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Added 02.06.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if exist('interpulse_clouds', 'var') && interpulse_capture_count > 0
        vars_to_save{end+1} = 'interpulse_clouds';
        fprintf('  Including %d inter-pulse cloud snapshots\n', interpulse_capture_count);
    end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end

% Ion accumulation data (if enabled)%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ENABLE_MULTIPULSE == true
    fprintf('  PIERCE GUN PIC V3  MULTI-PULSE (n=%d), SC ENABLED\n', n_pulses_config);
    ENABLE_INTERPULSE_SNAPSHOT  = true;   % Inter-pulse electron cloud capture
else
    fprintf('  PIERCE GUN PIC V3  SINGLE PULSE, SC ENABLED\n');
    ENABLE_INTERPULSE_SNAPSHOT  = false;   % Inter-pulse electron cloud capture
end
 
if ENABLE_ION_ACCUMULATION == true
    if exist('ion_density_grid', 'var')
        vars_to_save{end+1} = 'ion_density_grid';
        fprintf('  Including ion density grid\n');
    end
    
    if exist('ion_snapshot_data', 'var')
        vars_to_save{end+1} = 'ion_snapshot_data';
        fprintf('  Including ion snapshots\n');
    end
    
    if exist('ion_diag', 'var')
        vars_to_save{end+1} = 'ion_diag';
        fprintf('  Including ion diagnostics\n');
    end
end

% Betatron averaging data (if captured)
if exist('snapshot_p1', 'var') && snapshot_p1_count > 0
    vars_to_save{end+1} = 'snapshot_p1';
    fprintf('  Including Pulse 1 betatron snapshots (%d)\n', snapshot_p1_count);
end

if ENABLE_MULTIPULSE == true && exist('snapshot_p2', 'var') && snapshot_p2_count > 0
    vars_to_save{end+1} = 'snapshot_p2';
    fprintf('  Including Pulse 2 betatron snapshots (%d)\n', snapshot_p2_count);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%  added 02.03.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ENABLE_MULTIPULSE == true && exist('snapshot_p3', 'var') && snapshot_p3_count > 0
    vars_to_save{end+1} = 'snapshot_p3';
    fprintf('  Including Pulse 3 betatron snapshots (%d)\n', snapshot_p3_count);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if exist('twiss_p1_averaged', 'var')
    vars_to_save{end+1} = 'twiss_p1_averaged';
    vars_to_save{end+1} = 'twiss_p1_instantaneous';
    fprintf('  Including Pulse 1 betatron-averaged Twiss\n');
end

if ENABLE_MULTIPULSE == true  && exist('twiss_p2_averaged', 'var')
    vars_to_save{end+1} = 'twiss_p2_averaged';
    vars_to_save{end+1} = 'twiss_p2_instantaneous';
    fprintf('  Including Pulse 2 betatron-averaged Twiss\n');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%  added 02.03.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ENABLE_MULTIPULSE == true && exist('twiss_p3_averaged', 'var')
    vars_to_save{end+1} = 'twiss_p3_averaged';
    vars_to_save{end+1} = 'twiss_p3_instantaneous';
    fprintf('  Including Pulse 3 betatron-averaged Twiss\n');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Perform save
try
    save(workspace_filename, vars_to_save{:}, '-v7.3');
    fprintf('\nComplete workspace saved to: %s\n', workspace_filename);
    fprintf('Variables saved: %d\n', length(vars_to_save));
    fprintf('File size: %.1f MB\n', dir(workspace_filename).bytes/1024^2);
catch err
    fprintf('\nERROR saving workspace: %s\n', err.message);
    fprintf('Attempting minimal save...\n');
    % Fallback: save only guaranteed variables
    save(workspace_filename, 'I_cathode', 'I_anode', 't', 'pulse_config', '-v7.3');
    fprintf('Minimal workspace saved\n');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('\nComplete workspace saved to: %s\n', workspace_filename);
fprintf('File size: %.1f MB\n', dir(workspace_filename).bytes/1024^2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 26 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== TWISS PARAMETER COMPARISON: PULSE 1 vs PULSE 2 ====================
%% Location ~3930: Twiss Parameter Comparison
if PLOTS_AVAILABLE.pulse2_twiss
    fprintf('\n=== GENERATING PULSE COMPARISON PLOTS ===\n');
if exist('twiss_results', 'var') && exist('twiss_results_pulse2', 'var')
    fprintf('\n=== GENERATING PULSE COMPARISON PLOTS ===\n');
    
    figure('Position', [100, 100, 1800, 1000], 'Name', 'Twiss Parameter Comparison: P1 vs P2');
    
    % Extract values for both pulses
    z_vals = [twiss_results.z] * 1000;  % mm
    
    % Pulse 1 parameters
    beta_p1 = [twiss_results.beta];
    alpha_p1 = [twiss_results.alpha];
    gamma_p1 = [twiss_results.gamma];
    emit_p1 = [twiss_results.emit_norm];
    
    % Pulse 2 parameters
    beta_p2 = [twiss_results_pulse2.beta];
    alpha_p2 = [twiss_results_pulse2.alpha];
    gamma_p2 = [twiss_results_pulse2.gamma];
    emit_p2 = [twiss_results_pulse2.emit_norm];
    
    % Plot 1: Beta function comparison
    subplot(2,3,1);
    hold on;
    plot(z_vals, beta_p1, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Pulse 1');
    plot(z_vals, beta_p2, 'r-s', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Pulse 2');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Beta Function Comparison', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    % Add difference indicator
    beta_diff_exit = beta_p2(end) - beta_p1(end);
    text(0.6, 0.9, sprintf('Δβ at exit: %.3f m', beta_diff_exit), ...
         'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
    
    % Plot 2: Alpha parameter comparison
    subplot(2,3,2);
    hold on;
    plot(z_vals, alpha_p1, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Pulse 1');
    plot(z_vals, alpha_p2, 'r-s', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Pulse 2');
    yline(0, 'k--', 'LineWidth', 1, 'DisplayName', 'Collimated');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Alpha Parameter Comparison', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    % Highlight exit collimation difference
    alpha_diff_exit = alpha_p2(end) - alpha_p1(end);
    if abs(alpha_diff_exit) > 0.05
        text(0.6, 0.9, sprintf('Δα at exit: %.3f', alpha_diff_exit), ...
             'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'yellow');
        if alpha_diff_exit > 0
            text(0.6, 0.82, 'P2 more converging', 'Units', 'normalized', ...
                 'FontSize', 9, 'Color', 'red');
        else
            text(0.6, 0.82, 'P2 more diverging', 'Units', 'normalized', ...
                 'FontSize', 9, 'Color', 'blue');
        end
    end
    
    % Plot 3: Gamma parameter comparison
    subplot(2,3,3);
    hold on;
    plot(z_vals, gamma_p1, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Pulse 1');
    plot(z_vals, gamma_p2, 'r-s', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Pulse 2');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('γ (1/m)', 'FontSize', 12);
    title('Gamma Parameter Comparison', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    % Plot 4: Normalized emittance comparison
    subplot(2,3,4);
    hold on;
    plot(z_vals, emit_p1, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Pulse 1');
    plot(z_vals, emit_p2, 'r-s', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Pulse 2');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('εₙ (mm-mrad)', 'FontSize', 12);
    title('Normalized Emittance Comparison', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    % Emittance growth comparison
    emit_growth_p1 = (emit_p1(end) - emit_p1(1)) / emit_p1(1) * 100;
    emit_growth_p2 = (emit_p2(end) - emit_p2(1)) / emit_p2(1) * 100;
    text(0.6, 0.9, sprintf('P1 growth: %.1f%%', emit_growth_p1), ...
         'Units', 'normalized', 'FontSize', 10);
    text(0.6, 0.82, sprintf('P2 growth: %.1f%%', emit_growth_p2), ...
         'Units', 'normalized', 'FontSize', 10);
    
    % Plot 5: Absolute differences (β, α, γ)
    subplot(2,3,5);
    
    % Calculate differences
    beta_diff = beta_p2 - beta_p1;
    alpha_diff = alpha_p2 - alpha_p1;
    gamma_diff = gamma_p2 - gamma_p1;
    
    hold on;
    plot(z_vals, beta_diff, 'b-o', 'LineWidth', 2, 'DisplayName', 'Δβ (m)');
    plot(z_vals, alpha_diff, 'r-s', 'LineWidth', 2, 'DisplayName', 'Δα');
    plot(z_vals, gamma_diff*0.1, 'g-^', 'LineWidth', 2, 'DisplayName', 'Δγ/10 (1/m)');
    yline(0, 'k--', 'LineWidth', 1);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('P2 - P1', 'FontSize', 12);
    title('Twiss Parameter Differences', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    % Plot 6: Summary comparison table
    subplot(2,3,6);
    axis off;
    
    text(0.1, 0.95, 'TWISS COMPARISON SUMMARY', 'FontWeight', 'bold', 'FontSize', 14);
    text(0.1, 0.88, 'Exit Plane (z=2700mm):', 'FontWeight', 'bold', 'FontSize', 12);
    
    y_pos = 0.78;
    params = {'β (m)', 'α', 'γ (1/m)', 'εₙ (mm-mrad)', 'Condition'};
    p1_vals = {beta_p1(end), alpha_p1(end), gamma_p1(end), emit_p1(end), twiss_results(end).condition};
    p2_vals = {beta_p2(end), alpha_p2(end), gamma_p2(end), emit_p2(end), twiss_results_pulse2(end).condition};
    
    for i = 1:length(params)
        text(0.1, y_pos, params{i}, 'FontSize', 11);
        if i <= 4
            text(0.35, y_pos, sprintf('%.3f', p1_vals{i}), 'FontSize', 11, 'Color', 'blue');
            text(0.50, y_pos, sprintf('%.3f', p2_vals{i}), 'FontSize', 11, 'Color', 'red');
            diff_val = p2_vals{i} - p1_vals{i};
            text(0.65, y_pos, sprintf('Δ=%.3f', diff_val), 'FontSize', 11, 'FontWeight', 'bold');
        else
            text(0.35, y_pos, p1_vals{i}, 'FontSize', 11, 'Color', 'blue');
            text(0.50, y_pos, p2_vals{i}, 'FontSize', 11, 'Color', 'red');
        end
        y_pos = y_pos - 0.10;
    end
    
    % Add interpretation
    y_pos = 0.25;
    text(0.1, y_pos, 'KEY FINDINGS:', 'FontWeight', 'bold', 'FontSize', 11);
    y_pos = y_pos - 0.08;
    
    if abs(beta_diff_exit) > 0.05
        text(0.1, y_pos, sprintf('• β changed by %.1f%%', 100*beta_diff_exit/beta_p1(end)), ...
             'FontSize', 10);
        y_pos = y_pos - 0.06;
    end
    
    if abs(alpha_diff_exit) > 0.05
        text(0.1, y_pos, sprintf('• P2 is more %s', ...
             ternary(alpha_diff_exit > 0, 'converging', 'diverging')), ...
             'FontSize', 10, 'Color', 'red');
        y_pos = y_pos - 0.06;
    end
    
    emit_change = (emit_p2(end) - emit_p1(end)) / emit_p1(end) * 100;
    if abs(emit_change) > 5
        text(0.1, y_pos, sprintf('• Emittance %s by %.1f%%', ...
             ternary(emit_change > 0, 'grew', 'decreased'), abs(emit_change)), ...
             'FontSize', 10);
    end
    
    sgtitle('Pulse 1 vs Pulse 2: Twiss Parameter Evolution', 'FontSize', 16);
end
end
% Helper function for ternary operator
function result = ternary(condition, true_val, false_val)
    if condition
        result = true_val;
    else
        result = false_val;
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 27 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== INTER-PULSE ELECTRON CLOUD VISUALIZATION ====================
if exist('steady_state_beam', 'var') && exist('steady_state_beam_pulse2', 'var')
    if exist('interpulse_electron_cloud', 'var')
    fprintf('\n=== CREATING INTER-PULSE CLOUD DIAGNOSTIC PLOTS ===\n');
    
    figure('Position', [100, 100, 1800, 1000], ...
           'Name', 'Residual Electron Cloud Between Pulses');
    
    % Extract data
    z_cloud = interpulse_electron_cloud.z * 1000;
    r_cloud = interpulse_electron_cloud.r * 1000;
    E_cloud = interpulse_electron_cloud.energy_MeV;
    vz_cloud = interpulse_electron_cloud.vz;
    
    % Categorize electrons
    fast_electrons = E_cloud > 1.6;  % Near-full energy
    slow_electrons = E_cloud < 1.0;  % Significantly slower
    medium_electrons = ~fast_electrons & ~slow_electrons;
    
    % Plot 1: 2D Density Map (compare with Pulse snapshots)
    subplot(2,3,1);
    [N_cloud, ze, re] = histcounts2(z_cloud, r_cloud, 0:25:2750, 0:1:80);
    
    % Use log scale for better contrast
    imagesc(ze(1:end-1)+12.5, re(1:end-1)+0.5, log10(N_cloud'+1));
    axis xy;
    colorbar;
    title(sprintf('Residual e⁻ Cloud at t=%.0f ns', interpulse_electron_cloud.time*1e9), ...
          'FontSize', 14);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([254 254], [0 80], 'w:', 'LineWidth', 1.5);
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    xlim([0 8310]);
    ylim([0 80]);
    
    % Annotate with key info
    text(0.05, 0.95, sprintf('Total: %d e⁻', interpulse_electron_cloud.n_total), ...
         'Units', 'normalized', 'Color', 'white', 'FontSize', 11, 'FontWeight', 'bold');
    
    % Plot 2: Energy-coded spatial distribution
    subplot(2,3,2);
    scatter(z_cloud, r_cloud, 15, E_cloud, 'filled', 'MarkerFaceAlpha', 0.6);
    colormap(gca, 'jet');
    colorbar;
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    title('Residual Electrons (colored by energy)', 'FontSize', 14);
    xlim([0 8310]);
    ylim([0 80]);
    hold on;
    yline(75, 'w--', 'LineWidth', 2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
% Plot 3: Energy distribution - CORRECTED VERSION
subplot(2,3,3);

% Calculate appropriate x-axis range from actual data
E_min_actual = min(E_cloud);
E_max_actual = max(E_cloud);
E_range_actual = E_max_actual - E_min_actual;

% Set x-axis to show actual data with some padding
if E_range_actual > 0
    x_min = max(0, E_min_actual - 0.1*E_range_actual);
    x_max = E_max_actual + 0.2*E_range_actual;
else
    % If all electrons at same energy
    x_min = 0;
    x_max = E_min_actual * 2;
end

histogram(E_cloud, 50, 'FaceColor', [0.3 0.6 0.9], 'EdgeColor', 'none');
xlabel('Energy (MeV)', 'FontSize', 12);
ylabel('Count', 'FontSize', 12);
title('Energy Distribution of Residual e⁻ (Zoomed)', 'FontSize', 14);
grid on;
xlim([x_min x_max]);

hold on;

% Add statistics text with nominal beam reference
text(0.55, 0.9, sprintf('Fast (>1.6 MeV): %d', sum(fast_electrons)), ...
     'Units', 'normalized', 'FontSize', 10);
text(0.55, 0.83, sprintf('Medium: %d', sum(medium_electrons)), ...
     'Units', 'normalized', 'FontSize', 10);
text(0.55, 0.76, sprintf('Slow (<1 MeV): %d', sum(slow_electrons)), ...
     'Units', 'normalized', 'FontSize', 10, 'Color', 'red', 'FontWeight', 'bold');

% Add reference annotation (not plotted on axis since it's way outside data range)
text(0.55, 0.60, sprintf('Nominal beam: 1.69 MeV'), ...
     'Units', 'normalized', 'FontSize', 10, 'Color', [0.5 0.4 0.3]);
%text(0.55, 0.53, sprintf('%.0fx higher than cloud'), 1.69/mean(E_cloud), ...
text(0.55, 0.53, sprintf('%f higher than cloud', 1.69/mean(E_cloud)), ...
     'Units', 'normalized', 'FontSize', 10, 'Color', [0.5 0.4 0.3], 'FontWeight', 'bold');

% Add vertical line showing mean energy
xline(mean(E_cloud), 'r--', 'LineWidth', 2, 'Label', sprintf('Mean: %.3f MeV', mean(E_cloud)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    
    % Plot 4: Longitudinal distribution by energy category
    subplot(2,3,4);
    hold on;
    histogram(z_cloud(fast_electrons), 30, 'FaceColor', 'b', 'FaceAlpha', 0.5, ...
             'DisplayName', 'Fast (>1.6 MeV)');
    histogram(z_cloud(medium_electrons), 30, 'FaceColor', 'g', 'FaceAlpha', 0.5, ...
             'DisplayName', 'Medium (1.0-1.6 MeV)');
    histogram(z_cloud(slow_electrons), 30, 'FaceColor', 'r', 'FaceAlpha', 0.5, ...
             'DisplayName', 'Slow (<1.0 MeV)');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('Count', 'FontSize', 12);
    title('Longitudinal Distribution by Energy', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    % Plot 5: Radial distribution of slow electrons
    subplot(2,3,5);
    if sum(slow_electrons) > 10
        histogram(r_cloud(slow_electrons), 30, 'FaceColor', 'r', 'EdgeColor', 'none');
        xlabel('r (mm)', 'FontSize', 12);
        ylabel('Count', 'FontSize', 12);
        title('Radial Distribution: Slow e⁻ Only', 'FontSize', 14);
        grid on;
        xlim([0 80]);
        
        % Calculate RMS radius of slow cloud
        r_slow_rms = sqrt(mean(r_cloud(slow_electrons).^2));
        xline(r_slow_rms, 'b--', 'LineWidth', 2, ...
              'Label', sprintf('RMS: %.1f mm', r_slow_rms));
        
        % Estimate space charge focusing strength
        if r_slow_rms > 0
            text(0.6, 0.9, sprintf('Slow e⁻ RMS: %.1f mm', r_slow_rms), ...
                 'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
        end
    else
        text(0.5, 0.5, 'Too few slow electrons for analysis', ...
             'HorizontalAlignment', 'center', 'FontSize', 12);
    end
    
    % Plot 6: Estimated space charge field from residual cloud
    subplot(2,3,6);
    axis off;
    
    text(0.1, 0.95, 'RESIDUAL CLOUD ANALYSIS', 'FontWeight', 'bold', 'FontSize', 14);
    
    y_pos = 0.83;
    text(0.1, y_pos, sprintf('Total residual e⁻: %d', interpulse_electron_cloud.n_total), ...
         'FontSize', 11);
    y_pos = y_pos - 0.08;
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      % ===== ADD THESE CENTROID DISPLAY LINES =====
     if isfield(interpulse_electron_cloud, 'z_centroid')
         text(0.1, y_pos, sprintf('Centroid: z=%.0f mm, r=%.1f mm', ...
         interpulse_electron_cloud.z_centroid*1000, ...
         interpulse_electron_cloud.r_centroid*1000), ...
         'FontSize', 11, 'Color', 'blue', 'FontWeight', 'bold');
         y_pos = y_pos - 0.08;
     end
     % ===== END ADDITION =====
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    text(0.1, y_pos, sprintf('Slow e⁻ (<1 MeV): %d (%.1f%%)', ...
         sum(slow_electrons), 100*sum(slow_electrons)/n_active), ...
         'FontSize', 11, 'Color', 'red');
    y_pos = y_pos - 0.08;
    
    % Estimate charge density of slow cloud
    if sum(slow_electrons) > 10
        % Volume estimate (cylindrical approximation)
        z_range_slow = max(z_cloud(slow_electrons)) - min(z_cloud(slow_electrons));
        r_rms_slow = sqrt(mean(r_cloud(slow_electrons).^2)) / 1000;  % m
        volume_slow = pi * r_rms_slow^2 * z_range_slow/1000;  % m³
        
        if volume_slow > 0
            total_charge_slow = sum(interpulse_electron_cloud.weight(slow_electrons)) * e_charge;
            charge_density_slow = total_charge_slow / volume_slow;
            
            % Estimate SC field: E ≈ ρr/(2ε₀)
            field_estimate = charge_density_slow * r_rms_slow / (2*eps0);
            
            text(0.1, y_pos, sprintf('Charge density: %.2e C/m³', charge_density_slow), ...
                 'FontSize', 10);
            y_pos = y_pos - 0.08;
            text(0.1, y_pos, sprintf('Estimated SC field: %.2f kV/m', field_estimate/1e3), ...
                 'FontSize', 10, 'Color', 'blue', 'FontWeight', 'bold');
            y_pos = y_pos - 0.08;
            
            % Compare to beam energy
            focusing_strength = field_estimate / 1.7e6;  % Ratio to 1.7 MV beam energy
            focal_length_est = 1 / focusing_strength;  % Rough estimate
            
            text(0.1, y_pos, sprintf('Focusing strength: %.2e', focusing_strength), ...
                 'FontSize', 10);
            y_pos = y_pos - 0.08;
            text(0.1, y_pos, sprintf('Est. focal length: ~%.1f m', focal_length_est), ...
                 'FontSize', 10);
            y_pos = y_pos - 0.10;
            
            % Predicted effect on Pulse 2
            text(0.1, y_pos, 'PREDICTED EFFECT ON P2:', 'FontWeight', 'bold', ...
                 'FontSize', 11, 'Color', 'red');
            y_pos = y_pos - 0.08;
            
            predicted_delta_r = focusing_strength * 50 * 1000;  % mm, rough estimate
            text(0.1, y_pos, sprintf('Expected Δr: ~%.2f mm', predicted_delta_r), ...
                 'FontSize', 11, 'Color', 'red');
            y_pos = y_pos - 0.08;
            
            if predicted_delta_r < -0.5
                text(0.1, y_pos, '→ P2 should be TIGHTER', 'FontSize', 10, 'Color', 'green');
            elseif predicted_delta_r > 0.5
                text(0.1, y_pos, '→ P2 should be WIDER', 'FontSize', 10, 'Color', 'red');
            else
                text(0.1, y_pos, '→ Minimal effect expected', 'FontSize', 10);
            end
        end
    end
    
    % Save for detailed analysis
    save('interpulse_electron_cloud.mat', 'interpulse_electron_cloud');
    fprintf('  Inter-pulse cloud data saved to interpulse_electron_cloud.mat\n');
    
    else
        fprintf('  No active particles between pulses\n');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  Figure 28 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== THREE-WAY 2D DENSITY COMPARISON ====================
%% Location ~4500: Three-way Evolution Comparison
if PLOTS_AVAILABLE.interpulse_cloud && PLOTS_AVAILABLE.pulse2_snapshot
%    figure('Position', [100, 100, 1800, 600], ...
%          'Name', 'Evolution: P1 → Residual Cloud → P2');
% Compare: Pulse 1 → Inter-pulse cloud → Pulse 2
if exist('steady_state_beam', 'var') && exist('interpulse_electron_cloud', 'var') && ...
   exist('steady_state_beam_pulse2', 'var')
    
    figure('Position', [100, 100, 1800, 600], ...
           'Name', 'Evolution: P1 → Residual Cloud → P2');
    
    % Common binning
    z_edges = 0:25:8300;
    r_edges = 0:1:80;
    
    % Pulse 1 density
    subplot(1,3,1);
    [N1, ~, ~] = histcounts2(steady_state_beam.z*1000, steady_state_beam.r*1000, ...
                             z_edges, r_edges);
    imagesc(z_edges(1:end-1)+12.5, r_edges(1:end-1)+0.5, log10(N1'+1));
    axis xy;
    colorbar;
    caxis([0 max(log10(N1(:)+1))]);  % Consistent color scale
    title(sprintf('Pulse 1 at t=%.0f ns', steady_state_beam.time*1e9), 'FontSize', 14);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    xlim([0 8310]);
    ylim([0 80]);
    
    % Inter-pulse cloud
    subplot(1,3,2);
    [N_cloud, ~, ~] = histcounts2(interpulse_electron_cloud.z*1000, ...
                                  interpulse_electron_cloud.r*1000, z_edges, r_edges);
    imagesc(z_edges(1:end-1)+12.5, r_edges(1:end-1)+0.5, log10(N_cloud'+1));
    axis xy;
    colorbar;
    caxis([0 max(log10(N1(:)+1))]);  % Same scale as P1 for comparison
    title(sprintf('Residual Cloud at t=%.0f ns', interpulse_electron_cloud.time*1e9), ...
          'FontSize', 14);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    xlim([0 8310]);
    ylim([0 80]);
    
    % Annotate with electron count
    text(0.05, 0.95, sprintf('%d residual e⁻', interpulse_electron_cloud.n_total), ...
         'Units', 'normalized', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
    text(0.05, 0.88, sprintf('%.1f%% of P1', ...
         100*interpulse_electron_cloud.n_total/steady_state_beam.n_total), ...
         'Units', 'normalized', 'Color', 'yellow', 'FontSize', 10);
    
    % Pulse 2 density
    subplot(1,3,3);
    [N2, ~, ~] = histcounts2(steady_state_beam_pulse2.z*1000, ...
                             steady_state_beam_pulse2.r*1000, z_edges, r_edges);
    imagesc(z_edges(1:end-1)+12.5, r_edges(1:end-1)+0.5, log10(N2'+1));
    axis xy;
    colorbar;
    caxis([0 max(log10(N1(:)+1))]);  % Same scale for direct comparison
    title(sprintf('Pulse 2 at t=%.0f ns', steady_state_beam_pulse2.time*1e9), 'FontSize', 14);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    xlim([0 8310]);
    ylim([0 80]);
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Highlight the residual cloud region in P2 using STORED centroid
if isfield(interpulse_electron_cloud, 'z_centroid') && ...
   isfield(interpulse_electron_cloud, 'r_centroid')
    
    % Use the ACTUAL calculated centroid
    z_cloud_center = interpulse_electron_cloud.z_centroid * 1000;  % Convert to mm
    r_cloud_center = interpulse_electron_cloud.r_centroid * 1000;
    
    % Plot marker at CORRECT position
    plot(z_cloud_center, r_cloud_center, 'yo', 'MarkerSize', 15, ...
         'LineWidth', 3, 'MarkerFaceColor', 'yellow');
    text(z_cloud_center+150, r_cloud_center+5, ...
         sprintf('Cloud centroid\nz=%.0f mm, r=%.1f mm', z_cloud_center, r_cloud_center), ...
         'Color', 'yellow', 'FontSize', 11, 'FontWeight', 'bold', ...
         'BackgroundColor', 'black', 'EdgeColor', 'yellow');
    
    fprintf('  Plotting cloud centroid at z=%.0f mm, r=%.1f mm\n', ...
            z_cloud_center, r_cloud_center);
else
    fprintf('  WARNING: Cloud centroid not calculated - using histogram peak\n');
    
    % Fallback to old method
    [max_cloud, idx_max] = max(N_cloud(:));
    if max_cloud > 0
        [r_idx, z_idx] = ind2sub(size(N_cloud), idx_max);
        z_cloud_peak = z_edges(z_idx) + 12.5;
        r_cloud_peak = r_edges(r_idx) + 0.5;
        plot(z_cloud_peak, r_cloud_peak, 'yo', 'MarkerSize', 12, 'LineWidth', 3);
        text(z_cloud_peak+100, r_cloud_peak+5, 'Cloud histogram peak', ...
             'Color', 'yellow', 'FontSize', 10, 'FontWeight', 'bold');
    end
end
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== DECOMPOSE P1→P2 EFFECTS: CLOUD vs IONS ====================
%% Location ~4650: Decompose Effects
if PLOTS_AVAILABLE.interpulse_cloud && PLOTS_AVAILABLE.ion_data
    fprintf('\n=== SEPARATING ELECTRON CLOUD vs ION EFFECTS ===\n');

if exist('interpulse_electron_cloud', 'var') && ENABLE_ION_ACCUMULATION
    fprintf('\n=== SEPARATING ELECTRON CLOUD vs ION EFFECTS ===\n');
    
    % At exit (z=2700mm), compare:
    % 1. P1 baseline
    % 2. Residual cloud strength
    % 3. Ion cloud strength
    % 4. P2 actual result
    
    % Electron cloud estimate
    tol = 100;  % ±100mm at exit
    %in_exit_cloud = abs(interpulse_electron_cloud.z*1000 - 2700) < tol;
    in_exit_cloud = abs(interpulse_electron_cloud.z*1000 - 8300) < tol;
    
    if sum(in_exit_cloud) > 10
        n_electrons_exit = sum(in_exit_cloud);
        total_charge_exit = sum(interpulse_electron_cloud.weight(in_exit_cloud)) * e_charge;
        
        % Estimate field strength
        r_exit_cloud = sqrt(mean((interpulse_electron_cloud.r(in_exit_cloud)*1000).^2))/1000;  % m
        volume_exit = pi * r_exit_cloud^2 * 0.200;  % 200mm axial extent
        rho_exit = total_charge_exit / volume_exit;
        E_cloud_exit = abs(rho_exit) * r_exit_cloud / (2*eps0);  % kV/m scale
        
        fprintf('\nAt Drift Exit (z=2700mm):\n');
        fprintf('  Residual electrons: %d\n', n_electrons_exit);
        fprintf('  Electron cloud field: ~%.2f kV/m\n', E_cloud_exit/1e3);
        
        % Compare to ion field
        if exist('ion_density_grid', 'var')
            %[~, iz_exit] = min(abs(sc_z - 2.700));
             [~, iz_exit] = min(abs(sc_z - 8.300));
            ions_at_exit = sum(ion_density_grid(:, max(1, iz_exit-5):min(sc_nz, iz_exit+5)), 'all');
            fprintf('  Ions near exit: ~%.0f\n', ions_at_exit);
            
            % Rough ion field estimate
            if ions_at_exit > 10
                ion_charge_exit = ions_at_exit * e_charge;
                E_ion_exit = ion_charge_exit / (2*eps0*pi*0.04^2*0.1);  % Rough
                fprintf('  Ion cloud field: ~%.2f kV/m\n', E_ion_exit/1e3);
                
                % Compare
                fprintf('\n  Electron/Ion field ratio: %.1f:1\n', E_cloud_exit/E_ion_exit);
                
                if E_cloud_exit > E_ion_exit
                    fprintf('  → ELECTRON CLOUD DOMINATES the P2 focusing!\n');
                else
                    fprintf('  → ION CLOUD DOMINATES the P2 focusing!\n');
                end
            end
        end
    end
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%  Updated Figures 28a, 28b, 28c %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== FIGURE 28a: P2 → CLOUD@549ns → P3 EVOLUTION ====================
if exist('steady_state_beam_pulse2', 'var') && exist('interpulse_clouds', 'var') && ...
   length(interpulse_clouds) >= 2 && ~isempty(interpulse_clouds{2}) && ...
   exist('steady_state_beam_pulse3', 'var')
    
    fprintf('\n=== Creating P2→P3 Inter-Pulse Cloud Visualization ===\n');
    
    figure('Position', [100, 100, 1800, 600], ...
           'Name', 'Evolution: P2 → Residual Cloud@549ns → P3');
    
    % Common binning
    z_edges = 0:25:8300;
    r_edges = 0:1:80;
    
    % Pulse 2 density
    subplot(1,3,1);
    [N_p2, ~, ~] = histcounts2(steady_state_beam_pulse2.z*1000, ...
                               steady_state_beam_pulse2.r*1000, z_edges, r_edges);
    imagesc(z_edges(1:end-1)+12.5, r_edges(1:end-1)+0.5, log10(N_p2'+1));
    axis xy;
    colorbar;
    max_log = max(log10(N_p2(:)+1));
    caxis([0 max_log]);
    title(sprintf('Pulse 2 at t=%.0f ns', steady_state_beam_pulse2.time*1e9), ...
          'FontSize', 14, 'FontWeight', 'bold');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    plot([254 254], [0 80], 'w:', 'LineWidth', 1.5);
    xlim([0 8310]);
    ylim([0 80]);
    
    % Inter-pulse cloud at t=549ns (before P3)
    subplot(1,3,2);
    cloud_549 = interpulse_clouds{2};
    [N_cloud, ~, ~] = histcounts2(cloud_549.z*1000, cloud_549.r*1000, ...
                                  z_edges, r_edges);
    imagesc(z_edges(1:end-1)+12.5, r_edges(1:end-1)+0.5, log10(N_cloud'+1));
    axis xy;
    colorbar;
    caxis([0 max_log]);  % Same scale as P2
    title(sprintf('Residual Cloud at t=%.0f ns', cloud_549.time*1e9), ...
          'FontSize', 14, 'FontWeight', 'bold');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    xlim([0 8310]);
    ylim([0 80]);
    
    % Annotate cloud statistics
    n_residual = cloud_549.n_total;
    percent_of_p2 = 100 * n_residual / steady_state_beam_pulse2.n_total;
    
    text(0.05, 0.95, sprintf('%d residual e⁻', n_residual), ...
         'Units', 'normalized', 'Color', 'white', 'FontSize', 13, 'FontWeight', 'bold');
    text(0.05, 0.88, sprintf('%.2f%% of P2', percent_of_p2), ...
         'Units', 'normalized', 'Color', 'yellow', 'FontSize', 11);
    
    if isfield(cloud_549, 'z_centroid') && isfield(cloud_549, 'r_centroid')
        text(0.05, 0.81, sprintf('Centroid: z=%.0f mm', cloud_549.z_centroid*1000), ...
             'Units', 'normalized', 'Color', 'cyan', 'FontSize', 10);
        text(0.05, 0.74, sprintf('r=%.1f mm', cloud_549.r_centroid*1000), ...
             'Units', 'normalized', 'Color', 'cyan', 'FontSize', 10);
    end
    
    % Pulse 3 density
    subplot(1,3,3);
    [N_p3, ~, ~] = histcounts2(steady_state_beam_pulse3.z*1000, ...
                               steady_state_beam_pulse3.r*1000, z_edges, r_edges);
    imagesc(z_edges(1:end-1)+12.5, r_edges(1:end-1)+0.5, log10(N_p3'+1));
    axis xy;
    colorbar;
    caxis([0 max_log]);
    title(sprintf('Pulse 3 at t=%.0f ns', steady_state_beam_pulse3.time*1e9), ...
          'FontSize', 14, 'FontWeight', 'bold');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    xlim([0 8310]);
    ylim([0 80]);
    
    % Mark cloud centroid position in P3 panel (shows where lensing occurs)
    if isfield(cloud_549, 'z_centroid') && isfield(cloud_549, 'r_centroid')
        z_cloud_center = cloud_549.z_centroid * 1000;
        r_cloud_center = cloud_549.r_centroid * 1000;
        
        plot(z_cloud_center, r_cloud_center, 'yo', 'MarkerSize', 15, ...
             'LineWidth', 3, 'MarkerFaceColor', 'yellow');
        text(z_cloud_center+150, r_cloud_center+5, ...
             sprintf('P2 cloud\ncentroid'), ...
             'Color', 'yellow', 'FontSize', 11, 'FontWeight', 'bold', ...
             'BackgroundColor', 'black', 'EdgeColor', 'yellow');
    end
    
    sgtitle('P2 → P3 Evolution: Inter-Pulse Electron Cloud Analysis', ...
            'FontSize', 18, 'FontWeight', 'bold');
    
    % Save figure
    saveas(gcf, 'Test70_P2_to_P3_Interpulse_Evolution.fig');
    saveas(gcf, 'Test70_P2_to_P3_Interpulse_Evolution.png');
end

%% ==================== FIGURE 28b: P3 → CLOUD@749ns → P4 EVOLUTION ====================
if exist('steady_state_beam_pulse3', 'var') && exist('interpulse_clouds', 'var') && ...
   length(interpulse_clouds) >= 3 && ~isempty(interpulse_clouds{3}) && ...
   exist('steady_state_beam_pulse4', 'var')
    
    fprintf('\n=== Creating P3→P4 Inter-Pulse Cloud Visualization ===\n');
    
    figure('Position', [100, 100, 1800, 600], ...
           'Name', 'Evolution: P3 → Residual Cloud@749ns → P4');
    
    % Common binning
    z_edges = 0:25:8300;
    r_edges = 0:1:80;
    
    % Pulse 3 density
    subplot(1,3,1);
    [N_p3, ~, ~] = histcounts2(steady_state_beam_pulse3.z*1000, ...
                               steady_state_beam_pulse3.r*1000, z_edges, r_edges);
    imagesc(z_edges(1:end-1)+12.5, r_edges(1:end-1)+0.5, log10(N_p3'+1));
    axis xy;
    colorbar;
    max_log = max(log10(N_p3(:)+1));
    caxis([0 max_log]);
    title(sprintf('Pulse 3 at t=%.0f ns', steady_state_beam_pulse3.time*1e9), ...
          'FontSize', 14, 'FontWeight', 'bold');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    plot([254 254], [0 80], 'w:', 'LineWidth', 1.5);
    xlim([0 8310]);
    ylim([0 80]);
    
    % Inter-pulse cloud at t=749ns (before P4)
    subplot(1,3,2);
    cloud_749 = interpulse_clouds{3};
    [N_cloud, ~, ~] = histcounts2(cloud_749.z*1000, cloud_749.r*1000, ...
                                  z_edges, r_edges);
    imagesc(z_edges(1:end-1)+12.5, r_edges(1:end-1)+0.5, log10(N_cloud'+1));
    axis xy;
    colorbar;
    caxis([0 max_log]);
    title(sprintf('Residual Cloud at t=%.0f ns', cloud_749.time*1e9), ...
          'FontSize', 14, 'FontWeight', 'bold');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    xlim([0 8310]);
    ylim([0 80]);
    
    % Annotate cloud statistics
    n_residual = cloud_749.n_total;
    percent_of_p3 = 100 * n_residual / steady_state_beam_pulse3.n_total;
    
    text(0.05, 0.95, sprintf('%d residual e⁻', n_residual), ...
         'Units', 'normalized', 'Color', 'white', 'FontSize', 13, 'FontWeight', 'bold');
    text(0.05, 0.88, sprintf('%.2f%% of P3', percent_of_p3), ...
         'Units', 'normalized', 'Color', 'yellow', 'FontSize', 11);
    
    if isfield(cloud_749, 'z_centroid') && isfield(cloud_749, 'r_centroid')
        text(0.05, 0.81, sprintf('Centroid: z=%.0f mm', cloud_749.z_centroid*1000), ...
             'Units', 'normalized', 'Color', 'cyan', 'FontSize', 10);
        text(0.05, 0.74, sprintf('r=%.1f mm', cloud_749.r_centroid*1000), ...
             'Units', 'normalized', 'Color', 'cyan', 'FontSize', 10);
    end
    
    % Pulse 4 density
    subplot(1,3,3);
    [N_p4, ~, ~] = histcounts2(steady_state_beam_pulse4.z*1000, ...
                               steady_state_beam_pulse4.r*1000, z_edges, r_edges);
    imagesc(z_edges(1:end-1)+12.5, r_edges(1:end-1)+0.5, log10(N_p4'+1));
    axis xy;
    colorbar;
    caxis([0 max_log]);
    title(sprintf('Pulse 4 at t=%.0f ns', steady_state_beam_pulse4.time*1e9), ...
          'FontSize', 14, 'FontWeight', 'bold');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    xlim([0 8310]);
    ylim([0 80]);
    
    % Mark cloud centroid position in P4 panel
    if isfield(cloud_749, 'z_centroid') && isfield(cloud_749, 'r_centroid')
        z_cloud_center = cloud_749.z_centroid * 1000;
        r_cloud_center = cloud_749.r_centroid * 1000;
        
        plot(z_cloud_center, r_cloud_center, 'yo', 'MarkerSize', 15, ...
             'LineWidth', 3, 'MarkerFaceColor', 'yellow');
        text(z_cloud_center+150, r_cloud_center+5, ...
             sprintf('P3 cloud\ncentroid'), ...
             'Color', 'yellow', 'FontSize', 11, 'FontWeight', 'bold', ...
             'BackgroundColor', 'black', 'EdgeColor', 'yellow');
    end
    
    sgtitle('P3 → P4 Evolution: Inter-Pulse Electron Cloud Analysis', ...
            'FontSize', 18, 'FontWeight', 'bold');
    
    % Save figure
    saveas(gcf, 'Test70_P3_to_P4_Interpulse_Evolution.fig');
    saveas(gcf, 'Test70_P3_to_P4_Interpulse_Evolution.png');
end

%% ==================== FIGURE 28c: COMPARATIVE CLOUD EVOLUTION ====================
% Bonus figure showing ALL THREE inter-pulse clouds side-by-side
if exist('interpulse_clouds', 'var') && length(interpulse_clouds) == 3 && ...
   all(cellfun(@(x) ~isempty(x), interpulse_clouds))
    
    fprintf('\n=== Creating Comparative Cloud Evolution Figure ===\n');
    
    figure('Position', [100, 100, 1800, 600], ...
           'Name', 'Inter-Pulse Cloud Evolution: All Three Snapshots');
    
    % Common binning
    z_edges = 0:25:8300;
    r_edges = 0:1:80;
    
    % Find common color scale across all three clouds
    max_counts = zeros(3,1);
    for ipc = 1:3
        [N_temp, ~, ~] = histcounts2(interpulse_clouds{ipc}.z*1000, ...
                                     interpulse_clouds{ipc}.r*1000, z_edges, r_edges);
        max_counts(ipc) = max(N_temp(:));
    end
    max_log_common = log10(max(max_counts)+1);
    
    % Plot all three clouds
    cloud_times = [349, 549, 749];  % ns
    cloud_labels = {'Before P2', 'Before P3', 'Before P4'};
    
    for ipc = 1:3
        subplot(1,3,ipc);
        
        cloud = interpulse_clouds{ipc};
        [N_cloud, ~, ~] = histcounts2(cloud.z*1000, cloud.r*1000, z_edges, r_edges);
        
        imagesc(z_edges(1:end-1)+12.5, r_edges(1:end-1)+0.5, log10(N_cloud'+1));
        axis xy;
        colorbar;
        caxis([0 max_log_common]);  % Common scale for comparison
        
        title(sprintf('%s (t=%.0f ns)', cloud_labels{ipc}, cloud.time*1e9), ...
              'FontSize', 14, 'FontWeight', 'bold');
        xlabel('z (mm)', 'FontSize', 12);
        ylabel('r (mm)', 'FontSize', 12);
        
        hold on;
        plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
        xlim([0 8310]);
        ylim([0 80]);
        
        % Annotate each cloud
        text(0.05, 0.95, sprintf('%d e⁻', cloud.n_total), ...
             'Units', 'normalized', 'Color', 'white', 'FontSize', 12, 'FontWeight', 'bold');
        
        if isfield(cloud, 'n_slow')
            text(0.05, 0.88, sprintf('Slow (<1 MeV): %d', cloud.n_slow), ...
                 'Units', 'normalized', 'Color', 'yellow', 'FontSize', 10);
        end
        
        % Mark centroid if available
        if isfield(cloud, 'z_centroid') && ~isnan(cloud.z_centroid)
            plot(cloud.z_centroid*1000, cloud.r_centroid*1000, 'yo', ...
                 'MarkerSize', 12, 'LineWidth', 2.5, 'MarkerFaceColor', 'yellow');
        end
        
        % Show which pulses contributed
        if isfield(cloud, 'before_pulse')
            text(0.05, 0.10, sprintf('Ion lens for P%d', cloud.before_pulse), ...
                 'Units', 'normalized', 'Color', 'magenta', 'FontSize', 11, ...
                 'FontWeight', 'bold', 'BackgroundColor', 'black');
        end
    end
    
    sgtitle('Inter-Pulse Electron Cloud Evolution: Comparing All Three Snapshots', ...
            'FontSize', 18, 'FontWeight', 'bold');
    
    % Print comparison statistics
    fprintf('\n=== INTER-PULSE CLOUD COMPARISON ===\n');
    for ipc = 1:3
        cloud = interpulse_clouds{ipc};
        fprintf('\nCloud %d (before P%d, t=%.0f ns):\n', ipc, ipc+1, cloud.time*1e9);
        fprintf('  Total electrons: %d\n', cloud.n_total);
        
        if isfield(cloud, 'n_slow')
            fprintf('  Slow electrons (<1 MeV): %d (%.1f%%)\n', ...
                    cloud.n_slow, 100*cloud.n_slow/cloud.n_total);
        end
        
        if isfield(cloud, 'z_centroid') && ~isnan(cloud.z_centroid)
            fprintf('  Centroid: z=%.0f mm, r=%.1f mm\n', ...
                    cloud.z_centroid*1000, cloud.r_centroid*1000);
        end
        
        fprintf('  Energy range: %.3f to %.3f MeV\n', ...
                min(cloud.energy_MeV), max(cloud.energy_MeV));
    end
    
    % Check for trends
    n_clouds = [interpulse_clouds{1}.n_total, interpulse_clouds{2}.n_total, ...
                interpulse_clouds{3}.n_total];
    
    fprintf('\n=== CLOUD EVOLUTION TREND ===\n');
    fprintf('Cloud size progression: %d → %d → %d electrons\n', n_clouds);
    
    if n_clouds(3) > n_clouds(2) && n_clouds(2) > n_clouds(1)
        fprintf('âœ" Clouds growing with each pulse (accumulation)\n');
    elseif abs(n_clouds(3) - n_clouds(2)) < 0.1*n_clouds(2)
        fprintf('âœ" Cloud size stabilized (equilibrium reached)\n');
    else
        fprintf('âš  Irregular cloud evolution pattern\n');
    end
    
    % Save figure
    saveas(gcf, 'Test70_All_Interpulse_Clouds_Comparison.fig');
    saveas(gcf, 'Test70_All_Interpulse_Clouds_Comparison.png');
    fprintf('\nâœ" All inter-pulse cloud figures created!\n');
end
%%%%%%%%%%%%%%%%%%%%%%%%% added interpulse cloud analysis 02.09.2026 %%%%%%%%%%%%%%%
%% ==================== QUANTITATIVE INTER-PULSE CLOUD ANALYSIS ====================
%% CRITICAL FOR EXPERIMENTAL VALIDATION
% This section extracts all measurable cloud properties for comparison with experiment
% Engineers can use these metrics to validate model predictions

if exist('interpulse_clouds', 'var') && length(interpulse_clouds) == 3 && ...
   all(cellfun(@(x) ~isempty(x), interpulse_clouds))
    
    fprintf('\n========================================================================\n');
    fprintf('  QUANTITATIVE INTER-PULSE CLOUD COMPARISON                            \n');
    fprintf('  (For Experimental Validation)                                        \n');
    fprintf('========================================================================\n');
    
    %% ===== EXTRACT METRICS FROM ALL THREE CLOUDS =====
    cloud_metrics = struct();
    
    for ipc = 1:3
        cloud = interpulse_clouds{ipc};
        
        %% Basic counts
        cloud_metrics(ipc).time_ns = cloud.time * 1e9;
        cloud_metrics(ipc).before_pulse = cloud.before_pulse;
        cloud_metrics(ipc).n_total = cloud.n_total;
        
        %% Energy distribution analysis
        E_cloud = cloud.energy_MeV;
        
        cloud_metrics(ipc).E_mean = mean(E_cloud);
        cloud_metrics(ipc).E_median = median(E_cloud);
        cloud_metrics(ipc).E_rms = std(E_cloud);
        cloud_metrics(ipc).E_min = min(E_cloud);
        cloud_metrics(ipc).E_max = max(E_cloud);
        
        % Energy categories (experimentally distinguishable)
        cloud_metrics(ipc).n_fast = sum(E_cloud > 1.6);      % Near-full energy
        cloud_metrics(ipc).n_medium = sum(E_cloud >= 1.0 & E_cloud <= 1.6);
        cloud_metrics(ipc).n_slow = sum(E_cloud < 1.0);      % Strong lensing potential
        
        cloud_metrics(ipc).frac_fast = cloud_metrics(ipc).n_fast / cloud.n_total;
        cloud_metrics(ipc).frac_medium = cloud_metrics(ipc).n_medium / cloud.n_total;
        cloud_metrics(ipc).frac_slow = cloud_metrics(ipc).n_slow / cloud.n_total;
        
        %% Spatial distribution (BPM-measurable)
        z_cloud = cloud.z;
        r_cloud = cloud.r;
        
        % First moments (centroids)
        if isfield(cloud, 'z_centroid')
            cloud_metrics(ipc).z_centroid = cloud.z_centroid * 1000;  % mm
            cloud_metrics(ipc).r_centroid = cloud.r_centroid * 1000;  % mm
        else
            cloud_metrics(ipc).z_centroid = mean(z_cloud) * 1000;
            cloud_metrics(ipc).r_centroid = sqrt(mean(r_cloud.^2)) * 1000;
        end
        
        % Second moments (RMS sizes)
        cloud_metrics(ipc).z_rms = std(z_cloud) * 1000;  % mm
        cloud_metrics(ipc).r_rms = sqrt(mean(r_cloud.^2)) * 1000;  % mm
        
        % Spatial extent (FWHM-like)
        cloud_metrics(ipc).z_min = min(z_cloud) * 1000;
        cloud_metrics(ipc).z_max = max(z_cloud) * 1000;
        cloud_metrics(ipc).z_span = (max(z_cloud) - min(z_cloud)) * 1000;  % mm
        cloud_metrics(ipc).r_max = max(r_cloud) * 1000;  % mm
        
        %% Current calculation (ammeter-measurable)
        % Estimate current if cloud passes through a detector
        total_charge = sum(cloud.weight) * e_charge;  % Coulombs
        
        % Assume cloud passes detector in ~10ns (typical transit time)
        transit_time = 10e-9;  % seconds
        cloud_metrics(ipc).current_equivalent = total_charge / transit_time;  % Amperes
        
        % Peak current density (at centroid)
        % Find particles near centroid
        near_centroid = abs(z_cloud*1000 - cloud_metrics(ipc).z_centroid) < 50 & ...
                       r_cloud*1000 < 10;  % Within 50mm axially, <10mm radially
        
        if sum(near_centroid) > 10
            charge_near_centroid = sum(cloud.weight(near_centroid)) * e_charge;
            volume_centroid = pi * (0.010)^2 * 0.050;  % Cylinder: r=10mm, L=50mm
            cloud_metrics(ipc).charge_density_peak = charge_near_centroid / volume_centroid;  % C/m³
        else
            cloud_metrics(ipc).charge_density_peak = NaN;
        end
        
        %% Velocity distribution (time-of-flight measurable)
        vz_cloud = cloud.vz;
        
        cloud_metrics(ipc).vz_mean = mean(abs(vz_cloud));
        cloud_metrics(ipc).vz_rms = std(vz_cloud);
        cloud_metrics(ipc).beta_mean = cloud_metrics(ipc).vz_mean / c;
        
        %% Source pulse breakdown (if available)
        if isfield(cloud, 'source_pulse')
            for src_p = 1:ipc
                from_pulse = sum(cloud.source_pulse == src_p);
                cloud_metrics(ipc).(['from_P' num2str(src_p)]) = from_pulse;
                cloud_metrics(ipc).(['frac_from_P' num2str(src_p)]) = from_pulse / cloud.n_total;
            end
        end
        
        %% Space charge field estimate (field probe measurable)
        % Use slow electrons for lensing estimate
        if cloud_metrics(ipc).n_slow > 10
            slow_electrons = E_cloud < 1.0;
            z_slow = z_cloud(slow_electrons);
            r_slow = r_cloud(slow_electrons);
            
            % Calculate slow cloud dimensions
            z_slow_span = (max(z_slow) - min(z_slow));
            r_slow_rms = sqrt(mean(r_slow.^2));
            
            if r_slow_rms > 0 && z_slow_span > 0
                volume_slow = pi * r_slow_rms^2 * z_slow_span;
                charge_slow = sum(cloud.weight(slow_electrons)) * e_charge;
                rho_slow = charge_slow / volume_slow;
                
                % Estimate SC field: E ≈ ρ*r/(2ε₀) for cylindrical distribution
                E_sc_estimate = abs(rho_slow) * r_slow_rms / (2*eps0);
                
                cloud_metrics(ipc).E_sc_slow_cloud = E_sc_estimate;  % V/m
                cloud_metrics(ipc).slow_cloud_r_rms = r_slow_rms * 1000;  % mm
                cloud_metrics(ipc).slow_cloud_z_span = z_slow_span * 1000;  % mm
            else
                cloud_metrics(ipc).E_sc_slow_cloud = NaN;
                cloud_metrics(ipc).slow_cloud_r_rms = NaN;
                cloud_metrics(ipc).slow_cloud_z_span = NaN;
            end
        else
            cloud_metrics(ipc).E_sc_slow_cloud = NaN;
            cloud_metrics(ipc).slow_cloud_r_rms = NaN;
            cloud_metrics(ipc).slow_cloud_z_span = NaN;
        end
    end
    
    %% ===== PRINT PUBLICATION-QUALITY COMPARISON TABLE =====
    fprintf('\n╔═══════════════════════════════════════════════════════════════════════╗\n');
    fprintf('║           INTER-PULSE ELECTRON CLOUD COMPARISON TABLE                 ║\n');
    fprintf('║              (Model Predictions for Experimental Validation)          ║\n');
    fprintf('╚═══════════════════════════════════════════════════════════════════════╝\n\n');
    
    fprintf('─────────────────────────────────────────────────────────────────────────\n');
    fprintf('%-25s | %12s | %12s | %12s\n', 'Parameter', 'Cloud 1', 'Cloud 2', 'Cloud 3');
    fprintf('%-25s | %12s | %12s | %12s\n', '', '(before P2)', '(before P3)', '(before P4)');
    fprintf('─────────────────────────────────────────────────────────────────────────\n');
    
    %% Population metrics
    fprintf('POPULATION METRICS:\n');
    fprintf('%-25s | %12d | %12d | %12d\n', 'Total electrons', ...
            cloud_metrics(1).n_total, cloud_metrics(2).n_total, cloud_metrics(3).n_total);
    fprintf('%-25s | %12d | %12d | %12d\n', 'Slow e⁻ (<1 MeV)', ...
            cloud_metrics(1).n_slow, cloud_metrics(2).n_slow, cloud_metrics(3).n_slow);
    fprintf('%-25s | %11.1f%% | %11.1f%% | %11.1f%%\n', 'Slow fraction', ...
            cloud_metrics(1).frac_slow*100, cloud_metrics(2).frac_slow*100, ...
            cloud_metrics(3).frac_slow*100);
    fprintf('\n');
    
    %% Energy metrics (measurable with magnetic spectrometer)
    fprintf('ENERGY DISTRIBUTION:\n');
    fprintf('%-25s | %10.3f MeV | %10.3f MeV | %10.3f MeV\n', 'Mean energy', ...
            cloud_metrics(1).E_mean, cloud_metrics(2).E_mean, cloud_metrics(3).E_mean);
    fprintf('%-25s | %10.3f MeV | %10.3f MeV | %10.3f MeV\n', 'Energy spread (RMS)', ...
            cloud_metrics(1).E_rms, cloud_metrics(2).E_rms, cloud_metrics(3).E_rms);
    fprintf('%-25s | %10.3f MeV | %10.3f MeV | %10.3f MeV\n', 'Energy range', ...
            cloud_metrics(1).E_max - cloud_metrics(1).E_min, ...
            cloud_metrics(2).E_max - cloud_metrics(2).E_min, ...
            cloud_metrics(3).E_max - cloud_metrics(3).E_min);
    fprintf('\n');
    
    %% Spatial metrics (measurable with BPMs)
    fprintf('SPATIAL DISTRIBUTION (BPM measurable):\n');
    fprintf('%-25s | %10.1f mm | %10.1f mm | %10.1f mm\n', 'Axial centroid (z)', ...
            cloud_metrics(1).z_centroid, cloud_metrics(2).z_centroid, cloud_metrics(3).z_centroid);
    fprintf('%-25s | %10.1f mm | %10.1f mm | %10.1f mm\n', 'Radial centroid (r)', ...
            cloud_metrics(1).r_centroid, cloud_metrics(2).r_centroid, cloud_metrics(3).r_centroid);
    fprintf('%-25s | %10.1f mm | %10.1f mm | %10.1f mm\n', 'Axial RMS size', ...
            cloud_metrics(1).z_rms, cloud_metrics(2).z_rms, cloud_metrics(3).z_rms);
    fprintf('%-25s | %10.1f mm | %10.1f mm | %10.1f mm\n', 'Radial RMS size', ...
            cloud_metrics(1).r_rms, cloud_metrics(2).r_rms, cloud_metrics(3).r_rms);
    fprintf('%-25s | %10.1f mm | %10.1f mm | %10.1f mm\n', 'Axial extent', ...
            cloud_metrics(1).z_span, cloud_metrics(2).z_span, cloud_metrics(3).z_span);
    fprintf('\n');
    
    %% Current metrics (ammeter measurable)
    fprintf('CURRENT MEASUREMENTS (ammeter):\n');
    fprintf('%-25s | %10.2f ÂµA | %10.2f ÂµA | %10.2f ÂµA\n', 'Equivalent current', ...
            cloud_metrics(1).current_equivalent*1e6, ...
            cloud_metrics(2).current_equivalent*1e6, ...
            cloud_metrics(3).current_equivalent*1e6);
    fprintf('%-25s | %10.2e C/m³ | %10.2e C/m³ | %10.2e C/m³\n', 'Peak charge density', ...
            cloud_metrics(1).charge_density_peak, ...
            cloud_metrics(2).charge_density_peak, ...
            cloud_metrics(3).charge_density_peak);
    fprintf('\n');
    
    %% Space charge field (electric field probe)
    fprintf('SPACE CHARGE FIELD (slow e⁻ lens):\n');
    fprintf('%-25s | %10.2f kV/m | %10.2f kV/m | %10.2f kV/m\n', 'SC field estimate', ...
            cloud_metrics(1).E_sc_slow_cloud/1e3, ...
            cloud_metrics(2).E_sc_slow_cloud/1e3, ...
            cloud_metrics(3).E_sc_slow_cloud/1e3);
    fprintf('%-25s | %10.1f mm | %10.1f mm | %10.1f mm\n', 'Slow cloud RMS radius', ...
            cloud_metrics(1).slow_cloud_r_rms, ...
            cloud_metrics(2).slow_cloud_r_rms, ...
            cloud_metrics(3).slow_cloud_r_rms);
    fprintf('\n');
    
    %% ===== TREND ANALYSIS: Growth vs Saturation =====
    fprintf('─────────────────────────────────────────────────────────────────────────\n');
    fprintf('TREND ANALYSIS (Model Prediction):\n');
    fprintf('─────────────────────────────────────────────────────────────────────────\n\n');
    
    % Population growth rates
    growth_1to2 = (cloud_metrics(2).n_total - cloud_metrics(1).n_total) / ...
                  cloud_metrics(1).n_total * 100;
    growth_2to3 = (cloud_metrics(3).n_total - cloud_metrics(2).n_total) / ...
                  cloud_metrics(2).n_total * 100;
    
    fprintf('Population Growth:\n');
    fprintf('  Cloud 1 → 2: %+.1f%% (%d → %d electrons)\n', ...
            growth_1to2, cloud_metrics(1).n_total, cloud_metrics(2).n_total);
    fprintf('  Cloud 2 → 3: %+.1f%% (%d → %d electrons)\n', ...
            growth_2to3, cloud_metrics(2).n_total, cloud_metrics(3).n_total);
    
    % Test for saturation
    if abs(growth_2to3) < abs(growth_1to2) * 0.5
        fprintf('  *** SATURATION DETECTED: Cloud growth slowing ***\n');
        fprintf('  → Equilibrium between creation and loss\n');
        saturation_regime = true;
    elseif abs(growth_2to3 - growth_1to2) < 10
        fprintf('  → LINEAR GROWTH: Consistent accumulation\n');
        fprintf('  → Clouds scale with pulse number\n');
        saturation_regime = false;
    else
        fprintf('  → ACCELERATING GROWTH: Non-linear accumulation\n');
        saturation_regime = false;
    end
    
    % Spatial drift analysis
    z_drift_1to2 = cloud_metrics(2).z_centroid - cloud_metrics(1).z_centroid;
    z_drift_2to3 = cloud_metrics(3).z_centroid - cloud_metrics(2).z_centroid;
    
    fprintf('\nSpatial Evolution:\n');
    fprintf('  Axial centroid drift (Cloud 1→2): %+.1f mm\n', z_drift_1to2);
    fprintf('  Axial centroid drift (Cloud 2→3): %+.1f mm\n', z_drift_2to3);
    
    if abs(z_drift_1to2) > 100
        fprintf('  *** Significant cloud migration detected! ***\n');
    else
        fprintf('  → Clouds remain spatially stable\n');
    end
    
    % Energy evolution
    E_shift_1to2 = cloud_metrics(2).E_mean - cloud_metrics(1).E_mean;
    E_shift_2to3 = cloud_metrics(3).E_mean - cloud_metrics(2).E_mean;
    
    fprintf('\nEnergy Evolution:\n');
    fprintf('  Mean energy shift (Cloud 1→2): %+.3f MeV\n', E_shift_1to2);
    fprintf('  Mean energy shift (Cloud 2→3): %+.3f MeV\n', E_shift_2to3);
    
    if abs(E_shift_1to2) < 0.01 && abs(E_shift_2to3) < 0.01
        fprintf('  → Energy distribution stable (<10 keV shift)\n');
    end
    
    %% ===== LENSING POTENTIAL ESTIMATE =====
    fprintf('\n─────────────────────────────────────────────────────────────────────────\n');
    fprintf('LENSING POTENTIAL FOR SUBSEQUENT PULSES:\n');
    fprintf('─────────────────────────────────────────────────────────────────────────\n\n');
    
    for ipc = 1:3
        fprintf('Cloud %d (before P%d, t=%.0f ns):\n', ipc, ipc+1, cloud_metrics(ipc).time_ns);
        
        if ~isnan(cloud_metrics(ipc).E_sc_slow_cloud)
            % Focusing strength: ΔE/E_beam
            beam_energy = 1.7e6;  % 1.7 MeV beam
            focusing_strength = cloud_metrics(ipc).E_sc_slow_cloud / beam_energy;
            
            % Estimated focal length (thin lens approximation)
            % f ≈ 1/(focusing_strength × L_interaction)
            L_interaction = cloud_metrics(ipc).slow_cloud_z_span / 1000;  % meters
            if L_interaction > 0
                focal_length = 1 / (focusing_strength * L_interaction);
            else
                focal_length = Inf;
            end
            
            % Predicted deflection at exit (2.7m from cloud centroid)
            z_cloud_to_exit = (2.700 - cloud_metrics(ipc).z_centroid/1000);  % m
            if isfinite(focal_length) && focal_length > 0
                predicted_delta_r = z_cloud_to_exit * focusing_strength * ...
                                   cloud_metrics(ipc).slow_cloud_r_rms / 1000;  % m
            else
                predicted_delta_r = 0;
            end
            
            fprintf('  SC field: %.2f kV/m\n', cloud_metrics(ipc).E_sc_slow_cloud/1e3);
            fprintf('  Focusing strength: %.2e\n', focusing_strength);
            fprintf('  Estimated focal length: %.1f m\n', focal_length);
            fprintf('  Predicted Δr at exit: %.2f mm', predicted_delta_r*1000);
            
            if abs(predicted_delta_r*1000) > 0.5
                if predicted_delta_r < 0
                    fprintf(' (P%d should be TIGHTER)\n', ipc+1);
                else
                    fprintf(' (P%d should be WIDER)\n', ipc+1);
                end
            else
                fprintf(' (negligible effect)\n');
            end
        else
            fprintf('  Insufficient slow electrons for lensing estimate\n');
        end
        fprintf('\n');
    end
    
    %% ===== SAVE METRICS FOR EXPERIMENTAL COMPARISON =====
    save('interpulse_cloud_metrics.mat', 'cloud_metrics', 'interpulse_clouds');
    
    % Export to CSV for easy sharing with experimentalists
    fid = fopen('interpulse_cloud_metrics.csv', 'w');
    fprintf(fid, 'Parameter,Cloud_1,Cloud_2,Cloud_3,Unit\n');
    fprintf(fid, 'Time,%.1f,%.1f,%.1f,ns\n', ...
            cloud_metrics(1).time_ns, cloud_metrics(2).time_ns, cloud_metrics(3).time_ns);
    fprintf(fid, 'Total_electrons,%d,%d,%d,count\n', ...
            cloud_metrics(1).n_total, cloud_metrics(2).n_total, cloud_metrics(3).n_total);
    fprintf(fid, 'Slow_electrons,%d,%d,%d,count\n', ...
            cloud_metrics(1).n_slow, cloud_metrics(2).n_slow, cloud_metrics(3).n_slow);
    fprintf(fid, 'Mean_energy,%.3f,%.3f,%.3f,MeV\n', ...
            cloud_metrics(1).E_mean, cloud_metrics(2).E_mean, cloud_metrics(3).E_mean);
    fprintf(fid, 'Energy_spread,%.3f,%.3f,%.3f,MeV\n', ...
            cloud_metrics(1).E_rms, cloud_metrics(2).E_rms, cloud_metrics(3).E_rms);
    fprintf(fid, 'Z_centroid,%.1f,%.1f,%.1f,mm\n', ...
            cloud_metrics(1).z_centroid, cloud_metrics(2).z_centroid, cloud_metrics(3).z_centroid);
    fprintf(fid, 'R_centroid,%.1f,%.1f,%.1f,mm\n', ...
            cloud_metrics(1).r_centroid, cloud_metrics(2).r_centroid, cloud_metrics(3).r_centroid);
    fprintf(fid, 'Z_RMS,%.1f,%.1f,%.1f,mm\n', ...
            cloud_metrics(1).z_rms, cloud_metrics(2).z_rms, cloud_metrics(3).z_rms);
    fprintf(fid, 'R_RMS,%.1f,%.1f,%.1f,mm\n', ...
            cloud_metrics(1).r_rms, cloud_metrics(2).r_rms, cloud_metrics(3).r_rms);
    fprintf(fid, 'Equivalent_current,%.2f,%.2f,%.2f,microA\n', ...
            cloud_metrics(1).current_equivalent*1e6, ...
            cloud_metrics(2).current_equivalent*1e6, ...
            cloud_metrics(3).current_equivalent*1e6);
    fprintf(fid, 'SC_field_estimate,%.2f,%.2f,%.2f,kV/m\n', ...
            cloud_metrics(1).E_sc_slow_cloud/1e3, ...
            cloud_metrics(2).E_sc_slow_cloud/1e3, ...
            cloud_metrics(3).E_sc_slow_cloud/1e3);
    fclose(fid);
    
    fprintf('✓ Metrics saved to interpulse_cloud_metrics.mat\n');
    fprintf('✓ CSV exported to interpulse_cloud_metrics.csv\n');
    
    %% ===== CREATE COMPREHENSIVE COMPARISON FIGURE =====
    figure('Position', [100, 100, 1800, 1200], ...
           'Name', 'Inter-Pulse Cloud Quantitative Comparison');
    
    %% Plot 1: Population evolution
    subplot(3,3,1);
    n_tots = [cloud_metrics.n_total];
    n_slows = [cloud_metrics.n_slow];
    
    hold on;
    plot(1:3, n_tots, 'bo-', 'LineWidth', 3, 'MarkerSize', 14, ...
         'MarkerFaceColor', 'b', 'DisplayName', 'Total e⁻');
    plot(1:3, n_slows, 'ro-', 'LineWidth', 3, 'MarkerSize', 14, ...
         'MarkerFaceColor', 'r', 'DisplayName', 'Slow e⁻ (<1 MeV)');
    
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('Electron Count', 'FontSize', 13);
    title('Population Evolution', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    set(gca, 'XTick', 1:3);
    
    % Fit linear trend to test saturation
    p_linear = polyfit(1:3, n_tots, 1);
    n_fit = polyval(p_linear, 1:3);
    plot(1:3, n_fit, 'k:', 'LineWidth', 2, 'DisplayName', 'Linear fit');
    
    % Calculate R²
    SS_res = sum((n_tots - n_fit).^2);
    SS_tot = sum((n_tots - mean(n_tots)).^2);
    R2 = 1 - SS_res/SS_tot;
    
    text(0.55, 0.9, sprintf('R² = %.3f', R2), 'Units', 'normalized', ...
         'FontSize', 11, 'BackgroundColor', 'white');
    
    if R2 < 0.90
        text(0.55, 0.82, '→ Non-linear', 'Units', 'normalized', ...
             'FontSize', 10, 'Color', 'red', 'FontWeight', 'bold');
    end
    
    %% Plot 2: Energy distribution evolution
    subplot(3,3,2);
    E_means = [cloud_metrics.E_mean];
    E_stds = [cloud_metrics.E_rms];
    
    errorbar(1:3, E_means, E_stds, 'go-', 'LineWidth', 3, 'MarkerSize', 14, ...
             'CapSize', 12, 'MarkerFaceColor', 'g');
    
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('Mean Energy (MeV)', 'FontSize', 13);
    title('Energy Distribution Evolution', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTick', 1:3);
    ylim([0 1.0]);
    
    %% Plot 3: Slow electron fraction (key for lensing)
    subplot(3,3,3);
    slow_fracs = [cloud_metrics.frac_slow] * 100;
    
    bar(1:3, slow_fracs, 'FaceColor', [0.8 0.3 0.3], 'BarWidth', 0.6);
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('Slow e⁻ Fraction (%)', 'FontSize', 13);
    title('Slow Electron Content', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTick', 1:3);
    
    % Add values on bars
    for ipc = 1:3
        text(ipc, slow_fracs(ipc)+1, sprintf('%.1f%%', slow_fracs(ipc)), ...
             'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
    end
    
    %% Plot 4: Spatial centroid evolution
    subplot(3,3,4);
    z_centroids = [cloud_metrics.z_centroid];
    r_centroids = [cloud_metrics.r_centroid];
    
    yyaxis left
    plot(1:3, z_centroids, 'b-o', 'LineWidth', 3, 'MarkerSize', 14, 'MarkerFaceColor', 'b');
    ylabel('Axial Centroid z (mm)', 'FontSize', 13);
    ylim([0 8310]);
    
    yyaxis right
    plot(1:3, r_centroids, 'r-s', 'LineWidth', 3, 'MarkerSize', 14, 'MarkerFaceColor', 'r');
    ylabel('Radial Centroid r (mm)', 'FontSize', 13);
    ylim([0 60]);
    
    xlabel('Cloud Number', 'FontSize', 13);
    title('Cloud Centroid Evolution', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Axial (z)', 'Radial (r)', 'Location', 'best');
    grid on;
    set(gca, 'XTick', 1:3);
    
    %% Plot 5: RMS size evolution
    subplot(3,3,5);
    z_rms_vals = [cloud_metrics.z_rms];
    r_rms_vals = [cloud_metrics.r_rms];
    
    hold on;
    plot(1:3, z_rms_vals, 'b-o', 'LineWidth', 3, 'MarkerSize', 14, ...
         'MarkerFaceColor', 'b', 'DisplayName', 'Axial RMS (z)');
    plot(1:3, r_rms_vals, 'r-s', 'LineWidth', 3, 'MarkerSize', 14, ...
         'MarkerFaceColor', 'r', 'DisplayName', 'Radial RMS (r)');
    
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('RMS Size (mm)', 'FontSize', 13);
    title('Cloud Size Evolution', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    set(gca, 'XTick', 1:3);
    
    %% Plot 6: Equivalent current (experimental signature)
    subplot(3,3,6);
    currents = [cloud_metrics.current_equivalent] * 1e6;  % µA
    
    bar(1:3, currents, 'FaceColor', [0.3 0.7 0.5], 'BarWidth', 0.6);
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('Equivalent Current (µA)', 'FontSize', 13);
    title('Inter-Pulse Current Signature', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTick', 1:3);
    
    % Add measurement threshold reference
    yline(0.1, 'r--', 'LineWidth', 2, 'Label', 'Typical detector threshold');
    
    % Add values on bars
    for ipc = 1:3
        text(ipc, currents(ipc)+0.02, sprintf('%.2f µA', currents(ipc)), ...
             'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
    end
    
    %% Plot 7: Space charge field progression
    subplot(3,3,7);
    sc_fields = [cloud_metrics.E_sc_slow_cloud] / 1e3;  % kV/m
    
    bar(1:3, sc_fields, 'FaceColor', [0.7 0.4 0.9], 'BarWidth', 0.6);
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('SC Field (kV/m)', 'FontSize', 13);
    title('Lensing Field Strength', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTick', 1:3);
    
    % Add beam energy reference
    yline(1700, 'r--', 'LineWidth', 2, 'Label', 'Beam energy (1.7 MV/m)');
    
    % Calculate field/energy ratio
    for ipc = 1:3
        if ~isnan(sc_fields(ipc))
            ratio = sc_fields(ipc) / 1700;
            text(ipc, sc_fields(ipc)+10, sprintf('%.2e', ratio), ...
                 'HorizontalAlignment', 'center', 'FontSize', 10);
        end
    end
    
    %% Plot 8: Longitudinal profile comparison
    subplot(3,3,8);
    hold on;
    colors_cloud = ['b', 'g', 'r'];
    
    for ipc = 1:3
        cloud = interpulse_clouds{ipc};
        %[n_z, z_edges_prof] = histcounts(cloud.z*1000, 0:100:2700);
        [n_z, z_edges_prof] = histcounts(cloud.z*1000, 0:100:8300);
        z_centers_prof = z_edges_prof(1:end-1) + 50;
        
        plot(z_centers_prof, n_z, [colors_cloud(ipc) '-'], 'LineWidth', 2.5, ...
             'DisplayName', sprintf('Cloud %d', ipc));
    end
    
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('Electron Count per 100mm', 'FontSize', 13);
    title('Longitudinal Profile Comparison', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    %% Plot 9: Experimental validation checklist
    subplot(3,3,9);
    axis off;
    
    text(0.5, 0.95, 'EXPERIMENTAL VALIDATION', 'FontWeight', 'bold', 'FontSize', 15, ...
         'HorizontalAlignment', 'center', 'Color', [0.7 0 0]);
    text(0.5, 0.88, 'Recommended Measurements:', 'FontSize', 13, ...
         'HorizontalAlignment', 'center');
    
    y_pos = 0.75;
    
    % List key experimental observables
    observables = {
        '1. Current monitors:', sprintf('%.1f-%.1f µA between pulses', min(currents), max(currents));
        '2. BPM readings:', sprintf('Cloud at z≈%.0f-%.0f mm', min(z_centroids), max(z_centroids));
        '3. Energy analyzer:', sprintf('E≈%.2f±%.2f MeV', mean(E_means), mean(E_stds));
        '4. Beam size change:', sprintf('ΔrP2-P4 ≈ %.2f-%.2f mm', min(delta_r), max(delta_r));
        '5. Faraday cup:', sprintf('Total charge ≈%.1f pC/cloud', mean(currents)*10);
    };
    
    for i = 1:size(observables, 1)
        text(0.05, y_pos, observables{i,1}, 'FontSize', 11, 'FontWeight', 'bold');
        y_pos = y_pos - 0.06;
        text(0.10, y_pos, observables{i,2}, 'FontSize', 10, 'Color', [0.2 0.2 0.7]);
        y_pos = y_pos - 0.10;
    end
    
    % Add saturation prediction
    y_pos = 0.15;
    text(0.5, y_pos, 'MODEL PREDICTION:', 'FontSize', 12, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'Color', 'red');
    y_pos = y_pos - 0.08;
    
    if saturation_regime
        text(0.5, y_pos, '✓ Cloud SATURATION detected', 'FontSize', 11, ...
             'HorizontalAlignment', 'center', 'Color', 'green', 'FontWeight', 'bold');
        y_pos = y_pos - 0.06;
        text(0.5, y_pos, '→ P4 lensing ≈ P3 lensing', 'FontSize', 10, ...
             'HorizontalAlignment', 'center');
    else
        text(0.5, y_pos, '→ Linear cloud growth', 'FontSize', 11, ...
             'HorizontalAlignment', 'center', 'Color', 'blue', 'FontWeight', 'bold');
        y_pos = y_pos - 0.06;
        text(0.5, y_pos, '→ P4 lensing > P3 lensing', 'FontSize', 10, ...
             'HorizontalAlignment', 'center');
    end
    
    sgtitle('Inter-Pulse Electron Cloud: Quantitative Comparison for Experimental Validation', ...
            'FontSize', 18, 'FontWeight', 'bold');
    
    % Save figure
    saveas(gcf, 'Test70_Cloud_Quantitative_Comparison.fig');
    saveas(gcf, 'Test70_Cloud_Quantitative_Comparison.png');
    
    fprintf('\n✓ Quantitative cloud comparison figure created!\n');
end
%%%%%%%%%%%%%%%%%%%%%%%%% Added 02.09.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== CLOUD SPATIAL OVERLAP ANALYSIS ====================
% Calculate spatial correlation between consecutive clouds
% High overlap → cumulative lensing effect

if exist('interpulse_clouds', 'var') && length(interpulse_clouds) == 3
    
    fprintf('\n=== CLOUD SPATIAL OVERLAP ANALYSIS ===\n');
    
    figure('Position', [100, 100, 1400, 500], ...
           'Name', 'Inter-Pulse Cloud Spatial Correlation');
    
    % Create 2D histograms for all clouds
    z_bins = 0:50:8300;
    r_bins = 0:5:80;
    
    density_clouds = zeros(length(r_bins)-1, length(z_bins)-1, 3);
    
    for ipc = 1:3
        cloud = interpulse_clouds{ipc};
        [N, ~, ~] = histcounts2(cloud.r*1000, cloud.z*1000, r_bins, z_bins);
        density_clouds(:,:,ipc) = N;
    end
    
    %% Subplot 1: Cloud 1 vs Cloud 2 overlap
    subplot(1,3,1);
    
    % Normalize to maximum
    d1_norm = density_clouds(:,:,1) / max(density_clouds(:,:,1), [], 'all');
    d2_norm = density_clouds(:,:,2) / max(density_clouds(:,:,2), [], 'all');
    
    % Calculate overlap (element-wise minimum)
    overlap_12 = min(d1_norm, d2_norm);
    
    imagesc(z_bins(1:end-1)+25, r_bins(1:end-1)+2.5, overlap_12);
    axis xy;
    colorbar;
    title('Cloud 1 ∩ Cloud 2 Overlap', 'FontSize', 14);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    
    % Calculate overlap fraction
    overlap_frac_12 = sum(overlap_12(:)) / sum(d1_norm(:));
    text(0.05, 0.95, sprintf('Overlap: %.1f%%', overlap_frac_12*100), ...
         'Units', 'normalized', 'Color', 'white', 'FontSize', 13, 'FontWeight', 'bold');
    
    %% Subplot 2: Cloud 2 vs Cloud 3 overlap
    subplot(1,3,2);
    
    d3_norm = density_clouds(:,:,3) / max(density_clouds(:,:,3), [], 'all');
    overlap_23 = min(d2_norm, d3_norm);
    
    imagesc(z_bins(1:end-1)+25, r_bins(1:end-1)+2.5, overlap_23);
    axis xy;
    colorbar;
    title('Cloud 2 ∩ Cloud 3 Overlap', 'FontSize', 14);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    
    overlap_frac_23 = sum(overlap_23(:)) / sum(d2_norm(:));
    text(0.05, 0.95, sprintf('Overlap: %.1f%%', overlap_frac_23*100), ...
         'Units', 'normalized', 'Color', 'white', 'FontSize', 13, 'FontWeight', 'bold');
    
    %% Subplot 3: Three-way overlap
    subplot(1,3,3);
    
    % Triple overlap
    overlap_all = min(min(d1_norm, d2_norm), d3_norm);
    
    imagesc(z_bins(1:end-1)+25, r_bins(1:end-1)+2.5, overlap_all);
    axis xy;
    colorbar;
    title('All Three Clouds Overlap', 'FontSize', 14);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r (mm)', 'FontSize', 12);
    hold on;
    plot([0 8310], [75 75], 'w--', 'LineWidth', 2);
    
    overlap_frac_all = sum(overlap_all(:)) / sum(d1_norm(:));
    text(0.05, 0.95, sprintf('Overlap: %.1f%%', overlap_frac_all*100), ...
         'Units', 'normalized', 'Color', 'white', 'FontSize', 13, 'FontWeight', 'bold');
    
    sgtitle('Spatial Correlation Between Inter-Pulse Clouds', 'FontSize', 16);
    
    % Print interpretation
    fprintf('\nSpatial Overlap Analysis:\n');
    fprintf('  Cloud 1-2 overlap: %.1f%%\n', overlap_frac_12*100);
    fprintf('  Cloud 2-3 overlap: %.1f%%\n', overlap_frac_23*100);
    fprintf('  Three-way overlap: %.1f%%\n', overlap_frac_all*100);
    
    if overlap_frac_all > 0.5
        fprintf('  *** High spatial correlation - cumulative lensing likely! ***\n');
    elseif overlap_frac_all > 0.2
        fprintf('  → Moderate spatial correlation\n');
    else
        fprintf('  → Clouds occupy different regions - independent lensing\n');
    end
    
    % Save
    saveas(gcf, 'Test70_Cloud_Spatial_Correlation.fig');
    saveas(gcf, 'Test70_Cloud_Spatial_Correlation.png');
end
%%%%%%%%%%%%%%%%%%%%%%%% Added 02.09.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== QUANTITATIVE INTER-PULSE CLOUD ANALYSIS WITH UNCERTAINTIES ====================
%% CRITICAL FOR EXPERIMENTAL VALIDATION
% Uses bootstrap resampling to estimate statistical uncertainties
% Provides confidence intervals for all experimentally measurable quantities

if exist('interpulse_clouds', 'var') && length(interpulse_clouds) == 3 && ...
   all(cellfun(@(x) ~isempty(x), interpulse_clouds))
    
    fprintf('\n========================================================================\n');
    fprintf('  QUANTITATIVE INTER-PULSE CLOUD COMPARISON WITH UNCERTAINTIES         \n');
    fprintf('  (For Experimental Validation)                                        \n');
    fprintf('========================================================================\n');
    
    %% Bootstrap configuration
    n_bootstrap = 1000;  % Number of bootstrap samples
    confidence_level = 0.95;  % 95% confidence intervals
    
    %% ===== EXTRACT METRICS WITH UNCERTAINTIES FROM ALL THREE CLOUDS =====
    cloud_metrics = struct();
    
    for ipc = 1:3
        cloud = interpulse_clouds{ipc};
        n_particles = cloud.n_total;
        
        fprintf('\n=== Processing Cloud %d (before P%d, t=%.0f ns) ===\n', ...
                ipc, ipc+1, cloud.time*1e9);
        fprintf('Total particles: %d\n', n_particles);
        
        %% Basic identifiers
        cloud_metrics(ipc).time_ns = cloud.time * 1e9;
        cloud_metrics(ipc).before_pulse = cloud.before_pulse;
        cloud_metrics(ipc).n_total = n_particles;
        
        %% ===== BOOTSTRAP RESAMPLING FOR UNCERTAINTIES =====
        % Pre-allocate bootstrap arrays
        boot_E_mean = zeros(n_bootstrap, 1);
        boot_E_rms = zeros(n_bootstrap, 1);
        boot_z_centroid = zeros(n_bootstrap, 1);
        boot_r_centroid = zeros(n_bootstrap, 1);
        boot_z_rms = zeros(n_bootstrap, 1);
        boot_r_rms = zeros(n_bootstrap, 1);
        boot_vz_mean = zeros(n_bootstrap, 1);
        boot_slow_frac = zeros(n_bootstrap, 1);
        
        % Extract cloud data
        E_cloud = cloud.energy_MeV;
        z_cloud = cloud.z;
        r_cloud = cloud.r;
        vz_cloud = cloud.vz;
        weights = cloud.weight;
        
        fprintf('Running %d bootstrap samples...', n_bootstrap);
        
        for ib = 1:n_bootstrap
            % Random sample with replacement
            idx_boot = randi(n_particles, n_particles, 1);
            
            % Resample data
            E_boot = E_cloud(idx_boot);
            z_boot = z_cloud(idx_boot);
            r_boot = r_cloud(idx_boot);
            vz_boot = vz_cloud(idx_boot);
            w_boot = weights(idx_boot);
            
            % Calculate metrics for this bootstrap sample
            boot_E_mean(ib) = mean(E_boot);
            boot_E_rms(ib) = std(E_boot);
            boot_z_centroid(ib) = sum(z_boot .* w_boot) / sum(w_boot);  % Weighted
            boot_r_centroid(ib) = sqrt(sum(r_boot.^2 .* w_boot) / sum(w_boot));
            boot_z_rms(ib) = std(z_boot);
            boot_r_rms(ib) = sqrt(mean(r_boot.^2));
            boot_vz_mean(ib) = mean(abs(vz_boot));
            boot_slow_frac(ib) = sum(E_boot < 1.0) / length(E_boot);
            
            % Progress indicator
            if mod(ib, 200) == 0
                fprintf('.');
            end
        end
        fprintf(' Done!\n');
        
        %% ===== CALCULATE CONFIDENCE INTERVALS =====
        alpha = 1 - confidence_level;
        percentile_low = 100 * alpha/2;
        percentile_high = 100 * (1 - alpha/2);
        
        %% Energy metrics with uncertainties
        cloud_metrics(ipc).E_mean = mean(E_cloud);
        cloud_metrics(ipc).E_mean_std = std(boot_E_mean);
        cloud_metrics(ipc).E_mean_CI = [prctile(boot_E_mean, percentile_low), ...
                                        prctile(boot_E_mean, percentile_high)];
        
        cloud_metrics(ipc).E_rms = std(E_cloud);
        cloud_metrics(ipc).E_rms_std = std(boot_E_rms);
        cloud_metrics(ipc).E_rms_CI = [prctile(boot_E_rms, percentile_low), ...
                                       prctile(boot_E_rms, percentile_high)];
        
        cloud_metrics(ipc).E_median = median(E_cloud);
        cloud_metrics(ipc).E_min = min(E_cloud);
        cloud_metrics(ipc).E_max = max(E_cloud);
        
        %% Population fractions with uncertainties
        cloud_metrics(ipc).n_slow = sum(E_cloud < 1.0);
        cloud_metrics(ipc).n_medium = sum(E_cloud >= 1.0 & E_cloud <= 1.6);
        cloud_metrics(ipc).n_fast = sum(E_cloud > 1.6);
        
        cloud_metrics(ipc).frac_slow = mean(E_cloud < 1.0);
        cloud_metrics(ipc).frac_slow_std = std(boot_slow_frac);
        cloud_metrics(ipc).frac_slow_CI = [prctile(boot_slow_frac, percentile_low), ...
                                           prctile(boot_slow_frac, percentile_high)];
        
        %% Spatial metrics with uncertainties
        cloud_metrics(ipc).z_centroid = mean(boot_z_centroid) * 1000;  % mm
        cloud_metrics(ipc).z_centroid_std = std(boot_z_centroid) * 1000;
        cloud_metrics(ipc).z_centroid_CI = [prctile(boot_z_centroid, percentile_low) * 1000, ...
                                            prctile(boot_z_centroid, percentile_high) * 1000];
        
        cloud_metrics(ipc).r_centroid = mean(boot_r_centroid) * 1000;  % mm
        cloud_metrics(ipc).r_centroid_std = std(boot_r_centroid) * 1000;
        cloud_metrics(ipc).r_centroid_CI = [prctile(boot_r_centroid, percentile_low) * 1000, ...
                                            prctile(boot_r_centroid, percentile_high) * 1000];
        
        cloud_metrics(ipc).z_rms = mean(boot_z_rms) * 1000;  % mm
        cloud_metrics(ipc).z_rms_std = std(boot_z_rms) * 1000;
        
        cloud_metrics(ipc).r_rms = mean(boot_r_rms) * 1000;  % mm
        cloud_metrics(ipc).r_rms_std = std(boot_r_rms) * 1000;
        
        % Extent measurements
        cloud_metrics(ipc).z_min = min(z_cloud) * 1000;
        cloud_metrics(ipc).z_max = max(z_cloud) * 1000;
        cloud_metrics(ipc).z_span = (max(z_cloud) - min(z_cloud)) * 1000;
        cloud_metrics(ipc).r_max = max(r_cloud) * 1000;
        
        %% Current with uncertainty
        total_charge = sum(weights) * e_charge;
        transit_time = 10e-9;  % seconds (10ns detector window)
        
        cloud_metrics(ipc).current_equivalent = total_charge / transit_time;  % A
        
        % Uncertainty from charge counting statistics (Poisson)
        % For weighted particles: σ²(Q) = Σw²
        charge_variance = sum(weights.^2) * e_charge^2;
        cloud_metrics(ipc).current_std = sqrt(charge_variance) / transit_time;
        
        cloud_metrics(ipc).current_CI = cloud_metrics(ipc).current_equivalent + ...
                                         [-1.96, 1.96] * cloud_metrics(ipc).current_std;
        
        %% Velocity distribution
        cloud_metrics(ipc).vz_mean = mean(boot_vz_mean);
        cloud_metrics(ipc).vz_mean_std = std(boot_vz_mean);
        cloud_metrics(ipc).beta_mean = cloud_metrics(ipc).vz_mean / c;
        cloud_metrics(ipc).beta_std = cloud_metrics(ipc).vz_mean_std / c;
        
        %% Space charge field estimate with propagated uncertainty
        slow_electrons = E_cloud < 1.0;
        
        if sum(slow_electrons) > 10
            z_slow = z_cloud(slow_electrons);
            r_slow = r_cloud(slow_electrons);
            w_slow = weights(slow_electrons);
            
            % Bootstrap SC field calculation
            boot_E_sc = zeros(n_bootstrap, 1);
            
            for ib = 1:min(200, n_bootstrap)  % Limited samples for speed
                idx_boot = randi(sum(slow_electrons), sum(slow_electrons), 1);
                
                r_slow_boot = r_slow(idx_boot);
                w_slow_boot = w_slow(idx_boot);
                
                r_rms_slow_boot = sqrt(sum(r_slow_boot.^2 .* w_slow_boot) / sum(w_slow_boot));
                z_span_boot = max(z_slow(idx_boot)) - min(z_slow(idx_boot));
                
                if r_rms_slow_boot > 0 && z_span_boot > 0
                    vol_boot = pi * r_rms_slow_boot^2 * z_span_boot;
                    charge_boot = sum(w_slow_boot) * e_charge;
                    rho_boot = charge_boot / vol_boot;
                    boot_E_sc(ib) = abs(rho_boot) * r_rms_slow_boot / (2*eps0);
                else
                    boot_E_sc(ib) = NaN;
                end
            end
            
            % Remove NaN values
            boot_E_sc = boot_E_sc(~isnan(boot_E_sc));
            
            if ~isempty(boot_E_sc)
                cloud_metrics(ipc).E_sc_slow_cloud = mean(boot_E_sc);
                cloud_metrics(ipc).E_sc_slow_cloud_std = std(boot_E_sc);
                cloud_metrics(ipc).E_sc_slow_cloud_CI = [prctile(boot_E_sc, percentile_low), ...
                                                         prctile(boot_E_sc, percentile_high)];
                
                % Slow cloud dimensions
                cloud_metrics(ipc).slow_cloud_r_rms = sqrt(mean(r_slow.^2)) * 1000;  % mm
                cloud_metrics(ipc).slow_cloud_z_span = (max(z_slow) - min(z_slow)) * 1000;  % mm
            else
                cloud_metrics(ipc).E_sc_slow_cloud = NaN;
                cloud_metrics(ipc).E_sc_slow_cloud_std = NaN;
                cloud_metrics(ipc).E_sc_slow_cloud_CI = [NaN, NaN];
            end
        else
            cloud_metrics(ipc).E_sc_slow_cloud = NaN;
            cloud_metrics(ipc).E_sc_slow_cloud_std = NaN;
            cloud_metrics(ipc).E_sc_slow_cloud_CI = [NaN, NaN];
            cloud_metrics(ipc).slow_cloud_r_rms = NaN;
            cloud_metrics(ipc).slow_cloud_z_span = NaN;
        end
        
        %% Peak charge density with uncertainty
        near_centroid = abs(z_cloud*1000 - cloud_metrics(ipc).z_centroid) < 50 & ...
                       r_cloud*1000 < 10;
        
        if sum(near_centroid) > 10
            charge_near = sum(weights(near_centroid)) * e_charge;
            volume_centroid = pi * (0.010)^2 * 0.050;
            cloud_metrics(ipc).charge_density_peak = charge_near / volume_centroid;
            
            % Uncertainty from particle statistics
            charge_variance_near = sum(weights(near_centroid).^2) * e_charge^2;
            cloud_metrics(ipc).charge_density_peak_std = sqrt(charge_variance_near) / volume_centroid;
        else
            cloud_metrics(ipc).charge_density_peak = NaN;
            cloud_metrics(ipc).charge_density_peak_std = NaN;
        end
    end
    
    %% ===== PRINT PUBLICATION-QUALITY TABLE WITH UNCERTAINTIES =====
    fprintf('\n╔═══════════════════════════════════════════════════════════════════════════════════╗\n');
    fprintf('║        INTER-PULSE ELECTRON CLOUD COMPARISON WITH UNCERTAINTIES                  ║\n');
    fprintf('║        (Model Predictions ± Statistical Errors for Experimental Validation)      ║\n');
    fprintf('╚═══════════════════════════════════════════════════════════════════════════════════╝\n\n');
    
    fprintf('═════════════════════════════════════════════════════════════════════════════════════\n');
    fprintf('%-30s | %20s | %20s | %20s\n', 'Parameter', 'Cloud 1', 'Cloud 2', 'Cloud 3');
    fprintf('%-30s | %20s | %20s | %20s\n', '', '(before P2)', '(before P3)', '(before P4)');
    fprintf('═════════════════════════════════════════════════════════════════════════════════════\n');
    
    %% POPULATION METRICS
    fprintf('\n📊 POPULATION METRICS:\n');
    fprintf('─────────────────────────────────────────────────────────────────────────────────────\n');
    fprintf('%-30s | %20d | %20d | %20d\n', 'Total electrons', ...
            cloud_metrics(1).n_total, cloud_metrics(2).n_total, cloud_metrics(3).n_total);
    fprintf('%-30s | %20d | %20d | %20d\n', 'Slow e⁻ (<1 MeV)', ...
            cloud_metrics(1).n_slow, cloud_metrics(2).n_slow, cloud_metrics(3).n_slow);
    
    % Slow fraction with uncertainties
    fprintf('%-30s | %17.1f±%.1f%% | %17.1f±%.1f%% | %17.1f±%.1f%%\n', 'Slow fraction', ...
            cloud_metrics(1).frac_slow*100, cloud_metrics(1).frac_slow_std*100, ...
            cloud_metrics(2).frac_slow*100, cloud_metrics(2).frac_slow_std*100, ...
            cloud_metrics(3).frac_slow*100, cloud_metrics(3).frac_slow_std*100);
    
    % Confidence intervals for slow fraction
    fprintf('%-30s | [%.1f, %.1f]%%      | [%.1f, %.1f]%%      | [%.1f, %.1f]%%\n', ...
            '  95% CI', ...
            cloud_metrics(1).frac_slow_CI(1)*100, cloud_metrics(1).frac_slow_CI(2)*100, ...
            cloud_metrics(2).frac_slow_CI(1)*100, cloud_metrics(2).frac_slow_CI(2)*100, ...
            cloud_metrics(3).frac_slow_CI(1)*100, cloud_metrics(3).frac_slow_CI(2)*100);
    
    %% ENERGY DISTRIBUTION
    fprintf('\n⚡ ENERGY DISTRIBUTION (Magnetic Spectrometer):\n');
    fprintf('─────────────────────────────────────────────────────────────────────────────────────\n');
    
    fprintf('%-30s | %16.3f±%.3f MeV | %16.3f±%.3f MeV | %16.3f±%.3f MeV\n', ...
            'Mean energy', ...
            cloud_metrics(1).E_mean, cloud_metrics(1).E_mean_std, ...
            cloud_metrics(2).E_mean, cloud_metrics(2).E_mean_std, ...
            cloud_metrics(3).E_mean, cloud_metrics(3).E_mean_std);
    
    fprintf('%-30s | [%.3f, %.3f] MeV | [%.3f, %.3f] MeV | [%.3f, %.3f] MeV\n', ...
            '  95% CI', ...
            cloud_metrics(1).E_mean_CI(1), cloud_metrics(1).E_mean_CI(2), ...
            cloud_metrics(2).E_mean_CI(1), cloud_metrics(2).E_mean_CI(2), ...
            cloud_metrics(3).E_mean_CI(1), cloud_metrics(3).E_mean_CI(2));
    
    fprintf('%-30s | %16.3f±%.3f MeV | %16.3f±%.3f MeV | %16.3f±%.3f MeV\n', ...
            'Energy spread (RMS)', ...
            cloud_metrics(1).E_rms, cloud_metrics(1).E_rms_std, ...
            cloud_metrics(2).E_rms, cloud_metrics(2).E_rms_std, ...
            cloud_metrics(3).E_rms, cloud_metrics(3).E_rms_std);
    
    fprintf('%-30s | %17.3f MeV | %17.3f MeV | %17.3f MeV\n', 'Energy range (min-max)', ...
            cloud_metrics(1).E_max - cloud_metrics(1).E_min, ...
            cloud_metrics(2).E_max - cloud_metrics(2).E_min, ...
            cloud_metrics(3).E_max - cloud_metrics(3).E_min);
    
    %% SPATIAL DISTRIBUTION
    fprintf('\n📍 SPATIAL DISTRIBUTION (BPM/Screen Measurable):\n');
    fprintf('─────────────────────────────────────────────────────────────────────────────────────\n');
    
    fprintf('%-30s | %16.1f±%.1f mm | %16.1f±%.1f mm | %16.1f±%.1f mm\n', ...
            'Axial centroid (z)', ...
            cloud_metrics(1).z_centroid, cloud_metrics(1).z_centroid_std, ...
            cloud_metrics(2).z_centroid, cloud_metrics(2).z_centroid_std, ...
            cloud_metrics(3).z_centroid, cloud_metrics(3).z_centroid_std);
    
    fprintf('%-30s | [%.0f, %.0f] mm    | [%.0f, %.0f] mm    | [%.0f, %.0f] mm\n', ...
            '  95% CI', ...
            cloud_metrics(1).z_centroid_CI(1), cloud_metrics(1).z_centroid_CI(2), ...
            cloud_metrics(2).z_centroid_CI(1), cloud_metrics(2).z_centroid_CI(2), ...
            cloud_metrics(3).z_centroid_CI(1), cloud_metrics(3).z_centroid_CI(2));
    
    fprintf('%-30s | %16.1f±%.1f mm | %16.1f±%.1f mm | %16.1f±%.1f mm\n', ...
            'Radial centroid (r)', ...
            cloud_metrics(1).r_centroid, cloud_metrics(1).r_centroid_std, ...
            cloud_metrics(2).r_centroid, cloud_metrics(2).r_centroid_std, ...
            cloud_metrics(3).r_centroid, cloud_metrics(3).r_centroid_std);
    
    fprintf('%-30s | [%.1f, %.1f] mm    | [%.1f, %.1f] mm    | [%.1f, %.1f] mm\n', ...
            '  95% CI', ...
            cloud_metrics(1).r_centroid_CI(1), cloud_metrics(1).r_centroid_CI(2), ...
            cloud_metrics(2).r_centroid_CI(1), cloud_metrics(2).r_centroid_CI(2), ...
            cloud_metrics(3).r_centroid_CI(1), cloud_metrics(3).r_centroid_CI(2));
    
    fprintf('%-30s | %16.1f±%.1f mm | %16.1f±%.1f mm | %16.1f±%.1f mm\n', ...
            'Axial RMS size', ...
            cloud_metrics(1).z_rms, cloud_metrics(1).z_rms_std, ...
            cloud_metrics(2).z_rms, cloud_metrics(2).z_rms_std, ...
            cloud_metrics(3).z_rms, cloud_metrics(3).z_rms_std);
    
    fprintf('%-30s | %16.1f±%.1f mm | %16.1f±%.1f mm | %16.1f±%.1f mm\n', ...
            'Radial RMS size', ...
            cloud_metrics(1).r_rms, cloud_metrics(1).r_rms_std, ...
            cloud_metrics(2).r_rms, cloud_metrics(2).r_rms_std, ...
            cloud_metrics(3).r_rms, cloud_metrics(3).r_rms_std);
    
    fprintf('%-30s | %17.1f mm | %17.1f mm | %17.1f mm\n', 'Axial extent (z_max-z_min)', ...
            cloud_metrics(1).z_span, cloud_metrics(2).z_span, cloud_metrics(3).z_span);
    
    %% CURRENT MEASUREMENTS
    fprintf('\n🔌 CURRENT MEASUREMENTS (Ammeter/Faraday Cup):\n');
    fprintf('─────────────────────────────────────────────────────────────────────────────────────\n');
    
    fprintf('%-30s | %16.2f±%.2f µA | %16.2f±%.2f µA | %16.2f±%.2f µA\n', ...
            'Equivalent current (10ns gate)', ...
            cloud_metrics(1).current_equivalent*1e6, cloud_metrics(1).current_std*1e6, ...
            cloud_metrics(2).current_equivalent*1e6, cloud_metrics(2).current_std*1e6, ...
            cloud_metrics(3).current_equivalent*1e6, cloud_metrics(3).current_std*1e6);
    
    fprintf('%-30s | [%.2f, %.2f] µA | [%.2f, %.2f] µA | [%.2f, %.2f] µA\n', ...
            '  95% CI', ...
            cloud_metrics(1).current_CI(1)*1e6, cloud_metrics(1).current_CI(2)*1e6, ...
            cloud_metrics(2).current_CI(1)*1e6, cloud_metrics(2).current_CI(2)*1e6, ...
            cloud_metrics(3).current_CI(1)*1e6, cloud_metrics(3).current_CI(2)*1e6);
    
    % Total charge per cloud
    for ipc = 1:3
        Q_total = cloud_metrics(ipc).current_equivalent * 10e-9;  % C (over 10ns)
        Q_total_pC = Q_total * 1e12;  % pC
        fprintf('%-30s | %17.1f pC\n', sprintf('  Cloud %d total charge', ipc), Q_total_pC);
    end
    
    %% SPACE CHARGE FIELD (Lensing Potential)
    fprintf('\n🔬 SPACE CHARGE FIELD (Electric Field Probe):\n');
    fprintf('─────────────────────────────────────────────────────────────────────────────────────\n');
    
    for ipc = 1:3
        if ~isnan(cloud_metrics(ipc).E_sc_slow_cloud)
            fprintf('Cloud %d: E_SC = %.2f ± %.2f kV/m  (95%% CI: [%.2f, %.2f] kV/m)\n', ...
                    ipc, ...
                    cloud_metrics(ipc).E_sc_slow_cloud/1e3, ...
                    cloud_metrics(ipc).E_sc_slow_cloud_std/1e3, ...
                    cloud_metrics(ipc).E_sc_slow_cloud_CI(1)/1e3, ...
                    cloud_metrics(ipc).E_sc_slow_cloud_CI(2)/1e3);
            
            fprintf('         Slow cloud: r_RMS=%.1f mm, z_span=%.1f mm\n', ...
                    cloud_metrics(ipc).slow_cloud_r_rms, ...
                    cloud_metrics(ipc).slow_cloud_z_span);
        else
            fprintf('Cloud %d: Insufficient slow electrons for SC field estimate\n', ipc);
        end
    end
    
    %% ===== TREND ANALYSIS WITH SIGNIFICANCE TESTS =====
    fprintf('\n═════════════════════════════════════════════════════════════════════════════════════\n');
    fprintf('TREND ANALYSIS (Statistical Tests):\n');
    fprintf('═════════════════════════════════════════════════════════════════════════════════════\n\n');
    
    %% Test 1: Is population growth slowing? (Saturation test)
    fprintf('🔍 SATURATION TEST:\n');
    
    % Calculate growth rates with uncertainties
    n1 = cloud_metrics(1).n_total;
    n2 = cloud_metrics(2).n_total;
    n3 = cloud_metrics(3).n_total;
    
    growth_12 = (n2 - n1) / n1 * 100;
    growth_23 = (n3 - n2) / n2 * 100;
    
    % Uncertainty in growth rate (Poisson counting statistics)
    sigma_growth_12 = 100 * sqrt(1/n1 + 1/n2);
    sigma_growth_23 = 100 * sqrt(1/n2 + 1/n3);
    
    fprintf('  Growth rate (Cloud 1→2): %+.1f ± %.1f%%\n', growth_12, sigma_growth_12);
    fprintf('  Growth rate (Cloud 2→3): %+.1f ± %.1f%%\n', growth_23, sigma_growth_23);
    
    % Test if growth rates are significantly different
    delta_growth = growth_23 - growth_12;
    sigma_delta = sqrt(sigma_growth_12^2 + sigma_growth_23^2);
    
    if sigma_delta > 0
        z_score = abs(delta_growth) / sigma_delta;
        fprintf('  Difference: Δ(growth) = %+.1f ± %.1f%%\n', delta_growth, sigma_delta);
        fprintf('  Significance: z = %.2f', z_score);
        
        if z_score > 2.58
            fprintf(' (>99%% confidence)\n');
        elseif z_score > 1.96
            fprintf(' (>95%% confidence)\n');
        else
            fprintf(' (not significant)\n');
        end
        
        if growth_23 < growth_12 && z_score > 1.96
            fprintf('\n  *** SATURATION CONFIRMED (95%% confidence) ***\n');
            fprintf('  → Cloud growth is slowing\n');
            fprintf('  → Equilibrium between creation and loss\n');
            fprintf('  → Four-pulse regime is SAFE\n');
        elseif abs(delta_growth) < sigma_delta
            fprintf('\n  → Growth rates statistically identical\n');
            fprintf('  → Linear accumulation regime\n');
        else
            fprintf('\n  → Growth accelerating (unusual!)\n');
        end
    end
    
    %% Test 2: Is spatial position stable?
    fprintf('\n🎯 SPATIAL STABILITY TEST:\n');
    
    % Axial centroid drift
    z1 = cloud_metrics(1).z_centroid;
    z2 = cloud_metrics(2).z_centroid;
    z3 = cloud_metrics(3).z_centroid;
    
    dz_12 = z2 - z1;
    dz_23 = z3 - z2;
    
    sigma_dz_12 = sqrt(cloud_metrics(1).z_centroid_std^2 + cloud_metrics(2).z_centroid_std^2);
    sigma_dz_23 = sqrt(cloud_metrics(2).z_centroid_std^2 + cloud_metrics(3).z_centroid_std^2);
    
    fprintf('  Axial drift (Cloud 1→2): %+.1f ± %.1f mm', dz_12, sigma_dz_12);
    if abs(dz_12) > 2*sigma_dz_12
        fprintf(' (SIGNIFICANT)\n');
    else
        fprintf(' (within noise)\n');
    end
    
    fprintf('  Axial drift (Cloud 2→3): %+.1f ± %.1f mm', dz_23, sigma_dz_23);
    if abs(dz_23) > 2*sigma_dz_23
        fprintf(' (SIGNIFICANT)\n');
    else
        fprintf(' (within noise)\n');
    end
    
    if abs(dz_12) < 100 && abs(dz_23) < 100
        fprintf('  ✓ Clouds spatially stable (drift < 100mm)\n');
        fprintf('  → Lensing effect predictable and repeatable\n');
    else
        fprintf('  ⚠ Significant cloud migration detected!\n');
        fprintf('  → Lensing position changes between pulses\n');
    end
    
    %% Test 3: Is energy distribution stable?
    fprintf('\n⚡ ENERGY STABILITY TEST:\n');
    
    E1 = cloud_metrics(1).E_mean;
    E2 = cloud_metrics(2).E_mean;
    E3 = cloud_metrics(3).E_mean;
    
    dE_12 = E2 - E1;
    dE_23 = E3 - E2;
    
    sigma_dE_12 = sqrt(cloud_metrics(1).E_mean_std^2 + cloud_metrics(2).E_mean_std^2);
    sigma_dE_23 = sqrt(cloud_metrics(2).E_mean_std^2 + cloud_metrics(3).E_mean_std^2);
    
    fprintf('  Energy shift (Cloud 1→2): %+.3f ± %.3f MeV', dE_12, sigma_dE_12);
    if abs(dE_12) > 2*sigma_dE_12
        fprintf(' (SIGNIFICANT)\n');
    else
        fprintf(' (within noise)\n');
    end
    
    fprintf('  Energy shift (Cloud 2→3): %+.3f ± %.3f MeV', dE_23, sigma_dE_23);
    if abs(dE_23) > 2*sigma_dE_23
        fprintf(' (SIGNIFICANT)\n');
    else
        fprintf(' (within noise)\n');
    end
    
    if abs(dE_12) < 0.010 && abs(dE_23) < 0.010
        fprintf('  ✓ Energy distribution stable (shifts < 10 keV)\n');
    end
    
    %% Test 4: Lensing field comparison
    fprintf('\n🔬 LENSING FIELD COMPARISON:\n');
    
    for ipc = 1:3
        if ~isnan(cloud_metrics(ipc).E_sc_slow_cloud)
            E_sc = cloud_metrics(ipc).E_sc_slow_cloud / 1e3;  % kV/m
            sigma_E_sc = cloud_metrics(ipc).E_sc_slow_cloud_std / 1e3;
            
            fprintf('  Cloud %d: E_SC = %.2f ± %.2f kV/m', ipc, E_sc, sigma_E_sc);
            
            % Compare to beam energy field (1.7 MV/m)
            field_ratio = E_sc / 1700;
            sigma_ratio = sigma_E_sc / 1700;
            
            fprintf(' (%.2e ± %.2e of beam)\n', field_ratio, sigma_ratio);
            
            % Predicted beam deflection with uncertainty
            beam_energy = 1.7e6;  % eV
            deflection_strength = (E_sc*1e3) / beam_energy;
            sigma_deflection = (sigma_E_sc*1e3) / beam_energy;
            
            L_lens = cloud_metrics(ipc).slow_cloud_z_span / 1000;  % m
            %drift_length = 2.700 - cloud_metrics(ipc).z_centroid/1000;  % m to exit
            drift_length = 8.300 - cloud_metrics(ipc).z_centroid/1000;  % m to exit
            
            if L_lens > 0 && drift_length > 0
                delta_r_pred = deflection_strength * L_lens * drift_length * 1000;  % mm
                sigma_delta_r = sigma_deflection * L_lens * drift_length * 1000;
                
                fprintf('         Predicted Δr for P%d: %.2f ± %.2f mm\n', ...
                        ipc+1, delta_r_pred, sigma_delta_r);
            end
        end
    end
    
    %% ===== STATISTICAL COMPARISON: Cloud 2 vs Cloud 3 =====
    fprintf('\n═════════════════════════════════════════════════════════════════════════════════════\n');
    fprintf('KEY COMPARISON: Cloud 2 vs Cloud 3 (Test for Equilibrium)\n');
    fprintf('═════════════════════════════════════════════════════════════════════════════════════\n\n');
    
    % Population difference
    delta_n = n3 - n2;
    sigma_n = sqrt(n2 + n3);  % Poisson uncertainty
    z_n = abs(delta_n) / sigma_n;
    
    fprintf('Population difference:\n');
    fprintf('  Δn = %d ± %d electrons\n', delta_n, round(sigma_n));
    fprintf('  Relative: %.1f%% ± %.1f%%\n', 100*delta_n/n2, 100*sigma_n/n2);
    fprintf('  Significance: z = %.2f', z_n);
    
    if z_n < 1.96
        fprintf(' → NOT SIGNIFICANT\n');
        fprintf('  *** EQUILIBRIUM REACHED: Cloud size saturated ***\n');
    else
        fprintf(' → SIGNIFICANT GROWTH\n');
    end
    
    % Spatial position difference
    delta_z = cloud_metrics(3).z_centroid - cloud_metrics(2).z_centroid;
    sigma_delta_z = sqrt(cloud_metrics(2).z_centroid_std^2 + cloud_metrics(3).z_centroid_std^2);
    
    fprintf('\nCentroid shift:\n');
    fprintf('  Δz = %.1f ± %.1f mm', delta_z, sigma_delta_z);
    
    if abs(delta_z) > 2*sigma_delta_z
        fprintf(' (SIGNIFICANT - cloud migrating!)\n');
    else
        fprintf(' (stable position)\n');
    end
    
    %% ===== SAVE COMPLETE UNCERTAINTY DATA =====
    save('interpulse_cloud_metrics_with_uncertainties.mat', 'cloud_metrics');
    
    %% ===== EXPORT ENHANCED CSV WITH UNCERTAINTIES =====
    fid = fopen('interpulse_cloud_metrics_with_errors.csv', 'w');
    
    % Header
    fprintf(fid, 'Parameter,Cloud_1_Value,Cloud_1_Std,Cloud_1_CI_Low,Cloud_1_CI_High,');
    fprintf(fid, 'Cloud_2_Value,Cloud_2_Std,Cloud_2_CI_Low,Cloud_2_CI_High,');
    fprintf(fid, 'Cloud_3_Value,Cloud_3_Std,Cloud_3_CI_Low,Cloud_3_CI_High,Unit\n');
    
    % Data rows with uncertainties
    fprintf(fid, 'Time,%.1f,0,%.1f,%.1f,%.1f,0,%.1f,%.1f,%.1f,0,%.1f,%.1f,ns\n', ...
            cloud_metrics(1).time_ns, cloud_metrics(1).time_ns, cloud_metrics(1).time_ns, ...
            cloud_metrics(2).time_ns, cloud_metrics(2).time_ns, cloud_metrics(2).time_ns, ...
            cloud_metrics(3).time_ns, cloud_metrics(3).time_ns, cloud_metrics(3).time_ns);
    
    fprintf(fid, 'Total_electrons,%d,%.1f,%d,%d,%d,%.1f,%d,%d,%d,%.1f,%d,%d,count\n', ...
            cloud_metrics(1).n_total, sqrt(cloud_metrics(1).n_total), ...
            round(cloud_metrics(1).n_total - 1.96*sqrt(cloud_metrics(1).n_total)), ...
            round(cloud_metrics(1).n_total + 1.96*sqrt(cloud_metrics(1).n_total)), ...
            cloud_metrics(2).n_total, sqrt(cloud_metrics(2).n_total), ...
            round(cloud_metrics(2).n_total - 1.96*sqrt(cloud_metrics(2).n_total)), ...
            round(cloud_metrics(2).n_total + 1.96*sqrt(cloud_metrics(2).n_total)), ...
            cloud_metrics(3).n_total, sqrt(cloud_metrics(3).n_total), ...
            round(cloud_metrics(3).n_total - 1.96*sqrt(cloud_metrics(3).n_total)), ...
            round(cloud_metrics(3).n_total + 1.96*sqrt(cloud_metrics(3).n_total)));
    
    fprintf(fid, 'Mean_energy,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,MeV\n', ...
            cloud_metrics(1).E_mean, cloud_metrics(1).E_mean_std, ...
            cloud_metrics(1).E_mean_CI(1), cloud_metrics(1).E_mean_CI(2), ...
            cloud_metrics(2).E_mean, cloud_metrics(2).E_mean_std, ...
            cloud_metrics(2).E_mean_CI(1), cloud_metrics(2).E_mean_CI(2), ...
            cloud_metrics(3).E_mean, cloud_metrics(3).E_mean_std, ...
            cloud_metrics(3).E_mean_CI(1), cloud_metrics(3).E_mean_CI(2));
    
    fprintf(fid, 'Z_centroid,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,mm\n', ...
            cloud_metrics(1).z_centroid, cloud_metrics(1).z_centroid_std, ...
            cloud_metrics(1).z_centroid_CI(1), cloud_metrics(1).z_centroid_CI(2), ...
            cloud_metrics(2).z_centroid, cloud_metrics(2).z_centroid_std, ...
            cloud_metrics(2).z_centroid_CI(1), cloud_metrics(2).z_centroid_CI(2), ...
            cloud_metrics(3).z_centroid, cloud_metrics(3).z_centroid_std, ...
            cloud_metrics(3).z_centroid_CI(1), cloud_metrics(3).z_centroid_CI(2));
    
    fprintf(fid, 'R_centroid,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,mm\n', ...
            cloud_metrics(1).r_centroid, cloud_metrics(1).r_centroid_std, ...
            cloud_metrics(1).r_centroid_CI(1), cloud_metrics(1).r_centroid_CI(2), ...
            cloud_metrics(2).r_centroid, cloud_metrics(2).r_centroid_std, ...
            cloud_metrics(2).r_centroid_CI(1), cloud_metrics(2).r_centroid_CI(2), ...
            cloud_metrics(3).r_centroid, cloud_metrics(3).r_centroid_std, ...
            cloud_metrics(3).r_centroid_CI(1), cloud_metrics(3).r_centroid_CI(2));
    
    fprintf(fid, 'Current_equivalent,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,microA\n', ...
            cloud_metrics(1).current_equivalent*1e6, cloud_metrics(1).current_std*1e6, ...
            cloud_metrics(1).current_CI(1)*1e6, cloud_metrics(1).current_CI(2)*1e6, ...
            cloud_metrics(2).current_equivalent*1e6, cloud_metrics(2).current_std*1e6, ...
            cloud_metrics(2).current_CI(1)*1e6, cloud_metrics(2).current_CI(2)*1e6, ...
            cloud_metrics(3).current_equivalent*1e6, cloud_metrics(3).current_std*1e6, ...
            cloud_metrics(3).current_CI(1)*1e6, cloud_metrics(3).current_CI(2)*1e6);
    
    fprintf(fid, 'SC_field_slow_cloud,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f,kV/m\n', ...
            cloud_metrics(1).E_sc_slow_cloud/1e3, cloud_metrics(1).E_sc_slow_cloud_std/1e3, ...
            cloud_metrics(1).E_sc_slow_cloud_CI(1)/1e3, cloud_metrics(1).E_sc_slow_cloud_CI(2)/1e3, ...
            cloud_metrics(2).E_sc_slow_cloud/1e3, cloud_metrics(2).E_sc_slow_cloud_std/1e3, ...
            cloud_metrics(2).E_sc_slow_cloud_CI(1)/1e3, cloud_metrics(2).E_sc_slow_cloud_CI(2)/1e3, ...
            cloud_metrics(3).E_sc_slow_cloud/1e3, cloud_metrics(3).E_sc_slow_cloud_std/1e3, ...
            cloud_metrics(3).E_sc_slow_cloud_CI(1)/1e3, cloud_metrics(3).E_sc_slow_cloud_CI(2)/1e3);
    
    fprintf(fid, 'Slow_electron_fraction,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,%.1f,percent\n', ...
            cloud_metrics(1).frac_slow*100, cloud_metrics(1).frac_slow_std*100, ...
            cloud_metrics(1).frac_slow_CI(1)*100, cloud_metrics(1).frac_slow_CI(2)*100, ...
            cloud_metrics(2).frac_slow*100, cloud_metrics(2).frac_slow_std*100, ...
            cloud_metrics(2).frac_slow_CI(1)*100, cloud_metrics(2).frac_slow_CI(2)*100, ...
            cloud_metrics(3).frac_slow*100, cloud_metrics(3).frac_slow_std*100, ...
            cloud_metrics(3).frac_slow_CI(1)*100, cloud_metrics(3).frac_slow_CI(2)*100);
    
    fclose(fid);
    
    fprintf('\n✓ Metrics with uncertainties saved to interpulse_cloud_metrics_with_uncertainties.mat\n');
    fprintf('✓ CSV with error bars exported to interpulse_cloud_metrics_with_errors.csv\n');
    
    %% ===== CREATE ERROR BAR VISUALIZATION =====
    figure('Position', [100, 100, 1800, 1200], ...
           'Name', 'Inter-Pulse Cloud Metrics with Uncertainties');
    
    %% Plot 1: Population with Poisson error bars
    subplot(3,3,1);
    n_tots = [cloud_metrics.n_total];
    n_errs = sqrt(n_tots);  % Poisson uncertainty
    
    errorbar(1:3, n_tots, n_errs, 'bo-', 'LineWidth', 3, 'MarkerSize', 14, ...
             'CapSize', 12, 'MarkerFaceColor', 'b');
    
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('Total Electrons', 'FontSize', 13);
    title('Population ± Poisson Error', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTick', 1:3);
    
    % Add growth rate annotation with significance
    text(0.55, 0.9, sprintf('Growth 1→2: %+.1f±%.1f%%', growth_12, sigma_growth_12), ...
         'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
    text(0.55, 0.82, sprintf('Growth 2→3: %+.1f±%.1f%%', growth_23, sigma_growth_23), ...
         'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
    
    if z_score > 1.96
        text(0.55, 0.74, '✓ Difference significant', 'Units', 'normalized', ...
             'FontSize', 9, 'Color', 'red', 'FontWeight', 'bold');
    end
    
    %% Plot 2: Mean energy with bootstrap error bars
    subplot(3,3,2);
    E_means = [cloud_metrics.E_mean];
    E_stds = [cloud_metrics.E_mean_std];
    
    errorbar(1:3, E_means, E_stds, 'go-', 'LineWidth', 3, 'MarkerSize', 14, ...
             'CapSize', 12, 'MarkerFaceColor', 'g');
    
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('Mean Energy (MeV)', 'FontSize', 13);
    title('Energy ± Bootstrap StdDev', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTick', 1:3);
    ylim([0 1.0]);
    
    % Show if energy shifts are significant
    fprintf('Energy shift significance:\n');
    z_E_12 = abs(dE_12) / sigma_dE_12;
    z_E_23 = abs(dE_23) / sigma_dE_23;
    
    text(0.55, 0.9, sprintf('ΔE(1→2): %+.3f±%.3f MeV', dE_12, sigma_dE_12), ...
         'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
    text(0.55, 0.82, sprintf('z = %.2f', z_E_12), ...
         'Units', 'normalized', 'FontSize', 10);
    
    %% Plot 3: Slow fraction with confidence intervals
    subplot(3,3,3);
    slow_fracs = [cloud_metrics.frac_slow] * 100;
    slow_stds = [cloud_metrics.frac_slow_std] * 100;
    
    errorbar(1:3, slow_fracs, slow_stds, 'ro-', 'LineWidth', 3, 'MarkerSize', 14, ...
             'CapSize', 12, 'MarkerFaceColor', 'r');
    
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('Slow e⁻ Fraction (%)', 'FontSize', 13);
    title('Slow Electron Content ± Bootstrap Error', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTick', 1:3);
    ylim([0 60]);
    
    % Add 95% CI shading
    for ipc = 1:3
        CI = cloud_metrics(ipc).frac_slow_CI * 100;
        patch([ipc ipc ipc ipc], [CI(1) CI(2) CI(2) CI(1)], ...
              'red', 'FaceAlpha', 0.1, 'EdgeColor', 'none');
    end
    
    %% Plot 4: Axial centroid with error bars
    subplot(3,3,4);
    z_cents = [cloud_metrics.z_centroid];
    z_stds = [cloud_metrics.z_centroid_std];
    
    errorbar(1:3, z_cents, z_stds, 'bo-', 'LineWidth', 3, 'MarkerSize', 14, ...
             'CapSize', 12, 'MarkerFaceColor', 'b');
    
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('Axial Centroid z (mm)', 'FontSize', 13);
    title('Cloud Position ± Bootstrap Error', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTick', 1:3);
    ylim([0 8310]);
    
    % Show if centroid shifts are significant
    text(0.55, 0.9, sprintf('Δz(1→2): %+.0f±%.0f mm', dz_12, sigma_dz_12), ...
         'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
    text(0.55, 0.82, sprintf('Δz(2→3): %+.0f±%.0f mm', dz_23, sigma_dz_23), ...
         'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
    
    if abs(dz_12) < 2*sigma_dz_12 && abs(dz_23) < 2*sigma_dz_23
        text(0.55, 0.74, '✓ Position stable', 'Units', 'normalized', ...
             'FontSize', 9, 'Color', 'green', 'FontWeight', 'bold');
    end
    
    %% Plot 5: Radial centroid with error bars
    subplot(3,3,5);
    r_cents = [cloud_metrics.r_centroid];
    r_stds = [cloud_metrics.r_centroid_std];
    
    errorbar(1:3, r_cents, r_stds, 'mo-', 'LineWidth', 3, 'MarkerSize', 14, ...
             'CapSize', 12, 'MarkerFaceColor', 'm');
    
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('Radial Centroid r (mm)', 'FontSize', 13);
    title('Radial Position ± Bootstrap Error', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTick', 1:3);
    ylim([0 80]);
    
    % Reference line at beam target
    yline(50, 'k--', 'LineWidth', 2, 'Label', 'Beam target');
    
    %% Plot 6: Equivalent current with measurement error bars
    subplot(3,3,6);
    currents = [cloud_metrics.current_equivalent] * 1e6;  % µA
    current_stds = [cloud_metrics.current_std] * 1e6;
    
    errorbar(1:3, currents, current_stds, 'go-', 'LineWidth', 3, 'MarkerSize', 14, ...
             'CapSize', 12, 'MarkerFaceColor', 'g');
    
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('Equivalent Current (µA)', 'FontSize', 13);
    title('Inter-Pulse Current ± Counting Error', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTick', 1:3);
    
    % Add detector threshold and precision requirement
    yline(0.1, 'r--', 'LineWidth', 2, 'Label', 'Typical threshold');
    
    % Calculate required detector precision
    min_signal = min(currents - 1.96*current_stds);
    text(0.55, 0.9, sprintf('Min signal: %.2f µA', min_signal), ...
         'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'white');
    text(0.55, 0.82, sprintf('Required precision: <%.3f µA', max(current_stds)), ...
         'Units', 'normalized', 'FontSize', 10, 'BackgroundColor', 'yellow');
    
    %% Plot 7: SC field with propagated uncertainties
    subplot(3,3,7);
    
    sc_fields = zeros(3,1);
    sc_stds = zeros(3,1);
    
    for ipc = 1:3
        if ~isnan(cloud_metrics(ipc).E_sc_slow_cloud)
            sc_fields(ipc) = cloud_metrics(ipc).E_sc_slow_cloud / 1e3;  % kV/m
            sc_stds(ipc) = cloud_metrics(ipc).E_sc_slow_cloud_std / 1e3;
        else
            sc_fields(ipc) = 0;
            sc_stds(ipc) = 0;
        end
    end
    
    errorbar(1:3, sc_fields, sc_stds, 'mo-', 'LineWidth', 3, 'MarkerSize', 14, ...
             'CapSize', 12, 'MarkerFaceColor', 'm');
    
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('SC Field (kV/m)', 'FontSize', 13);
    title('Lensing Field ± Propagated Error', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTick', 1:3);
    
    % Compare to beam energy
    beam_E_field = 1700;  % kV/m equivalent
    yline(beam_E_field, 'r--', 'LineWidth', 2, 'Label', 'Beam energy field');
    
    %% Plot 8: Confidence intervals visualization
    subplot(3,3,8);
    hold on;
    
    % Plot current with shaded CI regions
    for ipc = 1:3
        CI = cloud_metrics(ipc).current_CI * 1e6;  % µA
        
        % Shaded confidence region
        patch([ipc-0.2 ipc+0.2 ipc+0.2 ipc-0.2], ...
              [CI(1) CI(1) CI(2) CI(2)], ...
              'blue', 'FaceAlpha', 0.2, 'EdgeColor', 'b', 'LineWidth', 1.5);
        
        % Central value
        plot(ipc, currents(ipc), 'bo', 'MarkerSize', 12, 'LineWidth', 2, ...
             'MarkerFaceColor', 'b');
    end
    
    xlabel('Cloud Number', 'FontSize', 13);
    ylabel('Current (µA)', 'FontSize', 13);
    title('95% Confidence Intervals', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    set(gca, 'XTick', 1:3);
    xlim([0.5 3.5]);
    
    % Test if clouds are statistically different
    fprintf('\n95%% Confidence Interval Tests:\n');
    
    % Cloud 1 vs Cloud 2
    CI1 = cloud_metrics(1).current_CI * 1e6;
    CI2 = cloud_metrics(2).current_CI * 1e6;
    
    if CI1(2) < CI2(1) || CI2(2) < CI1(1)
        fprintf('  Cloud 1 vs 2: SIGNIFICANTLY DIFFERENT (non-overlapping CIs)\n');
        text(1.5, mean([currents(1) currents(2)]), '✗', 'FontSize', 20, ...
             'Color', 'red', 'HorizontalAlignment', 'center');
    else
        fprintf('  Cloud 1 vs 2: Not significantly different (overlapping CIs)\n');
        text(1.5, mean([currents(1) currents(2)]), '✓', 'FontSize', 20, ...
             'Color', 'green', 'HorizontalAlignment', 'center');
    end
    
    % Cloud 2 vs Cloud 3
    CI3 = cloud_metrics(3).current_CI * 1e6;
    
    if CI2(2) < CI3(1) || CI3(2) < CI2(1)
        fprintf('  Cloud 2 vs 3: SIGNIFICANTLY DIFFERENT\n');
        text(2.5, mean([currents(2) currents(3)]), '✗', 'FontSize', 20, ...
             'Color', 'red', 'HorizontalAlignment', 'center');
    else
        fprintf('  Cloud 2 vs 3: Not significantly different → SATURATION!\n');
        text(2.5, mean([currents(2) currents(3)]), '✓', 'FontSize', 20, ...
             'Color', 'green', 'HorizontalAlignment', 'center');
    end
    
    %% Plot 9: Measurement precision requirements
    subplot(3,3,9);
    axis off;
    
    text(0.5, 0.95, 'DETECTOR REQUIREMENTS', 'FontWeight', 'bold', 'FontSize', 15, ...
         'HorizontalAlignment', 'center', 'Color', [0.7 0 0]);
    text(0.5, 0.88, '(Based on Model Uncertainties)', 'FontSize', 12, ...
         'HorizontalAlignment', 'center');
    
    y_pos = 0.75;
    
    % Required measurement precision
    text(0.05, y_pos, '1. Current Monitor:', 'FontWeight', 'bold', 'FontSize', 12);
    y_pos = y_pos - 0.06;
    text(0.10, y_pos, sprintf('   Precision required: <%.3f µA', max(current_stds)), 'FontSize', 11);
    y_pos = y_pos - 0.05;
    text(0.10, y_pos, sprintf('   Signal range: %.2f-%.2f µA', min(currents), max(currents)), ...
         'FontSize', 11);
    y_pos = y_pos - 0.05;
    text(0.10, y_pos, sprintf('   SNR required: >%.0f:1', max(currents)/max(current_stds)), ...
         'FontSize', 11, 'Color', 'red');
    y_pos = y_pos - 0.08;
    
    text(0.05, y_pos, '2. BPM Resolution:', 'FontWeight', 'bold', 'FontSize', 12);
    y_pos = y_pos - 0.06;
    text(0.10, y_pos, sprintf('   Position precision: <%.1f mm', max([cloud_metrics.z_centroid_std])), ...
         'FontSize', 11);
    y_pos = y_pos - 0.05;
    text(0.10, y_pos, sprintf('   To resolve drift: <%.0f mm', sigma_dz_23), ...
         'FontSize', 11, 'Color', 'red');
    y_pos = y_pos - 0.08;
    
    text(0.05, y_pos, '3. Energy Spectrometer:', 'FontWeight', 'bold', 'FontSize', 12);
    y_pos = y_pos - 0.06;
    text(0.10, y_pos, sprintf('   Energy resolution: <%.1f keV', max(E_stds)*1000), ...
         'FontSize', 11);
    y_pos = y_pos - 0.05;
    text(0.10, y_pos, '   Must distinguish: 0.1-1.0 MeV range', 'FontSize', 11);
    y_pos = y_pos - 0.08;
    
    text(0.05, y_pos, '4. Beam Size Monitor:', 'FontWeight', 'bold', 'FontSize', 12);
    y_pos = y_pos - 0.06;
    
    % Calculate required precision to see P3-P4 difference
    if exist('twiss_p3_averaged', 'var') && exist('twiss_p4_averaged', 'var')
        r_p3 = twiss_p3_averaged(end).r_rms_mean;
        r_p4 = twiss_p4_averaged(end).r_rms_mean;
        delta_r_p4_p3 = abs(r_p4 - r_p3);
        
        text(0.10, y_pos, sprintf('   To see P4-P3 change: <%.2f mm', delta_r_p4_p3/3), ...
             'FontSize', 11, 'Color', 'red');
    else
        text(0.10, y_pos, '   Position res: <0.5 mm', 'FontSize', 11);
    end
    
    sgtitle('Cloud Metrics with Statistical Uncertainties (95% Confidence)', ...
            'FontSize', 18, 'FontWeight', 'bold');
    
    % Save figure
    saveas(gcf, 'Test70_Cloud_Metrics_With_Uncertainties.fig');
    saveas(gcf, 'Test70_Cloud_Metrics_With_Uncertainties.png');
    
    fprintf('\n✓ Uncertainty analysis complete!\n');
end

%%%%%%%%%%%%%%%%%%%%%%% Updated STEP 4  01.26.2026  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== BETATRON-AVERAGED TWISS: PULSE 1 (WORKS IN ALL MODES) =============
%% ========================================================================
%  BETATRON-AVERAGED TWISS PARAMETER ANALYSIS
%% ========================================================================
if ENABLE_MULTIPULSE == true && ENABLE_BETATRON_AVERAGING == true && snapshot_p1_count == N_SNAPSHOTS % Commented out  
    
    fprintf('\n=== BETATRON-AVERAGED TWISS ANALYSIS - PULSE 1 ===\n');
    fprintf('Processing %d snapshots...\n', N_SNAPSHOTS);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % Define analysis planes
    %analysis_locations = [254, 600, 1000, 1700, 2700];
    %location_names = {'Anode', 'Trans1', 'Trans2', 'Trans3', 'Exit'};
    %n_locations = length(analysis_locations);
%%%%%%%%%%%%%%%%%%%%%%% Updated Twiss Analysis Locations 02.13.2026 %%%%%%%%%%%%%%%
    % Extended to cover key solenoid centers and BPMs
twiss_locations = [254;    % Anode (after gap acceleration)
                   600;    % Early drift (near Sol 3-4)
                   1000;   % Mid drift region 1 (near Sol 7-8)
                   1500;   % Between Sol 9-10
                   1700;   % Legacy diagnostic
                   2200;   % Near Sol 14-15
                   2700;   % BPM1 region (near Sol 19-20)
                   3400;   % Mid-extension (near Sol 25)
                   3964;   % BPM2 (experimental)
                   4600;   % Mid-extension 2 (near Sol 35)
                   5400;   % Near Sol 45
                   6402;   % BPM3 (experimental)
                   6828;   % BPM4 (experimental)
                   7450;   % Near final solenoid (Sol 49)
                   8305];  % BPM5 / Final exit

analysis_locations = twiss_locations;
location_names = {'Anode', 'Early_Drift', 'Mid_Drift1', 'Trans1', 'Trans2', ...
                  'Mid_Drift2', 'BPM1', 'Extension1', 'BPM2', 'Extension2', ...
                  'Late_Drift', 'BPM3', 'BPM4', 'Sol49', 'Exit'};

n_twiss_planes = length(twiss_locations);

fprintf('=== Twiss Analysis Configuration ===\n');
fprintf('  Number of analysis planes: %d (expanded from 5)\n', n_twiss_planes);
fprintf('  Axial coverage: %.0f mm to %.0f mm\n', ...
        twiss_locations(1), twiss_locations(end));
fprintf('  Average spacing: %.0f mm\n', mean(diff(twiss_locations)));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    twiss_p1_instantaneous = struct();
    twiss_p1_averaged = struct();
    
    %% Process all Pulse 1 snapshots
    for is = 1:N_SNAPSHOTS
        beam_data = snapshot_p1{is};
        

        % [... Keep your existing Pulse 1 analysis code here ...]
        for iloc = 1:n_locations
            z_target = analysis_locations(iloc) / 1000;  % Convert to meters
            
            % Select particles near this location
            selection_window = 0.015;  % ±15mm
            in_plane = abs(beam_data.z - z_target) < selection_window;
            n_selected = sum(in_plane);
            
            if n_selected >= 100
                % Extract coordinates
                r_sel = beam_data.r(in_plane);
                pr_sel = beam_data.pr(in_plane);
                pz_sel = beam_data.pz(in_plane);
                gamma_sel = beam_data.gamma(in_plane);
                
                % Normalized transverse momentum
                pr_norm = pr_sel ./ (gamma_sel * m_e * c);
                
                % Center distributions
                r_mean = mean(r_sel);
                pr_mean = mean(pr_norm);
                r_c = r_sel - r_mean;
                pr_c = pr_norm - pr_mean;
                
                % Second moments
                r2 = mean(r_c.^2);
                pr2 = mean(pr_c.^2);
                r_pr = mean(r_c .* pr_c);
                
                % Emittance
                emit_rms = sqrt(r2 * pr2 - r_pr^2);
                
                if emit_rms > 1e-10
                    % Twiss parameters
                    beta = r2 / emit_rms;
                    gamma_twiss = pr2 / emit_rms;
                    alpha = -r_pr / emit_rms;
                    
                    % Normalized emittance
                    gamma_avg = mean(gamma_sel);
                    beta_rel = sqrt(1 - 1/gamma_avg^2);
                    emit_norm = emit_rms * gamma_avg * beta_rel;
                    
                    % Store instantaneous values
                    twiss_p1_instantaneous(iloc,is).beta = beta;
                    twiss_p1_instantaneous(iloc,is).alpha = alpha;
                    twiss_p1_instantaneous(iloc,is).gamma = gamma_twiss;
                    twiss_p1_instantaneous(iloc,is).emit_norm = emit_norm * 1e6;  % mm-mrad
                    twiss_p1_instantaneous(iloc,is).r_rms = sqrt(r2) * 1000;  % mm
                    twiss_p1_instantaneous(iloc,is).n_particles = n_selected;
                    twiss_p1_instantaneous(iloc,is).time = beam_data.time;
                else
                    twiss_p1_instantaneous(iloc,is).beta = NaN;
                    twiss_p1_instantaneous(iloc,is).alpha = NaN;
                    twiss_p1_instantaneous(iloc,is).gamma = NaN;
                    twiss_p1_instantaneous(iloc,is).emit_norm = NaN;
                    twiss_p1_instantaneous(iloc,is).r_rms = NaN;
                end
            else
                % Insufficient particles
                twiss_p1_instantaneous(iloc,is).beta = NaN;
                twiss_p1_instantaneous(iloc,is).alpha = NaN;
                twiss_p1_instantaneous(iloc,is).gamma = NaN;
                twiss_p1_instantaneous(iloc,is).emit_norm = NaN;
                twiss_p1_instantaneous(iloc,is).r_rms = NaN;
            end
        end
    
    %% Compute phase-averaged Pulse 1 parameters
    for iloc = 1:n_locations
        beta_p1_all = [twiss_p1_instantaneous(iloc,:).beta];
        alpha_p1_all = [twiss_p1_instantaneous(iloc,:).alpha];
        gamma_p1_all = [twiss_p1_instantaneous(iloc,:).gamma];
        emit_p1_all = [twiss_p1_instantaneous(iloc,:).emit_norm];
        r_rms_p1_all = [twiss_p1_instantaneous(iloc,:).r_rms];
        
        valid_p1 = ~isnan(beta_p1_all);
        
        if sum(valid_p1) >= 3
            twiss_p1_averaged(iloc).location = location_names{iloc};
            twiss_p1_averaged(iloc).z_mm = analysis_locations(iloc);
            twiss_p1_averaged(iloc).beta_mean = mean(beta_p1_all(valid_p1));
            twiss_p1_averaged(iloc).beta_std = std(beta_p1_all(valid_p1));
            twiss_p1_averaged(iloc).alpha_mean = mean(alpha_p1_all(valid_p1));
            twiss_p1_averaged(iloc).alpha_std = std(alpha_p1_all(valid_p1));
            twiss_p1_averaged(iloc).gamma_mean = mean(gamma_p1_all(valid_p1));
            twiss_p1_averaged(iloc).gamma_std = std(gamma_p1_all(valid_p1));
            twiss_p1_averaged(iloc).emit_mean = mean(emit_p1_all(valid_p1));
            twiss_p1_averaged(iloc).emit_std = std(emit_p1_all(valid_p1));
            twiss_p1_averaged(iloc).r_rms_mean = mean(r_rms_p1_all(valid_p1));
            twiss_p1_averaged(iloc).r_rms_std = std(r_rms_p1_all(valid_p1));
            twiss_p1_averaged(iloc).n_snapshots = sum(valid_p1);
            
            if twiss_p1_averaged(iloc).alpha_mean > 0.1
                twiss_p1_averaged(iloc).condition = 'Converging';
            elseif twiss_p1_averaged(iloc).alpha_mean < -0.1
                twiss_p1_averaged(iloc).condition = 'Diverging';
            else
                twiss_p1_averaged(iloc).condition = 'Collimated';
            end
            
            fprintf('\n%s (z=%d mm) - PULSE 1:\n', location_names{iloc}, analysis_locations(iloc));
            fprintf('  β = %.3f ± %.3f m\n', ...
                    twiss_p1_averaged(iloc).beta_mean, twiss_p1_averaged(iloc).beta_std);
            fprintf('  α = %.3f ± %.3f (%s)\n', ...
                    twiss_p1_averaged(iloc).alpha_mean, twiss_p1_averaged(iloc).alpha_std, ...
                    twiss_p1_averaged(iloc).condition);
            fprintf('  r_rms = %.2f ± %.2f mm\n', ...
                    twiss_p1_averaged(iloc).r_rms_mean, twiss_p1_averaged(iloc).r_rms_std);
             end
           end    
         end  % End Pulse 1 analysis
     
end
%% ==================== BETATRON-AVERAGED TWISS: PULSE 2 (MULTI-PULSE ONLY) ====================
       if ENABLE_MULTIPULSE == true && ENABLE_BETATRON_AVERAGING == true && ...
        snapshot_p2_count == N_SNAPSHOTS
    
    fprintf('\n=== BETATRON-AVERAGED TWISS ANALYSIS - PULSE 2 ===\n');
    fprintf('Processing %d snapshots...\n', N_SNAPSHOTS);
    
    % Use same analysis_locations and location_names from above
    twiss_p2_instantaneous = struct();
    twiss_p2_averaged = struct();
    
    %% Process all Pulse 2 snapshots
    for is = 1:N_SNAPSHOTS
        beam_data = snapshot_p2{is};
        
        for iloc = 1:n_locations
            % [... Keep your existing Pulse 2 analysis code ...]
         for iloc = 1:n_locations
            z_target = analysis_locations(iloc) / 1000;
            
            selection_window = 0.015;
            in_plane = abs(beam_data.z - z_target) < selection_window;
            n_selected = sum(in_plane);
            
            if n_selected >= 100
                r_sel = beam_data.r(in_plane);
                pr_sel = beam_data.pr(in_plane);
                pz_sel = beam_data.pz(in_plane);
                gamma_sel = beam_data.gamma(in_plane);
                
                pr_norm = pr_sel ./ (gamma_sel * m_e * c);
                
                r_mean = mean(r_sel);
                pr_mean = mean(pr_norm);
                r_c = r_sel - r_mean;
                pr_c = pr_norm - pr_mean;
                
                r2 = mean(r_c.^2);
                pr2 = mean(pr_c.^2);
                r_pr = mean(r_c .* pr_c);
                
                emit_rms = sqrt(r2 * pr2 - r_pr^2);
                
                if emit_rms > 1e-10
                    beta = r2 / emit_rms;
                    gamma_twiss = pr2 / emit_rms;
                    alpha = -r_pr / emit_rms;
                    
                    gamma_avg = mean(gamma_sel);
                    beta_rel = sqrt(1 - 1/gamma_avg^2);
                    emit_norm = emit_rms * gamma_avg * beta_rel;
                    
                    twiss_p2_instantaneous(iloc,is).beta = beta;
                    twiss_p2_instantaneous(iloc,is).alpha = alpha;
                    twiss_p2_instantaneous(iloc,is).gamma = gamma_twiss;
                    twiss_p2_instantaneous(iloc,is).emit_norm = emit_norm * 1e6;
                    twiss_p2_instantaneous(iloc,is).r_rms = sqrt(r2) * 1000;
                    twiss_p2_instantaneous(iloc,is).n_particles = n_selected;
                    twiss_p2_instantaneous(iloc,is).time = beam_data.time;
                else
                    twiss_p2_instantaneous(iloc,is).beta = NaN;
                    twiss_p2_instantaneous(iloc,is).alpha = NaN;
                    twiss_p2_instantaneous(iloc,is).gamma = NaN;
                    twiss_p2_instantaneous(iloc,is).emit_norm = NaN;
                    twiss_p2_instantaneous(iloc,is).r_rms = NaN;
                end
            else
                twiss_p2_instantaneous(iloc,is).beta = NaN;
                twiss_p2_instantaneous(iloc,is).alpha = NaN;
                twiss_p2_instantaneous(iloc,is).gamma = NaN;
                twiss_p2_instantaneous(iloc,is).emit_norm = NaN;
                twiss_p2_instantaneous(iloc,is).r_rms = NaN;
            end
          end
        end
      end 
                     
        % [... Same averaging logic as Pulse 1 ...]
        for iloc = 1:n_locations
        % Extract all instantaneous values for this location
        beta_p2_all = [twiss_p2_instantaneous(iloc,:).beta];
        alpha_p2_all = [twiss_p2_instantaneous(iloc,:).alpha];
        gamma_p2_all = [twiss_p2_instantaneous(iloc,:).gamma];
        emit_p2_all = [twiss_p2_instantaneous(iloc,:).emit_norm];
        r_rms_p2_all = [twiss_p2_instantaneous(iloc,:).r_rms];
        
        % Remove NaN values
        valid_p2 = ~isnan(beta_p2_all);
                   
            % PULSE 2 AVERAGED
            twiss_p2_averaged(iloc).location = location_names{iloc};
            twiss_p2_averaged(iloc).z_mm = analysis_locations(iloc);
            twiss_p2_averaged(iloc).beta_mean = mean(beta_p2_all(valid_p2));
            twiss_p2_averaged(iloc).beta_std = std(beta_p2_all(valid_p2));
            twiss_p2_averaged(iloc).alpha_mean = mean(alpha_p2_all(valid_p2));
            twiss_p2_averaged(iloc).alpha_std = std(alpha_p2_all(valid_p2));
            twiss_p2_averaged(iloc).gamma_mean = mean(gamma_p2_all(valid_p2));
            twiss_p2_averaged(iloc).gamma_std = std(gamma_p2_all(valid_p2));
            twiss_p2_averaged(iloc).emit_mean = mean(emit_p2_all(valid_p2));
            twiss_p2_averaged(iloc).emit_std = std(emit_p2_all(valid_p2));
            twiss_p2_averaged(iloc).r_rms_mean = mean(r_rms_p2_all(valid_p2));
            twiss_p2_averaged(iloc).r_rms_std = std(r_rms_p2_all(valid_p2));
            twiss_p2_averaged(iloc).n_snapshots = sum(valid_p2);
            
            % Beam condition from averaged alpha
            
            if twiss_p2_averaged(iloc).alpha_mean > 0.1
                twiss_p2_averaged(iloc).condition = 'Converging';
            elseif twiss_p2_averaged(iloc).alpha_mean < -0.1
                twiss_p2_averaged(iloc).condition = 'Diverging';
            else
                twiss_p2_averaged(iloc).condition = 'Collimated';
            end
                 
            % Print results
            fprintf('\n%s (z=%d mm):\n', location_names{iloc}, analysis_locations(iloc));
            fprintf('  PULSE 1 (averaged over %d snapshots):\n', sum(valid_p1));
            fprintf('    β = %.3f ± %.3f m\n', ...
                    twiss_p1_averaged(iloc).beta_mean, twiss_p1_averaged(iloc).beta_std);
            fprintf('    α = %.3f ± %.3f (%s)\n', ...
                    twiss_p1_averaged(iloc).alpha_mean, twiss_p1_averaged(iloc).alpha_std, ...
                    twiss_p1_averaged(iloc).condition);
            fprintf('    γ = %.3f ± %.3f 1/m\n', ...
                    twiss_p1_averaged(iloc).gamma_mean, twiss_p1_averaged(iloc).gamma_std);
            fprintf('    r_rms = %.2f ± %.2f mm\n', ...
                    twiss_p1_averaged(iloc).r_rms_mean, twiss_p1_averaged(iloc).r_rms_std);
            
            fprintf('  PULSE 2 (averaged over %d snapshots):\n', sum(valid_p2));
            fprintf('    β = %.3f ± %.3f m\n', ...
                    twiss_p2_averaged(iloc).beta_mean, twiss_p2_averaged(iloc).beta_std);
            fprintf('    α = %.3f ± %.3f (%s)\n', ...
                    twiss_p2_averaged(iloc).alpha_mean, twiss_p2_averaged(iloc).alpha_std, ...
                    twiss_p2_averaged(iloc).condition);
            fprintf('    γ = %.3f ± %.3f 1/m\n', ...
                    twiss_p2_averaged(iloc).gamma_mean, twiss_p2_averaged(iloc).gamma_std);
            fprintf('    r_rms = %.2f ± %.2f mm\n', ...
                    twiss_p2_averaged(iloc).r_rms_mean, twiss_p2_averaged(iloc).r_rms_std);
            
            % Calculate differences
            delta_beta = twiss_p2_averaged(iloc).beta_mean - twiss_p1_averaged(iloc).beta_mean;
            delta_alpha = twiss_p2_averaged(iloc).alpha_mean - twiss_p1_averaged(iloc).alpha_mean;
            delta_r = twiss_p2_averaged(iloc).r_rms_mean - twiss_p1_averaged(iloc).r_rms_mean;
            
            fprintf('  DIFFERENCE (P2 - P1):\n');
            fprintf('    Δβ = %.3f m (%.1f%%)\n', delta_beta, ...
                    100*delta_beta/twiss_p1_averaged(iloc).beta_mean);
            fprintf('    Δα = %.3f\n', delta_alpha);
            fprintf('    Δr_rms = %.3f mm (%.1f%%)\n', delta_r, ...
                    100*delta_r/twiss_p1_averaged(iloc).r_rms_mean);
        end
     end
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Added Betatron Averaging TWISS Pulse 3 %%%%%%%%%%%%%%%%%
%% ==================== BETATRON-AVERAGED TWISS: PULSE 3 ====================
if ENABLE_MULTIPULSE == true && ENABLE_BETATRON_AVERAGING == true && ...
        snapshot_p3_count == N_SNAPSHOTS
    
    fprintf('\n=== BETATRON-AVERAGED TWISS ANALYSIS - PULSE 3 ===\n');
    
    % Use same analysis_locations as P1 and P2
    twiss_p3_instantaneous = struct();
    twiss_p3_averaged = struct();
    
    % Process all Pulse 3 snapshots (same code structure as P2)
    for is = 1:N_SNAPSHOTS
        beam_data = snapshot_p3{is};
        
        for iloc = 1:n_locations
            z_target = analysis_locations(iloc) / 1000;
            selection_window = 0.015;
            in_plane = abs(beam_data.z - z_target) < selection_window;
            n_selected = sum(in_plane);
            
            if n_selected >= 100
                % [Same Twiss calculation as P2 - extract and calculate]
                r_sel = beam_data.r(in_plane);
                pr_sel = beam_data.pr(in_plane);
                gamma_sel = beam_data.gamma(in_plane);
                
                pr_norm = pr_sel ./ (gamma_sel * m_e * c);
                r_c = r_sel - mean(r_sel);
                pr_c = pr_norm - mean(pr_norm);
                
                r2 = mean(r_c.^2);
                pr2 = mean(pr_c.^2);
                r_pr = mean(r_c .* pr_c);
                
                emit_rms = sqrt(r2 * pr2 - r_pr^2);
                
                if emit_rms > 1e-10
                    beta = r2 / emit_rms;
                    gamma_twiss = pr2 / emit_rms;
                    alpha = -r_pr / emit_rms;
                    
                    gamma_avg = mean(gamma_sel);
                    beta_rel = sqrt(1 - 1/gamma_avg^2);
                    emit_norm = emit_rms * gamma_avg * beta_rel;
                    
                    twiss_p3_instantaneous(iloc,is).beta = beta;
                    twiss_p3_instantaneous(iloc,is).alpha = alpha;
                    twiss_p3_instantaneous(iloc,is).gamma = gamma_twiss;
                    twiss_p3_instantaneous(iloc,is).emit_norm = emit_norm * 1e6;
                    twiss_p3_instantaneous(iloc,is).r_rms = sqrt(r2) * 1000;
                    twiss_p3_instantaneous(iloc,is).n_particles = n_selected;
                     % CRITICAL: Include this line to fix the bug for P3:
                    twiss_p3_instantaneous(iloc,is).time = beam_data.time;
                else
                    twiss_p3_instantaneous(iloc,is).beta = NaN;
                    twiss_p3_instantaneous(iloc,is).alpha = NaN;
                    twiss_p3_instantaneous(iloc,is).gamma = NaN;
                    twiss_p3_instantaneous(iloc,is).emit_norm = NaN;
                    twiss_p3_instantaneous(iloc,is).r_rms = NaN;
                end
            else
                twiss_p3_instantaneous(iloc,is).beta = NaN;
                twiss_p3_instantaneous(iloc,is).alpha = NaN;
                twiss_p3_instantaneous(iloc,is).gamma = NaN;
                twiss_p3_instantaneous(iloc,is).emit_norm = NaN;
                twiss_p3_instantaneous(iloc,is).r_rms = NaN;
            end
        end
    end
    
    % Compute averaged parameters
    for iloc = 1:n_locations
        beta_p3_all = [twiss_p3_instantaneous(iloc,:).beta];
        alpha_p3_all = [twiss_p3_instantaneous(iloc,:).alpha];
        emit_p3_all = [twiss_p3_instantaneous(iloc,:).emit_norm];
        r_rms_p3_all = [twiss_p3_instantaneous(iloc,:).r_rms];
        
        valid_p3 = ~isnan(beta_p3_all);
        
        if sum(valid_p3) >= 3
            twiss_p3_averaged(iloc).location = location_names{iloc};
            twiss_p3_averaged(iloc).z_mm = analysis_locations(iloc);
            twiss_p3_averaged(iloc).beta_mean = mean(beta_p3_all(valid_p3));
            twiss_p3_averaged(iloc).beta_std = std(beta_p3_all(valid_p3));
            twiss_p3_averaged(iloc).alpha_mean = mean(alpha_p3_all(valid_p3));
            twiss_p3_averaged(iloc).alpha_std = std(alpha_p3_all(valid_p3));
            twiss_p3_averaged(iloc).r_rms_mean = mean(r_rms_p3_all(valid_p3));
            twiss_p3_averaged(iloc).r_rms_std = std(r_rms_p3_all(valid_p3));
            twiss_p3_averaged(iloc).emit_mean = mean(emit_p3_all(valid_p3));
            twiss_p3_averaged(iloc).emit_std = std(emit_p3_all(valid_p3));
            twiss_p3_averaged(iloc).n_snapshots = sum(valid_p3);
            
            fprintf('\n%s: β=%.3f±%.3f m, α=%.3f±%.3f, r=%.2f±%.2f mm\n', ...
                    location_names{iloc}, ...
                    twiss_p3_averaged(iloc).beta_mean, twiss_p3_averaged(iloc).beta_std, ...
                    twiss_p3_averaged(iloc).alpha_mean, twiss_p3_averaged(iloc).alpha_std, ...
                    twiss_p3_averaged(iloc).r_rms_mean, twiss_p3_averaged(iloc).r_rms_std);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%% Added 02.03.2026  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== P1 vs P3 STATISTICAL COMPARISON ====================
if exist('twiss_p1_averaged', 'var') && exist('twiss_p3_averaged', 'var')
    
    fprintf('\n=== P1 vs P3 COMPARISON (2× Ion Accumulation) ===\n');
    
    for iloc = 1:n_locations
        % Calculate difference
        delta_r = twiss_p3_averaged(iloc).r_rms_mean - twiss_p1_averaged(iloc).r_rms_mean;
        
        % Pooled standard error
        se_pooled = sqrt(twiss_p1_averaged(iloc).r_rms_std^2/N_SNAPSHOTS + ...
                        twiss_p3_averaged(iloc).r_rms_std^2/N_SNAPSHOTS);
        
        % t-statistic
        if se_pooled > 0
            t_stat = abs(delta_r) / se_pooled;
        else
            t_stat = 0;
        end
        
        fprintf('%s: Δr=%.3f mm, t=%.2f', location_names{iloc}, delta_r, t_stat);
        
        if t_stat > 2.0
            fprintf(' ***SIGNIFICANT***\n');
        else
            fprintf(' (not significant)\n');
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%% Added 02.06.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%STEP 8: Betatron-Averaged Twiss - Pulse 4
%Location: Line ~6050 (after P3 betatron averaging block)
%Action: Add P4 betatron processing
%% ==================== BETATRON-AVERAGED TWISS: PULSE 4 ====================
if ENABLE_MULTIPULSE == true && ENABLE_BETATRON_AVERAGING == true && ...
        snapshot_p4_count == N_SNAPSHOTS

    
    fprintf('\n=== BETATRON-AVERAGED TWISS ANALYSIS - PULSE 4 ===\n');
    fprintf('Processing %d snapshots...\n', N_SNAPSHOTS);
    
    % Use same analysis_locations and location_names from P1/P2/P3
    twiss_p4_instantaneous = struct();
    twiss_p4_averaged = struct();
    
    %% Process all Pulse 4 snapshots
    for is = 1:N_SNAPSHOTS
        beam_data = snapshot_p4{is};
        
        for iloc = 1:n_locations
            z_target = analysis_locations(iloc) / 1000;
            selection_window = 0.015;
            in_plane = abs(beam_data.z - z_target) < selection_window;
            n_selected = sum(in_plane);
            
            if n_selected >= 100
                r_sel = beam_data.r(in_plane);
                pr_sel = beam_data.pr(in_plane);
                gamma_sel = beam_data.gamma(in_plane);
                
                pr_norm = pr_sel ./ (gamma_sel * m_e * c);
                r_c = r_sel - mean(r_sel);
                pr_c = pr_norm - mean(pr_norm);
                
                r2 = mean(r_c.^2);
                pr2 = mean(pr_c.^2);
                r_pr = mean(r_c .* pr_c);
                
                emit_rms = sqrt(r2 * pr2 - r_pr^2);
                
                if emit_rms > 1e-10
                    beta = r2 / emit_rms;
                    gamma_twiss = pr2 / emit_rms;
                    alpha = -r_pr / emit_rms;
                    
                    gamma_avg = mean(gamma_sel);
                    beta_rel = sqrt(1 - 1/gamma_avg^2);
                    emit_norm = emit_rms * gamma_avg * beta_rel;
                    
                    twiss_p4_instantaneous(iloc,is).beta = beta;
                    twiss_p4_instantaneous(iloc,is).alpha = alpha;
                    twiss_p4_instantaneous(iloc,is).gamma = gamma_twiss;
                    twiss_p4_instantaneous(iloc,is).emit_norm = emit_norm * 1e6;
                    twiss_p4_instantaneous(iloc,is).r_rms = sqrt(r2) * 1000;
                    twiss_p4_instantaneous(iloc,is).n_particles = n_selected;
                     % CRITICAL: Include this line to fix the bug:
                    twiss_p4_instantaneous(iloc,is).time = beam_data.time;
                else
                    twiss_p4_instantaneous(iloc,is).beta = NaN;
                    twiss_p4_instantaneous(iloc,is).alpha = NaN;
                    twiss_p4_instantaneous(iloc,is).gamma = NaN;
                    twiss_p4_instantaneous(iloc,is).emit_norm = NaN;
                    twiss_p4_instantaneous(iloc,is).r_rms = NaN;
                end
            else
                twiss_p4_instantaneous(iloc,is).beta = NaN;
                twiss_p4_instantaneous(iloc,is).alpha = NaN;
                twiss_p4_instantaneous(iloc,is).gamma = NaN;
                twiss_p4_instantaneous(iloc,is).emit_norm = NaN;
                twiss_p4_instantaneous(iloc,is).r_rms = NaN;
            end
        end
    end
    
    %% Compute averaged parameters
    for iloc = 1:n_locations
        beta_p4_all = [twiss_p4_instantaneous(iloc,:).beta];
        alpha_p4_all = [twiss_p4_instantaneous(iloc,:).alpha];
        emit_p4_all = [twiss_p4_instantaneous(iloc,:).emit_norm];
        r_rms_p4_all = [twiss_p4_instantaneous(iloc,:).r_rms];
        
        valid_p4 = ~isnan(beta_p4_all);
        
        if sum(valid_p4) >= 3
            twiss_p4_averaged(iloc).location = location_names{iloc};
            twiss_p4_averaged(iloc).z_mm = analysis_locations(iloc);
            twiss_p4_averaged(iloc).beta_mean = mean(beta_p4_all(valid_p4));
            twiss_p4_averaged(iloc).beta_std = std(beta_p4_all(valid_p4));
            twiss_p4_averaged(iloc).alpha_mean = mean(alpha_p4_all(valid_p4));
            twiss_p4_averaged(iloc).alpha_std = std(alpha_p4_all(valid_p4));
            twiss_p4_averaged(iloc).r_rms_mean = mean(r_rms_p4_all(valid_p4));
            twiss_p4_averaged(iloc).r_rms_std = std(r_rms_p4_all(valid_p4));
            twiss_p4_averaged(iloc).emit_mean = mean(emit_p4_all(valid_p4));
            twiss_p4_averaged(iloc).emit_std = std(emit_p4_all(valid_p4));
            twiss_p4_averaged(iloc).n_snapshots = sum(valid_p4);
            
            fprintf('\n%s: β=%.3f±%.3f m, α=%.3f±%.3f, r=%.2f±%.2f mm\n', ...
                    location_names{iloc}, ...
                    twiss_p4_averaged(iloc).beta_mean, twiss_p4_averaged(iloc).beta_std, ...
                    twiss_p4_averaged(iloc).alpha_mean, twiss_p4_averaged(iloc).alpha_std, ...
                    twiss_p4_averaged(iloc).r_rms_mean, twiss_p4_averaged(iloc).r_rms_std);
        end
    end
end
%%%%%%%%%%%%%%%%%%%%%%%% Added 02.06.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%STEP 9: P1 vs P4 Statistical Comparison
%Location: Line ~5920 (after P1 vs P3 comparison)
%Action: Add comprehensive P1 vs P4 analysis
%% ==================== P1 vs P4 STATISTICAL COMPARISON ====================
if exist('twiss_p1_averaged', 'var') && exist('twiss_p4_averaged', 'var')
    
    fprintf('\n=== P1 vs P4 COMPARISON (3× Ion Accumulation) ===\n');
    fprintf('This represents MAXIMUM ion lensing effect in 4-pulse regime\n\n');
    
    for iloc = 1:n_locations
        % Calculate difference
        delta_r = twiss_p4_averaged(iloc).r_rms_mean - twiss_p1_averaged(iloc).r_rms_mean;
        
        % Pooled standard error
        se_pooled = sqrt(twiss_p1_averaged(iloc).r_rms_std^2/N_SNAPSHOTS + ...
                        twiss_p4_averaged(iloc).r_rms_std^2/N_SNAPSHOTS);
        
        % t-statistic
        if se_pooled > 0
            t_stat = abs(delta_r) / se_pooled;
        else
            t_stat = 0;
        end
        
        fprintf('%s (z=%d mm):\n', location_names{iloc}, analysis_locations(iloc));
        fprintf('  P1: r = %.2f ± %.2f mm\n', ...
                twiss_p1_averaged(iloc).r_rms_mean, twiss_p1_averaged(iloc).r_rms_std);
        fprintf('  P4: r = %.2f ± %.2f mm\n', ...
                twiss_p4_averaged(iloc).r_rms_mean, twiss_p4_averaged(iloc).r_rms_std);
        fprintf('  Δr = %.3f mm (%.1f%%)\n', delta_r, ...
                100*delta_r/twiss_p1_averaged(iloc).r_rms_mean);
        fprintf('  Significance: t = %.2f', t_stat);
        
        if t_stat > 3.0
            fprintf(' ***HIGHLY SIGNIFICANT***\n');
        elseif t_stat > 2.0
            fprintf(' **SIGNIFICANT**\n');
        else
            fprintf(' (not significant)\n');
        end
        
        % Check for linear scaling vs P2 and P3
        if exist('twiss_p2_averaged', 'var') && exist('twiss_p3_averaged', 'var')
            delta_r_p2 = twiss_p2_averaged(iloc).r_rms_mean - twiss_p1_averaged(iloc).r_rms_mean;
            delta_r_p3 = twiss_p3_averaged(iloc).r_rms_mean - twiss_p1_averaged(iloc).r_rms_mean;
            
            if abs(delta_r_p2) > 0.05  % Avoid division by zero
                scaling_p4_vs_p2 = delta_r / delta_r_p2;
                scaling_p4_vs_p3 = delta_r / delta_r_p3;
                
                fprintf('  Scaling check:\n');
                fprintf('    P4/P2 ratio: %.2f (expected 3.0)\n', scaling_p4_vs_p2);
                fprintf('    P4/P3 ratio: %.2f (expected 1.5)\n', scaling_p4_vs_p3);
                
                if abs(scaling_p4_vs_p2 - 3.0) < 0.5
                    fprintf('    ✓ LINEAR scaling confirmed!\n');
                elseif scaling_p4_vs_p2 < 2.5
                    fprintf('    ⚠ SATURATION detected\n');
                else
                    fprintf('    ⚠ SUPER-LINEAR growth\n');
                end
            end
        end
        fprintf('\n');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%% Added New Section 01.26.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== INTRA-PULSE ION FOCUSING ANALYSIS ====================
% NEW FEATURE: Analyze early-vs-late beam within single pulse to detect
% ion lensing caused by the beam's leading edge on its trailing edge

if ~ENABLE_MULTIPULSE && ENABLE_BETATRON_AVERAGING == true && ...
   snapshot_early_count == N_SNAPSHOTS_EARLY && snapshot_late_count == N_SNAPSHOTS_LATE
    
    fprintf('\n========================================================================\n');
    fprintf('  INTRA-PULSE ION LENSING ANALYSIS                                     \n');
    fprintf('========================================================================\n');
    fprintf('Hypothesis: Ions created by beam front focus beam tail\n');
    fprintf('Method: Compare EARLY beam (minimal ions) vs LATE beam (with ions)\n\n');
    
    % Define analysis planes (same as multi-pulse for consistency)
    %analysis_locations = [254, 600, 1000, 1700, 2700];
    %location_names = {'Anode', 'Trans1', 'Trans2', 'Trans3', 'Exit'};
    %n_locations = length(analysis_locations);
    %%%%%%%%%%%%%%%%%%%%% Updated analysis locations 02.13.2026 %%%%%%%%%%%%%%%%%%%%%
    % Extended to cover key solenoid centers and BPMs
twiss_locations = [254;    % Anode (after gap acceleration)
                   600;    % Early drift (near Sol 3-4)
                   1000;   % Mid drift region 1 (near Sol 7-8)
                   1500;   % Between Sol 9-10
                   1700;   % Legacy diagnostic
                   2200;   % Near Sol 14-15
                   2700;   % BPM1 region (near Sol 19-20)
                   3400;   % Mid-extension (near Sol 25)
                   3964;   % BPM2 (experimental)
                   4600;   % Mid-extension 2 (near Sol 35)
                   5400;   % Near Sol 45
                   6402;   % BPM3 (experimental)
                   6828;   % BPM4 (experimental)
                   7450;   % Near final solenoid (Sol 49)
                   8305];  % BPM5 / Final exit

location_names = {'Anode', 'Early_Drift', 'Mid_Drift1', 'Trans1', 'Trans2', ...
                  'Mid_Drift2', 'BPM1', 'Extension1', 'BPM2', 'Extension2', ...
                  'Late_Drift', 'BPM3', 'BPM4', 'Sol49', 'Exit'};

n_twiss_planes = length(twiss_locations);

fprintf('=== Twiss Analysis Configuration ===\n');
fprintf('  Number of analysis planes: %d (expanded from 5)\n', n_twiss_planes);
fprintf('  Axial coverage: %.0f mm to %.0f mm\n', ...
        twiss_locations(1), twiss_locations(end));
fprintf('  Average spacing: %.0f mm\n', mean(diff(twiss_locations)));
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    analysis_locations = twiss_locations;
    n_locations = length(analysis_locations);

    % Initialize storage
    twiss_early_instantaneous = struct();
    twiss_late_instantaneous = struct();
    twiss_early_averaged = struct();
    twiss_late_averaged = struct();
    
    %% ===== ANALYZE EARLY BEAM (t=165-180ns, minimal ions) =====
    fprintf('Processing EARLY beam snapshots...\n');
    
    for is = 1:N_SNAPSHOTS_EARLY
        beam_data = snapshot_early{is};
        
        for iloc = 1:n_locations
            z_target = analysis_locations(iloc) / 1000;
            selection_window = 0.015;
            in_plane = abs(beam_data.z - z_target) < selection_window;
            n_selected = sum(in_plane);
            
            if n_selected >= 100
                % Extract particle data
                r_sel = beam_data.r(in_plane);
                pr_sel = beam_data.pr(in_plane);
                gamma_sel = beam_data.gamma(in_plane);
                
                % Normalized transverse momentum
                pr_norm = pr_sel ./ (gamma_sel * m_e * c);
                
                % Center distributions
                r_c = r_sel - mean(r_sel);
                pr_c = pr_norm - mean(pr_norm);
                
                % Second moments
                r2 = mean(r_c.^2);
                pr2 = mean(pr_c.^2);
                r_pr = mean(r_c .* pr_c);
                
                % Emittance
                emit_rms = sqrt(r2 * pr2 - r_pr^2);
                
                if emit_rms > 1e-10
                    % Twiss parameters
                    beta = r2 / emit_rms;
                    gamma_twiss = pr2 / emit_rms;
                    alpha = -r_pr / emit_rms;
                    
                    % Normalized emittance
                    gamma_avg = mean(gamma_sel);
                    beta_rel = sqrt(1 - 1/gamma_avg^2);
                    emit_norm = emit_rms * gamma_avg * beta_rel;
                    
                    % Store instantaneous
                    twiss_early_instantaneous(iloc,is).beta = beta;
                    twiss_early_instantaneous(iloc,is).alpha = alpha;
                    twiss_early_instantaneous(iloc,is).gamma = gamma_twiss;
                    twiss_early_instantaneous(iloc,is).emit_norm = emit_norm * 1e6;
                    twiss_early_instantaneous(iloc,is).r_rms = sqrt(r2) * 1000;
                    twiss_early_instantaneous(iloc,is).n_particles = n_selected;
                    twiss_early_instantaneous(iloc,is).time = beam_data.time;
                else
                    twiss_early_instantaneous(iloc,is).beta = NaN;
                    twiss_early_instantaneous(iloc,is).alpha = NaN;
                    twiss_early_instantaneous(iloc,is).gamma = NaN;
                    twiss_early_instantaneous(iloc,is).emit_norm = NaN;
                    twiss_early_instantaneous(iloc,is).r_rms = NaN;
                end
            else
                twiss_early_instantaneous(iloc,is).beta = NaN;
                twiss_early_instantaneous(iloc,is).alpha = NaN;
                twiss_early_instantaneous(iloc,is).gamma = NaN;
                twiss_early_instantaneous(iloc,is).emit_norm = NaN;
                twiss_early_instantaneous(iloc,is).r_rms = NaN;
            end
        end
    end
    
    %% ===== ANALYZE LATE BEAM (t=210-225ns, with ion focusing) =====
    fprintf('Processing LATE beam snapshots...\n');
    
    for is = 1:N_SNAPSHOTS_LATE
        beam_data = snapshot_late{is};
        
        for iloc = 1:n_locations
            z_target = analysis_locations(iloc) / 1000;
            selection_window = 0.015;
            in_plane = abs(beam_data.z - z_target) < selection_window;
            n_selected = sum(in_plane);
            
            if n_selected >= 100
                r_sel = beam_data.r(in_plane);
                pr_sel = beam_data.pr(in_plane);
                gamma_sel = beam_data.gamma(in_plane);
                
                pr_norm = pr_sel ./ (gamma_sel * m_e * c);
                r_c = r_sel - mean(r_sel);
                pr_c = pr_norm - mean(pr_norm);
                
                r2 = mean(r_c.^2);
                pr2 = mean(pr_c.^2);
                r_pr = mean(r_c .* pr_c);
                
                emit_rms = sqrt(r2 * pr2 - r_pr^2);
                
                if emit_rms > 1e-10
                    beta = r2 / emit_rms;
                    gamma_twiss = pr2 / emit_rms;
                    alpha = -r_pr / emit_rms;
                    
                    gamma_avg = mean(gamma_sel);
                    beta_rel = sqrt(1 - 1/gamma_avg^2);
                    emit_norm = emit_rms * gamma_avg * beta_rel;
                    
                    twiss_late_instantaneous(iloc,is).beta = beta;
                    twiss_late_instantaneous(iloc,is).alpha = alpha;
                    twiss_late_instantaneous(iloc,is).gamma = gamma_twiss;
                    twiss_late_instantaneous(iloc,is).emit_norm = emit_norm * 1e6;
                    twiss_late_instantaneous(iloc,is).r_rms = sqrt(r2) * 1000;
                    twiss_late_instantaneous(iloc,is).n_particles = n_selected;
                    twiss_late_instantaneous(iloc,is).time = beam_data.time;
                else
                    twiss_late_instantaneous(iloc,is).beta = NaN;
                    twiss_late_instantaneous(iloc,is).alpha = NaN;
                    twiss_late_instantaneous(iloc,is).gamma = NaN;
                    twiss_late_instantaneous(iloc,is).emit_norm = NaN;
                    twiss_late_instantaneous(iloc,is).r_rms = NaN;
                end
            else
                twiss_late_instantaneous(iloc,is).beta = NaN;
                twiss_late_instantaneous(iloc,is).alpha = NaN;
                twiss_late_instantaneous(iloc,is).gamma = NaN;
                twiss_late_instantaneous(iloc,is).emit_norm = NaN;
                twiss_late_instantaneous(iloc,is).r_rms = NaN;
            end
        end
    end
    
    %% ===== COMPUTE PHASE-AVERAGED PARAMETERS =====
    fprintf('\n=== Computing Phase-Averaged Parameters ===\n');
    
    for iloc = 1:n_locations
        %% EARLY beam average
        beta_early_all = [twiss_early_instantaneous(iloc,:).beta];
        alpha_early_all = [twiss_early_instantaneous(iloc,:).alpha];
        gamma_early_all = [twiss_early_instantaneous(iloc,:).gamma];
        emit_early_all = [twiss_early_instantaneous(iloc,:).emit_norm];
        r_rms_early_all = [twiss_early_instantaneous(iloc,:).r_rms];
        
        valid_early = ~isnan(beta_early_all);
        
        if sum(valid_early) >= 3
            twiss_early_averaged(iloc).location = location_names{iloc};
            twiss_early_averaged(iloc).z_mm = analysis_locations(iloc);
            twiss_early_averaged(iloc).beta_mean = mean(beta_early_all(valid_early));
            twiss_early_averaged(iloc).beta_std = std(beta_early_all(valid_early));
            twiss_early_averaged(iloc).alpha_mean = mean(alpha_early_all(valid_early));
            twiss_early_averaged(iloc).alpha_std = std(alpha_early_all(valid_early));
            twiss_early_averaged(iloc).gamma_mean = mean(gamma_early_all(valid_early));
            twiss_early_averaged(iloc).gamma_std = std(gamma_early_all(valid_early));
            twiss_early_averaged(iloc).emit_mean = mean(emit_early_all(valid_early));
            twiss_early_averaged(iloc).emit_std = std(emit_early_all(valid_early));
            twiss_early_averaged(iloc).r_rms_mean = mean(r_rms_early_all(valid_early));
            twiss_early_averaged(iloc).r_rms_std = std(r_rms_early_all(valid_early));
            twiss_early_averaged(iloc).n_snapshots = sum(valid_early);
            
            if twiss_early_averaged(iloc).alpha_mean > 0.1
                twiss_early_averaged(iloc).condition = 'Converging';
            elseif twiss_early_averaged(iloc).alpha_mean < -0.1
                twiss_early_averaged(iloc).condition = 'Diverging';
            else
                twiss_early_averaged(iloc).condition = 'Collimated';
            end
        end
        
        %% LATE beam average
        beta_late_all = [twiss_late_instantaneous(iloc,:).beta];
        alpha_late_all = [twiss_late_instantaneous(iloc,:).alpha];
        gamma_late_all = [twiss_late_instantaneous(iloc,:).gamma];
        emit_late_all = [twiss_late_instantaneous(iloc,:).emit_norm];
        r_rms_late_all = [twiss_late_instantaneous(iloc,:).r_rms];
        
        valid_late = ~isnan(beta_late_all);
        
        if sum(valid_late) >= 3
            twiss_late_averaged(iloc).location = location_names{iloc};
            twiss_late_averaged(iloc).z_mm = analysis_locations(iloc);
            twiss_late_averaged(iloc).beta_mean = mean(beta_late_all(valid_late));
            twiss_late_averaged(iloc).beta_std = std(beta_late_all(valid_late));
            twiss_late_averaged(iloc).alpha_mean = mean(alpha_late_all(valid_late));
            twiss_late_averaged(iloc).alpha_std = std(alpha_late_all(valid_late));
            twiss_late_averaged(iloc).gamma_mean = mean(gamma_late_all(valid_late));
            twiss_late_averaged(iloc).gamma_std = std(gamma_late_all(valid_late));
            twiss_late_averaged(iloc).emit_mean = mean(emit_late_all(valid_late));
            twiss_late_averaged(iloc).emit_std = std(emit_late_all(valid_late));
            twiss_late_averaged(iloc).r_rms_mean = mean(r_rms_late_all(valid_late));
            twiss_late_averaged(iloc).r_rms_std = std(r_rms_late_all(valid_late));
            twiss_late_averaged(iloc).n_snapshots = sum(valid_late);
            
            if twiss_late_averaged(iloc).alpha_mean > 0.1
                twiss_late_averaged(iloc).condition = 'Converging';
            elseif twiss_late_averaged(iloc).alpha_mean < -0.1
                twiss_late_averaged(iloc).condition = 'Diverging';
            else
                twiss_late_averaged(iloc).condition = 'Collimated';
            end
        end
        
        %% Calculate and report ion-induced changes
        if length(twiss_early_averaged) >= iloc && length(twiss_late_averaged) >= iloc
            
            % Get ion counts at early and late times
            [~, it_early] = min(abs(t - SNAPSHOT_EARLY_TIMES(1)));
            [~, it_late] = min(abs(t - SNAPSHOT_LATE_TIMES(end)));
            ions_at_early = ion_diag.total_ions_vs_time(it_early);
            ions_at_late = ion_diag.total_ions_vs_time(it_late);
            
            delta_r = twiss_late_averaged(iloc).r_rms_mean - twiss_early_averaged(iloc).r_rms_mean;
            delta_beta = twiss_late_averaged(iloc).beta_mean - twiss_early_averaged(iloc).beta_mean;
            delta_alpha = twiss_late_averaged(iloc).alpha_mean - twiss_early_averaged(iloc).alpha_mean;
            
            % Statistical significance test
            se_pooled = sqrt(twiss_early_averaged(iloc).r_rms_std^2/N_SNAPSHOTS_EARLY + ...
                            twiss_late_averaged(iloc).r_rms_std^2/N_SNAPSHOTS_LATE);
            if se_pooled > 0
                t_stat = abs(delta_r) / se_pooled;
            else
                t_stat = 0;
            end
            
            fprintf('\n%s (z=%d mm):\n', location_names{iloc}, analysis_locations(iloc));
            fprintf('  EARLY beam (t=%.0f-%.0fns, ~%.0f ions):\n', ...
                    SNAPSHOT_EARLY_TIMES(1)*1e9, SNAPSHOT_EARLY_TIMES(end)*1e9, ions_at_early);
            fprintf('    r_rms = %.2f ± %.2f mm\n', ...
                    twiss_early_averaged(iloc).r_rms_mean, twiss_early_averaged(iloc).r_rms_std);
            fprintf('    β = %.3f ± %.3f m\n', ...
                    twiss_early_averaged(iloc).beta_mean, twiss_early_averaged(iloc).beta_std);
            fprintf('    α = %.3f ± %.3f (%s)\n', ...
                    twiss_early_averaged(iloc).alpha_mean, twiss_early_averaged(iloc).alpha_std, ...
                    twiss_early_averaged(iloc).condition);
            
            fprintf('  LATE beam (t=%.0f-%.0fns, ~%.0f ions):\n', ...
                    SNAPSHOT_LATE_TIMES(1)*1e9, SNAPSHOT_LATE_TIMES(end)*1e9, ions_at_late);
            fprintf('    r_rms = %.2f ± %.2f mm\n', ...
                    twiss_late_averaged(iloc).r_rms_mean, twiss_late_averaged(iloc).r_rms_std);
            fprintf('    β = %.3f ± %.3f m\n', ...
                    twiss_late_averaged(iloc).beta_mean, twiss_late_averaged(iloc).beta_std);
            fprintf('    α = %.3f ± %.3f (%s)\n', ...
                    twiss_late_averaged(iloc).alpha_mean, twiss_late_averaged(iloc).alpha_std, ...
                    twiss_late_averaged(iloc).condition);
            
            fprintf('  ION-INDUCED CHANGE:\n');
            fprintf('    Δr_rms = %.3f mm (%.1f%%)\n', delta_r, ...
                    100*delta_r/twiss_early_averaged(iloc).r_rms_mean);
            fprintf('    Δβ = %.3f m (%.1f%%)\n', delta_beta, ...
                    100*delta_beta/twiss_early_averaged(iloc).beta_mean);
            fprintf('    Δα = %.3f\n', delta_alpha);
            fprintf('    Ion increase: %.1fx (%.0f → %.0f)\n', ...
                    ions_at_late/max(1,ions_at_early), ions_at_early, ions_at_late);
            fprintf('    Statistical significance: t=%.2f ', t_stat);
            
            if t_stat > 2
                fprintf('*** SIGNIFICANT! ***\n');
                if delta_r < -0.3
                    fprintf('    → Ion FOCUSING effect confirmed!\n');
                elseif delta_r > 0.3
                    fprintf('    → Ion DEFOCUSING effect confirmed!\n');
                end
            else
                fprintf('(within noise)\n');
            end
        end
    end
    
    %% ===== SAVE INTRA-PULSE RESULTS =====
    save('twiss_intrapulse_ion_focusing.mat', ...
         'twiss_early_averaged', 'twiss_late_averaged', ...
         'twiss_early_instantaneous', 'twiss_late_instantaneous', ...
         'snapshot_early', 'snapshot_late', ...
         'SNAPSHOT_EARLY_TIMES', 'SNAPSHOT_LATE_TIMES', ...
         'analysis_locations', 'location_names');
    
    fprintf('\n✓ Intra-pulse ion focusing analysis saved to twiss_intrapulse_ion_focusing.mat\n');
    %%%%%%%%%%%%%%%%%%%% Figure in Single Pulse regime %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% ===== CREATE VISUALIZATION FIGURE =====
    figure('Position', [100, 100, 1600, 1000], ...
           'Name', 'Intra-Pulse Ion Focusing: Early vs Late Beam');
    
    z_vals = [twiss_early_averaged.z_mm];
    
    % Extract averaged values
    r_early = [twiss_early_averaged.r_rms_mean];
    r_early_std = [twiss_early_averaged.r_rms_std];
    r_late = [twiss_late_averaged.r_rms_mean];
    r_late_std = [twiss_late_averaged.r_rms_std];
    
    beta_early = [twiss_early_averaged.beta_mean];
    beta_early_std = [twiss_early_averaged.beta_std];
    beta_late = [twiss_late_averaged.beta_mean];
    beta_late_std = [twiss_late_averaged.beta_std];
    
    alpha_early = [twiss_early_averaged.alpha_mean];
    alpha_early_std = [twiss_early_averaged.alpha_std];
    alpha_late = [twiss_late_averaged.alpha_mean];
    alpha_late_std = [twiss_late_averaged.alpha_std];
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %% Plot 1: RMS Radius Comparison with Ion Accumulation
    subplot(2,3,1);
    hold on;
    errorbar(z_vals, r_early, r_early_std, 'b-o', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'Early (190-220ns)');
    errorbar(z_vals, r_late, r_late_std, 'r-s', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'Late (220-250ns)');
    yline(50, 'm--', 'LineWidth', 2, 'DisplayName', 'Target');
    
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r_{rms} (mm)', 'FontSize', 12);
    title('Beam Envelope: Ion Focusing Within Single Pulse', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    ylim([0 80]);
    
    %% Plot 2: Ion-Induced Radius Change
    subplot(2,3,2);
    delta_r = r_late - r_early;
    delta_r_err = sqrt(r_early_std.^2 + r_late_std.^2);
    
    errorbar(z_vals, delta_r, delta_r_err, 'ko-', 'LineWidth', 2.5, ...
             'MarkerSize', 8, 'CapSize', 10, 'MarkerFaceColor', 'k');
    hold on;
    yline(0, 'r--', 'LineWidth', 2);
    
    % Highlight statistically significant regions
    for iloc = 1:length(z_vals)
        se = sqrt(twiss_early_averaged(iloc).r_rms_std^2/N_SNAPSHOTS_EARLY + ...
                 twiss_late_averaged(iloc).r_rms_std^2/N_SNAPSHOTS_LATE);
        if se > 0
            t_stat_loc = abs(delta_r(iloc)) / se;
            if t_stat_loc > 2
                y_range = ylim;
                patch([z_vals(iloc)-50, z_vals(iloc)+50, z_vals(iloc)+50, z_vals(iloc)-50], ...
                      [y_range(1), y_range(1), y_range(2), y_range(2)], ...
                      'yellow', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            end
        end
    end
    
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('Δr_{rms} = r_{late} - r_{early} (mm)', 'FontSize', 12);
    title('Ion-Induced Radius Change', 'FontSize', 14);
    grid on;
    xlim([0 8310]);
    legend('Difference', 'Zero line', 'Location', 'best');
    
    %% Plot 3: Ion Accumulation Timeline with Snapshot Windows
    subplot(2,3,3);
    nonzero_idx = ion_diag.total_ions_vs_time > 0;
    semilogy(t(nonzero_idx)*1e9, ion_diag.total_ions_vs_time(nonzero_idx), 'g-', 'LineWidth', 2.5);
    hold on;
    
    % Get actual y-limits for patch
    ylims = ylim;
    
    % Mark EARLY snapshot window
    patch([SNAPSHOT_EARLY_TIMES(1)*1e9, SNAPSHOT_EARLY_TIMES(end)*1e9, ...
           SNAPSHOT_EARLY_TIMES(end)*1e9, SNAPSHOT_EARLY_TIMES(1)*1e9], ...
          [ylims(1), ylims(1), ylims(2), ylims(2)], ...
          'blue', 'FaceAlpha', 0.2, 'EdgeColor', 'b', 'LineWidth', 2);
    
    % Mark LATE snapshot window
    patch([SNAPSHOT_LATE_TIMES(1)*1e9, SNAPSHOT_LATE_TIMES(end)*1e9, ...
           SNAPSHOT_LATE_TIMES(end)*1e9, SNAPSHOT_LATE_TIMES(1)*1e9], ...
          [ylims(1), ylims(1), ylims(2), ylims(2)], ...
          'red', 'FaceAlpha', 0.2, 'EdgeColor', 'r', 'LineWidth', 2);
    
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('Total Ions in System', 'FontSize', 12);
    title('Ion Buildup During Single Pulse', 'FontSize', 14);
    legend('Ion count', 'Early snapshots', 'Late snapshots', 'Location', 'best');
    grid on;
    %xlim([150 270]);
    xlim([145 305]);
    
    % Add text annotations
    [~, it_early_mid] = min(abs(t - mean(SNAPSHOT_EARLY_TIMES)));
    [~, it_late_mid] = min(abs(t - mean(SNAPSHOT_LATE_TIMES)));
    text(172, ion_diag.total_ions_vs_time(it_early_mid), ...
         sprintf('%.1e ions', ion_diag.total_ions_vs_time(it_early_mid)), ...
         'FontSize', 10, 'Color', 'blue', 'FontWeight', 'bold');
    text(217, ion_diag.total_ions_vs_time(it_late_mid), ...
         sprintf('%.1e ions', ion_diag.total_ions_vs_time(it_late_mid)), ...
         'FontSize', 10, 'Color', 'red', 'FontWeight', 'bold');
    
    %% Plot 4: Beta Function Comparison
    subplot(2,3,4);
    hold on;
    errorbar(z_vals, beta_early, beta_early_std, 'b-o', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'Early');
    errorbar(z_vals, beta_late, beta_late_std, 'r-s', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'Late');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Beta Function: Early vs Late', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    %% Plot 5: Alpha Parameter Comparison
    subplot(2,3,5);
    hold on;
    errorbar(z_vals, alpha_early, alpha_early_std, 'b-o', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'Early');
    errorbar(z_vals, alpha_late, alpha_late_std, 'r-s', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'Late');
    yline(0, 'k--', 'LineWidth', 1.5);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Alpha Parameter: Early vs Late', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    %% Plot 6: Summary and Statistical Analysis
    subplot(2,3,6);
    axis off;
    
    text(0.1, 0.95, 'INTRA-PULSE ION FOCUSING', 'FontWeight', 'bold', 'FontSize', 14);
    text(0.1, 0.88, 'Exit Plane (z=2700mm):', 'FontWeight', 'bold', 'FontSize', 12);
    
    y_pos = 0.78;
    
    % Find exit plane data
    iloc_exit = find([twiss_early_averaged.z_mm] == 2700, 1);
    
    if ~isempty(iloc_exit)
        % Calculate significance
        delta_r_exit = twiss_late_averaged(iloc_exit).r_rms_mean - ...
                      twiss_early_averaged(iloc_exit).r_rms_mean;
        se_exit = sqrt(twiss_early_averaged(iloc_exit).r_rms_std^2/N_SNAPSHOTS_EARLY + ...
                      twiss_late_averaged(iloc_exit).r_rms_std^2/N_SNAPSHOTS_LATE);
        t_stat_exit = abs(delta_r_exit) / se_exit;
        
        % Early beam stats
        text(0.1, y_pos, sprintf('Early: r=%.2f±%.2f mm', ...
             twiss_early_averaged(iloc_exit).r_rms_mean, ...
             twiss_early_averaged(iloc_exit).r_rms_std), ...
             'FontSize', 11, 'Color', 'blue');
        y_pos = y_pos - 0.08;
        
        text(0.15, y_pos, sprintf('(~%.0f ions present)', ions_at_early), ...
             'FontSize', 10, 'Color', [0.3 0.3 0.7]);
        y_pos = y_pos - 0.10;
        
        % Late beam stats
        text(0.1, y_pos, sprintf('Late: r=%.2f±%.2f mm', ...
             twiss_late_averaged(iloc_exit).r_rms_mean, ...
             twiss_late_averaged(iloc_exit).r_rms_std), ...
             'FontSize', 11, 'Color', 'red');
        y_pos = y_pos - 0.08;
        
        text(0.15, y_pos, sprintf('(~%.0f ions present)', ions_at_late), ...
             'FontSize', 10, 'Color', [0.7 0.3 0.3]);
        y_pos = y_pos - 0.12;
        
        % Change metrics
        text(0.1, y_pos, sprintf('Δr = %.3f ± %.3f mm', delta_r_exit, se_exit*sqrt(2)), ...
             'FontSize', 12, 'FontWeight', 'bold', 'Color', 'black');
        y_pos = y_pos - 0.08;
        
        text(0.1, y_pos, sprintf('Relative change: %.1f%%', ...
             100*delta_r_exit/twiss_early_averaged(iloc_exit).r_rms_mean), ...
             'FontSize', 11);
        y_pos = y_pos - 0.10;
        
        % Statistical significance
        text(0.1, y_pos, sprintf('Significance: t=%.2f', t_stat_exit), ...
             'FontSize', 11, 'FontWeight', 'bold');
        y_pos = y_pos - 0.10;
        
        % Interpretation
        text(0.1, y_pos, 'INTERPRETATION:', 'FontWeight', 'bold', 'FontSize', 11);
        y_pos = y_pos - 0.08;
        
        if t_stat_exit > 2
            if delta_r_exit < -0.3
                text(0.1, y_pos, '✓ ION FOCUSING detected!', ...
                     'FontSize', 11, 'Color', 'green', 'FontWeight', 'bold');
                y_pos = y_pos - 0.06;
                text(0.1, y_pos, '  → Late beam is TIGHTER', 'FontSize', 10, 'Color', 'green');
                y_pos = y_pos - 0.06;
                text(0.1, y_pos, '  → Ions act as lens', 'FontSize', 10);
            elseif delta_r_exit > 0.3
                text(0.1, y_pos, '✓ ION DEFOCUSING detected!', ...
                     'FontSize', 11, 'Color', 'red', 'FontWeight', 'bold');
                y_pos = y_pos - 0.06;
                text(0.1, y_pos, '  → Late beam is WIDER', 'FontSize', 10, 'Color', 'red');
                y_pos = y_pos - 0.06;
                text(0.1, y_pos, '  → Ions cause aberration', 'FontSize', 10);
            else
                text(0.1, y_pos, '✓ Significant but small', 'FontSize', 11, 'Color', 'blue');
            end
        else
            text(0.1, y_pos, '• No significant difference', 'FontSize', 11, 'Color', 'blue');
            y_pos = y_pos - 0.06;
            text(0.1, y_pos, '  (ion density too low)', 'FontSize', 10);
            y_pos = y_pos - 0.06;
            text(0.1, y_pos, '  or statistical noise', 'FontSize', 10);
        end
    end
    
    sgtitle(sprintf('Intra-Pulse Ion Lensing: Δt=%.0f ns, ΔIons≈%.0fM', ...
                    (SNAPSHOT_LATE_TIMES(end) - SNAPSHOT_EARLY_TIMES(1))*1e9, ...
                    (ions_at_late - ions_at_early)/1e6), ...
            'FontSize', 16, 'FontWeight', 'bold');
    
end  % End intra-pulse analysis

%%%%%%%%%%%%%%%%%%%%%%%%%%% added 02.25.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================================================================================
%% FIX 8: SINGLE-PULSE BETATRON-AVERAGED TWISS FOR PULSE 1
%% Add this AFTER the existing intra-pulse analysis section
%% This runs when ENABLE_MULTIPULSE == false AND P1 snapshots were captured
%% ==================================================================================

if ENABLE_MULTIPULSE == false && ENABLE_BETATRON_AVERAGING == true && ...
   exist('snapshot_p1', 'var') && snapshot_p1_count == N_SNAPSHOTS
    
    fprintf('\n========================================================================\n');
    fprintf('  BETATRON-AVERAGED TWISS ANALYSIS - PULSE 1 (SINGLE-PULSE MODE)      \n');
    fprintf('  Mid-pulse snapshots: t=%.0f-%.0f ns (%d snapshots)                  \n', ...
            SNAPSHOT_P1_TIMES(1)*1e9, SNAPSHOT_P1_TIMES(end)*1e9, N_SNAPSHOTS);
    fprintf('========================================================================\n');
    
    % Use standard analysis locations
    twiss_p1_instantaneous = struct();
    twiss_p1_averaged = struct();
    
    %% Process all P1 snapshots
    for is = 1:N_SNAPSHOTS
        beam_data = snapshot_p1{is};
        
        for iloc = 1:N_ANALYSIS_PLANES
            z_target = ANALYSIS_LOCATIONS(iloc) / 1000;  % meters
            
            selection_window = 0.015;  % +/-15mm
            in_plane = abs(beam_data.z - z_target) < selection_window;
            n_selected = sum(in_plane);
            
            if n_selected >= 100
                r_sel = beam_data.r(in_plane);
                pr_sel = beam_data.pr(in_plane);
                gamma_sel = beam_data.gamma(in_plane);
                
                pr_norm = pr_sel ./ (gamma_sel * m_e * c);
                r_c = r_sel - mean(r_sel);
                pr_c = pr_norm - mean(pr_norm);
                
                r2 = mean(r_c.^2);
                pr2 = mean(pr_c.^2);
                r_pr = mean(r_c .* pr_c);
                emit_rms = sqrt(r2 * pr2 - r_pr^2);
                
                if emit_rms > 1e-10
                    beta = r2 / emit_rms;
                    gamma_twiss = pr2 / emit_rms;
                    alpha = -r_pr / emit_rms;
                    
                    gamma_avg = mean(gamma_sel);
                    beta_rel = sqrt(1 - 1/gamma_avg^2);
                    emit_norm = emit_rms * gamma_avg * beta_rel;
                    
                    twiss_p1_instantaneous(iloc, is).beta = beta;
                    twiss_p1_instantaneous(iloc, is).alpha = alpha;
                    twiss_p1_instantaneous(iloc, is).gamma = gamma_twiss;
                    twiss_p1_instantaneous(iloc, is).emit_norm = emit_norm * 1e6;
                    twiss_p1_instantaneous(iloc, is).r_rms = sqrt(r2) * 1000;
                    twiss_p1_instantaneous(iloc, is).n_particles = n_selected;
                    twiss_p1_instantaneous(iloc, is).time = beam_data.time;
                else
                    twiss_p1_instantaneous(iloc, is).beta = NaN;
                    twiss_p1_instantaneous(iloc, is).alpha = NaN;
                    twiss_p1_instantaneous(iloc, is).gamma = NaN;
                    twiss_p1_instantaneous(iloc, is).emit_norm = NaN;
                    twiss_p1_instantaneous(iloc, is).r_rms = NaN;
                end
            else
                twiss_p1_instantaneous(iloc, is).beta = NaN;
                twiss_p1_instantaneous(iloc, is).alpha = NaN;
                twiss_p1_instantaneous(iloc, is).gamma = NaN;
                twiss_p1_instantaneous(iloc, is).emit_norm = NaN;
                twiss_p1_instantaneous(iloc, is).r_rms = NaN;
            end
        end
    end
    
    %% Compute phase-averaged parameters
    for iloc = 1:N_ANALYSIS_PLANES
        beta_all = [twiss_p1_instantaneous(iloc,:).beta];
        alpha_all = [twiss_p1_instantaneous(iloc,:).alpha];
        gamma_all = [twiss_p1_instantaneous(iloc,:).gamma];
        emit_all = [twiss_p1_instantaneous(iloc,:).emit_norm];
        r_rms_all = [twiss_p1_instantaneous(iloc,:).r_rms];
        
        valid = ~isnan(beta_all);
        
        if sum(valid) >= 3
            twiss_p1_averaged(iloc).location = ANALYSIS_LOCATION_NAMES{iloc};
            twiss_p1_averaged(iloc).z_mm = ANALYSIS_LOCATIONS(iloc);
            twiss_p1_averaged(iloc).beta_mean = mean(beta_all(valid));
            twiss_p1_averaged(iloc).beta_std = std(beta_all(valid));
            twiss_p1_averaged(iloc).alpha_mean = mean(alpha_all(valid));
            twiss_p1_averaged(iloc).alpha_std = std(alpha_all(valid));
            twiss_p1_averaged(iloc).gamma_mean = mean(gamma_all(valid));
            twiss_p1_averaged(iloc).gamma_std = std(gamma_all(valid));
            twiss_p1_averaged(iloc).emit_mean = mean(emit_all(valid));
            twiss_p1_averaged(iloc).emit_std = std(emit_all(valid));
            twiss_p1_averaged(iloc).r_rms_mean = mean(r_rms_all(valid));
            twiss_p1_averaged(iloc).r_rms_std = std(r_rms_all(valid));
            twiss_p1_averaged(iloc).n_snapshots = sum(valid);
            
            if twiss_p1_averaged(iloc).alpha_mean > 0.1
                twiss_p1_averaged(iloc).condition = 'Converging';
            elseif twiss_p1_averaged(iloc).alpha_mean < -0.1
                twiss_p1_averaged(iloc).condition = 'Diverging';
            else
                twiss_p1_averaged(iloc).condition = 'Collimated';
            end
            
            fprintf('\n%s (z=%d mm) - P1 BETATRON-AVERAGED:\n', ...
                    ANALYSIS_LOCATION_NAMES{iloc}, ANALYSIS_LOCATIONS(iloc));
            fprintf('  r_rms = %.2f +/- %.2f mm\n', ...
                    twiss_p1_averaged(iloc).r_rms_mean, twiss_p1_averaged(iloc).r_rms_std);
            fprintf('  beta  = %.3f +/- %.3f m\n', ...
                    twiss_p1_averaged(iloc).beta_mean, twiss_p1_averaged(iloc).beta_std);
            fprintf('  alpha = %.3f +/- %.3f (%s)\n', ...
                    twiss_p1_averaged(iloc).alpha_mean, twiss_p1_averaged(iloc).alpha_std, ...
                    twiss_p1_averaged(iloc).condition);
            fprintf('  emit_n = %.2f +/- %.2f mm-mrad\n', ...
                    twiss_p1_averaged(iloc).emit_mean, twiss_p1_averaged(iloc).emit_std);
        end
    end
    
    %% ===== THREE-WAY COMPARISON: P1-Averaged vs Early vs Late =====
    if exist('twiss_early_averaged', 'var') && exist('twiss_late_averaged', 'var')
        
        fprintf('\n========================================================================\n');
        fprintf('  THREE-WAY COMPARISON: P1-Averaged vs Early vs Late                   \n');
        fprintf('  Shows ion focusing effect WITHIN single pulse                         \n');
        fprintf('========================================================================\n');
        
        figure('Position', [100, 100, 1800, 1000], ...
               'Name', 'Single-Pulse: P1-Averaged vs Early vs Late');
        
        z_vals = [twiss_p1_averaged.z_mm];
        
        % Extract all three sets
        r_p1_mean = [twiss_p1_averaged.r_rms_mean];
        r_p1_std = [twiss_p1_averaged.r_rms_std];
        r_early_mean = [twiss_early_averaged.r_rms_mean];
        r_early_std = [twiss_early_averaged.r_rms_std];
        r_late_mean = [twiss_late_averaged.r_rms_mean];
        r_late_std = [twiss_late_averaged.r_rms_std];
        
        beta_p1 = [twiss_p1_averaged.beta_mean];
        beta_p1_std = [twiss_p1_averaged.beta_std];
        beta_early = [twiss_early_averaged.beta_mean];
        beta_early_std = [twiss_early_averaged.beta_std];
        beta_late = [twiss_late_averaged.beta_mean];
        beta_late_std = [twiss_late_averaged.beta_std];
        
        alpha_p1 = [twiss_p1_averaged.alpha_mean];
        alpha_p1_std = [twiss_p1_averaged.alpha_std];
        alpha_early = [twiss_early_averaged.alpha_mean];
        alpha_late = [twiss_late_averaged.alpha_mean];
        
        %% Plot 1: RMS Radius - Three-way comparison
        subplot(2,3,1);
        hold on;
        errorbar(z_vals, r_early_mean, r_early_std, 'b-o', 'LineWidth', 2, ...
                 'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'Early (190-220ns)');
        errorbar(z_vals, r_p1_mean, r_p1_std, 'k-d', 'LineWidth', 2.5, ...
                 'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'P1-Avg (210-240ns)');
        errorbar(z_vals, r_late_mean, r_late_std, 'r-s', 'LineWidth', 2, ...
                 'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'Late (220-250ns)');
        yline(50, 'm--', 'LineWidth', 2, 'DisplayName', 'Target');
        xlabel('z (mm)', 'FontSize', 13);
        ylabel('r_{rms} (mm)', 'FontSize', 13);
        title('Beam Envelope: Early vs P1-Avg vs Late', 'FontSize', 15, 'FontWeight', 'bold');
        legend('Location', 'best', 'FontSize', 10);
        grid on; xlim([0 8310]); ylim([0 80]);
        
        %% Plot 2: Beta Function - Three-way
        subplot(2,3,2);
        hold on;
        errorbar(z_vals, beta_early, beta_early_std, 'b-o', 'LineWidth', 2, ...
                 'MarkerSize', 8, 'DisplayName', 'Early');
        errorbar(z_vals, beta_p1, beta_p1_std, 'k-d', 'LineWidth', 2.5, ...
                 'MarkerSize', 8, 'DisplayName', 'P1-Avg');
        errorbar(z_vals, beta_late, beta_late_std, 'r-s', 'LineWidth', 2, ...
                 'MarkerSize', 8, 'DisplayName', 'Late');
        xlabel('z (mm)', 'FontSize', 13);
        ylabel('\beta (m)', 'FontSize', 13);
        title('Beta Function: Three-Way Comparison', 'FontSize', 15, 'FontWeight', 'bold');
        legend('Location', 'best'); grid on; xlim([0 8310]);
        
        %% Plot 3: Alpha Parameter - Three-way
        subplot(2,3,3);
        hold on;
        plot(z_vals, alpha_early, 'b-o', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Early');
        plot(z_vals, alpha_p1, 'k-d', 'LineWidth', 2.5, 'MarkerSize', 8, 'DisplayName', 'P1-Avg');
        plot(z_vals, alpha_late, 'r-s', 'LineWidth', 2, 'MarkerSize', 8, 'DisplayName', 'Late');
        yline(0, 'k--', 'LineWidth', 1.5);
        xlabel('z (mm)', 'FontSize', 13);
        ylabel('\alpha', 'FontSize', 13);
        title('Alpha Parameter: Three-Way', 'FontSize', 15, 'FontWeight', 'bold');
        legend('Location', 'best'); grid on; xlim([0 8310]);
        
        %% Plot 4: Difference (Late - Early) with P1-Avg reference
        subplot(2,3,4);
        delta_r_late_early = r_late_mean - r_early_mean;
        delta_r_err = sqrt(r_early_std.^2 + r_late_std.^2);
        
        errorbar(z_vals, delta_r_late_early, delta_r_err, 'ko-', 'LineWidth', 2.5, ...
                 'MarkerSize', 8, 'CapSize', 10);
        hold on;
        yline(0, 'r--', 'LineWidth', 2);
        xlabel('z (mm)', 'FontSize', 13);
        ylabel('\Delta r_{rms} = r_{late} - r_{early} (mm)', 'FontSize', 13);
        title('Ion-Induced Change Within Pulse', 'FontSize', 15, 'FontWeight', 'bold');
        grid on; xlim([0 8310]);
        
        % Shade significant regions
        for iloc = 1:N_ANALYSIS_PLANES
            se = sqrt(r_early_std(iloc)^2/N_SNAPSHOTS_EARLY + r_late_std(iloc)^2/N_SNAPSHOTS_LATE);
            if se > 0 && abs(delta_r_late_early(iloc)) / se > 2.0
                y_range = ylim;
                patch([z_vals(iloc)-50, z_vals(iloc)+50, z_vals(iloc)+50, z_vals(iloc)-50], ...
                      [y_range(1), y_range(1), y_range(2), y_range(2)], ...
                      'yellow', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            end
        end
        
        %% Plot 5: Statistical significance
        subplot(2,3,5);
        t_stats = zeros(N_ANALYSIS_PLANES, 1);
        for iloc = 1:N_ANALYSIS_PLANES
            se = sqrt(r_early_std(iloc)^2/N_SNAPSHOTS_EARLY + r_late_std(iloc)^2/N_SNAPSHOTS_LATE);
            if se > 0
                t_stats(iloc) = abs(delta_r_late_early(iloc)) / se;
            end
        end
        bar(1:N_ANALYSIS_PLANES, t_stats, 'FaceColor', [0.3 0.6 0.9]);
        hold on;
        yline(2.0, 'r--', 'LineWidth', 3, 'Label', '95% significance');
        set(gca, 'XTickLabel', ANALYSIS_LOCATION_NAMES, 'FontSize', 9);
        xtickangle(45);
        ylabel('t-statistic', 'FontSize', 13);
        title('Statistical Significance: Late vs Early', 'FontSize', 15, 'FontWeight', 'bold');
        grid on;
        
        %% Plot 6: Summary
        subplot(2,3,6);
        axis off;
        
        text(0.5, 0.95, 'SINGLE-PULSE ION ANALYSIS', 'FontWeight', 'bold', 'FontSize', 16, ...
             'HorizontalAlignment', 'center');
        
        y_pos = 0.82;
        text(0.1, y_pos, 'Three Analysis Windows:', 'FontWeight', 'bold', 'FontSize', 12);
        y_pos = y_pos - 0.08;
        text(0.1, y_pos, sprintf('  EARLY: t=%.0f-%.0f ns (minimal ions)', ...
             SNAPSHOT_EARLY_TIMES(1)*1e9, SNAPSHOT_EARLY_TIMES(end)*1e9), 'FontSize', 11, 'Color', 'blue');
        y_pos = y_pos - 0.06;
        text(0.1, y_pos, sprintf('  P1-AVG: t=%.0f-%.0f ns (betatron averaged)', ...
             SNAPSHOT_P1_TIMES(1)*1e9, SNAPSHOT_P1_TIMES(end)*1e9), 'FontSize', 11, 'Color', 'black');
        y_pos = y_pos - 0.06;
        text(0.1, y_pos, sprintf('  LATE:  t=%.0f-%.0f ns (with ion focusing)', ...
             SNAPSHOT_LATE_TIMES(1)*1e9, SNAPSHOT_LATE_TIMES(end)*1e9), 'FontSize', 11, 'Color', 'red');
        y_pos = y_pos - 0.10;
        
        % Ion counts
        [~, it_early] = min(abs(t - SNAPSHOT_EARLY_TIMES(1)));
        [~, it_late] = min(abs(t - SNAPSHOT_LATE_TIMES(end)));
        ions_early = ion_diag.total_ions_vs_time(it_early);
        ions_late = ion_diag.total_ions_vs_time(it_late);
        
        text(0.1, y_pos, sprintf('Ion buildup: %.1e -> %.1e (%.0fx)', ...
             ions_early, ions_late, ions_late/max(1,ions_early)), ...
             'FontSize', 11, 'FontWeight', 'bold');
        y_pos = y_pos - 0.10;
        
        % Exit plane comparison
        idx_exit = find(ANALYSIS_LOCATIONS == 8305, 1);
        if isempty(idx_exit), idx_exit = N_ANALYSIS_PLANES; end
        
        text(0.1, y_pos, sprintf('Exit (z=%dmm):', ANALYSIS_LOCATIONS(idx_exit)), ...
             'FontWeight', 'bold', 'FontSize', 12);
        y_pos = y_pos - 0.06;
        text(0.1, y_pos, sprintf('  Early: r=%.2f mm', r_early_mean(idx_exit)), ...
             'FontSize', 11, 'Color', 'blue');
        y_pos = y_pos - 0.05;
        text(0.1, y_pos, sprintf('  P1-Avg: r=%.2f mm', r_p1_mean(idx_exit)), ...
             'FontSize', 11, 'Color', 'black');
        y_pos = y_pos - 0.05;
        text(0.1, y_pos, sprintf('  Late: r=%.2f mm', r_late_mean(idx_exit)), ...
             'FontSize', 11, 'Color', 'red');
        y_pos = y_pos - 0.06;
        
        delta_exit = r_late_mean(idx_exit) - r_early_mean(idx_exit);
        text(0.1, y_pos, sprintf('  Delta: %.3f mm (%.1f%%)', ...
             delta_exit, 100*delta_exit/r_early_mean(idx_exit)), ...
             'FontSize', 11, 'FontWeight', 'bold');
        y_pos = y_pos - 0.06;
        
        if t_stats(idx_exit) > 2.0
            text(0.1, y_pos, sprintf('  t=%.2f *** SIGNIFICANT ***', t_stats(idx_exit)), ...
                 'FontSize', 11, 'Color', 'red', 'FontWeight', 'bold');
        else
            text(0.1, y_pos, sprintf('  t=%.2f (within noise)', t_stats(idx_exit)), ...
                 'FontSize', 11, 'Color', 'green');
        end
        
        sgtitle(sprintf('Single-Pulse Ion Focusing: P1-Averaged + Early/Late (%d snapshots each)', ...
                N_SNAPSHOTS), 'FontSize', 18, 'FontWeight', 'bold');
    end
    
    %% Save P1 betatron data (single-pulse mode)
    save('twiss_betatron_p1_single_pulse.mat', ...
         'twiss_p1_averaged', 'twiss_p1_instantaneous', ...
         'snapshot_p1', 'ANALYSIS_LOCATIONS', 'ANALYSIS_LOCATION_NAMES', ...
         'SNAPSHOT_P1_TIMES', 'N_SNAPSHOTS');
    fprintf('\nP1 betatron-averaged Twiss saved (single-pulse mode)\n');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 30 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== STEP 5.1: BETATRON OSCILLATION VISUALIZATION P1 ====================

if ENABLE_BETATRON_AVERAGING == true && exist('twiss_p1_averaged', 'var')
    
    figure('Position', [100, 100, 1800, 1200], ...
           'Name', 'Betatron Oscillation Analysis Pulse 1');
    
    %% Plot 1: Beta function oscillations at each location
    subplot(1,3,1);
    hold on;
    colors = lines(n_locations);
    
    for iloc = 1:n_locations
        % Extract beta values across all snapshots
        beta_p1 = [twiss_p1_instantaneous(iloc,:).beta];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;  % ns
        valid = ~isnan(beta_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), beta_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'DisplayName', location_names{iloc});
            
            % Add mean line
            beta_mean = twiss_p1_averaged(iloc).beta_mean;
            plot([min(times_p1) max(times_p1)], [beta_mean beta_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Pulse 1: Beta Function Oscillations', 'FontSize', 14);
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    
    %% Plot 2: Alpha parameter oscillations
    subplot(1,3,2);
    hold on;
    
    for iloc = 1:n_locations
        alpha_p1 = [twiss_p1_instantaneous(iloc,:).alpha];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(alpha_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), alpha_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2);
            alpha_mean = twiss_p1_averaged(iloc).alpha_mean;
            plot([min(times_p1) max(times_p1)], [alpha_mean alpha_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    
    yline(0, 'k:', 'LineWidth', 1.5);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Pulse 1: Alpha Parameter Oscillations', 'FontSize', 14);
    grid on;
    
    %% Plot 3: RMS radius oscillations (key betatron signature!)
    subplot(1,3,3);
    hold on;
    
    for iloc = 1:n_locations
        r_rms_p1 = [twiss_p1_instantaneous(iloc,:).r_rms];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(r_rms_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), r_rms_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'MarkerSize', 6);
            r_mean = twiss_p1_averaged(iloc).r_rms_mean;
            plot([min(times_p1) max(times_p1)], [r_mean r_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('r_{rms} (mm)', 'FontSize', 12);
    title('Pulse 1: RMS Radius Oscillations', 'FontSize', 14);
    grid on;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% RR Figure in jet colors %%%%%%%%%%%%%%%%%%%%%%%%%%%
if ENABLE_BETATRON_AVERAGING == true && exist('twiss_p1_averaged', 'var')

 figure('Position', [100, 100, 1800, 1200], ...
           'Name', 'Betatron Oscillation Analysis Pulse 1');
    
    %% Plot 1: Beta function oscillations at each location
    subplot(1,3,1);
    hold on;
    length = n_locations;
    colors = jet(length);

    for iloc = 1:n_locations
        % Extract beta values across all snapshots
        beta_p1 = [twiss_p1_instantaneous(iloc,:).beta];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;  % ns
        valid = ~isnan(beta_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), beta_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'DisplayName', location_names{iloc});
            
            % Add mean line
            beta_mean = twiss_p1_averaged(iloc).beta_mean;
            plot([min(times_p1) max(times_p1)], [beta_mean beta_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Pulse 1: Beta Function Oscillations', 'FontSize', 14);
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    
    %% Plot 2: Alpha parameter oscillations
    subplot(1,3,2);
    hold on;
    
    for iloc = 1:n_locations
        alpha_p1 = [twiss_p1_instantaneous(iloc,:).alpha];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(alpha_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), alpha_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2);
            alpha_mean = twiss_p1_averaged(iloc).alpha_mean;
            plot([min(times_p1) max(times_p1)], [alpha_mean alpha_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    
    yline(0, 'k:', 'LineWidth', 1.5);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Pulse 1: Alpha Parameter Oscillations', 'FontSize', 14);
    grid on;
    
    %% Plot 3: RMS radius oscillations (key betatron signature!)
    subplot(1,3,3);
    hold on;
    
    for iloc = 1:n_locations
        r_rms_p1 = [twiss_p1_instantaneous(iloc,:).r_rms];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(r_rms_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), r_rms_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'MarkerSize', 6);
            r_mean = twiss_p1_averaged(iloc).r_rms_mean;
            plot([min(times_p1) max(times_p1)], [r_mean r_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('r_{rms} (mm)', 'FontSize', 12);
    title('Pulse 1: RMS Radius Oscillations', 'FontSize', 14);
    grid on;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 31 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
%% ==================== STEP 5.2: BETATRON OSCILLATION VISUALIZATION P1 vs P2 ===============

if ENABLE_MULTIPULSE == true && ENABLE_BETATRON_AVERAGING == true && exist('twiss_p2_averaged', 'var')
    
    figure('Position', [100, 100, 1800, 1200], ...
           'Name', 'Betatron Oscillation Analysis P1 vs P2');
    
    %% Plot 1: Beta function oscillations at each location
    subplot(3,3,1);
    hold on;
    colors = lines(n_locations);
    
    for iloc = 1:n_locations
        % Extract beta values across all snapshots
        beta_p1 = [twiss_p1_instantaneous(iloc,:).beta];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;  % ns
        valid = ~isnan(beta_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), beta_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'DisplayName', location_names{iloc});
            
            % Add mean line
            beta_mean = twiss_p1_averaged(iloc).beta_mean;
            plot([min(times_p1) max(times_p1)], [beta_mean beta_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Pulse 1: Beta Function Oscillations', 'FontSize', 14);
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    
    %% Plot 2: Alpha parameter oscillations
    subplot(3,3,2);
    hold on;
    
    for iloc = 1:n_locations
        alpha_p1 = [twiss_p1_instantaneous(iloc,:).alpha];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(alpha_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), alpha_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2);
            alpha_mean = twiss_p1_averaged(iloc).alpha_mean;
            plot([min(times_p1) max(times_p1)], [alpha_mean alpha_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    
    yline(0, 'k:', 'LineWidth', 1.5);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Pulse 1: Alpha Parameter Oscillations', 'FontSize', 14);
    grid on;
    
    %% Plot 3: RMS radius oscillations (key betatron signature!)
    subplot(3,3,3);
    hold on;
    
    for iloc = 1:n_locations
        r_rms_p1 = [twiss_p1_instantaneous(iloc,:).r_rms];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(r_rms_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), r_rms_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'MarkerSize', 6);
            r_mean = twiss_p1_averaged(iloc).r_rms_mean;
            plot([min(times_p1) max(times_p1)], [r_mean r_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('r_{rms} (mm)', 'FontSize', 12);
    title('Pulse 1: RMS Radius Oscillations', 'FontSize', 14);
    grid on;
    
    %% Plot 4-6: Same for Pulse 2
    subplot(3,3,4);
    hold on;
    for iloc = 1:n_locations
        beta_p2 = [twiss_p2_instantaneous(iloc,:).beta];
        times_p2 = [twiss_p2_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(beta_p2);
        if sum(valid) > 2
            plot(times_p2(valid), beta_p2(valid), 's-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2);
            beta_mean = twiss_p2_averaged(iloc).beta_mean;
            plot([min(times_p2) max(times_p2)], [beta_mean beta_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Pulse 2: Beta Function Oscillations', 'FontSize', 14);
    grid on;
    
    subplot(3,3,5);
    hold on;
    for iloc = 1:n_locations
        alpha_p2 = [twiss_p2_instantaneous(iloc,:).alpha];
        times_p2 = [twiss_p2_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(alpha_p2);
        if sum(valid) > 2
            plot(times_p2(valid), alpha_p2(valid), 's-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2);
            alpha_mean = twiss_p2_averaged(iloc).alpha_mean;
            plot([min(times_p2) max(times_p2)], [alpha_mean alpha_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    yline(0, 'k:', 'LineWidth', 1.5);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Pulse 2: Alpha Parameter Oscillations', 'FontSize', 14);
    grid on;
    
    subplot(3,3,6);
    hold on;
    for iloc = 1:n_locations
        r_rms_p2 = [twiss_p2_instantaneous(iloc,:).r_rms];
        times_p2 = [twiss_p2_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(r_rms_p2);
        if sum(valid) > 2
            plot(times_p2(valid), r_rms_p2(valid), 's-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'MarkerSize', 6);
            r_mean = twiss_p2_averaged(iloc).r_rms_mean;
            plot([min(times_p2) max(times_p2)], [r_mean r_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('r_{rms} (mm)', 'FontSize', 12);
    title('Pulse 2: RMS Radius Oscillations', 'FontSize', 14);
    grid on;
    
    %% Plot 7: Oscillation amplitude analysis
    subplot(3,3,7);
    hold on;
    
    % Calculate oscillation amplitude for each location
    osc_amp_beta_p1 = zeros(n_locations, 1);
    osc_amp_beta_p2 = zeros(n_locations, 1);
    
    for iloc = 1:n_locations
        beta_p1 = [twiss_p1_instantaneous(iloc,:).beta];
        beta_p2 = [twiss_p2_instantaneous(iloc,:).beta];
        
        valid_p1 = ~isnan(beta_p1);
        valid_p2 = ~isnan(beta_p2);
        
        if sum(valid_p1) >= 3
            osc_amp_beta_p1(iloc) = (max(beta_p1(valid_p1)) - min(beta_p1(valid_p1))) / ...
                                    mean(beta_p1(valid_p1));
        end
        if sum(valid_p2) >= 3
            osc_amp_beta_p2(iloc) = (max(beta_p2(valid_p2)) - min(beta_p2(valid_p2))) / ...
                                    mean(beta_p2(valid_p2));
        end
    end
    
    bar(1:n_locations, [osc_amp_beta_p1, osc_amp_beta_p2]*100, 'grouped');
    set(gca, 'XTickLabel', location_names);
    ylabel('Oscillation Amplitude (% of mean)', 'FontSize', 12);
    title('Beta Function Oscillation Amplitude', 'FontSize', 14);
    legend('Pulse 1', 'Pulse 2');
    grid on;
    
    %% Plot 8: Phase-averaged comparison - Beta
    subplot(3,3,8);
    z_vals = [twiss_p1_averaged.z_mm];
    beta_p1_mean = [twiss_p1_averaged.beta_mean];
    beta_p1_std = [twiss_p1_averaged.beta_std];
    beta_p2_mean = [twiss_p2_averaged.beta_mean];
    beta_p2_std = [twiss_p2_averaged.beta_std];
    
    hold on;
    errorbar(z_vals, beta_p1_mean, beta_p1_std, 'b-o', 'LineWidth', 2, ...
             'MarkerSize', 8, 'DisplayName', 'P1 (averaged)');
    errorbar(z_vals, beta_p2_mean, beta_p2_std, 'r-s', 'LineWidth', 2, ...
             'MarkerSize', 8, 'DisplayName', 'P2 (averaged)');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Phase-Averaged Beta Function', 'FontSize', 14);
    legend('Location', 'best');
    xlim([0 8310]);
    grid on;
    
    %% Plot 9: Phase-averaged comparison - Alpha
    subplot(3,3,9);
    alpha_p1_mean = [twiss_p1_averaged.alpha_mean];
    alpha_p1_std = [twiss_p1_averaged.alpha_std];
    alpha_p2_mean = [twiss_p2_averaged.alpha_mean];
    alpha_p2_std = [twiss_p2_averaged.alpha_std];
    
    hold on;
    errorbar(z_vals, alpha_p1_mean, alpha_p1_std, 'b-o', 'LineWidth', 2, ...
             'MarkerSize', 8, 'DisplayName', 'P1 (averaged)');
    errorbar(z_vals, alpha_p2_mean, alpha_p2_std, 'r-s', 'LineWidth', 2, ...
             'MarkerSize', 8, 'DisplayName', 'P2 (averaged)');
    yline(0, 'k--', 'LineWidth', 1);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Phase-Averaged Alpha Parameter', 'FontSize', 14);
    legend('Location', 'best');
    xlim([0 8310]);
    grid on;
    
    sgtitle('Betatron-Averaged Twiss Analysis: Removing Phase Sampling Artifacts', ...
            'FontSize', 16);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 31 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== STEP 6: QUANTITATIVE COMPARISON WITH ERROR BARS ====================

if exist('twiss_p1_averaged', 'var') && exist('twiss_p2_averaged', 'var')
    
    figure('Position', [100, 100, 1600, 900], ...
           'Name', 'Phase-Averaged Pulse Comparison (Robust)');
    
    z_vals = [twiss_p1_averaged.z_mm];
    
    %% Plot 1: RMS Radius with statistical uncertainty
    subplot(2,3,1);
    r1_mean = [twiss_p1_averaged.r_rms_mean];
    r1_std = [twiss_p1_averaged.r_rms_std];
    r2_mean = [twiss_p2_averaged.r_rms_mean];
    r2_std = [twiss_p2_averaged.r_rms_std];
    
    hold on;
    errorbar(z_vals, r1_mean, r1_std, 'b-o', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'Pulse 1');
    errorbar(z_vals, r2_mean, r2_std, 'r-s', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'Pulse 2');
    yline(50, 'm--', 'LineWidth', 2, 'DisplayName', 'Target');
    
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r_{rms} (mm)', 'FontSize', 12);
    title('Phase-Averaged RMS Radius', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    %% Plot 2: Statistical significance test
    subplot(2,3,2);
    
    % Calculate if differences are statistically significant
    % Using pooled standard deviation for 2-sample test
    significance = zeros(n_locations, 1);
    
    for iloc = 1:n_locations
        r1_m = twiss_p1_averaged(iloc).r_rms_mean;
        r1_s = twiss_p1_averaged(iloc).r_rms_std;
        r2_m = twiss_p2_averaged(iloc).r_rms_mean;
        r2_s = twiss_p2_averaged(iloc).r_rms_std;
        n = N_SNAPSHOTS;
        
        % Pooled standard error
        se_pooled = sqrt(r1_s^2/n + r2_s^2/n);
        
        % t-statistic
        if se_pooled > 0
            t_stat = abs(r2_m - r1_m) / se_pooled;
            significance(iloc) = t_stat;  % >2 is significant at 95% level
        else
            significance(iloc) = 0;
        end
    end
    
    bar(1:n_locations, significance);
    set(gca, 'XTickLabel', location_names);
    yline(2, 'r--', 'LineWidth', 2, 'Label', '95% significance');
    ylabel('t-statistic', 'FontSize', 12);
    title('Statistical Significance of P2-P1 Difference', 'FontSize', 14);
    grid on;
    
    %% Plot 3: Difference with error propagation
    subplot(2,3,3);
    delta_r = r2_mean - r1_mean;
    delta_r_error = sqrt(r1_std.^2 + r2_std.^2);  % Error propagation
    
    errorbar(z_vals, delta_r, delta_r_error, 'ko-', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'MarkerFaceColor', 'k');
    hold on;
    yline(0, 'r--', 'LineWidth', 2);
    
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('Δr_{rms} = r₂ - r₁ (mm)', 'FontSize', 12);
    title('Pulse 2 - Pulse 1 with Uncertainty', 'FontSize', 14);
    grid on;
    xlim([0 8310]);
    
    % Shade regions of significant difference
    for iloc = 1:n_locations
        if significance(iloc) > 2
            y_range = ylim;
            patch([z_vals(iloc)-50, z_vals(iloc)+50, z_vals(iloc)+50, z_vals(iloc)-50], ...
                  [y_range(1), y_range(1), y_range(2), y_range(2)], ...
                  'yellow', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        end
    end
    
    %% Plot 4: Beta comparison with error bars
    subplot(2,3,4);
    beta1_mean = [twiss_p1_averaged.beta_mean];
    beta1_std = [twiss_p1_averaged.beta_std];
    beta2_mean = [twiss_p2_averaged.beta_mean];
    beta2_std = [twiss_p2_averaged.beta_std];
    
    hold on;
    errorbar(z_vals, beta1_mean, beta1_std, 'b-o', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'P1');
    errorbar(z_vals, beta2_mean, beta2_std, 'r-s', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'P2');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Phase-Averaged Beta Function', 'FontSize', 14);
    legend('Location', 'best');
    xlim([0 8310]);
    grid on;
    
    %% Plot 5: Alpha comparison
    subplot(2,3,5);
    alpha1_mean = [twiss_p1_averaged.alpha_mean];
    alpha1_std = [twiss_p1_averaged.alpha_std];
    alpha2_mean = [twiss_p2_averaged.alpha_mean];
    alpha2_std = [twiss_p2_averaged.alpha_std];
    
    hold on;
    errorbar(z_vals, alpha1_mean, alpha1_std, 'b-o', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'P1');
    errorbar(z_vals, alpha2_mean, alpha2_std, 'r-s', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'P2');
    yline(0, 'k--', 'LineWidth', 1);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Phase-Averaged Alpha Parameter', 'FontSize', 14);
    legend('Location', 'best');
    xlim([0 8310]);
    grid on;
    
    %% Plot 6: Summary table with significance
    subplot(2,3,6);
    axis off;
    
    text(0.1, 0.95, 'PHASE-AVERAGED COMPARISON', 'FontWeight', 'bold', 'FontSize', 14);
    text(0.1, 0.88, 'Exit Plane (z=2700mm):', 'FontWeight', 'bold', 'FontSize', 12);
    
    y_pos = 0.78;
    
    % Beta
    text(0.1, y_pos, 'β (m):', 'FontSize', 11);
    text(0.30, y_pos, sprintf('%.3f±%.3f', beta1_mean(end), beta1_std(end)), ...
         'FontSize', 11, 'Color', 'blue');
    text(0.50, y_pos, sprintf('%.3f±%.3f', beta2_mean(end), beta2_std(end)), ...
         'FontSize', 11, 'Color', 'red');
    delta_beta = beta2_mean(end) - beta1_mean(end);
    text(0.70, y_pos, sprintf('Δ=%.3f', delta_beta), 'FontSize', 11);
    y_pos = y_pos - 0.10;
    
    % Alpha
    text(0.1, y_pos, 'α:', 'FontSize', 11);
    text(0.30, y_pos, sprintf('%.3f±%.3f', alpha1_mean(end), alpha1_std(end)), ...
         'FontSize', 11, 'Color', 'blue');
    text(0.50, y_pos, sprintf('%.3f±%.3f', alpha2_mean(end), alpha2_std(end)), ...
         'FontSize', 11, 'Color', 'red');
    delta_alpha = alpha2_mean(end) - alpha1_mean(end);
    text(0.70, y_pos, sprintf('Δ=%.3f', delta_alpha), 'FontSize', 11);
    y_pos = y_pos - 0.10;
    
    % RMS radius
    text(0.1, y_pos, 'r_rms (mm):', 'FontSize', 11);
    text(0.30, y_pos, sprintf('%.2f±%.2f', r1_mean(end), r1_std(end)), ...
         'FontSize', 11, 'Color', 'blue');
    text(0.50, y_pos, sprintf('%.2f±%.2f', r2_mean(end), r2_std(end)), ...
         'FontSize', 11, 'Color', 'red');
    delta_r = r2_mean(end) - r1_mean(end);
    text(0.70, y_pos, sprintf('Δ=%.2f', delta_r), 'FontSize', 11, 'FontWeight', 'bold');
    y_pos = y_pos - 0.10;
    
    % Statistical significance
    text(0.1, y_pos, 'Significance:', 'FontSize', 11, 'FontWeight', 'bold');
    if significance(end) > 2
        text(0.40, y_pos, sprintf('t=%.2f (SIGNIFICANT)', significance(end)), ...
             'FontSize', 11, 'Color', 'red', 'FontWeight', 'bold');
    else
        text(0.40, y_pos, sprintf('t=%.2f (within noise)', significance(end)), ...
             'FontSize', 11, 'Color', 'green');
    end
    y_pos = y_pos - 0.12;
    
    % Interpretation
    text(0.1, y_pos, 'INTERPRETATION:', 'FontWeight', 'bold', 'FontSize', 11);
    y_pos = y_pos - 0.08;
    
    if significance(end) > 2
        text(0.1, y_pos, '✓ Real P1→P2 difference detected', 'FontSize', 10, 'Color', 'red');
        y_pos = y_pos - 0.06;
        if delta_r < -0.3
            text(0.1, y_pos, '→ P2 is TIGHTER (focusing effect)', 'FontSize', 10);
        elseif delta_r > 0.3
            text(0.1, y_pos, '→ P2 is WIDER (defocusing effect)', 'FontSize', 10);
        end
    else
        text(0.1, y_pos, '✓ No significant P1-P2 difference', 'FontSize', 10, 'Color', 'green');
        y_pos = y_pos - 0.06;
        text(0.1, y_pos, '→ Betatron phase averaging successful!', 'FontSize', 10);
    end
    
    sgtitle(sprintf('Robust Pulse Comparison: %d Snapshots Per Pulse', N_SNAPSHOTS), ...
            'FontSize', 16);
end

%% ==================== STEP 7: BETATRON WAVELENGTH ANALYSIS ====================

if exist('twiss_p1_averaged', 'var')
    
    fprintf('\n=== BETATRON WAVELENGTH ESTIMATION ===\n');
    
    for iloc = 1:n_locations
        beta_val = twiss_p1_averaged(iloc).beta_mean;
        lambda_beta = 2 * pi * beta_val;  % meters
        
        fprintf('%s (z=%d mm):\n', location_names{iloc}, analysis_locations(iloc));
        fprintf('  β = %.3f m → λ_β = %.2f m\n', beta_val, lambda_beta);
        fprintf('  Expected oscillation period: ~%.1f ns at v≈0.94c\n', ...
                lambda_beta / (0.94 * c) * 1e9);
        
        % Check if our snapshot spacing captured the oscillation
        beta_all = [twiss_p1_instantaneous(iloc,:).beta];
        valid = ~isnan(beta_all);
        if sum(valid) >= 3
            beta_pk2pk = max(beta_all(valid)) - min(beta_all(valid));
            fprintf('  Observed β variation: %.3f m (%.1f%% of mean)\n', ...
                    beta_pk2pk, 100*beta_pk2pk/beta_val);
        end
    end
end

%%%%%%%%%%%%%%%%%%%%%%% Added Conditional Save 01.26.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== CONDITIONAL TWISS SAVE (ROBUST) ====================
% Save based on what mode we're in and what data exists

if ENABLE_MULTIPULSE -- true
    % Multi-pulse mode: save P1 and P2 if both exist
    if exist('twiss_p1_averaged', 'var') && exist('twiss_p2_averaged', 'var')
        save('twiss_betatron_averaged_results.mat', ...
             'twiss_p1_averaged', 'twiss_p2_averaged', ...
             'twiss_p1_instantaneous', 'twiss_p2_instantaneous', ...
             'snapshot_p1', 'snapshot_p2', ...
             'analysis_locations', 'location_names', ...
             'SNAPSHOT_P1_TIMES', 'SNAPSHOT_P2_TIMES', ...
             'SNAPSHOT_P3_TIMES', 'SNAPSHOT_P4_TIMES');
        fprintf('\n✓ Multi-pulse betatron-averaged Twiss saved (both pulses)\n');
 %%%%%%%%%%%%%%%%%%%%%% Added 02.09.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
         % Pulse 3 data (NEW)
if exist('steady_state_beam_pulse3', 'var')
    vars_to_save{end+1} = 'steady_state_beam_pulse3';
    fprintf('  Including Pulse 3 snapshot\n');
end

if exist('twiss_results_pulse3', 'var')
    vars_to_save{end+1} = 'twiss_results_pulse3';
    fprintf('  Including Pulse 3 Twiss analysis\n');
end

if exist('snapshot_p3', 'var') && snapshot_p3_count > 0
    vars_to_save{end+1} = 'snapshot_p3';
    fprintf('  Including Pulse 3 betatron snapshots (%d)\n', snapshot_p3_count);
end

if exist('twiss_p3_averaged', 'var')
    vars_to_save{end+1} = 'twiss_p3_averaged';
    vars_to_save{end+1} = 'twiss_p3_instantaneous';
    fprintf('  Including Pulse 3 betatron-averaged Twiss\n');
end
 %%%%%%%%%%%%%%%%%%%%%% Added 02.09.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Pulse 4 data (NEW)
if exist('steady_state_beam_pulse4', 'var')
    vars_to_save{end+1} = 'steady_state_beam_pulse4';
    fprintf('  Including Pulse 4 snapshot\n');
end

if exist('twiss_results_pulse4', 'var')
    vars_to_save{end+1} = 'twiss_results_pulse4';
    fprintf('  Including Pulse 4 Twiss analysis\n');
end

if exist('snapshot_p4', 'var') && snapshot_p4_count > 0
    vars_to_save{end+1} = 'snapshot_p4';
    fprintf('  Including Pulse 4 betatron snapshots (%d)\n', snapshot_p4_count);
end

if exist('twiss_p4_averaged', 'var')
    vars_to_save{end+1} = 'twiss_p4_averaged';
    vars_to_save{end+1} = 'twiss_p4_instantaneous';
    fprintf('  Including Pulse 4 betatron-averaged Twiss\n');
end
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
    elseif exist('twiss_p1_averaged', 'var')
        % Only P1 exists (P2 not simulated yet)
        save('twiss_betatron_averaged_p1_only.mat', ...
             'twiss_p1_averaged', 'twiss_p1_instantaneous', ...
             'snapshot_p1', 'analysis_locations', 'location_names', ...
             'SNAPSHOT_P1_TIMES');
        fprintf('\n✓ Betatron-averaged Twiss saved (Pulse 1 only)\n');
        fprintf('  Note: Pulse 2 not yet analyzed\n');
    else
        fprintf('\nWARNING: No Twiss data to save (multi-pulse mode)\n');
    end
    
else
    % Single-pulse mode: check for intra-pulse analysis
    if exist('twiss_early_averaged', 'var') && exist('twiss_late_averaged', 'var')
        % Intra-pulse data exists - already saved above
        fprintf('\n✓ Intra-pulse ion focusing analysis already saved\n');
        
    elseif exist('twiss_p1_averaged', 'var')
        % Legacy single-snapshot Pulse 1 data
        save('twiss_betatron_averaged_p1_results.mat', ...
             'twiss_p1_averaged', 'twiss_p1_instantaneous', ...
             'snapshot_p1', 'analysis_locations', 'location_names', ...
             'SNAPSHOT_P1_TIMES');
        fprintf('\n✓ Single-pulse betatron-averaged Twiss saved\n');
    else
        fprintf('\nINFO: No betatron-averaged Twiss data to save\n');
        fprintf('  (ENABLE_BETATRON_AVERAGING may be disabled)\n');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== STEP 8: EXPORT RESULTS TABLE ====================

if exist('twiss_p1_averaged', 'var') && exist('twiss_p2_averaged', 'var')
    
    % Create publication-ready table
    fprintf('\n=== PHASE-AVERAGED TWISS PARAMETERS (EXPORT) ===\n');
    fprintf('%-12s | %12s | %12s | %12s | %12s\n', ...
            'Location', 'β (m)', 'α', 'r_rms (mm)', 'Significance');
    fprintf('%-12s-+-%-12s-+-%-12s-+-%-12s-+-%-12s\n', ...
            repmat('-',1,12), repmat('-',1,12), repmat('-',1,12), ...
            repmat('-',1,12), repmat('-',1,12));
    
    for iloc = 1:n_locations
        loc_name = location_names{iloc};
        
        % Pulse 1
        fprintf('%-12s | %5.3f±%.3f | %5.3f±%.3f | %5.1f±%.1f | %-12s\n', ...
                [loc_name ' P1'], ...
                twiss_p1_averaged(iloc).beta_mean, twiss_p1_averaged(iloc).beta_std, ...
                twiss_p1_averaged(iloc).alpha_mean, twiss_p1_averaged(iloc).alpha_std, ...
                twiss_p1_averaged(iloc).r_rms_mean, twiss_p1_averaged(iloc).r_rms_std, ...
                twiss_p1_averaged(iloc).condition);
        
        % Pulse 2
        sig_marker = '';
        if significance(iloc) > 2
            sig_marker = '***';
        elseif significance(iloc) > 1.5
            sig_marker = '*';
        end
        
        fprintf('%-12s | %5.3f±%.3f | %5.3f±%.3f | %5.1f±%.1f | t=%.2f %s\n', ...
                [loc_name ' P2'], ...
                twiss_p2_averaged(iloc).beta_mean, twiss_p2_averaged(iloc).beta_std, ...
                twiss_p2_averaged(iloc).alpha_mean, twiss_p2_averaged(iloc).alpha_std, ...
                twiss_p2_averaged(iloc).r_rms_mean, twiss_p2_averaged(iloc).r_rms_std, ...
                significance(iloc), sig_marker);
        fprintf('\n');
    end
    
    fprintf('*** = statistically significant difference (t > 2.0)\n');
    fprintf('* = marginally significant (t > 1.5)\n');
end
%%%%%%%%%%%%%%%%%%%%%% Added Figure 32 of comparison Pulse 1 and Pulse 3 %%%%%%%%%%%%%
%% ==================== FIGURE: P1 vs P3 DETAILED TWISS COMPARISON ====================
if exist('twiss_p1_averaged', 'var') && exist('twiss_p3_averaged', 'var')
    
    figure('Position', [100, 100, 1800, 1200], ...
           'Name', 'Test 70: Pulse 1 vs Pulse 3 Ion Focusing Analysis');
    
    % Extract data
    z_vals = [twiss_p1_averaged.z_mm];
    n_locations = length(z_vals);
    
    % P1 data
    beta_p1 = [twiss_p1_averaged.beta_mean];
    beta_p1_std = [twiss_p1_averaged.beta_std];
    alpha_p1 = [twiss_p1_averaged.alpha_mean];
    alpha_p1_std = [twiss_p1_averaged.alpha_std];
    r_p1 = [twiss_p1_averaged.r_rms_mean];
    r_p1_std = [twiss_p1_averaged.r_rms_std];
    emit_p1 = [twiss_p1_averaged.emit_mean];
    emit_p1_std = [twiss_p1_averaged.emit_std];
    
    % P3 data
    beta_p3 = [twiss_p3_averaged.beta_mean];
    beta_p3_std = [twiss_p3_averaged.beta_std];
    alpha_p3 = [twiss_p3_averaged.alpha_mean];
    alpha_p3_std = [twiss_p3_averaged.alpha_std];
    r_p3 = [twiss_p3_averaged.r_rms_mean];
    r_p3_std = [twiss_p3_averaged.r_rms_std];
    emit_p3 = [twiss_p3_averaged.emit_mean];
    emit_p3_std = [twiss_p3_averaged.emit_std];
    
    % Calculate differences and statistical significance
    delta_beta = beta_p3 - beta_p1;
    delta_alpha = alpha_p3 - alpha_p1;
    delta_r = r_p3 - r_p1;
    delta_emit = emit_p3 - emit_p1;
    
    % T-statistics for each location
    t_stat = zeros(n_locations, 1);
    for iloc = 1:n_locations
        se_pooled = sqrt(r_p1_std(iloc)^2/N_SNAPSHOTS + r_p3_std(iloc)^2/N_SNAPSHOTS);
        if se_pooled > 0
            t_stat(iloc) = abs(delta_r(iloc)) / se_pooled;
        end
    end
    
    %% ===== PLOT 1: Beta Function Comparison =====
    subplot(3,3,1);
    hold on;
    errorbar(z_vals, beta_p1, beta_p1_std, 'b-o', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P1 (0 ions)');
    errorbar(z_vals, beta_p3, beta_p3_std, 'r-s', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P3 (8.4B ions)');
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('β (m)', 'FontSize', 13);
    title('Beta Function Evolution', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    xlim([0 8310]);
    
    %% ===== PLOT 2: Alpha Parameter Comparison =====
    subplot(3,3,2);
    hold on;
    errorbar(z_vals, alpha_p1, alpha_p1_std, 'b-o', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P1');
    errorbar(z_vals, alpha_p3, alpha_p3_std, 'r-s', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P3');
    yline(0, 'k--', 'LineWidth', 2, 'DisplayName', 'Collimated');
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('α', 'FontSize', 13);
    title('Alpha Parameter (Convergence)', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    xlim([0 8310]);
    
    %% ===== PLOT 3: RMS Radius Comparison =====
    subplot(3,3,3);
    hold on;
    errorbar(z_vals, r_p1, r_p1_std, 'b-o', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P1');
    errorbar(z_vals, r_p3, r_p3_std, 'r-s', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P3');
    yline(50, 'm--', 'LineWidth', 2, 'DisplayName', 'Target');
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('r_{rms} (mm)', 'FontSize', 13);
    title('Beam Envelope Evolution', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    xlim([0 8310]);
    ylim([0 80]);
    
    %% ===== PLOT 4: Beta Difference (P3-P1) =====
    subplot(3,3,4);
    delta_beta_err = sqrt(beta_p1_std.^2 + beta_p3_std.^2);
    errorbar(z_vals, delta_beta, delta_beta_err, 'ko-', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'MarkerFaceColor', 'k');
    hold on;
    yline(0, 'r--', 'LineWidth', 2);
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('Δβ = β₃ - β₁ (m)', 'FontSize', 13);
    title('Ion-Induced Beta Change', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    xlim([0 8310]);
    
    %% ===== PLOT 5: Alpha Difference (P3-P1) =====
    subplot(3,3,5);
    delta_alpha_err = sqrt(alpha_p1_std.^2 + alpha_p3_std.^2);
    errorbar(z_vals, delta_alpha, delta_alpha_err, 'ko-', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'MarkerFaceColor', 'k');
    hold on;
    yline(0, 'r--', 'LineWidth', 2);
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('Δα = α₃ - α₁', 'FontSize', 13);
    title('Ion-Induced Alpha Change', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    xlim([0 8310]);
    
    %% ===== PLOT 6: Radius Difference with Significance Shading =====
    subplot(3,3,6);
    delta_r_err = sqrt(r_p1_std.^2 + r_p3_std.^2);
    errorbar(z_vals, delta_r, delta_r_err, 'ko-', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'MarkerFaceColor', 'k');
    hold on;
    yline(0, 'r--', 'LineWidth', 2);
    
    % Shade regions of statistical significance
    y_range = ylim;
    for iloc = 1:n_locations
        if t_stat(iloc) > 2.0
            % Highly significant - yellow background
            patch([z_vals(iloc)-50, z_vals(iloc)+50, z_vals(iloc)+50, z_vals(iloc)-50], ...
                  [y_range(1), y_range(1), y_range(2), y_range(2)], ...
                  'yellow', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            % Red marker
            plot(z_vals(iloc), delta_r(iloc), 'ro', 'MarkerSize', 14, ...
                 'LineWidth', 3, 'MarkerFaceColor', 'red');
        end
    end
    
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('Δr_{rms} = r₃ - r₁ (mm)', 'FontSize', 13);
    title('Ion-Induced Radius Change', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Difference', 'Zero line', 'Significant (t>2)', 'Location', 'best');
    grid on;
    xlim([0 8310]);
    
    %% ===== PLOT 7: Statistical Significance Bars =====
    subplot(3,3,7);
    bar(1:n_locations, t_stat, 'FaceColor', [0.3 0.6 0.9], 'EdgeColor', 'k', 'LineWidth', 1.5);
    hold on;
    yline(2.0, 'r--', 'LineWidth', 3, 'Label', '95% significance');
    yline(3.0, 'g--', 'LineWidth', 2, 'Label', '99% significance');
    set(gca, 'XTickLabel', location_names, 'FontSize', 12);
    ylabel('t-statistic', 'FontSize', 13);
    title('Statistical Significance Test', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    
    % Color bars by significance
    for iloc = 1:n_locations
        if t_stat(iloc) > 3.0
            bar(iloc, t_stat(iloc), 'FaceColor', 'green');
        elseif t_stat(iloc) > 2.0
            bar(iloc, t_stat(iloc), 'FaceColor', 'yellow');
        else
            bar(iloc, t_stat(iloc), 'FaceColor', [0.7 0.7 0.7]);
        end
    end
    
    %% ===== PLOT 8: Emittance Comparison =====
    subplot(3,3,8);
    hold on;
    errorbar(z_vals, emit_p1, emit_p1_std, 'b-o', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P1');
    errorbar(z_vals, emit_p3, emit_p3_std, 'r-s', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P3');
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('ε_n (mm-mrad)', 'FontSize', 13);
    title('Normalized Emittance', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    xlim([0 8310]);
    
    %% ===== PLOT 9: Summary Table =====
    subplot(3,3,9);
    axis off;
    
    text(0.5, 0.95, 'ION FOCUSING SUMMARY', 'FontWeight', 'bold', 'FontSize', 16, ...
         'HorizontalAlignment', 'center');
    text(0.5, 0.88, 'Exit Plane (z=2700mm)', 'FontWeight', 'bold', 'FontSize', 14, ...
         'HorizontalAlignment', 'center', 'Color', [0.2 0.2 0.7]);
    
    y_pos = 0.75;
    
    % Radius change
    text(0.1, y_pos, sprintf('Δr_{rms} = %.3f ± %.3f mm', ...
         delta_r(end), delta_r_err(end)), 'FontSize', 13, 'FontWeight', 'bold');
    y_pos = y_pos - 0.08;
    
    percent_change = 100 * delta_r(end) / r_p1(end);
    text(0.15, y_pos, sprintf('(%.1f%% change)', percent_change), 'FontSize', 12);
    y_pos = y_pos - 0.10;
    
    % Statistical significance
    text(0.1, y_pos, sprintf('Significance: t = %.2f', t_stat(end)), ...
         'FontSize', 13, 'FontWeight', 'bold');
    y_pos = y_pos - 0.08;
    
    if t_stat(end) > 3.0
        text(0.15, y_pos, '✓ HIGHLY SIGNIFICANT (99%)', 'FontSize', 12, ...
             'Color', 'green', 'FontWeight', 'bold');
    elseif t_stat(end) > 2.0
        text(0.15, y_pos, '✓ SIGNIFICANT (95%)', 'FontSize', 12, ...
             'Color', [0.8 0.6 0], 'FontWeight', 'bold');
    else
        text(0.15, y_pos, '○ Not significant', 'FontSize', 12, 'Color', 'red');
    end
    y_pos = y_pos - 0.12;
    
    % Comparison with expected (2× P2-P1 effect)
    text(0.1, y_pos, 'SCALING CHECK:', 'FontWeight', 'bold', 'FontSize', 12);
    y_pos = y_pos - 0.08;
    
    if exist('twiss_p2_averaged', 'var')
        r_p2 = [twiss_p2_averaged.r_rms_mean];
        delta_r_p2 = r_p2(end) - r_p1(end);
        scaling_ratio = delta_r(end) / delta_r_p2;
        
        text(0.1, y_pos, sprintf('P2-P1: Δr = %.3f mm', delta_r_p2), 'FontSize', 11);
        y_pos = y_pos - 0.06;
        text(0.1, y_pos, sprintf('P3-P1: Δr = %.3f mm', delta_r(end)), 'FontSize', 11);
        y_pos = y_pos - 0.06;
        text(0.1, y_pos, sprintf('Ratio: %.2f (expected 2.0)', scaling_ratio), ...
             'FontSize', 11, 'FontWeight', 'bold');
        y_pos = y_pos - 0.08;
        
        if abs(scaling_ratio - 2.0) < 0.3
            text(0.1, y_pos, '✓ Linear scaling confirmed!', 'FontSize', 11, 'Color', 'green');
        elseif scaling_ratio < 1.5
            text(0.1, y_pos, '⚠ Saturation detected', 'FontSize', 11, 'Color', 'red');
        else
            text(0.1, y_pos, '⚠ Super-linear growth', 'FontSize', 11, 'Color', 'red');
        end
    end
    
    y_pos = y_pos - 0.12;
    
    % Emittance change
    delta_emit_percent = 100 * (emit_p3(end) - emit_p1(end)) / emit_p1(end);
    text(0.1, y_pos, sprintf('Δε_n = %.1f%%', delta_emit_percent), ...
         'FontSize', 12, 'FontWeight', 'bold');
    
    if delta_emit_percent < -10
        y_pos = y_pos - 0.06;
        text(0.15, y_pos, '→ Ion focusing reduces emittance!', 'FontSize', 10, 'Color', 'green');
    end
    
    % Overall title
    sgtitle(sprintf('Test 70: P1 vs P3 Ion Focusing Analysis (8.4B ions, %d snapshots/pulse)', ...
                    N_SNAPSHOTS), 'FontSize', 18, 'FontWeight', 'bold');
    
    % Save figure
    saveas(gcf, 'Test70_P1_vs_P3_Twiss_Comparison.fig');
    saveas(gcf, 'Test70_P1_vs_P3_Twiss_Comparison.png');
    fprintf('\n✓ P1 vs P3 comparison figure saved\n');
end
%%%%%%%%%%%%%%%%%%%%%%%%% Added Figure 33 02.03.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== BETATRON OSCILLATION ANALYSIS: P1 vs P3 ====================
if exist('twiss_p1_averaged', 'var') && exist('twiss_p3_averaged', 'var') && ...
   exist('twiss_p1_instantaneous', 'var') && exist('twiss_p3_instantaneous', 'var')
    
    figure('Position', [100, 100, 1800, 1200], ...
           'Name', 'Test 70: Betatron Oscillations P1 vs P3');
    
    % Use same colors for locations
    colors = lines(n_locations);
    
    %% ===== ROW 1: PULSE 1 OSCILLATIONS =====
    
    % Plot 1: P1 Beta oscillations
    subplot(3,3,1);
    hold on;
    for iloc = 1:n_locations
        beta_p1 = [twiss_p1_instantaneous(iloc,:).beta];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(beta_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), beta_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'DisplayName', location_names{iloc});
            % Add mean line
            beta_mean = twiss_p1_averaged(iloc).beta_mean;
            plot([min(times_p1) max(times_p1)], [beta_mean beta_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Pulse 1: Beta Function Oscillations', 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    
    % Plot 2: P1 Alpha oscillations
    subplot(3,3,2);
    hold on;
    for iloc = 1:n_locations
        alpha_p1 = [twiss_p1_instantaneous(iloc,:).alpha];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(alpha_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), alpha_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2);
            alpha_mean = twiss_p1_averaged(iloc).alpha_mean;
            plot([min(times_p1) max(times_p1)], [alpha_mean alpha_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    yline(0, 'k:', 'LineWidth', 1.5);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Pulse 1: Alpha Parameter Oscillations', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % Plot 3: P1 RMS radius oscillations
    subplot(3,3,3);
    hold on;
    for iloc = 1:n_locations
        r_rms_p1 = [twiss_p1_instantaneous(iloc,:).r_rms];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(r_rms_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), r_rms_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'MarkerSize', 6);
            r_mean = twiss_p1_averaged(iloc).r_rms_mean;
            plot([min(times_p1) max(times_p1)], [r_mean r_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('r_{rms} (mm)', 'FontSize', 12);
    title('Pulse 1: RMS Radius Oscillations', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    %% ===== ROW 2: PULSE 3 OSCILLATIONS =====
    
    % Plot 4: P3 Beta oscillations
    subplot(3,3,4);
    hold on;
    for iloc = 1:n_locations
        beta_p3 = [twiss_p3_instantaneous(iloc,:).beta];
        times_p3 = [twiss_p3_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(beta_p3);
        
        if sum(valid) > 2
            plot(times_p3(valid), beta_p3(valid), 's-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'MarkerSize', 6);
            beta_mean = twiss_p3_averaged(iloc).beta_mean;
            plot([min(times_p3) max(times_p3)], [beta_mean beta_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Pulse 3: Beta Function Oscillations', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % Plot 5: P3 Alpha oscillations
    subplot(3,3,5);
    hold on;
    for iloc = 1:n_locations
        alpha_p3 = [twiss_p3_instantaneous(iloc,:).alpha];
        times_p3 = [twiss_p3_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(alpha_p3);
        
        if sum(valid) > 2
            plot(times_p3(valid), alpha_p3(valid), 's-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'MarkerSize', 6);
            alpha_mean = twiss_p3_averaged(iloc).alpha_mean;
            plot([min(times_p3) max(times_p3)], [alpha_mean alpha_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    yline(0, 'k:', 'LineWidth', 1.5);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Pulse 3: Alpha Parameter Oscillations', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % Plot 6: P3 RMS radius oscillations
    subplot(3,3,6);
    hold on;
    for iloc = 1:n_locations
        r_rms_p3 = [twiss_p3_instantaneous(iloc,:).r_rms];
        times_p3 = [twiss_p3_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(r_rms_p3);
        
        if sum(valid) > 2
            plot(times_p3(valid), r_rms_p3(valid), 's-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'MarkerSize', 6);
            r_mean = twiss_p3_averaged(iloc).r_rms_mean;
            plot([min(times_p3) max(times_p3)], [r_mean r_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('r_{rms} (mm)', 'FontSize', 12);
    title('Pulse 3: RMS Radius Oscillations', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    %% ===== ROW 3: PHASE-AVERAGED COMPARISONS =====
    
    % Plot 7: Oscillation amplitude comparison
    subplot(3,3,7);
    hold on;
    
    % Calculate oscillation amplitudes
    osc_amp_beta_p1 = zeros(n_locations, 1);
    osc_amp_beta_p3 = zeros(n_locations, 1);
    
    for iloc = 1:n_locations
        beta_p1 = [twiss_p1_instantaneous(iloc,:).beta];
        beta_p3 = [twiss_p3_instantaneous(iloc,:).beta];
        
        valid_p1 = ~isnan(beta_p1);
        valid_p3 = ~isnan(beta_p3);
        
        if sum(valid_p1) >= 3
            osc_amp_beta_p1(iloc) = (max(beta_p1(valid_p1)) - min(beta_p1(valid_p1))) / ...
                                    mean(beta_p1(valid_p1));
        end
        if sum(valid_p3) >= 3
            osc_amp_beta_p3(iloc) = (max(beta_p3(valid_p3)) - min(beta_p3(valid_p3))) / ...
                                    mean(beta_p3(valid_p3));
        end
    end
    
    bar_data = [osc_amp_beta_p1, osc_amp_beta_p3] * 100;
    bar(1:n_locations, bar_data, 'grouped');
    set(gca, 'XTickLabel', location_names, 'FontSize', 11);
    ylabel('Oscillation Amplitude (% of mean)', 'FontSize', 12);
    title('Beta Function Oscillation Amplitude', 'FontSize', 14, 'FontWeight', 'bold');
    legend('Pulse 1', 'Pulse 3', 'FontSize', 11);
    grid on;
    
    % Plot 8: Phase-averaged Beta comparison
    subplot(3,3,8);
    beta_p1_mean = [twiss_p1_averaged.beta_mean];
    beta_p1_std = [twiss_p1_averaged.beta_std];
    beta_p3_mean = [twiss_p3_averaged.beta_mean];
    beta_p3_std = [twiss_p3_averaged.beta_std];
    
    hold on;
    errorbar(z_vals, beta_p1_mean, beta_p1_std, 'b-o', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P1 (averaged)');
    errorbar(z_vals, beta_p3_mean, beta_p3_std, 'r-s', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P3 (averaged)');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Phase-Averaged Beta Function', 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    xlim([0 8310]);
    
    % Plot 9: Phase-averaged Alpha comparison
    subplot(3,3,9);
    alpha_p1_mean = [twiss_p1_averaged.alpha_mean];
    alpha_p1_std = [twiss_p1_averaged.alpha_std];
    alpha_p3_mean = [twiss_p3_averaged.alpha_mean];
    alpha_p3_std = [twiss_p3_averaged.alpha_std];
    
    hold on;
    errorbar(z_vals, alpha_p1_mean, alpha_p1_std, 'b-o', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P1 (averaged)');
    errorbar(z_vals, alpha_p3_mean, alpha_p3_std, 'r-s', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P3 (averaged)');
    yline(0, 'k--', 'LineWidth', 1.5);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Phase-Averaged Alpha Parameter', 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    xlim([0 8310]);
    
    sgtitle('Test 70: Betatron-Averaged Twiss Analysis P1 vs P3 (8.4B ions)', ...
            'FontSize', 18, 'FontWeight', 'bold');
    
    % Save figure
    saveas(gcf, 'Test70_P1_vs_P3_Betatron_Oscillations.fig');
    saveas(gcf, 'Test70_P1_vs_P3_Betatron_Oscillations.png');
    fprintf('\n✓ P1 vs P3 betatron oscillation figure saved\n');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%% Added 02.06.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%STEP 12: P1 vs P4 Betatron Oscillation Figure
%Location: After Figure 33, around line 6550
%Action: Add oscillation visualization
%% ==================== BETATRON OSCILLATION ANALYSIS: P1 vs P4 ====================
if exist('twiss_p1_instantaneous', 'var') && exist('twiss_p4_instantaneous', 'var') &&...
    exist('twiss_p1_instantaneous', 'var') && exist('twiss_p3_instantaneous', 'var')

    figure('Position', [100, 100, 1800, 1200], ...
           'Name', 'Test 68: Betatron Oscillations P1 vs P4');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Use same colors for locations
    colors = lines(n_locations);
    
    %% ===== ROW 1: PULSE 1 OSCILLATIONS =====
    
    % Plot 1: P1 Beta oscillations
    subplot(3,3,1);
    hold on;
    for iloc = 1:n_locations
        beta_p1 = [twiss_p1_instantaneous(iloc,:).beta];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(beta_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), beta_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'DisplayName', location_names{iloc});
            % Add mean line
            beta_mean = twiss_p1_averaged(iloc).beta_mean;
            plot([min(times_p1) max(times_p1)], [beta_mean beta_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Pulse 1: Beta Function Oscillations', 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 9);
    grid on;
    
    % Plot 2: P1 Alpha oscillations
    subplot(3,3,2);
    hold on;
    for iloc = 1:n_locations
        alpha_p1 = [twiss_p1_instantaneous(iloc,:).alpha];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(alpha_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), alpha_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2);
            alpha_mean = twiss_p1_averaged(iloc).alpha_mean;
            plot([min(times_p1) max(times_p1)], [alpha_mean alpha_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    yline(0, 'k:', 'LineWidth', 1.5);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Pulse 1: Alpha Parameter Oscillations', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % Plot 3: P1 RMS radius oscillations
    subplot(3,3,3);
    hold on;
    for iloc = 1:n_locations
        r_rms_p1 = [twiss_p1_instantaneous(iloc,:).r_rms];
        times_p1 = [twiss_p1_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(r_rms_p1);
        
        if sum(valid) > 2
            plot(times_p1(valid), r_rms_p1(valid), 'o-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'MarkerSize', 6);
            r_mean = twiss_p1_averaged(iloc).r_rms_mean;
            plot([min(times_p1) max(times_p1)], [r_mean r_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('r_{rms} (mm)', 'FontSize', 12);
    title('Pulse 1: RMS Radius Oscillations', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    %% ===== ROW 2: PULSE 4 OSCILLATIONS =====
    
    % Plot 4: P4 Beta oscillations
    subplot(3,3,4);
    hold on;
    for iloc = 1:n_locations
        beta_p4 = [twiss_p4_instantaneous(iloc,:).beta];
        times_p4 = [twiss_p4_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(beta_p4);
        
        if sum(valid) > 2
            plot(times_p4(valid), beta_p4(valid), 's-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'MarkerSize', 6);
            beta_mean = twiss_p4_averaged(iloc).beta_mean;
            plot([min(times_p4) max(times_p4)], [beta_mean beta_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Pulse 4: Beta Function Oscillations', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % Plot 5: P4 Alpha oscillations
    subplot(3,3,5);
    hold on;
    for iloc = 1:n_locations
        alpha_p4 = [twiss_p4_instantaneous(iloc,:).alpha];
        times_p4 = [twiss_p4_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(alpha_p4);
        
        if sum(valid) > 2
            plot(times_p4(valid), alpha_p4(valid), 's-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'MarkerSize', 6);
            alpha_mean = twiss_p4_averaged(iloc).alpha_mean;
            plot([min(times_p4) max(times_p4)], [alpha_mean alpha_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    yline(0, 'k:', 'LineWidth', 1.5);
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Pulse 4: Alpha Parameter Oscillations', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    % Plot 6: P4 RMS radius oscillations
    subplot(3,3,6);
    hold on;
    for iloc = 1:n_locations
        r_rms_p4 = [twiss_p4_instantaneous(iloc,:).r_rms];
        times_p4 = [twiss_p4_instantaneous(iloc,:).time] * 1e9;
        valid = ~isnan(r_rms_p4);
        
        if sum(valid) > 2
            plot(times_p4(valid), r_rms_p4(valid), 's-', 'Color', colors(iloc,:), ...
                 'LineWidth', 2, 'MarkerSize', 6);
            r_mean = twiss_p4_averaged(iloc).r_rms_mean;
            plot([min(times_p4) max(times_p4)], [r_mean r_mean], '--', ...
                 'Color', colors(iloc,:), 'LineWidth', 1.5);
        end
    end
    xlabel('Time (ns)', 'FontSize', 12);
    ylabel('r_{rms} (mm)', 'FontSize', 12);
    title('Pulse 4: RMS Radius Oscillations', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    
    %% ===== ROW 4: PHASE-AVERAGED COMPARISONS =====
    % Plot 7: Oscillation amplitude comparison
    subplot(3,3,7);
    hold on;
    
    % Calculate oscillation amplitudes
    osc_amp_beta_p1 = zeros(n_locations, 1);
    osc_amp_beta_p4 = zeros(n_locations, 1);
    
    for iloc = 1:n_locations
        beta_p1 = [twiss_p1_instantaneous(iloc,:).beta];
        beta_p4 = [twiss_p4_instantaneous(iloc,:).beta];
        
        valid_p1 = ~isnan(beta_p1);
        valid_p4 = ~isnan(beta_p4);
        
        if sum(valid_p1) >= 3
            osc_amp_beta_p1(iloc) = (max(beta_p1(valid_p1)) - min(beta_p1(valid_p1))) / ...
                                    mean(beta_p1(valid_p1));
        end
        if sum(valid_p4) >= 3
            osc_amp_beta_p4(iloc) = (max(beta_p4(valid_p4)) - min(beta_p4(valid_p4))) / ...
                                    mean(beta_p4(valid_p4));
        end
    end
    
    bar_data = [osc_amp_beta_p1, osc_amp_beta_p4] * 100;
    bar(1:n_locations, bar_data, 'grouped');
    set(gca, 'XTickLabel', location_names, 'FontSize', 11);
    ylabel('Oscillation Amplitude (% of mean)', 'FontSize', 12);
    title('Beta Function Oscillation Amplitude', 'FontSize', 14, 'FontWeight', 'bold');
    legend('Pulse 1', 'Pulse 4', 'FontSize', 11);
    grid on;
    
    % Plot 8: Phase-averaged Beta comparison
    subplot(3,3,8);
    beta_p1_mean = [twiss_p1_averaged.beta_mean];
    beta_p1_std = [twiss_p1_averaged.beta_std];
    beta_p4_mean = [twiss_p4_averaged.beta_mean];
    beta_p4_std = [twiss_p4_averaged.beta_std];
    
    hold on;
    errorbar(z_vals, beta_p1_mean, beta_p1_std, 'b-o', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P1 (averaged)');
    errorbar(z_vals, beta_p4_mean, beta_p4_std, 'r-s', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P4 (averaged)');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Phase-Averaged Beta Function', 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    xlim([0 8310]);
    
    % Plot 9: Phase-averaged Alpha comparison
    subplot(3,3,9);
    alpha_p1_mean = [twiss_p1_averaged.alpha_mean];
    alpha_p1_std = [twiss_p1_averaged.alpha_std];
    alpha_p4_mean = [twiss_p4_averaged.alpha_mean];
    alpha_p4_std = [twiss_p4_averaged.alpha_std];
    
    hold on;
    errorbar(z_vals, alpha_p1_mean, alpha_p1_std, 'b-o', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P1 (averaged)');
    errorbar(z_vals, alpha_p4_mean, alpha_p4_std, 'r-s', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P3 (averaged)');
    yline(0, 'k--', 'LineWidth', 1.5);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Phase-Averaged Alpha Parameter', 'FontSize', 14, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    xlim([0 8310]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
     sgtitle('Test 70: Betatron-Averaged Twiss P1 vs P4 (12.6B ions)', ...
            'FontSize', 18, 'FontWeight', 'bold');
     % Save figure
     saveas(gcf, 'Test70_P1_vs_P4_Betatron_Oscillations.fig');
     saveas(gcf, 'Test70_P1_vs_P4_Betatron_Oscillations.png');
     fprintf('\n✓ P1 vs P4 betatron oscillation figure saved\n');
end
%%%%%%%%%%%%%%%%%%%%Figure 35 Added 02.06.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%STEP 11: P1 vs P4 Twiss Comparison Figure
%Location: After Figure 32 (P1 vs P3), around line 6380
%Action: Add comprehensive P1 vs P4 comparison
%% ==================== FIGURE: P1 vs P4 DETAILED TWISS COMPARISON ====================
if exist('twiss_p1_averaged', 'var') && exist('twiss_p4_averaged', 'var')
    
    figure('Position', [100, 100, 1800, 1200], ...
           'Name', 'Test 70: Pulse 1 vs Pulse 4 Maximum Ion Focusing');
    
    % Extract data
    z_vals = [twiss_p1_averaged.z_mm];
    
    % P1 data
    beta_p1 = [twiss_p1_averaged.beta_mean];
    beta_p1_std = [twiss_p1_averaged.beta_std];
    alpha_p1 = [twiss_p1_averaged.alpha_mean];
    alpha_p1_std = [twiss_p1_averaged.alpha_std];
    r_p1 = [twiss_p1_averaged.r_rms_mean];
    r_p1_std = [twiss_p1_averaged.r_rms_std];
    emit_p1 = [twiss_p1_averaged.emit_mean];
    
    % P4 data
    beta_p4 = [twiss_p4_averaged.beta_mean];
    beta_p4_std = [twiss_p4_averaged.beta_std];
    alpha_p4 = [twiss_p4_averaged.alpha_mean];
    alpha_p4_std = [twiss_p4_averaged.alpha_std];
    r_p4 = [twiss_p4_averaged.r_rms_mean];
    r_p4_std = [twiss_p4_averaged.r_rms_std];
    emit_p4 = [twiss_p4_averaged.emit_mean];
    
    % Calculate differences
    delta_r = r_p4 - r_p1;
    delta_r_err = sqrt(r_p1_std.^2 + r_p4_std.^2);
    
    % T-statistics
    t_stat = zeros(n_locations, 1);
    for iloc = 1:n_locations
        se = sqrt(r_p1_std(iloc)^2/N_SNAPSHOTS + r_p4_std(iloc)^2/N_SNAPSHOTS);
        if se > 0
            t_stat(iloc) = abs(delta_r(iloc)) / se;
        end
    end
    
    %% Plot 1: Beta comparison
    subplot(3,3,1);
    hold on;
    errorbar(z_vals, beta_p1, beta_p1_std, 'b-o', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'DisplayName', 'P1 (0 ions)');
    errorbar(z_vals, beta_p4, beta_p4_std, 'r-s', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'DisplayName', 'P4 (12.6B ions)');
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('β (m)', 'FontSize', 13);
    title('Beta Function Evolution', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    %% Plot 2: Alpha comparison
    subplot(3,3,2);
    hold on;
    errorbar(z_vals, alpha_p1, alpha_p1_std, 'b-o', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'DisplayName', 'P1');
    errorbar(z_vals, alpha_p4, alpha_p4_std, 'r-s', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'DisplayName', 'P4');
    yline(0, 'k--', 'LineWidth', 2);
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('α', 'FontSize', 13);
    title('Alpha Parameter', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    %% Plot 3: RMS Radius comparison
    subplot(3,3,3);
    hold on;
    errorbar(z_vals, r_p1, r_p1_std, 'b-o', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'DisplayName', 'P1');
    errorbar(z_vals, r_p4, r_p4_std, 'r-s', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'DisplayName', 'P4');
    yline(50, 'm--', 'LineWidth', 2, 'DisplayName', 'Target');
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('r_{rms} (mm)', 'FontSize', 13);
    title('Beam Envelope Evolution', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    ylim([0 80]);
    
    %% Plot 4-6: Difference plots (same as P1 vs P4 figure)
    % [Add Beta difference, Alpha difference, Radius difference with significance shading]
    %% ===== PLOT 4: Beta Difference (P4-P1) =====
    subplot(3,3,4);
    delta_beta_err = sqrt(beta_p1_std.^2 + beta_p4_std.^2);
    errorbar(z_vals, delta_beta, delta_beta_err, 'ko-', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'MarkerFaceColor', 'k');
    hold on;
    yline(0, 'r--', 'LineWidth', 2);
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('Δβ = β4 - β1 (m)', 'FontSize', 13);
    title('Ion-Induced Beta Change', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    xlim([0 8310]);
    
    %% ===== PLOT 5: Alpha Difference (P4-P1) =====
    subplot(3,3,5);
    delta_alpha_err = sqrt(alpha_p1_std.^2 + alpha_p4_std.^2);
    errorbar(z_vals, delta_alpha, delta_alpha_err, 'ko-', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'MarkerFaceColor', 'k');
    hold on;
    yline(0, 'r--', 'LineWidth', 2);
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('Δα = α4 - α1', 'FontSize', 13);
    title('Ion-Induced Alpha Change', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    xlim([0 8310]);
    
    %% ===== PLOT 6: Radius Difference with Significance Shading =====
    subplot(3,3,6);
    delta_r_err = sqrt(r_p1_std.^2 + r_p4_std.^2);
    errorbar(z_vals, delta_r, delta_r_err, 'ko-', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'MarkerFaceColor', 'k');
    hold on;
    yline(0, 'r--', 'LineWidth', 2);
    
    % Shade regions of statistical significance
    y_range = ylim;
    for iloc = 1:n_locations
        if t_stat(iloc) > 2.0
            % Highly significant - yellow background
            patch([z_vals(iloc)-50, z_vals(iloc)+50, z_vals(iloc)+50, z_vals(iloc)-50], ...
                  [y_range(1), y_range(1), y_range(2), y_range(2)], ...
                  'yellow', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
            % Red marker
            plot(z_vals(iloc), delta_r(iloc), 'ro', 'MarkerSize', 14, ...
                 'LineWidth', 3, 'MarkerFaceColor', 'red');
        end
    end
    
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('Δr_{rms} = r4 - r1 (mm)', 'FontSize', 13);
    title('Ion-Induced Radius Change', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Difference', 'Zero line', 'Significant (t>2)', 'Location', 'best');
    grid on;
    xlim([0 8310]);
    %% Plots 7. 8 
     %% ===== PLOT 7: Statistical Significance Bars =====
    subplot(3,3,7);
    bar(1:n_locations, t_stat, 'FaceColor', [0.3 0.6 0.9], 'EdgeColor', 'k', 'LineWidth', 1.5);
    hold on;
    yline(2.0, 'r--', 'LineWidth', 3, 'Label', '95% significance');
    yline(3.0, 'g--', 'LineWidth', 2, 'Label', '99% significance');
    set(gca, 'XTickLabel', location_names, 'FontSize', 12);
    ylabel('t-statistic', 'FontSize', 13);
    title('Statistical Significance Test', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    
    % Color bars by significance
    for iloc = 1:n_locations
        if t_stat(iloc) > 3.0
            bar(iloc, t_stat(iloc), 'FaceColor', 'green');
        elseif t_stat(iloc) > 2.0
            bar(iloc, t_stat(iloc), 'FaceColor', 'yellow');
        else
            bar(iloc, t_stat(iloc), 'FaceColor', [0.7 0.7 0.7]);
        end
    end
    
    %% ===== PLOT 8: Emittance Comparison =====
    subplot(3,3,8);
    hold on;
    errorbar(z_vals, emit_p1, emit_p1_std, 'b-o', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P1');
    errorbar(z_vals, emit_p4, emit_p4_std, 'r-s', 'LineWidth', 2.5, ...
             'MarkerSize', 10, 'CapSize', 12, 'DisplayName', 'P3');
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('ε_n (mm-mrad)', 'FontSize', 13);
    title('Normalized Emittance', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    xlim([0 8310]);
    
    
    %% Plot 9: Summary with scaling analysis
    subplot(3,3,9);
    axis off;
    
    text(0.5, 0.95, 'P1 vs P4 ION FOCUSING', 'FontWeight', 'bold', 'FontSize', 16, ...
         'HorizontalAlignment', 'center');
    text(0.5, 0.88, 'Exit Plane (z=2700mm)', 'FontWeight', 'bold', 'FontSize', 14, ...
         'HorizontalAlignment', 'center');
    
    y_pos = 0.75;
    
    % Show the scaling progression
    if exist('twiss_p2_averaged', 'var') && exist('twiss_p3_averaged', 'var')
        r_p2 = [twiss_p2_averaged.r_rms_mean];
        r_p3 = [twiss_p3_averaged.r_rms_mean];
        
        delta_r_p2 = r_p2(end) - r_p1(end);
        delta_r_p3 = r_p3(end) - r_p1(end);
        delta_r_p4 = delta_r(end);
        
        text(0.1, y_pos, 'ION FOCUSING PROGRESSION:', 'FontSize', 12, 'FontWeight', 'bold');
        y_pos = y_pos - 0.08;
        
        text(0.15, y_pos, sprintf('P2-P1: Δr = %.3f mm', delta_r_p2), 'FontSize', 11);
        y_pos = y_pos - 0.06;
        text(0.15, y_pos, sprintf('P3-P1: Δr = %.3f mm (%.1f× P2)', ...
             delta_r_p3, delta_r_p3/delta_r_p2), 'FontSize', 11);
        y_pos = y_pos - 0.06;
        text(0.15, y_pos, sprintf('P4-P1: Δr = %.3f mm (%.1f× P2)', ...
             delta_r_p4, delta_r_p4/delta_r_p2), 'FontSize', 11, 'FontWeight', 'bold');
        y_pos = y_pos - 0.10;
        
        expected_linear = 3.0 * delta_r_p2;
        text(0.1, y_pos, sprintf('Expected (linear): %.3f mm', expected_linear), 'FontSize', 11);
        y_pos = y_pos - 0.06;
        text(0.1, y_pos, sprintf('Actual: %.3f mm', delta_r_p4), ...
             'FontSize', 11, 'FontWeight', 'bold', 'Color', 'red');
    end
    
    sgtitle('Test 70: Maximum Ion Lensing in 4-Pulse Regime (12.6B ions)', ...
            'FontSize', 18, 'FontWeight', 'bold');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%% Added 02.06.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 36_P4 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== STEP 6: QUANTITATIVE COMPARISON WITH ERROR BARS P1 vs P4 ==============

if exist('twiss_p1_averaged', 'var') && exist('twiss_p4_averaged', 'var')
    
    figure('Position', [100, 100, 1600, 900], ...
           'Name', 'Phase-Averaged Pulse P1 vs P4 Comparison (Robust)');
    
    z_vals = [twiss_p1_averaged.z_mm];
    
    %% Plot 1: RMS Radius with statistical uncertainty
    subplot(2,3,1);
    r1_mean = [twiss_p1_averaged.r_rms_mean];
    r1_std = [twiss_p1_averaged.r_rms_std];
    r4_mean = [twiss_p4_averaged.r_rms_mean];
    r4_std = [twiss_p4_averaged.r_rms_std];
    
    hold on;
    errorbar(z_vals, r1_mean, r1_std, 'b-o', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'Pulse 1');
    errorbar(z_vals, r4_mean, r4_std, 'r-s', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'Pulse 4');
    yline(50, 'm--', 'LineWidth', 2, 'DisplayName', 'Target');
    
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('r_{rms} (mm)', 'FontSize', 12);
    title('Phase-Averaged RMS Radius', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    %% Plot 2: Statistical significance test
    subplot(2,3,2);
    
    % Calculate if differences are statistically significant
    % Using pooled standard deviation for 2-sample test
    significance = zeros(n_locations, 1);
    
    for iloc = 1:n_locations
        r1_m = twiss_p1_averaged(iloc).r_rms_mean;
        r1_s = twiss_p1_averaged(iloc).r_rms_std;
        r4_m = twiss_p4_averaged(iloc).r_rms_mean;
        r4_s = twiss_p4_averaged(iloc).r_rms_std;
        n = N_SNAPSHOTS;
        
        % Pooled standard error
        se_pooled = sqrt(r1_s^2/n + r4_s^2/n);
        
        % t-statistic
        if se_pooled > 0
            t_stat = abs(r4_m - r1_m) / se_pooled;
            significance(iloc) = t_stat;  % >2 is significant at 95% level
        else
            significance(iloc) = 0;
        end
    end
    
    bar(1:n_locations, significance);
    set(gca, 'XTickLabel', location_names);
    yline(2, 'r--', 'LineWidth', 2, 'Label', '95% significance');
    ylabel('t-statistic', 'FontSize', 12);
    title('Statistical Significance of P4-P1 Difference', 'FontSize', 14);
    grid on;
    
    %% Plot 3: Difference with error propagation
    subplot(2,3,3);
    delta_r = r4_mean - r1_mean;
    delta_r_error = sqrt(r1_std.^2 + r4_std.^2);  % Error propagation
    
    errorbar(z_vals, delta_r, delta_r_error, 'ko-', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'MarkerFaceColor', 'k');
    hold on;
    yline(0, 'r--', 'LineWidth', 2);
    
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('Δr_{rms} = r4 - r1 (mm)', 'FontSize', 12);
    title('Pulse 4 - Pulse 1 with Uncertainty', 'FontSize', 14);
    grid on;
    xlim([0 8310]);
    
    % Shade regions of significant difference
    for iloc = 1:n_locations
        if significance(iloc) > 2
            y_range = ylim;
            patch([z_vals(iloc)-50, z_vals(iloc)+50, z_vals(iloc)+50, z_vals(iloc)-50], ...
                  [y_range(1), y_range(1), y_range(2), y_range(2)], ...
                  'yellow', 'FaceAlpha', 0.2, 'EdgeColor', 'none');
        end
    end
    
    %% Plot 4: Beta comparison with error bars
    subplot(2,3,4);
    beta1_mean = [twiss_p1_averaged.beta_mean];
    beta1_std = [twiss_p1_averaged.beta_std];
    beta4_mean = [twiss_p4_averaged.beta_mean];
    beta4_std = [twiss_p4_averaged.beta_std];
    
    hold on;
    errorbar(z_vals, beta1_mean, beta1_std, 'b-o', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'P1');
    errorbar(z_vals, beta4_mean, beta4_std, 'r-s', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'P2');
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('β (m)', 'FontSize', 12);
    title('Phase-Averaged Beta Function', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    
    %% Plot 5: Alpha comparison
    subplot(2,3,5);
    alpha1_mean = [twiss_p1_averaged.alpha_mean];
    alpha1_std = [twiss_p1_averaged.alpha_std];
    alpha4_mean = [twiss_p4_averaged.alpha_mean];
    alpha4_std = [twiss_p4_averaged.alpha_std];
    
    hold on;
    errorbar(z_vals, alpha1_mean, alpha1_std, 'b-o', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'P1');
    errorbar(z_vals, alpha4_mean, alpha4_std, 'r-s', 'LineWidth', 2, ...
             'MarkerSize', 8, 'CapSize', 10, 'DisplayName', 'P2');
    yline(0, 'k--', 'LineWidth', 1);
    xlabel('z (mm)', 'FontSize', 12);
    ylabel('α', 'FontSize', 12);
    title('Phase-Averaged Alpha Parameter', 'FontSize', 14);
    legend('Location', 'best');
    grid on;
    
    %% Plot 6: Summary table with significance
    subplot(2,3,6);
    axis off;
    
    text(0.1, 0.95, 'PHASE-AVERAGED COMPARISON', 'FontWeight', 'bold', 'FontSize', 14);
    text(0.1, 0.88, 'Exit Plane (z=2700mm):', 'FontWeight', 'bold', 'FontSize', 12);
    
    y_pos = 0.78;
    
    % Beta
    text(0.1, y_pos, 'β (m):', 'FontSize', 11);
    text(0.30, y_pos, sprintf('%.3f±%.3f', beta1_mean(end), beta1_std(end)), ...
         'FontSize', 11, 'Color', 'blue');
    text(0.50, y_pos, sprintf('%.3f±%.3f', beta4_mean(end), beta4_std(end)), ...
         'FontSize', 11, 'Color', 'red');
    delta_beta = beta4_mean(end) - beta1_mean(end);
    text(0.70, y_pos, sprintf('Δ=%.3f', delta_beta), 'FontSize', 11);
    y_pos = y_pos - 0.10;
    
    % Alpha
    text(0.1, y_pos, 'α:', 'FontSize', 11);
    text(0.30, y_pos, sprintf('%.3f±%.3f', alpha1_mean(end), alpha1_std(end)), ...
         'FontSize', 11, 'Color', 'blue');
    text(0.50, y_pos, sprintf('%.3f±%.3f', alpha4_mean(end), alpha4_std(end)), ...
         'FontSize', 11, 'Color', 'red');
    delta_alpha = alpha4_mean(end) - alpha1_mean(end);
    text(0.70, y_pos, sprintf('Δ=%.3f', delta_alpha), 'FontSize', 11);
    y_pos = y_pos - 0.10;
    
    % RMS radius
    text(0.1, y_pos, 'r_rms (mm):', 'FontSize', 11);
    text(0.30, y_pos, sprintf('%.2f±%.2f', r1_mean(end), r1_std(end)), ...
         'FontSize', 11, 'Color', 'blue');
    text(0.50, y_pos, sprintf('%.2f±%.2f', r4_mean(end), r4_std(end)), ...
         'FontSize', 11, 'Color', 'red');
    delta_r = r4_mean(end) - r1_mean(end);
    text(0.70, y_pos, sprintf('Δ=%.2f', delta_r), 'FontSize', 11, 'FontWeight', 'bold');
    y_pos = y_pos - 0.10;
    
    % Statistical significance
    text(0.1, y_pos, 'Significance:', 'FontSize', 11, 'FontWeight', 'bold');
    if significance(end) > 2
        text(0.40, y_pos, sprintf('t=%.2f (SIGNIFICANT)', significance(end)), ...
             'FontSize', 11, 'Color', 'red', 'FontWeight', 'bold');
    else
        text(0.40, y_pos, sprintf('t=%.2f (within noise)', significance(end)), ...
             'FontSize', 11, 'Color', 'green');
    end
    y_pos = y_pos - 0.12;
    
    % Interpretation
    text(0.1, y_pos, 'INTERPRETATION:', 'FontWeight', 'bold', 'FontSize', 11);
    y_pos = y_pos - 0.08;
    
    if significance(end) > 2
        text(0.1, y_pos, '✓ Real P1→P4 difference detected', 'FontSize', 10, 'Color', 'red');
        y_pos = y_pos - 0.06;
        if delta_r < -0.3
            text(0.1, y_pos, '→ P4 is TIGHTER (focusing effect)', 'FontSize', 10);
        elseif delta_r > 0.3
            text(0.1, y_pos, '→ P4 is WIDER (defocusing effect)', 'FontSize', 10);
        end
    else
        text(0.1, y_pos, '✓ No significant P1-P4 difference', 'FontSize', 10, 'Color', 'green');
        y_pos = y_pos - 0.06;
        text(0.1, y_pos, '→ Betatron phase averaging successful!', 'FontSize', 10);
    end
    
    sgtitle(sprintf('Robust Pulse P1 vs P4 Comparison: %d Snapshots Per Pulse', N_SNAPSHOTS), ...
            'FontSize', 16);
end



%%%%%%%%%%%%%%%%%%%%%%%%%%% Added 02.09.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%New Diagnostic Figures for V3_12
%Add these comparison figures:
%Figure 47: Four-Pulse Transmission Comparison
%% ==================== FOUR-PULSE EFFICIENCY COMPARISON ====================
if ENABLE_MULTIPULSE == true && pulse_config.n_pulses == 4
    figure('Position', [100, 100, 1600, 600], 'Name', 'Four-Pulse Transmission Analysis');
    
    % Plot efficiencies for all four pulses
    eff = zeros(4,1);
    for ip = 1:4
        eff(ip) = 100 * pulse_diagnostics(ip).particles_transmitted / ...
                  pulse_diagnostics(ip).particles_emitted;
    end
    
    bar(1:4, eff, 'FaceColor', [0.2 0.6 0.9], 'BarWidth', 0.6);
    hold on;
    yline(94, 'r--', 'LineWidth', 2, 'Label', 'Operational Target');
    yline(mean(eff), 'g--', 'LineWidth', 2, 'Label', sprintf('Mean: %.2f%%', mean(eff)));
    
    xlabel('Pulse Number', 'FontSize', 14);
    ylabel('Transmission Efficiency (%)', 'FontSize', 14);
    title('Four-Pulse Operational Test: Transmission Efficiency', 'FontSize', 16);
    ylim([92 96]);
    grid on;
    
    % Add value labels on bars
    for ip = 1:4
        text(ip, eff(ip)+0.2, sprintf('%.2f%%', eff(ip)), ...
             'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Added 02.09.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
%Figure 48: Cumulative Ion Buildup (All 4 Pulses)
%% ==================== CUMULATIVE ION EVOLUTION ====================
if ENABLE_MULTIPULSE == true
figure('Position', [100, 100, 1400, 600], 'Name', 'Ion Accumulation: Four-Pulse Evolution');

subplot(1,2,1);
nonzero_idx = ion_diag.total_ions_vs_time > 0;
semilogy(t(nonzero_idx)*1e9, ion_diag.total_ions_vs_time(nonzero_idx), 'b-', 'LineWidth', 2.5);
hold on;

% Mark all four pulse boundaries
colors_pulse = lines(4);
for ip = 1:4
    t_p = pulse_config.pulse_starts(ip)*1e9;
    xline(t_p, '--', 'Color', colors_pulse(ip,:), 'LineWidth', 2, ...
          'Label', sprintf('P%d', ip));
end

xlabel('Time (ns)', 'FontSize', 14);
ylabel('Total Ions in System', 'FontSize', 14);
title('Ion Buildup Across Four Pulses', 'FontSize', 16);
grid on;
xlim([t_plot_min t_plot_max]);

% Annotate peak values
[max_ions, idx_max] = max(ion_diag.total_ions_vs_time);
text(t(idx_max)*1e9, max_ions*1.5, sprintf('Peak: %.2e ions', max_ions), ...
     'FontSize', 11, 'FontWeight', 'bold');

subplot(1,2,2);
bar(1:4, [ion_diag.ions_per_pulse(1:4)]/1e9, 'FaceColor', [0.3 0.7 0.4]);
xlabel('Pulse Number', 'FontSize', 14);
ylabel('Ions Created (billions)', 'FontSize', 14);
title('Ionization Per Pulse', 'FontSize', 16);
grid on;

% Add cumulative line
hold on;
cumulative = cumsum([ion_diag.ions_per_pulse(1:4)])/1e9;
plot(1:4, cumulative, 'ro-', 'LineWidth', 2.5, 'MarkerSize', 10, ...
     'DisplayName', 'Cumulative');
legend('Per pulse', 'Cumulative', 'FontSize', 12);
end
%%%%%%%%%%%%%%%%%%%%%%%% Added 0209.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Figure 49: P1 vs P4 Comparison (Maximum Ion Effect)
%% ==================== P1 vs P4 TWISS COMPARISON (MAXIMUM ION DOSE) ====================
if exist('twiss_p1_averaged', 'var') && exist('twiss_p4_averaged', 'var')
    
    figure('Position', [100, 100, 1800, 1000], 'Name', 'Test 70: P1 vs P4 Ion Focusing');
    
    z_vals = [twiss_p1_averaged.z_mm];
    
    % Extract P1 and P4 data
    r_p1 = [twiss_p1_averaged.r_rms_mean];
    r_p1_std = [twiss_p1_averaged.r_rms_std];
    r_p4 = [twiss_p4_averaged.r_rms_mean];
    r_p4_std = [twiss_p4_averaged.r_rms_std];
    
    beta_p1 = [twiss_p1_averaged.beta_mean];
    beta_p4 = [twiss_p4_averaged.beta_mean];
    alpha_p1 = [twiss_p1_averaged.alpha_mean];
    alpha_p4 = [twiss_p4_averaged.alpha_mean];
    
    % Subplot 1: RMS radius with 3× ion accumulation
    subplot(2,3,1);
    hold on;
    errorbar(z_vals, r_p1, r_p1_std, 'b-o', 'LineWidth', 2.5, 'MarkerSize', 10, ...
             'DisplayName', 'P1 (baseline)');
    errorbar(z_vals, r_p4, r_p4_std, 'r-s', 'LineWidth', 2.5, 'MarkerSize', 10, ...
             'DisplayName', 'P4 (max ions)');
    yline(50, 'm--', 'LineWidth', 2, 'DisplayName', 'Target');
    
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('r_{rms} (mm)', 'FontSize', 13);
    title('Envelope: P1 vs P4 (3× Ion Accumulation)', 'FontSize', 15, 'FontWeight', 'bold');
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    
    % Statistical significance test
    delta_r = r_p4 - r_p1;
    t_stat = zeros(length(z_vals), 1);
    for iloc = 1:length(z_vals)
        se = sqrt(r_p1_std(iloc)^2/N_SNAPSHOTS + r_p4_std(iloc)^2/N_SNAPSHOTS);
        if se > 0
            t_stat(iloc) = abs(delta_r(iloc)) / se;
        end
    end
    
    % Subplot 2: Statistical significance
    subplot(2,3,2);
    bar(1:length(z_vals), t_stat, 'FaceColor', [0.3 0.6 0.9]);
    hold on;
    yline(2.0, 'r--', 'LineWidth', 3, 'Label', '95% significance');
    set(gca, 'XTickLabel', location_names);
    ylabel('t-statistic', 'FontSize', 13);
    title('Statistical Significance Test', 'FontSize', 15);
    grid on;
    
    % Subplot 3: Delta r with significance shading
    subplot(2,3,3);
    delta_r_err = sqrt(r_p1_std.^2 + r_p4_std.^2);
    errorbar(z_vals, delta_r, delta_r_err, 'ko-', 'LineWidth', 2.5, 'MarkerSize', 10);
    hold on;
    yline(0, 'r--', 'LineWidth', 2);
    
    % Shade significant regions
    y_range = ylim;
    for iloc = 1:length(z_vals)
        if t_stat(iloc) > 2
            patch([z_vals(iloc)-50, z_vals(iloc)+50, z_vals(iloc)+50, z_vals(iloc)-50], ...
                  [y_range(1), y_range(1), y_range(2), y_range(2)], ...
                  'yellow', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        end
    end
    
    xlabel('z (mm)', 'FontSize', 13);
    ylabel('\Deltar_{rms} = r_4 - r_1 (mm)', 'FontSize', 13);
    title('Ion-Induced Change (P4-P1)', 'FontSize', 15, 'FontWeight', 'bold');
    grid on;
    
    % [Add subplots 4-6 for Beta, Alpha, summary table]
    
    sgtitle('Maximum Ion Test: P1 vs P4 (~12B ions)', 'FontSize', 18);
end
%%%%%%%%%%%%%%%%%%%%%%%% Aded 02.09.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Fix #7: PLOTS_AVAILABLE Validation
%Around line 3000:
if ENABLE_MULTIPULSE == true
    PLOTS_AVAILABLE.pulse2_snapshot = exist('steady_state_beam_pulse2', 'var');
    PLOTS_AVAILABLE.pulse2_twiss = exist('twiss_results_pulse2', 'var');
    PLOTS_AVAILABLE.pulse3_snapshot = exist('steady_state_beam_pulse3', 'var');
    PLOTS_AVAILABLE.pulse3_twiss = exist('twiss_results_pulse3', 'var');
    PLOTS_AVAILABLE.pulse4_snapshot = exist('steady_state_beam_pulse4', 'var');  % ADD
    PLOTS_AVAILABLE.pulse4_twiss = exist('twiss_results_pulse4', 'var');  % ADD
    PLOTS_AVAILABLE.interpulse_cloud = exist('interpulse_electron_cloud', 'var');
    PLOTS_AVAILABLE.betatron_averaging = (snapshot_p1_count == N_SNAPSHOTS) && ...
                                         (snapshot_p2_count == N_SNAPSHOTS) && ...
                                         (snapshot_p3_count == N_SNAPSHOTS) && ...
                                         (snapshot_p4_count == N_SNAPSHOTS);  % MODIFY
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Figure 52 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================== PULSE 3 vs PULSE 4 COMPARISON FIGURE ====================
%if PLOTS_AVAILABLE.pulse3_snapshot
 %   figure('Position', [100, 100, 1600, 900], 'Name', 'Pulse 1 vs Pulse 2 Comparison');
if exist('steady_state_beam_pulse3', 'var') && exist('steady_state_beam_pulse4', 'var')
  
    figure('Position', [100, 100, 1600, 900], 'Name', 'Pulse 4 vs Pulse 3 Comparison');
    
    % Extract Pulse 3 data
    z3 = steady_state_beam_pulse3.z * 1000;  % mm
    r3 = steady_state_beam_pulse3.r * 1000;
    
    % Extract Pulse 4 data
    z4 = steady_state_beam_pulse4.z * 1000;
    r4 = steady_state_beam_pulse4.r * 1000;
    
    % Plot 1: RMS radius comparison
    subplot(2,3,1);
    
    % Bin both pulses
    z_bins = 0:50:2700;
    r3_rms = zeros(length(z_bins)-1, 1);
    r4_rms = zeros(length(z_bins)-1, 1);
    z_centers = zeros(length(z_bins)-1, 1);
    
    for ib = 1:length(z_bins)-1
        z_centers(ib) = (z_bins(ib) + z_bins(ib+1))/2;
        
        % Pulse 3
        in_bin = z3 >= z_bins(ib) & z3 < z_bins(ib+1);
        if sum(in_bin) > 20
            r3_rms(ib) = sqrt(mean(r3(in_bin).^2));
        else
            r3_rms(ib) = NaN;
        end
        
        % Pulse 4
        in_bin = z2 >= z_bins(ib) & z2 < z_bins(ib+1);
        if sum(in_bin) > 20
            r4_rms(ib) = sqrt(mean(r4(in_bin).^2));
        else
            r4_rms(ib) = NaN;
        end
    end
    
    hold on;
    plot(z_centers, r3_rms, 'b-o', 'LineWidth', 2, 'DisplayName', 'Pulse 3');
    plot(z_centers, r4_rms, 'r-s', 'LineWidth', 2, 'DisplayName', 'Pulse 4');
    yline(50, 'm--', 'LineWidth', 2, 'DisplayName', 'Target');
    xlabel('z (mm)');
    ylabel('RMS Radius (mm)');
    title('Beam Envelope: Pulse 3 vs Pulse 4');
    legend('Location', 'best');
    grid on;
    xlim([0 8310]);
    ylim([0 80]);
    
    % Plot 2: Particle count comparison
    subplot(2,3,2);
    [n3, edges] = histcounts(z3, z_bins);
    [n4, ~] = histcounts(z4, z_bins);
    
    bar(z_centers, [n3; n4]', 'grouped');
    legend('Pulse 3', 'Pulse 4');
    xlabel('z (mm)');
    ylabel('Particles per bin');
    title('Longitudinal Distribution Comparison');
    grid on;
    
    % Plot 3: Radial distribution comparison
    subplot(2,3,3);
    histogram(r3, 30, 'FaceAlpha', 0.5, 'DisplayName', 'Pulse 3');
    hold on;
    histogram(r4, 30, 'FaceAlpha', 0.5, 'DisplayName', 'Pulse 4');
    xlabel('r (mm)');
    ylabel('Count');
    title('Radial Distribution Comparison');
    legend;
    grid on;
    
    % Plot 4: 2D density comparison - Pulse 1
    subplot(2,3,4);
    [N3, ze, re] = histcounts2(z3, r3, 0:25:8300, 0:1:80);
    imagesc(ze(1:end-1)+12.5, re(1:end-1)+0.5, log10(N3'+1));
    axis xy;
    colorbar;
    title('Pulse 3: 2D Density (t=605ns)');
    xlabel('z (mm)');
    ylabel('r (mm)');
    
    % Plot 5: 2D density - Pulse 2
    subplot(2,3,5);
    [N4, ~, ~] = histcounts2(z4, r4, 0:25:8300, 0:1:80);
    imagesc(ze(1:end-1)+12.5, re(1:end-1)+0.5, log10(N4'+1));
    axis xy;
    colorbar;
    title('Pulse 4: 2D Density (t=805ns)');
    xlabel('z (mm)');
    ylabel('r (mm)');
    
    % Plot 6: Difference map
    subplot(2,3,6);
    diff_map = N4 - N3;
    imagesc(ze(1:end-1)+12.5, re(1:end-1)+0.5, diff_map');
    axis xy;
    colorbar;
    title('Difference: Pulse 3 - Pulse 2');
    xlabel('z (mm)');
    ylabel('r (mm)');
    clim([-max(abs(diff_map(:))) max(abs(diff_map(:)))]);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %colormap(gca, 'redblue');
    % Replace with:
    cmap_redblue = [linspace(0,1,128)', linspace(0,1,128)', ones(128,1); ...
                ones(128,1), linspace(1,0,128)', linspace(1,0,128)'];
    colormap(gca, cmap_redblue);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %sgtitle(sprintf('Pulse Comparison: Δ Transmission = %.2f%%', ...
    %      eff2 - eff1, 'FontSize', 14));
    %        pulse_diagnostics(2).efficiency - pulse_diagnostics(1).efficiency), ...
    sgtitle(sprintf('Pulse 3 vs Pulse 4 Comparison','FontSize', 18,'Bold'));        
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  added figure 53 02.09.2026 %%%%%%%%%%%%%%%%%%%%%
%% ==================== FOUR-PULSE PROGRESSION FIGURE (COMPLETE) ====================
if pulse_config.n_pulses == 4 && exist('twiss_p1_averaged', 'var') && ...
   exist('twiss_p2_averaged', 'var') && exist('twiss_p3_averaged', 'var') && ...
   exist('twiss_p4_averaged', 'var')
    
    figure('Position', [100, 100, 1800, 1200], 'Name', 'Beam Quality Progression: 4-Pulse Evolution');
    
    %% Extract data for all four pulses
    cumulative_ions = cumsum([ion_diag.ions_per_pulse(1:4)])/1e9;  % billions
    
    % Transmission efficiencies
    eff = zeros(4,1);
    for ip = 1:4
        eff(ip) = 100 * pulse_diagnostics(ip).particles_transmitted / ...
                  pulse_diagnostics(ip).particles_emitted;
    end
    
    % Exit plane parameters (z=2700mm)
    r_exit = zeros(4,1);
    beta_exit = zeros(4,1);
    alpha_exit = zeros(4,1);
    emit_exit = zeros(4,1);
    
    for ip = 1:4
        eval(['r_exit(ip) = twiss_p' num2str(ip) '_averaged(end).r_rms_mean;']);
        eval(['beta_exit(ip) = twiss_p' num2str(ip) '_averaged(end).beta_mean;']);
        eval(['alpha_exit(ip) = twiss_p' num2str(ip) '_averaged(end).alpha_mean;']);
        eval(['emit_exit(ip) = twiss_p' num2str(ip) '_averaged(end).emit_mean;']);
    end
    
    %% Plot 1: Exit radius vs cumulative ions (PRIMARY METRIC)
    subplot(3,3,1);
    plot(cumulative_ions, r_exit, 'bo-', 'LineWidth', 3, 'MarkerSize', 14, ...
         'MarkerFaceColor', 'b');
    hold on;
    yline(50, 'r--', 'LineWidth', 2.5, 'Label', 'Target 50mm');
    xlabel('Cumulative Ions (billions)', 'FontSize', 14);
    ylabel('Exit r_{rms} (mm)', 'FontSize', 14);
    title('Beam Size vs Ion Accumulation', 'FontSize', 16, 'FontWeight', 'bold');
    grid on;
    xlim([0 max(cumulative_ions)*1.1]);
    ylim([0 60]);
    
    % Add linear fit to check for saturation
    p_fit = polyfit(cumulative_ions, r_exit, 1);
    r_fit = polyval(p_fit, cumulative_ions);
    plot(cumulative_ions, r_fit, 'r:', 'LineWidth', 2, 'DisplayName', 'Linear fit');
    
    % Calculate R² for linearity check
    SS_res = sum((r_exit - r_fit).^2);
    SS_tot = sum((r_exit - mean(r_exit)).^2);
    R_squared = 1 - SS_res/SS_tot;
    
    text(0.05, 0.95, sprintf('Slope: %.3f mm/B ions', p_fit(1)), ...
         'Units', 'normalized', 'FontSize', 11, 'BackgroundColor', 'white');
    text(0.05, 0.88, sprintf('RÂ² = %.3f', R_squared), ...
         'Units', 'normalized', 'FontSize', 11, 'BackgroundColor', 'white');
    
    if R_squared > 0.95
        text(0.05, 0.81, 'âœ" Linear regime', 'Units', 'normalized', ...
             'FontSize', 10, 'Color', 'green', 'FontWeight', 'bold');
    else
        text(0.05, 0.81, 'âš  Non-linear', 'Units', 'normalized', ...
             'FontSize', 10, 'Color', 'red', 'FontWeight', 'bold');
    end
    
    %% Plot 2: Transmission efficiency vs ion dose
    subplot(3,3,2);
    plot(cumulative_ions, eff, 'go-', 'LineWidth', 3, 'MarkerSize', 14, ...
         'MarkerFaceColor', 'g');
    hold on;
    yline(94, 'r--', 'LineWidth', 2.5, 'Label', 'Operational Target');
    yline(mean(eff), 'b:', 'LineWidth', 2, 'Label', sprintf('Mean: %.2f%%', mean(eff)));
    
    xlabel('Cumulative Ions (billions)', 'FontSize', 14);
    ylabel('Transmission Efficiency (%)', 'FontSize', 14);
    title('Efficiency vs Ion Dose', 'FontSize', 16, 'FontWeight', 'bold');
    grid on;
    ylim([92 96]);
    
    % Stability metric
    eff_variation = std(eff) / mean(eff) * 100;
    text(0.55, 0.15, sprintf('Variation: %.2f%%', eff_variation), ...
         'Units', 'normalized', 'FontSize', 11, 'BackgroundColor', 'white');
    
    if eff_variation < 1.0
        text(0.55, 0.08, 'âœ" Highly stable', 'Units', 'normalized', ...
             'FontSize', 10, 'Color', 'green', 'FontWeight', 'bold');
    end
    
    %% Plot 3: Normalized emittance progression
    subplot(3,3,3);
    plot(cumulative_ions, emit_exit, 'mo-', 'LineWidth', 3, 'MarkerSize', 14, ...
         'MarkerFaceColor', 'm');
    hold on;
    
    % Reference line at P1 emittance
    yline(emit_exit(1), 'k--', 'LineWidth', 2, 'Label', 'P1 baseline');
    
    xlabel('Cumulative Ions (billions)', 'FontSize', 14);
    ylabel('Îµ_n (mm-mrad)', 'FontSize', 14);
    title('Normalized Emittance Evolution', 'FontSize', 16, 'FontWeight', 'bold');
    grid on;
    
    % Calculate emittance growth
    emit_growth = (emit_exit(end) - emit_exit(1)) / emit_exit(1) * 100;
    text(0.55, 0.9, sprintf('Total growth: %.1f%%', emit_growth), ...
         'Units', 'normalized', 'FontSize', 11, 'BackgroundColor', 'white');
    
    if abs(emit_growth) < 5
        text(0.55, 0.83, 'âœ" Excellent preservation', 'Units', 'normalized', ...
             'FontSize', 10, 'Color', 'green');
    elseif abs(emit_growth) < 10
        text(0.55, 0.83, 'âœ" Good preservation', 'Units', 'normalized', ...
             'FontSize', 10, 'Color', 'blue');
    else
        text(0.55, 0.83, 'âš  Significant growth', 'Units', 'normalized', ...
             'FontSize', 10, 'Color', 'red');
    end
    
    %% Plot 4: Beta function at exit
    subplot(3,3,4);
    plot(cumulative_ions, beta_exit, 'co-', 'LineWidth', 3, 'MarkerSize', 14, ...
         'MarkerFaceColor', 'c');
    hold on;
    yline(beta_exit(1), 'k--', 'LineWidth', 2, 'Label', 'P1 baseline');
    
    xlabel('Cumulative Ions (billions)', 'FontSize', 14);
    ylabel('Î² (m)', 'FontSize', 14);
    title('Beta Function at Exit', 'FontSize', 16, 'FontWeight', 'bold');
    grid on;
    
    % Check for systematic drift
    beta_drift = (beta_exit(end) - beta_exit(1)) / beta_exit(1) * 100;
    text(0.55, 0.9, sprintf('Change: %.1f%%', beta_drift), ...
         'Units', 'normalized', 'FontSize', 11);
    
    %% Plot 5: Alpha parameter at exit (collimation quality)
    subplot(3,3,5);
    plot(cumulative_ions, alpha_exit, 'ro-', 'LineWidth', 3, 'MarkerSize', 14, ...
         'MarkerFaceColor', 'r');
    hold on;
    yline(0, 'k--', 'LineWidth', 2.5, 'Label', 'Perfect collimation');
    
    xlabel('Cumulative Ions (billions)', 'FontSize', 14);
    ylabel('Î±', 'FontSize', 14);
    title('Alpha Parameter at Exit', 'FontSize', 16, 'FontWeight', 'bold');
    grid on;
    
    % Highlight convergence/divergence trends
    for ip = 1:4
        if alpha_exit(ip) > 0.1
            plot(cumulative_ions(ip), alpha_exit(ip), 'rv', 'MarkerSize', 12, ...
                 'LineWidth', 2, 'MarkerFaceColor', 'red');
        elseif alpha_exit(ip) < -0.1
            plot(cumulative_ions(ip), alpha_exit(ip), 'r^', 'MarkerSize', 12, ...
                 'LineWidth', 2, 'MarkerFaceColor', 'blue');
        end
    end
    
    % Add legend for markers
    text(0.55, 0.9, 'â–¼ = Converging', 'Units', 'normalized', 'FontSize', 10);
    text(0.55, 0.83, 'â–² = Diverging', 'Units', 'normalized', 'FontSize', 10);
    
    %% Plot 6: Pulse-to-pulse radius differences
    subplot(3,3,6);
    delta_r_progressive = diff(r_exit);
    bar(1:3, delta_r_progressive, 'FaceColor', [0.7 0.3 0.3], 'BarWidth', 0.6);
    hold on;
    yline(0, 'k--', 'LineWidth', 2);
    
    set(gca, 'XTickLabel', {'P2-P1', 'P3-P2', 'P4-P3'}, 'FontSize', 12);
    ylabel('\Deltar_{rms} (mm)', 'FontSize', 14);
    title('Incremental Radius Changes', 'FontSize', 16, 'FontWeight', 'bold');
    grid on;
    
    % Check for saturation
    if abs(delta_r_progressive(3)) < abs(delta_r_progressive(1))*0.8
        text(0.5, 0.9, 'âš  Saturation detected!', 'Units', 'normalized', ...
             'FontSize', 12, 'Color', 'red', 'FontWeight', 'bold', ...
             'HorizontalAlignment', 'center');
    else
        text(0.5, 0.9, 'âœ" Consistent progression', 'Units', 'normalized', ...
             'FontSize', 12, 'Color', 'green', 'FontWeight', 'bold', ...
             'HorizontalAlignment', 'center');
    end
    
    %% Plot 7: Ion dose per pulse (balance check)
    subplot(3,3,7);
    ions_per_pulse_billions = [ion_diag.ions_per_pulse(1:4)]/1e9;
    
    bar(1:4, ions_per_pulse_billions, 'FaceColor', [0.3 0.7 0.4], 'BarWidth', 0.6);
    hold on;
    
    % Add cumulative line
    plot(1:4, cumulative_ions, 'ro-', 'LineWidth', 2.5, 'MarkerSize', 12, ...
         'DisplayName', 'Cumulative');
    
    xlabel('Pulse Number', 'FontSize', 14);
    ylabel('Ions (billions)', 'FontSize', 14);
    title('Ionization Balance Check', 'FontSize', 16, 'FontWeight', 'bold');
    legend('Per pulse', 'Cumulative', 'FontSize', 12);
    grid on;
    
    % Add values on bars
    for ip = 1:4
        text(ip, ions_per_pulse_billions(ip)+0.1, ...
             sprintf('%.2f B', ions_per_pulse_billions(ip)), ...
             'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
    end
    
    % Check balance
    ion_balance = std(ions_per_pulse_billions) / mean(ions_per_pulse_billions) * 100;
    text(0.5, 0.08, sprintf('Balance: Â±%.1f%%', ion_balance), ...
         'Units', 'normalized', 'FontSize', 10, 'HorizontalAlignment', 'center');
    
    %% Plot 8: Beam quality degradation timeline
    subplot(3,3,8);
    
    % Normalize all parameters to P1 values
    r_normalized = r_exit / r_exit(1);
    beta_normalized = beta_exit / beta_exit(1);
    emit_normalized = emit_exit / emit_exit(1);
    
    hold on;
    plot(1:4, r_normalized, 'b-o', 'LineWidth', 2.5, 'MarkerSize', 12, ...
         'DisplayName', 'r_{rms}/r_1');
    plot(1:4, beta_normalized, 'r-s', 'LineWidth', 2.5, 'MarkerSize', 12, ...
         'DisplayName', '\beta/\beta_1');
    plot(1:4, emit_normalized, 'm-^', 'LineWidth', 2.5, 'MarkerSize', 12, ...
         'DisplayName', '\epsilon/\epsilon_1');
    yline(1, 'k--', 'LineWidth', 2);
    
    xlabel('Pulse Number', 'FontSize', 14);
    ylabel('Normalized Parameter', 'FontSize', 14);
    title('Beam Quality Evolution (Normalized)', 'FontSize', 16, 'FontWeight', 'bold');
    legend('Location', 'best', 'FontSize', 11);
    grid on;
    ylim([0.95 1.05]);
    
    %% Plot 9: Summary statistics and validation
    subplot(3,3,9);
    axis off;
    
    text(0.5, 0.95, 'FOUR-PULSE SUMMARY', 'FontWeight', 'bold', 'FontSize', 16, ...
         'HorizontalAlignment', 'center');
    text(0.5, 0.88, 'Exit Plane Metrics', 'FontSize', 14, ...
         'HorizontalAlignment', 'center', 'Color', [0.2 0.2 0.7]);
    
    y_pos = 0.75;
    
    % Show progression for each parameter
    text(0.1, y_pos, 'r_{rms} (mm):', 'FontSize', 12, 'FontWeight', 'bold');
    y_pos = y_pos - 0.06;
    for ip = 1:4
        text(0.15, y_pos, sprintf('P%d: %.2f', ip, r_exit(ip)), 'FontSize', 11);
        y_pos = y_pos - 0.05;
    end
    
    y_pos = y_pos - 0.03;
    text(0.1, y_pos, 'Transmission (%):', 'FontSize', 12, 'FontWeight', 'bold');
    y_pos = y_pos - 0.06;
    for ip = 1:4
        text(0.15, y_pos, sprintf('P%d: %.2f%%', ip, eff(ip)), 'FontSize', 11);
        y_pos = y_pos - 0.05;
    end
    
    y_pos = y_pos - 0.03;
    text(0.1, y_pos, 'Total ions: %.2f B', max(cumulative_ions), ...
         'FontSize', 12, 'FontWeight', 'bold');
    y_pos = y_pos - 0.06;
    
    % Overall assessment
    text(0.1, y_pos, 'ASSESSMENT:', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'red');
    y_pos = y_pos - 0.06;
    
    % Check if all efficiencies meet target
    if all(eff > 94)
        text(0.1, y_pos, 'âœ" All pulses >94% transmission', 'FontSize', 11, 'Color', 'green');
        y_pos = y_pos - 0.05;
    end
    
    % Check stability
    if eff_variation < 0.5
        text(0.1, y_pos, sprintf('âœ" Excellent stability (Â±%.2f%%)', eff_variation), ...
             'FontSize', 11, 'Color', 'green');
        y_pos = y_pos - 0.05;
    end
    
    % Check radius control
    r_variation = std(r_exit) / mean(r_exit) * 100;
    if r_variation < 3
        text(0.1, y_pos, sprintf('âœ" Good radius control (Â±%.1f%%)', r_variation), ...
             'FontSize', 11, 'Color', 'green');
    end
    
    sgtitle('Test 70: Four-Pulse Progression Analysis', 'FontSize', 18, 'FontWeight', 'bold');
    
    % Save figure
    saveas(gcf, 'Test70_Four_Pulse_Progression.fig');
    saveas(gcf, 'Test70_Four_Pulse_Progression.png');
    fprintf('\nâœ" Four-pulse progression figure saved\n');
end


%%%%%%%%%%%%%%%%%%%%%% NEW HANDOFF FILE CREATION 03.26.2026 %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% HANDOFF FILE CREATION  ALL VERSIONS %%%%%%%%%%%%%%%
fprintf('\n================================================================\n');
fprintf('  CREATING HANDOFF FILE FOR NEXT ACCELERATION STAGE\n');
fprintf('  Generating 3 versions: Flat-top / Full pulse / Natural pulse\n');
fprintf('================================================================\n');

%% ---- n_created safety check -------------------------------------------
if ~exist('n_created','var') || isempty(n_created) || ...
   ~isscalar(n_created)     || n_created < 1
    fprintf('  ERROR: n_created invalid  cannot create handoff.\n');
    fprintf('================================================================\n');
    return
end
n_created = round(double(n_created));
fprintf('  n_created = %d (verified)\n', n_created);

%% ---- Force all crossing arrays to correct shape and length -------------
%% Use a helper pattern: extract, reshape to row, extend, reassign
%% This handles ALL edge cases: scalar, column, row, short, struct field

pte  = double(particle_t_at_exit(:)');    %% force row vector, double
pke  = double(particle_KE_at_exit(:)');
pce  = logical(particle_crossed_exit(:)');
pra  = double(particle_r_at_anode(:)');
wp   = double(weight_particles(:)');

%% Extend to n_created if shorter
if numel(pte)  < n_created,  pte(n_created)  = 0;     end
if numel(pke)  < n_created,  pke(n_created)  = 0;     end
if numel(pce)  < n_created,  pce(n_created)  = false; end
if numel(pra)  < n_created,  pra(n_created)  = 0;     end
if numel(wp)   < n_created,  wp(n_created)   = 0;     end

fprintf('  Array shapes verified:\n');
fprintf('    particle_t_at_exit:    %d elements\n', numel(pte));
fprintf('    particle_KE_at_exit:   %d elements\n', numel(pke));
fprintf('    particle_crossed_exit: %d elements\n', numel(pce));
fprintf('    particle_r_at_anode:   %d elements\n', numel(pra));
fprintf('    weight_particles:      %d elements\n', numel(wp));

%% ---- Build masks using LOCAL copies (not original arrays) --------------
crossed_mask  = pce(1:n_created);
t_exit_ns     = pte(1:n_created) * 1e9;
KE_exit_all   = pke(1:n_created);

mask_A = crossed_mask & (t_exit_ns >= 190) & (t_exit_ns <= 270);
mask_B = crossed_mask;
KE_threshold_MeV = 1.0;
mask_C = crossed_mask & (KE_exit_all >= KE_threshold_MeV * 1e6);

fprintf('  Version A (flat-top 190-270ns):   %d particles\n', sum(mask_A));
fprintf('  Version B (all crossing):         %d particles\n', sum(mask_B));
fprintf('  Version C (KE > %.1f MeV):        %d particles\n', ...
        KE_threshold_MeV, sum(mask_C));

%% ---- Recompute flat-top scalars if needed ------------------------------
if ~exist('I_exit_ss','var') || ~exist('I_cath_ss','var')
    t_ns_full = t * 1e9;
    flat_mask = (t_ns_full >= 190) & (t_ns_full <= 270);
    I_exit_ss = mean(I_exit(flat_mask));
    I_cath_ss = mean(I_cathode(flat_mask));
    fprintf('  NOTE: I_exit_ss recomputed from I_exit array.\n');
end

%% ====================================================================
%% VERSION LOOP  uses local copies pte, pke, pra, wp throughout
%% ====================================================================
for ver_idx = 1:3
    switch ver_idx
        case 1
            use_mask      = mask_A;
            version_label = 'VERSION_A';
            version_desc  = 'Flat-top only (190-270ns)  idealized steady state';
        case 2
            use_mask      = mask_B;
            version_label = 'VERSION_B';
            version_desc  = 'Full pulse  all particles  realistic rise/fall';
        case 3
            use_mask      = mask_C;
            version_label = 'VERSION_C';
            version_desc  = sprintf('Natural pulse  KE > %.1f MeV threshold', ...
                                    KE_threshold_MeV);
    end

    idx = find(use_mask);   %% row index vector

    if isempty(idx)
        fprintf('\n  %s: No particles found  skipped.\n', version_label);
        continue
    end

    fprintf('\n  Processing %s (%d particles)...\n', version_label, numel(idx));

    %% Index into LOCAL copies  guaranteed correct length and shape
    t_cross   = pte(idx);   %% row vector
    KE_eV     = pke(idx);
    r_anode   = pra(idx);
    w_vec     = wp(idx);

    %% Phase space reconstruction
    gam_h  = 1 + KE_eV / (m_e * c^2 / e_charge);
    beta_h = sqrt(1 - 1./gam_h.^2);
    p_h    = gam_h .* m_e .* beta_h .* c;

    %% Build struct  all fields from local variables, no re-indexing
    ho                         = struct();
    ho.description             = sprintf('Pierce Gun PIC V3  %s', version_desc);
    ho.version                 = version_label;
    ho.date                    = datestr(now);
    ho.z_handoff               = 8.305;
    ho.n_particles             = numel(idx);       %% numel not length
    ho.t_cross                 = t_cross;
    ho.KE_eV                   = KE_eV;
    ho.KE_MeV                  = KE_eV / 1e6;
    ho.gamma                   = gam_h;
    ho.beta                    = beta_h;
    ho.pz                      = p_h;
    ho.r_at_anode              = r_anode;
    ho.weight                  = w_vec;

    %% Statistics
    ho.KE_mean_MeV             = mean(ho.KE_MeV);
    ho.KE_std_MeV              = std(ho.KE_MeV);
    ho.KE_min_MeV              = min(ho.KE_MeV);
    ho.KE_max_MeV              = max(ho.KE_MeV);
    ho.t_mean_ns               = mean(t_cross) * 1e9;
    ho.t_min_ns                = min(t_cross)  * 1e9;
    ho.t_max_ns                = max(t_cross)  * 1e9;
    ho.pulse_duration_ns       = ho.t_max_ns - ho.t_min_ns;
    ho.I_peak_A                = I_exit_ss;
    ho.transmission_pct        = 100 * numel(idx) / n_created;
    ho.flatop_transmission_pct = 100 * I_exit_ss / max(I_cath_ss, 1);

    %% Time-resolved current profile
    t_bins      = linspace(ho.t_min_ns - 1, ho.t_max_ns + 1, 101);
    t_centers   = 0.5 * (t_bins(1:end-1) + t_bins(2:end));
    [n_bin, ~]  = histcounts(t_cross * 1e9, t_bins);
    dt_bin      = mean(diff(t_bins)) * 1e-9;
    w_pos       = w_vec(w_vec > 0);
    w_mean      = mean(w_pos);
    ho.pulse_t_ns      = t_centers;
    ho.pulse_I_A       = n_bin * w_mean * e_charge / dt_bin;
    ho.pulse_I_peak_A  = max(ho.pulse_I_A);

    %% Save
    fname = sprintf('handoff_%s_%s.mat', ...
                    version_label, datestr(now, 'yyyymmdd_HHMMSS'));
    save(fname, 'ho', '-v7.3');

    fprintf('  === %s SUMMARY ===\n',        version_label);
    fprintf('  Description:        %s\n',    version_desc);
    fprintf('  Particles:          %d\n',    ho.n_particles);
    fprintf('  KE mean:            %.4f MeV\n', ho.KE_mean_MeV);
    fprintf('  KE std:             %.4f MeV  (%.2f%% spread)\n', ...
            ho.KE_std_MeV, 100*ho.KE_std_MeV/max(ho.KE_mean_MeV,1e-9));
    fprintf('  KE range:           %.4f - %.4f MeV\n', ...
            ho.KE_min_MeV, ho.KE_max_MeV);
    fprintf('  Arrival window:     %.1f - %.1f ns\n', ...
            ho.t_min_ns, ho.t_max_ns);
    fprintf('  Pulse duration:     %.1f ns\n',  ho.pulse_duration_ns);
    fprintf('  Peak current:       %.1f A\n',   ho.pulse_I_peak_A);
    fprintf('  Transmission:       %.1f%%\n',   ho.transmission_pct);
    fprintf('  Saved to:           %s\n',       fname);

end  %% version loop

fprintf('\n================================================================\n');
fprintf('  ALL HANDOFF FILES CREATED\n');
fprintf('  VERSION_A  idealized flat-top for benchmarking\n');
fprintf('  VERSION_B  full realistic pulse with rise/fall\n');
fprintf('  VERSION_C  natural pulse with KE threshold applied\n');
fprintf('================================================================\n');
%%%%%%%%%%%%%%%%%%%% Updated Helper Functions 02.12.2026 %%%%%%%%%%%%%%%%%%%%%%%
%% ======================== HELPER FUNCTIONS (EXTENDED) ====================
%%%%%%%%%%%%%%%%%%%%%%%%% New Helper  Function for dual pulse %%%%%%%%%%%%%%%%%
%% ==================== HELPER FUNCTIONS (at end of file) ====================
function factor = pulse_shape_func(t, pulse_start, pulse_rise, pulse_flat, pulse_fall)
    % Single pulse (backward compatible)
    if t < pulse_start
        factor = 0;
    elseif t < pulse_start + pulse_rise
        phase = (t - pulse_start) / pulse_rise;
        factor = 0.5 * (1 + sin(pi * (phase - 0.5)));
    elseif t < pulse_start + pulse_rise + pulse_flat
        factor = 1;
    elseif t < pulse_start + pulse_rise + pulse_flat + pulse_fall
        phase = (t - pulse_start - pulse_rise - pulse_flat) / pulse_fall;
        factor = 0.5 * (1 + sin(pi * (0.5 - phase)));
    else
        factor = 0;
    end
end

function factor = pulse_shape_multipulse(t, config)
    % Multi-pulse capability
    factor = 0;  % Start with no field
    
    for ip = 1:config.n_pulses
        t_pulse = t - config.pulse_starts(ip);
        
        if t_pulse < 0
            continue;  % Before this pulse starts
        elseif t_pulse < config.rise_time
            % Rising edge
            phase = t_pulse / config.rise_time;
            pulse_factor = 0.5 * (1 + sin(pi * (phase - 0.5)));
        elseif t_pulse < config.rise_time + config.flat_time
            % Flat top
            pulse_factor = 1;
        elseif t_pulse < config.rise_time + config.flat_time + config.fall_time
            % Falling edge
            phase = (t_pulse - config.rise_time - config.flat_time) / config.fall_time;
            pulse_factor = 0.5 * (1 + sin(pi * (0.5 - phase)));
        else
            % After this pulse ends
            pulse_factor = 0;
        end
        
        % Take maximum (allows pulse overlap if needed)
        factor = max(factor, pulse_factor);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% New Updated Bz Br functions %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% Bz_func // Br_func %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function Bz = calculate_Bz_solenoid(z_pos, r_pos, t_curr, ...
    sol1, sol2, sol3, sol4, sol5, sol7, sol8, sol9, sol10, sol11, sol12, ...
    sol14, sol15, sol16, sol17, sol18, sol19, ...
    sol20, sol21, sol22, sol23, sol24, sol25, sol26, sol27, sol28, sol29, ...
    sol30, sol31, sol32, sol33, sol34, sol35, sol36, ...
    sol38, sol39, sol40, sol41, sol42, sol43, ...
    sol45, sol46, sol47, sol48, sol49)
    
    % ========================================================================
    % SOLENOID TIMING - INDEPENDENT OF EMISSION PULSE
    % ========================================================================
    % Single-pulse mode: covers t=150-270ns (emission) + margins
    % Multi-pulse mode: covers t=150-870ns (all 4 pulses) + margins
    %
    % For single-pulse (current test):
    %   Emission: 150-270ns
    %   Solenoids: 100-370ns (50ns early, 100ns late)
    % ========================================================================
    
    % Timing parameters (adjust for multi-pulse if needed)
    t_first_pulse_start = 150e-9;    % First emission pulse
    t_last_pulse_end = 270e-9;       % Last pulse end (single-pulse mode)
    
    t_sol_start = 100e-9;            % Start 50ns before emission
    t_sol_ramp = 50e-9;              % 50ns ramp time
    t_sol_flat_start = t_sol_start + t_sol_ramp;  % 150ns
    t_sol_end = t_last_pulse_end + 100e-9;        % 370ns (100ns after pulse)
    
    % Compute solenoid amplitude factor (time-dependent, NOT pulse-dependent!)
    if t_curr < t_sol_start
        solenoid_factor = 0.0;  % Before energization
        
    elseif t_curr < t_sol_flat_start
        % Ramp-up (smooth cosine)
        t_rel = t_curr - t_sol_start;
        solenoid_factor = 0.5 * (1 - cos(pi * t_rel / t_sol_ramp));
        
    elseif t_curr < t_sol_end
        % Flat-top: FULL STRENGTH (independent of emission pulse!)
        solenoid_factor = 1.0;
        
    else
        % Stay on for particle transport
        solenoid_factor = 1.0;
    end
    
    % Sum all solenoid contributions
    Bz = solenoid_factor * (...
         solenoid_Bz(z_pos, r_pos, sol1) + solenoid_Bz(z_pos, r_pos, sol2) + ...
         solenoid_Bz(z_pos, r_pos, sol3) + solenoid_Bz(z_pos, r_pos, sol4) + ...
         solenoid_Bz(z_pos, r_pos, sol5) + solenoid_Bz(z_pos, r_pos, sol7) + ...
         solenoid_Bz(z_pos, r_pos, sol8) + solenoid_Bz(z_pos, r_pos, sol9) + ...
         solenoid_Bz(z_pos, r_pos, sol10) + solenoid_Bz(z_pos, r_pos, sol11) + ...
         solenoid_Bz(z_pos, r_pos, sol12) + solenoid_Bz(z_pos, r_pos, sol14) + ...
         solenoid_Bz(z_pos, r_pos, sol15) + solenoid_Bz(z_pos, r_pos, sol16) + ...
         solenoid_Bz(z_pos, r_pos, sol17) + solenoid_Bz(z_pos, r_pos, sol18) + ...
         solenoid_Bz(z_pos, r_pos, sol19) + solenoid_Bz(z_pos, r_pos, sol20) + ...
         solenoid_Bz(z_pos, r_pos, sol21) + solenoid_Bz(z_pos, r_pos, sol22) + ...
         solenoid_Bz(z_pos, r_pos, sol23) + solenoid_Bz(z_pos, r_pos, sol24) + ...
         solenoid_Bz(z_pos, r_pos, sol25) + solenoid_Bz(z_pos, r_pos, sol26) + ...
         solenoid_Bz(z_pos, r_pos, sol27) + solenoid_Bz(z_pos, r_pos, sol28) + ...
         solenoid_Bz(z_pos, r_pos, sol29) + solenoid_Bz(z_pos, r_pos, sol30) + ...
         solenoid_Bz(z_pos, r_pos, sol31) + solenoid_Bz(z_pos, r_pos, sol32) + ...
         solenoid_Bz(z_pos, r_pos, sol33) + solenoid_Bz(z_pos, r_pos, sol34) + ...
         solenoid_Bz(z_pos, r_pos, sol35) + solenoid_Bz(z_pos, r_pos, sol36) + ...
         solenoid_Bz(z_pos, r_pos, sol38) + solenoid_Bz(z_pos, r_pos, sol39) + ...
         solenoid_Bz(z_pos, r_pos, sol40) + solenoid_Bz(z_pos, r_pos, sol41) + ...
         solenoid_Bz(z_pos, r_pos, sol42) + solenoid_Bz(z_pos, r_pos, sol43) + ...
         solenoid_Bz(z_pos, r_pos, sol45) + solenoid_Bz(z_pos, r_pos, sol46) + ...
         solenoid_Bz(z_pos, r_pos, sol47) + solenoid_Bz(z_pos, r_pos, sol48) + ...
         solenoid_Bz(z_pos, r_pos, sol49));
end

function Br = calculate_Br_solenoid(z_pos, r_pos, t_curr, ...
    sol1, sol2, sol3, sol4, sol5, sol7, sol8, sol9, sol10, sol11, sol12, ...
    sol14, sol15, sol16, sol17, sol18, sol19, ...
    sol20, sol21, sol22, sol23, sol24, sol25, sol26, sol27, sol28, sol29, ...
    sol30, sol31, sol32, sol33, sol34, sol35, sol36, ...
    sol38, sol39, sol40, sol41, sol42, sol43, ...
    sol45, sol46, sol47, sol48, sol49)
    
    % Same timing as Bz
    t_first_pulse_start = 150e-9;
    t_last_pulse_end = 270e-9;
    
    t_sol_start = 100e-9;
    t_sol_ramp = 50e-9;
    t_sol_flat_start = t_sol_start + t_sol_ramp;
    t_sol_end = t_last_pulse_end + 100e-9;
    
    if t_curr < t_sol_start
        solenoid_factor = 0.0;
    elseif t_curr < t_sol_flat_start
        t_rel = t_curr - t_sol_start;
        solenoid_factor = 0.5 * (1 - cos(pi * t_rel / t_sol_ramp));
    elseif t_curr < t_sol_end
        solenoid_factor = 1.0;
    else
        solenoid_factor = 1.0;
    end
    
    Br = solenoid_factor * (...
         solenoid_Br(z_pos, r_pos, sol1) + solenoid_Br(z_pos, r_pos, sol2) + ...
         solenoid_Br(z_pos, r_pos, sol3) + solenoid_Br(z_pos, r_pos, sol4) + ...
         solenoid_Br(z_pos, r_pos, sol5) + solenoid_Br(z_pos, r_pos, sol7) + ...
         solenoid_Br(z_pos, r_pos, sol8) + solenoid_Br(z_pos, r_pos, sol9) + ...
         solenoid_Br(z_pos, r_pos, sol10) + solenoid_Br(z_pos, r_pos, sol11) + ...
         solenoid_Br(z_pos, r_pos, sol12) + solenoid_Br(z_pos, r_pos, sol14) + ...
         solenoid_Br(z_pos, r_pos, sol15) + solenoid_Br(z_pos, r_pos, sol16) + ...
         solenoid_Br(z_pos, r_pos, sol17) + solenoid_Br(z_pos, r_pos, sol18) + ...
         solenoid_Br(z_pos, r_pos, sol19) + solenoid_Br(z_pos, r_pos, sol20) + ...
         solenoid_Br(z_pos, r_pos, sol21) + solenoid_Br(z_pos, r_pos, sol22) + ...
         solenoid_Br(z_pos, r_pos, sol23) + solenoid_Br(z_pos, r_pos, sol24) + ...
         solenoid_Br(z_pos, r_pos, sol25) + solenoid_Br(z_pos, r_pos, sol26) + ...
         solenoid_Br(z_pos, r_pos, sol27) + solenoid_Br(z_pos, r_pos, sol28) + ...
         solenoid_Br(z_pos, r_pos, sol29) + solenoid_Br(z_pos, r_pos, sol30) + ...
         solenoid_Br(z_pos, r_pos, sol31) + solenoid_Br(z_pos, r_pos, sol32) + ...
         solenoid_Br(z_pos, r_pos, sol33) + solenoid_Br(z_pos, r_pos, sol34) + ...
         solenoid_Br(z_pos, r_pos, sol35) + solenoid_Br(z_pos, r_pos, sol36) + ...
         solenoid_Br(z_pos, r_pos, sol38) + solenoid_Br(z_pos, r_pos, sol39) + ...
         solenoid_Br(z_pos, r_pos, sol40) + solenoid_Br(z_pos, r_pos, sol41) + ...
         solenoid_Br(z_pos, r_pos, sol42) + solenoid_Br(z_pos, r_pos, sol43) + ...
         solenoid_Br(z_pos, r_pos, sol45) + solenoid_Br(z_pos, r_pos, sol46) + ...
         solenoid_Br(z_pos, r_pos, sol47) + solenoid_Br(z_pos, r_pos, sol48) + ...
         solenoid_Br(z_pos, r_pos, sol49));
end

% Keep atomic functions unchanged
function Bz = solenoid_Bz(z, r, sol)
    in_radius = r <= sol.R;
    z_factor = 0.5 * (tanh(2*(z - (sol.z_c - sol.L/2))/sol.L) - ...
                      tanh(2*(z - (sol.z_c + sol.L/2))/sol.L));
    Bz = sol.B * in_radius .* z_factor;
end

function Br = solenoid_Br(z, r, sol)
    in_radius = r <= sol.R;
    r_factor = -r/2;
    z_deriv = (2/sol.L) * (sech(2*(z - (sol.z_c - sol.L/2))/sol.L).^2 - ...
                           sech(2*(z - (sol.z_c + sol.L/2))/sol.L).^2);
    Br = sol.B * in_radius .* r_factor .* z_deriv;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% End of the modelV3 script %%%%%%%%%%%%%%%%%%%%%