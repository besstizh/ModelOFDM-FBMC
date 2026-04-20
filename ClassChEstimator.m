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
        end
        function H = Step(obj, TxSignal, FadedSignal)
            if obj.isTransparent
                H = ones(obj.NumSC, obj.LenFrame);
                return;
            end

            TxFrame    = reshape(TxSignal(:), ... 
                obj.NumFFT + obj.LenCP, obj.LenFrame);
            FadedFrame = reshape(FadedSignal(:), ... 
                obj.NumFFT + obj.LenCP, obj.LenFrame);

            H = zeros(obj.NumSC, obj.LenFrame);
            scIdxs = obj.NumGI + 1 : obj.NumFFT - obj.NumGI;

            for symIdx = 1 : obj.LenFrame
                TxSym    = TxFrame(obj.LenCP + 1 : end, symIdx);
                FadedSym = FadedFrame(obj.LenCP + 1 : end, symIdx);

                fdTx    = fftshift( fft( TxSym ) );
                fdFaded = fftshift( fft( FadedSym ) );

                H(:, symIdx) = fdFaded(scIdxs) ./ fdTx(scIdxs);
            end
        end
    end
end