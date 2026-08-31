# Proyecto 3: Lugar de las Raíces con Compensador Interactivo

- Estudiante: Jeffrey Salas | Carné: 2020186279

Script de MATLAB para diseñar un compensador en cascada de forma interactiva: se ingresan los polos y ceros de la planta, se dibuja el lugar de las raíces del sistema en lazo abierto, y se pueden arrastrar esos puntos (o agregar nuevos con el mouse) para ver en tiempo real cómo cambian la función de transferencia, la ecuación característica y la respuesta al escalón del sistema.

## Ubicación

El script `proyecto3.m` se encuentra en la carpeta `script/`.

## Requisitos

MATLAB con las siguientes toolboxes:

- **Symbolic Math Toolbox** — construye y expande simbólicamente la ecuación característica (`syms`, `expand`, `coeffs`).
- **Control System Toolbox** — modelo `zpk`, lugar de las raíces (`rlocus`), realimentación (`feedback`), reducción (`minreal`) y respuesta al escalón (`step`).
- **Image Processing Toolbox** — puntos interactivos arrastrables (`drawpoint`, `images.roi.Point`).

## Guía de uso

### 1. Ejecutar el script
Con la carpeta `script` en el path de MATLAB, escriba `proyecto3` en la línea de comandos y presione **ENTER**, o abra el archivo y presione el botón **RUN**.

### 2. Ingresar ceros y polos
El script pide primero los ceros y luego los polos, cada uno en una sola línea con los valores separados por espacios. Ejemplo:

```
Ingrese los ceros separados por espacios ...: -2 -6i -1+5i -4+3j
Ingrese los polos separados por espacios ...: 0 -6 -3+4i
```

Reglas del formato:
- Los números complejos se escriben en formato nativo de MATLAB, **sin espacios internos**: `-1+5i` o `-4+3j` (no `-1 + 5i`, porque el `+` quedaría como un token separado). El sufijo puede ser `i` o `j` indistintamente.
- No hace falta escribir el conjugado: si se ingresa `-1+5i`, el script agrega automáticamente `-1-5i`. Si de todas formas se escribe a mano, no se duplica.
- Los ceros pueden dejarse vacíos (ENTER sin escribir nada) si el sistema no tiene ceros. Se recomienda ingresar al menos un polo para que el lugar de las raíces y las respuestas tengan sentido.
- Después de escribir los ceros se presiona **ENTER** para pasar a los polos, y de nuevo **ENTER** al terminar con los polos.

### 3. Salida en la línea de comandos
Cada vez que el sistema se recalcula (al iniciar, al arrastrar un punto o al agregar uno nuevo) la ventana de comandos muestra:
- La función de transferencia en lazo abierto (planta + compensador agregado).
- La función de transferencia en lazo cerrado con realimentación unitaria, si es realizable.
- La ecuación característica expandida, con coeficientes numéricos.

### 4. Figura 1 — Lugar de las raíces interactivo
- Los puntos ingresados al inicio (la **planta**) quedan marcados dos veces: una **x/o negra fija** que marca la posición original y no se mueve, y un **punto de color arrastrable** (rojo = polo, azul = cero) etiquetado `P#`/`Z#`, que sí se puede mover.
- Si un punto pertenece a un par conjugado, su etiqueta lleva un asterisco (`P1*`, `Z1*`) y, al arrastrar cualquiera de los dos, el otro se refleja automáticamente sobre el eje real.
- Un punto ingresado (o soltado) muy cerca del eje real — dentro del 2 % del rango vertical visible — queda **bloqueado sobre el eje real**: solo se puede mover horizontalmente y su parte imaginaria se fuerza siempre a 0. Un punto complejo, en cambio, se mueve libremente junto con su pareja conjugada, pero **no se pueden colocar sobre el eje real (y = 0)**.
- La curva celeste es el lugar de las raíces del sistema total (planta + compensador) y se redibuja automáticamente después de cada cambio.
- Al crearse la gráfica por primera vez, los límites de los ejes se ajustan para tratar de mostrar la curva completa, entonces la vista inicial puede dejar los polos/ceros pequeños y amontonados en el centro. Haga zoom con el **scroll del mouse** sobre la zona.

### 5. Agregar polos/ceros de compensador
Los botones **Agregar Polo** y **Agregar Cero**, en la esquina inferior izquierda de la Figura 1, activan el modo de click: al hacer click sobre el plano se crea un nuevo punto.
- Estos puntos se etiquetan `Pc#`/`Zc#` para diferenciarlos de los de la planta, y se tratan internamente como un **compensador en cascada**, independiente de la planta.
- Si el click se hace cerca del eje real, el punto se agrega como real; si no, se agrega automáticamente su conjugado.
- No hay forma de eliminar un punto una vez agregado; para quitarlo hay que volver a ejecutar el script.

### 6. Figura 2 — Respuestas
Debajo de las dos gráficas hay un cuadro de texto con la ecuación característica actual (`1 + K*G(s)*C(s) = 0`, con `K = 1`; el barrido real de ganancia para el lugar de las raíces lo hace `rlocus` internamente, no depende de este valor).

- **Gráfica superior — Respuesta en lazo cerrado:** compara, ambas con realimentación unitaria, la respuesta al escalón de la **planta sola** (línea sólida azul) contra la de **planta + compensador** (línea punteada verde). Si alguna de las dos no es realizable, se muestra un aviso en lugar de la curva.
- **Gráfica inferior — Respuesta del compensador:** respuesta al escalón del **compensador solo, sin realimentación** (usa únicamente los puntos `Pc#`/`Zc#`). Si todavía no se agregó ningún polo de compensador se muestra un línea constante en 1.

## Notas y limitaciones
- Los puntos no se pueden eliminar ni deshacer individualmente; para reiniciar el diseño hay que volver a correr el script.
- Ambas figuras se abren en modo `docked`; si prefiere verlas como ventanas independientes, puede desacoplarlas desde el menú de la pestaña de la figura.