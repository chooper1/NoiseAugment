# NoiseAugment

NoiseAugment is a Matlab application that allows the user to visualize the location of multiple sound sources in a room and generate synthetic noisy datasets using both input speech datasets and multiple noisy datasets. It also allows for multiple microphones to be placed at different locations in the room environment.


## Organization
The code is organized as follows:
Logging/ - Contains scripts for modifying the room environment configuration file in accordance with GUI parameters, as well as for writing the noise parameters to a log file.
NoiseTypes/ - Contains scripts for adding colored noise of different types (from [1]).
Roomsimove/ - Contains scripts for computing the Room Impulse Response (RIR) for sound sources in a simulated room environment (from [2]).
WithoutApp/ - Contains scripts to augment datasets directly (without using the Matlab application)
MatlabApp - The NoiseAugment dataset augmentation tool
augment_file.m - A support script for the Matlab application

## REFERENCES
[1] Hristo Zhivomirov (2021). Pink, Red, Blue and Violet Noise Generation with Matlab (https://www.mathworks.com/matlabcentral/fileexchange/42919-pink-red-blue-and-violet-noise-generation-with-matlab), MATLAB Central File Exchange.
[2] Emmanuel Vincent (2008). Roomsimove: Matlab toolbox for the computation of simulated room impulse reponses for moving sources (http://www.irisa.fr/metiss/members/evincent/software), GPL.
