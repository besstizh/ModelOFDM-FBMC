% % %% OFDM 
% Mapper.isTransparent      = false;
% Encoder.isTransparent     = false;
% Interleaver.isTransparent = false;
% Channel.isTransparent     = false;
% Channel.Type              = 'AWGN';
% Mapper.ModulationOrder    = 16;
% Mapper.DecisionMethod     = 'Approximate log-likelihood ratio';
% ChEstimator.isTransparent = true;
% Equalizer.isTransparent   = true;
% Sig.WaveformType          = 'OFDM';
% Sig.OverlapFactor         = 4;
% Sig.PrototypeFilter       = 'IOTA';
% 
% BER.h2dBInit           = -5;
% BER.h2dBInitStep       = 0.5;
% BER.h2dBMaxStep        = 1;
% BER.h2dBMinStep        = 0.1;
% BER.h2dBMax            = 25;
% Common.NumWorkers       = 6;
% Common.NumOneIterFrames = 120;
% Common.SaveDirName      = 'Bufer_OFDM_FBMC';
% Common.SaveFileName     = 'OFDM_AWGN';
% % End of Params

%% FBMC 
% AWGN
Mapper.isTransparent      = false;
Encoder.isTransparent     = false;
Interleaver.isTransparent = false;
Channel.isTransparent     = true;
Channel.Type              = 'AWGN';
Mapper.ModulationOrder    = 16;
Mapper.DecisionMethod     = 'Approximate log-likelihood ratio';
ChEstimator.isTransparent = true;
Equalizer.isTransparent   = true;
Sig.WaveformType          = 'FBMC';
Sig.OverlapFactor         = 4;
Sig.PrototypeFilter       = 'IOTA';

BER.h2dBInit           = 0;
BER.h2dBInitStep       = 1;
BER.h2dBMaxStep        = 2;
BER.h2dBMinStep        = 0.1;
BER.h2dBMax            = 20;
Common.NumWorkers       = 6;
Common.NumOneIterFrames = 120;
Common.SaveDirName      = 'Bufer_OFDM_FBMC';
Common.SaveFileName     = 'FBMC_AWGN';

