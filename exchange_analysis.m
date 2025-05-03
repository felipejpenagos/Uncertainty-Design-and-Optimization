function [ cost , constraint ] = exchange_analysis(param, Plots)
% cost = exchange_analysis(param)
% analyze a policy for buying and selling stocks
%
% INPUT VARIABLES
% p(1)  = N       .... points in averaging
% p(2)  = q(1)    .... quality slope coeff
% p(3)  = q(2)    .... quality curvature coeff
% p(4)  = q(3)    .... quality volatility coeff
% p(5)  = fc      .... fraction of cash to invest (must be between 0 and 1)
% p(6)  = B       .... buy  threshold
% p(7)  = S       .... sell threshold

%W = ceil(param(8));  % WMA window size new <----------------------------------- new parameter -------------------------------------
                                                                 % It's another Weighted Moving Average to trade on general stock's
                                                                 % behavior

%
% OUTPUT VARIABLES
% cost            .... the negative of the value of cash and investments 
%                      after 200 days of trading.


%epsPlots = 0; if epsPlots, formatPlot(20,3,5); else formatPlot(0); end	

global  stock_prices

% Modified Block (Pairs Trading Logic) <----------------------------------------- new block: -------------------------------------
% Pairs trading setup (stock 6 and 11)
idx_a = 6;  % stock_6 
idx_b = 11; % stock_11

log_price_a = log(stock_prices(:, idx_a));
log_price_b = log(stock_prices(:, idx_b));
hedge_ratio = polyfit(log_price_b, log_price_a, 1); % this is just the slope of the regression
spread = log_price_a - hedge_ratio(1) * log_price_b - hedge_ratio(2); % eqtn. see jupyter notebook
spread_mean = mean(spread);
spread_std = std(spread);
zscore = (spread - spread_mean) / spread_std;
% <-------------------------------------------------------------------------------------------------------------------------------

N  = ceil(param(1));  % window length (days)
q  = param(2:4);		% stock quality parameters
fc = param(5);			% fraction of cash to invest
B  = param(6);			% buy  threshold on day 1
S  = param(7); 			% sell threshold on day 1
W = ceil(param(8));  % WMA window size <--------------------------------------------- new param ----------------------------------


if fc < 0
    disp (' exchange_analysis:  param(5), fc, must be greater than zero');
    return;
end
if fc > 1
    disp (' exchange_analysis:  param(5), fc, must be less than one');
    return;
end

weights = exp(-[1:N]*5/N);		% weight recent data more heaviliy
weights = weights / sum(weights);	% weights must add to 1

[days,stocks] = size(stock_prices); % number of trading days, number of stocks

% initialize matrices

smooth_price = stock_prices;
smooth_veloc = NaN(days,stocks);	
smooth_accel = NaN(days,stocks);	
volatility   = NaN(days,stocks);	

quality      = NaN(days,stocks);	% the quality of all stocks
B_record     = NaN(days,1);		    % record of buy-threshold
S_record     = NaN(days,1); 		% record of sell-threshold

shares_owned = zeros(days,stocks);	% the number of shares in each stock
value        = zeros(days,1);		% the value of the investments
cash         = zeros(days,1);		% the cash in hand

cash(1:N+1) = 1000.00;			% in your pocket on "day 1"

fraction_of_cash_to_invest = fc;	% amount of your cash to invest

buy_threshold  = B;
sell_threshold = S;

transaction_cost = 2.00;		% transaction cost ... $2.00

B_record(1:N) = B;
S_record(1:N) = S;

for  day = N+1:days-1			% loop over the trading days

     price  = stock_prices(day-1:-1:day-N,:);	% most recent "N" prices

     smooth_price(day,:) = weights*price;
     smooth_veloc(day,:) = ( smooth_price(day,:)-smooth_price(day-2,:) ) ./ ...
                           ( smooth_price(day,:)+smooth_price(day-2,:) );

     smooth_accel(day,:) = ( smooth_veloc(day,:)-smooth_veloc(day-2,:) ) / 2;

     volatility(day,:) = sqrt(var(price)) ./ smooth_price(day,:);

     % New Block (Weighted Moving Average) <----------------------------------------- new block WMA: -------------------------------
     % Compute WMA for each stock using weights over W days
     wma_weights = linspace(1, 2, W);  % increasing weights
     wma_weights = wma_weights / sum(wma_weights);
    
     for s = 1:stocks
         if day >= W
             wma(day,s) = sum(stock_prices(day-W+1:day,s) .* wma_weights');
         else
             wma(day,s) = stock_prices(day,s);  % fallback for early days
         end
     end
     % <---------------------------------------------------------------------------------------------------------------------------
     stocks_owned = find( shares_owned(day,:) > 0 );	% stocks owned today

     value(day) = sum ( stock_prices( day, stocks_owned ) .* ...
                        shares_owned( day, stocks_owned ) );

     %%% New Block (Drawdown, Risk Management) –––––––––––––------------------------- new block (dradown %): ----------------------
     % Added to visualize porfolio drawdown as a function of time.
     % Total portfolio value = cash + investment value
 
     total_value = value + cash;
    
     % Initialize rolling 3-day drawdown
     % this (3-day period) is to deal with unsmoothed peaks caused by transaction days
     drawdown = zeros(size(total_value));  % same size as total_value
     window = 3;
    
     for t = window:length(total_value)
         local_peak = max(total_value(t-window+1:t));  % peak over last 3 days
         drawdown(t) = (local_peak - total_value(t)) / local_peak;
     end
    
     % Fill the first few days with 0 (or NaN, if preferred)
     drawdown(1:window-1) = 0;
    
    %%%% –––––----------------------------------------------------------------------------------------------------------------------

     % RISK MANAGEMENT: Check for prolonged portfolio drawdown --------------------- new block:  ------------------------------------
     % --- RISK MANAGEMENT: Trigger liquidation if drawdown > 25% for 3 consecutive days after day 48 
     if day >= 52  % day 52 lets us safely access drawdown(day-3:day)
         if all(drawdown(day-3:day) > 0.25) && day > 48
             fprintf('Day %d: Drawdown > 25%% for 4 consecutive days. Triggering liquidation.\n', day);
    
             % Liquidate all current holdings
             owned_now = find(shares_owned(day,:) > 0);
             cash(day) = cash(day) + sum(stock_prices(day, owned_now) .* shares_owned(day, owned_now));
             cash(day) = cash(day) - transaction_cost * length(owned_now);
             shares_owned(day, owned_now) = 0;
    
            % Optional: tighten thresholds for safer re-entry
             B = 0.01;
             S = -0.01;
         end
     end

   %%%% –––––----------------------------------------------------------------------------------------------------------------------


% *** You may change the following definition of "quality"

     quality(day,:)  = q(1)*smooth_veloc(day,:) + ...
                       q(2)*smooth_accel(day,:) + ...
                       q(3)*volatility(day,:); 

% ----- trading decisions ... sell the bad, buy the good  

%    Find stocks that are potentially sellable and potentially buyable 
     stocks_to_sell = find( quality(day,:) < S );
     stocks_to_buy  = find( quality(day,:) > B );


     % Block WMA crossover strategy <------------------------------------------------- new block: -----------------------------------
     % we defined wma above, no we add it here to trade on it.
     price_today = stock_prices(day,:); 
    
    % Only sell if price is below WMA
     stocks_to_sell = intersect(stocks_to_sell, find(price_today < wma(day,:)));
    
    % Only buy if price is above WMA 
     stocks_to_buy = intersect(stocks_to_buy, find(price_today > wma(day,:))); 
     %<------------------------------------------------------------------------------------------------------------------------------–
     
    % Block Pairs trading signal logic  <-------------------------------------------- new block: -------------------------------------
    % we defined pairs trading relevant statistics (stocks 11 annd 6) above now we trade on it.

     z = zscore(day);
     z_entry_threshold = -1.3;
     z_exit_threshold = -0.25;
    
     if z < z_entry_threshold
         if shares_owned(day, idx_a) == 0 && price_today(idx_a) > wma(day, idx_a)
             fprintf('Day %d: BUY signal (pairs logic) for stock %d due to z = %.2f\n', day, idx_a, z);
             stocks_to_buy = union(stocks_to_buy, idx_a);
         end
         if shares_owned(day, idx_b) == 0 && price_today(idx_b) > wma(day, idx_b)
             fprintf('Day %d: BUY signal (pairs logic) for stock %d due to z = %.2f\n', day, idx_b, z);
             stocks_to_buy = union(stocks_to_buy, idx_b);
         end
     end
    
     if z > z_exit_threshold
         if shares_owned(day, idx_a) > 0
             fprintf('Day %d: SELL signal (pairs logic) for stock %d due to z = %.2f\n', day, idx_a, z);
             stocks_to_sell = union(stocks_to_sell, idx_a);
         end
         if shares_owned(day, idx_b) > 0
             fprintf('Day %d: SELL signal (pairs logic) for stock %d due to z = %.2f\n', day, idx_b, z);
             stocks_to_sell = union(stocks_to_sell, idx_b);
         end
     end
    % <--------------------------------------------------------------------------------------------------------------------------------

%    Don't sell what you don't own.   (no shorting)
     so = zeros(1,stocks); sts = zeros(1,stocks);  
     so(stocks_owned) = 1; sts(stocks_to_sell) = 1;
     stocks_to_sell = find(so & sts);

%    Don't sell if you are not going to buy.  (You may ignore this rule.)
     if length(stocks_to_buy) == 0		% If there are no stocks to buy
  	stocks_to_sell = [];			% then don't sell any. 
     end
     
     if length(stocks_to_sell) > 0		% there are stocks to sell
	cash(day) = cash(day) + sum ( stock_prices(day,stocks_to_sell) .* ...
                     shares_owned(day,stocks_to_sell) );
	cash(day) = cash(day) - transaction_cost * length( stocks_to_sell );
	shares_owned( day, stocks_to_sell ) = 0;	% stocks are sold
     end

     shares_to_buy = zeros(1,stocks);
     if length(stocks_to_buy) > 0 && cash(day) > 0  % there are stocks to buy

	cash(day) = cash(day) - transaction_cost * length( stocks_to_buy );

	if cash(day) < 0 && value(day) < 0
		fprintf('you lose.\n');
	end

	% amount of cash available to invest ...
	cash_to_invest = cash(day) * fraction_of_cash_to_invest;

        % *** You may change how cash is distributed among stocks to buy
	% distribute all cash equally among all stocks to buy
  	shares_to_buy(stocks_to_buy) = ( cash_to_invest / ...
              length(stocks_to_buy) ) ./ stock_prices(day,stocks_to_buy);

	cash(day) = cash(day) - cash_to_invest;

     end

     shares_owned( day+1,:) = shares_owned(day,:) + shares_to_buy;

     % cash is in some very safe investment ... 4% growth per year
     cash(day+1) = cash(day) * (1 + 0.04/365);

% *** You may change the threshold update on the following four lines ...

    % set B to the max quality of all owned stocks
    bb = max( quality( day, find( shares_owned(day+1,:)>0 )));
    if sum(shares_owned(day+1,:))==0, bb = B; end
  
    % set S to the min quality of all owned stocks
    ss = min( quality( day, find( shares_owned(day+1,:)>0 )));
    if sum(shares_owned(day+1,:))==0, ss = S; end

    if length(bb) > 0, B = bb; end
    if length(ss) > 0, S = ss; end

% *** You may change the following line, as long as S < B
    S = min(B-0.01*abs(B),S); % sell threshold must be less than the buy threshold

    B_record(day) =  B;
    S_record(day) =  S;

end

stocks_owned = find( shares_owned(days,:) > 0 );
value(days)  = sum ( stock_prices( days, stocks_owned ) .* ...
                     shares_owned( days, stocks_owned ) );


% minimize the negative of the value (the same as maximizing value)
cost = -value(days) - cash(days);   
constraint = -1;


if Plots	% ----- plotting

 stp = [ 1 3 12 16 ];	% Stocks To Plot ... 1 to 19
 param = param(:);

 day0 = 1;

 time = [1:days];

 figure(1)
% clf
  subplot(511)
   plot(time+day0, stock_prices(time,stp), '-b', ...
        time+day0, smooth_price(time,stp), '-r');
    ylabel('price')
    legend(num2str(stp))
    axis('tight')
  subplot(512)
   plot(time+day0, smooth_veloc(:,stp), '-r');
    ylabel('% change')
    axis('tight')
  subplot(513)
   plot(time+day0, smooth_accel(:,stp), '-r');
    ylabel('change of % change')
    axis('tight')
  subplot(514)
   plot(time+day0, volatility(:,stp), '-r');
    ylabel('volatility')
    axis('tight')
  subplot(515)
   plot(time+day0, B_record,'--k', time+day0,S_record,'--k', time+day0,quality(:,stp) )
    ylabel('quality')
    axis('tight')
  %if epsPlots, print('exchange_analysis_1.eps','-color','-solid','-F:20'); end
 
 figure(2)
  clf
  subplot(211)
   plot( time+day0,shares_owned.*stock_prices,'-');
   hold on
   plot( time+day0,value,'-b','LineWidth',6)
   plot( time+day0,cash, '-g','LineWidth',6)
   legend('investments','cash')
%  ttl = ['p=[ ' num2str(param') ' ]'];
%  title(ttl)
    axis('tight')
    ylabel('value')
   title(num2str(param'))
  subplot(212)
   plot(time+day0,shares_owned,'-')
    axis('tight')
    ylabel('shares owned')
    maxSharesOwned = max(max(shares_owned))
    [d,s] = find( shares_owned(2:days,:) > 2.0*round(shares_owned(1:days-1,:)) );
    for k=1:length(d)
	text(d(k),shares_owned(d(k)+1,s(k)),num2str(s(k)))
    end
  %if epsPlots, print('exchange_analysis_2.eps','-color','-solid','-F:20'); end

 figure(3)
   clf
   plot( time+day0,B_record, time+day0,S_record )
    axis('tight')
    ylabel('threshold values')
    legend('buy threshold','sell threshold')
  %if epsPlots, print('exchange_analysis_3.eps','-color','-solid','-F:20'); end

  % - Drawdown plot ------------------------------------------------------------------------- new block: ------------------------
  %%%% Added figure to visualise the drawdown (portoflio % value compromised) of our portoflio as a function of time
  figure(4)
    clf
    plot(time+day0, drawdown * 100, '-r', 'LineWidth', 2)
        xlabel('Day')
        ylabel('Drawdown (%)')
        title('Portfolio Drawdown (3-day-smoothed) Over Time')
        grid on
        axis tight
  % ------------------------ ------------------------ ------------------------ ------------------------ ------------------------ 

end		% ----- plotting
 
% exchange_analysis ------------------------------------------ 4 Apr 2011, 23 Mar 2015
