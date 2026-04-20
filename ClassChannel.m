 classdef ClassChannel < handle
    properties (SetAccess = private) % Переменные из параметров
        isTransparent;
        LogLanguage;
        log2M;
        NumFFT;
        Rate;
        Type;
        DelayProfile;
        DopplerFreq;
        SamplingRate;
        MIMOCorrelation;
        Seed;
    end
    properties (SetAccess = private) % Вычисляемые переменные
        % % Значение средней мощности модуляционного символа
        %     Ps;
        % % Значение средней мощности модуляционного бита
        %     Pb;
        % % Значение средней мощности информационного бита
        %     Pbd;
    end
    methods
        function obj = ClassChannel(Params, Objs, LogLanguage)
        % Конструктор
            Channel           = Params.Channel;
            obj.isTransparent = Channel.isTransparent;
            obj.LogLanguage   = LogLanguage;
            obj.log2M         = Objs.Mapper.log2M;

            obj.NumFFT        = Objs.Sig.NumFFT;

            obj.Type            = Channel.Type;
            obj.DelayProfile    = Channel.FadingType;
            obj.DopplerFreq     = Channel.DopplerFreq;
            obj.SamplingRate    = Channel.SamplingRate;    
            obj.MIMOCorrelation = Channel.MIMOCorrelation;
            obj.Seed            = Channel.Seed;

            if Objs.Encoder.isTransparent
                obj.Rate = 1;
            else
                obj.Rate = Objs.Encoder.R;
            end
        % % Определим среднюю мощность модуляционного символа
        %     Const = Objs.Mapper.Constellation;
        %     obj.Ps = mean((abs(Const)).^2);
        % 
        % % Определим среднюю мощность модуляционного бита
        %     obj.Pb = obj.Ps / Objs.Mapper.log2M;
        % 
        %     obj.log2M = Objs.Mapper.log2M;
        %     obj.Rate  = Objs.Encoder.R;
        % 
        % % Определим среднюю мощность информационного бита (энергия,
        % % приходящаяся на информационный бит, оказывается больше, так
        % % как используются проверочные биты)
        %     % obj.Pbd = obj.Pb;
        %     % Когда и если будет реализован класс кодирования, то здесь
        %     % должно будет быть
        %     obj.Pbd = obj.Pb / Objs.Encoder.Rate;
        end
        function [OutData, InstChannelParams] = Step(obj, InData, h2dB)
            if obj.isTransparent
                OutData = InData;
                InstChannelParams.Variance = 1;
                return
            end
             
            % Многолучевость
                if strcmp(obj.Type, 'Fading')
                    cfg.NRxAnts         = 1;
                    cfg.DelayProfile    = obj.DelayProfile;
                    cfg.DopplerFreq     = obj.DopplerFreq;
                    cfg.MIMOCorrelation = obj.MIMOCorrelation;
                    cfg.SamplingRate    = obj.SamplingRate;
                    cfg.InitTime        = 0; % сброс состояния канала
                    cfg.Seed            = obj.Seed;
    
                    FadeSignal = lteFadingChannel(cfg, InData.');
                    InData     = FadeSignal.';
                end

            % Сохранение сигнала до того, как он прошел через шум
                InstChannelParams.FadedSignal = FadeSignal.';

            % Считаем мощность сигнала                
                Ps  = mean(abs(InData).^2);
                Pb  = Ps / obj.log2M;
                Pbd = Pb /  obj.Rate;

            % Сформируем АБГШ
                Sigma = sqrt(Pbd * 10^(-h2dB/10) / 2);
                InstChannelParams.Variance = 2*Sigma^2 / Ps;
                Noise = ( randn( size(InData) ) + 1i * randn( size(InData) ))* Sigma;

            % Добавим его к сигналу
                OutData = InData + Noise;
        end
    end
end