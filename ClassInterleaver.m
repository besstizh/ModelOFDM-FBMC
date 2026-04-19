classdef ClassInterleaver < handle
    properties (SetAccess = private) % Переменные из параметров
        % Нужно ли выполнять перемежение и деперемежение
            isTransparent;
        % Переменная управления языком вывода информации для пользователя
            LogLanguage;
        % Порядок перемежения для деперемежителя 
            IntrlvIdx;
    end
    properties (SetAccess = private) % Вычисляемые переменные
    end
    methods
        function obj = ClassInterleaver(Params, LogLanguage) % Конструктор
            % Выделим поля Params, необходимые для инициализации
                Interleaver  = Params.Interleaver;
            % Инициализация значений переменных из параметров
                obj.isTransparent = Interleaver.isTransparent;
            % Переменная LogLanguage
                obj.LogLanguage = LogLanguage;
        end
        function OutData = StepTx(obj, InData)
            if obj.isTransparent
                OutData = InData;
                return
            end
            Len           = length(InData);
            obj.IntrlvIdx = randperm(Len);
            OutData       = InData(obj.IntrlvIdx);
        end
        function OutData = StepRx(obj, InData)
            if obj.isTransparent
                OutData = InData;
                return
            end
            Len                       = length(InData);
            DeintrlvIdx               = zeros(1, Len);
            DeintrlvIdx(obj.IntrlvIdx) = 1 : Len;
            OutData                   = InData(DeintrlvIdx);
        end
    end
end