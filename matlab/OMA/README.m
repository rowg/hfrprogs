% README general description of open-boundary modal analysis functions
%
% Functions in the directory deal with doing open-boundary modal analysis
% (OMA) of surface currents data.  It uses the openMA toolbox developed
% by David M. Kaplan in Kaplan & Lekien (submitted)
% (https://erizo.pmc.ucsc.edu/COCMP-wiki/index.php/Documentation:OpenMA_Matlab_Toolbox)
% to do the actual analysis.  The functions in this directory are mainly
% an interface between that toolbox and the data formats developed in the
% Radials and Totals directories.
%
% The application of OMA to currents data is carried out in several steps.
% First, modes are generated on a specific domain with a continuous
% boundary.  This is done with generate_OMA_modes.m.  To generate modes, the
% Lon,Lat coordinates of the domain area are converted to x,y coordinates
% using the m_map projection (which must be set up before generating modes).
% The modes are then generated and the relevant coordinates are converted
% back to Lon,Lat.  Lon,Lat is used for all further calculations.  These
% modes are typically saved somewhere where they can be accessed and used
% for fitting data many times.
%
% Next, the modes are typically interpolated on the total currents grid
% using interp_OMA_modes_to_grid.m.  This is so that currents on the grid
% can be generated from the fit to the modes quickly without having to
% reinterpolate every time.  These interpolated modes are saved for future
% reference.
%
% The next step is to fit data to the modes.  This can be done with
% either radial current measurements or totals currents using either
% fit_OMA_modes_to_radials.m or fit_OMA_modes_to_totals.m.  See Kaplan &
% Lekien (submitted) for more details on the differences and
% advantages/disadvantages of the two approaches to fitting data.  Both
% of these functions generate TUV structures just like makeTUV.m, with
% the exception of some different metadata.  In particular, there will be a
% variable TUV.OtherTemporalVars.OMA_alpha that contains the coefficients
% of each mode for each timestep.  These coefficients can later be used
% to generate currents at arbitrary points in the domain.  This is useful
% for particle tracking.  The TUV structure will also contain an error
% estimate derived from error propagation of totals or radials errors.
%
% After the fits the OMA currents are ready to be used.  One possibility
% is to use them to generate particle trajectories with the functions in
% the trajectories directory.
%
% NOTE: The functions in this directory represent to some degree a "best
% usage" of the OMA approach.  Not all possible OMA configurations are
% allowed by the functions and particular usages may require different
% approaches.  However, this type of site specific configuration will
% require modification by the individual user.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: README.m 460 2007-07-20 19:24:22Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

help(mfilename)

