%% Process raw radionuclide data into the TITANICA/Nautilica template
% ---------------------------------------------------------------------
% Reads a raw data file, computes TEOS-10 derived variables, converts
% tracer concentrations from at/kg to at/L, and writes out a .mat and
% .xlsx file with columns in the standard group order.
%
% Expected raw-file columns (headings must match exactly):
%   Cruise, Section, Station, Cast,
%   Latitude_degN, Longitude_degE, Date, Time, Bottom_Depth_m, Bottle,
%   Pressure_dbar, Temp_C, Salinity_psu, Sample_ID,
%   I129_at_kg, unc_I129_at_kg, I129_flag,
%   U236_at_kg, unc_U236_at_kg, U236_flag,
%   U236_U238, unc_U236_U238, U236_U238_flag,
%   U238_ppb, unc_U238_ppb,
%   water_mass, comments
%
% Requires: TEOS-10 (gsw) MATLAB toolbox on the path.
% ---------------------------------------------------------------------

clear; clc; close all;

%% ---- Folder paths (edit these) ----
dataDir   = 'data';
outputDir = 'output';
figureDir = 'figures';
if ~exist(outputDir, 'dir'), mkdir(outputDir); end
if ~exist(figureDir, 'dir'), mkdir(figureDir); end

%% ---- File names (edit these) ----
inputFile      = fullfile(dataDir,   'Your_Filename_raw.xlsx');
outputFileBase = fullfile(outputDir, 'Your_Filename_processed');

%% Load raw data
D = readtable(inputFile);

%% Shortcuts for TEOS-10 inputs
p   = D.Pressure_dbar;
lon = D.Longitude_degE;
lat = D.Latitude_degN;
SP  = D.Salinity_psu;     % practical salinity
t   = D.Temp_C;           % in-situ temperature (degC)

%% Derived oceanographic variables
Depth_m       = -1 * gsw_z_from_p(p, lat);              % positive downwards, m
Abs_Sal       = gsw_SA_from_SP(SP, p, lon, lat);        % absolute salinity, g/kg
Con_Temp      = gsw_CT_from_t(Abs_Sal, t, p);           % conservative temperature, degC
Pot_Temp      = gsw_pt0_from_t(Abs_Sal, t, p);          % potential temperature at 0 dbar, degC
Density_kgm3  = gsw_rho(Abs_Sal, Con_Temp, p);          % in-situ density, kg/m^3
Sigma_0       = gsw_sigma0(Abs_Sal, Con_Temp);          % potential density anomaly, ref 0    dbar
Sigma_1000    = gsw_sigma1(Abs_Sal, Con_Temp);          % potential density anomaly, ref 1000 dbar
Sigma_2000    = gsw_sigma2(Abs_Sal, Con_Temp);          % potential density anomaly, ref 2000 dbar

%% Convert tracer concentrations from at/kg to at/L
rho_kgL        = Density_kgm3 / 1000;                   % in-situ density in kg/L
I129_at_l      = D.I129_at_kg     .* rho_kgL;
unc_I129_at_l  = D.unc_I129_at_kg .* rho_kgL;
U236_at_l      = D.U236_at_kg     .* rho_kgL;
unc_U236_at_l  = D.unc_U236_at_kg .* rho_kgL;

%% Assemble output table with columns in the standard group order
D_out = table( ...
    D.Cruise, D.Section, D.Station, D.Cast, ...
    lat, lon, D.Date, D.Time, D.Bottom_Depth_m, D.Bottle, ...
    p, Depth_m, t, Pot_Temp, Con_Temp, SP, Abs_Sal, Density_kgm3, ...
    Sigma_0, Sigma_1000, Sigma_2000, ...
    D.Sample_ID, ...
    D.I129_at_kg, D.unc_I129_at_kg, D.I129_flag, I129_at_l, unc_I129_at_l, ...
    D.U236_at_kg, D.unc_U236_at_kg, D.U236_flag, U236_at_l, unc_U236_at_l, ...
    D.U236_U238, D.unc_U236_U238, D.U236_U238_flag, ...
    D.U238_ppb, D.unc_U238_ppb, ...
    D.water_mass, D.comments, ...
    'VariableNames', { ...
        'Cruise','Section','Station','Cast', ...
        'Latitude_degN','Longitude_degE','Date','Time','Bottom_Depth_m','Bottle', ...
        'Pressure_dbar','Depth_m','Temp_C','Pot_Temp','Con_Temp', ...
        'Salinity_psu','Abs_Sal','Density_kgm3', ...
        'Sigma_0','Sigma_1000','Sigma_2000', ...
        'Sample_ID', ...
        'I129_at_kg','unc_I129_at_kg','I129_flag','I129_at_l','unc_I129_at_l', ...
        'U236_at_kg','unc_U236_at_kg','U236_flag','U236_at_l','unc_U236_at_l', ...
        'U236_U238','unc_U236_U238','U236_U238_flag', ...
        'U238_ppb','unc_U238_ppb', ...
        'water_mass','comments'});

%% Save outputs
save([outputFileBase '.mat'], 'D_out');
writetable(D_out, [outputFileBase '.xlsx']);

fprintf('Processed %d rows. Output saved to:\n  %s.mat\n  %s.xlsx\n', ...
        height(D_out), outputFileBase, outputFileBase);
