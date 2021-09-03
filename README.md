# realtime-emg-feedback

This is a collection of MATLAB scripts that implement realtime biofeedback on the basis of EMG activity. The scripts are implemented in MATLAB using [lab streaming layer](https://github.com/labstreaminglayer/liblsl-Matlab/) and some low-level preprocessing functions from the [FieldTrip](https://github.com/fieldtrip/fieldtrip) toolbox.

On the first (acquisition and analysis) computer you run either `realtime_plot_timeseries` or `realtime_compute_rms`.

On the second (feedback) computer you run `realtime_plot_rms`.
