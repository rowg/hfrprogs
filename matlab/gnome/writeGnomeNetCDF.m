function [ ] = writeGnomeNetCDF(dom,lon,lat,times,U,V,file_netcdf,netcdfFlag,timeNow,desc,author)
%WRITEGNOMENETCDF  Write current data to NetCDF file following NOAA's GNOME format
%
% NOTE:  Requires the free netCDF matlab toolbox.
%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
%
%	$Id: writeGnomeNetCDF.m 583 2008-01-26 00:24:27Z cook $
%
%~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

%% NOTES for future modifications:
% 1) Document: At a minimum, we need to properly establish dimensionality
%    of lon, lat, times, U, V, etc.
% 2) lon, lat, times, U, V should be basic input arguments.
% 3) Other arguments should be param,val pairs following model of
%    makeTotals.  These should take appropriate default values.  Also
%    need to add additional parameters such as description, author.
% 4) All references to us should be removed - generalize.
% 5) Add possibility of including error estimates

%% Set default values if necessary.
if ~exist('timeNow','var') || isempty(timeNow)
  disp( 'Using time=now for creation TimeStamp.' );
  timeNow = now;      % TIMESTAMP
end
if ~exist('desc','var') || isempty(desc)
    desc = 'HF Radar Derived Surface Currents'
end
if ~exist('author','var') || isempty(author)
    author = 'anonymous'
end


[y,m,d,h,mm,s] = datevec(timeNow);
if ~exist('file_netcdf','var')
  file_netcdf = sprintf('GNOME_%s_%04d_%02d_%02d_%02d00.nc', ...
                        dom,y,m,d,h);
  disp([ 'Attempting to write DEFAULT file named ', ...
          file_netcdf ' in the current directory' ])
end
if ~exist('netcdfFlag','var')  || isempty(netcdfFlag)
  netcdfFlag = -9999;
  % netcdfFlag = -9.9999e+32;
  fprintf('Using default flag of: %g\n',netcdfFlag);
end

% base_stamp appears to be the year, month, day, hour of the 1st TUV file
[year,mon,day,hr,mn,sec] = datevec(times(1));
base_stamp = sprintf('%.4d, %.2d, %.2d, %.2d',year,mon,day,hr);
% time_units appears to be "hours since the first TUV time
time_units = sprintf('hours since %.4d-%.2d-%.2d %.2d:%.2d:%.2d', ...
                     year,mon,day,hr,mn,0);

numTimes = size(times(:),1);

% ------------------- DEFINE THE NetCDF FILE ATTRIBUTES------------------ %

ncquiet                                          % No NetCDF warnings.

try
    nc = netcdf(file_netcdf, 'clobber');         % Create NetCDF file.
    fprintf('%s - GNOME netCDF file named:\n\t%s has been created\n',mfilename, ...
            file_netcdf);
catch
    fprintf('########## PROBLEM opening %s, ##########\n%s exiting WITHOUT WRITING FILE.\n', ...
            file_netcdf, mfilename);
end

% Create time, the RECORD VARIABLE.  The RECORD VARIABLE is the dimension
% in any array that you can append to if subsequent opens on this netCDF
% file are desired.  This is what is referred to at the UNLIMITED variable,
% or dimension, in the GNOME documentation.
nc('time') = 0;

% Define global attributes
nc.description = desc;
nc.author = author;
% Not sure about this one
nc.date = datestr(timeNow);
nc.base_date = base_stamp;
% Alaska example had CURVILINEAR
nc.grid_type = 'REGULAR';

% Define variables dimensions - time (RECORD VARIABLE) defined above.
nc('lon') = length(lon);  % lon should be 1 x n
nc('lat') = length(lat);  % lat should be n x 1

% Define variables and dimensions
nc{'time'} = 'time';
nc{'lat'} = {'lat'};
nc{'lon'} = {'lon'};
nc{'water_u'} = {'time','lat','lon'};
nc{'water_v'} = {'time','lat','lon'};
nc{'u_error'} = {'time','lat','lon'};
nc{'v_error'} = {'time','lat','lon'};

% Define long name attributes
nc{'time'}.long_name = 'Valid Time (GMT)';
nc{'lat'}.long_name = 'Latitude';
nc{'lon'}.long_name = 'Longitude';
nc{'water_u'}.long_name = 'Eastward Water Velocity' ;
nc{'water_v'}.long_name = 'Northward Water Velocity' ;
nc{'u_error'}.long_name = 'Eastward Water Velocity Error' ;
nc{'v_error'}.long_name = 'Northward Water Velocity Error' ;

% Define base date for time (attributes)
nc{'time'}.base_date = base_stamp;

% Define variable units (attributes)
nc{'time'}.units = time_units;
nc{'lat'}.units = 'degrees north';                  
nc{'lon'}.units = 'degrees east';
nc{'water_u'}.units = 'm/s';
nc{'water_v'}.units = 'm/s';
nc{'u_error'}.units = 'm/s';
nc{'v_error'}.units = 'm/s';

% Define variable standard names (attributes)
nc{'time'}.standard_name = 'time';
nc{'lat'}.standard_name = 'latitude';
nc{'lon'}.standard_name = 'longitude';
nc{'water_u'}.standard_name = 'eastward_sea_water_velocity';
nc{'water_v'}.standard_name = 'northward_sea_water_velocity';
nc{'u_error'}.standard_name = 'eastward_sea_water_velocity_error';
nc{'v_error'}.standard_name = 'northward_sea_water_velocity_error';

% Define variable fill values (attributes)
nc{'water_u'}.FillValue_ = netcdfFlag;
nc{'water_v'}.FillValue_ = netcdfFlag;
nc{'u_error'}.FillValue_ = netcdfFlag;
nc{'v_error'}.FillValue_ = netcdfFlag;

% Write the grid information to the netcdf file
% % nc{'time'}(:) = 0:number_files-1;
nc{'time'}(1:numTimes) = 0:numTimes-1;
% lat, lon, and mask may have to be transposed!  If so make sure the
% u,v,uerr, and verr are also TRANSPOSED!
nc{'lat'}(:) = lat;
nc{'lon'}(:) = lon;
% nc{'mask'}(:) = maskInd;

% Now convert everything from cm/s to m/s
U = U ./ 100;
V = V ./ 100;
% grid_Uerr = grid_Uerr ./ 100;  % They are in funky units, don't want to
% grid_Verr = grid_Verr ./ 100;  % divide by 100 RIGHT?

% Replace NaN's (matlab flags) with NetCDF flags - do this after
% converting from cm/s to m/s or -9999 will become -99.99!
U(isnan(U)) = netcdfFlag;
V(isnan(V)) = netcdfFlag;

nc{'water_u'}(:) = U;           % Write velocity data to the NetCDF file
nc{'water_v'}(:) = V;
% % nc{'u_error'}(:) = grid_Uerr;
% % nc{'v_error'}(:) = grid_Verr;

disp('closing netCDF file ...')
nc = close(nc);                    % Close the file
