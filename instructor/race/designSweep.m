function T = designSweep(paths, varargin)
% DESIGNSWEEP  Every affordable design on every path, scored with benchmark times.
%
%   T = designSweep()                          % core paths C1-C3
%   T = designSweep(["drag" "technical" "endurance"], 'Reference', refDesign)
%   T = designSweep(courses)                   % a cell array of RacePath objects
%   T = designSweep(paths, 'Catalogue', cat)   % try a candidate catalogue
%
%   Fast first look at balance (no controller): each design's estimated
%   benchmark time per path (energy-limited), its score per path against the
%   reference design, and overall = 0.6 mean + 0.4 min.  Confirm the
%   interesting designs with balanceSweep (full simulator + controllers).
%
%   T: table, one row per design, sorted by overall score.
%
%   See also: balanceSweep, trackTuning, benchmarkTime

    o = inputParser();
    o.addParameter('Reference', []);
    o.addParameter('Catalogue', []);
    o.parse(varargin{:});
    if nargin < 1 || isempty(paths), paths = ["drag", "technical", "endurance"]; end
    courses = toCourses(paths);
    names = string(cellfun(@(c) c.name, courses, 'UniformOutput', false));

    cat = o.Results.Catalogue;
    if isempty(cat), cat = parts(); end
    ref = o.Results.Reference;
    if isempty(ref), ref = referenceDesign(cat); end
    designs = allDesigns(cat);
    nD = numel(designs);  nP = numel(courses);
    time = nan(nD, nP);  energy = nan(nD, nP);  feasible = false(nD, nP);
    cost = zeros(nD, 1);  mass = zeros(nD, 1);
    for i = 1:nD
        car = buildCar(designs(i), cat);
        cost(i) = car.cost;  mass(i) = car.mass;
        for j = 1:nP
            b = benchmarkTime(car, courses{j});
            time(i,j) = b.time;  energy(i,j) = b.energyWh;  feasible(i,j) = b.feasible;
        end
    end
    refCar = buildCar(ref, cat);
    tref = zeros(1, nP);
    for j = 1:nP, tref(j) = benchmarkTime(refCar, courses{j}).time; end

    score = min(120, 100 * tref ./ time);
    score(~feasible) = 0;
    overall = 0.6 * mean(score, 2) + 0.4 * min(score, [], 2);

    T = table(string({designs.motor})', string({designs.battery})', string({designs.tyres})', ...
        string({designs.aero})', string({designs.gearing})', cost, mass, ...
        'VariableNames', {'motor', 'battery', 'tyres', 'aero', 'gearing', 'cost', 'mass'});
    for j = 1:nP
        T.("t_" + matlab.lang.makeValidName(names(j))) = time(:,j);
    end
    for j = 1:nP
        T.("s_" + matlab.lang.makeValidName(names(j))) = score(:,j);
    end
    T.overall = overall;
    T = sortrows(T, 'overall', 'descend');
end

function d = referenceDesign(cat)
% The middle option of every part.
    d = struct('team', "Reference");
    for p = cat.partNames, d.(p) = cat.(p)(2).id; end
end

function designs = allDesigns(cat)
% Every design within budget.
    designs = struct('team', {}, 'motor', {}, 'battery', {}, 'tyres', {}, 'aero', {}, 'gearing', {});
    for m = [cat.motor.id]
        for b = [cat.battery.id]
            for t = [cat.tyres.id]
                for a = [cat.aero.id]
                    for g = [cat.gearing.id]
                        d = struct('team', "sweep", 'motor', m, 'battery', b, 'tyres', t, 'aero', a, 'gearing', g);
                        try
                            buildCar(d, cat);
                            designs(end+1) = d; %#ok<AGROW>
                        catch
                        end
                    end
                end
            end
        end
    end
end

function c = toCourses(paths)
    if iscell(paths), c = paths; return; end
    c = cell(1, numel(paths));
    for j = 1:numel(paths), c{j} = loadPath(paths(j)); end
end
