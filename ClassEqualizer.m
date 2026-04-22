classdef ClassEqualizer < handle
    properties (SetAccess = private)
        isTransparant;
        Type;
        NumFFT;
        NumSC;
        NumGI;
        LenCP;
        LenFrame;
        LogLanguage;
    end
    methods
        function obj = ClassEqualizer(Params, Objs, LogLanguage)
            Equalizer         = Params.Equalizer;
            obj.isTransparant = Equalizer.isTransparant;
            obj.Type          = Equalizer.Type;          
            obj.NumFFT        = Objs.Sig.NumFFT;
            obj.NumSC         = Objs.Sig.NumSC;
            obj.NumGI         = Objs.Sig.NumGI;
            obj.LenCP         = Objs.Sig.LenCP;
            obj.LenFrame      = Objs.Sig.LenFrame;
            obj.LogLanguage   = LogLanguage;
        end

        function [OutData, NoiseVar] = Step(obj, InData, H, Variance)
            if obj.isTransparant
                OutData  = InData;
                NoiseVar = Variance * ones( size( InData ) );
                return;
            end
            % ZF эквализация: поэлементное деление на H
            % H       - матрица NumSC x LenFrame (1600 x 14)
            % InData  - вектор сигнала, прошедщего канал с шумом
            % OutData - вектор эквализированного сигнала той же длины

            % План выполнения: 
            % ) reshape сигнала, пришедшего на вход в размерность (LenCP +
            % NumFFT) x LenFrame. то есть в столбце символ с ЦП
            % ) захожу в цикл по символам, то есть по столбцам InData
            % ) отбрасываю циклический префикс 
            % ) FFT
            % ) выделяю индексы поднесущих внутри защитных интервалов
            % ) делю символ после FFT в области этих индексов на столбец H
            % ) На выходе получаю матрицу эквализированных символов
            % ) перезаписываю матрицу InData 
            % ) вытягиваю в вектор и подаю на выход 
            % ) пересчитываю дисперсию
                InData = reshape(Indata, obj.LenCP + obj.NumFFT, obj.LenFrame);
                OutData = zeros(size(InData));

                for symIdx = 1 : obj.LenFrame
                    % Выделяю символ 
                        CPSymbol = InData(:, symIdx);
                    % Отбрасываю циклический префикс
                        Symbol   = CPSymbol(obj.LenCP + 1: end);
                    % FFT
                        fdSymbol = ...
                            fftshift( fft( Symbol ) ) / sqrt(obj.NumFFT);
                    % Выделяю индексы поднесущих 
                        scIdx    = (obj.NumGI + 1: obj.NumFFT - obj.NumGI);
                    % Создаю копию символа, которую буду менять
                        EqSymbol = fdSymbol;
                    % Делю на оценку канала
                        EqSymbol(scIdx) = fdSymbol(scIdx) ./ H(:, symIdx);
                    % IFFT 
                        tdEqSymbol = ...
                            ifft( ifftshift( EqSymbol ) ) * sqrt(obj.NumFFT);
                    % Заменяю в исходном символе часть после ЦП
                        CPSymbol(obj.LenCP + 1: end) = tdEqSymbol;
                    % Помещаю эквализированный символ в выходной массив
                        OutData(:, symIdx) = CPSymbol; 
                end

                OutData = OutData(:).';
 
            % Дисперсия шума после эквализации
            % После FFT дисперсия умножается на NumFFT
            % После деления на H делится на |H|^2
                NoiseVar = ...
                    Variance * obj.NumFFT ./ (abs(H).^2);
        end
    end
end