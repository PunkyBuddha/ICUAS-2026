%% Script de Exportação Total de ROSBAG
clear; clc;

% 1. Selecionar o arquivo via Explorador
[arquivo, caminho] = uigetfile('*.bag', 'Selecione o arquivo ROSBAG');
if isequal(arquivo, 0), return; end
fullPath = fullfile(caminho, arquivo);

% 2. Carregar o Bag e Criar Pasta de Destino
fprintf('Lendo arquivo: %s...\n', arquivo);
bag = rosbag(fullPath);
listaTopicos = bag.AvailableTopics.Properties.RowNames;

% Criar uma pasta com o nome do arquivo para organizar os resultados
nomePasta = strrep(arquivo, '.bag', '_exportado');
if ~exist(nomePasta, 'dir')
    mkdir(nomePasta);
end

fprintf('Exportando tópicos para a pasta: %s\n', nomePasta);

% 3. Loop para ler e salvar CADA tópico
for i = 1:length(listaTopicos)
    nomeTopico = listaTopicos{i};
    
    % Criar um nome de arquivo válido (remove / e .)
    nomeArquivoLimpo = strrep(nomeTopico, '/', '_');
    if nomeArquivoLimpo(1) == '_', nomeArquivoLimpo(1) = ''; end
    
    fprintf('Exportando: %s...\n', nomeTopico);
    
    try
        % Selecionar e ler mensagens
        sel = select(bag, 'Topic', nomeTopico);
        msgs = readMessages(sel, 'DataFormat', 'struct');
        
        % Extrair Dados e Tempo
        % Assume-se mensagens simples (Float, Int, etc). 
        % Para mensagens complexas, a estrutura completa será salva no .mat
        tempo = sel.MessageList.Time - bag.StartTime;
        
        if isfield(msgs{1}, 'Data')
            valores = cellfun(@(m) double(m.Data), msgs);
            % Criar tabela para CSV
            T = table(tempo, valores, 'VariableNames', {'Tempo_s', 'Valor'});
            writetable(T, fullfile(nomePasta, [nomeArquivoLimpo '.csv']));
        end
        
        % Salvar sempre o arquivo .mat com a struct completa (backup total)
        save(fullfile(nomePasta, [nomeArquivoLimpo '.mat']), 'msgs', 'tempo');
        
    catch
        fprintf('Aviso: Tópico %s contém dados complexos. Salvo apenas como .mat\n', nomeTopico);
        try
            sel = select(bag, 'Topic', nomeTopico);
            msgs = readMessages(sel, 'DataFormat', 'struct');
            save(fullfile(nomePasta, [nomeArquivoLimpo '.mat']), 'msgs');
        catch
            fprintf('Erro crítico ao ler tópico %s.\n', nomeTopico);
        end
    end
end

fprintf('\nConcluído! Todos os tópicos foram salvos em: %s\n', fullfile(pwd, nomePasta));