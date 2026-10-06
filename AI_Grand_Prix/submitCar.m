function zipFile = submitCar()
% SUBMITCAR  Check your best model and hand it in.
%
%   submitCar
%
%   What you hand in is your BEST MODEL: the car, driver and tuning that
%   practiceRace('Path', 'all') saved the last time you beat your best
%   (bestModel shows it).  Not the files you are editing right now.
%
%   1. Checks the best model: known parts, within budget, a team name.
%   2. Runs its controller for a few seconds on each scored path: it must
%      not error.  (It does not have to be fast - that is race day's job.)
%   3. Adds your engineering log (student/engineering_log.md) to the zip.
%   4. Copies best_model/<team>.zip to the shared folder if one is set
%      (the instructor gives the folder on the day; it is read from
%      submitFolder.txt next to this file, or the AIGP_SUBMIT_DIR
%      environment variable).  Otherwise: send that file to your instructor.
%
%   The name shown on race day is car.team inside the model.  You can
%   submit again until the code freeze: the newest copy counts.
%
%   See also: bestModel, practiceRace

    thisDir = fileparts(mfilename('fullpath'));
    addpath(fullfile(thisDir, 'simulator'), fullfile(thisDir, 'simulator', 'physics'), ...
            fullfile(thisDir, 'student'), fullfile(thisDir, 'tracks'));

    fprintf('\n=== SUBMIT ===\n');
    info = bestModel('load');
    if isempty(info)
        error('submitCar:noBest', ['You have no best model yet. Run practiceRace(''Path'', ''all''): ' ...
            'your first finish is saved as best_model/<team>.zip, and that is what you hand in.']);
    end
    zipFile = info.zipFile;

    % ---- check the model itself, not the files in student/ ------------- %
    stage = fullfile(tempdir, "aigp_submit_" + string(feature('getpid')));
    if exist(stage, 'dir'), rmdir(stage, 's'); end
    mkdir(stage);
    unzip(zipFile, stage);
    cleanup = onCleanup(@() restore(stage));
    addpath(stage, '-begin');
    clear carDesign controller robotConfig
    car = buildCar(carDesign());                    % errors with a clear message if not legal
    fprintf('[OK] best model "%s": %s, %s, %s, %s, %s gearing - %d / %d credits - overall %.1f (saved %s)\n', ...
        car.team, car.parts.motor, car.parts.battery, car.parts.tyres, car.parts.aero, car.parts.gearing, ...
        car.cost, car.budget, info.overall, info.saved);
    if car.team == "Team Name"
        warning('submitCar:team', ['Your model is still called "Team Name". Set car.team in carDesign.m and run ' ...
            'practiceRace(''Path'', ''all'') again: the same car under its new name replaces the old one.']);
    end
    config = struct();
    try, config = robotConfig(); catch, end
    for nm = ["drag", "technical", "endurance", "mud"]
        course = loadPath(nm);
        clear controller
        r = RaceSimulation(course.withTimeLimit(5), car, @controller, config, struct('headless', true));
        if r.dnf && startsWith(r.dnfReason, "Controller error")
            error('submitCar:controller', 'Your best model''s controller fails on the %s path: %s', nm, r.dnfReason);
        end
        fprintf('[OK] controller runs on %s\n', nm);
    end

    % ---- add the engineering log (it changes after the model is saved) -- %
    logFile = fullfile(thisDir, 'student', 'engineering_log.md');
    if exist(logFile, 'file')
        copyfile(logFile, stage);
        delete(fullfile(stage, '*.asv'));
        zip(zipFile, '*', stage);
        fprintf('[OK] engineering_log.md added\n');
    else
        fprintf('[!!] No student/engineering_log.md found: the judges read it for two awards.\n');
    end
    fprintf('[OK] your hand-in: %s\n', zipFile);

    % ---- copy to the shared folder ------------------------------------- %
    shared = getenv('AIGP_SUBMIT_DIR');
    cfg = fullfile(thisDir, 'submitFolder.txt');
    if isempty(shared) && exist(cfg, 'file')
        shared = strtrim(fileread(cfg));
    end
    if isempty(shared)
        fprintf('[!!] No shared folder set: send the file above to your instructor.\n');
    else
        try
            copyfile(zipFile, shared, 'f');
            fprintf('[OK] copied to %s\n', shared);
        catch ME
            fprintf('[!!] Could not copy to %s (%s).\n     Send this file instead: %s\n', shared, ME.message, zipFile);
        end
    end
    fprintf('=== done: you can submit again until the code freeze ===\n\n');
    if nargout == 0, clear zipFile; end
end

function restore(stage)
% Put the student's own files back in front, and remove the unpacked copy.
    if contains(path, stage), rmpath(stage); end
    clear carDesign controller robotConfig
    if exist(stage, 'dir'), rmdir(stage, 's'); end
end
