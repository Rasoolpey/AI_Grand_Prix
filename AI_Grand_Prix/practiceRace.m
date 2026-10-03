function results = practiceRace(varargin)
% PRACTICERACE  Run a local practice race with your autonomous controller.
%
%   USAGE:
%     practiceRace                          % run with visualisation
%     practiceRace('Headless', true)        % fast run, no animation
%     results = practiceRace(...)           % also return results struct
%
%   OPTIONS (name-value pairs):
%     'Headless'   logical  — skip animation (faster, useful for rapid tuning)
%                            default: false
%     'MaxTime'    numeric  — maximum allowed lap time in seconds
%                            default: 120
%     'DT'         numeric  — simulation timestep in seconds
%                            default: 0.02  (50 Hz)
%
%   RETURNS:
%     results.lapCompleted  — true if lap finished within MaxTime
%     results.lapTime       — lap time in seconds (Inf if DNF)
%     results.nOffTrack     — number of off-track excursions (debounced)
%     results.nCollision    — number of hard barrier contacts
%     results.dnf           — true if did not finish
%     results.dnfReason     — reason string
%     results.score         — lapTime + 5*exits + 10*collisions (Inf if DNF)
%     results.log           — full telemetry struct for plotLap()
%
%   EXAMPLES:
%     % Run and check score
%     r = practiceRace('Headless', true);
%     fprintf('Score: %.2f\n', r.score);
%
%     % Run and plot diagnostics
%     r = practiceRace('Headless', true);
%     plotLap(r);
%
%   See also: plotLap, student/controller.m, AGENT_GUIDE.md

    % ------------------------------------------------------------------ %
    %  Parse name-value options                                           %
    % ------------------------------------------------------------------ %
    p = inputParser();
    p.addParameter('Headless', false, @(x) islogical(x) || isnumeric(x));
    p.addParameter('MaxTime',  180,   @isnumeric);
    p.addParameter('DT',       0.02,  @isnumeric);

    p.parse(varargin{:});
    opts = p.Results;
    opts.Headless = logical(opts.Headless);

    % ------------------------------------------------------------------ %
    %  Setup paths                                                        %
    % ------------------------------------------------------------------ %
    thisDir = fileparts(mfilename('fullpath'));
    addpath(fullfile(thisDir, 'simulator'));
    addpath(fullfile(thisDir, 'student'));
    addpath(fullfile(thisDir, 'tracks'));

    % ------------------------------------------------------------------ %
    %  Load (or generate) practice track                                 %
    % ------------------------------------------------------------------ %
    trackFile = fullfile(thisDir, 'tracks', 'practiceTrack.mat');
    if ~exist(trackFile, 'file')
        fprintf('  Generating practice track for the first time...\n');
        trackData = createPracticeTrack();
        save(trackFile, 'trackData');
        fprintf('  Saved to tracks/practiceTrack.mat\n');
    else
        load(trackFile, 'trackData'); %#ok<LOAD>
    end
    track = Track(trackData);

    % ------------------------------------------------------------------ %
    %  Load student controller config                                    %
    % ------------------------------------------------------------------ %
    config = struct();
    try
        config = robotConfig();
    catch ME
        warning('practiceRace: Could not load robotConfig — %s', ME.message);
    end

    % ------------------------------------------------------------------ %
    %  Initialise vehicle at start/finish line                           %
    % ------------------------------------------------------------------ %
    startPos   = trackData.centreline(1, :);
    startTang  = trackData.centreline(2,:) - trackData.centreline(1,:);
    startHeading = atan2(startTang(2), startTang(1));
    vehicle = Vehicle(startPos(1), startPos(2), startHeading);

    % ------------------------------------------------------------------ %
    %  Print banner                                                       %
    % ------------------------------------------------------------------ %
    fprintf('\n');
    fprintf('============================================================\n');
    fprintf('  AI GRAND PRIX — Practice Race\n');
    fprintf('  Track  : %s  (%.0f m)\n', track.name, track.lapLength);
    fprintf('  MaxTime: %.0f s     DT: %.3f s     Headless: %d\n', ...
        opts.MaxTime, opts.DT, opts.Headless);
    fprintf('============================================================\n');

    % ------------------------------------------------------------------ %
    %  Run simulation                                                     %
    % ------------------------------------------------------------------ %
    simOpts.headless = opts.Headless;
    simOpts.maxTime  = opts.MaxTime;
    simOpts.dt       = opts.DT;

    tic;
    results = RaceSimulation(track, vehicle, @controller, config, simOpts);
    wallTime = toc;

    % ------------------------------------------------------------------ %
    %  Print results                                                      %
    % ------------------------------------------------------------------ %
    fprintf('============================================================\n');
    fprintf('  RACE RESULTS\n');
    fprintf('------------------------------------------------------------\n');
    if results.dnf
        fprintf('  Result    : DNF — %s\n', results.dnfReason);
    else
        fprintf('  Result    : Lap completed  ✓\n');
        fprintf('  Lap time  : %.2f s\n', results.lapTime);
    end
    fprintf('  Off-track : %d event(s)\n', results.nOffTrack);
    fprintf('  Collisions: %d event(s)\n', results.nCollision);
    if ~results.dnf
        fprintf('  Score     : %.2f  (time + 5×exits + 10×collisions)\n', results.score);
    end
    fprintf('  Wall time : %.2f s\n', wallTime);
    fprintf('============================================================\n\n');

    % Return nothing (suppress ans output) if called without assignment
    if nargout == 0
        clear results;
    end

end
