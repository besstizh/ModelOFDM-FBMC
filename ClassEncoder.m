classdef ClassEncoder < handle
    properties (SetAccess = private) % Переменные из параметров
        % Нужно ли выполнять кодирование и декодирование
            isTransparent;
        % Переменная управления языком вывода информации для пользователя
            LogLanguage;
        % Длина потока после кодирования
            LenEncBits;
        % Количество бит для информационных поднесущих в одном кадре 
            NumBits4DC;
            R;
            isSoftInput;
    end
    properties (SetAccess = private) % Вычисляемые переменные
    end
    methods
        function obj = ClassEncoder(Params, LogLanguage) % Конструктор
            % Выделим поля Params, необходимые для инициализации
                Encoder  = Params.Encoder;
            % Инициализация значений переменных из параметров
                obj.isTransparent = Encoder.isTransparent;
            if ~Params.Encoder.isTransparent
            % Длина потока после кодирования
                obj.LenEncBits    = Encoder.LenEncBits;
            end
            % Количество бит для информационных поднесущих в одном кадре 
                obj.NumBits4DC    = Encoder.NumBits4DC;
                obj.R = Encoder.R; 
            % Переменная LogLanguage
                obj.LogLanguage   = LogLanguage;
                obj.isSoftInput = Encoder.isSoftInput; 

        end
        function OutData = StepTx(obj, InData)
            if obj.isTransparent
                OutData = InData;
                return
            end
            
            EncodedBits = lteConvolutionalEncode( InData );
            OutData  = ...
                lteRateMatchConvolutional(EncodedBits, obj.NumBits4DC);
        end
        function OutData = StepRx(obj, InData)
            if obj.isTransparent
                OutData = InData;
                return
            end
            if obj.isSoftInput
                LLR = InData;
            else
                LLR = 2 * double(InData) - 1; 
            end
            DeRMOut = lteRateRecoverConvolutional(LLR, obj.LenEncBits); % 3 * len(DataBits)
            OutData = lteConvolutionalDecode( DeRMOut ); 
        end
    end
end