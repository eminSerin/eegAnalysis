function [TFdata,freqs] = waveletTransform(EEG,minF,maxF,varCycle,nCycle)
%   WAVELETTRANSFORM performs time frequency analysis on EEG data using
%   Morlet wavelets. 
%   
%   It requires EEG structure that created by EEGLAB and returns time
%   frequency data structure and frequency vector.
%
%   Also can perform wavelet analysis using either fixed wavelet cycle or
%   multiple cycles varied for each frequencies (lower cycles for lower
%   frequencies, higher cycles for higher frequencies).
%
%   Usage: TFdata = do_waveletAnalysis(EEG,minF,maxF,varCycle, nCycle) 
%   TFdata = do_waveletAnalysis(EEG,1,25,true,7)
%
%   Output structure format: electrodes x dataBins x frequencies
%
%   Emin Serin - Berlin School of Mind and Brain

%% Precomputation
% Default values.
if nargin < 1
    help waveletTransform
elseif nargin < 5
    % Default values if nCycle is not entered. 
    if ~varCycle
        nCycle = 7;
    else
        rangeCycle = [4,10];
    end
end
     
% Frequencies.
fSteps = (maxF-minF+1); % frequency resolution.
freqs = linspace(minF,maxF,fSteps); % family of frequencies.

% Set some parameters.
sampR = EEG.srate; % in hz
waveT  = -1:1/sampR:1; % best practice is to have time=0 at the center of the wavelet
halfWave = (length(waveT)-1) / 2; % length of half wave. 

% Convolution parameters.
nWave = length(waveT); % wavelet length. 
nData = EEG.pnts * EEG.trials; % data length. 
nConv = nData + nWave - 1; % convulation length.

% Variable cycle or fixed cycle.
if varCycle
    % variable wavelet cycle. 
    nCycles = logspace(log10(rangeCycle(1)),log10(rangeCycle(2)),fSteps);
else
    % fixed wavelet cycle
    nCycles = repmat(nCycle,1,fSteps);
end

%% Convulation. 
tic;
TFdata = zeros(size(EEG.data,1),size(EEG.data,2),fSteps); % pre-allocate tf data.
for chan = 1: size(EEG.data,1)
    cData = reshape(EEG.data(chan,:,:),1,[]);
    dataX = fft(cData, nConv);
    for f = 1: length(freqs)
        % Create morlet wavelet and do FFT. 
        wavelet  = exp(2*1i*pi*freqs(f).*waveT)...
            .* exp(-waveT.^2./(2*(nCycles(f) / (2*pi*freqs(f)))^2));
        waveletX = fft(wavelet,nConv); % FFT.
        waveletX = waveletX ./ max(waveletX); % normalize scale.    
        
        % now for convolution...
        convDataTF = ifft(dataX .* waveletX);
        convDataTF = convDataTF(halfWave+1:end-halfWave);
        
        % reshape and average. 
        convDataTF = reshape(convDataTF,EEG.pnts,EEG.trials);
        TFdata(chan,:,f) = mean(abs(convDataTF).^2,2);
    end
end
toc;

end

