% writes information about dataset to a text file
function write_info(output_path, dataset_path, noise_paths, noise_prob, amp, source_pos, noise_pos, mic_pos, room_dims)
    % open file in the same directory as the output synthetic dataset
    s = strcat(output_path, 'info.txt');
    fileID = fopen(s,'w');
    
    %print information to the file
    fprintf(fileID, 'Dataset Information: \n');
    fprintf(fileID, 'Input Dataset:  %s, ' , dataset_path);
    if length(source_pos) == 3
        fprintf(fileID, 'Position (x,y,z): %f, %f, %f' , source_pos(1), source_pos(2), source_pos(3));
    elseif length(source_pos) == 6
        fprintf(fileID, 'Position (x,y,z): %f, %f, %f to %f, %f, %f' , source_pos(1), source_pos(2), source_pos(3), source_pos(4), source_pos(5), source_pos(6));
    end
    fprintf(fileID, '\n');
    fprintf(fileID, 'Noise Datasets:\n');
    for i=1:length(noise_paths)
        fprintf(fileID, '%d' , i);
        fprintf(fileID, '. Dataset: %s, Probability: %f, Amplitude: %f, ' , noise_paths(i), noise_prob(i), amp(i));

        if length(noise_pos{i}) == 3
            fprintf(fileID, 'Position (x,y,z): %f, %f, %f' , noise_pos{i}(1), noise_pos{i}(2), noise_pos{i}(3));
        elseif length(noise_pos{i}) == 6
            fprintf(fileID, 'Position (x,y,z): %f, %f, %f to %f, %f, %f' , noise_pos{i}(1), noise_pos{i}(2), noise_pos{i}(3), noise_pos{i}(4), noise_pos{i}(5), noise_pos{i}(6));
        end
        fprintf(fileID, '\n');
    end
    fprintf(fileID, 'Room Configuration:\n');
    fprintf(fileID, 'Dimensions: %f, %f, %f \n', room_dims(1), room_dims(2), room_dims(3));
    fprintf(fileID, 'Microphone Locations (x,y,z):\n');
    for i=1:size(mic_pos,1)
        fprintf(fileID, '%f, %f, %f \n', mic_pos(i,1), mic_pos(i,2), mic_pos(i,3)); 
    end
    
    %close the file
    fclose(fileID);
end