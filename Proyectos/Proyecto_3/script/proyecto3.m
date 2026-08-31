% =======================================================================
% Script: Lugar de las Raíces con Compensador Interactivo
% Estudiante: Jeffrey Salas
% =======================================================================

clear all; clc; close all;

syms K s

% Solicitar ceros y polos por separado
% Para números complejos use el formato nativo de MATLAB
zeros_str = input(['Ingrese los ceros separados por espacios (para complejos use ' ...
    'el formato #+#i; el conjugado se agrega automático) [ENTER si no hay]: '], 's');
polos_str = input(['Ingrese los polos separados por espacios (para complejos use ' ...
    'el formato #+#i; el conjugado se agrega automático): '], 's');

% Parsear ceros y polos (soporta reales y complejos)
ceros = parsear_numeros(zeros_str);
polos = parsear_numeros(polos_str);

% Construir G(s) a partir de ceros y polos ingresados
num_s = prod(s - ceros);   % si ceros está vacío, prod([]) = 1
den_s = prod(s - polos);

% Ecuación característica: 1 + K*G(s) = 0  ->  den(s) + K*num(s) = 0
K = 1;
charEq = expand(den_s + K*num_s);

% Extraer coeficientes en orden descendente de s
coefs = coeffs(charEq, s, 'All');

% Construir G(s) numérico para el lugar de las raíces
Gol = zpk(ceros, polos, 1);

%% ==================== FIGURA 1: Lugar de las raíces (interactivo) ====================
fig = figure('Name', 'Lugar de las raíces', 'NumberTitle', 'off', 'WindowStyle', 'docked');
ax = axes(fig);
ax.Position = [0.08 0.15 0.87 0.78];   % deja espacio abajo para los botones

hold(ax, 'on');
grid(ax, 'on');
axis(ax, 'equal');   % escala simétrica: 1 unidad en Real = 1 unidad Imaginario

% Marcar polos y ceros de lazo abierto (solo como referencia visual)
plot(ax, real(polos), imag(polos), 'kx', 'MarkerSize', 8, 'LineWidth', 1.5);
if ~isempty(ceros)
    plot(ax, real(ceros), imag(ceros), 'ko', 'MarkerSize', 8, 'LineWidth', 1.5);
end

xlabel(ax, 'Eje Real');
ylabel(ax, 'Eje Imaginario');
title(ax, 'Lugar de las Raíces Interactivo');

%% ==================== FIGURA 2: Respuestas (planta + compensador) ====================
fig2 = figure('Name', 'Respuesta de la planta y del compensador', 'NumberTitle', 'off', 'WindowStyle', 'docked');
ax_resp = axes(fig2, 'Position', [0.10 0.60 0.85 0.34]);
ax_resp_comp = axes(fig2, 'Position', [0.10 0.20 0.85 0.28]);

% Cuadro de texto debajo de los gráficos para la ecuación característica
h_texto_ecuacion = uicontrol(fig2, 'Style', 'text', 'Units', 'normalized', ...
    'Position', [0.05 0.02 0.9 0.1], 'HorizontalAlignment', 'left', 'FontSize', 9);

%% ==================== Datos compartidos (guardados en la figura del root locus) ====================
setappdata(fig, 's_sym', s);
setappdata(fig, 'K_sym', K);
setappdata(fig, 'ax_resp', ax_resp);
setappdata(fig, 'ax_resp_comp', ax_resp_comp);
setappdata(fig, 'fig2', fig2);
setappdata(fig, 'h_texto_ecuacion', h_texto_ecuacion);

% Estado "vivo" separado en DOS grupos independientes:
%  - "planta": los polos/ceros ingresados al inicio. Se pueden arrastrar,
%    y SOLO ellos determinan la respuesta mostrada como "Planta".
%  - "comp": los polos/ceros agregados con los botones/mouse. Se pueden
%    arrastrar, y SOLO ellos determinan la respuesta del "Compensador".
% El root locus y la ecuación característica usan los DOS grupos juntos.
setappdata(fig, 'polos_planta_actuales', polos);
setappdata(fig, 'ceros_planta_actuales', ceros);
setappdata(fig, 'polos_comp_actuales', []);
setappdata(fig, 'ceros_comp_actuales', []);
setappdata(fig, 'siguiente_num_polo_comp', 1);
setappdata(fig, 'siguiente_num_cero_comp', 1);

% Puntos arrastrables para los polos y ceros de la PLANTA (los ingresados al inicio)
    % Enlaza cada par conjugado como "pareja", igual que al agregar uno con clic,
    % para que al arrastrar uno de los dos el otro se refleje automáticamente.
crear_puntos_iniciales(fig, ax, 'polo', 'planta', polos);
crear_puntos_iniciales(fig, ax, 'zero', 'planta', ceros);

% Botones para agregar polos y ceros
uicontrol(fig, 'Style', 'pushbutton', 'String', 'Agregar Polo', ...
    'Units', 'normalized', 'Position', [0.02 0.02 0.15 0.06], ...
    'Callback', @(src, evt) agregar_polo(fig, ax));

uicontrol(fig, 'Style', 'pushbutton', 'String', 'Agregar Cero', ...
    'Units', 'normalized', 'Position', [0.20 0.02 0.15 0.06], ...
    'Callback', @(src, evt) agregar_cero(fig, ax));

refrescar_todo(fig, ax);


%% ==================== FUNCIONES ====================

function refrescar_todo(fig, ax)
    polos_planta_actuales = getappdata(fig, 'polos_planta_actuales');
    ceros_planta_actuales = getappdata(fig, 'ceros_planta_actuales');
    polos_comp_actuales = getappdata(fig, 'polos_comp_actuales');
    ceros_comp_actuales = getappdata(fig, 'ceros_comp_actuales');
    s = getappdata(fig, 's_sym');
    K = getappdata(fig, 'K_sym');
    ax_resp = getappdata(fig, 'ax_resp');
    ax_resp_comp = getappdata(fig, 'ax_resp_comp');
    h_texto_ecuacion = getappdata(fig, 'h_texto_ecuacion');

    % Sistema total en lazo abierto = planta (en su posición actual) + compensador agregado
    polos_totales = [polos_planta_actuales, polos_comp_actuales];
    ceros_totales = [ceros_planta_actuales, ceros_comp_actuales];

    % --- Root locus actualizado (Figura 1), con el sistema total ---
    fprintf('//////////////////////////////////////////////////////////////////\n')
    G_ol = zpk(ceros_totales, polos_totales, 1)
    [r, ~] = rlocus(G_ol);

    h_locus = getappdata(fig, 'h_locus');
    if ~isempty(h_locus)
        delete(h_locus(isgraphics(h_locus)));
    end
    h_locus = plot(ax, real(r).', imag(r).', 'Color', [0.3 0.6 1]);
    uistack(h_locus, 'bottom');   % que la curva no tape los puntos arrastrables
    setappdata(fig, 'h_locus', h_locus);

    % --- Ecuación característica del sistema total (planta + compensador) ---
    num_nueva = prod(s - ceros_totales);
    den_nueva = prod(s - polos_totales);
    Ec_caracteristica = expand(den_nueva + K*num_nueva);
    coefs_nueva = coeffs(Ec_caracteristica, s, 'All');
    texto = sprintf('EC: 1 + K*G(s)*C(s) = 0  -->  %s = 0', formatear_polinomio(coefs_nueva, 's'));
    h_texto_ecuacion.String = texto;

    % --- Planta y compensador POR SEPARADO, cada uno con SOLO sus propios puntos ---
    G_planta_actual = zpk(ceros_planta_actuales, polos_planta_actuales, 1);
    Gc = minreal(zpk(ceros_comp_actuales, polos_comp_actuales, 1));

    % Compensador solo, SIN realimentación (bloque aislado)
    try
        [y_comp, t_comp] = step(Gc);
        compensador_valido = true;
    catch
        compensador_valido = false;
    end

    % Planta, y Planta+Compensador, ambos CON realimentación unitaria
    % (coincide con lo que muestra Control System Designer)
    try
        Gcl_planta = feedback(G_planta_actual, 1);
        [y_planta, t_planta] = step(Gcl_planta);
        planta_valida = true;
    catch
        planta_valida = false;
    end

    try
        G_cl = feedback(G_ol, 1)
        [y_total, t_total] = step(G_cl);
        total_valido = true;
    catch
        total_valido = false;
    end

    % Ec_caracteristica
    fprintf('\n Ecuación característica:\n %s = 0', formatear_polinomio(coefs_nueva, 's'));
    fprintf('\n//////////////////////////////////////////////////////////////////\n')

    % --- Gráfico superior: Planta vs Planta+Compensador (lazo cerrado) ---
    cla(ax_resp);
    hold(ax_resp, 'on');
    leyenda_resp = {};
    if planta_valida
        plot(ax_resp, t_planta, y_planta, 'Color', [0 0.4470 0.7410], 'LineWidth', 1.5);
        leyenda_resp{end+1} = 'Planta (lazo cerrado)';
    end
    if total_valido
        plot(ax_resp, t_total, y_total, 'Color', [0.4660 0.6740 0.1880], 'LineWidth', 1.5, 'LineStyle', '--');
        leyenda_resp{end+1} = 'Planta + Compensador (lazo cerrado)';
    end
    avisos_resp = {};
    if ~planta_valida
        avisos_resp{end+1} = 'Planta en lazo cerrado no realizable';
    end
    if ~total_valido
        avisos_resp{end+1} = 'Planta+Compensador en lazo cerrado no realizable';
    end
    if ~isempty(avisos_resp)
        text(ax_resp, 0.03, 0.95, avisos_resp, 'Units', 'normalized', 'HorizontalAlignment', 'left', ...
            'VerticalAlignment', 'top', 'Color', [0.85 0.33 0.10], 'FontWeight', 'bold', 'FontSize', 8);
    end
    grid(ax_resp, 'on');
    xlabel(ax_resp, 'Tiempo (s)');
    ylabel(ax_resp, 'Amplitud');
    title(ax_resp, 'Respuesta en Lazo Cerrado');
    if ~isempty(leyenda_resp)
        legend(ax_resp, leyenda_resp, 'Location', 'best');
    end

    % --- Gráfico inferior: Compensador solo (sin realimentación) ---
    cla(ax_resp_comp);
    hold(ax_resp_comp, 'on');
    if compensador_valido
        plot(ax_resp_comp, t_comp, y_comp, 'Color', [0.8500 0.3250 0.0980], 'LineWidth', 1.5);
        legend(ax_resp_comp, {'Compensador (sin realimentación)'}, 'Location', 'best');
    else
        text(ax_resp_comp, 0.5, 0.5, 'Compensador no realizable (impropio): agregue al menos un polo', ...
            'Units', 'normalized', 'HorizontalAlignment', 'center', 'Color', [0.85 0.33 0.10], 'FontWeight', 'bold');
    end
    grid(ax_resp_comp, 'on');
    xlabel(ax_resp_comp, 'Tiempo (s)');
    ylabel(ax_resp_comp, 'Amplitud');
    title(ax_resp_comp, 'Respuesta del Compensador');
end


function actualizar_punto(fig, ax, src, pos)
    info = src.UserData;
    val = pos(1) + 1i*pos(2);

    if isempty(info.partner)
        val = real(val);   % es un punto real (bloqueado al eje): forzar Im=0 exacto
    end

    if strcmp(info.tipo, 'polo')
        base = 'polos';
    else
        base = 'ceros';
    end
    campo = sprintf('%s_%s_actuales', base, info.grupo);   % ej: 'polos_planta_actuales'

    lista = getappdata(fig, campo);
    lista(info.idx) = val;

    if ~isempty(info.partner) && isvalid(info.partner)
        conj_val = conj(val);
        info.partner.Position = [real(conj_val), imag(conj_val)];   % mover la pareja al conjugado exacto
        lista(info.partner.UserData.idx) = conj_val;
    end

    setappdata(fig, campo, lista);
    refrescar_todo(fig, ax);
end


% Mueve el punto al eje Real si se coloca a 2% del rango vertical visible.
function tf = es_real(ax, y)
    tol = 0.02 * diff(ax.YLim);
    tf = abs(y) < tol;
end


% Convierte un texto con números (reales o complejos) separados por
% espacios en un vector.
    % Si un valor tiene parte imaginaria, se agrega su conjugado
    % automáticamente (sin duplicar si ya se escribió).
function vals = parsear_numeros(str_entrada)    
    if isempty(strtrim(str_entrada))
        vals = [];
        return;
    end

    tokens = strsplit(strtrim(str_entrada));
    vals = [];
    for k = 1:numel(tokens)
        tok = tokens{k};
        if isempty(tok)
            continue;
        end
        v = str2double(tok);
        if isnan(v)
            error(['Entrada inválida: "%s" no es un número válido. Para complejos use ' ...
                'el formato de MATLAB, ej: #+#i (el coeficiente va antes de la i).'], tok);
        end

        if any(abs(vals - v) < 1e-9)
            continue;   % ya estaba en la lista (ej. agregado como conjugado automático)
        end
        vals(end+1) = v; %#ok<AGROW>

        if abs(imag(v)) > 1e-9
            v_conj = conj(v);
            if ~any(abs(vals - v_conj) < 1e-9)
                vals(end+1) = v_conj; %#ok<AGROW>
            end
        end
    end
end


% Crea los puntos arrastrables iniciales, enlazando cada par conjugado
% para que arrastrar uno mueva al otro reflejado exactamente.
function crear_puntos_iniciales(fig, ax, tipo, grupo, valores)     
    n = numel(valores);
    procesado = false(1, n);
    for i = 1:n
        if procesado(i)
            continue;
        end
        j = [];
        if abs(imag(valores(i))) > 1e-9
            candidatos = find(abs(valores - conj(valores(i))) < 1e-9 & ~procesado);
            candidatos(candidatos == i) = [];
            if ~isempty(candidatos)
                j = candidatos(1);
            end
        end

        p1 = crear_punto(fig, ax, tipo, grupo, i, i, real(valores(i)), imag(valores(i)), []);
        procesado(i) = true;

        if ~isempty(j)
            crear_punto(fig, ax, tipo, grupo, j, i, real(valores(j)), imag(valores(j)), p1);
            procesado(j) = true;
        end
    end
end


function p = crear_punto(fig, ax, tipo, grupo, idx, num, x, y, partner)
    if strcmp(tipo, 'polo')
        color = 'r';
    else
        color = 'b';
    end

    % Prefijo de la etiqueta: distingue visualmente los puntos de la
    % planta (P/Z) de los agregados como compensador (Pc/Zc)
    if strcmp(grupo, 'planta')
        prefijo = tipo(1);
        prefijo = upper(prefijo);
    else
        prefijo = [upper(tipo(1)) 'c'];
    end

    if es_real(ax, y) && isempty(partner)
        y = 0;   % forzar exactamente al eje real
        drawing_area = [-1e6, -1e-9, 2e6, 2e-9];
    else
        drawing_area = [-1e6, -1e6, 2e6, 2e6];
    end

    p = images.roi.Point(ax, 'Position', [x, y], 'Color', color, 'DrawingArea', drawing_area);

    if isempty(partner)
        p.Label = sprintf('%s%d', prefijo, num);
    else
        p.Label = sprintf('%s%d*', prefijo, num);
        partner.UserData.partner = p;   % enlazar la pareja existente hacia este nuevo punto
    end

    p.UserData = struct('idx', idx, 'num', num, 'tipo', tipo, 'grupo', grupo, 'partner', partner);
    addlistener(p, 'ROIMoved', @(src, evt) actualizar_punto(fig, ax, src, evt.CurrentPosition));
end


function agregar_polo(fig, ax)
    p_temp = drawpoint(ax, 'Color', 'r');
    if isempty(p_temp.Position)
        return;
    end
    pos = p_temp.Position;
    delete(p_temp);   % es solo para capturar el click; el punto real lo arma crear_punto

    if es_real(ax, pos(2))
        pos(2) = 0;   % forzar exactamente al eje real
    end

    polos_comp_actuales = getappdata(fig, 'polos_comp_actuales');
    idx = numel(polos_comp_actuales) + 1;
    polos_comp_actuales(idx) = pos(1) + 1i*pos(2);
    setappdata(fig, 'polos_comp_actuales', polos_comp_actuales);

    num = getappdata(fig, 'siguiente_num_polo_comp');
    setappdata(fig, 'siguiente_num_polo_comp', num + 1);

    p = crear_punto(fig, ax, 'polo', 'comp', idx, num, pos(1), pos(2), []);

    if ~es_real(ax, pos(2))
        polos_comp_actuales = getappdata(fig, 'polos_comp_actuales');
        conj_val = conj(pos(1) + 1i*pos(2));
        idx_nuevo = numel(polos_comp_actuales) + 1;
        polos_comp_actuales(idx_nuevo) = conj_val;
        setappdata(fig, 'polos_comp_actuales', polos_comp_actuales);
        crear_punto(fig, ax, 'polo', 'comp', idx_nuevo, num, real(conj_val), imag(conj_val), p);
    end

    refrescar_todo(fig, ax);
end

function agregar_cero(fig, ax)
    z_temp = drawpoint(ax, 'Color', 'b');
    if isempty(z_temp.Position)
        return;
    end
    pos = z_temp.Position;
    delete(z_temp);

    if es_real(ax, pos(2))
        pos(2) = 0;   % forzar exactamente al eje real
    end

    ceros_comp_actuales = getappdata(fig, 'ceros_comp_actuales');
    idx = numel(ceros_comp_actuales) + 1;
    ceros_comp_actuales(idx) = pos(1) + 1i*pos(2);
    setappdata(fig, 'ceros_comp_actuales', ceros_comp_actuales);

    num = getappdata(fig, 'siguiente_num_cero_comp');
    setappdata(fig, 'siguiente_num_cero_comp', num + 1);

    z = crear_punto(fig, ax, 'zero', 'comp', idx, num, pos(1), pos(2), []);

    if ~es_real(ax, pos(2))
        ceros_comp_actuales = getappdata(fig, 'ceros_comp_actuales');
        conj_val = conj(pos(1) + 1i*pos(2));
        idx_nuevo = numel(ceros_comp_actuales) + 1;
        ceros_comp_actuales(idx_nuevo) = conj_val;
        setappdata(fig, 'ceros_comp_actuales', ceros_comp_actuales);
        crear_punto(fig, ax, 'zero', 'comp', idx_nuevo, num, real(conj_val), imag(conj_val), z);
    end

    refrescar_todo(fig, ax);
end


% Arma string de un polinomio: orden descendente,
% coeficientes en decimal (no fracciones), omite términos con
% coeficiente ~0.
function str = formatear_polinomio(coefs_vec, nombre_var)    
    n = numel(coefs_vec) - 1;
    partes = {};
    for k = 0:n
        c = double(coefs_vec(k+1));
        if abs(c) < 1e-10
            continue;
        end
        grado = n - k;
        if grado == 0
            cuerpo = sprintf('%.4g', abs(c));
        elseif grado == 1
            cuerpo = sprintf('%.4g*%s', abs(c), nombre_var);
        else
            cuerpo = sprintf('%.4g*%s^%d', abs(c), nombre_var, grado);
        end
    
        if isempty(partes)
            if c < 0
                partes{end+1} = ['-' cuerpo]; %#ok<AGROW>
            else
                partes{end+1} = cuerpo; %#ok<AGROW>
            end
        else
            if c < 0
                partes{end+1} = [' - ' cuerpo]; %#ok<AGROW>
            else
                partes{end+1} = [' + ' cuerpo]; %#ok<AGROW>
            end
        end
    end
    
    if isempty(partes)
        str = '0';
    else
        str = strjoin(partes, '');
    end
end