classdef ClassChEstimator < handle
    properties (SetAccess = private)
        isTransparent;
        Type;
        NumFFT;
        NumSC;
        LenCP;
        LenFrame;
        NumGI;
        LogLanguage;

        % Параметры пилотов (для 'Pilots')
        PilotSyms;
        pIdx;
        pIdxShift;
        pilotFlags;
        PilotNumbersOdd;
        PilotNumbersEven;
        NumPCperSym;
    end
    methods
        function obj = ClassChEstimator(Params, Objs, LogLanguage)
            ChEstimator       = Params.ChEstimator;
            obj.isTransparent = ChEstimator.isTransparent;
            obj.Type          = ChEstimator.Type;
            obj.NumFFT        = Objs.Sig.NumFFT;
            obj.NumSC         = Objs.Sig.NumSC;
            obj.LenCP         = Objs.Sig.LenCP;
            obj.LenFrame      = Objs.Sig.LenFrame;
            obj.NumGI         = Objs.Sig.NumGI;
            obj.LogLanguage   = LogLanguage;

            % Параметры пилотов
            obj.PilotSyms        = Objs.Sig.PilotSyms;
            obj.pIdx             = Objs.Sig.pIdx;
            obj.pIdxShift        = Objs.Sig.pIdxShift;
            obj.pilotFlags       = Objs.Sig.pilotFlags;
            obj.PilotNumbersOdd  = Objs.Sig.PilotNumbersOdd;
            obj.PilotNumbersEven = Objs.Sig.PilotNumbersEven;
            obj.NumPCperSym      = Objs.Sig.NumPCperSym;
        end

        function H = Step(obj, RxSignal, InstChannelParams) % TxSignal, FadedSignal)
            if obj.isTransparent
                H = ones(obj.NumSC, obj.LenFrame);
                return;
            end
    
            switch obj.Type
                case 'Ideal'
                    H = obj.estimateIdeal(...
                        InstChannelParams.FadedSignal, ...
                        InstChannelParams.TxSignal);
                case 'Pilots'
                    H = obj.estimatePilots(RxSignal);
                otherwise
                    error('Недопустимое значение ChEstimator.Type: %s', obj.Type);
            end                  
        end
    end

    methods (Access = private)
        function H = estimateIdeal(obj, FadedSignal, TxSignal)
            TxFrame    = reshape(TxSignal(:), ... 
                obj.NumFFT + obj.LenCP, obj.LenFrame);
            FadedFrame = reshape(FadedSignal(:), ... 
                obj.NumFFT + obj.LenCP, obj.LenFrame);

            H = zeros(obj.NumSC, obj.LenFrame);
            scIdxs = obj.NumGI + 1 : obj.NumFFT - obj.NumGI;

            for symIdx = 1 : obj.LenFrame
                TxSym    = TxFrame(obj.LenCP + 1 : end, symIdx);
                FadedSym = FadedFrame(obj.LenCP + 1 : end, symIdx);

                fdTx    = fftshift( fft( TxSym )    ) / sqrt(obj.NumFFT);
                fdFaded = fftshift( fft( FadedSym ) ) / sqrt(obj.NumFFT);

                H(:, symIdx) = fdFaded(scIdxs) ./ fdTx(scIdxs);
            end
        end

        function H = estimatePilots(obj, RxSignal)
            % Пока не реализовано
            error('Стоит обождать маленько');
        end
    end
end