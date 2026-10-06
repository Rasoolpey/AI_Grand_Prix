function S = finalRace(folder, varargin)
% FINALRACE  The projector finale: race every student model in one folder.
%
%   finalRace(folder)                       every model in FOLDER, on the race-day paths
%   finalRace(folder, 'Paths', "practice")  rehearsal on the four practice paths
%   S = finalRace(...)                      also returns the standings table
%
%   A model is a student's best model: the <team>.zip that
%   practiceRace('Path', 'all') saves in their best_model/ folder (submitCar
%   adds their engineering log).  Copy every model into one folder (zips, or
%   the same files unzipped in sub-folders) and run this.  The name on
%   screen is car.team INSIDE each model, not the file name.
%
%   1. Scrutineering: every model is checked (legal car, code scan) and
%      driven on every path here, on this computer, with the same physics.
%   2. Each race: every car on the track at once (ghost cars: they do not
%      touch), paced so it lasts about 'Seconds' on screen, with a live
%      running order.  Then that race's results.
%   3. The final standings: overall = 0.6 x mean + 0.4 x min of the path
%      scores; cars that finished every path rank first.
%
%   Options:
%     'Paths'        "finals"   finals/finals.mat from makeFinals (default when it exists)
%                    "practice" the four practice paths (rehearsal)
%     'Seconds'      on-screen length of a race, set by the reference time   (12)
%     'Pause'        wait for a key between scenes (false: 4 s each)          (true)
%     'AllowFlagged' also race models the code scan flagged (read them first) (false)
%     'RunLimit'     computing seconds one car may use on one path (then DNF) (60)
%     'Out'          results folder                (results/final_<date>_<time>)
%     'SaveFrames'   folder: save still frames instead of animating           ("")
%
%   A model whose controller loops forever stops the scrutineering on its own
%   line: press Ctrl+C, take that file out of the folder and run again.  For
%   full isolation (each team in its own MATLAB) use collectSubmissions +
%   qualify + raceDay instead.
%
%   See also: raceDay, makeFinals, scanModelCode, standings

    here = fileparts(mfilename('fullpath'));
    o = inputParser();
    o.addParameter('Paths', "");
    o.addParameter('Seconds', 12);
    o.addParameter('Pause', true);
    o.addParameter('AllowFlagged', false);
    o.addParameter('RunLimit', 60);
    o.addParameter('Out', "");
    o.addParameter('SaveFrames', "");
    o.parse(varargin{:});
    opt = o.Results;
    simRoot = fullfile(here, '..', '..', 'AI_Grand_Prix');
    addpath(fullfile(simRoot, 'simulator'), fullfile(simRoot, 'simulator', 'physics'), fullfile(simRoot, 'tracks'), here);

    % ---- the paths ------------------------------------------------------ %
    finalsFile = fullfile(here, 'finals', 'finals.mat');
    which = string(opt.Paths);
    if which == ""
        which = "practice";
        if exist(finalsFile, 'file'), which = "finals"; end
    end
    if which == "finals"
        L = load(finalsFile, 'F');  F = L.F;
        fprintf('Race-day paths: %s (%s)\n', strjoin(F.ids, ', '), finalsFile);
    else
        F.ids = ["drag", "technical", "endurance", "mud"];
        F.courses = arrayfun(@(n) loadPath(n), F.ids, 'UniformOutput', false);
        F.tref = arrayfun(@(n) practiceReference(n), F.ids);
        F.seed = NaN;  F.created = string(datetime('now'));
        fprintf('REHEARSAL on the practice paths (race-day paths: run makeFinals(seed) first)\n');
    end
    nP = numel(F.ids);

    % ---- the models ----------------------------------------------------- %
    M = findModels(folder);
    nM = numel(M);
    if nM == 0
        error('finalRace:none', 'No models in %s: copy the students'' <team>.zip files there.', folder);
    end
    fprintf('%d models in %s\n', nM, folder);
    cleanup = onCleanup(@() removeStage(M));

    % ---- scrutineering: check and drive every model ---------------------- %
    scr = Scrutineering(M, F, opt);
    R = [];
    for i = 1:nM
        scr.mark(i, "checking", [1 0.85 0.3], M(i).label);
        [flagged, findings] = scanModelCode(M(i).dir);
        addpath(M(i).dir, '-begin');
        rehash;
        clear carDesign controller robotConfig
        car = [];  name = M(i).label;  err = "";
        try
            car = buildCar(carDesign());
            name = car.team;
        catch ME
            err = "Invalid car: " + ME.message;
        end
        config = struct();
        try, config = robotConfig(); catch, end
        if flagged && ~opt.AllowFlagged
            rmpath(M(i).dir);
            clear carDesign controller robotConfig
            fprintf('  FLAGGED %s (%s): %s\n', name, M(i).file, strjoin(findings, '; '));
            scr.mark(i, "flagged by the code check: not racing", [1 0.4 0.35], name);
            continue;
        end
        for k = 1:nP
            if err ~= ""
                res = dnfResult(err);
            else
                clear controller                         % fresh persistent variables every run
                t0 = tic;
                try
                    r = RaceSimulation(F.courses{k}, car, @(ob, c) guarded(ob, c, t0, opt.RunLimit), config, ...
                        struct('headless', true));
                    res = compact(r);
                catch ME
                    res = dnfResult("Simulator error: " + ME.message);
                end
            end
            res.team = M(i).id;  res.pathId = F.ids(k);  res.teamName = name;
            res.colour = [0.6 0.6 0.6];  if ~isempty(car), res.colour = car.colour; end
            res = orderfields(res);
            if isempty(R), R = res; else, R(end+1) = res; end %#ok<AGROW>
        end
        rmpath(M(i).dir);
        clear carDesign controller robotConfig
        mine = R(string({R.team}) == M(i).id);
        nFin = sum([mine.finished]);
        if err ~= ""
            scr.mark(i, err, [1 0.4 0.35], name);
        elseif nFin == nP
            scr.mark(i, sprintf('ready: finished all %d paths', nP), [0.45 0.95 0.5], name);
        elseif nFin == 0
            scr.mark(i, "DNF on every path: " + mine(1).dnfReason, [1 0.4 0.35], name);
        else
            scr.mark(i, sprintf('ready: finished %d of %d (DNF: %s)', nFin, nP, ...
                strjoin([mine(~[mine.finished]).pathId], ', ')), [1 0.65 0.3], name);
        end
    end
    if isempty(R), error('finalRace:noneRacing', 'No model can race (all flagged or invalid).'); end
    R = uniqueNames(R);
    scr.done();

    % ---- save, then the show -------------------------------------------- %
    outDir = string(opt.Out);
    if outDir == ""
        outDir = fullfile(here, 'results', "final_" + string(datetime('now', 'Format', 'yyyyMMdd_HHmmss')));
    end
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    save(fullfile(outDir, 'runs.mat'), 'R', 'F');
    S = standings(R, F);
    writetable(S, fullfile(outDir, 'results.csv'));
    fprintf('Results saved in %s\n', outDir);
    raceDay('Out', outDir, 'Seconds', opt.Seconds, 'Pause', opt.Pause, 'SaveFrames', opt.SaveFrames);
    if nargout == 0, clear S; end
end

% ======================================================================= %
function cmd = guarded(o, c, t0, limit)
% The team's controller, with a limit on the computing time of one run.
    if toc(t0) > limit
        error('AIGP:slow', 'used more than %d s of computing on this path', limit);
    end
    cmd = controller(o, c);
end

function M = findModels(folder)
% Every <name>.zip and every sub-folder with a carDesign.m, unpacked into a private stage.
    stage = fullfile(tempdir, "aigp_final_" + string(feature('getpid')));
    if exist(stage, 'dir'), rmdir(stage, 's'); end
    mkdir(stage);
    M = struct('id', {}, 'file', {}, 'label', {}, 'dir', {}, 'stage', {});
    zips = dir(fullfile(folder, '*.zip'));
    subs = dir(folder);
    subs = subs([subs.isdir] & ~startsWith({subs.name}, '.'));
    subs = subs(arrayfun(@(d) exist(fullfile(d.folder, d.name, 'carDesign.m'), 'file') == 2, subs));
    items = [zips; subs];
    for k = 1:numel(items)
        id = sprintf('m%02d', k);
        dest = fullfile(stage, id);
        mkdir(dest);
        src = fullfile(items(k).folder, items(k).name);
        try
            if items(k).isdir
                copyfile(fullfile(src, '*'), dest);
            else
                unzip(src, dest);
            end
        catch ME
            warning('finalRace:unpack', '%s: cannot unpack (%s) - skipped', items(k).name, ME.message);
            continue;
        end
        inner = dir(fullfile(dest, '**', 'carDesign.m'));       % a zip of a folder: use the folder inside
        if isempty(inner)
            warning('finalRace:noDesign', '%s has no carDesign.m - skipped', items(k).name);
            continue;
        end
        [~, label] = fileparts(items(k).name);
        M(end+1) = struct('id', string(id), 'file', string(items(k).name), 'label', string(label), ...
            'dir', string(inner(1).folder), 'stage', string(stage)); %#ok<AGROW>
    end
end

function removeStage(M)
    if isempty(M), return; end
    for i = 1:numel(M)
        if contains(path, M(i).dir), rmpath(M(i).dir); end
    end
    clear carDesign controller robotConfig
    if exist(M(1).stage, 'dir'), rmdir(M(1).stage, 's'); end
end

function R = uniqueNames(R)
% Two models with the same car.team: "Name" and "Name (2)".
    teams = unique(string({R.team}), 'stable');
    names = arrayfun(@(t) string(R(find(string({R.team}) == t, 1)).teamName), teams);
    for i = 2:numel(names)
        same = sum(names(1:i-1) == names(i)) + sum(startsWith(names(1:i-1), names(i) + " ("));
        if same > 0
            newName = names(i) + " (" + (same + 1) + ")";
            [R(string({R.team}) == teams(i)).teamName] = deal(newName);
            names(i) = newName;
        end
    end
end

function res = compact(r)
    keep = {'finished', 'dnf', 'dnfReason', 'time', 'penalty', 'totalTime', 'nOffTrack', 'nBarrier', ...
            'stopInRunoff', 'lapTimes', 'energyUsedWh', 'batteryLeftFrac', 'checkpointsPassed'};
    for f = keep, res.(f{1}) = r.(f{1}); end
    lg = r.log;
    res.log = struct('t', single(lg.t), 'x', single(lg.x), 'y', single(lg.y), 'theta', single(lg.theta), ...
        'v', single(lg.v), 'progress', single(lg.progress), 'lap', uint8(lg.lap));
    res.parts = r.car.parts;
end

function res = dnfResult(reason)
    res = struct('finished', false, 'dnf', true, 'dnfReason', string(reason), 'time', Inf, 'penalty', 0, ...
        'totalTime', Inf, 'nOffTrack', 0, 'nBarrier', 0, 'stopInRunoff', false, 'lapTimes', [], ...
        'energyUsedWh', 0, 'batteryLeftFrac', 1, 'checkpointsPassed', 0, ...
        'log', struct('t', single([]), 'x', single([]), 'y', single([]), 'theta', single([]), 'v', single([]), ...
        'progress', single([]), 'lap', uint8([])), 'parts', struct());
end
