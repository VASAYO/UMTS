function [Flag_isOk, MCC, MNC] = Parse_BCCH(BCCH)
% Функция выполняет синтаксический анализ полученных данных вещательного  
% канала. Основными извлекаемыми параметрами являются код страны MCC и код 
% оператора MNC. 
% 
% Входные переменные: 
%   BCCH – массив с количеством строк, равным количеству декодированых 
%          транспортных блоков BCCH, и количеством столбцов 246. 
% 
% Выходные переменные: 
%   Flag_isOk - указывает на то, удалось ли считать параметры MCC, MNC; 
%   MCC, MNC  - код страны и код оператора.

% Инициализация выходных переменных
    Flag_isOk = false;
    MCC = [];
    MNC = [];

% Указатель, необходимый для последовательного чтения данных блока
    Ptr = 0;

% Считываем SFN всех транспортных блоков и ищем блок, содержащий ГИБ
    FoundMIB = false;
    NumBCCHs = size(BCCH, 1);

    for k = 1:NumBCCHs
        Buf = BCCH(k, 1:11);
        SFN = 2 * bit2int(Buf', 11, true, "IsSigned", false);

        % Проверка наличия ГИБа в текущем транспортном блоке
            if mod(SFN, 8) == 0
                FoundMIB = true;
                ProcBCCH = BCCH(k, :);
                break;
            end
    end

    if ~FoundMIB
        disp('Parse_BCCH.m: не найден транспортный блок, содержащий ГИБ.');
        return;
    end

    Ptr = Ptr + 11;

% Считываем значение поля Payload
    Payload = bit2int(ProcBCCH( (1:4) + Ptr)', 4, true) +1;
    Ptr = Ptr + 4;

% Определяем, какие сегменты (или полные БСИ) находятся в транспортном
% блоке, после чего выполняем обработку. 
%
% В случае, если в блоке присутствуют как целые БСИ, так и сегменты других 
% БСИ, то по правилам сначала приводится информация для полного БСИ.
    switch Payload
        case 6  % lastAndComplete, полный БСИ и последний сегмент неполного 
                % БСИ

        case 7  % lastAndCompleteAndFirst, полный БСИ, последний сегмент 
                % неполного БСИ и первый сегмент неполного БСИ

        case 8  % completeSIB-List, несколько полных БСИ
            % Считываем значение числа полных БСИ в транспортном блоке
                NumCompleteSIBs = bit2int(ProcBCCH( (1:4)+Ptr)', 4) +1;
                Ptr = Ptr + 4;

            % Последовательно считываем заголовки каждого полного БСИ,
            % состоящие из типа БСИ и длины БСИ в бит, пока не найдём
            % расположение ГИБа.
                FoundCompleteMIB = false;

                for k = 1:NumCompleteSIBs
                    % Считываем тип и размер БСИ 
                        SIBType = bit2int(ProcBCCH( (1:5)+Ptr)', 5);
                        SIBSize = bit2int(ProcBCCH( (1:8)+Ptr+5)', 8) +1;

                    % Если данный БСИ является ГИБом, то выбираем биты ГИБа
                        if SIBType == 0
                            MIB = ProcBCCH( (1:SIBSize)+Ptr+5+8+1);
                        end

                    % Переходим к обработке заголовка следующего полного
                    % БСИ
                        Ptr = Ptr + 5 + 8 + 1 + SIBSize;
                end

        case 9  % completeAndFirst, полный БСИ и первый сегмент неполного 
                % БСИ
            % Считываем значение числа полных БСИ в транспортном блоке
                NumCompleteSIBs = bit2int(ProcBCCH( (1:4)+Ptr)', 4) +1;
                Ptr = Ptr + 4;

            % Последовательно считываем заголовки каждого полного БСИ,
            % состоящие из типа БСИ и длины БСИ в бит, пока не найдём
            % расположение ГИБа.
                FoundCompleteMIB = false;

                for k = 1:NumCompleteSIBs
                    % Считываем тип и размер БСИ 
                        SIBType = bit2int(ProcBCCH( (1:5)+Ptr)', 5);
                        SIBSize = bit2int(ProcBCCH( (1:8)+Ptr+5)', 8) +1;

                    % Если данный БСИ является ГИБом, то выбираем биты ГИБа
                        if SIBType == 0
                            FoundCompleteMIB = true;
                            MIB = ProcBCCH( (1:SIBSize)+Ptr+5+8+1);
                        end

                    % Переходим к обработке заголовка следующего полного
                    % БСИ
                        Ptr = Ptr + 5 + 8 + 1 + SIBSize;
                end

            if ~FoundCompleteMIB
                disp(['Parse_BCCH.m: транспортный блок содержит лишь ' ...
                    'первый сегмент ГИБа.']);
                return;
            end

        case 10 % completeSIB, единственный полный БСИ

    end

if ~exist("MIB", "var")
    disp(['Parse_BCCH.m: функциональность поиска ГИБа для данного ' ...
        'значения поля Payload не реализована.']);
    return;
end

% Парсинг ГИБа
    PtrMIB = 0;

    % Считываем ValueTag
        MIBValueTag = bit2int(MIB( (1:3)+PtrMIB)', 3) +1;
        PtrMIB = PtrMIB + 3;

    % Считываем PLMN-Type
        PLMN_Type = bit2int(MIB( (1:2)+PtrMIB)', 2);
        PtrMIB = PtrMIB + 2;

    % Если PLMN-Type равно ansi-41 или spare, то извлечь MNC и MCC не
    % получится
        if PLMN_Type == 1 || PLMN_Type == 3
            disp(['Parse_BCCH.m: поле ГИБа PLMN-Type принимает ' ...
                'значения ansi-41 или spare']);
            return;
        end

    % Парсим поле PLMN-Identity и считываем MNC и MCC
        % Считываем MCC
            MCC1 = bit2int(MIB( (1:4)+PtrMIB)', 4);
            PtrMIB = PtrMIB + 4;

            MCC2 = bit2int(MIB( (1:4)+PtrMIB)', 4);
            PtrMIB = PtrMIB + 4;

            MCC3 = bit2int(MIB( (1:4)+PtrMIB)', 4);
            PtrMIB = PtrMIB + 4;

            MCC = 100 * MCC1 + 10 * MCC2 + MCC3;

        % Считываем MNC
            MNC_Size = MIB(PtrMIB +1);
            PtrMIB = PtrMIB + 1;

            if MNC_Size == 0 % MNC - двухзначное число
                MNC1 = bit2int(MIB( (1:4)+PtrMIB)', 4);
                PtrMIB = PtrMIB + 4;

                MNC2 = bit2int(MIB( (1:4)+PtrMIB)', 4);
                PtrMIB = PtrMIB + 4;

                MNC = 10 * MNC1 + 1 * MNC2;

            else % MNC - трёхзначное число
                MNC1 = bit2int(MIB( (1:4)+PtrMIB)', 4);
                PtrMIB = PtrMIB + 4;

                MNC2 = bit2int(MIB( (1:4)+PtrMIB)', 4);
                PtrMIB = PtrMIB + 4;

                MNC3 = bit2int(MIB( (1:4)+PtrMIB)', 4);
                PtrMIB = PtrMIB + 4;

                MCC = 100 * MNC1 + 10 * MNC2 + MNC3;
            end

            Flag_isOk = true;
