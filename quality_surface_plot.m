% quality_surface_plot.m
clear; clc;
global stock_prices
stock_prices = csvread('stock_prices1.csv');

% Fixed Parameters
N  = 27.0235;
q1 = -0.6170;  % fixed velocity weight
fc = 0.7015;
B  = 0.0418;
S  = -0.0086;
WMA = 4.6282;

% Grid setup for q2 and q3
q2_vals = linspace(-1, 1, 30);
q3_vals = linspace(-1, 1, 30);
portfolio_value = NaN(length(q3_vals), length(q2_vals));  % matrix for surf plot

% Grid search
for i = 1:length(q2_vals)
    for j = 1:length(q3_vals)
        q = [q1, q2_vals(i), q3_vals(j)];
        param = [N, q, fc, B, S, WMA];
        try
            [cost, ~] = exchange_analysis(param, 0);
            portfolio_value(j,i) = -cost;
        catch
            fprintf('Failed at q2=%.2f, q3=%.2f\n', q2_vals(i), q3_vals(j));
        end
    end
end

% Smoothed robustness scoring using local volatility
alpha = 0.5;
robust_value = portfolio_value;
for i = 2:size(portfolio_value,1)-1
    for j = 2:size(portfolio_value,2)-1
        local = portfolio_value(i-1:i+1, j-1:j+1);
        local_std = std(local(:), 'omitnan');
        robust_value(i,j) = portfolio_value(i,j) - alpha * local_std;
    end
end

% Sort and find top 3 robust combinations
[sorted_vals, sorted_idx] = sort(robust_value(:), 'descend');
top3_idx = sorted_idx(1:3);
[rows, cols] = ind2sub(size(robust_value), top3_idx);
top3_q2 = q2_vals(cols);
top3_q3 = q3_vals(rows);
top3_vals = sorted_vals(1:3);

% Print top 3
fprintf('\n Top 3 Robust q2/q3 combos:\n');
for k = 1:3
    fprintf('#%d: q2 = %.4f, q3 = %.4f, Value = %.2f\n', ...
        k, top3_q2(k), top3_q3(k), top3_vals(k));
end

% Plot surface
[Q2, Q3] = meshgrid(q2_vals, q3_vals);
figure;
surf(Q2, Q3, portfolio_value, 'EdgeColor', 'none');
xlabel('q2 - Acceleration Weight');
ylabel('q3 - Volatility Weight');
zlabel('Portfolio Value');
title('Portfolio Value Surface over q2 and q3');
colormap('hot'); colorbar;
view(45, 30); shading interp;
hold on;

% Highlight Top 3 Points
scatter3(top3_q2, top3_q3, top3_vals, 100, 'cyan', 'filled');
for k = 1:3
    text(top3_q2(k), top3_q3(k), top3_vals(k), ...
        sprintf(' #%d (%.2f, %.2f)', k, top3_q2(k), top3_q3(k)), ...
        'Color', 'cyan', 'FontWeight', 'bold');
end
