%augment a single .wav file with noisy data
function augment_file(input, noise, H1, H2, noise_index, out_path, amp, other_noise, goal_freq, snr_amp)

    % INPUTS:
    % input - path to input desired speaker sound file
    % noise - path(s) to background noise sound file(s)
    % H1 - room impulse response for the desired speaker
    % H2 - room impulse response(s) for the background noise(s)
    % noise_index - array containing noise indices (since some background sources
    %               may not be included each time)
    % out_path - target output path
    % amp - array of the amplitudes of the noise files
    %       note that these are scaling factors applied to the noise files and do
    %       not apply scaling relative to the input speech amplitude
    % other_noise - option to add white/pink/brownian noise
    % goal_freq - desired output frequency
    % snr_amp - if given, the combined noise file is scaled relative to the
    %           input speech amplitude using this scaling factor

    %open desired speech file
    [s1_, FS]=audioread(input);

    %convert frequency if necessary
    %(https://www.mathworks.com/help/signal/ug/changing-signal-sample-rate.html)
    if FS ~= goal_freq
        [P,Q] = rat(goal_freq/FS);
        s1 = resample(s1_,P,Q);
    else
        s1 = s1_;
    end

    %set SNR flag
    if ~exist('snr_params','var')
        % third parameter does not exist, so default it to something
        snr_flag = 0;
    else
        snr_flag = 1
    end

    %get the average amplitude of the input speech
    avg_amp_speaker = sqrt(mean((s1.^2)));

    %add white/pink/brownian noise
    addpath('NoiseTypes/');
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

    %average amplitude of s1_delay
    avg_amp_in = sqrt(mean(mean((s1_delay.^2),2)));

    % loop over noise files
    if size(noise,1) ~= 0
        for i=1:length(noise)
        	minLength=length(s1);
            clear s2 s2_;

            %open noise file
            [s2_, fs] = audioread(noise(i));

            % average if noise has multiple channels
            if size(s2_,2) > 1
                s2_ = sum(s2_,2) / size(s2_, 2);
            end

            %convert frequency if necessary
            %(https://www.mathworks.com/help/signal/ug/changing-signal-sample-rate.html)
            if fs ~= goal_freq
            	[P,Q] = rat(goal_freq/fs);
                s2 = resample(s2_,P,Q);
            else
            	s2 = s2_;
            end

            % adjust the noise file according to the length of the input
            % speech file, and randomly place it within the input clip if
            % the input clip is longer
            if length(s2) > minLength
            	  start_ind = randi([1 length(s2)-minLength]);
                s2 = s2(start_ind:minLength+start_ind-1);
            elseif length(s2) < minLength
                rand_ind = randi([1 minLength-length(s2)]);
                s2(rand_ind:end+rand_ind-1) = s2(1:end);
                s2(1:rand_ind-1) = 0;
                s2(end+1:minLength) = 0;
            end

            % average amplitude of noise file
            avg_amp_noise = sqrt(mean((s2.^2)));

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

                % use this to correctly scale the amplitude of the noise
                check_zero = sum(check_zeros, 2);
                check = find(check_zero ~= 0);

                % get amplitude of the noise file channels
                avg_amp_noise_channels = 0;
                if length(check) ~= 0
                    for j=1:size(H1,2)
                        avg_amp_noise_channels = avg_amp_noise_channels + mean((s2_delay{j}(check(:),i).^2));
                    end
                    avg_amp_noise_channels = sqrt(avg_amp_noise_channels/size(H1,2));
                end

                % scale the noise files by the desired amplitude scaling
                % factor (normalized to the amplitude of the input file)
                if size(amp,1) == 2 %if random amplitude
                    amp_temp = unifrnd(amp(1,noise_index(i)), amp(2,noise_index(i)));
                else
                    amp_temp = amp(noise_index(i));
                end

                % scale files base on average noise amplitude and amplitude scaling factor
                if avg_amp_noise_channels == 0
                    for j=1:size(H1,2)
                        s2_delay{j}(:,i) = s2_delay{j}(:,i) * 0;
                    end
                else
                    for j=1:size(H1,2)
                        s2_delay{j}(:,i) = s2_delay{j}(:,i) * amp_temp * (avg_amp_in/avg_amp_noise_channels);
                    end
                end
            end
        end

        %combine noise files
        for j=1:size(H1,2)
            s2_combined{j} = (sum(s2_delay{j},2));
        end
        for j=1:size(H1,2)
            n_(:,j) = s2_combined{j};
        end

        if snr_flag % snr scaling
            if length(snr_amp) == 2 % if random snr value
                g_goal = unifrnd(snr_amp(1), snr_amp(2));
            else
                g_goal = snr_amp;
            end
            snr_val = snr(s1_delay, n_); % in dB
            g_val = 10^(snr_val/20); % how many times bigger the desired source is than the noise source

            % combine noise and input speech
            for j=1:size(H1,2)
                x(:,j) = s1_delay(:,j)+ n_(:,j)* g_val*g_goal;
            end
        else
            % combine noise and input speech
            for j=1:size(H1,2)
                x(:,j) = s1_delay(:,j)+ n_(:,j);
            end
        end
    else
        for j=1:size(H1,2)
            x(:,j) = s1_delay(:,j);
        end
    end

    % scale the final output file to have the same amplitude as the input file
    avg_amp_out = sqrt(mean(mean((x.^2),2)));
    x = x * (avg_amp_speaker / avg_amp_out);

    % write the output wav file
    audiowrite(out_path, x, FS);
end
