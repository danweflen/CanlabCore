function [han, X, Y, slope_stats] = line_plot_multisubject(X, Y, varargin)
% Plots a scatterplot with multi-subject data, with one line per subject
% in a unique color.
%
% :Usage:
% ::
%
%    [han, X, Y, b] = line_plot_multisubject(X, Y, varargin)
%
% :Inputs:
%
%   **X and Y:**
%        are cell arrays, one cell per upper level unit (subject)
%
% varargin:
%
%   **'n_bins:**
%        pass in the number of point "bins".  Will divide each subj's trials
%        into bins, get the avg X and Y per bin, and plot those points.  
%
%   **'noind':**
%        suppress points
%
%   **'subjid':**
%        followed by integer vector of subject ID numbers. Use when
%        passing in vectors (with subjects concatenated) rather than
%        cell arrays in X and Y
%
%   **'center':**
%        subtract means of each subject before plotting
%
%   **'colors':**
%        followed by cell array length N of desired colors, rgb specification,
%        for each line.  if not passed in, will use custom_colors.
%        Group average lines use color{1} for line and color{2} for fill.
%
%   **'gcolors':***
%        Group average line colors, {[r g b] [r g b]} for line and point
%        fill, respectively
%
%   **'MarkerTypes':**
%        followed by char string.  if not passed in, uses
%        'osvd^<>ph' by default
%
%   **'group_avg_ref_line':**
%        will make a reference line for the group avg
%
% :Outputs:
%
%   **han:**
%        handles to points and lines
%
%   **X, Y:**
%        new variables (binned if bins requested)
%
%   **slope_stats** 
%        slope of linear relationship for each person
%         
% :Examples:
% ::
%
%    for i = 1:20, X{i} = randn(4, 1); Y{i} = X{i} + .3*randn(4, 1) + randn(1); end
%    han = line_plot_multisubject(X, Y)
%
%   Custom colors and points:
%   [han, Xbin, Ybin] = line_plot_multisubject(expect, pain, 'n_bins', 4, 'group_avg_ref_line', 'MarkerTypes', 'o', 'colors', custom_colors([1 .7 .4], [1 .7 .4], 100));
%
% Center within subjects and bin, then calculate correlation of
% within-subject variables:
% ::
%
%    create_figure('lines'); [han, Xbin, Ybin] = line_plot_multisubject(stats.Y, stats.yfit, 'n_bins', 7, 'center');
%    corr(cat(1, Xbin{:}), cat(1, Ybin{:}))

% -------------------------------------------------------------------------
% Defaults and inputs
% -------------------------------------------------------------------------

docenter = 0;
doind = 1;
dolines = 1;
group_avg_ref_line = 0;

for i=1:length(varargin)
    if ischar(varargin{i})
        switch varargin{i}
            case 'n_bins'
                n_bins = varargin{i+1};
                %bin_size = length(X{1}) / n_bins;
                %if rem(length(X{1}), n_bins) ~= 0, error('Num trials must be divisible by num bins'), end;
                
            case 'subjid'
                subjid = varargin{i + 1};
                if iscell(X) || iscell(Y)
                    error('X and Y should be vectors when using subjid, not cell arrays.');
                end
                u = unique(subjid);
                for i = 1:length(u)
                    XX{i} = X(subjid == u(i));
                    YY{i} = Y(subjid == u(i));
                end
                X = XX;
                Y = YY;
                
            case 'center'
                docenter = 1;
                
            case 'colors'
                colors = varargin{i+1};
                
            case 'MarkerTypes'
                mtypes = varargin{i+1};
                
            case 'noind'
                doind=0;
                
            case 'nolines'
                dolines = 0;
                
            case 'group_avg_ref_line'
                group_avg_ref_line = 1;
                
            case 'gcolors' % Mj added!!
                gcolors = varargin{i+1};
        end
    end
end

if ~iscell(X) || ~iscell(Y)
    error('X and Y should be cell arrays, one cell per line to plot.');
end

N = length(X);

% Set color options and check
% -------------------------------------------------------------------------

if ~exist('colors', 'var') %,colors = scn_standard_colors(N); end
    colors = custom_colors([1 .5 .4], [.8 .8 .4], N);
end
if ~iscell(colors), error('Colors should be cell array of color specifications.'); end
if length(colors) < N, colors = repmat(colors, 1, N); end

if ~exist('mtypes', 'var'), mtypes = 'osvd^<>ph'; end

if ~exist('gcolors', 'var') 
    % MJ added.  Line then fill.
    gcolors = colors(1:2);
end
if ~iscell(gcolors), gcolors = {gcolors}; end
    
% replicate for fill color if 2nd color is empty
if length(gcolors) < 2, gcolors{2} = gcolors{1}; end

hold on

% -------------------------------------------------------------------------
% Plot points and lines
% -------------------------------------------------------------------------

for i = 1:N
    
    % choose marker
    whm = min(i, mod(i, length(mtypes)) + 1);
    
    if length(X{i}) == 0 || all(isnan(X{i})) ||  all(isnan(Y{i}))
        % empty
        continue
        
    elseif length(X{i}) ~= length(Y{i})
        error(['Subject ' num2str(i) ' has unequal elements in X{i} and Y{i}. Check data.'])
    end
    
    % centere, if asked for
    if docenter
        X{i} = scale(X{i}, 1);
        Y{i} = scale(Y{i}, 1);
    end
    
    
    % plot points in bins
    if exist('n_bins', 'var')
        if n_bins ~= 0
            points = zeros(n_bins,2);
            t = sortrows([X{i} Y{i}],1); % not really even needed
            
            x = t(:, 1);
            bins = prctile(x, linspace(0, 100, n_bins + 1));
            bins(end) = Inf;
            
            for j=1:n_bins %make the bins
                
                wh = x >= bins(j) & x < bins(j+1);
                
                points(j,:) = nanmean(t(wh, :));
                
                ste_points(j, :) = nanstd(t(wh, :)) ./ sqrt(sum(wh));
                
                %points(j,:) = nanmean(t( bin_size*(j-1)+1 : bin_size*j ,:));
            end
            
            X{i} = points(:, 1);
            Y{i} = points(:, 2);
            
            %han.point_handles(i) = plot(points(:,1), points(:,2), ['k' mtypes(whm(1))], 'MarkerFaceColor', colors{i}, 'Color', max([0 0 0; colors{i}.*.7]));
        end
    end
    
    % plot ref line
    b(i,:) = glmfit(X{i}, Y{i});
    
    if dolines
        han.line_handles(i) = plot([min(X{i}) max(X{i})], [b(i,1)+b(i,2)*min(X{i}) b(i,1)+b(i,2)*max(X{i})], 'Color', colors{i}, 'LineWidth', 1);
    end
    
    % plot all the points
    if doind
        han.point_handles(i) = plot(X{i}, Y{i}, ['k' mtypes(whm(1))], 'MarkerSize', 3, 'MarkerFaceColor', colors{i}, 'Color', max([0 0 0; colors{i}]));
    end
end % subject loop

% Stats on slope
% -----------------------------------------------------------------
slope_stats.b = b;
[~, slope_stats.p, ~, tmpstat] = ttest(b(:, 2));
slope_stats.t = tmpstat.tstat;
slope_stats.df = tmpstat.df;
    
Xc = cat(1, X{:});
Yc = cat(1, Y{:});
[wasnan, Xc, Yc] = nanremove(Xc, Yc);
slope_stats.r = corr(Xc, Yc);
slope_stats.wasnan = wasnan;

fprintf('r = %3.2f, t(%3.0f) = %3.2f, p = %3.6f, num. missing: %3.0f\n', ...
    slope_stats.r, slope_stats.df, slope_stats.t, slope_stats.p, sum(slope_stats.wasnan));

% Individual points
% -----------------------------------------------------------------
% get rid of bad handles for missing subjects
if doind
    han.point_handles = han.point_handles(ishandle(han.point_handles) & han.point_handles ~= 0);
end

if dolines
    han.line_handles = han.line_handles(ishandle(han.line_handles) & han.line_handles ~= 0);
end

%the correlation
%r=corr(cat(1,detrend(X{:},'constant')), cat(1,detrend(Y{:}, 'constant')), 'rows', 'complete')

% plot the average ref line
% -----------------------------------------------------------------
if group_avg_ref_line
    
    if exist('n_bins', 'var') && n_bins ~= 0
        % PLOT GROUP BIN WITH CROSSHAIR STD. ERRORS FOR EACH BIN
        
        XX = cat(2, X{:})';
        YY = cat(2, Y{:})';
        
        % means and standard errors
        mX = nanmean(XX);
        sX = ste(XX);
        mY = nanmean(YY);
        sY = ste(YY);
        
        h = sepplot(mX, mY, .7, 'color', gcolors{1}, 'linewidth', 4);
        
        h2 = errorbar_horizontal(mX, mY, sX, 'o', 'color', gcolors{1}, 'linewidth', 3, 'markersize', 8, 'markerfacecolor', gcolors{2});
        h1 = errorbar(mX, mY, sY, 'o', 'color', gcolors{1}, 'linewidth', 3, 'markersize', 8, 'markerfacecolor', gcolors{2});
        set(h2, 'linewidth', 3, 'color', gcolors{1});
        
        han.grpline_handle = h;
        han.grpline_err_handle = [h1 h2];
        else
            
    avg_b = mean(b);
    Xs = cat(2,X{:});
    minX = prctile(Xs(1,:),5);
    maxX = prctile(Xs(end,:),95);
    han.grpline_handle = plot([minX maxX], [avg_b(1)+avg_b(2)*minX avg_b(1)+avg_b(2)*maxX], 'Color', 'k', 'LineWidth', 6);
end

end % function
