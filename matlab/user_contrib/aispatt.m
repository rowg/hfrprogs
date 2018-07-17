%% About this script

% requirements: polargeo.m

% 2015-05-04 (cww) - Loads and processes LOOP files from AIS APm software.
%                   Divided into the following sections:
% 
%   1. Set Parameters (Need to define site info once)
%   2. Load Pattern File
%   3. Load Loop(s)
%   4. Reorganize Loop Data
%   5. Calculate complex valued antenna pattern from loop 
%   6. Turn loop file time string into date/time vector & matlab datenum
%   7. Loop Data Filtering *This is where the most adjusting is done!*
%   8. Statistics
%   9. Plotting (May need to tweak some plot window values, etc.)

clear

%% 1. Load Data

% Data file locations
% If no patt file to compare, just make pattfile string empty:
pattfile = '/Users/chad/Desktop/MONT_APM_Tests_20180507/Boat/PatternData/PATT_MONT_2018_05_09_1444_01d00sm.xlp/SEAS_MONT_2018_05_09_1444.patt';

loopfolder = '/Users/chad/Desktop/MONT_APM_Tests_20180507/AutoAPM_rev1/PatternData/Loops/';


% Load Pattern File
if (~isempty(pattfile)),
    patt = load(pattfile);
else
    patt = [];
end

% Load Loop(s)

% Load a single file
% loopfile = 'LOOP_FORT_2013_03_16_0000.loop';
% loop = load([loopfolder,loopfile]);

disp('Loading Loop Files...');

% Load & concatenate all loop file data
loop = [];
d = dir([loopfolder,'*.loop']);
for n = 1:length(d), loop = cat(1,loop,load([loopfolder,d(n).name]));end

%% 2. Set Parameters

% Choose Site
code = 'MONT';

% Set Parameters based on site

% % ************
% % *** MONT ***
% % ************
% %

% Site Info
ant1bearing = 298;
txfreq = 13.500000;

% Data & plot parameters
start = 170;
stop = 355;

%% 3
plotstart = 30*floor(start/30);
plotstop = 30*ceil(stop/30);
brngIncr = 1;
brngwidth = 5;
maxpatt = 2;

% Some Simple Calculations
braggwavelength = 300/(2*txfreq);
braggvel = sqrt(9.8*braggwavelength/(2*pi));  % Bragg Velocity (m/s)


%% 4. Reorganize Loop Data

if (start>stop),
    disp('Wrapping to 180...');
    loop(:,1) = wrapTo180(loop(:,1));
    start = wrapTo180(start);
    stop = wrapTo180(stop);
    plotstart = wrapTo180(plotstart);
    plotstop = wrapTo180(plotstop);
end

bearings = (start:brngIncr:stop)';

if (~isempty(patt)),
    patt(:,1) = ant1bearing + patt(:,1);
    % patt(:,1) = mod(patt(:,1),360);
    patt = sortrows(patt,1);
end

%% 5. Calculate complex valued antenna pattern from loop 
loopA13 = loop(:,2).*exp(1i*loop(:,3)*pi/180);
loopA23 = loop(:,4).*exp(1i*loop(:,5)*pi/180);

% Organize complex pattern as 4 real and imaginary components
loopRI = [real(loopA13) imag(loopA13) real(loopA23) imag(loopA23)];

%% 6. Turn loop file time string into date/time vector (cols 34:39) and MATLAB
%
loop(:,35:37) = [floor(loop(:,33)/10000) (mod(loop(:,33),10000)-mod(loop(:,33),100))/100 mod(loop(:,33),100)];
loop(:,38:40) = [floor(loop(:,34)/10000) (mod(loop(:,34),10000)-mod(loop(:,34),100))/100 mod(loop(:,34),100)];
loop(:,41) = datenum(loop(:,35:40));

%% 7. Loop Data Filtering

disp('Filtering Loop Data...');

% Filter values
minSNR = 11; % Minimum Signal-to-Noise Threshold
maxSNR = 40; % Maximum Signal-to-Noise Threshold
maxRangeWidth = 3;
minRangeWidth = 1;
minDoppWidth = 1;
maxDoppWidth = 20;
maxRange = 50; % Maximum Range to Vessel (km)
minRange = 3; % Minimum Range to Vessel (km)
maxcurrent = 1; % Maximum absolute current speed (m/s)
minVesselSpeed = .5;
maxVesselSpeed = 13;
minEchoes = 4;

% use subsampling?
dosubsample = 0; % logical: 1 = yes, 0 = no
numsamples = 200; % set lower than the size of the set

% Begin assembling filter string statement
filtStr = 'ind = find(';

% Require minSNR for Ch3 only
% filtStr = [filtStr,'loop(:,14)>minSNR'];

% Require minSNR for Ch3 & either Ch1 or Ch2
filtStr = [filtStr,'loop(:,14)>minSNR & (loop(:,12)>minSNR | loop(:,13)>minSNR)'];

% Require maxSNR for Ch3, Ch1 & Ch2
% filtStr = [filtStr,'& (loop(:,14)<maxSNR & loop(:,12)<maxSNR & loop(:,13)<maxSNR)'];

% Require minSNR for Ch3, Ch1 & Ch2
% filtStr = [filtStr,'loop(:,14)>minSNR & loop(:,12)>minSNR & loop(:,13)>minSNR'];

% Require min IIR SNR for all three channels
% filtStr = [filtStr,'loop(:,27)>minSNR & loop(:,28)>minSNR & loop(:,29)>minSNR'];

% Require min IIR SNR for Ch 3 & either Ch1 or Ch2
% filtStr = [filtStr,'loop(:,27)>minSNR & (loop(:,28)>minSNR | loop(:,29)>minSNR)'];

% Filter out solutions outside of bearing limits
% if (start < stop),
%     filtStr = [filtStr,' & loop(:,1)>=start & loop(:,1)<=stop'];
% else
%     filtStr = [filtStr,' & loop(:,1)>=start | loop(:,1)<=stop'];
% end

% Filter out solutions in an arbitrary section
% filtStr = [filtStr,' & ~(loop(:,1)<180 & real(loopA13)>.5)'];

% % Filter out solutions near DC
filtStr = [filtStr,' & abs(loop(:,9)) > minVesselSpeed'];
% 
% % Filter out solutions with high radial velocity
% filtStr = [filtStr,' & abs(loop(:,9)) < maxVesselSpeed'];
% 
% Filter out solutions past max range
% filtStr = [filtStr,' & abs(loop(:,8))/1000 < ', num2str(maxRange)];

% Filter out solutions closer than min range
% filtStr = [filtStr,' & abs(loop(:,8))/1000 > ', num2str(minRange)];

% Filter out solutions in a certain sector
% filtStr = [filtStr,' & ~(loop(:,8) > 27.5 & loop(:,1) > 93 | loop(:,1) < 300)'];

% Filter out solutions with peaks wide in range
filtStr = [filtStr,' & loop(:,25) - loop(:,24) <= maxRangeWidth'];

% Filter out solutions with peaks narrow in range
% filtStr = [filtStr,' & (loop(:,25) - loop(:,24) >= minRangeWidth)'];

% Filter out solutions with peaks wide in Doppler
filtStr = [filtStr,' & loop(:,27) - loop(:,26) <= maxDoppWidth'];
% filtStr = [filtStr,' & loop(:,26) - loop(:,25) <= maxDoppWidth'];

% Filter out solutions by date range
% filtStr = [filtStr,' & (loop(:,40) >= datenum(2015,10,19,0,0,0) & loop(:,40) <= datenum(2015,10,26,0,0,0))'];
% filtStr = [filtStr,' & loop(:,40) >= datenum(2014,10,16,0,0,0)'];

% Filter out solutions by hour of the day
% filtStr = [filtStr,' & loop(:,37) < 15'];
% filtStr = [filtStr,' & loop(:,38) < 8 | loop(:,38) > 20'];

% Filter out solutions near Bragg
filtStr = [filtStr,' & ~(abs(loop(:,9))>braggvel-maxcurrent & abs(loop(:,9))<braggvel+maxcurrent)'];

% Limit Solutions to Doppler between Bragg & DC
% filtStr = [filtStr,' & abs(loop(:,9))<braggvel-maxcurrent'];

% Limit Solutions to specific MMSI
% filtStr = [filtStr,' & loop(:,30)==351176000'];

% Close the filter string
filtStr = [filtStr,');'];

% Evaluate Filter String
eval(filtStr);

% test = find(loopRI(ind,4)<0 & loop(ind,1)>98 & loop(ind,1)<=110);

%% 8. Statistics

% trgtBrngsReduced = round(loop(:,1)/brngIncr)*brngIncr;

if (dosubsample && numsamples < length(ind)),
    sampind = randperm(length(ind),numsamples)';
else
    sampind = (1:length(ind))';
end

% Preallocate array memory
numPerBrng = zeros(size(bearings));
loopRImean = NaN*ones(length(bearings),4);
loopRImedian = NaN*ones(length(bearings),4);
loopRIwmean = NaN*ones(length(bearings),4);
loopRIstd = NaN*ones(length(bearings),4);

% Loop through bearings & antenna parameters(4)
for m = 1:length(bearings),
    
%     indb = find(trgtBrngsReduced(ind,1) == bearings(m));
    indb = find(loop(ind(sampind),1) > bearings(m)-brngwidth/2 & loop(ind(sampind),1) < bearings(m)+brngwidth/2); % Need to address wrap around North
    numPerBrng(m) = length(indb);
%     meanSNR(m) = mean(loop(ind(indb),27));
    if numPerBrng(m) > minEchoes,
        for n = 1:4,
            
            % Mean
            loopRImean(m,n) = mean(loopRI(ind(sampind(indb)),n));
            
            % Median
            loopRImedian(m,n) = median(loopRI(ind(sampind(indb)),n));
            
            % Weighted Mean (by power ratio - not dB)
            loopRIwmean(m,n) = sum(loopRI(ind(sampind(indb)),n).*10.^(loop(ind(sampind(indb)),14)/10))/sum(10.^(loop(ind(sampind(indb)),14)/10));
            
            % Standard Deviation
            loopRIstd(m,n) = std(loopRI(ind(sampind(indb)),n));
            
        end
    end
end




%% 9. Plotting
disp('Plotting.')
% plotcolors = ['r','y','b','g'];
labelfontsize = 14;
plotLabels = ['Real(A13)';'Imag(A13)';'Real(A23)';'Imag(A23)'];
plotTitles = ['a.';'b.';'c.';'d.'];

% figNameStr = [loopdatestr,', Min SNR ',num2str(minSNR)];
figNameStr = [code,', Min SNR ',num2str(minSNR)];

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 1. Real & Imaginary components
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure('Name',figNameStr)
clf

% Plot Real and Imaginary Antenna Patterns
for n = 1:4,
    subplot(2,2,n)
%     plot(loop(ind,1),loopRI(ind,n),[plotcolors(n),'.'])
    plot(loop(ind(sampind),1),loopRI(ind(sampind),n), 'r.', 'markersize', 8)
    hold on;
    grid
%     errorbar(bearings,loopRImean(:,n),loopRIstd,'ko','LineWidth',2)
%     errorbar(bearings,loopRImedian(:,n),loopRIstd(:,n),'bo')
    plot(bearings(1:1:length(bearings)),loopRImedian(1:1:length(loopRImedian),n),'bo','LineWidth',2)
%     plot(bearings,loopRIwmean(:,n),'go','LineWidth',2)
%     if(~isempty(patt)),plot(patt(:,1),patt(:,n+1),'k--','LineWidth',2);end
    if(~isempty(patt)),plot(patt(:,1),patt(:,n+1),'k+','MarkerSize',8);end
    xlim([plotstart plotstop]);
    ylim([-1 1]*3)
    set(gca,'XTick',plotstart:30:plotstop);

%     title(plotTitles(n,:))
    ylabel(plotLabels(n,:),'Fontsize', labelfontsize);
    xlabel('Bearing (deg True)','Fontsize', labelfontsize)
end



% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Polar plot of ant patt amplitude
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure

polamp1 = abs(loopRImedian(:,1)+1i*loopRImedian(:,2));
polamp2 = abs(loopRImedian(:,3)+1i*loopRImedian(:,4));

maxrho = max([polamp1;polamp2]);

polargeo(pi,maxrho);
hold on;

% Median
polargeo(bearings*pi/180,polamp1,'ro')
hold on;
polargeo(bearings*pi/180,polamp2,'bo')

% Weighted Mean
% polargeo(bearings*pi/180,abs(loopRIwmean(:,1)+1i*loopRIwmean(:,2)),'mx')
% polargeo(bearings*pi/180,abs(loopRIwmean(:,3)+1i*loopRIwmean(:,4)),'cx')

% Baseline pattern
if(~isempty(patt)),
    polargeo(patt(:,1)*pi/180,patt(:,7),'m--')
    polargeo(patt(:,1)*pi/180,patt(:,9),'c--')
end


% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Cartesian plot of ant patt phases
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure 

% Median
plot(bearings,angle(loopRImedian(:,1)+1i*loopRImedian(:,2))*180/pi,'ro')
hold on;
plot(bearings,angle(loopRImedian(:,3)+1i*loopRImedian(:,4))*180/pi,'bo')
xlim([plotstart plotstop]);
set(gca,'XTick',plotstart:30:plotstop);
ylim([-180 180])
set(gca,'YTick',-180:30:180);

% Weighted MEan
% plot(bearings,angle(loopRIwmean(:,1)+1i*loopRIwmean(:,2))*180/pi,'mx')
% plot(bearings,angle(loopRIwmean(:,3)+1i*loopRIwmean(:,4))*180/pi,'cx')

% Baseline pattern
if(~isempty(patt)),
    plot(patt(:,1),patt(:,8),'m--')
    plot(patt(:,1),patt(:,10),'c--')
end

% a = axis;
% a(1:2) = [plotstart plotstop];
% axis(a);
xlabel('Bearing (deg True)','Fontsize', labelfontsize)
ylabel('Phase (deg)','Fontsize', labelfontsize)

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Cartesian plot of ant patt amps
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure 

% Median
plot(bearings,abs(loopRImedian(:,1)+1i*loopRImedian(:,2)),'ro')
hold on;
plot(bearings,abs(loopRImedian(:,3)+1i*loopRImedian(:,4)),'bo')
set(gca,'XTick',plotstart:30:plotstop);

% Weighted MEan
% plot(bearings,abs(loopRIwmean(:,1)+1i*loopRIwmean(:,2))*180/pi,'mx')
% plot(bearings,abs(loopRIwmean(:,3)+1i*loopRIwmean(:,4))*180/pi,'cx')

% Baseline pattern
if(~isempty(patt)),
    plot((patt(:,1)),patt(:,7),'m--')
    plot((patt(:,1)),patt(:,9),'c--')
end

xlim([plotstart plotstop]);
xlabel('Bearing (deg True)','Fontsize', labelfontsize)
ylabel('Amplitude Ratio','Fontsize', labelfontsize)

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. Plot Metadata
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
clf

% Plot range vs. bearing
subplot(3,2,1)
plot(loop(ind(sampind),1),loop(ind(sampind),8)/1000,'r.', 'markersize', 8)
hold on;
% plot(loop(ind(sampind)(test),1),loop(ind(sampind)(test),8)/1000,'r.')
% xlabel('Bearing (deg True)','Fontsize', labelfontsize)
ylabel('Range (km)','Fontsize', labelfontsize)
% axis([plotstart plotstop 0 maxRange])
xlim([plotstart plotstop])
set(gca,'XTick',plotstart:30:plotstop);
title('a)');

% Plot rad vel. vs. bearing
subplot(3,2,2)
plot(loop(ind(sampind),1),loop(ind(sampind),9),'r.', 'markersize', 8)
hold on;
% plot(loop(ind(test),1),loop(ind(test),9),'b.')
% xlabel('Bearing (deg True)','Fontsize', labelfontsize)
ylabel('Radial Velocity (m/s)','Fontsize', labelfontsize)
plot([plotstart plotstop],braggvel*[1 1],'b-')
plot([plotstart plotstop],-braggvel*[1 1],'b-')
xlim([plotstart plotstop]);
ylim([-1 1]*maxVesselSpeed)
set(gca,'XTick',plotstart:30:plotstop);
title('b)');

% Plot # solutions vs. bearing
subplot(3,2,3)
bar(bearings,numPerBrng,'r')
hold on;
% a = axis;
% a(1:2) = [plotstart plotstop];
% axis(a);
% xlabel('Bearing (deg True)','Fontsize', labelfontsize)
ylabel('# of Sols','Fontsize', labelfontsize)
xlim([plotstart plotstop]);
set(gca,'XTick',plotstart:30:plotstop);
title('c)');

% Plot SNR vs. bearing
subplot(3,2,4)
plot(loop(ind(sampind),1),loop(ind(sampind),14),'r.', 'markersize', 8)
hold on;
% plot(loop(ind(test),1),loop(ind(test),14),'b.','LineWidth',2)
% a = axis;
% a(1:3) = [plotstart plotstop 0];
% axis(a);
% xlabel('Bearing (deg True)','Fontsize', labelfontsize)
ylabel('SNR (dB)','Fontsize', labelfontsize)
xlim([plotstart plotstop]);
set(gca,'XTick',plotstart:30:plotstop);
title('d)');

% plot the range width of the peak
subplot(3,2,5)
plot(loop(ind(sampind),1),loop(ind(sampind),25)-loop(ind(sampind),24),'r.', 'markersize', 8)
% plot(loop(ind(sampind),1),loop(ind(sampind),24)-loop(ind(sampind),23),'r.', 'markersize', 8)
hold on;
% plot(loop(ind(test),1),loop(ind(test),24)-loop(ind(test),23),'b.','LineWidth',2)
% a = axis;
% a(1:2) = [plotstart plotstop];
% axis(a);
xlabel('Bearing (deg True)','Fontsize', labelfontsize)
ylabel('Range Width','Fontsize', labelfontsize)
xlim([plotstart plotstop]);
set(gca,'XTick',plotstart:30:plotstop);
title('e)');

% plot the Doppler width of the peak
subplot(3,2,6)
plot(loop(ind(sampind),1),loop(ind(sampind),27)-loop(ind(sampind),26),'r.', 'markersize', 8)
% plot(loop(ind(sampind),1),loop(ind(sampind),26)-loop(ind(sampind),25),'r.', 'markersize', 8)
hold on;
% plot(loop(ind(test),1),loop(ind(test),26)-loop(ind(test),25),'b.','LineWidth',2)
% a = axis;
% a(1:2) = [plotstart plotstop];
% axis(a);
xlabel('Bearing (deg True)','Fontsize', labelfontsize)
ylabel('Doppler Width','Fontsize', labelfontsize)
xlim([plotstart plotstop]);
set(gca,'XTick',plotstart:30:plotstop);
title('f)');

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. Plot Vessel Positions
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure
polargeo(pi,60);
hold on;
polargeo(loop(ind(sampind),1)*pi/180, loop(ind(sampind),8)/1000, 'r.');

%% 10. Write Pattern File

filename = ['SEAS_' code datestr(max(loop(:,41)),'_yyyy_mm_dd_HHMM') '.patt'];
fileID = fopen(filename,'w');

fprintf(fileID,'%%CTF: 1.00\n');
fprintf(fileID,'%%%% SeaSonde Crossloop Antenna Pattern File\n');
fprintf(fileID,'%%FileType: PATT xlp4 "AntennaPattern"\n');
fprintf(fileID,'%%Owner: CODAR Ocean Sensors\n');
fprintf(fileID,['%%TimeStamp: ',datestr(max(loop(:,41)),'yyyy mm dd  HH MM SS'),'\n']);
fprintf(fileID,'%%Site: LISL ""\n');
% fprintf(fileID,'%%Origin:  ',36.6917167  -75.9226333,'\n');
fprintf(fileID,'%%UserComment: VesselEchoPattern\n');
fprintf(fileID,['%%AntennaBearing: ',sprintf('%3.1f',ant1bearing),' True ;;\n']);
fprintf(fileID,'%%ReferenceChannel: 3\n');
fprintf(fileID,'%%AngularResolution: 1.0 deg\n');
fprintf(fileID,'%%TableType: PATT MP01\n');
fprintf(fileID,'%%TableColumns: 5\n');
fprintf(fileID,'%%TableColumnTypes: BEAR A13R A13I A23R A23I\n');
fprintf(fileID,['%%TableRows: ',sprintf('%d',size(bearings,1)),'\n']);
fprintf(fileID,'%%TableStart:\n');
fprintf(fileID,'%%%% Bearing    A13        A13        A23        A23\n');
fprintf(fileID,'%%%%  DegCW     real       imag       real       imag\n');

for n = 1:size(bearings,1),
    fprintf(fileID,'  %03.1f  %1.7f  %1.7f  %1.7f  %1.7f\n',bearings(n)-ant1bearing,loopRImedian(n,1),loopRImedian(n,2),loopRImedian(n,3),loopRImedian(n,4));
end

fprintf(fileID,'%%TableEnd:\n');
fprintf(fileID,'%%%%\n');
fprintf(fileID,['%%ProcessedTimeStamp: ',datestr(now,'yyyy mm dd  HH MM SS'),'\n']);
fprintf(fileID,'%%ProcessingTool: "Chad''s MATLAB Script" 2.0\n');
fprintf(fileID,'%%End:\n');

fclose(fileID)

