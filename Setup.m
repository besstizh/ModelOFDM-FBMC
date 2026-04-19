

% % EVA 70
% Mapper.isTransparent = false;
% Channel.isTransparent = false;
% Channel.Type = 'Fading';
% Channel.FadingType = 'EVA';
% Channel.DopplerFreq = 70;
% Mapper.ModulationOrder = 16;
% Mapper.DecisionMethod = 'Approximate log-likelihood ratio';
% Sig.isTransparent = false;
% Encoder.isTransparent = false;
% Interleaver.isTransparent = false;
% 
% BER.h2dBInit = 0;
% BER.h2dBInitStep = 1;
% BER.h2dBMaxStep  = 2;
% BER.h2dBMinStep  = 0.5;
% BER.h2dBMax      = 20;
% 
% Common.NumWorkers = 6;
% Common.NumOneIterFrames = 120;
% 
% Common.SaveFileName = 'OFDM_EVA70_16QAM_LLR';
% % End of Params

% % ETU300
% Mapper.isTransparent = false;
% Channel.isTransparent = false;
% Channel.Type = 'Fading';
% Channel.FadingType = 'ETU';
% Channel.DopplerFreq = 300;
% Mapper.ModulationOrder = 16;
% Mapper.DecisionMethod = 'Approximate log-likelihood ratio';
% Sig.isTransparent = false;
% Encoder.isTransparent = false;
% Interleaver.isTransparent = false;
% 
% BER.h2dBInit = 0;
% BER.h2dBInitStep = 1;
% BER.h2dBMaxStep  = 2;
% BER.h2dBMinStep  = 0.5;
% BER.h2dBMax      = 20;
% 
% Common.NumWorkers = 6;
% Common.NumOneIterFrames = 120;
% 
% Common.SaveFileName = 'OFDM_ETU300_16QAM_LLR';
% % End of Params
% 
% % EPA 5
% Mapper.isTransparent = false;
% Channel.isTransparent = false;
% Channel.Type = 'Fading';
% Channel.FadingType = 'EPA';
% Channel.DopplerFreq = 5;
% Mapper.ModulationOrder = 16;
% Mapper.DecisionMethod = 'Approximate log-likelihood ratio';
% Sig.isTransparent = false;
% Encoder.isTransparent = false;
% Interleaver.isTransparent = false;
% 
% BER.h2dBInit = 0;
% BER.h2dBInitStep = 1;
% BER.h2dBMaxStep  = 2;
% BER.h2dBMinStep  = 0.5;
% BER.h2dBMax      = 20;
% 
% Common.NumWorkers = 6;
% Common.NumOneIterFrames = 120;
% 
% Common.SaveFileName = 'OFDM_EPA5_16QAM_LLR';
% % End od Params


Mapper.isTransparent = false;
Channel.isTransparent = false;   
Mapper.ModulationOrder = 16;
Mapper.DecisionMethod = 'Hard decision';
Sig.isTransparent = false;
Encoder.isTransparent = true;
Interleaver.isTransparent = true;

BER.h2dBInit = 0;
BER.h2dBInitStep = 1;
BER.h2dBMaxStep  = 2;
BER.h2dBMinStep  = 0.5;
BER.h2dBMax      = 20;

Common.NumWorkers = 1;
% Common.NumOneIterFrames = 240;

Common.SaveFileName = 'OFDM_AWGN_16QAM_EncOff_IntOff';
% End of Params

