function command = controller(obs, config)
% CONTROLLER  Your car's driver.  ⭐ YOUR FILE (with carDesign.m)
%
%   command = controller(obs, config)      called every 0.02 s
%
% -------------------------------------------------------------------------
% INPUTS
% -------------------------------------------------------------------------
%   obs.position       [x y]     car position (m)
%   obs.heading        theta     heading (rad): 0 = +x (East), pi/2 = +y (North)
%   obs.speed          v         speed (m/s, >= 0)
%   obs.steeringAngle  delta     actual front-wheel angle (rad, + = left)
%   obs.time                     time since the start (s)
%   obs.dt                       time step (0.02 s)
%   obs.trackWidth               road width (m)
%   obs.previewPoints  N x 4     the next ~60 centreline points, ~1 m apart,
%                                nearest first:  [x  y  grade(%)  wet(0/1)]
%                                (fewer near the end of an open path)
%   obs.car            the car you built: mass, mu, Crr, power, CdA, ClA,
%                      vGear, Fgear, wheelbase, maxSteer, steerRate, eta,
%                      rho, g, batteryWh, batteryJ  (see PHYSICS.md)
%   obs.batteryWh      energy left (Wh);  obs.batteryFrac  fraction left (0-1)
%   obs.path.type      "circuit" or "open"
%   obs.path.lap, .laps, .lapsLeft
%   obs.path.nextCheckpoint, .checkpointsPerLap
%   obs.path.distanceToFinish   metres to the (final) finish line
%   obs.path.distanceToStop     open path: metres to the END of the stop box
%                               (NaN on a circuit)
%   config             your values from robotConfig.m
%
% -------------------------------------------------------------------------
% OUTPUT
% -------------------------------------------------------------------------
%   command.throttle   [-1, +1]   +1 full drive, 0 coast, -1 full brake
%   command.steering   [-1, +1]   +1 full LEFT, -1 full RIGHT
%
%   You may keep memory between calls with  persistent  variables
%   (they are cleared before every run).
%
% -------------------------------------------------------------------------
% THE PHYSICS (PHYSICS.md):  the tyres' grip is shared between braking,
% driving and turning (eq. 5).  The fastest safe speed in a corner of
% curvature kappa is (eq. 6):
%       v^2 = mu g cos(alpha) / (|kappa| - mu rho C_L A / (2 m))
% The simulator has this as a function:  cornerSpeed(obs.car, kappa)
% -------------------------------------------------------------------------

    lookahead   = getparam(config, 'lookaheadDistance', 3.0);
    targetSpeed = getparam(config, 'targetSpeed',       7.0);
    kThrottle   = getparam(config, 'throttleGain',      0.5);
    stopDecel   = getparam(config, 'stopDecel',         4.0);

    P = obs.previewPoints;
    if isempty(P)
        command.throttle = -1;  command.steering = 0;
        return;
    end

    % ---- Steering: aim at the preview point about 'lookahead' metres away ----
    dist = hypot(P(:,1) - obs.position(1), P(:,2) - obs.position(2));
    [~, k] = min(abs(dist - lookahead));
    angleToTarget = atan2(P(k,2) - obs.position(2), P(k,1) - obs.position(1));
    headingError  = wrapAngle(angleToTarget - obs.heading);   % + = target is to the LEFT
    command.steering = max(-1, min(1, 1.2 * headingError));

    % ---- Speed: one constant target speed everywhere ----
    % TODO: slow down only for corners (eq. 6) and brake just in time.
    vTarget = targetSpeed;

    % Drag strip: be stopped by the end of the stop box  (v^2 = 2 a d)
    if obs.path.type == "open" && isfinite(obs.path.distanceToStop)
        vTarget = min(vTarget, sqrt(2 * stopDecel * max(obs.path.distanceToStop - 2, 0)));
    end

    command.throttle = max(-1, min(1, kThrottle * (vTarget - obs.speed)));
end

% =========================================================================
function val = getparam(config, field, default)
    if isstruct(config) && isfield(config, field)
        val = config.(field);
    else
        val = default;
    end
end

function a = wrapAngle(a)
    a = mod(a + pi, 2*pi) - pi;
end
