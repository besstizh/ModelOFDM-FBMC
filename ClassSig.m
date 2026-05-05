classdef ClassSig < handle
    properties (SetAccess = private) % Переменные из параметров
        isTransparent;
        NumFFT;
        NumSC;
        LenCP;
        LenFrame;
        StepPC;
        PilotModOrder;
        LogLanguage;
        PilotBoost;
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
    end
    methods
        function obj = ClassSig(Params, LogLanguage) % Конструктор
            % Выделим поля Params, необходимые для инициализации
                Sig  = Params.Sig;

            % Инициализация значений переменных из параметров
                obj.isTransparent = Sig.isTransparent;
                obj.NumFFT        = Sig.NumFFT;
                obj.NumSC         = Sig.NumSC;
                obj.LenCP         = Sig.LenCP;
                obj.LenFrame      = Sig.LenFrame;
                obj.StepPC        = Sig.StepPC;
                obj.PilotModOrder = Sig.PilotModOrder;
                obj.PilotBoost    = Sig.PilotBoost;
                obj.LogLanguage   = LogLanguage;

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
        end
        function OutData = StepTx(obj, InData)
            if obj.isTransparent
                OutData = InData;
                return
            end
            
            % Выделение памяти под кадр 
                FrameOFDM = zeros(obj.NumFFT + obj.LenCP, obj.LenFrame);
            % Указатель на текущую позицию в массиве символов данных 
                Pntr     = 1;
            % Счетчик символов с пилотами
                pFlagIdx = 1;

            for symIdx = 1 : obj.LenFrame
                SymOFDM = zeros(obj.NumFFT, 1);

                if ismember(symIdx, obj.pilotFlags)
                    % Индексы пилотов в массиве PilotSyms
                        startIdx = (pFlagIdx - 1) * obj.NumPCperSym + 1;
                        endIdx   = pFlagIdx       * obj.NumPCperSym;

                    % Заполнение пилотами
                        if ismember(symIdx, obj.PilotNumbersOdd)
                            SymOFDM(obj.pIdx) = ...
                                obj.PilotAmp * obj.PilotSyms(startIdx : endIdx);
                        else
                            SymOFDM(obj.pIdxShift) = ...
                                obj.PilotAmp * obj.PilotSyms(startIdx : endIdx);
                        end
                    % Заполнение данными 
                        allIdx  = obj.NumGI + 1 : obj.NumFFT - obj.NumGI;
                        freeIdx = allIdx( SymOFDM( allIdx ) == 0 );
                        SymOFDM( freeIdx ) = obj.DataAmpOnPilotSym * ...
                            InData( Pntr : Pntr + obj.CutNumDCperSym - 1 );

                        pFlagIdx = pFlagIdx + 1;
                        Pntr     = Pntr + obj.CutNumDCperSym;
                else
                    scIdx = obj.NumGI + 1 : obj.NumFFT - obj.NumGI;
                    SymOFDM(scIdx) = InData( Pntr : Pntr + obj.NumSC - 1 );
                    Pntr = Pntr + obj.NumSC;
                end

                % IFFT и добавление циклического префикса 
                    tdSymOFDM    = ifft(ifftshift(SymOFDM)) * sqrt(obj.NumFFT);
                    CyclicPrefix = tdSymOFDM( end - obj.LenCP + 1 : end );
                    FrameOFDM(:, symIdx) = [ CyclicPrefix; tdSymOFDM ];
            end

            % Вытягивание в строку и нормировка
                OutData = FrameOFDM(:).';
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
end