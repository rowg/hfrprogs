function [] = aispatt()
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
%
% 2018-07-17 (tgu) Modifications to put notes in the files, add header info,
%                  exclude NaNs from the output patt file, distribute figures
%                  on the display, print images, see "TGU" comments below
% 2018-08-08 (tgu) Created a separate function applyfilters and simplified
%                  method of indicating which filters/thresholds to use
%                  Added amplitude filters
%                  Added option to use different filter sets on different
%                  bearing sections
%
% NOTES: The filtering is based on column numbers not column header names.
% Doublecheck that these numbers are correct for your version of the loop
% file.  It works for %TableType: LOOP LP05 but other versions require
% checking.
%
% Before running aispatt.m sections, you will need to do the following:
%
%    edit the reference .patt filename and the LOOP folder name in section 1
%    edit the site info (code, ant1bearing and frequency) in section 2
%    edit filters and thresholds in section 7

clear

%% 1. Load Data

% Data file locations
% If no patt file to compare, just make pattfile string empty:
pattfile = '/Users/teresa/Desktop/Codar_Files/Pattern_Measurements/LISL/2018_02_23_LISL_APM/PATT_LISL_2018_02_26_1932_r01_s05.xlp/SEAS_LISL_2018_02_26_1932.patt';
loopfolder = '/Users/teresa/Desktop/Codar_Files/Pattern_Measurements/LISL/Loops_IOOS/';

% Load Pattern File
if (~isempty(pattfile))
    patt = load(pattfile);
else
    patt = [];
end

% Load Loop(s)

% Load a single file
% loopfile = 'LOOP_FORT_2013_03_16_0000.loop';
% loop = load([loopfolder,loopfile]);

disp('Loading Loop Files...');
tic
% Load & concatenate all loop file data
loop = [];
d = dir([loopfolder,'*.loop']);
for n = 1:length(d), loop = cat(1,loop,load([loopfolder,d(n).name]));end
toc

%% 2. Set Parameters

% Choose Site
code = 'LISL';

% Set Parameters based on site

% Site Info
lat = 36.69172;
lon = -75.92263;
ant1bearing = 130;
txfreq = 4.537183;

% Data & plot parameters
% NOT filtering on these for .patt
datastart = 352;
datastop = 149;
printplots = 1;  % TGU set to 1 to save figures as PNG images, otherwise 0


%% 3
plotstart = 30*floor(datastart/30);
plotstop = 30*ceil(datastop/30);
brngIncr = 1;
brngwidth = 5;
maxpatt = 2;

% Some Simple Calculations
braggwavelength = 300/(2*txfreq);
braggvel = sqrt(9.8*braggwavelength/(2*pi));  % Bragg Velocity (m/s)


%% 4. Reorganize Loop Data

if (datastart>datastop)
    disp('Wrapping to 180...');
    loop(:,1) = wrapTo180(loop(:,1));
    datastart = wrapTo180(datastart);
    datastop = wrapTo180(datastop);
    plotstart = wrapTo180(plotstart);
    plotstop = wrapTo180(plotstop);
end

bearings = (datastart:brngIncr:datastop)';

if (~isempty(patt))
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

ds = min(loop(:,41));
de = max(loop(:,41));

%pattfolder = sprintf('PATT_%s_%s_%s/',code, datestr(min(loop(:,41)),'yyyymmdd'),datestr(max(loop(:,41)),'yyyymmdd'));
pattfolder = sprintf('PATT_%s_%s_%s_P%s/',code, datestr(min(loop(:,41)),'yyyymmdd'),datestr(max(loop(:,41)),'yyyymmdd'),datestr(now,'yyyymmddHHMM'));
eval(sprintf('mkdir %s%s',loopfolder,pattfolder(1:end-1)))  % TGU create directory to save .patt file and images


%% 7. Loop Data Filtering

disp('Filtering Loop Data...');

minEchoes = 4;  % this is always used after other filters are applied

% use subsampling?
dosubsample = 0; % logical: 1 = yes, 0 = no
numsamples = 200; % set lower than the size of the set

% Which tests? Set =1 to perform filter test, =0 to ignore test

filters = struct();
thresholds = struct();

thresholds.minSNR = 15; % Minimum Signal-to-Noise Threshold
filters.minSNR = 'monopole_and_1loop';   % minSNR can be 'none', 'monopole', 'monopole_and_1loop' or 'all'
filters.minIIR = 'monopole_and_1loop';   % minIIR can be 'none', 'monopole', 'monopole_and_1loop' or 'all'

filters.maxSNR        = 1;   thresholds.maxSNR = 40; % Maximum Signal-to-Noise Threshold
filters.bear          = 1;   thresholds.start = 30; thresholds.stop = 120;
filters.maxrange      = 1;   thresholds.maxRange = 70; % Maximum Range to Vessel (km)
filters.minrange      = 0;   thresholds.minRange = 10; % Minimum Range to Vessel (km)
filters.widerange     = 1;   thresholds.maxRangeWidth = 10;
filters.narrowrange   = 0;   thresholds.minRangeWidth = 1;
filters.wideDoppler   = 1;   thresholds.maxDoppWidth = 120;
filters.narrowDoppler = 0;   thresholds.minDoppWidth = 1;
filters.highvel       = 0;   thresholds.maxVesselSpeed = 13;
filters.lowvel        = 0;   thresholds.minVesselSpeed = .5;
filters.nearBragg     = 1;   thresholds.braggvel = braggvel; thresholds.maxcurrent = 1; % Maximum absolute current speed (m/s)
filters.outsideBraggDC= 0;   %uses same thresholds.braggvel and thresholds.maxcurrent defined above
filters.hourofday     = 0;   thresholds.hstart = 13; thresholds.hstop = 20;
filters.daterange     = 0;   thresholds.cds = datenum(2015,10,19,0,0,0); thresholds.cde = datenum(2015,10,26,0,0,0);
filters.mmsi          = 0;   thresholds.mmsi = 351176000;
filters.realL1        = 0;   thresholds.max_rA13 = 1; thresholds.min_rA13 = -1; 
filters.imagL1        = 0;   thresholds.max_iA13 = 1; thresholds.min_iA13 = -1;  
filters.realL2        = 0;   thresholds.max_rA23 = 1; thresholds.min_rA23 = -1;                        
filters.imagL2        = 0;   thresholds.max_iA23 = 2; thresholds.min_iA23 = -0.9;

multipleFilters = 0;  % TO RUN DIFFERENT FILTERS FOR DIFFERENT BEARINGS SET THIS =1 AND SEE THE OPTIONAL SECTION BELOW

thresholds.start180 = wrapTo180(thresholds.start);  thresholds.stop180 = wrapTo180(thresholds.stop);
notestart = sprintf('%s_to_%s;',datestr(ds,'yyyy-mm-dd'), datestr(de,'yyyy-mm-dd'));

[filtStr,notes] = applyfilters(filters, thresholds, notestart);
filtStr = strrep(filtStr,'#',num2str(1));

% Evaluate Filter String
eval(filtStr);  % this returns a variable called I{1} 
ind = I{1};

%---------------------------------------------------------------
% OPTIONAL
% Run other sets of filters for particular bearings (to work as intended, sets have to be mutually
% exclusive from each other and not overlap with the bearings for the first filter applied above)
% For example, make the minSNR less restrictive to keep more data for an area that does not have many detections

if multipleFilters
    nsets = 2;  % how many extra sets
    bearingvalues = { [352,29]; [121,143] };  % for each extra set, supply a start and stop bearing
    minsnrvalues = [15, 12];    
    %xvalues = [ , ] % e.g. for any other threshold variables you want to differ from above, adapt the code and notes below as appropriate
    
    for ss = 1:nsets
        thresholds.minSNR = minsnrvalues(ss);  % define a less restrictive minimum SNR
        %thresholds.x = xvalues(ss);  % e.g. for other thresholds besides minSNR that you wanted to change
        
        % define the bearing limits where less restrictive filtering should apply
        thresholds.start = bearingvalues{ss}(1);
        thresholds.stop = bearingvalues{ss}(2);
        thresholds.start180 = wrapTo180(thresholds.start);  thresholds.stop180 = wrapTo180(thresholds.stop);
        if (thresholds.start180 < thresholds.stop180)
            notes = [notes, sprintf('bearing>=%03d_and_bearing<=%03d_allows_SNR>%2d;',thresholds.start,thresholds.stop,thresholds.minSNR)];
        else
            notes = [notes, sprintf('bearing>=%03d_or_bearing<=%03d_allows_SNR>%2d;',thresholds.start,thresholds.stop,thresholds.minSNR)];
        end
        
        [filtStr,~] = applyfilters(filters, thresholds, notestart);
        filtStr = strrep(filtStr,'#',num2str(ss+1));
        eval(filtStr);  % this returns a variable called I{2} I{3}, etc depending on number of set
        ind = union(ind,I{ss+1});
    end
end
%---------------------------------------------------------------

notes = [notes, sprintf('min_%d_echoes_at_bearing',minEchoes)]



%% 8. Statistics

% trgtBrngsReduced = round(loop(:,1)/brngIncr)*brngIncr;

if (dosubsample && numsamples < length(ind))
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
for m = 1:length(bearings)
    
    %     indb = find(trgtBrngsReduced(ind,1) == bearings(m));
    indb = find(loop(ind(sampind),1) > bearings(m)-brngwidth/2 & loop(ind(sampind),1) < bearings(m)+brngwidth/2); % Need to address wrap around North
    numPerBrng(m) = length(indb);
    %     meanSNR(m) = mean(loop(ind(indb),27));
    if numPerBrng(m) > minEchoes
        for n = 1:4
            
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

notnan = find(~isnan(loopRImedian(:,1))); %TGU added to adjust table row count for written file
bcount = length(notnan); %TGU added


%% 9. Plotting

disp('Plotting.')
% plotcolors = ['r','y','b','g'];
labelfontsize = 14;
plotLabels = ['Real(A13)';'Imag(A13)';'Real(A23)';'Imag(A23)'];
plotTitles = ['a.';'b.';'c.';'d.'];

% figNameStr = [loopdatestr,', Min SNR ',num2str(thresholds.minSNR)];
if multipleFilters
    figNameStr = [code,', Min SNR Multiple Values'];
else
    figNameStr = [code,', Min SNR ',num2str(thresholds.minSNR)];
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Figure 1. Real & Imaginary components
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
fw = 560; fh = 420;
figure('Name',figNameStr,'Position',[100,100,fw,fh])
clf

% Plot Real and Imaginary Antenna Patterns
for n = 1:4
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
    %set(gca,'XTick',plotstart:30:plotstop);
    
    %     title(plotTitles(n,:))
    ylabel(plotLabels(n,:),'Fontsize', labelfontsize);
    xlabel('Bearing (deg True)','Fontsize', labelfontsize)
end

if printplots
    eval(sprintf('print -dpng %s%sPATT_%s_%s_%s_RealImag.png',loopfolder,pattfolder, code, datestr(min(loop(:,41)),'yyyymmdd'),datestr(max(loop(:,41)),'yyyymmdd') ) )
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 2. Polar plot of ant patt amplitude
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Position',[100+fw,100,fw,fh])

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
if(~isempty(patt))
    polargeo(patt(:,1)*pi/180,patt(:,7),'m--')
    polargeo(patt(:,1)*pi/180,patt(:,9),'c--')
end
if printplots
    eval(sprintf('print -dpng %s%sPATT_%s_%s_%s_AmpPolar.png',loopfolder,pattfolder, code, datestr(min(loop(:,41)),'yyyymmdd'),datestr(max(loop(:,41)),'yyyymmdd') ) )
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 3. Cartesian plot of ant patt phases
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Position',[100+2*fw,100,fw,fh])

% Median
plot(bearings,angle(loopRImedian(:,1)+1i*loopRImedian(:,2))*180/pi,'ro')
hold on;
plot(bearings,angle(loopRImedian(:,3)+1i*loopRImedian(:,4))*180/pi,'bo')
xlim([plotstart plotstop]);
%set(gca,'XTick',plotstart:30:plotstop);
ylim([-180 180])
set(gca,'YTick',-180:30:180);

% Weighted MEan
% plot(bearings,angle(loopRIwmean(:,1)+1i*loopRIwmean(:,2))*180/pi,'mx')
% plot(bearings,angle(loopRIwmean(:,3)+1i*loopRIwmean(:,4))*180/pi,'cx')

% Baseline pattern
if(~isempty(patt))
    plot(patt(:,1),patt(:,8),'m--')
    plot(patt(:,1),patt(:,10),'c--')
end

% a = axis;
% a(1:2) = [plotstart plotstop];
% axis(a);
xlabel('Bearing (deg True)','Fontsize', labelfontsize)
ylabel('Phase (deg)','Fontsize', labelfontsize)
if printplots
    eval(sprintf('print -dpng %s%sPATT_%s_%s_%s_Phase.png',loopfolder, pattfolder,code, datestr(min(loop(:,41)),'yyyymmdd'),datestr(max(loop(:,41)),'yyyymmdd') ) )
end
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 4. Cartesian plot of ant patt amps
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Position',[100,100+fh+75,fw,fh])

% Median
plot(bearings,abs(loopRImedian(:,1)+1i*loopRImedian(:,2)),'ro')
hold on;
plot(bearings,abs(loopRImedian(:,3)+1i*loopRImedian(:,4)),'bo')
%set(gca,'XTick',plotstart:30:plotstop);

% Weighted MEan
% plot(bearings,abs(loopRIwmean(:,1)+1i*loopRIwmean(:,2))*180/pi,'mx')
% plot(bearings,abs(loopRIwmean(:,3)+1i*loopRIwmean(:,4))*180/pi,'cx')

% Baseline pattern
if(~isempty(patt))
    plot((patt(:,1)),patt(:,7),'m--')
    plot((patt(:,1)),patt(:,9),'c--')
end

xlim([plotstart plotstop]);
xlabel('Bearing (deg True)','Fontsize', labelfontsize)
ylabel('Amplitude Ratio','Fontsize', labelfontsize)

if printplots
    eval(sprintf('print -dpng %s%sPATT_%s_%s_%s_Amplitude.png',loopfolder,pattfolder, code, datestr(min(loop(:,41)),'yyyymmdd'),datestr(max(loop(:,41)),'yyyymmdd') ) )
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 5. Plot Metadata
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Position',[100+fw,100+fh+75,fw,fh])
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
%set(gca,'XTick',plotstart:30:plotstop);
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
ylim([-1 1]*thresholds.maxVesselSpeed)
%set(gca,'XTick',plotstart:30:plotstop);
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
%set(gca,'XTick',plotstart:30:plotstop);
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
%set(gca,'XTick',plotstart:30:plotstop);
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
%set(gca,'XTick',plotstart:30:plotstop);
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
%set(gca,'XTick',plotstart:30:plotstop);
title('f)');

if printplots
    eval(sprintf('print -dpng %s%sPATT_%s_%s_%s_Metadata.png',loopfolder,pattfolder, code, datestr(min(loop(:,41)),'yyyymmdd'),datestr(max(loop(:,41)),'yyyymmdd') ) )
end

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 6. Plot Vessel Positions
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figure('Position',[100+fw*2,100+fh+75,fw,fh])
polargeo(pi,60);
hold on;
polargeo(loop(ind(sampind),1)*pi/180, loop(ind(sampind),8)/1000, 'r.');
if printplots
    eval(sprintf('print -dpng %s%sPATT_%s_%s_%s_Vessels.png',loopfolder,pattfolder,code, datestr(min(loop(:,41)),'yyyymmdd'),datestr(max(loop(:,41)),'yyyymmdd') ) )
end

%% 10. Write Pattern File

filename = ['SEAS_' code datestr(max(loop(:,41)),'_yyyy_mm_dd_HHMM') '.patt'];
fileID = fopen([loopfolder,pattfolder,filename],'w'); %TGU save .patt file in a pattern folder under the loops folder

fprintf(fileID,'%%CTF: 1.00\n');
fprintf(fileID,'%%%% SeaSonde Crossloop Antenna Pattern File\n');
fprintf(fileID,'%%FileType: PATT xlp4 "AntennaPattern"\n');
fprintf(fileID,'%%Owner: CODAR Ocean Sensors\n');
fprintf(fileID,['%%TimeStamp: ',datestr(max(loop(:,41)),'yyyy mm dd  HH MM SS'),'\n']);
fprintf(fileID,'%%Site: %s ""\n',code); %TGU added code variable
fprintf(fileID,'%%Origin:  %11.7f %11.7f\n',lat,lon);  %TGU uncommented and added requirement for origin in section 2
fprintf(fileID,['%%UserComment: VesselEchoPattern;',sprintf('%s',notes),'\n']);
fprintf(fileID,['%%AntennaBearing: ',sprintf('%3.1f',ant1bearing),' True ;;\n']);
fprintf(fileID,'%%ReferenceChannel: 3\n');
fprintf(fileID,'%%AngularResolution: 1.0 deg\n');
fprintf(fileID,'%%TableType: PATT MP01\n');
fprintf(fileID,'%%TableColumns: 5\n');
fprintf(fileID,'%%TableColumnTypes: BEAR A13R A13I A23R A23I\n');
%fprintf(fileID,['%%TableRows: ',sprintf('%d',size(bearings,1)),'\n']);
fprintf(fileID,'%%TableRows: %d\n',bcount);  %TGU added to account for NaN values removed
fprintf(fileID,'%%TableStart:\n');
fprintf(fileID,'%%%% Bearing    A13        A13        A23        A23\n');
fprintf(fileID,'%%%%  DegCW     real       imag       real       imag\n');

for n = 1:size(bearings,1)
    if ~isnan(loopRImedian(n,1)) %TGU added to keep NaNs out of file
        fprintf(fileID,'  %03.1f  %1.7f  %1.7f  %1.7f  %1.7f\n',bearings(n)-ant1bearing,loopRImedian(n,1),loopRImedian(n,2),loopRImedian(n,3),loopRImedian(n,4));
    end
end

fprintf(fileID,'%%TableEnd:\n');
fprintf(fileID,'%%%%\n');
fprintf(fileID,['%%ProcessedTimeStamp: ',datestr(now,'yyyy mm dd  HH MM SS'),'\n']);
fprintf(fileID,'%%ProcessingTool: "Chad''s MATLAB Script" 2.0\n');
fprintf(fileID,'%%End:\n');

fclose(fileID);
end


function [filtStr,notes] = applyfilters(filters,thresholds,notes)
% Begin assembling filter string statement
filtStr = 'I{#} = find(';

%____________________________________________________________________________________
%TGU NOTE - HAVE TO USE AT LEAST ONE AND NOT MORE THAN ONE OF THESE FIRST THREE FILTERS
%DEALING WITH MINIMUM SIGNAL TO NOISE
switch filters.minSNR
    case 'monopole'
        % Require minSNR for Ch3 only
        filtStr = [filtStr,'loop(:,14)>thresholds.minSNR']; notes = [notes, sprintf('monopole_only_SNR>%2d;',thresholds.minSNR)];
    case 'monopole_and_1loop'
        % Require minSNR for Ch3 & either Ch1 or Ch2
        filtStr = [filtStr,'loop(:,14)>thresholds.minSNR & (loop(:,12)>thresholds.minSNR | loop(:,13)>thresholds.minSNR)'];   notes = [notes, sprintf('monopole_&_a_loop_SNR>%02d;',thresholds.minSNR)];
    case 'all'
        % Require minSNR for all three channels
        filtStr = [filtStr,'loop(:,14)>thresholds.minSNR & loop(:,12)>thresholds.minSNR & loop(:,13)>thresholds.minSNR']; notes = [notes, sprintf('all_channels_SNR>%02d;',thresholds.minSNR)];
end
%_____________________________________________________________________________________

if filters.maxSNR
    % Require maxSNR for Ch3, Ch1 & Ch2
    filtStr = [filtStr,' & loop(:,14)<thresholds.maxSNR & loop(:,12)<thresholds.maxSNR & loop(:,13)<thresholds.maxSNR']; notes = [notes, sprintf('all_channels_SNR<%02d;',thresholds.maxSNR)];
end

switch filters.minIIR
    case  'all'
        % Require min IIR SNR for all three channels
        % TGU NOTE had to increase column numbers by 1 and added &
        filtStr = [filtStr,' & loop(:,28)>thresholds.minSNR & loop(:,29)>thresholds.minSNR & loop(:,30)>thresholds.minSNR']; notes = [notes, sprintf('all_channels_IIR_SNR>%02d;',thresholds.minSNR)];
        
    case 'monopole_and_1loop'
        % Require min IIR SNR for Ch 3 & either Ch1 or Ch2
        %TGU NOTE corrected Ch 3 column number to 30 and added &
        filtStr = [filtStr,' & loop(:,30)>thresholds.minSNR & (loop(:,28)>thresholds.minSNR | loop(:,29)>thresholds.minSNR)']; notes = [notes, sprintf('monopole_&_a_loop_IIR_SNR>%02d;',thresholds.minSNR)];
end

if filters.bear
    %wrap to 180
    % Filter out solutions outside of bearing limits
    if (thresholds.start180 < thresholds.stop180)
        filtStr = [filtStr,' & loop(:,1)>=thresholds.start180 & loop(:,1)<=thresholds.stop180']; notes = [notes, sprintf('bearing>=%03d_and_bearing<=%03d;',thresholds.start,thresholds.stop)];
    else
        filtStr = [filtStr,' & loop(:,1)>=thresholds.start180 | loop(:,1)<=thresholds.stop180']; notes = [notes, sprintf('bearing>=%03d_or_bearing<=%03d;',thresholds.start,thresholds.stop)];
    end
end

if filters.lowvel
    % % Filter out solutions near DC (radial velocity is too low)
    filtStr = [filtStr,' & abs(loop(:,9)) >thresholds.minVesselSpeed'];  notes = [notes, sprintf('Bragg_velocity>%04.1f;',thresholds.minVesselSpeed)];
end

if filters.highvel
    % % Filter out solutions with high radial velocity
    filtStr = [filtStr,' & abs(loop(:,9)) < thresholds.maxVesselSpeed']; notes = [notes, sprintf('Bragg_velocity<%03d;',thresholds.maxVesselSpeed)];
end

if filters.maxrange
    % Filter out solutions past max range
    filtStr = [filtStr,' & abs(loop(:,8))/1000 < ', num2str(thresholds.maxRange)];  notes = [notes, sprintf('range<%04.1fkm;',thresholds.maxRange)];
end

if filters.minrange
    % Filter out solutions closer than min range
    filtStr = [filtStr,' & abs(loop(:,8))/1000 > ', num2str(thresholds.minRange)];  notes = [notes, sprintf('range>%04.1fkm;',thresholds.minRange)];
end

if filters.widerange
    % Filter out solutions with peaks wide in range
    filtStr = [filtStr,' & loop(:,25) - loop(:,24) <= thresholds.maxRangeWidth'];  notes = [notes, sprintf('range_width<=%04.1fkm;',thresholds.maxRangeWidth)];
end

if filters.narrowrange
    % Filter out solutions with peaks narrow in range
    filtStr = [filtStr,' & (loop(:,25) - loop(:,24) >= thresholds.minRangeWidth)']; notes = [notes, sprintf('range_width>=%04.1fkm;',thresholds.minRangeWidth)];
end

if filters.wideDoppler
    % Filter out solutions with peaks wide in Doppler
    %TGU NOTE, 27 - 26 is correct column assignment for my files
    filtStr = [filtStr,' & loop(:,27) - loop(:,26) <= thresholds.maxDoppWidth']; notes = [notes, sprintf('Doppler_width<=%02d;',thresholds.maxDoppWidth)];
    % filtStr = [filtStr,' & loop(:,26) - loop(:,25) <= thresholds.maxDoppWidth'];
end

if filters.daterange
    % Filter out solutions by date range
    filtStr = [filtStr,' & (loop(:,40) >= thresholds.cds & loop(:,40) <= thresholds.cde)'];  notes = [notes, sprintf('custom_dates_%s_to_%s;',datestr(thresholds.cds,'yyyy-mm-dd'), datestr(thresholds.cde,'yyyy-mm-dd'))];
end

if filters.hourofday
    % Filter out solutions by hour of the day
    if (thresholds.hstart < thresholds.hstop)
        filtStr = [filtStr,' & loop(:,38) > thresholds.hstart & loop(:,38) < thresholds.hstop']; notes = [notes, sprintf('hour>%02d_and_hour<%02d;',thresholds.hstart,thresholds.hstop)];
    else
        filtStr = [filtStr,' & loop(:,38) > thresholds.hstart | loop(:,38) < thresholds.hstop']; notes = [notes, sprintf('hour>%02d_or_hour<%02d;',thresholds.hstart,thresholds.hstop)];
    end
end

if filters.nearBragg
    % Filter out solutions near Bragg
    filtStr = [filtStr,' & ~(abs(loop(:,9))>thresholds.braggvel-thresholds.maxcurrent & abs(loop(:,9))<thresholds.braggvel+thresholds.maxcurrent)']; notes = [notes, sprintf('velocities>=%04.1fm/s_from_Bragg_vel;',thresholds.maxcurrent)];
end

if filters.outsideBraggDC
    % Limit Solutions to Doppler between Bragg & DC
    filtStr = [filtStr,' & abs(loop(:,9))<thresholds.braggvel-thresholds.maxcurrent']; notes = [notes, sprintf('absolute_velocity<%04.1fm/s;',thresholds.braggvel - thresholds.maxcurrent)];
end

if filters.mmsi
    % Limit Solutions to specific MMSI
    % TGU NOTE had to increase column number by 1
    filtStr = [filtStr,' & loop(:,31)== thresholds.mmsi']; notes = [notes, sprintf('MMSI=%s;',num2str(thresholds.mmsi))];
end

if filters.realL1
    % Filter solutions with a low or high amplitude ratio
    filtStr = [filtStr,' & real(loopA13)>thresholds.min_rA13 & real(loopA13)<thresholds.max_rA13'];  notes = [notes, sprintf('only_keep_real(LoopA13)>%03.1f_and<%03.1f;',thresholds.min_rA13,thresholds.max_rA13)];
end

if filters.imagL1
    % Filter solutions with a low or high amplitude ratio
    filtStr = [filtStr,' & imag(loopA13)>thresholds.min_iA13 & imag(loopA13)<thresholds.max_iA13'];  notes = [notes, sprintf('only_keep_imag(LoopA13)>%03.1f_and<%03.1f;',thresholds.min_iA13,thresholds.max_iA13)];
end

if filters.realL2
    % Filter solutions with a low or high amplitude ratio
    filtStr = [filtStr,' & real(loopA23)>thresholds.min_rA23 & real(loopA23)<thresholds.max_rA23'];  notes = [notes, sprintf('only_keep_real(LoopA23)>%03.1f_and<%03.1f;',thresholds.min_rA23,thresholds.max_rA23)];
end

if filters.imagL2
    % Filter solutions with a low or high amplitude ratio
    filtStr = [filtStr,' & imag(loopA23)>thresholds.min_iA23 & imag(loopA23)<thresholds.max_iA23'];  notes = [notes, sprintf('only_keep_imag(LoopA23)>%03.1f_and<%03.1f;',thresholds.min_iA23,thresholds.max_iA23)];
end

% Close the filter string
filtStr = [filtStr,');'];


end

