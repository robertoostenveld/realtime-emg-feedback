clear all
close all

% instantiate the library
disp('Loading the library...');
lib = lsl_loadlib();

% resolve a stream...
disp('Resolving an EEG stream...');
result = {};
while isempty(result)
  result = lsl_resolve_byprop(lib,'type','EEG');
end

% create a new inlet
disp('Opening an inlet...');
inlet = lsl_inlet(result{1});

% show some information about the stream
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

dat = [];
ylim = [-1000 1000];
bufsize = 5*fsample;
figstyle = 'timecourse';

hpfreq = nan;
hpfiltord = 4;

lpfreq = nan;
lpfiltord = 4;

bsfreq = nan; % [48 50];
bsfiltord = 4;

bpfreq = nan; % [55 100];
bpfiltord = 4;

disp('Now receiving chunked data...');
while true
  % get chunk from the inlet
  [chunk,stamps] = inlet.pull_chunk();
  [nchan, nsample] = size(chunk);
  
  if nsample==0
    pause(0.01);
    continue
  end
  
  if isempty(dat)
    % this is only for the first time
    dat = zeros(nchan, bufsize);
    tim = zeros(1,     bufsize);
    sample = 1;
    prevsample = 1;
    
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
  
  begsample = sample;
  endsample = sample+nsample-1;
  
  % append the data to the end of the buffer
  dat = [dat(:,nsample+1:end) chunk];
  tim = [tim(1,nsample+1:end) (begsample:endsample)/fsample];
  
  if (sample-prevsample)>fsample/10
    % redraw the figure if there are sufficient new samples
    prevsample = sample;
    
    switch figstyle
      case 'rms'
        bar(1:nchan, sqrt(mean(dat.^2, 2)))
        ax = axis;
        ax(3) = 0;
        ax(4) = max(ylim);
        axis(ax);
        
      case 'timecourse'
        for i=1:nchan
          subplot(nchan,1,i);
          plot(tim, dat(i,:));
          axis([tim(1) tim(end) ylim(1) ylim(2)]);
        end
    end
    
    drawnow
  end
  
  sample = endsample+1;
  disp(sample)
  
end