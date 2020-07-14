function AugmentDataset(paths, positions, noise_settings, other_noise, goal_freq)
	dataset_path = paths{1};
    noise_paths = paths{2};
    output_path = paths{3};
    name_conv = paths{4};
            
    source_pos = positions{1};
    noise_pos = positions{2};
    mic_pos = positions{3};
    room_dims = positions{4};
    
    noise_prob = noise_settings{1};
    amp = noise_settings{2};
    goal_freq = goal_freq * 1000;
    
    %configure microphones here!
    addpath('Roomsimove/');
    addpath('Logging/');
    % edit Roomsimove/room_sensor_config_cellphone_MJ.txt
    rewrite_config(mic_pos, room_dims);
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
            
    if length(source_pos) == 3
        H1 = roomsimove_single('room_sensor_config_cellphone_MJ.txt', source_pos);
        source_pos_temp = source_pos;
    end
            
    for i=1:length(noise_paths) % could be an issue for this to all be loaded in memory at once
        noise_Files{i}(:) = [dir(fullfile(noise_paths(i),'*.wav')), dir(fullfile(noise_paths(i),'*.flac')),
                    dir(fullfile(noise_paths(i),'*.ogg')), dir(fullfile(noise_paths(i),'*.au')),
                    dir(fullfile(noise_paths(i),'*.aiff')), dir(fullfile(noise_paths(i),'*.aif')),
                    dir(fullfile(noise_paths(i),'*.aifc')), dir(fullfile(noise_paths(i),'*.m4a')),
                    dir(fullfile(noise_paths(i),'*.mp3')), dir(fullfile(noise_paths(i),'*.mp4'))]; %gets all wav files in directory
        
        if length(noise_pos{i}) == 3
        	H2{i} = roomsimove_single('room_sensor_config_cellphone_MJ.txt', noise_pos{i});
            noise_pos_temp{i} = noise_pos{i};
        elseif length(noise_pos{i}) == 6
            H2{i} = [];
            noise_pos_temp{i} = [0; 0; 0;];
        end
    end
    if length(paths) == 4
    	dataset_Files = [dir(fullfile(dataset_path,'*.wav')), dir(fullfile(dataset_path,'*.flac')),
                    dir(fullfile(dataset_path,'*.ogg')), dir(fullfile(dataset_path,'*.au')),
                    dir(fullfile(dataset_path,'*.aiff')), dir(fullfile(dataset_path,'*.aif')),
                    dir(fullfile(dataset_path,'*.aifc')), dir(fullfile(dataset_path,'*.m4a')),
                    dir(fullfile(dataset_path,'*.mp3')), dir(fullfile(dataset_path,'*.mp4'))]; %gets all wav files in directory
    elseif length(paths) == 5
    	srcfile = paths{5};
        fid=fopen(srcfile);
        tline = fgetl(fid);
        while ischar(tline)
            dataset_Files{end+1} = tline;
            tline = fgetl(fid);
        end
        fclose(fid);
    end
            
    for k = 1:length(dataset_Files)
    	clear noise_filename noise_index;
        if length(paths) == 4
        	dataset_filename = dataset_Files(k).name;
        elseif length(paths) == 5
        	dataset_filename = dataset_Files{k};
        end
                    
        %if random speaker position
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
            H1 = roomsimove_single('room_sensor_config_cellphone_MJ.txt', [x; y; z;]);
            source_pos_temp = [x; y; z;];
        end
        
        %select necessary noise files
        noise_count = 1;
        for i=1:length(noise_paths)
        	rand_prob = unifrnd(0,1);
            if rand_prob < noise_prob(i) 
                %add noise of this type
                noise_ind = randi([1 length(noise_Files{i})]);
                baseFileName = noise_Files{i}(noise_ind).name;
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
                    H2{i} = roomsimove_single('room_sensor_config_cellphone_MJ.txt', [x; y; z;]);
                    noise_pos_temp{i} = [x; y; z;];
                end
                noise_count = noise_count + 1;
            end
        end
        %augment file
                
        if ~(exist("noise_filename"))
        	noise_filename = [];
            noise_index = [];
        end 
        if ~(exist("H2"))
            H2 = [];
            noise_pos_temp = [];
        end    
                    
        augment_file(dataset_filename, noise_filename, H1, H2, noise_index, dataset_path, output_path, name_conv, k, amp, other_noise, goal_freq,source_pos_temp, noise_pos_temp);
        k
        length(dataset_Files)
    end
end