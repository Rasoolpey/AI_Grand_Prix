function tests = testPhysics
% TESTPHYSICS  Unit checks for the shared physics (TODO_RACE §8).
%   results = runtests('testPhysics')
    tests = functiontests(localfunctions);
end

function setupOnce(tc)
    setupPaths();
    tc.TestData.car = buildCar(design("3.5kW", "70Wh", "medium", "lowdrag", "medium"));
end

function d = design(m, b, t, a, g)
    d = struct('team', "T", 'motor', m, 'battery', b, 'tyres', t, 'aero', a, 'gearing', g);
end

function s = state0(car)
    s = struct('x', 0, 'y', 0, 'theta', 0, 'v', 0, 'delta', 0, 'energyJ', car.batteryJ);
end

function t = timeTo(car, vTarget)
    s = state0(car);  road = struct('alpha', 0, 'muFactor', 1);  t = 0;
    while s.v < vTarget && t < 60
        s = stepCar(car, s, 1, 0, road, 0.02);  t = t + 0.02;
    end
end

function testHeavierIsSlower(tc)
    car = tc.TestData.car;  heavy = car;  heavy.mass = car.mass + 20;
    tc.verifyGreaterThan(timeTo(heavy, 10), timeTo(car, 10));
end

function testMoreGripFasterCorner(tc)
    car = tc.TestData.car;  grippy = car;  grippy.mu = car.mu + 0.2;
    tc.verifyGreaterThan(cornerSpeed(grippy, 1/10), cornerSpeed(car, 1/10));
end

function testDownforceHelpsOnlyAtSpeed(tc)
    % the worked example on the equation sheet: soft tyres, 95 kg
    c = tc.TestData.car;  c.mu = 1.3;  c.mass = 95;  c.ClA = 0;
    a = c;  a.ClA = 1.2;
    tc.verifyEqual(cornerSpeed(c, 1/8),  10.1, 'AbsTol', 0.05);
    tc.verifyEqual(cornerSpeed(a, 1/8),  10.5, 'AbsTol', 0.05);
    tc.verifyEqual(cornerSpeed(c, 1/40), 22.6, 'AbsTol', 0.05);
    tc.verifyEqual(cornerSpeed(a, 1/40), 29.0, 'AbsTol', 0.05);
    tc.verifyEqual(cornerSpeed(c, 0), Inf);
end

function testMudIsSlipperyAndSticky(tc)
    % mud: grip x 0.6 (eq. 6 with muFactor) and rolling resistance x 4 (eq. 4)
    car = tc.TestData.car;
    tc.verifyEqual(cornerSpeed(car, 1/10, 0, 0.6), cornerSpeed(setfield(car, 'mu', 0.6 * car.mu), 1/10), 'RelTol', 1e-12); %#ok<SFLD>
    [~, Froll] = roadForces(car, 5, 0);
    [~, FrollMud] = roadForces(car, 5, 0, 4);
    tc.verifyEqual(FrollMud, 4 * Froll, 'RelTol', 1e-12);
    s = state0(car);  s.v = 8;
    dry = stepCar(car, s, 0, 0, struct('alpha', 0, 'muFactor', 1), 0.02);
    mud = stepCar(car, s, 0, 0, struct('alpha', 0, 'muFactor', 0.6, 'rollFactor', 4), 0.02);
    tc.verifyLessThan(mud.v, dry.v);                      % coasting: mud slows the car more
    c = loadPath("mud");
    P = c.preview(find(c.rollFactor > 1, 1) - 20, 60);   % 10 m before the first mud
    tc.verifySize(P, [60 5]);
    tc.verifyTrue(any(P(:,5) == 1) && all(P(P(:,5) == 1, 4) == 1));   % mud points are also flagged slippery
    tc.verifyTrue(all(c.rollFactor(c.rollFactor > 1) == 4) && all(c.muFactor(c.rollFactor > 1) == 0.6));
end

function testEmptyBatteryCoasts(tc)
    car = tc.TestData.car;  s = state0(car);  s.v = 10;  s.energyJ = 0;
    road = struct('alpha', 0, 'muFactor', 1);
    [s2, info] = stepCar(car, s, 1, 0, road, 0.02);
    tc.verifyEqual(info.Fdrive, 0);
    tc.verifyLessThan(s2.v, 10);
    tc.verifyEqual(s2.energyJ, 0);
end

function testUndersteer(tc)
    car = tc.TestData.car;  s = state0(car);  s.v = 15;  s.delta = car.maxSteer;
    road = struct('alpha', 0, 'muFactor', 1);
    [~, info] = stepCar(car, s, 0, 1, road, 0.02);
    tc.verifyTrue(info.understeer);
    tc.verifyLessThan(abs(info.kappa), tan(car.maxSteer) / car.wheelbase);
    tc.verifyEqual(info.gripUse, 1, 'AbsTol', 1e-9);
end

function testFrictionCircleLimitsBraking(tc)
    car = tc.TestData.car;  s = state0(car);  s.v = 10;
    road = struct('alpha', 0, 'muFactor', 1);
    [~, straightInfo] = stepCar(car, s, -1, 0, road, 0.02);
    s.delta = 0.08;                                   % turning: part of the grip is used sideways
    [~, cornerInfo] = stepCar(car, s, -1, 0.16, road, 0.02);
    tc.verifyLessThan(cornerInfo.Fbrake, straightInfo.Fbrake);
    tc.verifyLessThanOrEqual(hypot(cornerInfo.Fx, cornerInfo.Fy), cornerInfo.G * (1 + 1e-9));
end

function testEnergyBookkeeping(tc)
    % energy used = sum(F_drive * distance) / eta, stored in joules, shown in Wh
    car = tc.TestData.car;  s = state0(car);  s.v = 5;
    road = struct('alpha', 0, 'muFactor', 1);  E = 0;
    for k = 1:200
        vOld = s.v;
        [s, info] = stepCar(car, s, 0.5, 0, road, 0.02);
        E = E + info.Fdrive * 0.5 * (vOld + s.v) * 0.02 / car.eta;
    end
    tc.verifyEqual(car.batteryJ - s.energyJ, E, 'RelTol', 1e-9);
    tc.verifyEqual(car.batteryWh * 3600, car.batteryJ);
end

function testSlopeForce(tc)
    car = tc.TestData.car;  car.mass = 95;
    [~, ~, Fg] = roadForces(car, 0, atan(0.10));       % 10 % hill
    tc.verifyEqual(Fg, 95 * 9.81 * sin(atan(0.1)), 'RelTol', 1e-12);
    tc.verifyEqual(Fg, 92.7, 'AbsTol', 0.1);
end

function testCircuitsReturnToStartHeight(tc)
    for nm = ["technical", "endurance", "mud", "wet"]
        c = loadPath(nm);
        tc.verifyLessThan(abs(c.z(end) - c.z(1)), 0.05, nm);
        tc.verifyLessThan(norm(c.centreline(end,:) - c.centreline(1,:)), 0.6, nm);
        tc.verifyEqual(sum(c.kappa) * c.ds, 2 * pi, 'AbsTol', 0.02, nm);
    end
end

function testDeterministic(tc)
    car = tc.TestData.car;  c = loadPath("technical");
    clear refController
    r1 = RaceSimulation(c, car, @refController, struct());
    clear refController
    r2 = RaceSimulation(c, car, @refController, struct());
    tc.verifyEqual(r1.log, r2.log);
    tc.verifyEqual(r1.time, r2.time);
end

function testBudget(tc)
    cat = parts();  n = 0;  total = 0;
    for m = [cat.motor.id]
        for b = [cat.battery.id]
            for t = [cat.tyres.id]
                for a = [cat.aero.id]
                    for g = [cat.gearing.id]
                        total = total + 1;
                        try
                            buildCar(design(m, b, t, a, g));  n = n + 1;
                        catch
                        end
                    end
                end
            end
        end
    end
    tc.verifyEqual(total, 243);
    tc.verifyEqual(n, 207);
    tc.verifyError(@() buildCar(design("5.5kW", "100Wh", "soft", "downforce", "long")), 'AIGP:design');
    tc.verifyError(@() buildCar(design("9kW", "70Wh", "soft", "none", "long")), 'AIGP:design');
end

function testBenchmarkMatchesSimulatorOnStraight(tc)
    car = tc.TestData.car;
    c = buildPath(road.straight(320), 'Type', "open", 'FinishRunoff', 20, 'TimeLimit', 60);
    r = RaceSimulation(c, car, @(o, cf) struct('throttle', 1, 'steering', 0), struct());
    b = benchmarkTime(car, c);
    tc.verifyEqual(b.time, r.time, 'RelTol', 0.01);
    tc.verifyEqual(b.energyWh, r.energyUsedWh, 'RelTol', 0.02);
end

function testCornerSpeedHoldsInSimulator(tc)
    % a steady circle just under eq. 6 does not understeer; just over it does
    car = tc.TestData.car;  R = 20;
    c = buildPath([road.straight(1, 0, "adjust"), road.corner(R, 180, "L"), road.straight(1, 0, "adjust"), ...
                   road.corner(R, 180, "L")], 'Laps', 2, 'Width', 6, 'Transition', 0.01, 'Checkpoints', 20);
    vc = cornerSpeed(car, 1/R);
    rUnder = RaceSimulation(c, car, @(o, cf) circleCtrl(o, 0.97 * vc), struct());
    rOver  = RaceSimulation(c, car, @(o, cf) circleCtrl(o, 1.05 * vc), struct());
    late = rUnder.log.t > 8;
    tc.verifyFalse(any(rUnder.log.understeer(late)));
    tc.verifyTrue(any(rOver.log.understeer));
end

function cmd = circleCtrl(o, vT)
    P = o.previewPoints;  d = hypot(P(:,1) - o.position(1), P(:,2) - o.position(2));  k = find(d >= 4, 1);
    ang = atan2(P(k,2) - o.position(2), P(k,1) - o.position(1)) - o.heading;  ang = atan2(sin(ang), cos(ang));
    cmd.steering = atan(2 * o.car.wheelbase * sin(ang) / d(k)) / o.car.maxSteer;
    cmd.throttle = max(-1, min(1, 2 * (vT - o.speed)));
end
