clear all; clc; close all;

syms s
syms K real

% Solicitar ceros y polos por separado
zeros_str = input('Ingrese los ceros de G(s) separados por espacios (presiona [ENTER] si no hay): ', 's');
polos_str = input('Ingrese los polos de G(s) separados por espacios: ', 's');

% Parsear ceros
if isempty(strtrim(zeros_str))
    ceros = [];
else
    ceros = str2double(strsplit(strtrim(zeros_str)));
end

% Parsear polos
if isempty(strtrim(polos_str))
    polos = [];
else
    polos = str2double(strsplit(strtrim(polos_str)));
end

% Validación básica: que no hayan quedado NaN por texto mal escrito
if any(isnan(ceros)) || any(isnan(polos))
    error('Entrada inválida: verifique que solo ingresó números separados por espacios.');
end



% Construir G(s) a partir de ceros y polos ingresados
num_s = prod(s - ceros);   % si ceros está vacío, prod([]) = 1
den_s = prod(s - polos);

% Ecuación característica: 1 + K*G(s) = 0  ->  den(s) + K*num(s) = 0
charEq = expand(den_s + K*num_s);

% Extraer coeficientes en orden descendente de s
coefs = coeffs(charEq, s, 'All');



% Routh-Hurwitz
% Tamaño de la matriz según el grado de la ecuación característica
grado  = numel(coefs) - 1;      % grado del polinomio
nfilas = grado + 1;             % una fila por cada potencia de s, desde s^grado hasta s^0
ncols  = ceil(nfilas/2);

R = sym(zeros(nfilas, ncols));  % Matriz

% Primeras dos filas: coeficientes en posiciones impares y pares
fila1 = coefs(1:2:end);
fila2 = coefs(2:2:end);
R(1, 1:numel(fila1)) = fila1;
R(2, 1:numel(fila2)) = fila2;

% Filas restantes por la fórmula recursiva de Routh
for n = 3:nfilas
    for m = 1:ncols-1
        R(n,m) = (R(n-1,1)*R(n-2,m+1) - R(n-2,1)*R(n-1,m+1)) / R(n-1,1);
        R(n,m) = simplify(R(n,m));
    end
end



% Condición de estabilidad: Toda la primera columna de la tabla de Routh 
% debe ser positiva.
fprintf('\n');
fprintf('--- Tabla de Routh ---\n');
disp(R) % Muestra la tabla completa de Routh-Hurwitz

fprintf('--- Condiciones de estabilidad ---\n');
fprintf('Primera columna de tabla de Routh:\n')
primera_col = simplify(R(:,1));  % Solamente muestra la primera columna
disp(primera_col)                % de la tabla Routh

% Analiza si hay estabilidad y en que rangos de K hay estabilidad
sistema_estable = true;
for idx = 1:numel(primera_col)
    expr = primera_col(idx);

    if has(expr, K)
        [num_expr, den_expr] = numden(expr);
    
        raices = [solve(num_expr == 0, K); solve(den_expr == 0, K)];
        raices = double(raices);
        raices = raices(abs(imag(raices)) < 1e-9);     % solo reales
        raices = sort(unique(raices(raices > 0)));     % solo K positivas
    
        limites = [0; raices; Inf];
    
        fprintf('Fila %d (%s > 0):', idx, char(expr));
        hay_intervalo_estable = false;
        for b = 1:numel(limites)-1
            if isinf(limites(b+1))
                punto_prueba = limites(b) + 1;
            else
                punto_prueba = (limites(b) + limites(b+1)) / 2;
            end
    
            valor = double(subs(expr, K, punto_prueba));
    
            if valor > 0
                fprintf('   Sistema Estable en: [%.4g  <  K  <  %.4g]\n', limites(b), limites(b+1));
                hay_intervalo_estable = true;
            end
        end
        if ~hay_intervalo_estable
            sistema_estable = false;
            fprintf('   Nunca se cumple para K >= 0 -> Sistema Inestable\n');
        end

    else
        if double(expr) > 0
            fprintf('Fila %d (%s > 0):  Siempre se cumple -> Sistema Estable\n', idx, char(expr));
        else
            sistema_estable = false;
            fprintf('Fila %d (%s > 0):  NUNCA se cumple -> Sistema Inestable\n', idx, char(expr));            
        end
    end
end

fprintf('\n');
if sistema_estable
    fprintf('En conclusión, el Sistema es Estable en el rango de K más pequeño, porque en ese rango no hay cambio de signo de ningún elemento en la primera columna de la tabla de Routh\n');
else
    fprintf('En conclusión, el Sistema es Inestable porque no hay un rango de K que evite el cambio de signo de al menos un elemento en la primera columna de la tabla de Routh\n');
end



% Lugar de las raíces (root locus)
% Construir G(s) numérico para el lugar de las raíces
G = zpk(ceros, polos, 1);

figure;
rlocus(G);
hold on;

% Marcar polos y ceros de lazo abierto
if ~isempty(ceros)
    plot(real(ceros), imag(ceros), 'bo', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Ceros');
end
plot(real(polos), imag(polos), 'rx', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Polos');

legend('show');
grid on;
title('Lugar de las raíces de G(s)');
xlabel('Eje Real');
ylabel('Eje Imaginario');
hold off;