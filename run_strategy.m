% run_strategy.m
clear; clc;
global stock_prices
stock_prices = csvread('stock_prices1.csv');  % Load prices

% Optimal parameters (replace with your final values)
% [N, q1, q2, q3, fc, B, S, WMA] where wma is added parameter for crossover
% strat.

param = [27.0235; -0.6170; -0.3793; 0.3103; 0.7015; 0.0418; -0.0086; 4.6282];


% Call exchange_analysis
[cost, ~] = exchange_analysis(param, 1);
fprintf('Final Portfolio Value: %.2f\n', -cost);
