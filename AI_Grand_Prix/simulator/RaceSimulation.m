function results = RaceSimulation(track, vehicle, controllerFn, config, options)
% RACESIMULATION  Core simulation loop for the AI Grand Prix.
%
%   ╔══════════════════════════════════════╗
%   ║  SIMULATOR FILE — DO NOT MODIFY     ║
%   ╚══════════════════════════════════════╝
%
%   results = RaceSimulation(track, vehicle, controllerFn, config, options)
%
%   INPUTS:
%     track         — Track object (from Track(createPracticeTrack()))
%     vehicle       — Vehicle object, already positioned at start
%     controllerFn  — function handle:  @(obs, config) → command
%     config        — config struct passed to controllerFn each step
%     options       — (optional) simulation options struct:
%       .headless   : skip visualisation (default: false)
%       .maxTime    : maximum lap time in seconds (default: 120)
%       .dt         : fixed timestep in seconds (default: 0.02)
%
%   OUTPUT:  results struct with fields
%     .lapCompleted  logical
%     .lapTime       seconds (Inf if DNF)
%     .nOffTrack     integer (debounced exit count)
%     .nCollision    integer (hard barrier contacts)
%     .dnf           logical
%     .dnfReason     string
%     .score         lapTime + 5*nOffTrack + 10*nCollision (Inf if DNF)
%     .log           telemetry struct (t, x, y, theta, v, throttle,
%                    steering, steeringAngle, offTrack, crossTrackErr)
%     .track         Track object (for plotLap)
%     .dt            timestep used

    % ------------------------------------------------------------------ %
    %  Parse options                                                      %
    % ------------------------------------------------------------------ %
    if nargin < 5 || isempty(options), options = struct(); end
    dt       = raceGetOpt(options, 'dt',       0.02);
    maxTime  = raceGetOpt(options, 'maxTime',  120);
    headless = raceGetOpt(options, 'headless', false);

    maxSteps = ceil(maxTime / dt);

    % ------------------------------------------------------------------ %
    %  Pre-allocate telemetry logs                                        %
    % ------------------------------------------------------------------ %
    lg.t             = zeros(maxSteps, 1);
    lg.x             = zeros(maxSteps, 1);
    lg.y             = zeros(maxSteps, 1);
    lg.theta         = zeros(maxSteps, 1);
    lg.v             = zeros(maxSteps, 1);
    lg.throttle      = zeros(maxSteps, 1);
    lg.steering      = zeros(maxSteps, 1);
    lg.steeringAngle = zeros(maxSteps, 1);
    lg.offTrack      = false(maxSteps, 1);
    lg.crossTrackErr = zeros(maxSteps, 1);

    % ------------------------------------------------------------------ %
    %  Race state                                                         %
    % ------------------------------------------------------------------ %
    lapTime    = Inf;
    nOffTrack  = 0;
    nCollision = 0;
    wasOnTrack = true;   % for debounced off-track counting
    dnf        = false;
    dnfReason  = '';

    % ------------------------------------------------------------------ %
    %  Visualiser                                                         %
    % ------------------------------------------------------------------ %
    if ~headless
        viz = Visualizer(track);
    end

    prevX = vehicle.x;
    prevY = vehicle.y;

    % ------------------------------------------------------------------ %
    %  Main simulation loop                                               %
    % ------------------------------------------------------------------ %
    step = 0;
    while step < maxSteps

        step = step + 1;
        t    = (step - 1) * dt;

        % ---- Build observation struct ----
        obs = vehicle.buildObs(track, dt);

        % ---- Call student controller (protected) ----
        try
            command = controllerFn(obs, config);
            throttle = double(command.throttle);
            steering = double(command.steering);
        catch ME
            warning('RaceSimulation: controller error at t=%.2fs — %s', t, ME.message);
            throttle = -1;   % emergency brake on controller crash
            steering = 0;
        end

        % ---- Step vehicle physics ----
        vehicle.step(throttle, steering, dt);

        % ---- Log telemetry ----
        lg.t(step)             = t;
        lg.x(step)             = vehicle.x;
        lg.y(step)             = vehicle.y;
        lg.theta(step)         = vehicle.theta;
        lg.v(step)             = vehicle.v;
        lg.throttle(step)      = throttle;
        lg.steering(step)      = steering;
        lg.steeringAngle(step) = vehicle.steeringAngle;

        % ---- Off-track and collision detection ----
        [~, crossErr, onTrack] = track.findNearest(vehicle.x, vehicle.y);
        lg.offTrack(step)      = ~onTrack;
        lg.crossTrackErr(step) = crossErr;

        % Hard collision: more than one full track width from centreline
        if abs(crossErr) > track.width
            nCollision = nCollision + 1;
        end

        % Debounced off-track: count ON→OFF transitions, not every frame
        if ~onTrack && wasOnTrack
            nOffTrack  = nOffTrack + 1;
            wasOnTrack = false;
        elseif onTrack
            wasOnTrack = true;
        end

        % ---- Lap completion ----
        % Ignore the first 0.5s to avoid false detection at race start
        if step > round(0.5 / dt)
            if track.checkStartFinish(prevX, prevY, vehicle.x, vehicle.y)
                lapTime = t;
                break;
            end
        end

        % ---- DNF conditions ----
        if nOffTrack > 20
            dnf = true;
            dnfReason = 'Excessive off-track events (> 20)';
            break;
        end
        if abs(crossErr) > 4 * track.width
            dnf = true;
            dnfReason = sprintf('Irrecoverable: %.1f m from centreline', abs(crossErr));
            break;
        end

        % ---- Update visualiser ----
        if ~headless
            viz.update(vehicle, t, nOffTrack);
            drawnow limitrate;
        end

        prevX = vehicle.x;
        prevY = vehicle.y;
    end % simulation loop

    % ------------------------------------------------------------------ %
    %  Post-loop: check for timeout DNF                                  %
    % ------------------------------------------------------------------ %
    if ~dnf && isinf(lapTime)
        dnf       = true;
        dnfReason = sprintf('Time limit exceeded (%.0f s)', maxTime);
    end

    % ------------------------------------------------------------------ %
    %  Scoring                                                            %
    % ------------------------------------------------------------------ %
    if dnf
        score = Inf;
    else
        score = lapTime + 5 * nOffTrack + 10 * nCollision;
    end

    % ------------------------------------------------------------------ %
    %  Trim logs to actual steps taken                                   %
    % ------------------------------------------------------------------ %
    fields = fieldnames(lg);
    for fi = 1:numel(fields)
        lg.(fields{fi}) = lg.(fields{fi})(1:step);
    end

    % ------------------------------------------------------------------ %
    %  Pack output                                                        %
    % ------------------------------------------------------------------ %
    results.lapCompleted = ~isinf(lapTime);
    results.lapTime      = lapTime;
    results.nOffTrack    = nOffTrack;
    results.nCollision   = nCollision;
    results.dnf          = dnf;
    results.dnfReason    = dnfReason;
    results.score        = score;
    results.log          = lg;
    results.track        = track;
    results.dt           = dt;

end % RaceSimulation

% ======================================================================= %
%  Local helpers                                                           %
% ======================================================================= %

function val = raceGetOpt(s, field, default)
% Return s.field if it exists, otherwise default.
    if isfield(s, field)
        val = s.(field);
    else
        val = default;
    end
end
