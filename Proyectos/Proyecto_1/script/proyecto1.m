% =======================================================================
% Script: Respuesta al Escalón Unitario - Sistema de Primer Orden
% Función de transferencia: G(s) = K / (T*s + 1)
% Profesor de Control Automático: Luis C. Rosales | Github: lcrosales
% Estudiante: Jeffrey Salas
% =======================================================================

clear all; clc; close all;

%%%%% 0. Cargar el paquete de control (Requisito fundamental en Octave)
%pkg load control;

% 1. Ingreso de parámetros desde la línea de comandos con validación (>= 0)

J = input('Ingrese J (momento de inercia) [kg*m^2]: ');
while ~isnumeric(J) || isempty(J) || J < 0
    disp('Valor inválido. J debe ser un número mayor o igual a 0.');
    J = input('Ingrese J (momento de inercia) [kg*m^2]: ');
end

Ra = input('Ingrese Ra (resistencia de armadura) [Ohm]: ');
while ~isnumeric(Ra) || isempty(Ra) || Ra < 0
    disp('Valor inválido. Ra debe ser un número mayor o igual a 0.');
    Ra = input('Ingrese Ra (resistencia de armadura) [Ohm]: ');
end

b = input('Ingrese b (coeficiente de fricción de motor) [N*m*s/rad]: ');
while ~isnumeric(b) || isempty(b) || b < 0
    disp('Valor inválido. b debe ser un número mayor o igual a 0.');
    b = input('Ingrese b (coeficiente de fricción de motor) [N*m*s/rad]: ');
end

Kt = input('Ingrese Kt (constante de par) [N*m/A]: ');
while ~isnumeric(Kt) || isempty(Kt) || Kt < 0
    disp('Valor inválido. Kt debe ser un número mayor o igual a 0.');
    Kt = input('Ingrese Kt (constante de par) [N*m/A]: ');
end

Kb = input('Ingrese Kb (constante de fuerza electromotriz) [V*s/rad]: ');
while ~isnumeric(Kb) || isempty(Kb) || Kb < 0
    disp('Valor inválido. Kb debe ser un número mayor o igual a 0.');
    Kb = input('Ingrese Kb (constante de fuerza electromotriz) [V*s/rad]: ');
end

% 2. Parámetros del sistema (Modificar según la planta a analizar)
K = Kt/(Ra*b+Kt*Kb);  % Ganancia en estado estable
T = Ra*J/(Ra*b+Kt*Kb);  % Constante de tiempo [segundos]

% 3. Definición de la Función de Transferencia G(s)
% Numerador: [K]
% Denominador: [T, 1] que representa (T*s + 1)
num = [K];
den = [T, 1];
G = tf(num, den);

% Imprimir la función de transferencia en la ventana de comandos
disp('Función de Transferencia Obtenida G(s):');
G

% 4. Definición del vector de tiempo de simulación
% Se simula hasta 10 veces T, 
% En 5T el sistema alcanza el 99.3% del valor final.
t_final = 10 * T;
t = 0:0.01:t_final;

t_f = 5 * T;

% 5. Cálculo de la respuesta al escalón unitario
[y, t] = step(G, t);

% 6. Graficación y formato didáctico
figure('Name', 'Respuesta al Escalón - Sistema de Primer Orden');
plot(t, y, 'b-', 'LineWidth', 2);
grid on;
hold on;


% --- Puntos y líneas de referencia didácticas ---

% a) Valor final en estado estable (y_f = K)
line([0 t_final], [K K], 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);

% b) Punto característico en t = T (63.2% del valor final)
y_T = 0.632 * K;

line([T T], [0 y_T], 'Color', 'k', 'LineStyle', ':', 'HandleVisibility', 'off');
line([0 T], [y_T y_T], 'Color', 'k', 'LineStyle', ':', 'HandleVisibility', 'off');

plot(T, y_T, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');

% c) Punto característico en t = 4T (98.2% - Criterio de tiempo de asentamiento)
t_a2 = 4 * T;
y_4T = 0.982 * K;

line([4*T 4*T], [0 y_4T], 'Color', 'k', 'LineStyle', ':', 'HandleVisibility', 'off');
line([0 4*T], [y_4T y_4T], 'Color', 'k', 'LineStyle', ':', 'HandleVisibility', 'off');

plot(t_a2, y_4T, 'mo', 'MarkerSize', 8, 'MarkerFaceColor', 'm');

% d) Punto característico en t = 5T (99.3% - Tiempo de asentamiento)
t_asentamiento = 5 * T;
y_5T = 0.993 * K;

line([5*T 5*T], [0 y_5T], 'Color', 'k', 'LineStyle', ':', 'HandleVisibility', 'off');
line([0 5*T], [y_5T y_5T], 'Color', 'k', 'LineStyle', ':', 'HandleVisibility', 'off');

plot(t_asentamiento, y_5T, 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'g');


% e) Error de estado estacionario (solo si existe)
r_final = 1;              % Valor de referencia (entrada escalón unitario)
ess = r_final - K;        % Error de estado estacionario
tol = 1e-6;               % Tolerancia para considerar que hay error

hay_error = abs(ess) > tol;

if hay_error
    % Línea de referencia r(t) = 1
    line([0 t_final], [r_final r_final], 'Color', 'k', ...
        'LineStyle', '-.', 'LineWidth', 1.3, 'HandleVisibility', 'off');

    % Indicador vertical del error, ubicado cerca del final del eje x
    x_err = 0.65 * t_final;
    line([x_err x_err], [K r_final], 'Color', [0.9 0.5 0], 'LineStyle', ':', ...
        'LineWidth', 1.8);

    % Texto con el valor numérico del error
    text(x_err + 0.05*t_final, (K + r_final)/2, ...
        sprintf('e_{ss} = %.2f (%.0f%%)', ess, ess*100), ...
        'Color', [0.9 0.5 0]);
end



% 7. Títulos y Leyendas
title(['Respuesta al Escalón Unitario: G(s) = ', num2str(K), ' / (', num2str(T), 's + 1)'], 'FontSize', 12);
xlabel('Tiempo (s)', 'FontSize', 11);
ylabel('Respuesta y(t)', 'FontSize', 11);

legend('Respuesta y(t)', ...
    ['Valor final (K = ', num2str(K), ')'], ...
    ['t = T (63.2% K = ', num2str(y_T), ')'], ...
    ['t = 4T (Tiempo 2% de asentamiento = ', num2str(t_a2), 's)'], ...
    ['t = 5T (Tiempo de asentamiento = ', num2str(t_asentamiento), 's)'], ...
    ['Ess = ', num2str(ess), ' (', num2str(ess*100), '%)'], ...
    'Location', 'southeast');

xlim([0 t_final]);
ylim([0 K * 1.15]);