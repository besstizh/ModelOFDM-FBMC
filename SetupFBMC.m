%% OFDM 
% EPA5 идеальная оценка канала
Mapper.isTransparent   = false;
Encoder.isTransparent  = false;
Interleaver.isTransparent = false;
Channel.isTransparent  = false;
Channel.Type           = 'Fading';
Channel.FadingType     = 'EPA';
Channel.DopplerFreq    = 5;
Mapper.ModulationOrder = 16;
Mapper.DecisionMethod  = 'Approximate log-likelihood ratio';
ChEstimator.isTransparent = false;
ChEstimator.Type       = 'Ideal';
Equalizer.isTransparent = false;
Equalizer.Type         = 'ZF';

BER.h2dBInit           = 0;
BER.h2dBInitStep       = 1;
BER.h2dBMaxStep        = 2;
BER.h2dBMinStep        = 0.5;
BER.h2dBMax            = 25;
Common.NumWorkers      = 6;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'Bufer_OFDM_FBMC';
Common.SaveFileName    = 'EPA5_16QAM_IdeadEq';
% End of Params

%% FBMC 
% AWGN
Mapper.isTransparent      = false;
Encoder.isTransparent     = false;
Interleaver.isTransparent = false;
Channel.isTransparent     = false;
Channel.Type              = 'AWGN';
Mapper.ModulationOrder    = 16;
Mapper.DecisionMethod     = 'Approximate log-likelihood ratio';
ChEstimator.isTransparent = true;
Equalizer.isTransparent   = true;
Sig.WaveformType          = 'FBMC';
Sig.OverlapFactor         = 4;
Sig.PrototypeFilter       = 'IOTA';

BER.h2dBInit            = 10;
BER.h2dBInitStep        = 5;
BER.h2dBMax             = 25;
Common.NumWorkers       = 6;
Common.NumOneIterFrames = 120;
Common.SaveDirName      = 'Bufer_OFDM_FBMC';
Common.SaveFileName     = 'FBMC_AWGN_test';