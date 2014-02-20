% TOTALS
%
% Files
%   cleanTotals            - Remove total current measurements exceeding speed or error thresholds
%   gdop_max_orthog        - Compute GDOP
%   gridTotals             - Place total current data on a regular grid 
%   makeTotals             - Generates total vectors from radial measurements 
%   maskTotals             - Removes totals current grid points 
%   README                 - Functions in this directory pertain principally to the generation of total
%   README_error_estimates - Here I wanted to explain in more detail how errors estimates for totals
%   rotateTotals           - Rotates total currents through an angle
%   spatialConcatTUV       - Concatenate grid points in various TUV structures
%   spatialInterpTotals    - Spatial interpolation of total vector
%   subsrefTUV             - Used to splice totals structures, pulling out certain pieces.
%   subsrefTUVerror        - Used to splice total error structures, 
%   temporalConcatTUV      - Concatenate timesteps in various TUV structures
%   temporalInterpTotals   - Temporal interpolation of total vector currents
%   TUVerrorMatvars        - Convenience function that just returns a cell array
%   TUVerrorstruct         - Creates an empty default TUVerror structure that can be
%   tuvLS                  - Calculate total current vectors from radial currents
%   TUVstruct              - Creates an empty default TUV structure that can be
