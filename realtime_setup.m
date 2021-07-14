% add the dependencies to the MATLAB path

switch getenv('USER')
  case 'roboos'
    addpath(fileparts(mfilename('fullpath')));
    addpath('/Users/roboos/matlab/liblsl-1.14.0');
    addpath('/Users/roboos/matlab/liblsl-1.14.0/bin');
    addpath('/Users/roboos/matlab/fieldtrip/preproc');
    
  otherwise
    fprintf('unknown user');
end
