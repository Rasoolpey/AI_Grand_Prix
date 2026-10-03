function command = controller(obs, config)
% =========================================================================
% controller.m — AI GRAND PRIX AUTONOMOUS RACING CONTROLLER
% =========================================================================
%
%   THIS IS YOUR MAIN FILE.  Edit it with your AI agent.
%   DO NOT modify anything inside the simulator/ folder.
%
% -------------------------------------------------------------------------
% INTERFACE
% -------------------------------------------------------------------------
%
%   command = controller(obs, config)
%
% -------------------------------------------------------------------------
% INPUTS
% -------------------------------------------------------------------------
%
%   obs — Observation struct  (read-only, provided by the simulator each step)
%
%     obs.position      [1×2]  Current vehicle position [x, y]  (metres)
%
%     obs.heading       [1×1]  Current vehicle heading θ  (radians)
%                              0 = pointing East  (+x direction)
%                              π/2 = pointing North (+y direction)
%                              (wraps to [−π, π])
%
%     obs.speed         [1×1]  Current speed  (m/s,  always ≥ 0)
%
%     obs.previewPoints [N×2]  Upcoming centreline waypoints [x,y]
%                              Ordered nearest → furthest ahead
%                              Typically N = 20 points
%
%     obs.trackWidth    [1×1]  Track width  (m)
%
%     obs.dt            [1×1]  Simulation timestep  (s,  fixed = 0.02 s)
%
%   config — Tuning parameters from student/robotConfig.m
%            Access with:  config.fieldName
%
% -------------------------------------------------------------------------
% OUTPUTS
% -------------------------------------------------------------------------
%
%   command — Command struct  (you fill this in every call)
%
%     command.throttle  [1×1]  Throttle / brake demand, range [−1, +1]
%                               +1 = maximum acceleration
%                                0 = coast (no throttle, no brake)
%                               −1 = maximum braking
%
%     command.steering  [1×1]  Steering demand, range [−1, +1]
%                               −1 = maximum left
%                                0 = straight ahead
%                               +1 = maximum right
%
% -------------------------------------------------------------------------
% PHYSICAL LIMITS  (enforced by the simulator — you cannot exceed these)
% -------------------------------------------------------------------------
%
%   Maximum speed           :  10   m/s  (36 km/h)
%   Maximum acceleration    :   3   m/s²
%   Maximum braking         :   6   m/s²
%   Maximum steering angle  :   0.5 rad  (~28°)
%   Maximum steering rate   :   1.0 rad/s
%
% -------------------------------------------------------------------------
% SCORING
% -------------------------------------------------------------------------
%
%   Score = LapTime  +  5 × OffTrackExits  +  10 × BarrierContacts
%   Lower is better.  DNF if the lap is not completed within 120 s.
%
% =========================================================================

    % ------------------------------------------------------------------
    % Pull tuning parameters from config (with safe defaults)
    % ------------------------------------------------------------------
    lookaheadDist = getparam(config, 'lookaheadDistance', 3.0);   % metres
    targetSpeed   = getparam(config, 'targetSpeed',       3.5);   % m/s
    steeringGain  = getparam(config, 'steeringGain',      1.2);   % proportional gain
    throttleGain  = getparam(config, 'throttleGain',      0.5);   % proportional gain

    % ------------------------------------------------------------------
    % BASELINE: Pure Pursuit Steering
    % ------------------------------------------------------------------
    % Strategy: find a look-ahead point on the centreline at roughly
    % 'lookaheadDist' metres ahead, compute the heading error to that
    % point, and command proportional steering.
    % ------------------------------------------------------------------

    if isempty(obs.previewPoints)
        % Emergency stop — no preview data available
        command.throttle = -1;
        command.steering =  0;
        return;
    end

    % Euclidean distances from vehicle to each preview point
    dx   = obs.previewPoints(:,1) - obs.position(1);
    dy   = obs.previewPoints(:,2) - obs.position(2);
    dist = sqrt(dx.^2 + dy.^2);

    % Choose the preview point closest to our desired look-ahead distance
    [~, idx]     = min(abs(dist - lookaheadDist));
    targetPoint  = obs.previewPoints(idx, :);

    % Angle from vehicle to target in world frame
    angleToTarget = atan2(targetPoint(2) - obs.position(2), ...
                          targetPoint(1) - obs.position(1));

    % Heading error  (positive = target is to the LEFT)
    headingError = wrapAngle(angleToTarget - obs.heading);

    % Proportional steering, clamped to [−1, +1]
    command.steering = max(-1, min(1, steeringGain * headingError));

    % ------------------------------------------------------------------
    % BASELINE: Constant Target Speed
    % ------------------------------------------------------------------
    % The baseline runs at a fixed target speed.
    % TODO: improve this — use curvature to slow down in corners!
    % ------------------------------------------------------------------
    speedError       = targetSpeed - obs.speed;
    command.throttle = max(-1, min(1, throttleGain * speedError));

end

% =========================================================================
% Local helpers
% =========================================================================

function val = getparam(config, field, default)
% Safely get config.field, returning default if missing.
    if isstruct(config) && isfield(config, field)
        val = config.(field);
    else
        val = default;
    end
end

function a = wrapAngle(a)
% Wrap angle to [−π, π] without requiring the Signal Processing Toolbox.
    a = mod(a + pi, 2*pi) - pi;
end
