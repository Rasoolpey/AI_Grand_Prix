function assignments = draw_lots(seed, reveal)
% DRAW_LOTS  Fair topic draw for Part 1, shown on the projector.
%
%   draw_lots              % draw with a fresh random seed, animated reveal
%   draw_lots(123456)      % repeat an earlier draw exactly (same seed, same files)
%   draw_lots([], false)   % no animation (just the table + assignments.csv)
%
%   Reads   participants.csv  (name, choice = pool | own, own_topic)
%           topic_pool.csv    (id, title, keywords, matlab_angle)
%   Writes  assignments.csv   (name, choice, topic_id, topic, keywords)
%
%   Each "pool" participant gets a different topic from the pool. "own" participants keep their own topic.
%   The seed is printed and saved, so anyone can re-run the draw and check it.

    if nargin < 1 || isempty(seed)
        seed = mod(floor(posixtime(datetime('now')) * 1000), 2^31 - 1);
    end
    if nargin < 2, reveal = true; end

    here   = fileparts(mfilename('fullpath'));
    people = readtable(fullfile(here, 'participants.csv'), 'TextType', 'string', 'Delimiter', ',', 'Encoding', 'UTF-8');
    pool   = readtable(fullfile(here, 'topic_pool.csv'),   'TextType', 'string', 'Delimiter', ',', 'Encoding', 'UTF-8');

    people.choice = lower(strtrim(people.choice));
    isPool = people.choice == "pool";
    nPool  = nnz(isPool);
    if nPool > height(pool)
        error('draw_lots:tooFew', '%d people/groups chose the pool but there are only %d topics. Add topics to topic_pool.csv.', ...
              nPool, height(pool));
    end

    rng(seed, 'twister');
    order  = randperm(nPool);                 % who is revealed first
    picks  = randperm(height(pool), nPool);   % which topics, without repeats

    poolIdx = find(isPool);
    n = height(people);
    topicId = strings(n, 1); topic = strings(n, 1); keywords = strings(n, 1);
    for k = 1:nPool
        r = poolIdx(k);
        topicId(r)  = string(pool.id(picks(k)));
        topic(r)    = pool.title(picks(k));
        keywords(r) = pool.keywords(picks(k));
    end
    own = find(~isPool);
    for r = own'
        topicId(r) = "own";
        topic(r)   = people.own_topic(r);
    end

    assignments = table(people.name, people.choice, topicId, topic, keywords, ...
        'VariableNames', {'name', 'choice', 'topic_id', 'topic', 'keywords'});
    writetable(assignments, fullfile(here, 'assignments.csv'));

    fprintf('\n  TOPIC DRAW  |  seed %d  |  %d from the pool, %d own topic(s)\n\n', seed, nPool, numel(own));
    disp(assignments(:, {'name', 'topic_id', 'topic'}));
    fprintf('  Saved to assignments.csv. Re-run with draw_lots(%d) to reproduce this draw.\n\n', seed);

    if reveal && usejava('desktop')
        showReveal(people.name(poolIdx(order)), topic(poolIdx(order)), seed);
    end
end

function showReveal(names, topics, seed)
    bg = [0.075 0.125 0.227]; fg = [0.96 0.95 0.93]; accent = [1.00 0.54 0.24];
    f = figure('Color', bg, 'MenuBar', 'none', 'ToolBar', 'none', 'Name', 'Topic draw', ...
               'NumberTitle', 'off', 'WindowState', 'maximized');
    ax = axes(f, 'Position', [0 0 1 1], 'Visible', 'off', 'XLim', [0 1], 'YLim', [0 1]);
    text(ax, 0.5, 0.92, 'TOPIC DRAW', 'Color', accent, 'FontSize', 28, 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center', 'FontName', 'Consolas');
    text(ax, 0.5, 0.05, sprintf('seed %d', seed), 'Color', [0.6 0.65 0.74], 'FontSize', 14, ...
         'HorizontalAlignment', 'center', 'FontName', 'Consolas');
    hName  = text(ax, 0.5, 0.60, '', 'Color', fg, 'FontSize', 44, 'FontWeight', 'bold', 'HorizontalAlignment', 'center');
    hTopic = text(ax, 0.5, 0.42, '', 'Color', accent, 'FontSize', 34, 'HorizontalAlignment', 'center');
    hCount = text(ax, 0.5, 0.80, '', 'Color', [0.6 0.65 0.74], 'FontSize', 18, 'HorizontalAlignment', 'center');
    hHint  = text(ax, 0.5, 0.15, 'press any key for the next draw', 'Color', [0.6 0.65 0.74], ...
                  'FontSize', 16, 'HorizontalAlignment', 'center');
    for k = 1:numel(names)
        if ~isvalid(f), return; end
        hCount.String = sprintf('%d / %d', k, numel(names));
        hName.String  = names(k);
        hTopic.String = '';
        for spin = 1:12                                 % a short "spinning" effect before the reveal
            hTopic.String = topics(randi(numel(topics)));
            pause(0.08);
        end
        hTopic.String = topics(k);
        if k < numel(names)
            waitforbuttonpress;
        else
            hHint.String = 'all topics drawn - see assignments.csv';
        end
    end
end
