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
                    OutData = obj.assembleFBMCFrame(Spectrum);
                else
                    OutData = obj.assembleOFDMFrame(Spectrum);
                end
        end

        function [OutData, NoiseVar] = StepRx(obj, InData, NoiseVarIn)
            if obj.isTransparent
                OutData = InData;
                return
            end

            % Разветвление на тип сигнала 
             if strcmp(obj.WaveformType, 'FBMC')
                 GridFD = obj.fbmcToGrid(InData);
             else
                 GridFD = obj.ofdmToGrid(InData);
             end 

             % Общая для FBMC, OFDM часть
                [OutData, NoiseVar] = obj.extractDataFromGrid(GridFD, NoiseVarIn);
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
                    error('PrototypeFilter: %s', obj.PrototypeFilter);
            end
        end

        function taps = generateIOTA(obj)
            % Заглушка
            % len = obj.OverlapFactor * obj.NumFFT;
            % taps = ones(len, 1);

            M = obj.OverlapFactor;
            N = obj.NumFFT;

            % Односторонние коэффициенты IOTA
                % HkOneSided = [-0.875450, 0.481361, -0.163639, 0.0343042, ...
                %       0.013840, -0.019876, 0.016883, -0.007068, ...
                %       0.002515, 0.000209];

                HkOneSided = [  9.9975556751297368e-01   ...
                    6.5920965840958623e-01  -1.1841742623999482e-01   ...
                    1.6741167183333790e-02   7.3290399681881654e-02  ...
                    -1.7314088694931531e-01  -8.0718159213293630e-03  ...
                    -5.9276750624914750e-03   5.6762577289995501e-02];

            % Полный симметричный набор 
                Hk = [ fliplr(HkOneSided), 1.0128740774848271e+00 , ...
                    HkOneSided ];

            % Размещение коэффициентов в центре спектра длины M*N с нулями 
                Lpad = N*M/2 - length( HkOneSided );
                Sp = [ zeros(1, Lpad), Hk, zeros(1, Lpad - 1) ];
                
            % IFFT
                Pulse = ifft( ifftshift( Sp ) );

            % Центрирование импульса
                [~, pk] = max(abs(Pulse));
                Pulse = circshift(Pulse, round(M*N/2) - pk);

            % Перевод в столбец
                Pulse = Pulse(:);

            % Нормировка
                Pulse = Pulse / norm( Pulse ) * sqrt(M * N);

            taps = Pulse;
        end

        function GridFD = ofdmToGrid(obj, InData)
        % OFDM прием: 
        % 1. reshape 
        % 2. Удаление CP
        % 3. FFT с нормировкой 
        % Возвращает матрицу [NumFFT, LenFrame] в частотной области 
            RxFrame = ...
                    reshape(InData(:), obj.NumFFT + obj.LenCP, obj.LenFrame);
            GridFD = zeros(obj.NumFFT, obj.LenFrame);

            for symIdx = 1 : obj.LenFrame
                % Удаление CP
                Sym   = RxFrame( obj.LenCP + 1 : end, symIdx );
                GridFD(:, symIdx) = fftshift( fft(Sym) ) / sqrt(obj.NumFFT);
            end
        end

        function GridFD = fbmcToGrid(obj, InData)
        % FBMC прием: 
        % 1. Беру окно длиной M * NumFFT 
        % 2. Согласованная фильтрация
        % 3. FFT длины M * NumFFT
        % 4. Прореживаю спектр в M раз 
        % 5. Получаю ресурсную сетку [NumFFT, LenFrame]
            M = obj.OverlapFactor;
            N = obj.NumFFT;

            InData = InData(:); % на всякий случай 
            GridFD = zeros(N, obj.LenFrame);

            for symIdx = 1 : obj.LenFrame
                % Окно во времени, начинается с (symIdx - 1) * N
                    offset   = (symIdx - 1) * N;
                    window   = InData(offset + 1 : offset + M*N);
                % Согласованная фильтрация
                    filtered = window .* obj.FilterTaps;
                % FFT
                    fdLong   = fftshift( fft( filtered ) ) / sqrt(N);
                % Прореживание: каждый M-й бит
                    dc_long  = M*N/2 + 1;
                % Индексы N точек: от dc_long - (N/2)*M с шагом M
                    idx      = dc_long + (-N/2 : N/2 - 1) * M;
                    GridFD(:, symIdx) = fdLong(idx);
            end
        end

        function [OutData, NoiseVar] = extractDataFromGrid(obj, GridFD, NoiseVarIn)
        % Извлечение данных и пилотов из частотной сетки 
            % Выделение памяти 
            NumDCperFrame = obj.CutNumDCperSym * length(obj.pilotFlags) + ...
                            obj.NumSC * (obj.LenFrame - length(obj.pilotFlags));
            RxDataSyms    = zeros(NumDCperFrame, 1);
            NoiseVar  = zeros( size( RxDataSyms ) );

            Pntr     = 1;
            pFlagIdx = 1;

            for symIdx = 1 : obj.LenFrame
                fdSym = GridFD(:, symIdx);

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
    end     % Конец блока methods (private)
end