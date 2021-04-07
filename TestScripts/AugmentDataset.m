%loops over dataset and augments all files
function AugmentDataset(paths, positions, noise_settings, other_noise, goal_freq, exclusive, snr_amp)

    % INPUTS:
    % paths - path to input desired speaker sound file
    dataset_path = paths{1};
    noise_paths = paths{2};
    output_path = paths{3};
    name_conv = paths{4};
    % paths{5} (optional) - text file listing files to augment

    % positions - positions of source, noise source(s), microphone(s), and room dimensions
    source_pos = positions{1};
    noise_pos = positions{2};
    mic_pos = positions{3};
    room_dims = positions{4};

    % noise_settings - probability and amplitude scaling factor for each noise source
    noise_prob = noise_settings{1};
    amp = noise_settings{2};

    % other_noise - option to add white/pink/brownian noise
    % goal_freq - desired output frequency in KHz (gets converted to Hz)
    goal_freq = goal_freq * 1000;

    % exclusive - specific to LibriSpeech, this argument ensures that the desired speakers
    %             and background noise speakers are different

    % snr_amp - if given, the combined noise file is scaled relative to the
    %           input speech amplitude using this scaling factor

    rng('shuffle');

    %set exclusive variable
    if ~exist('exclusive','var')
        % third parameter does not exist, so default it to something
        exclusive = 0;
    end

    %configure microphones here
    addpath('Roomsimove/');
    addpath('Logging/');
    % edit Roomsimove/room_config.txt
    rewrite_config(mic_pos, room_dims);
    conf_file = './Logging/room_config.txt';

    %write information to log file
    write_info(output_path, dataset_path, noise_paths, noise_prob, amp, source_pos, noise_pos, mic_pos, room_dims);
    C =  {"Output File","Input File", "x", "y", "z"};
    for i=1:length(noise_paths)
        C{(i)*4+2} = strcat("Noise File ",int2str(i));
        C{(i)*4+3} = "x";
        C{(i)*4+4} = "y";
        C{(i)*4+5} = "z";
    end
    s = strcat(output_path,'log.xls');
    writecell(C,s);

    % compute RIR once in non-random case
    if length(source_pos) == 3
        H1 = roomsimove_single(conf_file, source_pos);
        source_pos_temp = source_pos;
    end

    for i=1:length(noise_paths) % could be an issue for this to all be loaded in memory at once
        noise_Files{i}(:) = [dir(fullfile(noise_paths(i),'*.wav')), dir(fullfile(noise_paths(i),'*.flac')),
                    dir(fullfile(noise_paths(i),'*.ogg')), dir(fullfile(noise_paths(i),'*.au')),
                    dir(fullfile(noise_paths(i),'*.aiff')), dir(fullfile(noise_paths(i),'*.aif')),
                    dir(fullfile(noise_paths(i),'*.aifc')), dir(fullfile(noise_paths(i),'*.m4a')),
                    dir(fullfile(noise_paths(i),'*.mp3')), dir(fullfile(noise_paths(i),'*.mp4'))]; %gets all sound files in directory

        % compute RIR once in non-random case
        if length(noise_pos{i}) == 3
          	H2{i} = roomsimove_single(conf_file, noise_pos{i});
            noise_pos_temp{i} = noise_pos{i};
        elseif length(noise_pos{i}) == 6
            H2{i} = [];
            noise_pos_temp{i} = [0; 0; 0;];
        end
    end
    if length(paths) == 4 % augment all files in dataset path
        name_same = 0; % files will be named using the input naming convention
      	dataset_Files = [dir(fullfile(dataset_path,'*.wav')), dir(fullfile(dataset_path,'*.flac')),
                         dir(fullfile(dataset_path,'*.ogg')), dir(fullfile(dataset_path,'*.au')),
                         dir(fullfile(dataset_path,'*.aiff')), dir(fullfile(dataset_path,'*.aif')),
                         dir(fullfile(dataset_path,'*.aifc')), dir(fullfile(dataset_path,'*.m4a')),
                         dir(fullfile(dataset_path,'*.mp3')), dir(fullfile(dataset_path,'*.mp4'))]; %gets all wav files in directory

    elseif length(paths) == 5 % augment all files listed in text file
        name_same = 1; % files will be named the same as the input filenames
    	  srcfile = paths{5};
        fid=fopen(srcfile);
        tline = fgetl(fid);
        while ischar(tline)
            if  ~(exist("dataset_Files"))
                dataset_Files{1} = tline;
            else
                dataset_Files{end+1} = tline;
            end
            tline = fgetl(fid);
        end
        fclose(fid);
    end

    for k = 1:length(dataset_Files)
    	  clear noise_filename noise_index;
        % get filename
        if length(paths) == 4
        	dataset_filename = dataset_Files(k).name;
        elseif length(paths) == 5
        	dataset_filename = dataset_Files{k};
        end

        % specifically for LibriSpeech, make speaker exclusive
        if exclusive
            baseFileNameOne = dataset_filename;
            reader = split(baseFileNameOne, "-");
            reader_ID_one = char(reader(1));
        end

        % if random speaker position
        if length(source_pos) == 6
          	if source_pos(1) > source_pos(4)
                x = unifrnd(source_pos(4), source_pos(1));
            else
              	x = unifrnd(source_pos(1), source_pos(4));
            end
            if source_pos(2) > source_pos(5)
                y = unifrnd(source_pos(5), source_pos(2));
            else
                y = unifrnd(source_pos(2), source_pos(5));
            end
            if source_pos(3) > source_pos(6)
                z = unifrnd(source_pos(6), source_pos(3));
            else
                z = unifrnd(source_pos(3), source_pos(6));
            end
            % generate room impulse response for speaker
            H1 = roomsimove_single(conf_file, [x; y; z;]);
            source_pos_temp = [x; y; z;];
        end

        % select necessary noise files
        noise_count = 1;
        for i = 1:length(noise_paths)
            % include noise w/ specific prob
          	rand_prob = unifrnd(0,1);
            if rand_prob < noise_prob(i)
                % add noise of this type
                noise_ind = randi([1 length(noise_Files{i})]);
                baseFileName = noise_Files{i}(noise_ind).name;

                % specifically for LibriSpeech, make speaker exclusive
                if exclusive
                    reader = split(baseFileName, "-");
                    reader_ID = char(reader(1));
                    %enforce exlusive
                    while strcmp(reader_ID, reader_ID_one) == 1
                        noise_ind = randi([1 length(noise_Files{i})]);
                        baseFileName = noise_Files{i}(noise_ind).name;
                        reader = split(baseFileName, "-");
                        reader_ID = char(reader(1));
                    end
                end

                noise_filename(noise_count) = strcat(noise_paths(i), baseFileName);
                noise_index(noise_count) = i;

                %if random noise position
                if length(noise_pos{i}) == 6
                    if noise_pos{i}(1) > noise_pos{i}(4)
                        x = unifrnd(noise_pos{i}(4), noise_pos{i}(1));
                	else
                        x = unifrnd(noise_pos{i}(1), noise_pos{i}(4));
                    end
                    if noise_pos{i}(2) > noise_pos{i}(5)
                        y = unifrnd(noise_pos{i}(5), noise_pos{i}(2));
                    else
                        y = unifrnd(noise_pos{i}(2), noise_pos{i}(5));
                    end
                    if noise_pos{i}(3) > noise_pos{i}(6)
                        z = unifrnd(noise_pos{i}(6), noise_pos{i}(3));
                    else
                        z = unifrnd(noise_pos{i}(3), noise_pos{i}(6));
                    end
                    H2{i} = roomsimove_single(conf_file, [x; y; z;]);
                    noise_pos_temp{i} = [x; y; z;];
                end
                noise_count = noise_count + 1;
            end
        end

        % set values as empty if no noise sources for this input
        if ~(exist("noise_filename"))
          	noise_filename = [];
            noise_index = [];
        end
        if ~(exist("H2"))
            H2 = [];
            noise_pos_temp = [];
        end


        % name_conv - naming convention (i.e. the files will be named {name_conv}_#.wav)
        % name_same - if name_same is 1, the output filenames will be the same as the input
        %             desired speaker filenames
        if name_same == 1
            out_path = strcat(output_path, dataset_filename);
            s = dataset_filename;
        else
            out_path = strcat(output_path, name_conv, " ", int2str(k), '.wav');
            s = strcat(name_conv, " ", int2str(k), '.wav');
        end

        % dataset_fn is the full path of the desired speech file
        dataset_fn = strcat(dataset_path, dataset_filename);

        %augment sound file
        augment_file(dataset_fn, noise_filename, H1, H2, noise_index, out_path, amp, other_noise, goal_freq, snr_amp);

        %add to log file
        C =  {s, dataset_fn, source_pos_temp(1), source_pos_temp(2), source_pos_temp(3)};
        noise_count = 1;
        for i=1:max(noise_index)
            if sum(ismember(i,noise_index)) == 0
                C{(i)*4+2} = "";
                C{(i)*4+3} = "";
                C{(i)*4+4} = "";
                C{(i)*4+5} = "";
            else
                C{(i)*4+2} = noise_filename(noise_count);
                n = noise_pos_temp{i};
                C{(i)*4+3} = n(1);
                C{(i)*4+4} = n(2);
                C{(i)*4+5} = n(3);
                noise_count = noise_count + 1;
            end
        end
        writecell(C,strcat(output_path,'log.xls'),'WriteMode','append')
    end
end
