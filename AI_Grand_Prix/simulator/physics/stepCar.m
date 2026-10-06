function [s, info] = stepCar(car, s, throttle, steer, road, dt)
% STEPCAR  Advance the car by one time step (equations 1-9).
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   [s, info] = stepCar(car, s, throttle, steer, road, dt)
%
%   car       struct from buildCar
%   s         state: x, y, theta (rad), v (m/s), delta (steering angle, rad),
%             energyJ (battery energy left, J)
%   throttle  [-1, 1]: > 0 drive, < 0 brake (fraction of the grip budget)
%   steer     [-1, 1]: +1 = full LEFT (counter-clockwise), -1 = full right
%   road      struct: alpha (road angle, rad), muFactor (1 dry, < 1 wet or mud),
%             rollFactor (optional; 1 normal, 4 on mud)
%   dt        time step (s)
%
%   Order within a step (semi-implicit Euler, deterministic):
%     1. steering angle moves toward the command at most steerRate*dt
%     2. grip budget G = mu * N                          (eqs. 4, 5)
%     3. sideways demand Fy = m v^2 tan(delta) / L        (eq. 7)
%        |Fy| > G -> UNDERSTEER: the car turns only as much as G allows
%        and has no grip left for driving or braking
%     4. driving / braking force limited by sqrt(G^2 - Fy^2)  (eqs. 2, 5)
%     5. m dv/dt = F_drive - F_drag - F_roll - F_grade - F_brake (eq. 1)
%        (the car never reverses: v >= 0)
%     6. heading and position from the new speed          (eq. 7)
%     7. battery: E <- E - F_drive * v * dt / eta          (eq. 8)
%        an empty battery gives no drive: the car coasts
%
%   info: Fx (tyre force along the car, + drive / - brake), Fy, G,
%         gripUse = sqrt(Fx^2+Fy^2)/G, understeer, Fdrive, Fbrake, Fdrag,
%         Froll, Fgrade, accel, kappa (actual path curvature)
%
%   See also: buildCar, driveForce, roadForces, gripLimit, cornerSpeed

    throttle = max(-1, min(1, throttle));
    steer    = max(-1, min(1, steer));
    m = car.mass;

    % 1. Steering with rate limit
    target  = steer * car.maxSteer;
    dmax    = car.steerRate * dt;
    s.delta = s.delta + max(-dmax, min(dmax, target - s.delta));

    % 2. Grip budget
    rf = 1;  if isfield(road, 'rollFactor'), rf = road.rollFactor; end
    [Fdrag, Froll, Fgrade, N] = roadForces(car, s.v, road.alpha, rf);
    G = car.mu * road.muFactor * N;

    % 3. Sideways demand and understeer
    kCmd = tan(s.delta) / car.wheelbase;
    Fy   = m * s.v^2 * kCmd;
    understeer = abs(Fy) > G;
    if understeer
        Fy    = sign(Fy) * G;
        kappa = Fy / (m * s.v^2);
        FxMax = 0;
    else
        kappa = kCmd;
        FxMax = sqrt(G^2 - Fy^2);
    end

    % 4. Driving or braking, inside what the friction circle leaves
    Fdrive = 0;  Fbrake = 0;
    if throttle > 0 && s.energyJ > 0
        Fdrive = min(driveForce(car, s.v, throttle), FxMax);
    elseif throttle < 0
        Fbrake = min(-throttle * G, FxMax);
    end

    % 5. Newton along the track; rolling resistance and brakes only stop the car
    accel = (Fdrive - Fdrag - Froll - Fgrade - Fbrake) / m;
    vOld  = s.v;
    s.v   = max(0, vOld + accel * dt);

    % 6. Heading and position (semi-implicit: uses the new speed)
    s.theta = s.theta + s.v * kappa * dt;
    s.theta = atan2(sin(s.theta), cos(s.theta));
    s.x = s.x + s.v * cos(s.theta) * dt;
    s.y = s.y + s.v * sin(s.theta) * dt;

    % 7. Battery (joules)
    s.energyJ = max(0, s.energyJ - Fdrive * 0.5 * (vOld + s.v) * dt / car.eta);

    if nargout > 1
        Fx = Fdrive - Fbrake;
        info = struct('Fx', Fx, 'Fy', Fy, 'G', G, 'gripUse', hypot(Fx, Fy) / max(G, eps), ...
            'understeer', understeer, 'Fdrive', Fdrive, 'Fbrake', Fbrake, 'Fdrag', Fdrag, ...
            'Froll', Froll, 'Fgrade', Fgrade, 'accel', (s.v - vOld) / dt, 'kappa', kappa);
    end
end
