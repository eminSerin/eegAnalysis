function [] = plot_aveTF()
%   PLOT_AVETF creates figures for average plot, signal to noise ratio and
%   time-frequency representation from given participants' analyzed data
%   structure. 
%
%   Usage: 
%   [] = plot_aveTF();
% 
%   Please select mat file using pop-up window (multiple selection is
%   possible). The .mat file must include participant's data of same
%   condition created using calculate_fftSNR function.
%
%   plot_aveTF saves pdf file of average plots in the input directory.
%
%   Author: Emin Serin / Berlin School of Mind and Brain
%
%% Load files.
[files, path] = uigetfile('.mat','Please load .mat eeg datafile',...
    'MultiSelect','on');

if ischar(files)
    nfile = 1;
else
    nfile = length(files);
end

%% Process loop.
for t = 1 : nfile
    if nfile ~= 1
        cfile = files{t};
    else
        cfile = files;
    end
    
    load(cfile);
    outputfilename = cfile(1:end-4);
    
    % Take Average.
    for d = 1 : numel(ft)
        ave.power(d,:) = mean(mean(ft(d).power,1),3);
        ave.snr(d,:) = mean(mean(ft(d).snr,1),3);
        ave.ersp(d,:,:) = ft(d).ft.ersp;
    end
    ave = structfun(@(x) mean(x,1), ave,'UniformOutput',false);
    
    % Plot Power
    fig = figure;
    subplot(2,2,1);
    plot(freqList,ave.power);
    title(['Power Spectrum Density (mean Occipital channels)']);
    xlim([2 freqList(end)])
    ymax = ceil(max(ave.power));
    ylim([-0.2 ymax+ymax/10])
    set(gca,'XTick',(0:1:freqList(end)))
    set(gca,'YTick',(-0.2:ymax/10:ymax))
    xlabel('Freq (Hz)', 'FontSize',10);
    ylabel('Amplitude (mV^2)', 'FontSize',10);
    
    % Plot SNR
    subplot(2,2,2);
    plot(freqList, ave.snr);
    title(['Signal to noise ratio (mean Occipital channels)']);
    xlim([2 freqList(end)])
    ymax = ceil(max(ave.snr));
    ylim([0.2 ymax+ymax/10])
    set(gca,'XTick',(0:1:freqList(end)))
    set(gca,'YTick',(0.2:ymax/10:ymax))
    xlabel('Freq (Hz)', 'FontSize',10)
    ylabel('SNR', 'FontSize',10)
    
    % Plot time-frequency
    subplot(2,2,[3,4])
    imagesc(ft(1).ft.times,ft(1).ft.freqs,squeeze(ave.ersp),[0 4]);
    title(['Time Frequency Representation (Channels Averaged)'],'FontSize',10);
    xlabel('Time (ms)','FontSize',10)
    ylabel('Frequency (Hz)','FontSize',10)
    set(gca,'Ydir','normal');
    colormap jet;
    cb = colorbar;
    title(cb,'ERSP (dB)')
    
    % Save pdf file.
    fig.PaperPositionMode = 'manual';
    orient(fig,'landscape')
    print(fig,'-dpdf', [path outputfilename,'.pdf'])
end
end

