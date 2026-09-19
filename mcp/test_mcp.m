% =============================================================================
% testMCP.m — MCP Connection Sanity Check
% =============================================================================
%
% PURPOSE:
%   Run this script to verify that your AI agent can successfully communicate
%   with MATLAB via the MATLAB MCP server.
%
% HOW TO USE:
%   Option A: Ask your AI agent "Run testMCP.m and tell me the result"
%   Option B: Run it directly in MATLAB: >> testMCP
%
% EXPECTED OUTPUT (if everything is working):
%   ============================================
%   MCP CONNECTION TEST — AI GRAND PRIX
%   ============================================
%   [OK] MATLAB is running
%   [OK] MATLAB version: 9.13.0.xxxx (R2024b)
%   [OK] Working directory: C:\...\AI_Grand_Prix
%   [OK] student/controller.m found
%   [OK] simulator/ folder found
%   ============================================
%   All checks passed. You're ready to race!
%   ============================================
%
% =============================================================================

fprintf('\n============================================\n');
fprintf('MCP CONNECTION TEST — AI GRAND PRIX\n');
fprintf('============================================\n');

% --- Check 1: MATLAB is running (trivially true if this runs) ---
fprintf('[OK] MATLAB is running\n');

% --- Check 2: MATLAB version ---
v = version;
fprintf('[OK] MATLAB version: %s\n', v);

% --- Check 3: Working directory ---
cwd = pwd;
fprintf('[OK] Working directory: %s\n', cwd);

% --- Check 4: controller.m present ---
if exist('student/controller.m', 'file') || exist('controller.m', 'file')
    fprintf('[OK] student/controller.m found\n');
else
    fprintf('[!!] student/controller.m NOT found\n');
    fprintf('     Make sure you ran this from the AI_Grand_Prix project folder.\n');
    fprintf('     Try: cd(''path/to/AI_Grand_Prix'') then run testMCP\n');
end

% --- Check 5: simulator folder present ---
if exist('simulator', 'dir')
    fprintf('[OK] simulator/ folder found\n');
else
    fprintf('[!!] simulator/ folder NOT found\n');
    fprintf('     Make sure you are in the AI_Grand_Prix project root folder.\n');
end

% --- Summary ---
fprintf('============================================\n');
fprintf('All checks done. If all lines show [OK], you are ready to race!\n');
fprintf('============================================\n\n');
