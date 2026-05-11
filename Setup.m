% Бустинг пилотов
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
Common.NumWorkers      = 4;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'PilotBoosting';
Common.SaveFileName    = 'EPA5_16QAM_IdeadEq';
% End of Params

% EPA5 пилотная оценка канала
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
Common.NumWorkers      = 4;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'PilotBoosting';
Common.SaveFileName    = 'EPA5_16QAM_PilotEq';
% End of Params

% EPA5 пилотная оценка канала | Буст 1.5
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
Sig.PilotBoost         = 1.5;

BER.h2dBInit           = 0;
BER.h2dBInitStep       = 1;
BER.h2dBMaxStep        = 2;
BER.h2dBMinStep        = 0.5;
BER.h2dBMax            = 25;
Common.NumWorkers      = 4;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'PilotBoosting';
Common.SaveFileName    = 'EPA5_16QAM_PilotEq_Boost_1.5';
% End of Params

% EPA5 пилотная оценка канала | Буст 1.5
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
Sig.PilotBoost         = 1.5;

BER.h2dBInit           = 0;
BER.h2dBInitStep       = 1;
BER.h2dBMaxStep        = 2;
BER.h2dBMinStep        = 0.5;
BER.h2dBMax            = 25;
Common.NumWorkers      = 4;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'PilotBoosting';
Common.SaveFileName    = 'EPA5_16QAM_PilotEq_Boost_1.5';
% End of Params

% EPA5 пилотная оценка канала | Буст 2
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
Sig.PilotBoost         = 2;

BER.h2dBInit           = 0;
BER.h2dBInitStep       = 1;
BER.h2dBMaxStep        = 2;
BER.h2dBMinStep        = 0.5;
BER.h2dBMax            = 25;
Common.NumWorkers      = 4;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'PilotBoosting';
Common.SaveFileName    = 'EPA5_16QAM_PilotEq_Boost_2';
% End of Params

% EPA5 пилотная оценка канала | Буст 2.5
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
Sig.PilotBoost         = 2.5;

BER.h2dBInit           = 0;
BER.h2dBInitStep       = 1;
BER.h2dBMaxStep        = 2;
BER.h2dBMinStep        = 0.5;
BER.h2dBMax            = 25;
Common.NumWorkers      = 4;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'PilotBoosting';
Common.SaveFileName    = 'EPA5_16QAM_PilotEq_Boost_2.5';
% End of Params

% EPA5 пилотная оценка канала | Буст 3
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
Sig.PilotBoost         = 3;

BER.h2dBInit           = 0;
BER.h2dBInitStep       = 1;
BER.h2dBMaxStep        = 2;
BER.h2dBMinStep        = 0.5;
BER.h2dBMax            = 25;
Common.NumWorkers      = 4;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'PilotBoosting';
Common.SaveFileName    = 'EPA5_16QAM_PilotEq_Boost_3';
% End of Params

% EPA5 пилотная оценка канала | Буст 3.5
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
Sig.PilotBoost         = 3.5;

BER.h2dBInit           = 0;
BER.h2dBInitStep       = 1;
BER.h2dBMaxStep        = 2;
BER.h2dBMinStep        = 0.5;
BER.h2dBMax            = 25;
Common.NumWorkers      = 4;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'PilotBoosting';
Common.SaveFileName    = 'EPA5_16QAM_PilotEq_Boost_3.5';
% End of Params

% EPA5 пилотная оценка канала | Буст 4
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
Sig.PilotBoost         = 4;

BER.h2dBInit           = 0;
BER.h2dBInitStep       = 1;
BER.h2dBMaxStep        = 2;
BER.h2dBMinStep        = 0.5;
BER.h2dBMax            = 25;
Common.NumWorkers      = 4;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'PilotBoosting';
Common.SaveFileName    = 'EPA5_16QAM_PilotEq_Boost_4';
% End of Params

% EPA5 пилотная оценка канала | Буст 4.5
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
Sig.PilotBoost         = 4.5;

BER.h2dBInit           = 0;
BER.h2dBInitStep       = 1;
BER.h2dBMaxStep        = 2;
BER.h2dBMinStep        = 0.5;
BER.h2dBMax            = 25;
Common.NumWorkers      = 4;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'PilotBoosting';
Common.SaveFileName    = 'EPA5_16QAM_PilotEq_Boost_4.5';
% End of Params

% EPA5 пилотная оценка канала | Буст 5
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
Sig.PilotBoost         = 5;

BER.h2dBInit           = 0;
BER.h2dBInitStep       = 1;
BER.h2dBMaxStep        = 2;
BER.h2dBMinStep        = 0.5;
BER.h2dBMax            = 25;
Common.NumWorkers      = 4;
Common.NumOneIterFrames = 120;
Common.SaveDirName     = 'PilotBoosting';
Common.SaveFileName    = 'EPA5_16QAM_PilotEq_Boost_5';
% End of Params