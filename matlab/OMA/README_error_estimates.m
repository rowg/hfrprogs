% Here I wanted to explain in more detail how errors estimates for totals
% currents based on OMA fits generally work.  Before reading this
% document, please read totals/README_error_estimates for basic
% information regarding the structure, units and calculation of total
% current errors.
%
% OMA current error estimates are based on error propagation as detailed
% by Kaplan & Lekien (submitted).  For OMA fits from totals, these errors
% are calculated using a user-selected error estimates from the original
% TUV input data to the fit.  In this case, the U error, the V error and
% the UV covariance are all used in the propagation of the uncertainty.
% For OMA fits from radials, error estimates are generally based on
% assuming a diagonal radial covariance matrix (i.e., there is no
% covariance among the errors in different radial measurements).  This is
% not correct, but the only natural thing to assume in the absence of
% more information (this is equally incorrect when calculating totals
% errors of all but the GDOPMaxOrthog type).  The use can choose to
% either assume that the diagonal elements of the covariance matrix are
% all 1 (i.e., 'constant') or use the measured radial uncertainty.  In
% both cases, the final error estimates have the same form and units as
% typical totals errors from makeTUV (e.g. of the GDOP type).
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% 	$Id: README_error_estimates.m 460 2007-07-20 19:24:22Z dmk $	
%
% Copyright (C) 2007 David M. Kaplan
% Licence: GPL (Gnu Public License)
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

help(mfilename)

