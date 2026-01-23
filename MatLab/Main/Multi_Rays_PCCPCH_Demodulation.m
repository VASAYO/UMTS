function PCCPCH_Bits = Multi_Rays_PCCPCH_Demodulation(Signal, ...
    Rake_Pattern, Frame_Offset, SC_Num, Flag_Draw)
% Функция выполняет однолучевую демодуляцию всех кадров вещательного канала
% имеющихся в Signal.
%
% Входные переменные:
%   Signal       – комплексный массив, содержащий отсчеты исходного
%                  сигнала;
%   Rake_Pattern - rake-шаблона, структура, содержащая два поля данных:
%     Correl     - значения КФ пилотного канала для разных лучей;
%     dfs        - значения оценок частотных отстроек для разных лучей;
%   Frame_Offset – значение сдвига в FSignal до начала кадра;
%   SC_Num       – номер скремблирующей последовательности;
%   Flag_Draw    – флаг необходимости прорисовки корреляционной
%                  кривой, Flag_Draw = true указывает на
%                  необходимость прорисовки.
%
% Выходные переменные:
%   PCCPCH_Bits - массив-строка (длина кратна 270), содержащий значения
%                 бит всех кадров канала PCCPCH, считанных из Signal.

% Последовательность действий:
%   1. Определить 2-3 луча, для которых будет проводиться обработка;
%   2. Для каждого луча выполнить:
%     * Согласованную фильтрацию сигнала с предварительной компенсацией 
%       частотной отстройки луча;
%     * Дескрэмблирование чипов луча;
%     * Вычисление модуляционных символов (дерасширение);
%     * Оценка канала с использованием CPICH и эквалайзинг;
%     * Оценка дисперсии шума;
%   3. Выполнить сложение лучей с весами, равными обратной дисперсии шума в 
%      каждом луче;
%   4. Выполнить демодуляцию первичного общего канала управления.

% Параметры
    % Максимальное число обрабатываемых лучей
        MaxNumProcRays = 2;
    % Число чипов в одном кадре
        ChiPerFrame = 38400;
    % Число слотов в одном кадре
        SlotsPerFrame = 15;
    % Число бит P-CCPCH в одном кадре
        DataBitsPerFrame = 270;
    % Коэффициент расширения
        SF = 256;

    % Каналообразующие и скремблирующий коды
        ChCodeData  = Generate_Channelisation_Code(256, 1);
        ChCodePilot = Generate_Channelisation_Code(256, 0);
        ScrCode     = Generate_Scrambling_Code(SC_Num);

% Выбор лучей
    % Сдвиги до начала кадра соответствующих лучей и их частотные отстройки
        Rays_Offsets = [];
        Rays_dfs     = [];
    % Определим порог обнаружение лучей относительно величины главного луча
        Rays_Detect_Treshold = 0.3 * max(Rake_Pattern.Correl);
    
    FoundRays = 0;
    RaysDetection = Rake_Pattern.Correl;
    IndMidElem = median(1:length(RaysDetection) );

    while FoundRays < MaxNumProcRays && ...
            sum(Rake_Pattern.Correl > Rays_Detect_Treshold) > 0
        % Выбираем луч
            [~, Buf ] = max(RaysDetection);
            Rays_Offsets(end+1) = Frame_Offset + Buf -IndMidElem; %#ok<*AGROW>
            Rays_dfs    (end+1) = Rake_Pattern.dfs(Buf);

        % Зануляем в rake-шаблоне выбранный луч и два соседних отсчёта
            if Buf == 1
                P1 = Buf;
            else
                P1 = Buf - 1;
            end
            if Buf == length(RaysDetection)
                P2 = Buf;
            else
                P2 = Buf + 1;
            end
            RaysDetection(P1 : P2) = 0;
            
        FoundRays = FoundRays + 1;
    end

% Обработка лучей
    % Переменные для хранения модуляционных символов CHICH и PCCPCH разных
    % лучей
        SymbolsData  = cell(1, FoundRays);
        SymbolsPilot = cell(1, FoundRays);
    % Оценки канала
        ChEst  = cell(1, FoundRays);
    % Дисперсия шума в разных лучах
        Noise_Vars = zeros(1, FoundRays);
    % Число обрабатываемых кадров в каждом луче
        NumProcFrames = zeros(1, FoundRays);

    for k = 1:FoundRays
        % Согласованная фильтрация с компенсацией частотной отстройки
            FSignal = Matched_Filter(Signal, Rays_dfs(k) );
        % Чипы луча
            Chips = FSignal(Rays_Offsets(k):2:end);
        % Число обрабатываемых кадров
            NumProcFrames(k) = floor(length(Chips) / ChiPerFrame);

        % Память под модуляционные символы данного луча. 
        %   Первое измерение - индексация символов внутри слота, 
        %   второе измерение - индексация слотов внутри кадра, 
        %   третье измерение - индексация обрабатываемых кадров.
            SymbolsData{k} = ...
                zeros(10-1, SlotsPerFrame, NumProcFrames(k) );
            % SymbolsDataEq{end+1} = SymbolsData{end};
            SymbolsPilot{k} = ...
                zeros(10, SlotsPerFrame, NumProcFrames(k) );

        Chips = Chips(1 : NumProcFrames(k) * ChiPerFrame);
        Chips = reshape(Chips, ChiPerFrame, []);

        % Дескрэмблирование
            ChipsDeScr = Chips .* ...
                conj(repmat(ScrCode.', 1, NumProcFrames(k) ) ) / sqrt(2);

        % Дерасширение модуляционных символов
            ChipsDeScr = reshape(ChipsDeScr(:), SF, []);

        % Получение символов CPICH
            Buf = ChCodePilot * ChipsDeScr;
            SymbolsPilot{k} = ...
                reshape(Buf, 10, SlotsPerFrame, NumProcFrames(k) );
        % Получение символов P-CCPCH
            Buf = ChCodeData * ChipsDeScr;
            SymbolsData{k} = ...
                reshape(Buf, 10, SlotsPerFrame, NumProcFrames(k) );
            % Удаление в первого символа в каждом слоте т.к. в эти моменты
            % времени P-CCPCH не передаётся
                SymbolsData{k} = SymbolsData{k}(2:end, :, :);

        % Оценка канала и дисперсии шума
            ChEst{k} = SymbolsPilot{k}(2:end, :, :) / (1 + 1j);
            Noise_Vars(k) = SNR_Estimate(SymbolsPilot{k}(:) );
    end

% Суммирование лучей с весовыми коэффициентами
    SumRays = zeros(size(SymbolsData{1} ) );

    for k = 1:FoundRays
        SumRays = SumRays + ...
            SymbolsData{k} .* conj(ChEst{k} ) ./ Noise_Vars(k);
    end

% Демодуляция символов канала управления
    Buf = SumRays(:);
    PCCPCH_Bits = nan(1, DataBitsPerFrame * max(NumProcFrames) );
    for k = 1 : DataBitsPerFrame * max(NumProcFrames) / 2
        if (real(Buf(k)) >= 0)
            PCCPCH_Bits(2*(k -1) + 1) = 0;
        else
            PCCPCH_Bits(2*(k -1) + 1) = 1;
        end
        if (imag(Buf(k)) >= 0)
            PCCPCH_Bits(2*k) = 0;
        else
            PCCPCH_Bits(2*k) = 1;
        end
    end

% Прорисовка результатов
    if Flag_Draw
        figure(Name=['Multi_Rays_PCCPCH_Demodulation.m: ' ...
            'созвездия лучей по отдельности'])
        for k = 1:FoundRays
            subplot(1, FoundRays, k);
            plot(SymbolsData{k}(:) ./ ChEst{k}(:), '.' ); 
            grid minor; axis equal;
        end

        figure(Name=['Multi_Rays_PCCPCH_Demodulation.m: ' ...
            'созвездие комбинированного сигнала'])
        plot(SumRays(:), '.' ); 
            grid minor; axis equal;
    end


function [SNRat, D_Noise] = SNR_Estimate(SigSyms)
    % Амплитуда символа
        AmplSym = mean(abs(SigSyms)) / sqrt(2);
    % Удалим шум
        WithoutNois = ...
            AmplSym * (sign(real(SigSyms)) + 1i * sign(imag(SigSyms)));
    % Выделим шум
        Noise = SigSyms - WithoutNois;
    %     scatterplot(Noise);
    % Дисперсия шума
        D_Noise = var(Noise);
    % ОСШ в разах
        SNRat = mean(abs(SigSyms).^2) / D_Noise;
    % Переведём ОСШ в дБ
        SNRat = 10*log10(SNRat);
