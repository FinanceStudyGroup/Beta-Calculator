function B = Beta (y,x,yname,xname,interval,frequency,color)

% MATLAB Beta Calculator: A simple calculator for determining price
% sensitivity of financial assets. Data to be sourced from Excel.

% y and x are both (date,price) arrays collected from Excel. They may be of
% different length, or involve missing data. They are being merged according
% to the dates they have in common.

% Hardcode setting for the number of acceptable standard deviations
sigma = 100;

% Hardcode setting for the symbol of the scatter plot
symbol = 'o';

% Convert Excel-formatted dates to MATLAB format
y(:,1) = x2mdate(y(:,1),0);
x(:,1) = x2mdate(x(:,1),0);

% Sort y and x
y = sortrows(y,1);
x = sortrows(x,1);

% Definition of Default Settings ------------------------------------------
% Nargin is a function that counts the number of input arguments.
% It can be used to set default settings for functions.

if nargin==4
  %Default interval is 500 years (Basically all available data)
  interval = 500;
  %Default Returns Frequency
  frequency = 'd';
  %Default Color (Signature color = [0.4 0 1];)
  color = [31/255 73/255 125/255];
elseif nargin==5
  %Default Returns Frequency
  frequency = 'd';
  %Default Color
  color = [31/255 73/255 125/255];
elseif nargin==6
  %Default Color
  color = [31/255 73/255 125/255];
end

% Price Matrix ------------------------------------------------------------
% Convert arrays to tables
y = array2table(y,'VariableNames',{'Date','Price'});
x = array2table(x,'VariableNames',{'Date','Price'});

% Define pmatrix as the innerjoin intersection of x and y
pmatrix = innerjoin(x, y, 'Keys', 1);

% Restate pmatrix as a regular matrix
pmatrix = table2array(pmatrix);

% Restate pmatrix according to start date
since = pmatrix(end,1)-(365*interval);
dates = find(pmatrix(:,1)>=since);
pmatrix = pmatrix(dates(), :);
pmatrix = sortrows(pmatrix,1);
% -------------------------------------------------------------------------
% Here frequency settings can be defined
if frequency=='d'
  %If daily, do not modify pmatrix. Daily returns calculation is implied.
  frequency = 'Daily';
  pmatrix = sortrows(pmatrix,1);
elseif frequency=='w'
  %If weekly, these are the modifications to pmatrix.
  frequency = 'Weekly';
  pmatrix = sortrows(pmatrix,1);
  %Add a vector to pmatrix describing the week of each date.
  pmatrix(:,4) = weeknum(pmatrix(:,1));
  %Find the last instances of each week
  diffweeks = find(diff(pmatrix(:,4)));
  %Restate pmatrix with only information from the end-of-week dates
  pmatrix = pmatrix(diffweeks(), :);
  pmatrix = sortrows(pmatrix,1);
elseif frequency=='m'
  %If monthly, these are the modifications to pmatrix.
  frequency = 'Monthly';
  pmatrix = sortrows(pmatrix,1);
  %Add a vector to pmatrix describing the month of each date.
  pmatrix(:,4) = str2num(datestr(pmatrix(:,1),5));
  %Find the last instances of each month
  diffmonths = find(diff(pmatrix(:,4)));
  %Restate pmatrix with only information from the end-of-month dates
  pmatrix = pmatrix(diffmonths(), :);
  pmatrix = sortrows(pmatrix,1);
end

% Rfrequency is the variable for displaying returns frequency
% It can be 'Daily', 'Weekly', or 'Monthly'
rfrequency = sprintf('%s %s',frequency,'Returns on');

% -------------------------------------------------------------------------
% Returns Calculation
% Extract the index price and determine index returns
x = pmatrix(:, 2);
xlength = length(x)-1;
x = (x(2:end)./x(1:end-1))-ones(length(xlength),1);

% Extract the stock price and determine stock returns
y = pmatrix(:, 3);
ylength = length(y)-1;
y = (y(2:end)./y(1:end-1))-ones(length(ylength),1);

% Returns Matrix ----------------------------------------------------------
rmatrix = nan(length(y), 3);
rmatrix(:, 1) = pmatrix(2:end, 1);
rmatrix(:, 2) = x;
rmatrix(:, 3) = y;
% Standard Deviations
xsigma = sigma*std(rmatrix(:,2));
ysigma = sigma*std(rmatrix(:,3));
% Medians
xmedian = median(rmatrix(:,2));
ymedian = median(rmatrix(:,3));
% Maxima and minima
xmax = xmedian+xsigma;
xmin = xmedian-xsigma;
ymax = ymedian+ysigma;
ymin = ymedian-ysigma;
% Restate rmatrix according to permitted standard deviations
dates = find(rmatrix(:,2)<=xmax);
rmatrix = rmatrix(dates(), :);
dates = find(rmatrix(:,2)>=xmin);
rmatrix = rmatrix(dates(), :);
dates = find(rmatrix(:,3)<=ymax);
rmatrix = rmatrix(dates(), :);
dates = find(rmatrix(:,3)>=ymin);
rmatrix = rmatrix(dates(), :);
rmatrix = sortrows(rmatrix,1);

%Extract x- and y-valued returns
x = rmatrix(:, 2);
y = rmatrix(:, 3);

% Observations and time interval ------------------------------------------
% Observations
obs = length(y);

% Interval and unit
interval = (pmatrix(end,1)-pmatrix(1,1));
if interval > 300
    interval = interval/356;
    unit = '-Year';
elseif interval <= 300
    interval = interval/30;
    unit = '-Month';
end
interval = round(interval,0);

% Start Date --------------------------------------------------------------
% Returns occur, beginning at the date of the second subsetted price.

% Return = (P.2/P.1)/P.1, so for any price series, the returns series
% begins at the date of the second price.

% Start Date
startdate = pmatrix(2,1);
% Start Month
month = datestr(startdate,3);
% Start Year
year = datestr(startdate,10);
% Start Date output
start = sprintf('%s%s %s%s %s%s','(','Since',month,'.',year,')');
% -------------------------------------------------------------------------

% Main Plot and Attributes
ax2=subplot(10,10,[2,90]);
plot(x,y,symbol,'MarkerEdgeColor',color,'MarkerFaceColor',color);
%title(sprintf('%s %s','Beta Calculation:',yname),'FontSize',12,'FontWeight','bold')
title(sprintf('%s %s %s%s%s%s %s%s%s %s','Beta Calculation:',yname,'(',num2str(interval),unit,',',frequency,') (',num2str(obs),'Obs.)'),'FontSize',10,'FontWeight','bold')
grid on
set(gca,'XTickLabel',[])
set(gca,'YTickLabel',[])
p = polyfit(x,y,1);
X = [ones(length(x),1) x];
b = X\y;
yCalc2 = X*b;
hold on
plot(x,yCalc2,'-b')
lsline
Rsq2 = 1 - sum((y - yCalc2).^2)/sum((y - mean(y)).^2);
a1str = num2str(p(1));
a0str = num2str(p(2));
%betaL = ['Beta_{L} = ',num2str(p(1)),''];
betaL = ['Beta = ',num2str(p(1)),''];
rsqstr = ['R^2 = ', num2str(Rsq2),''];
eqnstr = ['y = ', a1str, 'x + ', a0str, ''];
dim = [.555 .6 .3 .3];
annotation('textbox',dim,'String',{betaL,rsqstr,eqnstr},'BackgroundColor','white','FitBoxToText','on');

% y-Histogram and Attributes
ax1=subplot(10,10,[1,81]);
histogram(y,'Normalization','probability','Orientation','horizontal','FaceColor',color,'BinWidth', 0.005)
yname = sprintf('%s %s %s',rfrequency,yname,start);
ylabel(yname,'FontSize',10)
set(gca, 'XTick', []);
yt = get(gca, 'ytick');
%yt100 = yt*100;
yt100 = round(yt*100,0);
ytstr = num2str(yt100');
ytcell = cellstr(ytstr);
ytcell_trim = strtrim(ytcell);
ytpercent = strcat(ytcell_trim, '%');
set(gca, 'yticklabel', ytpercent);
linkaxes([ax1,ax2],'y');

% x-Histogram and Attributes
ax3=subplot(10,10,[92,100]);
histogram(x,'Normalization','probability','FaceColor',color,'BinWidth', 0.005)
xname = sprintf('%s %s %s',rfrequency,xname,start);
xlabel(xname,'FontSize',10)
set(gca, 'YTick', []);
xt = get(gca, 'xtick');
%xt100 = xt*100;
xt100 = round(xt*100,0);
xtstr = num2str(xt100');
xtcell = cellstr(xtstr);
xtcell_trim = strtrim(xtcell);
xtpercent = strcat(xtcell_trim, '%');
set(gca, 'xticklabel', xtpercent);
linkaxes([ax3,ax2],'x');

% Assign beta to a variable
% This allows you to import the exact variable into Excel
B = p(1);
