
## 📘 Referencia Rápida de VHDL

### 1. Señales vs. Variables
Entender la diferencia es crucial para el diseño digital.

| Característica | Señal (`SIGNAL`) | Variable (`VARIABLE`) |
| :--- | :--- | :--- |
| **Operador** | `<=` | `:=` |
| **Ámbito** | Global (Arquitectura) | Local (Proceso/Subprograma) |
| **Actualización** | Al finalizar el proceso (programada) | Inmediata (secuencial) |
| **Uso** | Conexiones físicas, registros | Cálculos intermedios, bucles |

**Ejemplo:**
```vhdl
PROCESS(clk)
    VARIABLE v_cuenta : INTEGER := 0; 
BEGIN
    v_cuenta := v_cuenta + 1; -- Actualiza inmediatamente
    s_salida <= v_cuenta;     -- Se actualiza al final del proceso
END PROCESS;
```

### 2. Tipos de Datos Comunes
Requieren `USE ieee.std_logic_1164.all;` y `USE ieee.numeric_std.all;`.

*   **`STD_LOGIC`**: Bit individual (`'0'`, `'1'`, `'Z'`, `'X'`).
*   **`STD_LOGIC_VECTOR`**: Arreglo de bits (Bus). Ej: `SIGNAL bus : STD_LOGIC_VECTOR(7 DOWNTO 0);`
*   **`INTEGER`**: Números enteros (ideal para índices y rangos).
*   **`UNSIGNED` / `SIGNED`**: Vectores interpretados numéricamente para aritmética.

### 3. Palabras Reservadas Clave

*   **`PROCESS` (Secuencial):** Bloque fundamental para lógica secuencial y algoritmos. Se ejecuta paso a paso.
*   **`GENERATE` (Concurrente):** "Bucle" de hardware. Replica estructuras físicas en paralelo.
*   **`COMPONENT` / `PORT MAP` (Estructural):** Permite instanciar y conectar módulos dentro de otros (Jerarquía).
*   **`PACKAGE` (Modular):** Agrupa funciones, tipos y constantes reutilizables.
