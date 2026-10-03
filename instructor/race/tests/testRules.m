function tests = testRules
% TESTRULES  Race rules and adversarial controllers (TODO_RACE §4.2, §8).
%   results = runtests('testRules')
%   (Infinite loops are caught by qualify's wall-clock limit, not here.)
    tests = functiontests(localfunctions);
end

function setupOnce(tc)
    setupPaths();
    tc.TestData.car = buildCar(struct('team', "T", 'motor', "3.5kW", 'battery', "70Wh", ...
        'tyres', "medium", 'aero', "lowdrag", 'gearing', "medium"));
end

function testReferenceFinishesAllPaths(tc)
    for nm = ["drag", "technical", "endurance", "wet"]
        clear refController
        r = RaceSimulation(loadPath(nm), tc.TestData.car, @refController, struct());
        tc.verifyTrue(r.finished, nm + ": " + r.dnfReason);
        tc.verifyEqual(r.penalty, 0, nm);
    end
end

function testControllerErrorIsDNF(tc)
    r = RaceSimulation(loadPath("technical"), tc.TestData.car, @crashingCtrl, struct());
    tc.verifyTrue(r.dnf);
    tc.verifySubstring(char(r.dnfReason), 'boom');
    tc.verifyEqual(numel(r.log.t), 0);
end

function cmd = crashingCtrl(~, ~) %#ok<STOUT>
    error('boom');
end

function testInvalidCommandIsDNF(tc)
    bad = {struct('throttle', NaN, 'steering', 0), struct('throttle', 1), 5, struct('throttle', [1 1], 'steering', 0)};
    for i = 1:numel(bad)
        b = bad{i};
        r = RaceSimulation(loadPath("technical"), tc.TestData.car, @(o, c) b, struct());
        tc.verifyTrue(r.dnf, sprintf('bad command %d', i));
    end
end

function testIgnoringTheRoadIsDNF(tc)
    % drive straight ahead, ignoring the road: never a finish
    r = RaceSimulation(loadPath("technical"), tc.TestData.car, @(o, c) struct('throttle', 0.6, 'steering', 0), struct());
    tc.verifyTrue(r.dnf);
end

function testCheckpointSkipIsDNF(tc)
    % follow the road for a while, then cut across the infield
    course = loadPath("wet");
    clear refController
    r = RaceSimulation(course, tc.TestData.car, @(o, c) cutter(o, c, course), struct());
    tc.verifyTrue(r.dnf);
    tc.verifyFalse(r.finished);
end

function cmd = cutter(o, c, course)
    if o.time < 6
        cmd = refController(o, c);
    else
        target = course.centreline(round(0.75 * course.numPoints()), :);
        ang = atan2(target(2) - o.position(2), target(1) - o.position(1)) - o.heading;
        cmd = struct('throttle', 0.4, 'steering', max(-1, min(1, 2 * atan2(sin(ang), cos(ang)))));
    end
end

function testUTurnDoesNotFinish(tc)
    % circle round and cross the start line the wrong way: not a lap
    ctrl = @(o, c) struct('throttle', 0.3, 'steering', 1);
    r = RaceSimulation(loadPath("technical"), tc.TestData.car, ctrl, struct());
    tc.verifyFalse(r.finished);
end

function testBarrierHitterPenalisedOrDNF(tc)
    % full throttle everywhere, steering from the reference: too fast for the hairpins
    clear refController
    ctrl = @(o, c) fullThrottle(refController(o, c));
    r = RaceSimulation(loadPath("technical"), tc.TestData.car, ctrl, struct());
    tc.verifyTrue(r.dnf || r.nBarrier > 0 || r.nOffTrack > 0);
    if ~r.dnf, tc.verifyEqual(r.penalty, 5 * r.nOffTrack + 10 * r.nBarrier); end
end

function cmd = fullThrottle(cmd)
    cmd.throttle = 1;
end

function testPersistentStateWorks(tc)
    clear persistentCtrl
    r = RaceSimulation(loadPath("drag"), tc.TestData.car, @persistentCtrl, struct());
    tc.verifyTrue(r.finished, r.dnfReason);
end

function cmd = persistentCtrl(o, ~)
    persistent n
    if isempty(n), n = 0; end
    n = n + 1;
    cmd.steering = 0;
    cmd.throttle = 1;
    if o.path.distanceToStop < 0.5 * o.speed^2 / 6 + 1, cmd.throttle = -1; end
    if n < 2, cmd.throttle = 0.5; end
end

function testDragStopRules(tc)
    car = tc.TestData.car;  course = loadPath("drag");
    % never brakes: barrier at the end -> DNF
    r = RaceSimulation(course, car, @(o, c) struct('throttle', 1, 'steering', 0), struct());
    tc.verifyTrue(r.dnf);
    tc.verifySubstring(char(r.dnfReason), 'barrier');
    % brakes only after the line: stops in the run-off -> +3 s
    late = @(o, c) struct('throttle', 1 - 2 * (o.path.distanceToFinish < 0), 'steering', 0);
    r = RaceSimulation(course, car, late, struct());
    tc.verifyTrue(r.finished, r.dnfReason);
    tc.verifyTrue(r.stopInRunoff);
    tc.verifyEqual(r.penalty, 3);
end

function testEmptyBatteryCoastsOverLine(tc)
    % a car with almost no energy coasts; it still finishes if it rolls over the line
    car = tc.TestData.car;  car.batteryJ = 2500;  car.batteryWh = car.batteryJ / 3600;
    course = buildPath(road.straight(80), 'Type', "open", 'FinishRunoff', 40, 'TimeLimit', 60);
    r = RaceSimulation(course, car, @(o, c) struct('throttle', 1, 'steering', 0), struct());
    tc.verifyTrue(r.finished, r.dnfReason);
    tc.verifyEqual(r.batteryLeftFrac, 0);
end

function testStoppedIsDNF(tc)
    r = RaceSimulation(loadPath("technical"), tc.TestData.car, @(o, c) struct('throttle', 0, 'steering', 0), struct());
    tc.verifyTrue(r.dnf);
    tc.verifySubstring(char(r.dnfReason), 'Stopped');
end
