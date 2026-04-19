function Params = CalcAndCheckParams(inParams, LogLanguage)
%
% В этой функции можно проверять правильность установки комбинаций
% параметров и/или выполнять расчёт параметров одного класса, зависящих от
% параметров других классов, важно при этом понимать, что функция
% CalcAndCheckParams вызывается до создания объектов, т.е. до вызова
% конструкторов.

% Пересохраним входные данные
    Params = inParams;

% Вычисляемые параметры Sig 
    % Длина защитного интервала по краям символа OFDM
        Params.Sig.NumGI = (Params.Sig.NumFFT - Params.Sig.NumSC) / 2;

    % Количество пилотов в одном символе OFDM
        Params.Sig.NumPCperSym = ...
            length(1 : Params.Sig.StepPC : Params.Sig.NumSC);

    % Индексы символов с пилотами внутри кадра (счет с 1)
        Params.Sig.PilotNumbersOdd  = 1 : 7 : Params.Sig.LenFrame;
        Params.Sig.PilotNumbersEven = 5 : 7 : Params.Sig.LenFrame;
        Params.Sig.pilotFlags = sort( [ Params.Sig.PilotNumbersOdd ...
           Params.Sig.PilotNumbersEven ] );

    % Количество символов с пилотами в одном кадре 
        Params.Sig.NumPSperFrame = length(Params.Sig.pilotFlags);

    % Количество пилотов в одном кадре 
        Params.Sig.NumPC = ...
            Params.Sig.NumPSperFrame * Params.Sig.NumPCperSym;

    % Количество бит для пилотов в одном кадре 
        Params.Sig.NumBits4PC = ...
            Params.Sig.NumPC * log2(Params.Sig.PilotModOrder);

    % Количество информационных поднесущих в символе с пилотами 
        Params.Sig.CutNumDCperSym = ...
            Params.Sig.NumSC - Params.Sig.NumPCperSym;

    % Общее количество информационных поднесущих в одном кадре 
        NumDCperFrame = ...
            Params.Sig.NumSC * Params.Sig.LenFrame - Params.Sig.NumPC;

    % Количество бит для информационных поднесущих в одном кадре 
        Params.Sig.NumBits4DC = ...
            NumDCperFrame * log2(Params.Mapper.ModulationOrder);

% Вычисляемые параметры Encoder 
    if ~Params.Encoder.isTransparent
        % Количество бит на входе кодера за один кадр 
            Params.Encoder.NumBitsPerFrame = ...
                round(Params.Sig.NumBits4DC * Params.Encoder.R);

        % Длина потока после lteConvolutionalEncode — нужна декодеру
            Params.Encoder.LenEncBits = Params.Encoder.NumBitsPerFrame * 3;
    else
        Params.Encoder.NumBitsPerFrame = Params.Sig.NumBits4DC;
    end

    Params.Encoder.NumBits4DC = Params.Sig.NumBits4DC;
    
    Params.Encoder.isSoftInput = ...
        ~strcmp(Params.Mapper.DecisionMethod, 'Hard decision');


% Вычисляемые параметры Source 
    Params.Source.NumBitsPerFrame = Params.Encoder.NumBitsPerFrame;

% Если в модели отключено декодирование, то в демодуляторе нужно
% принудительно установить режим вынесения жёстких решений, иначе не
% удастся выполнить сравнение полученной и переданной информации
    if Params.Encoder.isTransparent
        Params.Mapper.DecisionMethod = 'Hard decision';
    end

% Проверка того, что в модулятор поступает число бит, делящееся на log2(M)
    if Params.Encoder.isTransparent
        % Как вариант, можно предусмотреть возможность набивания в
        % передатчике и отбрасывания в приёмнике дополнительных бит в
        % классе Mapper
        if mod(Params.Source.NumBitsPerFrame, ...
                log2(Params.Mapper.ModulationOrder)) > 0
            if strcmp(LogLanguage, 'Russian')
                error(['В модулятор поступает число бит не кратное ', ...
                    'log2(M).']);
            else
                error(['The number of bits at the input of the ', ...
                    'mapper is not multiple of log2(M).']);
            end
        end
    end
    