%% Streamlined Pierce Gun Field Solver - Single Pass with Capping
% Solves once, applies field cap during solution, saves immediately
% No redundant solving - more efficient workflow
% Date: 2025-12-18

clear all; close all; clc;

fprintf('================================================================\n');
fprintf('       STREAMLINED PIERCE GUN FIELD SOLVER                     \n');
fprintf('       Single-Pass Solution with Integrated Field Capping      \n');
fprintf('================================================================\n\n');

%% ========================= LOAD GEOMETRY =========================
fprintf('Loading geometry...\n');
%load('pierce_gun_geometry_extended_scale_1.mat');
%load('pierce_gun_lego_theta89_gap10_recess40.mat');
load('pierce_gun_lego_theta80_gap10_recess20.mat');

fprintf('  Mesh: %d x %d points\n', nz, nr);
fprintf('  Cathode voltage: %.0f kV\n', V_cathode/1000);
fprintf('  Anode voltage: %.0f kV\n', V_anode/1000);
fprintf('  Domain: %.0f to %.0f mm\n', chamber.z_start*1000, chamber.z_end*1000);

%% ========================= SOLVER PARAMETERS =========================
omega = 1.90;                % SOR relaxation factor
max_iterations = 50000;      % Maximum iterations
tolerance = 1e-9;            % Convergence tolerance
check_interval = 500;        % Check every 500 iterations

% Field capping parameters
field_cap = 7.5e6;           % 7.5 MV/m field cap for simulation stability

fprintf('\nSolver Configuration:\n');
fprintf('  Relaxation factor: %.2f\n', omega);
fprintf('  Max iterations: %d\n', max_iterations);
fprintf('  Tolerance: %.2e\n', tolerance);
fprintf('  Field cap: %.1f MV/m\n', field_cap/1e6);

%% ========================= INITIALIZE POTENTIAL =========================
fprintf('\nInitializing potential...\n');

V = zeros(nr, nz);

% Set electrode boundary conditions
for i = 1:nr
    for j = 1:nz
        if electrode_map(i,j) == 1      % Cathode
            V(i,j) = V_cathode;
        elseif electrode_map(i,j) == 2  % Anode
            V(i,j) = V_anode;
        elseif electrode_map(i,j) == 3  % Ground
            V(i,j) = V_ground;
        else  % Vacuum - linear initial guess
            z_norm = (z(j) - z(1)) / (anode.z_entrance - z(1));
            z_norm = max(0, min(1, z_norm));
            V(i,j) = V_cathode + (V_anode - V_cathode) * z_norm;
        end
    end
end

%% ========================= SOLVE WITH INTEGRATED CAPPING =========================
fprintf('\nSolving Laplace equation...\n');

converged = false;
V_min_limit = V_cathode - 1000;
V_max_limit = V_anode + 1000;

for iter = 1:max_iterations
    V_old = V;
    
    % SOR iteration
    for i = 2:nr-1
        for j = 2:nz-1
            if electrode_map(i,j) == 0  % Vacuum only
                r_local = r(i);
                
                if r_local > 1e-6
                    % Standard cylindrical Laplacian
                    V_new = (1/(2*(dr^2 + dz^2))) * ...
                            (dz^2 * (V(i+1,j) + V(i-1,j)) + ...
                             dr^2 * (V(i,j+1) + V(i,j-1)) + ...
                             (dz^2/(2*r_local)) * dr * (V(i+1,j) - V(i-1,j)));
                else
                    % On-axis: L'Hôpital's rule
                    V_new = (1/(4*dr^2 + 2*dz^2)) * ...
                            (4*dr^2*V(i+1,j) + dz^2*(V(i,j+1) + V(i,j-1)));
                end
                
                % Apply SOR with voltage limits
                V_proposed = (1 - omega) * V(i,j) + omega * V_new;
                V(i,j) = max(V_min_limit, min(V_max_limit, V_proposed));
            end
        end
    end
    
    % Axis symmetry
    V(1,:) = V(2,:);
    
    % Re-enforce electrode potentials
    V(electrode_map == 1) = V_cathode;
    V(electrode_map == 2) = V_anode;
    V(electrode_map == 3) = V_ground;
    
    % Check convergence
    if mod(iter, check_interval) == 0
        max_change = max(abs(V(:) - V_old(:)));
        residual = max_change / mean(abs(V(:)));
        
        fprintf('  Iter %5d: residual = %.2e\n', iter, residual);
        
        if residual < tolerance
            converged = true;
            fprintf('  ✓ CONVERGED!\n');
            break;
        end
    end
end

if ~converged
    fprintf('  ⚠ Did not fully converge after %d iterations\n', max_iterations);
end

%% ========================= CALCULATE FIELDS WITH CAPPING =========================
fprintf('\nCalculating fields with %.1f MV/m cap...\n', field_cap/1e6);

Ez = zeros(nr, nz);
Er = zeros(nr, nz);

% Calculate gradients
for i = 2:nr-1
    for j = 2:nz-1
        if electrode_map(i,j) == 0
            Ez(i,j) = -(V(i,j+1) - V(i,j-1))/(2*dz);
            Er(i,j) = -(V(i+1,j) - V(i-1,j))/(2*dr);
        end
    end
end

Ez(1,:) = Ez(2,:);
Er(1,:) = 0;

% Apply field cap
Ez_uncapped_max = max(abs(Ez(:)));
Er_uncapped_max = max(abs(Er(:)));

n_cap_Ez = sum(abs(Ez(:)) > field_cap);
n_cap_Er = sum(abs(Er(:)) > field_cap);

Ez(abs(Ez) > field_cap) = sign(Ez(abs(Ez) > field_cap)) * field_cap;
Er(abs(Er) > field_cap) = sign(Er(abs(Er) > field_cap)) * field_cap;

E_mag = sqrt(Ez.^2 + Er.^2);

fprintf('  Original peak Ez: %.1f MV/m → Capped to %.1f MV/m\n', ...
        Ez_uncapped_max/1e6, max(abs(Ez(:)))/1e6);
fprintf('  Original peak Er: %.1f MV/m → Capped to %.1f MV/m\n', ...
        Er_uncapped_max/1e6, max(abs(Er(:)))/1e6);
fprintf('  Capped Ez points: %d (%.2f%%)\n', n_cap_Ez, 100*n_cap_Ez/numel(Ez));
fprintf('  Capped Er points: %d (%.2f%%)\n', n_cap_Er, 100*n_cap_Er/numel(Er));

%% ========================= VALIDATION =========================
fprintf('\nValidating solution...\n');

V_min_actual = min(V(:));
V_max_actual = max(V(:));
fprintf('  Potential range: [%.1f, %.1f] kV\n', V_min_actual/1000, V_max_actual/1000);

% Check gap field
gap_center_z = anode.z_entrance / 2;
[~, gap_z_idx] = min(abs(z - gap_center_z));
E_gap_center = E_mag(1, gap_z_idx);
E_expected = abs(V_anode - V_cathode) / gap_distance;

fprintf('  Gap center field: %.2f MV/m (expected: %.2f MV/m)\n', ...
        E_gap_center/1e6, E_expected/1e6);
fprintf('  Field ratio: %.2f\n', E_gap_center/E_expected);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%% added 02.25.2026 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ==================================================================================
%% FIX 3: FIELD SOLVER ENHANCEMENT
%% ==================================================================================
%% Add to Pirce_Gun_field_solver_with_capping.m, in the VALIDATION section
%% (after "Gap center field" calculation, before SAVE section)
%% This saves the cathode surface field for cross-checking
%% ==================================================================================
%% ==================== CATHODE SURFACE FIELD CHARACTERIZATION ======================
% Extract and save the cathode surface field for PIC emission model
fprintf('\n  Cathode Surface Field Analysis:\n');

% Find field near cathode (z = 0 to 10mm, on-axis)
z_cath_idx = find(z >= 0 & z <= 0.010);
if ~isempty(z_cath_idx)
    Ez_cathode_profile = abs(Ez(1, z_cath_idx));
    [E_cathode_peak, idx_peak] = max(Ez_cathode_profile);
    z_cathode_peak = z(z_cath_idx(idx_peak));
    
    fprintf('    Peak on-axis field: %.2f MV/m at z=%.1f mm\n', ...
            E_cathode_peak/1e6, z_cathode_peak*1000);
    
    % Also check at several radial positions
    r_check = [0, 10, 20, 30, 40, 50, 60] * scale;  % mm → m
    fprintf('    Radial field profile at z=%.1f mm:\n', z_cathode_peak*1000);
    for rc = r_check
        [~, ir_check] = min(abs(r - rc));
        Ez_at_r = abs(Ez(ir_check, z_cath_idx(idx_peak)));
        fprintf('      r=%5.1f mm: Ez = %.2f MV/m\n', rc*1000, Ez_at_r/1e6);
    end
    
    % Calculate emission-weighted average (beam radius = 65mm)
    r_emit = 0.065;  % 65mm cathode radius
    ir_emit = find(r <= r_emit);
    Ez_emission_avg = mean(abs(Ez(ir_emit, z_cath_idx(idx_peak))));
    fprintf('    Emission-area average (r<65mm): %.2f MV/m\n', Ez_emission_avg/1e6);
    
    % Store for saving
    cathode_field_info = struct();
    cathode_field_info.E_peak_on_axis = E_cathode_peak;
    cathode_field_info.z_peak = z_cathode_peak;
    cathode_field_info.E_emission_average = Ez_emission_avg;
    cathode_field_info.radial_profile_r = r_check;
    cathode_field_info.radial_profile_Ez = zeros(size(r_check));
    for k = 1:length(r_check)
        [~, ir_k] = min(abs(r - r_check(k)));
        cathode_field_info.radial_profile_Ez(k) = abs(Ez(ir_k, z_cath_idx(idx_peak)));
    end
else
    fprintf('    WARNING: Cannot characterize cathode field\n');
    cathode_field_info = struct();
    cathode_field_info.E_peak_on_axis = NaN;
end

% ADD cathode_field_info to the save command:
% save('pierce_gun_field_solution_ready.mat', ..., 'cathode_field_info');

% Also save as _capped version for PIC compatibility
Ez_capped = Ez;  % Already capped at this point
Er_capped = Er;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ========================= SAVE SINGLE SOLUTION =========================
fprintf('\nSaving field solution...\n');

% Create full arrays for visualization
r_col = r(:);
r_full = [-flipud(r_col(2:end)); r_col];
V_full = [flipud(V(2:end,:)); V];
Ez_full = [flipud(Ez(2:end,:)); Ez];
Er_full = [-flipud(Er(2:end,:)); Er];
E_mag_full = [flipud(E_mag(2:end,:)); E_mag];
electrode_map_full = [flipud(electrode_map(2:end,:)); electrode_map];

save('pierce_gun_field_solution_ready.mat', ...
     'V', 'Ez', 'Er','Ez_capped', 'Er_capped', 'E_mag', ...
     'V_full', 'Ez_full', 'Er_full', 'E_mag_full', 'r_full', 'electrode_map_full', ...
     'z', 'r', 'Z', 'R', 'nr', 'nz', 'dr', 'dz', ...
     'electrode_map', 'V_cathode', 'V_anode', 'V_ground', ...
     'gap_distance', 'SCALE_FACTOR', ...
     'converged', 'field_cap', 'cathode_field_info');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
%save('pierce_gun_field_solution_capped.mat', ...
%     'V', 'Ez_capped', 'Er_capped', 'E_mag', ...
%     'z', 'r', 'Z', 'R', 'nr', 'nz', 'dr', 'dz', ...
%     'electrode_map', 'V_cathode', 'V_anode', 'V_ground', ...
%     'gap_distance', 'SCALE_FACTOR', ...
%     'converged', 'field_cap', 'cathode_field_info');
%fprintf('  Also saved as: pierce_gun_field_solution_capped.mat\n');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fprintf('  ✓ Saved to: pierce_gun_field_solution_ready.mat\n');

%% ========================= SUMMARY =========================
fprintf('\n================================================================\n');
fprintf('                    SOLUTION COMPLETE                           \n');
fprintf('================================================================\n');
fprintf('  Converged: %s\n', string(converged));
fprintf('  Potential range: [%.1f, %.1f] kV\n', V_min_actual/1000, V_max_actual/1000);
fprintf('  Max field (capped): %.1f MV/m\n', max(E_mag(:))/1e6);
fprintf('  Gap center field: %.2f MV/m\n', E_gap_center/1e6);
fprintf('  Domain: %.0f to %.0f mm\n', chamber.z_start*1000, chamber.z_end*1000);
fprintf('  Ready for PIC simulation: YES\n');
fprintf('================================================================\n');