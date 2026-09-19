function evaluateAll(trackName, submissionsDir)
% EVALUATEALL  Run all submitted controllers and produce the final leaderboard.
%
%   ╔══════════════════════════════════════════════╗
%   ║  INSTRUCTOR TOOL — Run on evaluation machine ║
%   ╚══════════════════════════════════════════════╝
%
%   USAGE:
%     evaluateAll                          % uses 'mystery' track
%     evaluateAll('practice')             % use practice track instead
%     evaluateAll('mystery', 'path/to/submissions')
%
%   EXPECTED FOLDER LAYOUT:
%     submissions/
%       TeamAlpha/
%         controller.m       ← required
%         robotConfig.m      ← optional (uses defaults if missing)
%       TeamBeta/
%         controller.m
%       ...
%
%   WHAT IT DOES:
%     1. Loads each team's controller.m (isolated from other teams)
%     2. Runs a full timed lap on the selected track (headless)
%     3. Catches any crash/timeout — it becomes a DNF, not a script error
%     4. Prints a sorted final leaderboard
%
%   SCORING:  Score = LapTime + 5×Exits + 10×Collisions   (lower = better)
%             DNF teams are listed at the bottom.
%
%   See also: practiceRace, tracks/createMysteryTrack.m

    % ------------------------------------------------------------------ %
    %  Defaults                                                           %
    % ------------------------------------------------------------------ %
    if nargin < 1 || isempty(trackName),    trackName     = 'mystery';     end
    if nargin < 2 || isempty(submissionsDir)
        submissionsDir = fullfile(fileparts(mfilename('fullpath')), 'submissions');
    end

    % ------------------------------------------------------------------ %
    %  Add simulator paths                                                %
    % ------------------------------------------------------------------ %
    thisDir = fileparts(mfilename('fullpath'));
    addpath(fullfile(thisDir, 'simulator'));
    addpath(fullfile(thisDir, 'tracks'));

    % ------------------------------------------------------------------ %
    %  Load track                                                         %
    % ------------------------------------------------------------------ %
    trackFile = fullfile(thisDir, 'tracks', [trackName, 'Track.mat']);
    if ~exist(trackFile, 'file')
        % Auto-generate if missing
        fprintf('Track file not found — generating %s track...\n', trackName);
        if strcmpi(trackName, 'mystery')
            trackData = createMysteryTrack();
        else
            trackData = createPracticeTrack();
        end
        save(trackFile, 'trackData');
        fprintf('Saved to %s\n', trackFile);
    else
        load(trackFile, 'trackData'); %#ok<LOAD>
    end
    track = Track(trackData);

    % ------------------------------------------------------------------ %
    %  Banner                                                             %
    % ------------------------------------------------------------------ %
    fprintf('\n');
    fprintf('================================================================\n');
    fprintf('  AI GRAND PRIX — Championship Evaluation\n');
    fprintf('  Track       : %s  (%.0f m)\n', track.name, track.lapLength);
    fprintf('  Submissions : %s\n', submissionsDir);
    fprintf('================================================================\n\n');

    % ------------------------------------------------------------------ %
    %  Discover submissions                                               %
    % ------------------------------------------------------------------ %
    entries = dir(submissionsDir);
    entries = entries([entries.isdir]);
    entries = entries(~ismember({entries.name}, {'.', '..'}));

    if isempty(entries)
        fprintf('  No team folders found in:\n  %s\n\n', submissionsDir);
        fprintf('  Expected layout:\n');
        fprintf('    submissions/\n');
        fprintf('      TeamName/\n');
        fprintf('        controller.m\n');
        fprintf('        robotConfig.m   (optional)\n');
        return;
    end

    nTeams  = numel(entries);
    results = cell(nTeams, 1);

    % ------------------------------------------------------------------ %
    %  Evaluate each team                                                 %
    % ------------------------------------------------------------------ %
    for i = 1:nTeams
        teamName = entries(i).name;
        teamDir  = fullfile(submissionsDir, teamName);
        ctrlFile = fullfile(teamDir, 'controller.m');

        fprintf('[%d/%d]  %-25s ... ', i, nTeams, teamName);

        if ~exist(ctrlFile, 'file')
            fprintf('SKIPPED (no controller.m)\n');
            results{i} = blankResult(teamName, true, 'No controller.m');
            continue;
        end

        % Load team config (if present)
        config = struct();
        cfgFile = fullfile(teamDir, 'robotConfig.m');
        if exist(cfgFile, 'file')
            try
                % Add team dir temporarily, call robotConfig
                prevPath = path();
                path(teamDir, prevPath);
                config = robotConfig();
                path(prevPath);
            catch
                path(prevPath);   % ensure path is restored even on error
            end
        end

        % Initialise fresh vehicle at start line
        vehicle = Vehicle(trackData.centreline(1,1), ...
                          trackData.centreline(1,2), 0);

        % Run simulation (headless, with error protection)
        simOpts.headless = true;
        simOpts.maxTime  = 180;
        simOpts.dt       = 0.02;

        try
            r = RaceSimulation(track, vehicle, ...
                makeControllerFn(teamDir), config, simOpts);

            results{i}.teamName   = teamName;
            results{i}.dnf        = r.dnf;
            results{i}.lapTime    = r.lapTime;
            results{i}.nOffTrack  = r.nOffTrack;
            results{i}.nCollision = r.nCollision;
            results{i}.score      = r.score;
            results{i}.dnfReason  = r.dnfReason;

            if r.dnf
                fprintf('DNF  (%s)\n', r.dnfReason);
            else
                fprintf('%.2f s  |  exits=%d  |  score=%.2f\n', ...
                    r.lapTime, r.nOffTrack, r.score);
            end

        catch ME
            fprintf('ERROR — %s\n', ME.message);
            results{i} = blankResult(teamName, true, ME.message);
        end
    end

    % ------------------------------------------------------------------ %
    %  Sort by score (DNF → bottom)                                      %
    % ------------------------------------------------------------------ %
    scores   = cellfun(@(r) r.score, results);
    [~, idx] = sort(scores, 'ascend');

    % ------------------------------------------------------------------ %
    %  Print leaderboard                                                  %
    % ------------------------------------------------------------------ %
    fprintf('\n');
    fprintf('================================================================\n');
    fprintf('  FINAL LEADERBOARD — %s Track\n', upper(trackName));
    fprintf('================================================================\n');
    fprintf('  %-4s  %-24s  %-9s  %-6s  %-6s  %-8s\n', ...
        'Pos', 'Team', 'Lap Time', 'Exits', 'Collsn', 'Score');
    fprintf('  %s\n', repmat('-', 1, 63));

    pos = 1;
    for k = 1:nTeams
        r = results{idx(k)};
        if r.dnf
            fprintf('  %-4s  %-24s  %-9s  %-6d  %-6d  DNF  (%s)\n', ...
                'DNF', r.teamName, '—', r.nOffTrack, r.nCollision, r.dnfReason);
        else
            fprintf('  %-4d  %-24s  %-9.2f  %-6d  %-6d  %-8.2f\n', ...
                pos, r.teamName, r.lapTime, r.nOffTrack, r.nCollision, r.score);
            pos = pos + 1;
        end
    end
    fprintf('================================================================\n\n');

end

% ======================================================================= %
%  Local helpers                                                           %
% ======================================================================= %

function fn = makeControllerFn(teamDir)
% Return a function handle that calls the team's controller.m in isolation.
% Each call prepends teamDir to the path and clears any cached controller.
    fn = @(obs, cfg) callIsolated(obs, cfg, teamDir);
end

function command = callIsolated(obs, config, teamDir)
% Execute team's controller with temporary path isolation.
    prevPath = path();
    path(teamDir, prevPath);
    cleanupObj = onCleanup(@() path(prevPath));

    % Force reload in case previous team's controller is cached
    clear('controller');
    rehash();

    try
        command = controller(obs, config);
    catch ME
        % Return emergency stop; simulation will handle DNF
        command.throttle = -1;
        command.steering = 0;
        warning('evaluateAll: controller error — %s', ME.message);
    end
end

function r = blankResult(teamName, isDnf, reason)
    r.teamName   = teamName;
    r.dnf        = isDnf;
    r.lapTime    = Inf;
    r.nOffTrack  = 0;
    r.nCollision = 0;
    r.score      = Inf;
    r.dnfReason  = reason;
end
