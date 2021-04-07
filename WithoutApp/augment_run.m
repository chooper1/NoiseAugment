paths{1} = ["input/"];
paths{2} = ["noise1/", "noise2/"];
paths{3} = ["output/"];
paths{4} = "";
%paths{5} = "";

room_dims = [10,10,3];

mic_pos(1,:) = [1, 5, 1];

source_pos = [1;1;1;9;9;2];

noise_pos{1} = [0; 0.5; 0.5; 0; 9.5; 2.5];
noise_pos{2} = [1;1;1;9;9;2];

positions{1} = source_pos;
positions{2} = noise_pos;
positions{3} = mic_pos;
positions{4} = room_dims;

amplitudes = [0.5 0.75];
noise_prob = [1; 1];
noise_settings{1} = noise_prob;
noise_settings{2} = amplitudes;

noise_options = [0,0,0,0,0,0];
Goal_freq = 16; %KHz

exclusive=1;
snr_params=[0.2 0.4];

AugmentDataset(paths, positions, noise_settings, noise_options, Goal_freq, exclusive, snr_params);
