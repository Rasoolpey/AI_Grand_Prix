function info = bestModel(action)
% BESTMODEL  Your best model so far: the one you hand in.
%
%   bestModel                 show it: team, overall score, score per path, file
%   info = bestModel          the same, as a struct (empty if you have none yet)
%
%   It is saved automatically by practiceRace('Path', 'all') whenever your
%   overall score beats your best, and it replaces the old one: there is only
%   ever one.  It lives in best_model/:
%     <team>.zip   your car, driver and tuning (+ manifest.json): hand this in
%     best.mat     its four runs, shown as the grey ghost car
%
%   See also: practiceRace, submitCar

    thisDir = fileparts(mfilename('fullpath'));
    f = fullfile(thisDir, 'best_model', 'best.mat');
    info = [];
    if exist(f, 'file')
        S = load(f, 'B');
        info = S.B;
        info.zipFile = string(fullfile(thisDir, 'best_model', info.zipName));
        if ~exist(info.zipFile, 'file'), info = []; end       % the zip is the model; without it there is none
    end
    if nargin >= 1 && strcmpi(string(action), "load")
        return;                                              % quiet, for practiceRace and submitCar
    end
    if isempty(info)
        fprintf('\n  No best model yet. Run practiceRace(''Path'', ''all''): your first finish is saved.\n\n');
    else
        fprintf('\n  BEST MODEL: %s   overall %.1f   (saved %s)\n', info.team, info.overall, info.saved);
        for i = 1:numel(info.paths)
            fprintf('    %-10s score %6.1f   total %s\n', info.paths(i), info.scores(i), timeStr(info.totalTimes(i)));
        end
        fprintf('    parts: %s, %s, %s, %s, %s gearing  (%d credits)\n', info.parts.motor, info.parts.battery, ...
            info.parts.tyres, info.parts.aero, info.parts.gearing, info.cost);
        fprintf('    file : %s   <- hand this in\n\n', info.zipFile);
    end
    if nargout == 0, clear info; end
end

function s = timeStr(t)
    if isfinite(t), s = sprintf('%.2f s', t); else, s = 'DNF'; end
end
