% =======================================================================
% Script: Respuesta al Escalón Unitario - Sistema de Primer Orden
% Función de transferencia: G(s) = K / (T*s + 1)
% Profesor de Control Automático: Luis Carlos Rosales | Github: lcrosales
% =======================================================================

clear all; clc; close all;

%%%%% 1. Cargar el paquete de control (Requisito fundamental en Octave)
%pkg load control;

% 2. Parámetros del sistema (Modificar según la planta a analizar)
K = 1;  % Ganancia en estado estable
T = 0.5;  % Constante de tiempo [segundos]

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
% Se simula hasta 10 veces T, tiempo en el que el sistema alcanza el 99.3% del valor final.
t_final = 10 * T;
t = 0:0.01:t_final;

% 5. Cálculo de la respuesta al escalón unitario
[y, t] = step(G, t);

% 6. Graficación y formato didáctico
figure('Name', 'Respuesta al Escalón - Sistema de Primer Orden');
plot(t, y, 'b-', 'LineWidth', 2);
grid on;
hold on;

% --- Puntos y líneas de referencia didácticas ---

% a) Valor final en estado estable (y_final = K)
line([0 t_final], [K K], 'Color', 'r', 'LineStyle', '--', 'LineWidth', 1.5);

% b) Punto característico en t = T (63.2% del valor final)
y_T = 0.632 * K;
plot(T, y_T, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
line([T T], [0 y_T], 'Color', 'k', 'LineStyle', ':');
line([0 T], [y_T y_T], 'Color', 'k', 'LineStyle', ':');

% c) Punto característico en t = 4T (98.2% - Criterio de tiempo de asentamiento)
t_asentamiento = 4 * T;
y_4T = 0.982 * K;
plot(t_asentamiento, y_4T, 'mo', 'MarkerSize', 8, 'MarkerFaceColor', 'm');

% 7. Títulos y Leyendas
title(['Respuesta al Escalón Unitario: G(s) = ', num2str(K), ' / (', num2str(T), 's + 1)'], 'FontSize', 12);
xlabel('Tiempo (s)', 'FontSize', 11);
ylabel('Respuesta y(t)', 'FontSize', 11);

legend('Respuesta y(t)', ...
       ['Valor final (K = ', num2str(K), ')'], ...
       ['t = T (63.2% K = ', num2str(y_T), ')'], ...
       ['t = 4T (Tiempo de asentamiento 2% = ', num2str(t_asentamiento), 's)'], ...
       'Location', 'southeast');

xlim([0 t_final]);
ylim([0 K * 1.15]);