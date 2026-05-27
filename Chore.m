% Параметры 
NumFFT = 2048;
M      = 4;
N      = NumFFT;
NumSC  = 1600;
NumGI  = (NumFFT - NumSC) / 2;   % 224

% Создаём чистый спектр: одна QPSK-точка на каждой активной поднесущей
Spectrum = zeros(NumFFT, 1);
activeIdx = NumGI + 1 : NumFFT - NumGI;
% Заполним детерминированно — например, все +1+1i для контроля
Spectrum(activeIdx) = (1 + 1i) / sqrt(2);

% TX
tdSym  = ifft(ifftshift(Spectrum)) * sqrt(N);
tdLong = repmat(tdSym, M, 1) / M;

FilterTaps = ones(M*N, 1);          % заглушка
% FilterTaps = ones(M*N, 1) / sqrt(M);  % альтернативная нормировка

fbmcSym = tdLong .* FilterTaps;

% Канал
Rx = fbmcSym;

% RX
filtered = Rx .* FilterTaps;
fdLong = fftshift(fft(filtered)) / sqrt(N);

dc_long = M*N/2 + 1;
idx     = dc_long + (-N/2 : N/2 - 1) * M;
RxSpec  = fdLong(idx);

% Сравним переданный и принятый спектры на активных поднесущих
TxAct = Spectrum(activeIdx);
RxAct = RxSpec(activeIdx);

fprintf('Mean |Tx|^2: %.4f\n', mean(abs(TxAct).^2));
fprintf('Mean |Rx|^2: %.4f\n', mean(abs(RxAct).^2));
fprintf('Mean |Rx - Tx|^2: %.4f\n', mean(abs(RxAct - TxAct).^2));
fprintf('Tx(1):   %.4f + %.4fi\n', real(TxAct(1)), imag(TxAct(1)));
fprintf('Rx(1):   %.4f + %.4fi\n', real(RxAct(1)), imag(RxAct(1)));
fprintf('Tx(end): %.4f + %.4fi\n', real(TxAct(end)), imag(TxAct(end)));
fprintf('Rx(end): %.4f + %.4fi\n', real(RxAct(end)), imag(RxAct(end)));

% Визуализация
figure;
subplot(2,1,1);
plot(real(TxAct), 'b'); hold on;
plot(real(RxAct), 'r--');
title('Real part'); legend('Tx', 'Rx');
subplot(2,1,2);
plot(imag(TxAct), 'b'); hold on;
plot(imag(RxAct), 'r--');
title('Imag part'); legend('Tx', 'Rx');

%% Тест 1
NumFFT = 2048;
NumSC  = 1600;
M      = 4;
K      = 14;          % LenFrame
N      = NumFFT;
NumGI  = (NumFFT - NumSC) / 2;
activeIdx = NumGI + 1 : NumFFT - NumGI;

% IOTA фильтр
HkOneSided = [-0.875450, 0.481361, -0.163639, 0.0343042, ...
               0.013840, -0.019876, 0.016883, -0.007068, ...
               0.002515, 0.000209];
Hk   = [fliplr(HkOneSided), 1, HkOneSided];
Lpad = N*M/2 - length(HkOneSided);
Sp   = [zeros(1, Lpad), Hk, zeros(1, Lpad - 1)];
Pulse = ifft(ifftshift(Sp));
Pulse = Pulse(:) / max(abs(Pulse));
FilterTaps = Pulse;

% Генерируем K разных OFDM-спектров со случайными QPSK
rng(1);
TxSpectra = zeros(NumFFT, K);
for k = 1:K
    s = (1 - 2*randi([0 1], NumSC, 1)) + 1i*(1 - 2*randi([0 1], NumSC, 1));
    s = s / sqrt(2);
    TxSpectra(activeIdx, k) = s;
end

% === TX: assembleFBMCFrame ===
FrameLen = (K + M - 1) * N;
Frame = zeros(1, FrameLen);
for k = 1:K
    tdSym   = ifft(ifftshift(TxSpectra(:,k))) * sqrt(N);
    tdLong  = repmat(tdSym, M, 1) / M;
    fbmcSym = tdLong .* FilterTaps;
    offset  = (k-1)*N;
    Frame(offset+1 : offset+M*N) = Frame(offset+1 : offset+M*N) + fbmcSym.';
end

% === RX: fbmcToGrid (без шума, без канала) ===
RxSig = Frame(:);
RxSpectra = zeros(NumFFT, K);
for k = 1:K
    offset   = (k-1)*N;
    window   = RxSig(offset+1 : offset+M*N);
    filtered = window .* FilterTaps;
    fdLong   = fftshift(fft(filtered)) / sqrt(N);
    dc_long  = M*N/2 + 1;
    idx      = dc_long + (-N/2 : N/2-1)*M;
    RxSpectra(:,k) = fdLong(idx);
end

% Сравнение по каждому символу
fprintf('Symbol | Mean|Tx|^2 | Mean|Rx|^2 | Mean|Rx-Tx|^2 | SIR (dB)\n');
for k = 1:K
    txk = TxSpectra(activeIdx, k);
    rxk = RxSpectra(activeIdx, k);
    pTx = mean(abs(txk).^2);
    pRx = mean(abs(rxk).^2);
    err = mean(abs(rxk - txk).^2);
    sir = 10*log10(pTx / err);
    fprintf('  %2d   |  %.4f   |  %.4f   |   %.4e  |  %.1f\n', ...
        k, pTx, pRx, err, sir);
end

%% Тест 2 
NumFFT = 2048; NumSC = 1600; M = 4; N = NumFFT;
NumGI = (NumFFT - NumSC)/2;
activeIdx = NumGI+1 : NumFFT-NumGI;

HkOneSided = [-0.875450, 0.481361, -0.163639, 0.0343042, ...
               0.013840, -0.019876, 0.016883, -0.007068, ...
               0.002515, 0.000209];
Hk   = [fliplr(HkOneSided), 1, HkOneSided];
Lpad = N*M/2 - length(HkOneSided);
Sp   = [zeros(1, Lpad), Hk, zeros(1, Lpad-1)];
Pulse = ifft(ifftshift(Sp));
FilterTaps = Pulse(:) / max(abs(Pulse));

% ТЕСТ A: только символ 1, символ 2 пустой
K = 2;
TxSpectra = zeros(NumFFT, K);
rng(1);
s1 = ((1-2*randi([0 1],NumSC,1)) + 1i*(1-2*randi([0 1],NumSC,1)))/sqrt(2);
TxSpectra(activeIdx, 1) = s1;
% символ 2 оставляем нулевым

FrameLen = (K+M-1)*N;
Frame = zeros(1, FrameLen);
for k=1:K
    tdSym=ifft(ifftshift(TxSpectra(:,k)))*sqrt(N);
    tdLong=repmat(tdSym,M,1)/M;
    fbmcSym=tdLong.*FilterTaps;
    off=(k-1)*N;
    Frame(off+1:off+M*N)=Frame(off+1:off+M*N)+fbmcSym.';
end

% приём символа 1
% off=0;
% window=Frame(off+1:off+M*N).';
% filtered=window.*FilterTaps;
% fdLong=fftshift(fft(filtered))/sqrt(N);
% dc=M*N/2+1;
% idx=dc+(-N/2:N/2-1)*M;
% Rx1=fdLong(idx);
% 
% err1 = mean(abs(Rx1(activeIdx)-TxSpectra(activeIdx,1)).^2);
% fprintf('ТЕСТ A (символ 1, сосед пустой): Mean|Rx-Tx|^2 = %.4e, SIR = %.1f dB\n', ...
%     err1, 10*log10(1/err1));
off = 0;
window = Frame(off+1 : off+M*N).';      % длина M*N, столбец

% Матрица [N, M]: столбец m — это m-й период
R = reshape(window, N, M);
G = reshape(FilterTaps, N, M);

% Числитель: сумма r·g по периодам
num = sum(R .* G, 2);                    % длина N
% Знаменатель: сумма g² по периодам
den = sum(G .^ 2, 2);                    % длина N

tdSym_hat = M * num ./ den;              % восстановленный временной символ

% Обратно в частоту
Rx1 = fftshift(fft(tdSym_hat)) / sqrt(N);

err1 = mean(abs(Rx1(activeIdx) - TxSpectra(activeIdx,1)).^2);
fprintf('Взвешенный приём: Mean|Rx-Tx|^2 = %.4e, SIR = %.1f dB\n', ...
    err1, 10*log10(1/err1));

% % приём символа 2 (он пустой, но должен ли он что-то "увидеть" от символа 1?)
% off=N;
% window=Frame(off+1:off+M*N).';
% filtered=window.*FilterTaps;
% fdLong=fftshift(fft(filtered))/sqrt(N);
% Rx2=fdLong(idx);
% leak = mean(abs(Rx2(activeIdx)).^2);
% fprintf('ТЕСТ A (символ 2 пустой): утечка от соседа Mean|Rx|^2 = %.4e\n', leak);

%% Диагностика FBMC: полный кадр, взвешенный приём, таблица SIR по символам
NumFFT = 2048; NumSC = 1600; M = 4; K = 14; N = NumFFT;
NumGI = (NumFFT - NumSC)/2;
activeIdx = NumGI+1 : NumFFT-NumGI;

% --- IOTA фильтр (точно как в generateIOTA) ---
HkOneSided = [-0.875450, 0.481361, -0.163639, 0.0343042, ...
               0.013840, -0.019876, 0.016883, -0.007068, ...
               0.002515, 0.000209];
Hk   = [fliplr(HkOneSided), 1, HkOneSided];
Lpad = N*M/2 - length(HkOneSided);
Sp   = [zeros(1, Lpad), Hk, zeros(1, Lpad-1)];
Pulse = ifft(ifftshift(Sp));
FilterTaps = Pulse(:) / max(abs(Pulse));

% --- Генерируем K разных OFDM-спектров со случайными QPSK ---
rng(1);
TxSpectra = zeros(NumFFT, K);
for k = 1:K
    s = (1 - 2*randi([0 1], NumSC, 1)) + 1i*(1 - 2*randi([0 1], NumSC, 1));
    TxSpectra(activeIdx, k) = s / sqrt(2);
end

% --- TX: assembleFBMCFrame ---
FrameLen = (K + M - 1) * N;
Frame = zeros(1, FrameLen);
for k = 1:K
    tdSym   = ifft(ifftshift(TxSpectra(:,k))) * sqrt(N);
    tdLong  = repmat(tdSym, M, 1) / M;
    fbmcSym = tdLong .* FilterTaps;
    offset  = (k-1)*N;
    Frame(offset+1 : offset+M*N) = Frame(offset+1 : offset+M*N) + fbmcSym.';
end

% --- RX: взвешенный приём (как новый fbmcToGrid) ---
RxSig = Frame(:);
G   = reshape(FilterTaps, N, M);
den = sum(G.^2, 2);

RxSpectra = zeros(NumFFT, K);
for k = 1:K
    offset = (k-1)*N;
    window = RxSig(offset+1 : offset+M*N);
    R      = reshape(window, N, M);
    num    = sum(R .* G, 2);
    tdSym_hat = M * num ./ den;
    RxSpectra(:,k) = fftshift(fft(tdSym_hat)) / sqrt(N);
end

% --- Таблица SIR по символам ---
fprintf('Sym | Mean|Tx|^2 | Mean|Rx|^2 | Mean|Rx-Tx|^2 | SIR(dB)\n');
for k = 1:K
    txk = TxSpectra(activeIdx, k);
    rxk = RxSpectra(activeIdx, k);
    pTx = mean(abs(txk).^2);
    pRx = mean(abs(rxk).^2);
    err = mean(abs(rxk - txk).^2);
    sir = 10*log10(pTx / err);
    fprintf(' %2d |  %.4f   |  %.4f   |  %.4e  |  %.1f\n', ...
        k, pTx, pRx, err, sir);
end