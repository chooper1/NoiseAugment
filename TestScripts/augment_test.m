%paths

%paths{1} = ["/n/acc_lab/ttambe/clean_libri/LibriSpeech/train/wav/"]; %LibriSpeech
%paths{2} = ["/n/acc_lab/ttambe/clean_libri/LibriSpeech/train/wav/"]; %LibriSpeech
%paths{3} = ["/n/holyscratch01/acc_lab/chooper/LibriSpeech/noisy_room_study/output_room1_dataset1/train/"];
%paths{4} = "";
%paths{5} = "/n/holyscratch01/acc_lab/chooper/LibriSpeech/noisy_room_study/src-train-1.txt";

paths{1} = [inputPath];
paths{2} = [noisePaths];
paths{3} = [OutputPath];
paths{4} = convertCharsToStrings("augment");
            
room_dims = [4.5, 3.5, 2.5];
            
mic_pos(1,:) = [1.5, 1.5, 1.5];
mic_pos(2,:) = [1.5, 2, 1.5];

source_pos = [0.5;0.5;1;4;3;2];
            
noise_pos{1} = [0.5;0.5;1;4;3;2];

positions{1} = source_pos;
positions{2} = noise_pos;
positions{3} = mic_pos;
positions{4} = room_dims;

amplitudes = [0.1;0.5];
noise_prob = [1];
noise_settings{1} = noise_prob;
noise_settings{2} = amplitudes;
            
noise_options = [0,0,0,0,0,0];
Goal_freq = 16; %KHz
            
AugmentDataset(paths, positions, noise_settings, noise_options, Goal_freq);