classdef ClassSigFBMC < handle
    properties (SetAccess = private) % Переменные из параметров
        isTransparent;
        NumFFT;
        NumSC;
        LenCP;         % в случае FBMC этот параметр всегда 0
        LenFrame;      % Число FBMC-символов в кадре, K
        StepPC;
        PilotModOrder;
        PilotBoost;
        OverlapFactor;   % M 
        PrototypeFilter; % имя фильтра
        LogLanguage; 
    end
    properties (SetAccess = private) % Вычисляемые переменные
        NumGI;
        NumPCperSym;
        PilotNumbersOdd;
        PilotNumbersEven;
        pilotFlags;
        CutNumDCperSym;
        pIdx;       % индексы пилотных поднесущих без сдвига
        pIdxShift;  % индексы пилотных поднесущих со сдвигом
        PilotSyms;  % эталонные пилотные символы
        PilotAmp;
        DataAmpOnPilotSym;

        % Непосрественно для FBMC
        FilterTaps;      % отчеты прототипного фильтра, длина M * NumFFT
        FrameLenSamples; % общая длина FBMC-кадра в отсчетах: (K + M - 1) * NumFFT
    end
    methods
        function obj = ClassSigFBMC(Params, LogLanguage)
            Sig = Params.Sig;

            % Инициализация значений переменных из параметров
                obj.isTransparent      = Sig.isTransparent;
                obj.NumFFT             = Sig.NumFFT;
                obj.NumSC              = Sig.NumSC;
                obj.LenCP              = 0; % !!!
                obj.LenFrame           = Sig.LenFrame;
                obj.StepPC             = Sig.StepPC;
                obj.PilotModOrder      = Sig.PilotModOrder;
                obj.PilotBoost         = Sig.PilotBoost;
                obj.OverlapFactor      = Sig.OverlapFactor;
                obj.PrototypeFilter    = Sig.PrototypeFilter;
                obj.LogLanguage        = LogLanguage;

            % Вычисляемые параметры 
                obj.NumGI = Sig.NumGI;
                obj.NumPCperSym      = Sig.NumPCperSym;
                obj.PilotNumbersOdd  = Sig.PilotNumbersOdd;
                obj.PilotNumbersEven = Sig.PilotNumbersEven;
                obj.pilotFlags       = Sig.pilotFlags;
                obj.CutNumDCperSym   = Sig.CutNumDCperSym;

            % Индексы пилотных поднесущих 
                obj.pIdx      = (obj.NumGI + 1) : Sig.StepPC : ...
                                (obj.NumGI + Sig.NumSC);
                obj.pIdxShift = (obj.NumGI + 4) : Sig.StepPC : ...
                                (obj.NumGI + Sig.NumSC);

            % Генерация пилотных символов через m-последовательность
                NumBits4PC = Sig.NumBits4PC;
                LenMLseq   = 2^10 - 1;
                while LenMLseq < NumBits4PC
                    LenMLseq = ( LenMLseq + 1 ) * 2 - 1;
                end
                mseq          = mlseq( LenMLseq );
                PilotBits     = ( mseq( 1 : NumBits4PC ) + 1 ) / 2;
                obj.PilotSyms = qammod( PilotBits, obj.PilotModOrder, ...
                                    'InputType', 'bit' );

            % Расчет амплитуд для буста пилотов 
                % Коэффициент мощности пилотов 
                    beta  = obj.PilotBoost;
                    Np    = obj.NumPCperSym;
                    Nd    = obj.CutNumDCperSym;
                % Компенсирующий коэффициент мощности данных 
                    alpha = 1 - Np * (beta - 1) / Nd;

                    if alpha <= 0
                        error(['ClassSig: слишком большой PilotBoost (%g)' ...
                            'Для текущих NumPCperSym=%d и CutNumDCperSym=%d ' ...
                            'максимально допустимый PilotBoost < %g.'], beta, Np, Nd, 1 + Nd/Np);
                    end
                    obj.PilotAmp          = sqrt(beta);
                    obj.DataAmpOnPilotSym = sqrt(alpha);

            % Загрузка прототипного фильтра 
                obj.FilterTaps = obj.loadFilter(); % !!!

            % Длина FBMC кадра в отсчетах
            % (K - 1) * NumFFT
            % Но если есть сдвиги, то еще + M*NumFFT на последний символ
                obj.FrameLenSamples = ...
                    (obj.LenFrame + obj.OverlapFactor - 1) * obj.NumFFT;
        end

        function OutData = StepTx(obj, InData)
            if obj.isTransparent
                OutData = InData;
                return;
            end

            % === Формирование K штук OFDM спектров без CP ===
            % Спектры собираются в матрицу [NumFFT, LenFrame]
                Spectrum = zeros(obj.NumFFT, obj.LenFrame);
                Pntr     = 1;
                pFlagIdx = 1;

                for symIdx = 1 : obj.LenFrame
                    SymSpec = zeros(obj.NumFFT, 1);

                    if ismember(symIdx, obj.pilotFlags)
                        % Раскладка пилотов 
                            startIdx = (pFlagIdx - 1) * obj.NumPCperSym + 1;
                            endIdx   =  pFlagIdx      * obj.NumPCperSym;

                            if ismember(symIdx, obj.PilotNumbersOdd)
                                SymSpec(obj.pIdx) = ...
                                    obj.PilotAmp * obj.PilotSyms(startIdx : endIdx);
                            else
                                SymSpec(obj.pIdxShift) = ...
                                    obj.PilotAmp * obj.PilotSyms(startIdx : endIdx);
                            end
                        % Заполнение данных с компенсацией
                            allIdx  = obj.NumGI + 1 : obj.NumFFT - obj.NumGI;
                            freeIdx = allIdx( SymSpec (allIdx) == 0 );
                            SymSpec( freeIdx ) = obj.DataAmpOnPilotSym * ...
                                InData( Pntr : Pntr + obj.CutNumDCperSym - 1 );

                            pFlagIdx = pFlagIdx + 1;
                            Pntr = Pntr + obj.NumSC;
                    end   

                    Spectrum(:, symIdx) = SymSpec;
                end

            % === Формирование FBMC-кадра === 
            % Для каждого OFDM спектра:
            % 1. IFFT с восстановлением порядка (аналогично OFDM, но без CP)
            % 2. Повтор M раз. Тогда длительность M * NumFFT
            % 3. Умножение на прототипный фильтр
            % 4. Сложение с предыдущими символами, сдвигаясь на NumFFT
                Frame = zeros(1, obj.FrameLenSamples);

                for symIdx = 1 : obj.LenFrame
                    % IFFT 
                        tdSym = ifft( ifftshift( Spectrum(:, symIdx) ) ) * ...
                            sqrt(obj.NumFFT);
                    
                    % Повтор M раз 
                        tdLong = repmat(tdSym, obj.OverlapFactor, 1);

                    % Умножение на прототипный фильтр
                        fbmcSym = tdLong .* obj.FilterTaps;

                    % Размещение в кадре со сдвигом 
                        offset = (symIdx - 1) * obj.NumFFT;
                        idx    = offset + 1 : ...
                                 offset + obj.OverlapFactor * obj.NumFFT; 
                        Frame(idx) = Frame(idx) + fbmcSym.';
                end

            OutData = Frame;
        end

        function [OutData, NoiseVar] = StepRx(obj, InData, NoiseVarIn) %#ok<INUSD>
            error('ClassSigFBMC.StepRx: не реализован');
        end
    end

    methods (Access = private)
        function taps = loadFilter(obj)
            switch obj.PrototypeFilter
                case 'IOTA'
                    taps = obj.generateIOTA();
                otherwise
                    error('Неизвестный PrototypeFilter: %s', obj.PrototypeFilter);
            end
        end

        function taps = generateIOTA(obj)
            % Заглушка нужна, но отсутсвует 
        end
    end
end