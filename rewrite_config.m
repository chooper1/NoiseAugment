function rewrite_config(micpos, room_dims)
%fix path
%mfilename('fullpath')
%path_ = matlab.desktop.editor.getActiveFilename;
%fprintf('%s\n',path);
%cd path_;
addpath('Roomsimove/');
% edit Roomsimove/room_sensor_config_cellphone_MJ.txt
fileID = fopen('room_sensor_config_cellphone_MJ.txt','w');
fid = fopen('Roomsimove/room_sensor_config_cellphone_MJ.txt');
tline = fgetl(fid);
i = 1;
while ischar(tline)
    %disp(tline)
    %i
    if i == 6   %disp(tline) 
        %write mic1 to output file
        fprintf(fileID, 'room_size  %f  %f  %f' , room_dims(1), room_dims(2), room_dims(3));
        fprintf(fileID, '\n');
    elseif i == 18
        tline = fgetl(fid);
        i = i + 1;
        %disp(tline) 
        %write mic1 to output file
        for j=1:size(micpos,1)
            fprintf(fileID, 'sp%d  %f  %f  %f' , j, micpos(j,1), micpos(j,2), micpos(j,3));
            fprintf(fileID, '\n');
        end
    elseif i == 22
        tline = fgetl(fid);
        i = i + 1;
        %disp(tline) 
        %write mic1 to output file
        for j=1:size(micpos,1)
            fprintf(fileID, 'so%d  %f  %f  %f' , j, 0, 0, 0);
            fprintf(fileID, '\n');
        end
    elseif i == 26
        tline = fgetl(fid);
        i = i + 1;
        %disp(tline) 
        %write mic1 to output file
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
