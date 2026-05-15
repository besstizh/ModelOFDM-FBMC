classdef ClassSig < handle
    properties (SetAccess = private) % Переменные из параметров
        isTransparent;
        NumFFT;
        NumSC;
        LenCP;
        LenFrame;
        StepPC;
        PilotModOrder;
        PilotBoost;
        WaveformType;
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
        function obj = ClassSig(Params, LogLanguage) % Конструктор
            % Выделим поля Params, необходимые для инициализации
                Sig  = Params.Sig;

            % Инициализация значений переменных из параметров
                obj.isTransparent      = Sig.isTransparent;
                obj.NumFFT             = Sig.NumFFT;
                obj.NumSC              = Sig.NumSC;
                obj.LenCP              = Sig.LenCP; % 0 для FBMC
                obj.LenFrame           = Sig.LenFrame;
                obj.StepPC             = Sig.StepPC;
                obj.PilotModOrder      = Sig.PilotModOrder;
                obj.PilotBoost         = Sig.PilotBoost;
                obj.WaveformType       = Sig.WaveformType;
                obj.LogLanguage        = LogLanguage;

            % Вычисляемые параметры
                obj.NumGI            = Sig.NumGI;
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


                if strcmp(obj.WaveformType, 'FBMC')
                    obj.OverlapFactor   = Sig.OverlapFactor;
                    obj.PrototypeFilter = Sig.PrototypeFilter;
                    obj.FilterTaps      = obj.loadFilter();
                    obj.FrameLenSamples = ...
                        (obj.LenFrame + obj.OverlapFactor - 1) * obj.NumFFT;
                else
                    obj.OverlapFactor   = 1;
                    obj.PrototypeFilter = '';
                    obj.FilterTaps      = [];
                    obj.FrameLenSamples = (obj.NumFFT + obj.LenCP) * obj.LenFrame;
                end
        end
        function OutData = StepTx(obj, InData)
            if obj.isTransparent
                OutData = InData;
                return
            end
            
            % Формирование спекта - это общая часть у OFDM и FBMC
                Spectrum = obj.buildSpectrum(InData); % [NumFFT, LenFrame]

            % Разветвление на тип сигнала 
                if strcmp(obj.WaveformType, 'FBMC')
                    OutData = obj.assembleOFDMFrame(Spectrum);
                else
                    OutData = obj.assembleFBMCFrame(Spectrum);
                end
        end

        function [OutData, NoiseVar] = StepRx(obj, InData, NoiseVarIn)
            if obj.isTransparent
                OutData = InData;
                return
            end

            % Reshape: столбец - символ OFDM
                RxFrame = ...
                    reshape(InData(:), obj.NumFFT + obj.LenCP, obj.LenFrame);

            % Выделение памяти 
                NumDCperFrame = obj.CutNumDCperSym * length(obj.pilotFlags) + ...
                                obj.NumSC * (obj.LenFrame - length(obj.pilotFlags));
                RxDataSyms    = zeros(NumDCperFrame, 1);
                NoiseVar  = zeros( size( RxDataSyms ) );

                Pntr     = 1;
                pFlagIdx = 1;

            for symIdx = 1 : obj.LenFrame
                % Удаление CP и FFT 
                    Sym   = RxFrame( obj.LenCP + 1 : end, symIdx );
                    fdSym = fftshift( fft( Sym ) ) / sqrt(obj.NumFFT);

                if ismember(symIdx, obj.pilotFlags)
                    allIdx   = obj.NumGI + 1 : obj.NumFFT - obj.NumGI;

                    if ismember(symIdx, obj.PilotNumbersOdd)
                        dataIdx = setdiff(allIdx, obj.pIdx);
                    else
                        dataIdx = setdiff(allIdx, obj.pIdxShift);
                    end

                    RxDataSyms(Pntr : Pntr + obj.CutNumDCperSym - 1) = ...
                        fdSym(dataIdx) / obj.DataAmpOnPilotSym;
                    NoiseVar(Pntr : Pntr + obj.CutNumDCperSym - 1) = ...
                        NoiseVarIn(dataIdx - obj.NumGI, symIdx) / obj.DataAmpOnPilotSym^2;

                    pFlagIdx = pFlagIdx + 1;
                    Pntr = Pntr + obj.CutNumDCperSym; 
                else
                    scIdxs = obj.NumGI + 1 : obj.NumFFT - obj.NumGI;
                    RxDataSyms(Pntr : Pntr + obj.NumSC - 1) = fdSym(scIdxs);
                    NoiseVar(Pntr : Pntr + obj.NumSC - 1) = ...
                        NoiseVarIn(:, symIdx);                    

                    Pntr = Pntr + obj.NumSC; 
                end
            end

            OutData = RxDataSyms;     
        end
    end

    methods (Access = private)
        function Spectrum = buildSpectrum(obj, InData)
            % Собираю матрицу [NumFFT, LenFrame] с пилотами и данными
            Spectrum = zeros(obj.NumFFT, obj.LenFrame);
            % Указатель на текущую позицию в массиве символов данных 
            Pntr     = 1;
            % Счетчик символов с пилотами
            pFlagIdx = 1;

            for symIdx = 1 : obj.LenFrame
                SymSpec = zeros(obj.NumFFT, 1);

                if ismember(symIdx, obj.pilotFlags)
                    % Индексы пилотов в массиве PilotSyms
                        startIdx = (pFlagIdx - 1) * obj.NumPCperSym + 1;
                        endIdx   = pFlagIdx       * obj.NumPCperSym;

                    % Заполнение пилотами
                        if ismember(symIdx, obj.PilotNumbersOdd)
                            SymSpec(obj.pIdx) = ...
                                obj.PilotAmp * obj.PilotSyms(startIdx : endIdx);
                        else
                            SymSpec(obj.pIdxShift) = ...
                                obj.PilotAmp * obj.PilotSyms(startIdx : endIdx);
                        end
                    % Заполнение данными 
                        allIdx  = obj.NumGI + 1 : obj.NumFFT - obj.NumGI;
                        freeIdx = allIdx( SymSpec( allIdx ) == 0 );
                        SymSpec( freeIdx ) = obj.DataAmpOnPilotSym * ...
                            InData( Pntr : Pntr + obj.CutNumDCperSym - 1 );

                        pFlagIdx = pFlagIdx + 1;
                        Pntr     = Pntr + obj.CutNumDCperSym;
                else
                    scIdx = obj.NumGI + 1 : obj.NumFFT - obj.NumGI;
                    SymSpec(scIdx) = InData( Pntr : Pntr + obj.NumSC - 1 );
                    Pntr = Pntr + obj.NumSC;
                end
                
                Spectrum(:, symIdx) = SymSpec;
            end
        end

        function Frame = assembleOFDMFrame(obj, Spectrum)
            % Выделение памяти под OFDM кадр 
            FrameOFDM = zeros(obj.NumFFT + obj.LenCP, obj.LenFrame);

            for symIdx = 1 : obj.LenFrame
                % IFFT и добавление циклического префикса
                tdSymOFDM    = ifft(ifftshift( Spectrum(:, symIdx) )) * sqrt(obj.NumFFT);
                CyclicPrefix = tdSymOFDM( end - obj.LenCP + 1 : end );
                % Фомрирование кадра
                FrameOFDM(:, symIdx) = [ CyclicPrefix; tdSymOFDM ]; 
            end

            % Вытягивание в строку
            Frame = FrameOFDM(:).';
        end

        function Frame = assembleFBMCFrame(obj, Spectrum)
            % FBMC кадр: 
            % 1. IFFT
            % 2. Повтор M раз
            % 3. Умножение на прототипный фильтр 
            % 4. Перекрытие 
            M     = obj.OverlapFactor;
            N     = obj.NumFFT;
            Frame = zeros(1, obj.FrameLenSamples);

            for symIdx = 1 : obj.LenFrame
                tdSym   = ifft( ifftshift(Spectrum(:, symIdx)) ) * sqrt(N);
                tdLong  = repmat(tdSym, M, 1) / M;
                fbmcSym = tdLong .* obj.FilterTaps;

                offset = (symIdx - 1) * N;
                idx    = offset + 1 : offset + M*N;
                Frame(idx) = Frame(idx) + fbmcSym.';
            end
        end
        
        function taps = loadFilter(obj)
            switch obj.PrototypeFilter
                case 'IOTA'
                    taps = obj.generateIOTA();
                otherwise
                    error('Неизвестный PrototypeFilter: %s', obj.PrototypeFilter);
            end
        end

        function taps = generateIOTA(obj)
            % Пока пустой
        end
    end     % Конец блока methods (private)
end