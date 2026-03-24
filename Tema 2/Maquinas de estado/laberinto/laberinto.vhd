LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;

ENTITY robot_laberinto IS
    PORT (
        clk         : IN  STD_LOGIC;
        rst         : IN  STD_LOGIC;
        
        -- 4 Entradas: Sensores del robot (1 = pared detectada, 0 = espacio libre)
        sen_frente  : IN  STD_LOGIC;
        sen_der     : IN  STD_LOGIC;
        sen_izq     : IN  STD_LOGIC;
        sen_atras   : IN  STD_LOGIC;
        
        -- 4 Salidas: Control de motores diferenciales (instrucciones de movimiento y giro)
        m_izq_fwd   : OUT STD_LOGIC; -- Motor izquierdo hacia adelante
        m_izq_rev   : OUT STD_LOGIC; -- Motor izquierdo hacia atras
        m_der_fwd   : OUT STD_LOGIC; -- Motor derecho hacia adelante
        m_der_rev   : OUT STD_LOGIC  -- Motor derecho hacia atras
    );
END ENTITY robot_laberinto;

ARCHITECTURE rtl OF robot_laberinto IS
    -- Estados principales de la FSM
    TYPE estado_t IS (S_REPOSO, S_DECIDIR, S_GIRAR, S_AVANZAR);
    SIGNAL estado : estado_t := S_REPOSO;

    -- Orientación interna absoluta: 0=Norte, 1=Este, 2=Sur, 3=Oeste
    SIGNAL ori : INTEGER RANGE 0 TO 3 := 0;
    
    -- Coordenadas virtuales para el mapa de memoria (Empezamos en el centro de un mapa 16x16)
    SIGNAL pos_x : INTEGER RANGE 0 TO 15 := 8;
    SIGNAL pos_y : INTEGER RANGE 0 TO 15 := 8;

    -- Siguiente direccion absoluta que el robot debe tomar
    SIGNAL dir_objetivo : INTEGER RANGE 0 TO 3 := 0;
    
    -- Memoria de mapa (Caminos visitados: '1' = Visitado, '0' = No visitado)
    TYPE mapa_t IS ARRAY (0 TO 15) OF STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL visitados : mapa_t := (OTHERS => (OTHERS => '0'));
    
    -- Memoria Pila (Historial) para rastrear decisiones y poder retroceder
    TYPE pila_t IS ARRAY (0 TO 63) OF INTEGER RANGE 0 TO 3;
    SIGNAL pila : pila_t := (OTHERS => 0);
    SIGNAL sp : INTEGER RANGE 0 TO 63 := 0; -- Stack Pointer

BEGIN
    PROCESS(clk, rst)
        -- Variables intermedias para mapear sensores
        VARIABLE abs_N, abs_E, abs_S, abs_W : STD_LOGIC;
        VARIABLE vis_N, vis_E, vis_S, vis_W : STD_LOGIC;
        VARIABLE dir_previa : INTEGER RANGE 0 TO 3;
    BEGIN
        IF rst = '1' THEN
            estado <= S_REPOSO;
            ori <= 0;
            pos_x <= 8;
            pos_y <= 8;
            sp <= 0;
            dir_objetivo <= 0;
            visitados <= (OTHERS => (OTHERS => '0'));
            
            m_izq_fwd <= '0'; m_izq_rev <= '0';
            m_der_fwd <= '0'; m_der_rev <= '0';
            
        ELSIF RISING_EDGE(clk) THEN
            -- Por defecto, los motores están apagados (señales de pulso para simulación)
            m_izq_fwd <= '0'; m_izq_rev <= '0';
            m_der_fwd <= '0'; m_der_rev <= '0';

            CASE estado IS
                WHEN S_REPOSO =>
                    -- Marca la celda actual como explorada
                    visitados(pos_y)(pos_x) <= '1';
                    estado <= S_DECIDIR;

                WHEN S_DECIDIR =>
                    -- 1. Traduce la lectura de los sensores relativos a las paredes absolutas (N, E, S, W)
                    IF ori = 0 THEN    -- Mirando al Norte
                        abs_N := sen_frente; abs_E := sen_der; abs_S := sen_atras; abs_W := sen_izq;
                    ELSIF ori = 1 THEN -- Mirando al Este
                        abs_E := sen_frente; abs_S := sen_der; abs_W := sen_atras; abs_N := sen_izq;
                    ELSIF ori = 2 THEN -- Mirando al Sur
                        abs_S := sen_frente; abs_W := sen_der; abs_N := sen_atras; abs_E := sen_izq;
                    ELSE               -- Mirando al Oeste
                        abs_W := sen_frente; abs_N := sen_der; abs_E := sen_atras; abs_S := sen_izq;
                    END IF;

                    -- 2. Analiza el entorno en la memoria (evitando salirnos del rango de array)
                    IF pos_y > 0  THEN vis_N := visitados(pos_y - 1)(pos_x); ELSE vis_N := '1'; END IF;
                    IF pos_x < 15 THEN vis_E := visitados(pos_y)(pos_x + 1); ELSE vis_E := '1'; END IF;
                    IF pos_y < 15 THEN vis_S := visitados(pos_y + 1)(pos_x); ELSE vis_S := '1'; END IF;
                    IF pos_x > 0  THEN vis_W := visitados(pos_y)(pos_x - 1); ELSE vis_W := '1'; END IF;

                    -- 3. Toma de decisión: PRIORIDAD a caminos LIBRES y NO VISITADOS
                    IF abs_N = '0' AND vis_N = '0' THEN
                        dir_objetivo <= 0;
                        IF sp < 63 THEN pila(sp) <= 0; sp <= sp + 1; END IF; -- Guardamos elección en memoria
                        estado <= S_GIRAR;
                        
                    ELSIF abs_E = '0' AND vis_E = '0' THEN
                        dir_objetivo <= 1;
                        IF sp < 63 THEN pila(sp) <= 1; sp <= sp + 1; END IF;
                        estado <= S_GIRAR;
                        
                    ELSIF abs_S = '0' AND vis_S = '0' THEN
                        dir_objetivo <= 2;
                        IF sp < 63 THEN pila(sp) <= 2; sp <= sp + 1; END IF;
                        estado <= S_GIRAR;
                        
                    ELSIF abs_W = '0' AND vis_W = '0' THEN
                        dir_objetivo <= 3;
                        IF sp < 63 THEN pila(sp) <= 3; sp <= sp + 1; END IF;
                        estado <= S_GIRAR;
                        
                    ELSE
                        -- ATASCO (3 paredes o solo caminos visitados): Toca RETROCEDER
                        -- Revisamos nuestra memoria pila, vemos por dónde vinimos e invertimos el camino
                        IF sp > 0 THEN
                            sp <= sp - 1;
                            dir_previa := pila(sp - 1); -- Obtener último movimiento
                            -- Calcular la dirección opuesta a la que entramos
                            IF dir_previa = 0 THEN dir_objetivo <= 2;
                            ELSIF dir_previa = 1 THEN dir_objetivo <= 3;
                            ELSIF dir_previa = 2 THEN dir_objetivo <= 0;
                            ELSE dir_objetivo <= 1; END IF;
                            estado <= S_GIRAR;
                        ELSE
                            -- Laberinto sin solución completado o atascado en inicio
                            estado <= S_REPOSO; 
                        END IF;
                    END IF;

                WHEN S_GIRAR =>
                    IF ori = dir_objetivo THEN
                        -- Si ya miramos hacia donde queremos ir, avanzamos
                        estado <= S_AVANZAR;
                    ELSE
                        -- Emitir "instrucción de giro" activando los motores
                        IF (ori = 0 AND dir_objetivo = 1) OR (ori = 1 AND dir_objetivo = 2) OR
                           (ori = 2 AND dir_objetivo = 3) OR (ori = 3 AND dir_objetivo = 0) THEN
                            -- Instrucción: Giro a la DERECHA
                            m_izq_fwd <= '1'; m_der_rev <= '1';
                            ori <= dir_objetivo;
                        ELSIF (ori = 0 AND dir_objetivo = 3) OR (ori = 3 AND dir_objetivo = 2) OR
                              (ori = 2 AND dir_objetivo = 1) OR (ori = 1 AND dir_objetivo = 0) THEN
                            -- Instrucción: Giro a la IZQUIERDA
                            m_izq_rev <= '1'; m_der_fwd <= '1';
                            ori <= dir_objetivo;
                        ELSE
                            -- Instrucción: MEDIA VUELTA (180 grados, trampa de 1x1)
                            m_izq_fwd <= '1'; m_der_rev <= '1';
                            ori <= dir_objetivo;
                        END IF;
                        estado <= S_AVANZAR;
                    END IF;

                WHEN S_AVANZAR =>
                    -- Instrucción de movimiento recto
                    m_izq_fwd <= '1';
                    m_der_fwd <= '1';
                    
                    -- Actualizar memoria de ubicación interna
                    IF ori = 0 THEN pos_y <= pos_y - 1;
                    ELSIF ori = 1 THEN pos_x <= pos_x + 1;
                    ELSIF ori = 2 THEN pos_y <= pos_y + 1;
                    ELSIF ori = 3 THEN pos_x <= pos_x - 1;
                    END IF;
                    
                    -- Tras avanzar 1 paso, volvemos a evaluar el nuevo espacio
                    estado <= S_REPOSO;
                    
            END CASE;
        END IF;
    END PROCESS;
END ARCHITECTURE rtl;