function [S, R] = qualify(varargin)
% QUALIFY  Run every team on every final path, each team in its own MATLAB (F6).
%
%   [S, R] = qualify()                        uses finals/finals.mat and submissions/
%   qualify('Workers', 6, 'PathWallLimit', 120, 'AllowFlagged', ["TeamX"])
%
%   Each team runs in a separate MATLAB process (qualifyOne) from its own copy
%   of its files.  A crash ends only that process; a hang is stopped by a
%   wall-clock limit per path and that path becomes a DNF ("wall-clock
%   timeout"); the team's other paths are then run in a fresh process.
%   This contains crashes and hangs.  It is NOT a security sandbox: read the
%   code collectSubmissions flags.  Flagged teams are skipped unless named
%   in 'AllowFlagged' (or 'AllowFlagged', true for all).
%
%   Options:
%     'Finals'         finals file              (finals/finals.mat)
%     'Submissions'    unpacked team folders    (submissions/)
%     'Out'            results folder           (results/)
%     'Workers'        MATLAB processes at once (4)
%     'PathWallLimit'  wall-clock seconds per path (120)
%     'Startup'        wall-clock seconds for MATLAB to start (120)
%     'Teams'          only these teams         (all)
%
%   Outputs: S = standings table (also results/results.csv), R = per run results.
%
%   See also: collectSubmissions, qualifyOne, standings, raceDay

    here = fileparts(mfilename('fullpath'));
    o = inputParser();
    o.addParameter('Finals', fullfile(here, 'finals', 'finals.mat'));
    o.addParameter('Submissions', fullfile(here, 'submissions'));
    o.addParameter('Out', fullfile(here, 'results'));
    o.addParameter('Workers', 4);
    o.addParameter('PathWallLimit', 120);
    o.addParameter('Startup', 120);
    o.addParameter('Teams', []);
    o.addParameter('AllowFlagged', false);
    o.parse(varargin{:});
    opt = o.Results;
    simRoot = char(java.io.File(fullfile(here, '..', '..', 'AI_Grand_Prix')).getCanonicalPath());
    finalsFile = char(java.io.File(opt.Finals).getCanonicalPath());
    L = load(finalsFile, 'F');  F = L.F;
    nP = numel(F.ids);
    outDir = opt.Out;  runRoot = fullfile(outDir, 'run');
    if ~exist(runRoot, 'dir'), mkdir(runRoot); end

    % ---- teams ---------------------------------------------------------- %
    d = dir(opt.Submissions);
    teams = string({d([d.isdir] & ~startsWith({d.name}, '.')).name});
    if ~isempty(opt.Teams), teams = intersect(teams, string(opt.Teams)); end
    flagged = strings(0);
    cf = fullfile(opt.Submissions, 'collected.csv');
    if exist(cf, 'file')
        C = readtable(cf, 'TextType', 'string', 'Delimiter', ',');
        folders = C.folder(logical(C.flagged));
        flagged = arrayfun(@(f) string(regexprep(char(f), '^.*[\\/]', '')), folders);
    end
    allow = opt.AllowFlagged;
    skip = strings(0);
    for t = teams
        if ismember(t, flagged) && ~(isequal(allow, true) || ismember(t, string(allow)))
            skip(end+1) = t; %#ok<AGROW>
        end
    end
    if ~isempty(skip)
        fprintf('Skipping flagged teams (read their code, then pass ''AllowFlagged''): %s\n', strjoin(skip, ', '));
    end
    teams = setdiff(teams, skip, 'stable');

    % ---- job queue ------------------------------------------------------ %
    for t = teams
        rd = fullfile(runRoot, t);
        if exist(rd, 'dir'), rmdir(rd, 's'); end
        mkdir(rd);
        copyfile(fullfile(opt.Submissions, t, '*'), rd);
        for k = 1:nP                                   % fresh results
            base = fullfile(outDir, t + "__" + F.ids(k));
            if exist(base + ".mat", 'file'), delete(base + ".mat"); end
            if exist(base + ".started", 'file'), delete(base + ".started"); end
        end
    end
    queue = struct('team', cellstr(teams), 'paths', {1:nP});
    running = struct('team', {}, 'paths', {}, 'proc', {}, 'launched', {});
    if ispc, exe = fullfile(matlabroot, 'bin', 'win64', 'MATLAB.exe'); else, exe = fullfile(matlabroot, 'bin', 'matlab'); end
    fprintf('Qualifying %d teams x %d paths with %d MATLAB processes...\n', numel(teams), nP, opt.Workers);
    tStart = tic;

    while ~isempty(queue) || ~isempty(running)
        while numel(running) < opt.Workers && ~isempty(queue)
            job = queue(1);  queue(1) = [];
            rd = fullfile(runRoot, job.team);
            cmd = sprintf('addpath(''%s''); qualifyOne(''%s'', ''%s'', ''%s'', [%s], ''%s'');', here, rd, ...
                finalsFile, char(java.io.File(outDir).getCanonicalPath()), num2str(job.paths), simRoot);
            pb = java.lang.ProcessBuilder({exe, '-batch', cmd});
            pb.directory(java.io.File(rd));
            pb.redirectErrorStream(true);
            pb.redirectOutput(java.io.File(fullfile(outDir, job.team + ".log")));
            job.proc = pb.start();
            job.launched = tic;
            running(end+1) = job; %#ok<AGROW>
        end
        pause(1);
        k = 1;
        while k <= numel(running)
            job = running(k);
            [doneIdx, startedIdx, startedAge] = progressOf(outDir, job.team, F.ids, job.paths);
            current = setdiff(startedIdx, doneIdx);
            timeout = false;
            if isempty(startedIdx)
                timeout = toc(job.launched) > opt.Startup;
            elseif ~isempty(current)
                timeout = startedAge(current(1) == startedIdx) > opt.PathWallLimit;
            end
            if ~job.proc.isAlive() || timeout
                if job.proc.isAlive(), job.proc.destroyForcibly(); pause(0.5); end
                left = setdiff(job.paths, doneIdx, 'stable');
                if ~isempty(left)
                    first = left(1);
                    if timeout
                        why = "Wall-clock timeout (controller too slow or stuck)";
                    elseif ismember(first, startedIdx)
                        why = "MATLAB process ended during this path";
                    else
                        why = "MATLAB process ended before this path";
                    end
                    writeDnf(outDir, job.team, F.ids(first), why);
                    rest = left(2:end);
                    if ~isempty(rest) && (timeout || ismember(first, startedIdx))
                        queue(end+1) = struct('team', job.team, 'paths', rest); %#ok<AGROW>
                    else
                        for r = rest, writeDnf(outDir, job.team, F.ids(r), why); end
                    end
                end
                running(k) = [];
                fprintf('  %-20s done (%.0f s since start)\n', job.team, toc(tStart));
            else
                k = k + 1;
            end
        end
    end
    fprintf('Qualifying finished in %.0f s\n', toc(tStart));

    % ---- collect -------------------------------------------------------- %
    R = struct([]);
    for t = teams
        for k = 1:nP
            f = fullfile(outDir, t + "__" + F.ids(k) + ".mat");
            x = load(f, 'res');
            R = [R; x.res]; %#ok<AGROW>
        end
    end
    save(fullfile(outDir, 'runs.mat'), 'R', 'F');
    S = standings(R, F);
    writetable(S, fullfile(outDir, 'results.csv'));
    disp(S);
    fprintf('Saved %s\n', fullfile(outDir, 'results.csv'));
end

function [doneIdx, startedIdx, startedAge] = progressOf(outDir, team, ids, paths)
    doneIdx = [];  startedIdx = [];  startedAge = [];
    for k = paths
        base = fullfile(outDir, team + "__" + ids(k));
        if exist(base + ".mat", 'file'), doneIdx(end+1) = k; end %#ok<AGROW>
        s = dir(base + ".started");
        if ~isempty(s)
            startedIdx(end+1) = k; %#ok<AGROW>
            startedAge(end+1) = seconds(datetime('now') - datetime(s.datenum, 'ConvertFrom', 'datenum')); %#ok<AGROW>
        end
    end
end

function writeDnf(outDir, team, id, why)
    res = struct('finished', false, 'dnf', true, 'dnfReason', string(why), 'time', Inf, 'penalty', 0, ...
        'totalTime', Inf, 'nOffTrack', 0, 'nBarrier', 0, 'stopInRunoff', false, 'lapTimes', [], ...
        'energyUsedWh', 0, 'batteryLeftFrac', 1, 'checkpointsPassed', 0, ...
        'log', struct('t', single([]), 'x', single([]), 'y', single([]), 'theta', single([]), 'v', single([]), ...
        'progress', single([]), 'lap', uint8([])), 'parts', struct(), 'team', string(team), 'pathId', string(id), ...
        'colour', [0.5 0.5 0.5], 'teamName', string(team));
    save(fullfile(outDir, team + "__" + id + ".mat"), 'res');
end
