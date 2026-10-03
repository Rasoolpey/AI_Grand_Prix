function zipFile = submitCar()
% SUBMITCAR  Check your car and hand it in for race day.
%
%   submitCar
%
%   1. Checks carDesign.m (known parts, within budget).
%   2. Runs your controller for a few seconds on each practice path: it must
%      not error.  (It does not have to be fast - that is race day's job.)
%   3. Zips the student/ folder with a manifest as submission_<team>.zip:
%        - saved in AI_Grand_Prix/submission/  (always - your local copy)
%        - copied to the shared submission folder if one is set
%          (the instructor gives the folder on the day; it is read from
%          submitFolder.txt next to this file, or the AIGP_SUBMIT_DIR
%          environment variable)
%      If the copy fails, hand in the local zip (e.g. on a USB stick).
%
%   You can submit again until the code freeze: the newest zip counts.
%
%   See also: carDesign, controller, practiceRace

    thisDir = fileparts(mfilename('fullpath'));
    addpath(fullfile(thisDir, 'simulator'), fullfile(thisDir, 'simulator', 'physics'), ...
            fullfile(thisDir, 'student'), fullfile(thisDir, 'tracks'));

    fprintf('\n=== SUBMIT ===\n');
    design = carDesign();
    car = buildCar(design);                         % errors with a clear message if not legal
    fprintf('[OK] car "%s": %s, %s, %s, %s, %s gearing - %d / %d credits\n', car.team, car.parts.motor, ...
        car.parts.battery, car.parts.tyres, car.parts.aero, car.parts.gearing, car.cost, car.budget);
    if car.team == "Team Name"
        warning('submitCar:team', 'Your team is still called "Team Name": set car.team in carDesign.m.');
    end

    config = struct();
    try, config = robotConfig(); catch, end
    for nm = ["drag", "technical", "endurance"]
        course = loadPath(nm);
        clear controller
        short = struct('headless', true);
        r = RaceSimulation(course.withTimeLimit(5), car, @controller, config, short);
        if r.dnf && startsWith(r.dnfReason, "Controller error")
            error('submitCar:controller', 'Your controller fails on the %s path: %s', nm, r.dnfReason);
        end
        fprintf('[OK] controller runs on %s\n', nm);
    end

    % ---- zip ----------------------------------------------------------- %
    team = regexprep(char(car.team), '[^A-Za-z0-9_-]', '_');
    outDir = fullfile(thisDir, 'submission');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    stage = fullfile(tempdir, ['aigp_submit_' team]);
    if exist(stage, 'dir'), rmdir(stage, 's'); end
    mkdir(stage);
    copyfile(fullfile(thisDir, 'student', '*'), stage);
    manifest = struct('team', car.team, 'design', rmfield(design, intersect(fieldnames(design), {'colour'})), ...
        'colour', car.colour, 'cost', car.cost, 'submitted', string(datetime('now', 'Format', 'yyyy-MM-dd HH:mm:ss')), ...
        'matlab', string(version), 'computer', string(getenv('COMPUTERNAME')));
    fid = fopen(fullfile(stage, 'manifest.json'), 'w');
    fprintf(fid, '%s', jsonencode(manifest, 'PrettyPrint', true));
    fclose(fid);
    zipFile = fullfile(outDir, ['submission_' team '.zip']);
    zip(zipFile, '*', stage);
    rmdir(stage, 's');
    fprintf('[OK] saved %s\n', zipFile);

    % ---- copy to the shared folder ------------------------------------- %
    shared = getenv('AIGP_SUBMIT_DIR');
    cfg = fullfile(thisDir, 'submitFolder.txt');
    if isempty(shared) && exist(cfg, 'file')
        shared = strtrim(fileread(cfg));
    end
    if isempty(shared)
        fprintf('[!!] No shared folder set: hand in the zip above (ask the instructor).\n');
    else
        try
            copyfile(zipFile, shared, 'f');
            fprintf('[OK] copied to %s\n', shared);
        catch ME
            fprintf('[!!] Could not copy to %s (%s).\n     Hand in the local zip instead: %s\n', shared, ME.message, zipFile);
        end
    end
    fprintf('=== done: you can submit again until the code freeze ===\n\n');
    if nargout == 0, clear zipFile; end
end
