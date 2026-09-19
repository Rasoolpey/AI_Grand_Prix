% =========================================================================
% testMCP.m — AI Grand Prix MCP Connection Sanity Check
% =========================================================================
%
%   Run this script to verify your AI agent can talk to MATLAB.
%
%   HOW TO USE:
%     Ask your agent: "Run testMCP and tell me the result"
%     OR run it directly in MATLAB:  >> testMCP
%
%   EXPECTED OUTPUT (all green = good to go):
%     [OK] MATLAB is running: R2024b
%     [OK] Working directory: C:\...\AI_Grand_Prix
%     [OK] simulator/ folder found
%     [OK] student/controller.m found
%     [OK] student/robotConfig.m found
%     [OK] practiceRace.m found
%     [OK] plotLap.m found
%     [OK] tracks/ folder found
%     =============================================
%     All checks passed. You are ready to race!
%
%   If any line shows [!!], fix that issue before starting the workshop.
%   See SETUP.md for troubleshooting help.
%
% =========================================================================

fprintf('\n=============================================\n');
fprintf('  MCP CONNECTION TEST — AI Grand Prix\n');
fprintf('=============================================\n');

allGood = true;

% --- Check 1: MATLAB is running ---
fprintf('[OK] MATLAB is running: %s\n', version('-release'));

% --- Check 2: Working directory ---
cwd = pwd;
fprintf('[OK] Working directory: %s\n', cwd);

% --- Check 3: Required folders ---
folders = {'simulator', 'student', 'tracks'};
for k = 1:numel(folders)
    if exist(folders{k}, 'dir')
        fprintf('[OK] %s/ folder found\n', folders{k});
    else
        fprintf('[!!] %s/ folder NOT found\n', folders{k});
        fprintf('     Make sure you are running from the AI_Grand_Prix root folder.\n');
        fprintf('     In MATLAB: cd(''path/to/AI_Grand_Prix'')  then run testMCP\n');
        allGood = false;
    end
end

% --- Check 4: Required files ---
files = {
    'student/controller.m',   'student controller';
    'student/robotConfig.m',  'student config';
    'practiceRace.m',         'race runner';
    'plotLap.m',              'diagnostic plotter';
};
for k = 1:size(files,1)
    if exist(files{k,1}, 'file')
        fprintf('[OK] %s found  (%s)\n', files{k,1}, files{k,2});
    else
        fprintf('[!!] %s NOT found\n', files{k,1});
        allGood = false;
    end
end

% --- Check 5: Simulator classes loadable ---
try
    addpath('simulator'); addpath('student'); addpath('tracks');
    v = Vehicle(0, 0, 0);
    fprintf('[OK] Vehicle class loaded (max speed: %.0f m/s)\n', v.MAX_SPEED);
catch ME
    fprintf('[!!] Could not load Vehicle class: %s\n', ME.message);
    allGood = false;
end

% --- Summary ---
fprintf('=============================================\n');
if allGood
    fprintf('  All checks passed. You are ready to race!\n');
    fprintf('  Next step: Ask your agent to run practiceRace\n');
else
    fprintf('  One or more checks failed. See SETUP.md.\n');
end
fprintf('=============================================\n\n');
