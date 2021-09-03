clear all
close all

% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

%% resolve a stream...
disp('Resolving the feedback stream...');
result = {};
while isempty(result)
  result = lsl_resolve_byprop(lib, 'name', 'rms');
end

%% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

%% show some information about the stream
inf = inlet.info();
inf.as_xml()

% inf.name
% inf.type
nchan = inf.channel_count;
fsample = inf.nominal_srate;
% inf.channel_format
% inf.source_id
% inf.version
% inf.created_at
% inf.uid
% inf.session_id

disp('Receiving timeseries data...');
while true
  % get chunk from the inlet
  [chunk, stamps] = inlet.pull_chunk();
  [nchan, nsample] = size(chunk);
  
  
  
  bar(1:nchan, chunk)
  ax = axis;
  ax(3) = 0;
  ax(4) = max(ylim);
  axis(ax);
  
  drawnow
  
end
