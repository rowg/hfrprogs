function pp=plot_vel(Lon,Lat,uVel,vVel,plot_type,c_bar,ranges,maxVel)
% plot_vel  Plot (quiver or contour) codar velocity vectors
%-------------------------------------------------------
% University of South Florida, Ocean Circulation Group
% Sage's Codar Processing Toolbox v1.0
%-------------------------------------------------------
% Usage:
%   plot_vel(Lon,Lat,uVel,vVel,plot_type,c_bar)
% Input:
%   Lon,Lat   = Longitude/Latitude in decimal degrees
%   uVel,vVel = Eastward/Northward velocity in cm/s
%   plot_type = 1) Black Arrows
%               2) Colored Arrows
%               3) Filled Contours w/ Black Arrows
%               4) Filled Contours Only
%   c_bar     = 0/1 Plot the colorbar
%   ranges    = Colorbar increment ranges (default [0:5:50])
%   max_vel   = Maximum velocity (used for scaling)
% Output: None
% Updates:
%   Written by Sage 6/25/2004
%   Added ranges and maxVel to input parameters 9/8/2006 
%   Added data distance check to pcolor routine 9/9/2006
% Note: This function scales the velcity values based on
%     the data aspect ratio.  Eventually this will be updated
%     to use the mapping toolbox functions.
%   Two colormaps are specified in this function, one for
%     the filled contours and a second which contains an 
%     additional row for overmax velocity values
%   Speed greater than max_vel are eliminated (types 2-4), and speeds
%     between the top ranges value and max_vel are plotted using 
%     the maximum colorbar value, but scaled appropriately
%   Grid spacing is 0.05 degrees and data must be within 0.05 degrees
%-------------------------------------------------------

% Default values
if (nargin<8) maxVel = 100; end
if (nargin<7) ranges = [0:5:50]; end
if (nargin<6) c_bar=''; end

% Set up the colormap to use
  cmap  = jet(length(ranges)-1);
  cmap  = cmap.^1.5;      %Used for filled contour
  cmap2 = [cmap; cmap(end,:)];  %Used for colored arrows
                          % with additional row for overmax values
% Set up plot scaling for velocity
  %maxVel       = 100;   %In cm/s
  max_vect_len = 0.5;   %In Degrees
  scale        = max_vect_len/maxVel;

% Initialize output array
  pp=[];

% Fix for Wierd Colorbar Bug
  fill(1,1,1);

% If data exists plot it, otherwise ignore
if(length(Lon)>0) 

  % Scale the quivers according to the plot data aspect ratio
  vel_mag = sqrt(uVel.^2+vVel.^2);
  dar     = get(gca,'dataaspectratio');
  u_scale = scale*uVel*dar(1);
  v_scale = scale*vVel*dar(2);

  % Plot the Hourly Velocity Maps
  switch plot_type
  case 1
    % TYPE 1 - Black Arrows Only
    pp=quiver(Lon,Lat,u_scale,v_scale,0);
    set(pp,'color','k');
  case 2
    % TYPE 2 - Colored Arrows
    %ranges = [0:5:50 100];
	ranges2 = [ranges maxVel];
    for ii=1:length(ranges2)-1
      ind_vel = find(vel_mag>ranges2(ii) & vel_mag<=ranges2(ii+1));
      if length(ind_vel)>0
        p = quiver(Lon(ind_vel), Lat(ind_vel), u_scale(ind_vel), v_scale(ind_vel), 0); hold on;
        set(p,'color',cmap2(ii,:));
		pp = [pp p]; 
      end
    end
  case 3
    % TYPE 3 - Contours w/ Black Arrows
    if(length(vel_mag)>10)
      [XL YL] = meshgrid([floor(min(Lon)):0.05:ceil(max(Lon))],[floor(min(Lat)):0.05:ceil(max(Lat))]);
      ZL = griddata(Lon,Lat,vel_mag,XL,YL);
	  % Remove points with no data nearby 
      [nr nc]=size(XL);
      for jj=1:nr
        for kk=1:nc
	      D(jj,kk) = min(distance(Lat,Lon,YL(jj,kk)*ones(length(Lat),1),XL(jj,kk)*ones(length(Lon),1)));
	    end
      end
      ZL(D>0.05) = NaN;
      [c h]=contourf(XL,YL,ZL,ranges);  hold on;
      set(h,'linestyle','none');
    end
    p=quiver(Lon,Lat,u_scale,v_scale,0);
    set(p,'color','k');
	pp=[h; p(:)];
  case 4
    % TYPE 4 - Filled Contours Only
    if(length(vel_mag)>10)
      [XL YL] = meshgrid([floor(min(Lon)):0.1:ceil(max(Lon))],[floor(min(Lat)):0.1:ceil(max(Lat))]);
      ZL = griddata(Lon,Lat,vel_mag,XL,YL);
	  % Remove points with no data nearby 
      [nr nc]=size(XL);
      for jj=1:nr
        for kk=1:nc
	      D(jj,kk) = min(distance(Lat,Lon,YL(jj,kk)*ones(length(Lat),1),XL(jj,kk)*ones(length(Lon),1)));
	    end
      end
      ZL(D>0.05) = NaN;
      [c h]=contourf(XL,YL,ZL,ranges);  hold on;
      set(h,'linestyle','none');
    end
  case 5
    % TYPE 3 - Shadded Velocity w/ Black Arrows
    if(length(vel_mag)>10)
      [XL YL] = meshgrid([floor(min(Lon)):0.05:ceil(max(Lon))],[floor(min(Lat)):0.05:ceil(max(Lat))]);
      ZL = griddata(Lon,Lat,vel_mag,XL,YL);
	  % Remove points with no data nearby 
      [nr nc]=size(XL);
      for jj=1:nr
        for kk=1:nc
	      D(jj,kk) = min(distance(Lat,Lon,YL(jj,kk)*ones(length(Lat),1),XL(jj,kk)*ones(length(Lon),1)));
	    end
      end
      ZL(D>km2deg(10)) = NaN;
      p1=pcolor(XL,YL,ZL);  shading interp;
	  hold on;
    end
    p2=quiver(Lon,Lat,u_scale,v_scale,0);
    set(p2,'color','k');
	pp=[p1; p2];
  end % plot_type
end % length(CData) check

if (c_bar)
  % Plot and Configure the Colorbar
  colormap(cmap);
  set(gca,'clim',[min(ranges) max(ranges)]);
  caxes=gca;
  color_bar=colorbar('vert');
  set(color_bar,'ylim',[min(ranges) max(ranges)],'ytick',ranges);
  set(gcf,'currentaxes',color_bar);
  yla_cb = ylabel('Surface Velocity (cm/s)');
  set(yla_cb,'fontsize',10,'fontweight','bold');
  set(gca,'fontsize',10,'fontweight','bold');
  set(gcf,'currentaxes',caxes);
end % c_bar    

