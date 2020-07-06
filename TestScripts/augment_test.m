%paths
paths{1} = [inputPath];
paths{2} = [noisePaths];
paths{3} = [OutputPath];
paths{4} = convertCharsToStrings("augment");
            
room_dims = [4.45, 3.55, 2.5];
            
mic_pos(1,:) = [1, 1.15, 1.5];
mic_pos(2,:) = [1, 1, 1.5];

source_pos = [1.15;1.3;1.5;1.3;1.5;1.75];
            
noise_pos{1} = [1.5;1.75;1.5;2;2;1.75];
noise_pos{2} = [0; 2.5; 1];
noise_pos{3} = [3; 0; 1];
noise_pos{4} = [3.5; 1; 1;];

positions{1} = source_pos;
positions{2} = noise_pos;
positions{3} = mic_pos;
positions{4} = room_dims;

amplitudes = [0.5, 0.3, 0.3, 0.5];
noise_prob = [1, 0.5, 0.5, 0.5];
noise_settings{1} = noise_prob;
noise_settings{2} = amplitudes;
            
noise_options = [0,0,0,0,0,0];
Goal_freq = 16; %KHz
            
AugmentDataset(paths, positions, noise_settings, noise_options, Goal_freq);