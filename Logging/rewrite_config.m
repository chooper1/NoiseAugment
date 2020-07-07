% update the roomsimove config file
function rewrite_config(micpos, room_dims)
    addpath('Roomsimove/');
    addpath('Logging/');
    % edit Logging/room_sensor_config_cellphone_MJ.txt
    fileID = fopen('Logging/room_sensor_config_cellphone_MJ.txt','w');
    fid = fopen('Roomsimove/room_sensor_config_cellphone_MJ.txt');
    tline = fgetl(fid);
    i = 1;
    %loop over lines in Roomsimove/room_sensor_config_cellphone_MJ.txt and
    %update lines in Logging/room_sensor_config_cellphone_MJ.txt based on
    %the input parameters
    while ischar(tline)
        if i == 6  
            %write room dimensions to output file
            fprintf(fileID, 'room_size  %f  %f  %f' , room_dims(1), room_dims(2), room_dims(3));
            fprintf(fileID, '\n');
        elseif i == 18
            tline = fgetl(fid);
            i = i + 1;
            %write mics to output file
            for j=1:size(micpos,1)
                fprintf(fileID, 'sp%d  %f  %f  %f' , j, micpos(j,1), micpos(j,2), micpos(j,3));
                fprintf(fileID, '\n');
            end
        elseif i == 22
            tline = fgetl(fid);
            i = i + 1;
            %write mics to output file
            for j=1:size(micpos,1)
                fprintf(fileID, 'so%d  %f  %f  %f' , j, 0, 0, 0);
                fprintf(fileID, '\n');
            end
        elseif i == 26
            tline = fgetl(fid);
            i = i + 1;
            %write mics to output file
            for j=1:size(micpos,1)
                fprintf(fileID, 'sd%d  %s' , j, "'omnidirectional'");
                fprintf(fileID, '\n');
            end
        else
            %write tline to output file
            fprintf(fileID, tline);
            fprintf(fileID, '\n');
        end
        tline = fgetl(fid);
        i = i+1;
    end
    fclose(fid);
end
