% T_DEMO - demonstration of capabilities.
% Short example of capabilities of tidal analysis toolbox.
%
% In this example, we 
%         a) do nodal corrections for satellites, 
%         b) use inference for P1 and K2, and
%         c) force a fit to a shallow-water constituent.

% Version 1.0

% Sept/2014 - it was pointed out that the elevations are in feet, not meters.
%             plot labels changed. Also added a note about time zones.

echo on
       echo on
       % Load the example.
       load t_example
      
       % Define inference parameters.
       infername=['P1';'K2'];
       inferfrom=['K1';'S2'];
       infamp=[.33093;.27215];
       infphase=[-7.07;-22.40];
       
       % The call (see t_demo code for details).
       [tidestruc,pout]=t_tide(tuk_elev,...
       'interval',1, ...                     % hourly data
       'start',tuk_time(1),...               % start time is datestr(tuk_time(1))
       'latitude',69+27/60,...               % Latitude of obs
       'inference',infername,inferfrom,infamp,infphase,...
       'shallow','M10',...                   % Add a shallow-water constituent 
       'error','linear',...                   % coloured boostrap CI
       'synthesis',1);                       % Use SNR=1 for synthesis. 

     % Note - in the demo I use tuk_time which is MST. Strictly speaking,
     % in order to get Greenwich phase one should use Greenwich TIME as well,
     % which means adding 6 hours.
     % However, I stuck with doing things the sloppy not-quite-correct way so that 
     % results would comparable to those published in Mike Foreman's data report on the Fortran code.
     
       echo off

    %    pout=t_predic(tuk_time,tidestruc,,...
    %                  'latitude',69+27/60,...
    %                  'synthesis',1);

clf;orient tall;
set(gcf,'defaultaxestickdir','out','defaultaxestickdirmode','manual');
subplot(411);
plot(tuk_time-datenum(1975,1,0),tuk_elev,'b');
line(tuk_time-datenum(1975,1,0),pout,'color',[0 .5 0]);
line(tuk_time-datenum(1975,1,0),tuk_elev-pout,'linewi',2,'color','r');
xlabel('Days in 1975');
ylabel('Elevation (ft)');
text(190,5.5,'Original Time series','color','b');
text(190,4.75,'Tidal prediction from Analysis','color',[0 .5 0]);
text(190,4.0,'Original time series minus Prediction','color','r');
title('Demonstration of T\_Tide toolbox');

ax(1)=subplot(412);
fsig=tidestruc.tidecon(:,1)>tidestruc.tidecon(:,2); % Significant peaks
semilogy([tidestruc.freq(~fsig),tidestruc.freq(~fsig)]',[.0005*ones(sum(~fsig),1),tidestruc.tidecon(~fsig,1)]','.-r');
line([tidestruc.freq(fsig),tidestruc.freq(fsig)]',[.0005*ones(sum(fsig),1),tidestruc.tidecon(fsig,1)]','marker','.','color','b');
line(tidestruc.freq,tidestruc.tidecon(:,2),'linestyle',':','color',[0 .5 0]);
set(gca,'ylim',[.0005 1],'xlim',[0 .5]);
xlabel('frequency (cycles/hour)');
text(tidestruc.freq,tidestruc.tidecon(:,1),tidestruc.name,'rotation',45,'vertical','base');
ylabel('Amplitude (ft)');
text(.3,.4,'Analyzed lines with 95% significance level','fontweight','bold');
text(.3,.2,'Significant Constituents','color','b');
text(.3,.1,'Insignificant Constituents','color','r');
text(.3,.05,'95% Significance Level','color',[0 .5 0]);

ax(2)=subplot(413);
errorbar(tidestruc.freq(~fsig),tidestruc.tidecon(~fsig,3),tidestruc.tidecon(~fsig,4),'.r');
hold on;
errorbar(tidestruc.freq(fsig),tidestruc.tidecon(fsig,3),tidestruc.tidecon(fsig,4),'o');
hold off;
set(gca,'ylim',[-45 360+45],'xlim',[0 .5],'ytick',[0:90:360]);
xlabel('frequency (cycles/hour)');
ylabel('Greenwich Phase (deg)');
text(.3,330,'Analyzed Phase angles with 95% CI','fontweight','bold');
text(.3,290,'Significant Constituents','color','b');
text(.3,250,'Insignificant Constituents','color','r');

ax(3)=subplot(414);
ysig=tuk_elev;
yerr=tuk_elev-pout;
nfft=389;
bd=isnan(ysig);
gd=find(~bd);
bd([1:(min(gd)-1) (max(gd)+1):end])=0;
ysig(bd)=interp1(gd,ysig(gd),find(bd)); 
%[Pxs,F]=psd(ysig(isfinite(ysig)),nfft,1,[],ceil(nfft/2));
[Pxs,F]=pwelch(ysig(isfinite(ysig)),hanning(nfft),ceil(nfft/2),nfft,1);
Pxs=Pxs/2;
%%[Pxso,Fo]=psd(ysig(isfinite(ysig)),nfft,1,[],ceil(nfft/2));

%[Pxs,F]=pmtm(ysig(isfinite(ysig)),4,4096,1);
yerr(bd)=interp1(gd,yerr(gd),find(bd)); 
%[Pxe,F]=psd(yerr(isfinite(ysig)),nfft,1,[],ceil(nfft/2));
[Pxe,F]=pwelch(yerr(isfinite(ysig)),hanning(nfft),ceil(nfft/2),nfft,1);
Pxe=Pxe/2;
%[Pxe,F]=pmtm(yerr(isfinite(ysig)),4,4096,1);

semilogy(F,Pxs);
line(F,Pxe,'color','r');
xlabel('frequency (cph)');
ylabel('m^2/cph');
text(.2,1e2,'Spectral Estimates before and after removal of tidal energy','fontweight','bold');
text(.3,1e1,'Original (interpolated) series','color','b');
text(.3,1e0,'Analyzed Non-tidal Energy','color','r');

% Zoom  on phase/amplitude together
linkaxes(ax,'x');

