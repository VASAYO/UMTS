function Check_Functions()
%
% Функция выполняет проверку правильности функционирования общих программ

% Очистка экрана
    clc;

% Попытка подключения двух вложенных директорий
    Dir = dir;
    Flag_Find1 = false;
    Flag_Find2 = false;
    for k = 1:length(Dir)
        if isequal(Dir(k).name, 'Common') && (Dir(k).isdir)
            Flag_Find1 = true;
        end
        if isequal(Dir(k).name, 'Main') && (Dir(k).isdir)
            Flag_Find2 = true;
        end
    end
    
    if ~(Flag_Find1 && Flag_Find2)
        disp('Ошибка расположения Check_Functions:')
        disp(['в директории отсутствуют вложенные директории ', ...
            'Common и Main!']);
        return
    end
    
    path([cd, '\Common'], path);
    path([cd, '\Main'], path);
    
% Инициализация списка проверяемых функций    
    ListString = { ...
        '1. Generate_Primary_Synchronisation_Code'; ...
        '2. Generate_Secondary_Synchronisation_Codes'; ...
        '3. Generate_Scrambling_Groups_Table'; ...
        '4. Generate_Channelisation_Code'; ...
        '5. Generate_Scrambling_Code'; ...
        '6. Check_CRC'; ...
        '7. Convolutional_Decoder'; ...
        '8. First_DeInterleaver'; ...
        '9. Second_DeInterleaver'; ...
        '0. Matched_Filter'};

% Вызов диалога выбора проверяемой функции    
    [Selection, Flag_isOk] = listdlg(...
        'PromptString', 'Select a checked function name:', ...
        'SelectionMode', 'single', ...
        'ListSize', [300, 200], ...
        'ListString', ListString);

    if ~Flag_isOk
        return
    end

% Загрузка тестовых данных    
    try
        load('Source_For_Check_Functions', 'Test');
    catch
        disp('Ошибка запуска Check_Functions:');
        disp('отсутствует или испорчен файл Source_For_Check_Functions!');
        return
    end

switch ListString{Selection, 1}
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '1. Generate_Primary_Synchronisation_Code'
        disp('Проверка функции Generate_Primary_Synchronisation_Code...');
        % Попытка запуска функции
            try
                PSC = Generate_Primary_Synchronisation_Code;
            catch Error
                disp('  ошибка выполнения функции:');
                display(getReport(Error));
                return
            end
        % Проверка результатов
            Flag_isOk = true;
            if Flag_isOk
                if ~isa(PSC, 'double')
                Flag_isOk = false;
                end
            end
            if Flag_isOk
                if ~isequal(PSC, ...
                        Test.Generate_Primary_Synchronisation_Code.PSC)
                    Flag_isOk = false;
                end
            end
            if ~Flag_isOk
                disp('  Результат НЕ верный!');
                return
            end
            disp('  Результат верный!');
        
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%       
    case '2. Generate_Secondary_Synchronisation_Codes'
        disp(['Проверка функции ', ...
            'Generate_Secondary_Synchronisation_Codes...']);
        % Попытка запуска функции
            try
                SSC = Generate_Secondary_Synchronisation_Codes;
            catch Error
                disp('  ошибка выполнения функции:');
                display(getReport(Error));
                return
            end
        % Проверка результатов
            Flag_isOk = true;
            if Flag_isOk
                if ~isa(SSC, 'double')
                Flag_isOk = false;
                end
            end
            if Flag_isOk
                if ~isequal(SSC, ...
                        Test.Generate_Secondary_Synchronisation_Codes.SSC)
                    Flag_isOk = false;
                end
            end
            if ~Flag_isOk
                disp('  Результат НЕ верный!');
                return
            end
            disp('  Результат верный!');

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '3. Generate_Scrambling_Groups_Table'
        disp('Проверка функции Generate_Scrambling_Groups_Table...');
        % Попытка запуска функции
            try
                SG = Generate_Scrambling_Groups_Table;
            catch Error
                disp('  ошибка выполнения функции:');
                display(getReport(Error));
                return
            end
        % Проверка результатов
            Flag_isOk = true;
            if Flag_isOk
                if ~isa(SG, 'double')
                Flag_isOk = false;
                end
            end
            if Flag_isOk
                if ~isequal(SG, ...
                        Test.Generate_Scrambling_Groups_Table.SG)
                    Flag_isOk = false;
                end
            end
            if ~Flag_isOk
                disp('  Результат НЕ верный!');
                return
            end
            disp('  Результат верный!');
            
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '4. Generate_Channelisation_Code'
        disp('Проверка функции Generate_Channelisation_Code...');
        % Значение коэффициента расширения
            SF = 256;
        % Цикл по номерам последовательностей
            for k = 0:255
                % Попытка запуска функции
                    try
                        Ch = Generate_Channelisation_Code(SF, k);
                    catch Error
                        disp('  ошибка выполнения функции:');
                        display(getReport(Error));
                        return
                    end
                % Проверка результатов
                    Flag_isOk = true;
                    if Flag_isOk
                        if ~isa(Ch, 'double')
                            Flag_isOk = false;
                        end
                    end
                    if Flag_isOk
                        if ~isequal(Ch, ...
                                Test.Generate_Channelisation_Code.Ch( ...
                                k+1, :))
                            Flag_isOk = false;
                        end
                    end
                    if ~Flag_isOk
                        disp('  Результат НЕ верный!');
                        return
                    end
            end
        disp('  Результат верный!');

% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '5. Generate_Scrambling_Code'
        disp('Проверка функции Generate_Scrambling_Code...');
        % Цикл по номерам последовательностей        
            for k = 1:length(Test.Generate_Scrambling_Code.ns)
                % Попытка запуска функции
                    try
                        Sn = Generate_Scrambling_Code( ...
                            Test.Generate_Scrambling_Code.ns(1, k));
                    catch Error
                        disp('  ошибка выполнения функции:');
                        display(getReport(Error));
                        return
                    end
                % Проверка результатов
                    Flag_isOk = true;
                    if Flag_isOk
                        if ~isa(Sn, 'double')
                            Flag_isOk = false;
                        end
                    end
                    if Flag_isOk
                        if ~isequal(Sn, ...
                                Test.Generate_Scrambling_Code.Sn(k, :))
                            Flag_isOk = false;
                        end
                    end
                    if ~Flag_isOk
                        disp('  Результат НЕ верный!');
                        return
                    end
            end
        disp('  Результат верный!');
        
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '6. Check_CRC'
        disp('Проверка функции Check_CRC...');
        % Попытка запуска функции
            try
                [Z_Flag_isOk, Data] = Check_CRC(Test.Check_CRC.InVect, ...
                    Test.Check_CRC.CRC_Size);
            catch Error
                disp('  ошибка выполнения функции:');
                display(getReport(Error));
                return
            end
        % Проверка результатов
            Flag_isOk = true;
            if Flag_isOk
                if ~((isa(Z_Flag_isOk, 'double') || ...
                        isa(Z_Flag_isOk, 'logical')) && ...
                        isa(Data, 'double'))
                    Flag_isOk = false;
                end
            end
            if Flag_isOk
                if ~(isequal(Z_Flag_isOk, Test.Check_CRC.Flag_isOk) && ...
                        isequal(Data, Test.Check_CRC.Data))
                    Flag_isOk = false;
                end
            end
            if ~Flag_isOk
                disp('  Результат НЕ верный!');
                return
            end
        disp('  Результат верный!');
        
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '7. Convolutional_Decoder'
        disp('Проверка функции Convolutional_Decoder...');
        % Попытка запуска функции
            try
                Decoded_Vect = Convolutional_Decoder( ...
                    Test.Convolutional_Decoder.Coded_Vect, ...
                    Test.Convolutional_Decoder.Flag_isHalf);
            catch Error
                disp('  ошибка выполнения функции:');
                display(getReport(Error));
                return
            end
        % Проверка результатов
            Flag_isOk = true;
            if Flag_isOk
                if ~isa(Decoded_Vect, 'double')
                    Flag_isOk = false;
                end
            end
            if Flag_isOk
                if ~isequal(Decoded_Vect, ...
                        Test.Convolutional_Decoder.Decoded_Vect)
                    Flag_isOk = false;
                end
            end
            if ~Flag_isOk
                disp('  Результат НЕ верный!');
                return
            end
        disp('  Результат верный!');
        
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '8. First_DeInterleaver'
        disp('Проверка функции First_DeInterleaver...');
        % Цикл по значениям TTI
            for k = 1:length(Test.First_DeInterleaver.TTI)
                % Попытка запуска функции
                    try
                        Deinterleaved_Vect = First_DeInterleaver( ...
                            Test.First_DeInterleaver.Interleaved_Vect{ ...
                            k, 1}, Test.First_DeInterleaver.TTI(1, k));
                    catch Error
                        disp('  ошибка выполнения функции:');
                        display(getReport(Error));
                        return
                    end
                % Проверка результатов
                    Flag_isOk = true;
                    if Flag_isOk
                        if ~isa(Deinterleaved_Vect, 'double')
                            Flag_isOk = false;
                        end
                    end
                    if Flag_isOk
                        if ~isequal(Deinterleaved_Vect, ...
                                Test.First_DeInterleaver. ...
                                Deinterleaved_Vect{k, 1})
                            Flag_isOk = false;
                        end
                    end
                    if ~Flag_isOk
                        disp('  Результат НЕ верный!');
                        return
                    end
            end
        disp('  Результат верный!');
        
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '9. Second_DeInterleaver'
        disp('Проверка функции Second_DeInterleaver...');
        % Попытка запуска функции
            try
                Deinterleaved_Vect = Second_DeInterleaver( ...
                    Test.Second_DeInterleaver.Interleaved_Vect);
            catch Error
                disp('  ошибка выполнения функции:');
                display(getReport(Error));
                return
            end
        % Проверка результатов
            Flag_isOk = true;
            if Flag_isOk
                if ~isa(Deinterleaved_Vect, 'double')
                    Flag_isOk = false;
                end
            end
            if Flag_isOk
                if ~isequal(Deinterleaved_Vect, ...
                        Test.Second_DeInterleaver.Deinterleaved_Vect)
                    Flag_isOk = false;
                end
            end
            if ~Flag_isOk
                disp('  Результат НЕ верный!');
                return
            end
        disp('  Результат верный!');
        
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    case '0. Matched_Filter'
        disp('Проверка функции Matched_Filter...');
        % Цикл по количеству тестовых сигналов и значений отстройки частоты
            for k = 1:2
                % Попытка запуска функции
                    try
                        FSignal = Matched_Filter( ...
                            Test.Matched_Filter.Signal{k, 1}, ...
                            Test.Matched_Filter.df{k, 1});
                    catch Error
                        disp('  ошибка выполнения функции:');
                        display(getReport(Error));
                        return
                    end
                % Проверка результатов
                    Flag_isOk = true;
                    if Flag_isOk
                        if ~isa(FSignal, 'double')
                            Flag_isOk = false;
                        end
                    end
                    if Flag_isOk
                        if mean(abs(FSignal - ...
                                Test.Matched_Filter.FSignal{k, 1})) > ...
                                10^(-10)
                            Flag_isOk = false;
                        end
                    end
                    if ~Flag_isOk
                        disp('  Результат НЕ верный!');
                        if isequal(k, 1)
                            disp('  Ошибка в фильтрации!');
                        else
                            disp('  Ошибка в подстройке частоты!');
                        end
                        return
                    end
            end
        disp('  Результат верный!');
        
end

% Удаление путей
    rmpath([cd, '\Common']);
    rmpath([cd, '\Main']);