function command = refController(obs, config)
% REFCONTROLLER  Instructor reference controller (sets T_ref; never give to students).
%
%   Pure pursuit steering + speed planned from equation 6 over the preview
%   points + braking curves + a battery-aware speed cap.
%
%   config fields (all optional):
%     gripMargin    fraction of the eq. 6 corner speed to aim for  (0.92)
%     brakeMargin   fraction of mu*g used to plan braking          (0.80)
%     lookGain      pure pursuit look-ahead = lookMin + lookGain*v  (0.35)
%     lookMin       (m)                                            (2.5)
%     wetFactor     grip factor assumed on wet points              (0.6)
%     energyAware   adapt a speed cap to the battery               (true)
%     kp            throttle gain per m/s of speed error           (1.5)
%
%   See also: controllerStyles, benchmarkTime

    persistent vCap startDist nextCheck
    if obs.time == 0, vCap = Inf; startDist = NaN; nextCheck = 100; end

    gm   = opt(config, 'gripMargin', 0.92);
    bm   = opt(config, 'brakeMargin', 0.80);
    lg   = opt(config, 'lookGain', 0.35);
    lmin = opt(config, 'lookMin', 2.5);
    wetF = opt(config, 'wetFactor', 0.6);
    kp   = opt(config, 'kp', 1.5);
    car  = obs.car;
    P    = obs.previewPoints;
    v    = obs.speed;

    % ---- Steering: pure pursuit ---------------------------------------- %
    d  = hypot(P(:,1) - obs.position(1), P(:,2) - obs.position(2));
    Ld = lmin + lg * v;
    k  = find(d >= Ld, 1);
    if isempty(k), k = size(P, 1); end
    ang   = atan2(P(k,2) - obs.position(2), P(k,1) - obs.position(1)) - obs.heading;
    ang   = atan2(sin(ang), cos(ang));
    delta = atan(2 * car.wheelbase * sin(ang) / max(d(k), 0.5));
    command.steering = max(-1, min(1, delta / car.maxSteer));

    % ---- Speed: eq. 6 at every preview point + braking curves ----------- %
    n = size(P, 1);
    kap = zeros(n, 1);
    for i = 3:n-2
        kap(i) = curvature3(P(i-2,1:2), P(i,1:2), P(i+2,1:2));
    end
    kap(1:2) = kap(min(3,n));  kap(max(n-1,1):n) = kap(max(n-2,1));
    mu  = ones(n, 1);  mu(P(:,4) > 0) = wetF;
    alpha = atan(P(:,3) / 100);
    vCorner = gm * cornerSpeed(car, kap, alpha, mu);
    along = [0; cumsum(hypot(diff(P(:,1)), diff(P(:,2))))] + d(1);
    aBrake = bm * car.mu * min(mu) * car.g;
    vAllow = sqrt(vCorner.^2 + 2 * aBrake * along);
    vT = min([vAllow; car.vGear]);

    % open path: be stopped by the end of the stop box
    if strcmp(obs.path.type, "open") && isfinite(obs.path.distanceToStop)
        vT = min(vT, sqrt(2 * aBrake * max(obs.path.distanceToStop - 1.5, 0)));
    end

    % ---- Battery: cap the speed if the energy will not last ------------- %
    % Every 20 m (after the first 100 m): compare the average energy used per
    % metre so far with what is left per metre to the finish, and move a
    % speed cap down or up by 0.3 m/s.  Never below 7 m/s.
    if opt(config, 'energyAware', true) && strcmp(obs.path.type, "circuit")
        distLeft = obs.path.distanceToFinish;
        if isnan(startDist), startDist = distLeft; end
        done = startDist - distLeft;
        if done >= nextCheck
            nextCheck = done + 20;
            rate   = (1 - obs.batteryFrac) * car.batteryJ / done;        % J per metre so far
            budget = obs.batteryFrac * car.batteryJ / max(distLeft, 1);  % J per metre we can afford
            if rate > 0.97 * budget
                vCap = max(7, min(vCap, max(v, 7)) - 0.3);
            elseif rate < 0.85 * budget && isfinite(vCap)
                vCap = vCap + 0.3;
            end
        end
        vT = min(vT, vCap);
    end

    e = vT - v;
    command.throttle = max(-1, min(1, kp * e));
end

function k = curvature3(a, b, c)
% Signed curvature of the circle through three points.
    ab = b - a;  bc = c - b;  ac = c - a;
    cr = ab(1) * bc(2) - ab(2) * bc(1);
    k  = 2 * cr / max(norm(ab) * norm(bc) * norm(ac), 1e-9);
end

function v = opt(s, f, d)
    if isstruct(s) && isfield(s, f), v = s.(f); else, v = d; end
end
