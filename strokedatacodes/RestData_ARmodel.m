clc
clear all
close all

% addpath 'F:'
DatafolderPath = '..\StrokeData\NewData\';
% NewDatafolder = 'F:\StrokeData\filterddatanew\';
% addpath 'D:\EMG detectors\detectors_review_paper'

contents = dir(DatafolderPath);
subfolders = contents([contents.isdir]);
subfolders = subfolders(~ismember({subfolders.name}, {'.', '..'}));
plotflag = 0;

%% Notch filter design
fs = 500;
fo = 50;
q = 35;
bw = (fo/(fs/2))/q;
[b1,a1] = iircomb(fs/fo,bw,'notch'); % Note type flag 'notch'

%% High pass filter
fc = 10;
[b2,a2]   = butter(2,fc/(fs/2),'high');

tr = 1;
for l = 1:length(subfolders)
    PatientfolderName = subfolders(l).name;
    Foldcontents = dir(fullfile(DatafolderPath,  PatientfolderName));
    sessionfolders = Foldcontents([Foldcontents.isdir]);
    sessionfolders = sessionfolders(~ismember({sessionfolders.name}, {'.', '..'}));   
    for m = 1:length(sessionfolders)           
         folderPath = fullfile(DatafolderPath,  PatientfolderName, sessionfolders(m).name );
          files = dir(fullfile(folderPath, '*.mat')); 
          if isempty(files) == 0 
             filePath = fullfile(folderPath, files(1).name);
                EMGdata = load(filePath);
                fieldList = fieldnames(EMGdata);
                EMGdata.finalEMGdata = EMGdata.(fieldList{1});
                for k = 1:size(EMGdata.finalEMGdata,2)
                    
                    %% Notch filter
                    EMGfilterdata = filter(b1,a1,EMGdata.finalEMGdata{1,k}.data);
                    
                    rawdata_rest = EMGfilterdata(1:2001);
                    %% AR_Model
                    %order of AR model
                    p = 5;
                    y = AR_MODEL(rawdata_rest',length(rawdata_rest),length(EMGdata.finalEMGdata{1,k}.data),p,EMGdata.finalEMGdata{1,k}.data);  
                    
                    %% plot
                    if plotflag == 1
                    figure('Position',[9.6667 266.3333 1272 373.3334]);
                    subplot(2,1,1)
                    plot(EMGdata.finalEMGdata{1,k}.filterdata);
                    hold on
                    l1 = xline(2001,'r--');
                    l1.LineWidth = 1.5;
                    hold on
                    l2 = xline(length(EMGdata.finalEMGdata{1,k}.filterdata),'r--');
                    l2.LineWidth = 1;
                    subplot(2,1,2)
                    plot(y);
                    hold on
                    l1 = xline(2001,'r--');
                    l1.LineWidth = 1.5;
                    hold on
                    l2 = xline(length(EMGdata.finalEMGdata{1,k}.filterdata),'r--');
                    l2.LineWidth = 1;
                    title('AR_Estimated','Interpreter','none')
                    sgtitle(strcat('Session',num2str(EMGdata.finalEMGdata{1,k}.session),'_',EMGdata.finalEMGdata{1,k}.file),'Interpreter','none')
                    
                    %% plot frequency plot
%                       fs = 500;
                      Nsamps = length(rawdata_rest);
                      t = (1/fs)*(1:Nsamps);          %Prepare time data for plot
    
                      %%     %Do Fourier Transform
                      Nsamps2 = length(y(2002:end));
                      t2 = (1/fs)*(1:Nsamps);   
                      y_fft = abs(fft(rawdata_rest));  %Retain Magnitude
                      y_fft = y_fft(1:Nsamps/2);      %Discard Half of Points
                      x_fft = abs(fft(y(2002:end)));  
                      x_fft = x_fft(1:Nsamps2/2);         
                      f1 = fs*(0:(Nsamps-2)/2)/Nsamps; %Prepare freq data for plot 
                      f2 = fs*(0:(Nsamps2-2)/2)/Nsamps2; %Prepare freq data for plot 
                      figure
%                       subplot(2,1,1)
                      plot(f1, y_fft,'Color', [0.43, 0.58, 0.85]) 
%                       subplot(2,1,2)
                      hold on
                      plot(f2, x_fft,'Color', [0.8, 0, 0, 0.3])  
                      legend('RestData','ARestimated');
%                       xlim([1 500])
                    
                    %%
                     pause(2);
                     close all;
                    end
                    %% Save  data
                        EMGdata.finalEMGdata{1,k}.Restdata = y;
                        finalfilename = fullfile(folderPath , strcat('Rest',sessionfolders(m).name,'.mat'));
                        save(finalfilename,'EMGdata');  
                end
                clear EMGdata
          end
    end
end