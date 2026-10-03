function styles = controllerStyles()
% CONTROLLERSTYLES  Several driving styles of the reference controller (TODO_RACE §8).
%
%   styles = controllerStyles()     struct array: name, config
%
%   reference  the style that sets T_ref
%   aggressive small margins: faster when it works, riskier
%   cautious   large margins
%   saver      energy-aware with a lower corner margin (lift early)
%
%   See also: refController, balanceSweep
    styles = struct( ...
        'name',   {"reference", "aggressive", "cautious", "saver"}, ...
        'config', {struct('gripMargin', 0.92, 'brakeMargin', 0.80), ...
                   struct('gripMargin', 0.98, 'brakeMargin', 0.92, 'kp', 2.5), ...
                   struct('gripMargin', 0.80, 'brakeMargin', 0.60), ...
                   struct('gripMargin', 0.88, 'brakeMargin', 0.70, 'energyAware', true, 'kp', 1.0)});
end
