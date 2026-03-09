# Documentación: Barredora Automática (barredora.vhd)

## Descripción
Este módulo implementa el control de una barredora "inteligente" mediante una Máquina de Estados Finitos (FSM) de Moore. El sistema alterna el sentido del giro (derecha/izquierda) cada vez que encuentra un obstáculo, siguiendo una secuencia cíclica.

## Interfaz (Puertos)
*   **CLK:** Reloj del sistema.
*   **RST:** Reset asíncrono (activo en alto).
*   **SENSOR:** Entrada del sensor, corresponde a la señal **B** (1 = Obstáculo, 0 = Libre).
*   **MOTOR_IZQ:** Salida motor Rueda Izquierda.
*   **MOTOR_DER:** Salida motor Rueda Derecha.

## Lógica de Movimiento
*   **Avanzar:** `MOTOR_IZQ='1'`, `MOTOR_DER='1'`.
*   **Giro Derecha:** `MOTOR_IZQ='0'`, `MOTOR_DER='1'`.
*   **Giro Izquierda:** `MOTOR_IZQ='1'`, `MOTOR_DER='0'`.

## Tabla de Estados Siguientes

| Descripción | Estado Actual | Entrada (SENSOR/B) | Estado Siguiente | Salidas (MI, MD) |
|:-----------:|:-------------:|:------------------:|:----------------:|:----------------:|
| Avance 1    | **$A_1$**     | 0 (Libre)          | $A_1$            | 1, 1             |
| Avance 1    | **$A_1$**     | 1 (Obstáculo)      | D                | 1, 1             |
| Derecha     | **D**         | 1 (Obstáculo)      | D                | 0, 1             |
| Derecha     | **D**         | 0 (Libre)          | $A_2$            | 0, 1             |
| Avance 2    | **$A_2$**     | 0 (Libre)          | $A_2$            | 1, 1             |
| Avance 2    | **$A_2$**     | 1 (Obstáculo)      | I                | 1, 1             |
| Izquierda   | **I**         | 1 (Obstáculo)      | I                | 1, 0             |
| Izquierda   | **I**         | 0 (Libre)          | $A_1$            | 1, 0             |

## Diagrama de Estados (Moore)

```mermaid
%%{init: {'theme':'base', 'themeVariables': {'primaryColor':'#e8eaf6','primaryTextColor':'#3f51b5','primaryBorderColor':'#7986cb','lineColor':'#5c6bc0','noteBkgColor':'#fffde7','noteTextColor':'#333'}}}%%
stateDiagram-v2
    RESET --> A_1
    
    A_1 --> A_1: SENSOR=0
    A_1 --> D: SENSOR=1
    
    D --> D: SENSOR=1
    D --> A_2: SENSOR=0
    
    A_2 --> A_2: SENSOR=0
    A_2 --> I: SENSOR=1
    
    I --> I: SENSOR=1
    I --> A_1: SENSOR=0
    
    note right of A_1
        Salida: 11
        Primer Avance
    end note
    
    note right of D
        Salida: 01
        Giro Derecha
    end note
    
    note right of I
        Salida: 10
        Giro Izquierda
    end note
```

## Observaciones
1.  **Diseño Moore:** Las salidas dependen exclusivamente del estado actual, lo que garantiza que no haya transiciones espurias (glitches) causadas directamente por la entrada `b`.
2.  **Seguridad:** En caso de error o estado no definido, la máquina vuelve a `E_Inicial` (Paro) por seguridad.
3.  **Nomenclatura:** Se han utilizado nombres cortos (`ri`, `rd`, `b`) para cumplir con el requisito de brevedad sin perder descriptividad.