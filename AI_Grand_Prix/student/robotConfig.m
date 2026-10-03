function config = robotConfig()
% ROBOTCONFIG  Tuning values for your controller.
%
%   config = robotConfig()
%
%   These values are passed to controller(obs, config) every step.
%   Read them in controller.m as  config.fieldName.
%
%   RULES:
%     ✓  Change the VALUES freely and add your own fields
%     ✗  Car parts go in carDesign.m; physics is in simulator/ (do not modify)

    % Pure pursuit look-ahead distance (m).
    % Longer -> smoother but cuts corners; shorter -> sharper but can oscillate.
    config.lookaheadDistance = 3.0;

    % Target speed (m/s).  The baseline drives at ONE speed everywhere.
    % Faster is possible: the safe corner speed comes from equation 6.
    config.targetSpeed = 7.0;

    % How hard to chase the target speed (throttle per m/s of error).
    config.throttleGain = 0.5;

    % Braking used to stop in the drag strip's stop box (m/s^2).
    config.stopDecel = 4.0;

    % ---- Add your own parameters below ----
    %   config.gripMargin   = 0.9;   % fraction of the eq. 6 corner speed to use
    %   config.brakeDecel   = 7.0;   % m/s^2 you plan to brake with
end
