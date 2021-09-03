clear all
close all

% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

%% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
  result = lsl_resolve_byprop(lib,'type','EEG');
end

%% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

%% show some information about the stream
info = inlet.info();
info.as_xml()

nchan = info.channel_count;
fsample = info.nominal_srate;

%% create a new outlet
disp('Opening an outlet...');
info = lsl_streaminfo(lib, 'rms', 'Markers', nchan, 0, 'cf_float32', 'id28347645');
info.as_xml()
outlet = lsl_outlet(info);

%% start processing the data

hpfreq = nan;
hpfiltord = 4;

lpfreq = nan;
lpfiltord = 4;

bsfreq = nan; % [48 50];
bsfiltord = 4;

bpfreq = nan; % [55 100];
bpfiltord = 4;

disp('Receiving timeseries data...');
while true
  % get chunk from the inlet
  [chunk, stamps] = inlet.pull_chunk();
  [nchan, nsample] = size(chunk);
  
  if nsample==0
    pause(0.01);
    continue
  end
  
  if isempty(dat)
    % this is only for the first time
    dat = zeros(nchan, bufsize);
    tim = zeros(1,     bufsize);
    begsample = 1;
    endsample = begsample + nsample - 1;
    
    % initialize the filter
    if ~isnan(hpfreq)
      [B,A] = butter(hpfiltord, hpfreq/fsample, 'high');
      hpstate = ft_preproc_online_filter_init(B, A, chunk(:,end));
    end
    if ~isnan(lpfreq)
      [B,A] = butter(lpfiltord, lpfreq/fsample, 'low');
      lpstate = ft_preproc_online_filter_init(B, A, chunk(:,end));
    end
    if ~isnan(bsfreq)
      [B,A] = butter(bsfiltord, bsfreq/fsample, 'stop');
      bsstate = ft_preproc_online_filter_init(B, A, chunk(:,end));
    end
    if ~isnan(bpfreq)
      [B,A] = butter(bpfiltord, bpfreq/fsample); % default is pass
      bpstate = ft_preproc_online_filter_init(B, A, chunk(:,end));
    end
  end
  
  % apply the filter
  if ~isnan(hpfreq)
    [hpstate, chunk] = ft_preproc_online_filter_apply(hpstate, chunk);
  end
  if ~isnan(lpfreq)
    [lpstate, chunk] = ft_preproc_online_filter_apply(lpstate, chunk);
  end
  if ~isnan(bsfreq)
    [bsstate, chunk] = ft_preproc_online_filter_apply(bsstate, chunk);
  end
  if ~isnan(bpfreq)
    [bstate, chunk] = ft_preproc_online_filter_apply(bpstate, chunk);
  end
  
  % append the data to the end of the buffer
  dat = [dat(:,nsample+1:end) chunk];
  tim = [tim(1,nsample+1:end) (begsample:endsample)/fsample];
  
  % compute RMS and send it as a stream, another computer can do something with it
  rms = sqrt(mean(dat.^2,2));
  outlet.push_sample(rms);
  disp(rms')
  
  begsample = begsample + nsample;
  endsample = endsample + nsample;
  
end