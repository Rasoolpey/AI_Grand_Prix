function qualifyOne(teamDir, finalsFile, outDir, pathIdx, simRoot)
% QUALIFYONE  Run ONE team on the given final paths (called by qualify in its own MATLAB).
%
%   qualifyOne(teamDir, finalsFile, outDir, pathIdx, simRoot)
%
%   Writes <outDir>/<team>__<pathId>.started before each path and
%   <outDir>/<team>__<pathId>.mat when it is done, so qualify knows which
%   path was running if it has to stop a hung process.
%
%   See also: qualify

    addpath(fullfile(simRoot, 'simulator'), fullfile(simRoot, 'simulator', 'physics'));
    cd(teamDir);
    addpath(teamDir, '-begin');                       % the team's carDesign / controller / robotConfig
    [~, team] = fileparts(teamDir);
    S = load(finalsFile, 'F');  F = S.F;

    designErr = "";  car = [];
    try
        car = buildCar(carDesign());
    catch ME
        designErr = "Invalid car design: " + ME.message;
    end
    config = struct();
    try, config = robotConfig(); catch, end

    for k = pathIdx(:)'
        id = F.ids(k);
        base = fullfile(outDir, team + "__" + id);
        fclose(fopen(base + ".started", 'w'));
        if designErr ~= ""
            res = dnfResult(designErr);
        else
            clear controller
            try
                r = RaceSimulation(F.courses{k}, car, @controller, config, struct('headless', true));
                res = compact(r);
            catch ME
                res = dnfResult("Simulator error: " + ME.message);
            end
        end
        res.team = string(team);  res.pathId = id;
        if ~isempty(car), res.colour = car.colour; res.teamName = car.team; else, res.colour = [0.5 0.5 0.5]; res.teamName = string(team); end
        save(base + ".mat", 'res');
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
