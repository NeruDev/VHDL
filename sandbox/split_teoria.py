import re
import os

with open("Teoria/Teoria.md", "r", encoding="utf-8") as f:
    content = f.read()

# Pattern for section headers: ## 1. Estructura estándar del código, etc.
sections_info = [
    (1, "01_estructura_codigo.md", "Estructura estándar del código", "Estructura estándar del código VHDL (librerías, entidad, arquitectura y genéricos)", ["librerias", "entidad", "arquitectura", "genericos", "vhdl"]),
    (2, "02_tipos_de_datos.md", "Tipos de datos", "Tipos de datos escalares, vectoriales, enumerados, arreglos y conversiones en VHDL", ["tipos-datos", "std-logic", "vector", "signed", "unsigned", "vhdl"]),
    (3, "03_senales_variables_constantes.md", "Señales, Variables y Constantes", "Modelo de ejecución delta-cycles, señales, variables, constantes y atributos", ["signal", "variable", "constant", "delta-cycles", "atributos", "vhdl"]),
    (4, "04_palabras_clave_principales.md", "Palabras clave principales", "Sentencias secuenciales y concurrentes: process, if, case, loop, generate, component, packages", ["process", "if-else", "case", "generate", "component", "functions", "packages", "vhdl"]),
    (5, "05_operadores.md", "Operadores", "Operadores lógicos, relacionales, aritméticos, concatenación, desplazamiento y precedencia", ["operadores", "logicos", "aritmeticos", "precedencia", "vhdl"]),
    (6, "06_logica_concurrente_vs_secuencial.md", "Lógica concurrente vs. secuencial", "Comparación exhaustiva entre lógica concurrente y secuencial, asignaciones y latches", ["concurrente", "secuencial", "when-else", "with-select", "latches", "vhdl"]),
    (7, "07_circuitos_secuenciales.md", "Circuitos Secuenciales", "Flip-Flops, Latches, contadores, registros y Máquinas de Estados Finitos (FSM Moore y Mealy)", ["fsm", "moore", "mealy", "flip-flop", "latch", "secuenciales", "vhdl"]),
    (8, "08_memorias_y_su_manejo.md", "Memorias y su manejo en VHDL", "Memorias RAM (single/dual port), ROM, FIFO, registros de desplazamiento y BRAM", ["memorias", "ram", "rom", "fifo", "shift-registers", "bram", "vhdl"]),
    (9, "09_buenas_practicas_y_estilo.md", "Buenas prácticas de diseño y estilo en VHDL", "Buenas prácticas de diseño hardware, estilo sintetizable, interfaces y sincronización", ["buenas-practicas", "estilo-sintetizable", "cdc", "handshake", "dry", "vhdl"]),
    (10, "10_verificacion_testbenches_depuracion.md", "Verificación práctica: testbenches y depuración", "Metodologías de verificación, generación de reloj/reset, assert, testbenches y depuración", ["testbench", "verificacion", "assert", "clock-gen", "textio", "depuracion", "vhdl"])
]

# Find where sections start
section_indices = []
for sec_num, fname, title, desc, kw in sections_info:
    pattern = rf"^## {sec_num}\. .*"
    match = re.search(pattern, content, re.MULTILINE)
    if not match:
        raise ValueError(f"Could not find section {sec_num}: {title}")
    section_indices.append((sec_num, match.start(), fname, title, desc, kw))

# Extract sections
out_dir = "Teoria"
for i in range(len(section_indices)):
    sec_num, start_idx, fname, title, desc, kw = section_indices[i]
    end_idx = section_indices[i+1][1] if i + 1 < len(section_indices) else len(content)
    sec_content = content[start_idx:end_idx].strip()
    
    # Change H2 to H1 for the top of the file
    sec_content = re.sub(rf"^## {sec_num}\. (.*)", rf"# \1", sec_content, count=1)
    
    kw_str = ", ".join(kw)
    frontmatter = f"""<!--
---
file: Teoria/{fname}
description: {desc}
type: doc/theory
version: 1.0.0
date: 2026-08-26
covers: []
relations: [Teoria/README.md]
keywords: [{kw_str}]
---
-->

"""
    file_path = os.path.join(out_dir, fname)
    with open(file_path, "w", encoding="utf-8") as out_f:
        out_f.write(frontmatter + sec_content + "\n")
    print(f"Generated: {file_path} ({len(sec_content.splitlines())} lines)")

print("All 10 sections generated successfully.")
