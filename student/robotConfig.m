function config = robotConfig()
% ROBOTCONFIG  Tuning hyperparameters for your autonomous controller.
%
%   config = robotConfig()
%
%   Edit the values below to tune your controller's behaviour.
%   These values are passed to controller(obs, config) each simulation step.
%
%   Access inside controller.m with:  config.fieldName
%
%   RULES:
%     ✓  Change the VALUES in this file freely
%     ✓  Add new fields for your own parameters
%     ✗  Do NOT change vehicle physics (those are in simulator/Vehicle.m)
%
%   TIP: Tell your AI agent to edit this file when you want to change
%   tuning parameters without touching the main control logic.

    % ------------------------------------------------------------------ %
    %  Core Pure-Pursuit parameters                                       %
    % ------------------------------------------------------------------ %

    % Look-ahead distance (metres)
    % Controls how far ahead the controller targets when computing steering.
    % Longer → smoother but slower to react to curves.
    % Shorter → sharper response but can oscillate or cut corners.
    config.lookaheadDistance = 3.0;

    % Target speed (m/s)   — Maximum allowed by physics: 10 m/s
    % Start conservative!  Reliability matters more than speed.
    config.targetSpeed = 4.5;


    % Proportional steering gain
    % Multiplies heading error → steering command.
    % Too low → sluggish cornering.  Too high → oscillation.
    config.steeringGain = 1.2;

    % Proportional throttle gain
    % How aggressively to accelerate/brake toward target speed.
    config.throttleGain = 0.5;

    % ------------------------------------------------------------------ %
    %  Add your own tuning parameters below as your controller evolves   %
    % ------------------------------------------------------------------ %
    %
    %  Example:
    %    config.cornerSpeed          = 2.0;   % m/s — target speed in corners
    %    config.straightSpeed        = 8.0;   % m/s — target speed on straights
    %    config.curvatureLookahead   = 8.0;   % m   — distance to pre-scan curvature
    %    config.curvatureThreshold   = 0.05;  % 1/m — curvature above which = corner
    %    config.brakingGain          = 0.8;   % how hard to brake before corners
    %

end
