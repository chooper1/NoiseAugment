function augment_file(input, noise, H1, H2, noise_index, in_path, out_path, name_conv, index, amp, other_noise, goal_freq, source_pos, noise_pos)
 	in_filename = strcat(in_path, input);
    [s1_, FS]=audioread(in_filename);
            
    %convert frequency https://www.mathworks.com/help/signal/ug/changing-signal-sample-rate.html
    if FS ~= goal_freq
        [P,Q] = rat(goal_freq/FS);
        s1 = resample(s1_,P,Q);
    else
        s1 = s1_;
    end
    
    avg_amp_speaker = sqrt(mean((s1.^2)));
    
    %add white/pink/brownian noise
    if other_noise(1) == 1 %white noise
        awg = awgn(s1, other_noise(2), 'measured');
    end
    if other_noise(3) == 1 %pink noise
    	n = pinknoise(length(s1),1);
        g_goal = 10^(other_noise(4)/20);  
        snr_val = snr(s1, n); % in dB
        g_val = 10^(snr_val/20); % how many times bigger the desired source is than the noise source
        pink = n * g_val/g_goal;
    end
    if other_noise(5) == 1 %brownian noise
        n = rednoise(length(s1),1);
        g_goal = 10^(other_noise(6)/20);  
        snr_val = snr(s1, n); % in dB
        g_val = 10^(snr_val/20); % how many times bigger the desired source is than the noise source
        brown = n * g_val/g_goal;
    end
    
    %allowing for multiple types of colored noise
    if other_noise(1) == 1 %white noise
        s1 = awg;
    end
    if other_noise(3) == 1 %pink noise
        s1 = s1 + pink;
    end
    if other_noise(5) == 1 %brownian noise
        s1 = s1 + brown;
    end
            
    % convolution
    for i=1:size(H1,2)
        s1_delay(:,i) = conv(H1(:,i),s1)/8;
    end
    avg_amp_in = sqrt(mean(mean((s1_delay.^2),2)));
    %s1_delay = s1_delay * (avg_amp_speaker / avg_amp_in);
    
    if size(noise,1) ~= 0
        for i=1:length(noise)
        	minLength=length(s1);
            clear s2 s2_;
            [s2_, fs] = audioread(noise(i)); 
            
            if size(s2_,2) > 1
                s2_ = sum(s2_,2) / size(s2_, 2);
            end
            
            if fs ~= goal_freq
            	[P,Q] = rat(goal_freq/fs);
                s2 = resample(s2_,P,Q);
            else
            	s2 = s2_;
            end
            
            % I put this here to avoid the issue where if the desired source
            % is a large file, then avg_amp_noise will be decreased due
            % to added zeros
            avg_amp_noise = sqrt(mean((s2.^2)));
            
            if length(s2) > minLength
            	start_ind = randi([1 length(s2)-minLength]);
                s2 = s2(start_ind:minLength+start_ind-1);
            elseif length(s2) < minLength
                rand_ind = randi([1 minLength-length(s2)]);
                s2(rand_ind:end+rand_ind-1) = s2(1:end);
                s2(1:rand_ind-1) = 0;
                s2(end+1:minLength) = 0;
            end
            % convolution
            if avg_amp_noise == 0
                for j=1:size(H1,2)
                    s2_delay{j}(:,i) = conv(H2{noise_index(i)}(:,j),s2)/8 * (0);
                end
            else
                for j=1:size(H1,2)
                    s2_delay{j}(:,i) = conv(H2{noise_index(i)}(:,j),s2)/8;
                    check_zeros(:,j) = s2_delay{j}(:,i) ~= 0; 
                end
                check_zero = sum(check_zeros, 2);
                check = find(check_zero ~= 0);
                %get amp
                avg_amp_noise_channels = 0;
                for j=1:size(H1,2)
                     avg_amp_noise_channels = avg_amp_noise_channels + mean((s2_delay{j}(check(:),i).^2));
                end
                avg_amp_noise_channels = sqrt(avg_amp_noise_channels/size(H1,2));
                %scale
                for j=1:size(H1,2)
                    s2_delay{j}(:,i) = s2_delay{j}(:,i) * amp(noise_index(i)) * (avg_amp_in/avg_amp_noise_channels); %replace avg_amp_noise w/ avg_amp_noise_channels
                end
                %ampl_ = sqrt((mean((s2_delay{1}(check(:),i).^2)) + mean((s2_delay{2}(check(:),i).^2)))/2)
                %ampl_ = sqrt((mean((s2_delay{1}(:,i).^2)) + mean((s2_delay{2}(:,i).^2)))/2)
            end
        end
        for j=1:size(H1,2)
            s2_combined{j} = (sum(s2_delay{j},2));
        end
        %ampl_1 = sqrt((mean((s2_delay{1}(:,1).^2)) + mean((s2_delay{2}(:,1).^2)))/2)
        %ampl_2 = sqrt((mean((s2_delay{1}(:,2).^2)) + mean((s2_delay{2}(:,2).^2)))/2)
        %avg_amp_ = sqrt((mean((s1_delay(:,1).^2)) + mean((s1_delay(:,2).^2)))/2)
        
        for j=1:size(H1,2)
        	x(:,j) = s1_delay(:,j)+s2_combined{j};
        end
    else
        for j=1:size(H1,2)
            x(:,j) = s1_delay(:,j);
        end
    end
    %avg amp
    avg_amp_out = sqrt(mean(mean((x.^2),2)));
    x = x * (avg_amp_speaker / avg_amp_out); 
    %write combined output file
    %note that the replace functions will need to be changed depending on
    %format of input file name
    s = strcat(out_path, name_conv, int2str(index), '.wav');
    audiowrite(s, x, FS);
    
    % Write info to a CSV file
    s = strcat(name_conv, int2str(index), '.wav');
    C =  {s, in_filename, source_pos(1), source_pos(2), source_pos(3)};
    noise_count = 1;
    for i=1:max(noise_index)
        if sum(ismember(i,noise_index)) == 0
            C{(i)*4+2} = "";
            C{(i)*4+3} = "";
            C{(i)*4+4} = "";
            C{(i)*4+5} = "";
        else
            C{(i)*4+2} = noise(noise_count);
            n = noise_pos{i};
            C{(i)*4+3} = n(1);
            C{(i)*4+4} = n(2);
            C{(i)*4+5} = n(3);
            noise_count = noise_count + 1;
        end
    end
    writecell(C,strcat(out_path,'log.xls'),'WriteMode','append')
end