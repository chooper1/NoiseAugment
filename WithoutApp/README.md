# Scripts Without Matlab Application

This directory contains scripts augment datasets directly without using the Matlab application.

augment_file.m - Augments one input speech file with one or more noise files.
AugmentDataset.m - Loops over all input speech files in the dataset and augments them (by calling augment_file) in accordance with the input noise parameters.
augment_run.m - The script that is run by the user which contains the desired input noise parameters and which calls AugmentDataset.
