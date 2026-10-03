function report = checkInstallation()
% CHECKINSTALLATION  Verify the workshop on the currently running MATLAB.
% Does not install products or change student files. Outputs go to .tools/log.
    workspace = fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
    raceDir = fullfile(workspace, 'AI_Grand_Prix');
    outDir = fullfile(workspace, '.tools', 'log');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    previousDir = pwd;
    previousVisibility = get(groot, 'defaultFigureVisible');
    cleanup = onCleanup(@() restoreState(previousDir, previousVisibility)); %#ok<NASGU>
    set(groot, 'defaultFigureVisible', 'off');
    cd(raceDir);
    addpath(fileparts(mfilename('fullpath')));
    setupPaths();
    addpath(raceDir, fullfile(raceDir, 'student'));

    report.release = version('-release');
    report.matlabRoot = matlabroot;
    installed = ver;
    report.installedProducts = {installed.Name};
    fprintf('CHECK: MATLAB %s; installed: %s\n', report.release, strjoin(report.installedProducts, ', '));

    testMCP;
    assert(allGood, 'checkInstallation:connection', 'The local MATLAB project sanity check failed.');
    tests = runAllTests();
    assert(all([tests.Passed]), 'checkInstallation:tests', 'Physics/rule tests failed.');
    report.testsPassed = sum([tests.Passed]);
    report.testsTotal = numel(tests);

    races = practiceRace('Path', 'all', 'Headless', true, 'Quiet', true);
    assert(all([races.finished]), 'checkInstallation:baseline', 'A baseline race did not finish.');
    report.baseline = struct('path', {}, 'time', {}, 'penalty', {}, 'energyWh', {});
    for k = 1:numel(races)
        report.baseline(k) = struct('path', races(k).pathName, 'time', races(k).totalTime, ...
            'penalty', races(k).penalty, 'energyWh', races(k).energyUsedWh);
        fprintf('BASELINE: %s %.2f s, penalty %.0f s, energy %.2f Wh\n', ...
            races(k).pathName, races(k).totalTime, races(k).penalty, races(k).energyUsedWh);
    end
    report.overallScore = races(1).overall;

    garage();
    exportgraphics(gcf, fullfile(outDir, 'garage-check.png'));
    close(gcf);
    lapFigure = plotLap(races(2));
    exportgraphics(lapFigure, fullfile(outDir, 'lap-report-check.png'));
    close(lapFigure);
    clear controller
    shortCourse = loadPath('drag');
    RaceSimulation(shortCourse.withTimeLimit(0.2), buildCar(carDesign()), ...
        @controller, robotConfig(), struct('headless', false));
    exportgraphics(gcf, fullfile(outDir, 'race-view-check.png'));
    close(gcf);
    report.graphicsPassed = true;
    fprintf('CHECK: Garage, lap report and race HUD rendered successfully.\n');

    styles = controllerStyles();
    sweep = balanceSweep('Designs', carDesign(), 'Styles', styles(1), 'Variations', 0);
    assert(all(isfinite(sweep.time(:))), 'checkInstallation:sweep', 'The small balance sweep failed.');
    report.smallSweepPassed = true;

    entries = {fullfile(raceDir, 'practiceRace.m'), fullfile(raceDir, 'garage.m'), ...
        fullfile(raceDir, 'plotLap.m'), fullfile(raceDir, 'submitCar.m'), ...
        fullfile(workspace, 'instructor', 'race', 'qualify.m'), ...
        fullfile(workspace, 'instructor', 'race', 'raceDay.m'), ...
        fullfile(workspace, 'instructor', 'race', 'balanceSweep.m'), ...
        fullfile(workspace, 'instructor', 'topics', 'draw_lots.m')};
    [~, products] = matlab.codetools.requiredFilesAndProducts(entries);
    report.detectedProducts = {products.Name};
    fprintf('DEPENDENCIES: %s\n', strjoin(report.detectedProducts, ', '));
    fid = fopen(fullfile(outDir, 'matlab-installation-check.json'), 'w');
    assert(fid ~= -1, 'checkInstallation:report', 'Could not write the installation report.');
    fileCleanup = onCleanup(@() fclose(fid)); %#ok<NASGU>
    fprintf(fid, '%s\n', jsonencode(report, 'PrettyPrint', true));
    fprintf('INSTALLATION_CHECK_PASSED: %s, %d/%d tests, baseline score %.2f\n', ...
        report.release, report.testsPassed, report.testsTotal, report.overallScore);
end

function restoreState(folder, visibility)
    cd(folder);
    set(groot, 'defaultFigureVisible', visibility);
end
