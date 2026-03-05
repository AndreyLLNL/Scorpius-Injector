%% Pierce Gun Parametric Geometry Builder V27 - 19-POINT LEGO SYSTEM
% Complete hardware: -400mm to +8305mm (49 solenoids)
% NEW: Exact 19-point LEGO cathode construction
% Date: 2026-02-19

clear all; close all; clc;

%% ========================= FLEXIBLE CATHODE PARAMETERS =========================
THETA_DEG = 68;      % Pierce gun angle [degrees] (68-90°) - FLAT CATHODE
GAP_MM = 0;          % Gap between cathode and shroud [mm] (0-1 mm)
RECESS_MM = 0;       % Cathode recess depth [mm] (0-2 mm)

fprintf('=== 19-Point LEGO Cathode Geometry Builder V27 ===\n');
fprintf('Parameters: Θ=%.1f°, Gap=%.2fmm, Recess=%.2fmm\n\n', ...
        THETA_DEG, GAP_MM, RECESS_MM);

%% ========================= SCALING & CONSTANTS =========================
SCALE_FACTOR = 1;
scale = 1 / (1000 * SCALE_FACTOR);

eps0 = 8.854187817e-12;
e_charge = 1.602176634e-19;
m_e = 9.10938356e-31;
k_B = 1.380649e-23;

%% ========================= FIXED DIMENSIONS =========================
% Cathode LEGO parameters (in mm, will be scaled)
H1 = 65;           % Main body height
W1 = 400;          % Main body width
H2 = GAP_MM;       % Gap height (variable)
W3 = RECESS_MM;    % Recess width (variable)
H4 = 49;           % Block D height along tilt
W7 = 225;          % Cathode stem width
H7 = 25;           % Cathode stem height
R_shroud = 100;    % Shroud radius (renamed from R to avoid meshgrid collision)

% Calculate W4 (FIXED for all angles)
W4_fixed = 15 / sin(pi/2 - 68*pi/180);  % = 40.042 mm at Θ=68°

% Convert angle
theta_rad = THETA_DEG * pi/180;

fprintf('Calculated W4_fixed = %.3f mm\n', W4_fixed);
fprintf('For Θ=%.1f°: W5=%.3f mm, H5=%.3f mm\n\n', ...
        THETA_DEG, W4_fixed*sin(theta_rad), W4_fixed*cos(theta_rad));

%% ========================= CALCULATE ALL 19 POINTS =========================
fprintf('Computing 19 corner points...\n');

% Block A corners
pt(1).z = 0;       pt(1).r = 0;
pt(2).z = 0;       pt(2).r = H1;
pt(3).z = -W1;     pt(3).r = H1;
pt(4).z = -W1;     pt(4).r = 0;

% Block D corners (rotated rectangle)
pt(5).z = W3;
pt(5).r = H1 + H2;

pt(6).z = H4 * cos(theta_rad) + W3;
pt(6).r = H4 * sin(theta_rad) + H1 + H2;

pt(7).z = H4 * cos(theta_rad) + W3 - W4_fixed * sin(theta_rad);
pt(7).r = H4 * sin(theta_rad) + H1 + H2 + W4_fixed * cos(theta_rad);

pt(8).z = W3 - W4_fixed * sin(theta_rad);  % CORRECTED: minus, not plus
pt(8).r = H1 + H2 + W4_fixed * cos(theta_rad);

% E block corners (first instance: 5, 9, 8, 10)
pt(9).z = W3;
pt(9).r = H1 + H2 + W4_fixed * cos(theta_rad);

pt(10).z = W3 - W4_fixed * sin(theta_rad);  % CORRECTED: minus, not plus
pt(10).r = H1 + H2;

% E block corners (second instance: 6, 11, 7, 12)
pt(11).z = H4 * cos(theta_rad) + W3;
pt(11).r = H4 * sin(theta_rad) + H1 + H2 + W4_fixed * cos(theta_rad);

pt(12).z = H4 * cos(theta_rad) + W3 - W4_fixed * sin(theta_rad);
pt(12).r = H4 * sin(theta_rad) + H1 + H2;

% Semicircle F (center and diameter endpoint)
pt(13).z = H4 * cos(theta_rad) + W3 - R_shroud;
pt(13).r = H4 * sin(theta_rad) + H1 + H2 + W4_fixed * cos(theta_rad);

pt(14).z = H4 * cos(theta_rad) + W3 - 2*R_shroud;
pt(14).r = H4 * sin(theta_rad) + H1 + H2 + W4_fixed * cos(theta_rad);

% Block C corners (cathode stem)
pt(15).z = -W1 + W7;
pt(15).r = H1 + H2 + W4_fixed * cos(theta_rad);

pt(16).z = -W1 + W7;
pt(16).r = H1 + H2 + W4_fixed * cos(theta_rad) + H7;

pt(17).z = -W1;
pt(17).r = H1 + H2 + W4_fixed * cos(theta_rad) + H7;

pt(18).z = -W1;
pt(18).r = H1 + H2 + W4_fixed * cos(theta_rad);

% Block B corner
pt(19).z = W3 - W4_fixed * sin(theta_rad);  % CORRECTED: minus, not plus
pt(19).r = H1;  % CORRECTED: H1, not W1

% Apply scaling to all points
for i = 1:19
    pt(i).z = pt(i).z * scale;
    pt(i).r = pt(i).r * scale;
end

fprintf('  All 19 points calculated and scaled\n');

%% ========================= SYSTEM PARAMETERS (unchanged) =========================
chamber.z_start = -400 * scale;
chamber.z_end = 8305 * scale;
chamber.r_inner = 411 * scale;
chamber.t_wall = 10 * scale;

anode.r_pipe_inner = 74 * scale;
anode.t_pipe_wall = 11 * scale;
anode.r_pipe_outer = anode.r_pipe_inner + anode.t_pipe_wall;
anode.r_toroid = 24 * scale;
anode.z_entrance = 254 * scale;
anode.pipe_length = 346 * scale;

ground.r_toroid = 92 * scale;
ground.r_inner = 220 * scale;
ground.r_center = ground.r_inner + ground.r_toroid;
ground.z_protrusion = 17 * scale;
ground.z_position = anode.z_entrance - anode.r_toroid - ground.z_protrusion + ground.r_toroid;

drift.r_inner = 74 * scale;
drift.t_wall = 11 * scale;
drift.r_outer = drift.r_inner + drift.t_wall;
drift.z_start = anode.z_entrance + anode.pipe_length;
drift.length = 7705 * scale;
drift.z_end = drift.z_start + drift.length;

% All 49 Solenoids (exact positions from hardware)
solenoid1.name = 'Cathode solenoid'; solenoid1.B_peak = -0.045; solenoid1.z_center = -279; solenoid1.z_length = 106; solenoid1.r_inner = 451;
solenoid2.name = 'Focus solenoid'; solenoid2.B_peak = 0.0135; solenoid2.z_center = 372; solenoid2.z_length = 195; solenoid2.r_inner = 245;
solenoid3.name = 'Drift solenoid 1'; solenoid3.B_peak = 0.0075; solenoid3.z_center = 1144.61; solenoid3.z_length = 120; solenoid3.r_inner = 245;
solenoid4.name = 'Drift solenoid 2'; solenoid4.B_peak = 0.0075; solenoid4.z_center = 1267.57; solenoid4.z_length = 120; solenoid4.r_inner = 245;
solenoid5.name = 'Drift solenoid 3'; solenoid5.B_peak = 0.0050; solenoid5.z_center = 1369.27; solenoid5.z_length = 60; solenoid5.r_inner = 245;
solenoid6.name = 'Steering magnet 1'; solenoid6.B_peak = 0.0000; solenoid6.z_center = 1412.00; solenoid6.z_length = 20; solenoid6.r_inner = 245;
solenoid7.name = 'Drift solenoid 4'; solenoid7.B_peak = 0.0025; solenoid7.z_center = 1492.23; solenoid7.z_length = 100; solenoid7.r_inner = 245;
solenoid8.name = 'Drift solenoid 5'; solenoid8.B_peak = 0.0025; solenoid8.z_center = 1593.93; solenoid8.z_length = 100; solenoid8.r_inner = 245;
solenoid9.name = 'Drift solenoid 6'; solenoid9.B_peak = 0.0025; solenoid9.z_center = 1716.89; solenoid9.z_length = 100; solenoid9.r_inner = 245;
solenoid10.name = 'Drift solenoid 7'; solenoid10.B_peak = 0.0025; solenoid10.z_center = 1818.60; solenoid10.z_length = 90; solenoid10.r_inner = 245;
solenoid11.name = 'Drift solenoid 8'; solenoid11.B_peak = 0.0020; solenoid11.z_center = 1941.56; solenoid11.z_length = 120; solenoid11.r_inner = 245;
solenoid12.name = 'Drift solenoid 9'; solenoid12.B_peak = 0.0020; solenoid12.z_center = 2043.26; solenoid12.z_length = 120; solenoid12.r_inner = 245;
solenoid13.name = 'Steering magnet 2'; solenoid13.B_peak = 0.0000; solenoid13.z_center = 2112.00; solenoid13.z_length = 20; solenoid13.r_inner = 245;
solenoid14.name = 'Drift solenoid 10'; solenoid14.B_peak = 0.0020; solenoid14.z_center = 2166.22; solenoid14.z_length = 90; solenoid14.r_inner = 245;
solenoid15.name = 'Drift solenoid 11'; solenoid15.B_peak = 0.0020; solenoid15.z_center = 2267.93; solenoid15.z_length = 120; solenoid15.r_inner = 245;
solenoid16.name = 'Drift solenoid 12'; solenoid16.B_peak = 0.0015; solenoid16.z_center = 2390.89; solenoid16.z_length = 120; solenoid16.r_inner = 245;
solenoid17.name = 'Drift solenoid 13'; solenoid17.B_peak = 0.0015; solenoid17.z_center = 2492.59; solenoid17.z_length = 120; solenoid17.r_inner = 245;
solenoid18.name = 'Drift solenoid 14'; solenoid18.B_peak = 0.0015; solenoid18.z_center = 2615.55; solenoid18.z_length = 100; solenoid18.r_inner = 245;
solenoid19.name = 'Drift solenoid 15'; solenoid19.B_peak = 0.0015; solenoid19.z_center = 2717.26; solenoid19.z_length = 100; solenoid19.r_inner = 245;
solenoid20.name = 'Drift solenoid 16'; solenoid20.B_peak = 0.0015; solenoid20.z_center = 2840.22; solenoid20.z_length = 100; solenoid20.r_inner = 245;
solenoid21.name = 'Drift solenoid 17'; solenoid21.B_peak = 0.0015; solenoid21.z_center = 2941.92; solenoid21.z_length = 100; solenoid21.r_inner = 245;
solenoid22.name = 'Drift solenoid 18'; solenoid22.B_peak = 0.0015; solenoid22.z_center = 3064.88; solenoid22.z_length = 100; solenoid22.r_inner = 245;
solenoid23.name = 'Drift solenoid 19'; solenoid23.B_peak = 0.0015; solenoid23.z_center = 3166.58; solenoid23.z_length = 100; solenoid23.r_inner = 245;
solenoid24.name = 'Drift solenoid 20'; solenoid24.B_peak = 0.0015; solenoid24.z_center = 3289.54; solenoid24.z_length = 100; solenoid24.r_inner = 245;
solenoid25.name = 'Drift solenoid 21'; solenoid25.B_peak = 0.0015; solenoid25.z_center = 3391.25; solenoid25.z_length = 100; solenoid25.r_inner = 245;
solenoid26.name = 'Drift solenoid 22'; solenoid26.B_peak = 0.0015; solenoid26.z_center = 3514.21; solenoid26.z_length = 100; solenoid26.r_inner = 245;
solenoid27.name = 'Drift solenoid 23'; solenoid27.B_peak = 0.0015; solenoid27.z_center = 3615.91; solenoid27.z_length = 100; solenoid27.r_inner = 245;
solenoid28.name = 'Drift solenoid 24'; solenoid28.B_peak = 0.0015; solenoid28.z_center = 3738.87; solenoid28.z_length = 100; solenoid28.r_inner = 245;
solenoid29.name = 'Drift solenoid 25'; solenoid29.B_peak = 0.0015; solenoid29.z_center = 3840.58; solenoid29.z_length = 100; solenoid29.r_inner = 245;
solenoid30.name = 'Drift solenoid 26'; solenoid30.B_peak = 0.0015; solenoid30.z_center = 3963.54; solenoid30.z_length = 100; solenoid30.r_inner = 245;
solenoid31.name = 'Drift solenoid 27'; solenoid31.B_peak = 0.0015; solenoid31.z_center = 4065.24; solenoid31.z_length = 100; solenoid31.r_inner = 245;
solenoid32.name = 'Drift solenoid 28'; solenoid32.B_peak = 0.0015; solenoid32.z_center = 4188.20; solenoid32.z_length = 100; solenoid32.r_inner = 245;
solenoid33.name = 'Drift solenoid 29'; solenoid33.B_peak = 0.0015; solenoid33.z_center = 4289.93; solenoid33.z_length = 100; solenoid33.r_inner = 245;
solenoid34.name = 'Drift solenoid 30'; solenoid34.B_peak = 0.0015; solenoid34.z_center = 4412.89; solenoid34.z_length = 100; solenoid34.r_inner = 245;
solenoid35.name = 'Drift solenoid 31'; solenoid35.B_peak = 0.0015; solenoid35.z_center = 4514.59; solenoid35.z_length = 100; solenoid35.r_inner = 245;
solenoid36.name = 'Drift solenoid 32'; solenoid36.B_peak = 0.0015; solenoid36.z_center = 4637.55; solenoid36.z_length = 100; solenoid36.r_inner = 245;
solenoid37.name = 'Steering solenoid 3'; solenoid37.B_peak = 0.0015; solenoid37.z_center = 4677.00; solenoid37.z_length = 100; solenoid37.r_inner = 245;
solenoid38.name = 'Drift solenoid 33'; solenoid38.B_peak = 0.0015; solenoid38.z_center = 4739.25; solenoid38.z_length = 100; solenoid38.r_inner = 245;
solenoid39.name = 'Drift solenoid 34'; solenoid39.B_peak = 0.0015; solenoid39.z_center = 4862.21; solenoid39.z_length = 100; solenoid39.r_inner = 245;
solenoid40.name = 'Drift solenoid 35'; solenoid40.B_peak = 0.0015; solenoid40.z_center = 4963.92; solenoid40.z_length = 100; solenoid40.r_inner = 245;
solenoid41.name = 'Drift solenoid 36'; solenoid41.B_peak = 0.0015; solenoid41.z_center = 5086.88; solenoid41.z_length = 100; solenoid41.r_inner = 245;
solenoid42.name = 'Drift solenoid 37'; solenoid42.B_peak = 0.0015; solenoid42.z_center = 5188.58; solenoid42.z_length = 100; solenoid42.r_inner = 245;
solenoid43.name = 'Drift solenoid 38'; solenoid43.B_peak = 0.0015; solenoid43.z_center = 5311.54; solenoid43.z_length = 100; solenoid43.r_inner = 245;
solenoid44.name = 'Steering solenoid 4'; solenoid44.B_peak = 0.0015; solenoid44.z_center = 5377.00; solenoid44.z_length = 100; solenoid44.r_inner = 245;
solenoid45.name = 'Drift solenoid 39'; solenoid45.B_peak = 0.0015; solenoid45.z_center = 5413.24; solenoid45.z_length = 100; solenoid45.r_inner = 245;
solenoid46.name = 'Drift solenoid 40'; solenoid46.B_peak = 0.0015; solenoid46.z_center = 5536.20; solenoid46.z_length = 100; solenoid46.r_inner = 245;
solenoid47.name = 'Drift solenoid 41'; solenoid47.B_peak = 0.0015; solenoid47.z_center = 5637.91; solenoid47.z_length = 100; solenoid47.r_inner = 245;
solenoid48.name = 'Drift solenoid 42'; solenoid48.B_peak = 0.0015; solenoid48.z_center = 5760.87; solenoid48.z_length = 100; solenoid48.r_inner = 245;
solenoid49.name = 'Drift solenoid 43'; solenoid49.B_peak = 0.0015; solenoid49.z_center = 7448.00; solenoid49.z_length = 100; solenoid49.r_inner = 245;

% BPM (Beam Position Monitor) locations
%BPM1_z = 2760 * scale;     % Original endpoint [m]
%BPM2_z = 4000 * scale;     % Mid-drift [m]
%BPM3_z = 5500 * scale;     % [m]
%BPM4_z = 7000 * scale;     % [m]
%BPM5_z = 8200 * scale;     % Near exit [m]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% updated 02.25.2026  %%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================================================================================
%% FIX 2: BPM POSITION SYNCHRONIZATION
%% ==================================================================================
%% The Geometry Builder (V40) uses approximate BPM positions:
%%   BPM1=2760, BPM2=4000, BPM3=5500, BPM4=7000, BPM5=8200 mm
%%
%% The PIC code uses actual hardware positions:
%%   BPM1=2760, BPM2=3964, BPM3=6401.8, BPM4=6827.6, BPM5=8305 mm
%%
%% UPDATE the Geometry Builder to use correct hardware positions.
%% Replace the BPM section in Pierce_Gun_Parametric_Geometry_Builder_V40.m:
%% ==================================================================================

% IN GEOMETRY BUILDER - Replace the BPM section (~line 115) with:

% BPM (Beam Position Monitor) locations - ACTUAL HARDWARE POSITIONS
% Verified from engineering drawings and experimental team measurements
BPM1_z = 2760 * scale;     % BPM1: Original injector endpoint [m]
BPM2_z = 3964 * scale;     % BPM2: First extended diagnostic [m]
BPM3_z = 6401.8 * scale;   % BPM3: Mid-extension diagnostic [m]
BPM4_z = 6827.6 * scale;   % BPM4: Pre-exit diagnostic [m]
BPM5_z = 8305 * scale;     % BPM5: Final exit / handoff point [m]

% NOTE: Previous approximate values (4000, 5500, 7000, 8200mm) replaced
% with measured hardware positions for consistency with PIC simulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
V_cathode = - 850e3;
V_anode = 850e3;
V_ground = 0;

% Scale all 49 solenoids (convert mm to meters)
for sol_num = 1:49
    sol = eval(sprintf('solenoid%d', sol_num));
    sol.z_center = sol.z_center * scale;
    sol.z_length = sol.z_length * scale;
    sol.r_inner = sol.r_inner * scale;
    eval(sprintf('solenoid%d = sol;', sol_num));
end
cath.z_position = 0;
gap_distance = anode.z_entrance - cath.z_position;
if SCALE_FACTOR == 1
    nr = 500;
    nz = 11000;
else
    nr = 300;
    nz = 6570;
end

z_min = chamber.z_start;
z_max = chamber.z_end;
r_max = chamber.r_inner * 1.1;

z = linspace(z_min, z_max, nz);
r = linspace(0, r_max, nr);
dz = z(2) - z(1);
dr = r(2) - r(1);

[Z, R] = meshgrid(z, r);

fprintf('\nMesh: %d x %d (dz=%.3fmm, dr=%.3fmm)\n', ...
        nz, nr, dz*1000*SCALE_FACTOR, dr*1000*SCALE_FACTOR);

%% ========================= BUILD GEOMETRY =========================
electrode_map = zeros(nr, nz);

fprintf('\nBuilding geometry using 19-point LEGO system...\n');

%% ---- Build LEGO Cathode ----
fprintf('  Building LEGO cathode blocks...\n');

% Helper function to fill polygon (VECTORIZED)
fill_polygon = @(points_idx) fill_poly_vectorized(Z, R, pt, points_idx);

% Block A (1, 2, 3, 4) - Main body
fprintf('    Block A: Main body...');
mask = fill_polygon([1, 2, 3, 4]);
electrode_map(mask) = 1;
fprintf(' done\n');

% Block B (19, 8, 18, 3) - Large rectangular body
fprintf('    Block B: Upper body...');
mask = fill_polygon([19, 8, 18, 3]);
electrode_map(mask) = 1;
fprintf(' done\n');

% Block C (15, 16, 17, 18) - Cathode stem
fprintf('    Block C: Stem...');
mask = fill_polygon([15, 16, 17, 18]);
electrode_map(mask) = 1;
fprintf(' done\n');

% Block D (5, 6, 7, 8) - Rotated rectangle (Pierce surface block)
fprintf('    Block D: Pierce block...');
mask = fill_polygon([5, 6, 7, 8]);
electrode_map(mask) = 1;
fprintf(' done\n');

% Block E (5, 9, 8, 10) - First E rectangle
fprintf('    Block E1: Horizontal rectangle...');
mask = fill_polygon([5, 9, 8, 10]);
electrode_map(mask) = 1;
fprintf(' done\n');

% Block E (6, 11, 7, 12) - Second E rectangle
fprintf('    Block E2: Horizontal rectangle...');
mask = fill_polygon([6, 11, 7, 12]);
electrode_map(mask) = 1;
fprintf(' done\n');

% Block F - Semicircle (center at point 13, radius R_shroud)
fprintf('    Block F: Semicircle shroud...');
center_z = pt(13).z;
center_r = pt(13).r;
radius_m = R_shroud * scale;  % Use R_shroud constant, not meshgrid R

% Vectorized distance calculation using meshgrid R (radial coordinate)
dist = sqrt((Z - center_z).^2 + (R - center_r).^2);
mask = (dist <= radius_m) & (R >= center_r);
electrode_map(mask) = 1;
fprintf(' done\n');

fprintf('  Cathode complete: %d points\n', sum(electrode_map(:)==1));

% Verify block solidification
fprintf('\n  Block verification:\n');
temp_map = zeros(size(electrode_map));
temp_map = temp_map + fill_poly_vectorized(Z, R, pt, [1, 2, 3, 4]);
fprintf('    Block A (main body): %d points\n', sum(temp_map(:)));

temp_map = zeros(size(electrode_map));
temp_map = temp_map + fill_poly_vectorized(Z, R, pt, [19, 8, 18, 3]);
fprintf('    Block B (upper body): %d points\n', sum(temp_map(:)));

temp_map = zeros(size(electrode_map));
temp_map = temp_map + fill_poly_vectorized(Z, R, pt, [15, 16, 17, 18]);
fprintf('    Block C (stem): %d points\n', sum(temp_map(:)));

temp_map = zeros(size(electrode_map));
temp_map = temp_map + fill_poly_vectorized(Z, R, pt, [5, 6, 7, 8]);
fprintf('    Block D (Pierce): %d points\n', sum(temp_map(:)));

temp_map = zeros(size(electrode_map));
temp_map = temp_map + fill_poly_vectorized(Z, R, pt, [5, 9, 8, 10]);
fprintf('    Block E1 (rectangle): %d points\n', sum(temp_map(:)));

temp_map = zeros(size(electrode_map));
temp_map = temp_map + fill_poly_vectorized(Z, R, pt, [6, 11, 7, 12]);
fprintf('    Block E2 (rectangle): %d points\n', sum(temp_map(:)));

% Count semicircle separately
temp_map = zeros(size(electrode_map));
radius_m = R_shroud * scale;  % Use R_shroud constant
dist = sqrt((Z - pt(13).z).^2 + (R - pt(13).r).^2);
temp_mask = (dist <= radius_m) & (R >= pt(13).r);
temp_map(temp_mask) = 1;
fprintf('    Block F (semicircle): %d points\n', sum(temp_map(:)));

clear temp_map temp_mask;

fprintf('  Cathode complete: %d points\n', sum(electrode_map(:)==1));

%% ---- Build Anode (unchanged) ----
fprintf('  Building anode...\n');
for i = 1:nr
    for j = 1:nz
        r_pos = r(i);
        z_pos = z(j);
        
        % Entrance toroid
        toroid_center_r = anode.r_pipe_inner + anode.r_toroid;
        toroid_center_z = anode.z_entrance;
        dist = sqrt((r_pos - toroid_center_r)^2 + (z_pos - toroid_center_z)^2);
        
        if dist <= anode.r_toroid && r_pos >= anode.r_pipe_inner
            electrode_map(i,j) = 2;
            continue;
        end
        
        % Pipe walls
        if z_pos >= anode.z_entrance && ...
           z_pos <= (anode.z_entrance + anode.pipe_length) && ...
           r_pos >= anode.r_pipe_inner && r_pos <= anode.r_pipe_outer
            electrode_map(i,j) = 2;
        end
    end
end

%% ---- Build Ground Structure (unchanged) ----
fprintf('  Building ground structure...\n');
for i = 1:nr
    for j = 1:nz
        r_pos = r(i);
        z_pos = z(j);
        
        % Chamber walls
        if r_pos >= chamber.r_inner && r_pos <= (chamber.r_inner + chamber.t_wall) && ...
           z_pos >= chamber.z_start && z_pos <= chamber.z_end
            electrode_map(i,j) = 3;
            continue;
        end
        
        % Top wall
        if z_pos >= chamber.z_start && z_pos <= chamber.z_end && r_pos >= chamber.r_inner
            electrode_map(i,j) = 3;
            continue;
        end
        
        % Quarter-toroid
        dist = sqrt((r_pos - ground.r_center)^2 + (z_pos - ground.z_position)^2);
        if dist <= ground.r_toroid
            electrode_map(i,j) = 3;
            continue;
        end
        
        % Remaining ground blocks (same as before)
        if z_pos >= (213*scale) && z_pos <= chamber.z_end && ...
           r_pos >= (312*scale) && r_pos <= (420*scale)
            electrode_map(i,j) = 3;
            continue;
        end
        
        if z_pos >= (305*scale) && z_pos <= chamber.z_end && ...
           r_pos >= (220*scale) && r_pos <= (312*scale)
            electrode_map(i,j) = 3;
            continue;
        end
        
        bulge_r_toroid = 108 * scale;
        bulge_center_r = chamber.r_inner - bulge_r_toroid;
        bulge_center_z = chamber.z_end - bulge_r_toroid;
        dist_bulge = sqrt((r_pos - bulge_center_r)^2 + (z_pos - bulge_center_z)^2);
        if dist_bulge <= bulge_r_toroid && r_pos >= bulge_center_r && ...
           r_pos <= chamber.r_inner && z_pos >= bulge_center_z && z_pos <= chamber.z_end
            electrode_map(i,j) = 3;
            continue;
        end
        
        if z_pos >= ground.z_position && z_pos <= (305*scale) && ...
           r_pos >= ground.r_inner && r_pos <= (312*scale)
            electrode_map(i,j) = 3;
            continue;
        end
        
        if abs(z_pos - chamber.z_start) <= dz*2 && r_pos >= 81.25*scale
            electrode_map(i,j) = 3;
            continue;
        end
        
        if abs(z_pos - chamber.z_end) <= dz*2 && ...
           r_pos >= anode.r_pipe_outer && r_pos <= chamber.r_inner
            electrode_map(i,j) = 3;
        end
    end
end

%% ---- Build Drift Tube (unchanged) ----
fprintf('  Building drift tube...\n');
for i = 1:nr
    for j = 1:nz
        r_pos = r(i);
        z_pos = z(j);
        
        if z_pos >= drift.z_start && z_pos <= drift.z_end && ...
           r_pos >= drift.r_inner && r_pos <= drift.r_outer
            electrode_map(i,j) = 4;
        end
    end
end

fprintf('\nGeometry complete:\n');
fprintf('  Cathode: %d points\n', sum(electrode_map(:)==1));
fprintf('  Anode: %d points\n', sum(electrode_map(:)==2));
fprintf('  Ground: %d points\n', sum(electrode_map(:)==3));
fprintf('  Drift: %d points\n', sum(electrode_map(:)==4));

%% ========================= VISUALIZATION =========================
cmap = [1.0 1.0 1.0; 0.0 0.0 1.0; 1.0 0.0 0.0; 0.0 0.7 0.0; 1.0 0.5 0.0];

% Figure 1: Cathode detail with 19 points labeled
figure('Position', [50, 50, 1400, 800], ...
       'Name', sprintf('19-Point LEGO Cathode (Θ=%.1f°, Gap=%.2fmm, Recess=%.2fmm)', ...
       THETA_DEG, GAP_MM, RECESS_MM));

subplot(2,2,1);
z_cath_idx = find(z >= -400*scale & z <= 50*scale);
r_cath_idx = find(r >= 0 & r <= 240*scale);
imagesc(z(z_cath_idx)*1000, r(r_cath_idx)*1000, electrode_map(r_cath_idx, z_cath_idx));
colormap(gca, cmap); caxis([0 4]);
xlabel('Z [mm]', 'FontSize', 12); ylabel('R [mm]', 'FontSize', 12);
title(sprintf('Cathode with 19 Points (Θ=%.1f°)', THETA_DEG), 'FontSize', 14);
axis equal tight; set(gca, 'YDir', 'normal'); grid on;
hold on;

% Plot all 19 points
for i = 1:19
    plot(pt(i).z*1000, pt(i).r*1000, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'y');
    text(pt(i).z*1000+2, pt(i).r*1000+3, sprintf('%d', i), ...
         'Color', 'r', 'FontSize', 10, 'FontWeight', 'bold');
end

% Draw block outlines
draw_block_outline([1,2,3,4], pt, 'k', 2);      % Block A
draw_block_outline([19,8,18,3], pt, 'b', 2);    % Block B
draw_block_outline([15,16,17,18], pt, 'm', 2);  % Block C
draw_block_outline([5,6,7,8], pt, 'r', 3);      % Block D
draw_block_outline([5,9,8,10], pt, 'g', 2);     % Block E1
draw_block_outline([6,11,7,12], pt, 'c', 2);    % Block E2
hold off;

subplot(2,2,2);
z_gap_idx = find(z >= -200*scale & z <= 400*scale);
r_gap_idx = find(r <= 300*scale);
imagesc(z(z_gap_idx)*1000, r(r_gap_idx)*1000, electrode_map(r_gap_idx, z_gap_idx));
colormap(gca, cmap); caxis([0 4]);
xlabel('Z [mm]', 'FontSize', 12); ylabel('R [mm]', 'FontSize', 12);
title('Gap Region Detail', 'FontSize', 14);
axis equal tight; set(gca, 'YDir', 'normal'); grid on;

subplot(2,2,3);
z_anode_idx = find(z >= 215*scale & z <= 300*scale);
r_anode_idx = find(r >= 50*scale & r <= 125*scale);
imagesc(z(z_anode_idx)*1000, r(r_anode_idx)*1000, electrode_map(r_anode_idx, z_anode_idx));
colormap(gca, cmap); caxis([0 4]);
xlabel('Z [mm]', 'FontSize', 12); ylabel('R [mm]', 'FontSize', 12);
title('Anode Entrance', 'FontSize', 14);
axis equal tight; set(gca, 'YDir', 'normal'); grid on;

subplot(2,2,4);
z_ground_idx = find(z >= 150*scale & z <= 360*scale);
r_ground_idx = find(r >= 150*scale & r <= 360*scale);
imagesc(z(z_ground_idx)*1000, r(r_ground_idx)*1000, electrode_map(r_ground_idx, z_ground_idx));
colormap(gca, cmap); caxis([0 4]);
xlabel('Z [mm]', 'FontSize', 12); ylabel('R [mm]', 'FontSize', 12);
title('Ground Structure', 'FontSize', 14);
axis equal tight; set(gca, 'YDir', 'normal'); grid on;

% Figure 2: Full cross-section (CLEAN - no annotations)
figure('Position', [50, 50, 1800, 700], 'Name', 'Complete Injector - Clean');
r_col = r(:);
electrode_map_full = [flipud(electrode_map(2:end,:)); electrode_map];
r_full = [-flipud(r_col(2:end)); r_col];
imagesc(z*1000, r_full*1000, electrode_map_full);
colormap(gca, cmap); caxis([0 4]);
xlabel('Z [mm]', 'FontSize', 14); ylabel('R [mm]', 'FontSize', 14);
title(sprintf('Complete Injector: 19-Point LEGO Cathode (Θ=%.1f°, Gap=%.2fmm, Recess=%.2fmm)', ...
      THETA_DEG, GAP_MM, RECESS_MM), 'FontSize', 16);
axis equal tight; set(gca, 'YDir', 'normal'); grid on;
colorbar('Ticks', [0,1,2,3,4], 'TickLabels', {'Vacuum','Cathode','Anode','Ground','Drift'});

%% ========================= FIGURE 3: WITH SOLENOIDS & BPMs =========================
figure('Position', [50, 50, 1800, 700], 'Name', 'Complete Injector - With Diagnostics');
imagesc(z*1000, r_full*1000, electrode_map_full);
colormap(gca, cmap); caxis([0 4]);
xlabel('Z [mm]', 'FontSize', 14); ylabel('R [mm]', 'FontSize', 14);
title(sprintf('Complete Injector with Solenoids & BPMs (Θ=%.1f°, Gap=%.2fmm, Recess=%.2fmm)', ...
      THETA_DEG, GAP_MM, RECESS_MM), 'FontSize', 16);
axis equal tight; set(gca, 'YDir', 'normal'); grid on;
colorbar('Ticks', [0,1,2,3,4], 'TickLabels', {'Vacuum','Cathode','Anode','Ground','Drift'});

hold on;

% Add solenoid centers (all 49, label only key ones)
for sol_num = 1:49
    sol = eval(sprintf('solenoid%d', sol_num));
    
    % Mark center with tall vertical line (same height as BPMs)
    plot([sol.z_center*1000, sol.z_center*1000], [-400, 400], 'k:', 'LineWidth', 1);
    
    % Label only key solenoids to avoid crowding
    if ismember(sol_num, [1, 2, 10, 20, 30, 40, 49])
        text(sol.z_center*1000, -450, sprintf('S%d', sol_num), ...
             'Color', 'k', 'FontSize', 9, 'HorizontalAlignment', 'center', ...
             'FontWeight', 'bold');
    end
end

% Add BPM locations (green vertical lines)
BPM_locations = [BPM1_z, BPM2_z, BPM3_z, BPM4_z, BPM5_z];
for i = 1:length(BPM_locations)
    plot([BPM_locations(i)*1000, BPM_locations(i)*1000], [-400, 400], 'g-', ...
         'LineWidth', 2.5);
    text(BPM_locations(i)*1000, 450, sprintf('BPM%d', i), ...
         'Color', 'g', 'FontSize', 11, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center');
end

% Add annotation
text(chamber.z_end*500, -350, ...
     sprintf('49 Solenoids (S1-S49) | 5 BPM Stations'), ...
     'FontSize', 10, 'HorizontalAlignment', 'center', 'Color', [0.3 0.3 0.3]);

hold off;

%% ========================= EXPORT 19 CORNER POINTS =========================
fprintf('\n=== 19 CORNER POINT COORDINATES ===\n');
fprintf('Parameters: Theta=%.1f°, Gap=%.2fmm, Recess=%.2fmm\n\n', ...
        THETA_DEG, GAP_MM, RECESS_MM);
fprintf('Point#  Z [mm]      R [mm]      Description\n');
fprintf('------  ----------  ----------  -----------\n');

point_desc = {
    'Origin (cathode surface center)', ...              % 1
    'Top of cathode surface', ...                       % 2
    'Top-left of main body', ...                        % 3
    'Bottom-left of main body', ...                     % 4
    'Block D - bottom-left corner', ...                 % 5
    'Block D - bottom-right corner', ...                % 6
    'Block D - top-right corner', ...                   % 7
    'Block D - top-left corner', ...                    % 8
    'Block E1 - top-left corner', ...                   % 9
    'Block E1 - bottom-left corner', ...                % 10
    'Block E2 - bottom-right corner', ...               % 11
    'Block E2 - top-right corner', ...                  % 12
    'Semicircle F - center', ...                        % 13
    'Semicircle F - left diameter endpoint', ...        % 14
    'Block C - bottom-left corner (stem)', ...          % 15
    'Block C - top-left corner (stem)', ...             % 16
    'Block C - top-right corner (stem)', ...            % 17
    'Block C - bottom-right corner (stem)', ...         % 18
    'Block B - connection point'};                      % 19

for i = 1:19
    fprintf('%2d      %10.3f  %10.3f  %s\n', i, pt(i).z*1000, pt(i).r*1000, point_desc{i});
end

fprintf('\n');

%% ========================= EXPORT BLOCK DEFINITIONS =========================
fprintf('=== LEGO BLOCK DEFINITIONS ===\n');
fprintf('Block A (main body):        Points [1, 2, 3, 4]\n');
fprintf('Block B (upper body):       Points [19, 8, 18, 3]\n');
fprintf('Block C (cathode stem):     Points [15, 16, 17, 18]\n');
fprintf('Block D (Pierce block):     Points [5, 6, 7, 8]\n');
fprintf('Block E1 (rectangle):       Points [5, 9, 8, 10]\n');
fprintf('Block E2 (rectangle):       Points [6, 11, 7, 12]\n');
fprintf('Block F (semicircle):       Center at Point 13, Radius=%.1fmm\n', R_shroud);
fprintf('                            Diameter: Points 11-14\n');

%% ========================= SAVE GEOMETRY =========================
save_filename = sprintf('pierce_gun_lego_theta%d_gap%.0f_recess%.0f.mat', ...
                        round(THETA_DEG), GAP_MM*10, RECESS_MM*10);

save(save_filename, 'electrode_map', 'z', 'r', 'Z', 'R', 'nr', 'nz', 'dr', 'dz', ...
     'cath', 'anode', 'ground', 'chamber', 'drift', ...
     'THETA_DEG', 'GAP_MM', 'RECESS_MM', 'pt', ...
     'solenoid1', 'solenoid2', 'solenoid3', 'solenoid4', 'solenoid5', ...
     'solenoid6', 'solenoid7', 'solenoid8', 'solenoid9', 'solenoid10', ...
     'solenoid11', 'solenoid12', 'solenoid13', 'solenoid14', 'solenoid15', ...
     'solenoid16', 'solenoid17', 'solenoid18', 'solenoid19', 'solenoid20', ...
     'solenoid21', 'solenoid22', 'solenoid23', 'solenoid24', 'solenoid25', ...
     'solenoid26', 'solenoid27', 'solenoid28', 'solenoid29', 'solenoid30', ...
     'solenoid31', 'solenoid32', 'solenoid33', 'solenoid34', 'solenoid35', ...
     'solenoid36', 'solenoid37', 'solenoid38', 'solenoid39', 'solenoid40', ...
     'solenoid41', 'solenoid42', 'solenoid43', 'solenoid44', 'solenoid45', ...
     'solenoid46', 'solenoid47', 'solenoid48', 'solenoid49', ...
     'BPM1_z', 'BPM2_z', 'BPM3_z', 'BPM4_z', 'BPM5_z', ...
     'V_cathode', 'V_anode', 'V_ground', 'gap_distance', 'SCALE_FACTOR', ...
     'eps0', 'e_charge', 'm_e', 'k_B');

fprintf('\n✓ Geometry saved: %s\n', save_filename);
fprintf('✓ Ready for field solver!\n');
fprintf('\n✓ Geometry builder V27 complete!\n');

%% ========================= HELPER FUNCTIONS =========================
function mask = fill_poly_vectorized(Z, R, pt, idx)
    % Fill polygon defined by points pt(idx) - VECTORIZED VERSION
    poly_z = [pt(idx).z];
    poly_r = [pt(idx).r];
    
    % Use vectorized inpolygon on the entire mesh at once
    mask = inpolygon(Z, R, poly_z, poly_r);
end

function draw_block_outline(idx, pt, color, width)
    % Draw outline of block defined by points
    z_pts = [pt(idx).z] * 1000;
    r_pts = [pt(idx).r] * 1000;
    plot([z_pts, z_pts(1)], [r_pts, r_pts(1)], ...
         'Color', color, 'LineWidth', width);
end