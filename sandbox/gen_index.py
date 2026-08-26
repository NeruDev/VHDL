import re
import os

files = [
    ("01_estructura_codigo.md", "1. Estructura estándar del código"),
    ("02_tipos_de_datos.md", "2. Tipos de datos"),
    ("03_senales_variables_constantes.md", "3. Señales, Variables y Constantes"),
    ("04_palabras_clave_principales.md", "4. Palabras clave principales"),
    ("05_operadores.md", "5. Operadores"),
    ("06_logica_concurrente_vs_secuencial.md", "6. Lógica concurrente vs. secuencial"),
    ("07_circuitos_secuenciales.md", "7. Circuitos Secuenciales"),
    ("08_memorias_y_su_manejo.md", "8. Memorias y su manejo en VHDL"),
    ("09_buenas_practicas_y_estilo.md", "9. Buenas prácticas de diseño y estilo en VHDL"),
    ("10_verificacion_testbenches_depuracion.md", "10. Verificación práctica: testbenches y depuración")
]

index_content = """<!--
---
file: Teoria/README.md
description: Indice general y guia de navegacion modular de la teoria de VHDL
type: doc/manual
version: 1.0.0
date: 2026-08-26
covers: []
relations: [AGENTS.md, README.md]
keywords: [indice, guia-navegacion, teoria, vhdl]
---
-->

# Índice General de Teoría VHDL

Bienvenido a la documentación modular de teoría de VHDL. Cada sección ha sido estructurada como un documento atómico para facilitar la consulta rápida y la lectura guiada.

---

## Módulos y Secciones

"""

for fname, title in files:
    fpath = os.path.join("Teoria", fname)
    with open(fpath, "r", encoding="utf-8") as f:
        text = f.read()
    
    # Find all ## and ### headers
    headers = re.findall(r'^(#{2,3})\s+(.*)', text, re.MULTILINE)
    
    index_content += f"### [{title}]({fname})\n\n"
    for level, htitle in headers:
        # Create anchor link
        # remove punctuation from header to create standard markdown anchor
        anchor = htitle.lower().replace(" ", "-").replace("—", "").replace(":", "").replace(".", "").replace(",", "").replace("/", "").replace("(", "").replace(")", "").replace("?", "").replace("¿", "")
        anchor = re.sub(r'-+', '-', anchor).strip("-")
        indent = "  -" if level == "###" else "-"
        index_content += f"{indent} [{htitle}]({fname}#{anchor})\n"
    index_content += "\n"

index_content += """---

## Mapa de Aprendizaje Recomendado

```mermaid
graph TD
    A["01. Estructura Estándar"] --> B["02. Tipos de Datos"]
    B --> C["03. Señales y Variables"]
    C --> D["04. Palabras Clave y Sentencias"]
    D --> E["05. Operadores"]
    E --> F["06. Concurrente vs Secuencial"]
    F --> G["07. Circuitos Secuenciales y FSMs"]
    G --> H["08. Memorias: RAM, ROM, FIFO"]
    H --> I["09. Buenas Prácticas"]
    I --> J["10. Testbenches y Verificación"]

    style A fill:#e8eaf6,stroke:#7986cb,color:#3f51b5
    style B fill:#e8f5e9,stroke:#81c784,color:#2e7d32
    style C fill:#fff3e0,stroke:#ffb74d,color:#e65100
    style D fill:#fce4ec,stroke:#f06292,color:#880e4f
    style E fill:#e0f2f1,stroke:#4db6ac,color:#00695c
    style F fill:#f3e5f5,stroke:#ba68c8,color:#4a148c
    style G fill:#e8eaf6,stroke:#7986cb,color:#3f51b5
    style H fill:#e8f5e9,stroke:#81c784,color:#2e7d32
    style I fill:#fff3e0,stroke:#ffb74d,color:#e65100
    style J fill:#fce4ec,stroke:#f06292,color:#880e4f
```
"""

with open("Teoria/README.md", "w", encoding="utf-8") as f:
    f.write(index_content)

print("Generated Teoria/README.md successfully.")
