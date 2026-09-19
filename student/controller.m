function command = controller(obs, config)
% =========================================================================
% controller.m — AI GRAND PRIX AUTONOMOUS RACING CONTROLLER
% =========================================================================
%
% THIS IS YOUR MAIN FILE. Edit it with your AI agent.
%
% INTERFACE:
%   command = controller(obs, config)
%
% -------------------------------------------------------------------------
% INPUTS
% -------------------------------------------------------------------------
%
%   obs  — Observation struct (read-only — provided by the simulator)
%
%     obs.position      [1×2] Current vehicle position [x, y] in metres
%     obs.heading       [1×1] Current vehicle heading θ in radians
%                             (0 = pointing in +x direction, 
%                              π/2 = pointing in +y direction)
%     obs.speed         [1×1] Current vehicle speed in m/s (always ≥ 0)
%     obs.previewPoints [N×2] Upcoming centreline waypoints [x1,y1; x2,y2; ...]
%                             ordered from nearest to furthest ahead
%                             (N is typically 20 points)
%     obs.trackWidth    [1×1] Track width in metres
%     obs.dt            [1×1] Simulation timestep in seconds (fixed = 0.02 s)
%
%   config — Controller configuration struct (from student/robotConfig.m)
%            Use this for tuning parameters. Leave empty if not using.
%
% -------------------------------------------------------------------------
% OUTPUTS
% -------------------------------------------------------------------------
%
%   command — Command struct (you fill this in)
%
%     command.throttle  [1×1] Throttle/brake demand, range [-1, +1]
%                             +1 = maximum acceleration
%                              0 = no throttle, no brake
%                             -1 = maximum braking
%
%     command.steering  [1×1] Steering demand, range [-1, +1]
%                             -1 = maximum left
%                              0 = straight ahead
%                             +1 = maximum right
%
% -------------------------------------------------------------------------
% PHYSICAL LIMITS (enforced by the simulator — you cannot exceed these)
% -------------------------------------------------------------------------
%
%   Maximum speed:          10 m/s  (36 km/h)
%   Maximum acceleration:   3  m/s²
%   Maximum braking:        6  m/s²
%   Maximum steering angle: 0.5 rad (~28°)
%   Maximum steering rate:  1.0 rad/s
%
% -------------------------------------------------------------------------
% SCORING REMINDER
% -------------------------------------------------------------------------
%
%   Score = LapTime + 5 × TrackExits + 10 × Collisions
%   Lower is better. DNF if you do not complete the lap within the time limit.
%
% =========================================================================

    % ------------------------------------------------------------------
    % BASELINE IMPLEMENTATION — Pure Pursuit (conservative)
    % ------------------------------------------------------------------
    % This baseline uses simple Pure Pursuit to steer toward a look-ahead
    % point on the centreline at a fixed low speed.
    %
    % It will complete the practice track safely but slowly.
    % Your job: make it better.
    % ------------------------------------------------------------------

    % --- Configuration defaults (override via robotConfig.m) ---
    if nargin < 2 || isempty(config)
        config = struct();
    end

    lookaheadDistance = getfield_default(config, 'lookaheadDistance', 2.0);  % metres
    targetSpeed       = getfield_default(config, 'targetSpeed',       2.5);  % m/s

    % --- Find look-ahead point on centreline ---
    if isempty(obs.previewPoints)
        % No preview points available — stop
        command.throttle = -1;
        command.steering = 0;
        return;
    end

    % Compute distance from vehicle to each preview point
    dx = obs.previewPoints(:,1) - obs.position(1);
    dy = obs.previewPoints(:,2) - obs.position(2);
    dist = sqrt(dx.^2 + dy.^2);

    % Find the preview point at approximately the look-ahead distance
    [~, idx] = min(abs(dist - lookaheadDistance));
    targetPoint = obs.previewPoints(idx, :);

    % --- Pure Pursuit steering ---
    % Compute angle to target point in world frame
    angleToTarget = atan2(targetPoint(2) - obs.position(2), ...
                          targetPoint(1) - obs.position(1));

    % Heading error (difference between where we point and where we want to go)
    headingError = wrapToPi(angleToTarget - obs.heading);

    % Proportional steering (clamp to [-1, +1])
    steeringGain = 1.5;
    command.steering = max(-1, min(1, steeringGain * headingError));

    % --- Speed control (fixed target speed for baseline) ---
    speedError = targetSpeed - obs.speed;
    throttleGain = 0.5;
    command.throttle = max(-1, min(1, throttleGain * speedError));

end

% =========================================================================
% Helper: get struct field with default value
% =========================================================================
function val = getfield_default(s, field, default)
    if isfield(s, field)
        val = s.(field);
    else
        val = default;
    end
end
