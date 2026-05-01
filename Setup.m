% % AWGN LLR
% Mapper.isTransparent   = false;
% Encoder.isTransparent  = false;
% Interleaver.isTransparent = false;
% Channel.isTransparent  = false;
% Channel.Type           = 'AWGN';
% Mapper.ModulationOrder = 16;
% Mapper.DecisionMethod  = 'Approximate log-likelihood ratio';
% 
% BER.h2dBInit           = 0;
% BER.h2dBInitStep       = 1;
% BER.h2dBMaxStep        = 2;
% BER.h2dBMinStep        = 0.5;
% BER.h2dBMax            = 20;
% 
% Common.NumWorkers      = 6;
% Common.NumOneIterFrames = 120;
% Common.SaveDirName     = 'AWGN_Results';
% Common.SaveFileName    = 'OFDM_AWGN_16QAM_LLR';
% % End of Params
% 
% % AWGN HD
% Mapper.isTransparent   = false;
% Encoder.isTransparent  = false;
% Interleaver.isTransparent = false;
% Channel.isTransparent  = false;
% Channel.Type           = 'AWGN';
% Mapper.ModulationOrder = 16;
% Mapper.DecisionMethod  = 'Hard decision';
% 
% BER.h2dBInit           = 0;
% BER.h2dBInitStep       = 1;
% BER.h2dBMaxStep        = 2;
% BER.h2dBMinStep        = 0.5;
% BER.h2dBMax            = 20;
% 
% Common.NumWorkers      = 6;
% Common.NumOneIterFrames = 120;
% Common.SaveDirName     = 'AWGN_Results';
% Common.SaveFileName    = 'OFDM_AWGN_16QAM_HD';
% % End of Params
% 
% % AWGN Enc Off 
% Mapper.isTransparent   = false;
% Encoder.isTransparent  = true;
% Interleaver.isTransparent = false;
% Channel.isTransparent  = false;
% Channel.Type           = 'AWGN';
% Mapper.ModulationOrder = 16;
% Mapper.DecisionMethod  = 'Hard decision';
% 
% BER.h2dBInit           = 0;
% BER.h2dBInitStep       = 1;
% BER.h2dBMaxStep        = 2;
% BER.h2dBMinStep        = 0.5;
% BER.h2dBMax            = 20;
% 
% Common.NumWorkers      = 6;
% Common.NumOneIterFrames = 120;
% Common.SaveDirName     = 'AWGN_Results';
% Common.SaveFileName    = 'OFDM_AWGN_16QAM_EncOff';
% % End of Params
% 
% % AWGN Enc Off Int Off
% Mapper.isTransparent   = false;
% Encoder.isTransparent  = true;
% Interleaver.isTransparent = true;
% Channel.isTransparent  = false;
% Channel.Type           = 'AWGN';
% Mapper.ModulationOrder = 16;
% Mapper.DecisionMethod  = 'Hard decision';
% 
% BER.h2dBInit           = 0;
% BER.h2dBInitStep       = 1;
% BER.h2dBMaxStep        = 2;
% BER.h2dBMinStep        = 0.5;
% BER.h2dBMax            = 20;
% 
% Common.NumWorkers      = 6;
% Common.NumOneIterFrames = 120;
% Common.SaveDirName     = 'AWGN_Results';
% Common.SaveFileName    = 'OFDM_AWGN_16QAM_EncOff_IntOff';
% % End of Params


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
ChEstimator.Type       = 'Pilots';
Equalizer.isTransparent = false;
Equalizer.Type         = 'ZF';

BER.h2dBInit           = 0;
BER.h2dBInitStep       = 1;
BER.h2dBMaxStep        = 2;
BER.h2dBMinStep        = 0.5;
BER.h2dBMax            = 25;
Common.NumWorkers      = 6;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'Fading_Results';
Common.SaveFileName    = 'OFDM_EPA5_16QAM_PilotsEq';
% End of Params

% % EVA70 Идеальная оценка канала
% Mapper.isTransparent   = false;
% Encoder.isTransparent  = false;
% Interleaver.isTransparent = false;
% Channel.isTransparent  = false;
% Channel.Type           = 'Fading';
% Channel.FadingType     = 'EVA';
% Channel.DopplerFreq    = 70;
% Mapper.ModulationOrder = 16;
% Mapper.DecisionMethod  = 'Approximate log-likelihood ratio';
% ChEstimator.isTransparent = false;
% ChEstimator.Type       = 'Ideal';
% Equalizer.isTransparent = false;
% Equalizer.Type         = 'ZF';
% 
% BER.h2dBInit           = 0;
% BER.h2dBInitStep       = 1;
% BER.h2dBMaxStep        = 2;
% BER.h2dBMinStep        = 0.5;
% BER.h2dBMax            = 25;
% Common.NumWorkers      = 6;
% Common.NumOneIterFrames = 120;
% Common.SaveDirName     = 'Fading_Results';
% Common.SaveFileName    = 'OFDM_EVA70_16QAM_IdealEq';
% % End of Params
% 
% % ETU300 Идеальная оценка канала
% Mapper.isTransparent   = false;
% Encoder.isTransparent  = false;
% Interleaver.isTransparent = false;
% Channel.isTransparent  = false;
% Channel.Type           = 'Fading';
% Channel.FadingType     = 'ETU';
% Channel.DopplerFreq    = 300;
% Mapper.ModulationOrder = 16;
% Mapper.DecisionMethod  = 'Approximate log-likelihood ratio';
% ChEstimator.isTransparent = false;
% ChEstimator.Type       = 'Ideal';
% Equalizer.isTransparent = false;
% Equalizer.Type         = 'ZF';
% 
% BER.h2dBInit           = 0;
% BER.h2dBInitStep       = 1;
% BER.h2dBMaxStep        = 2;
% BER.h2dBMinStep        = 0.5;
% BER.h2dBMax            = 25;
% Common.NumWorkers      = 6;
% Common.NumOneIterFrames = 120;
% Common.SaveDirName     = 'Fading_Results';
% Common.SaveFileName    = 'OFDM_ETU300_16QAM_IdealEq';
% % End of Params