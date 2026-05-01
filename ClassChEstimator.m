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
            % Собираю кадр 
                RxFrame = reshape(RxSignal(:), ...
                    obj.NumFFT + obj.LenCP, obj.LenFrame);

            % Выделяю активные поднесущие
                activeIdx = obj.NumGI + 1 : obj.NumFFT - obj.NumGI;

            % Переиндексирую пилоты в координаты активной сетки
                pIdxLocal      = obj.pIdx      - obj.NumGI;
                pIdxShiftLocal = obj.pIdxShift - obj.NumGI;

            % Хранение оценок H на пилотных символах 
                NumPilotSyms = length(obj.pilotFlags);
                H_at_pilot_syms = zeros(obj.NumSC, NumPilotSyms);

            % LS-оценка и интерполяция по частоте
                for ps = 1 : NumPilotSyms
                    symIdx = obj.pilotFlags(ps);

                    % FFT принятного пилотного символа
                        Sym   = RxFrame(obj.LenCP + 1 : end, symIdx);
                        fdSym = fftshift( fft(Sym) ) / sqrt(obj.NumFFT);
                        fdAct = fdSym(activeIdx);

                    % Определяю позиции пилотов и переданные значения
                        startIdx = (ps - 1) * obj.NumPCperSym + 1;
                        endIdx   =  ps      * obj.NumPCperSym;
                        txPilots = obj.PilotSyms(startIdx : endIdx);

                        if ismember(symIdx, obj.PilotNumbersOdd)
                            pPosLocal = pIdxLocal;
                        else
                            pPosLocal = pIdxShiftLocal;
                        end

                    % LS-оценка на пилотных позициях 
                        H_LS = fdAct(pPosLocal) ./ txPilots;

                    % Линейная интерполяция по частоте на все NumSC
                        H_at_pilot_syms(:, ps) = interp1( ...
                            pPosLocal, H_LS, 1:obj.NumSC, ...
                            'linear', 'extrap').';
                end

            % Интерполяция по времени 
                H = interp1( ...
                    obj.pilotFlags, H_at_pilot_syms.', 1:obj.LenFrame, ...
                    'linear', 'extrap').';
        end
    end
end