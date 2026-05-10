# Curso de VHDL - Repositorio de Prácticas

Este repositorio contiene los ejercicios, ejemplos y prácticas realizados durante un curso universitario de **VHDL**. El enfoque del proyecto es el diseño de hardware digital, desde la lógica combinacional básica hasta sistemas secuenciales más complejos.

## 🛠️ Herramientas Utilizadas
- **Lenguaje:** VHDL.
- **Simulación:** Logisim Evolution v3.8.0 y Testbenches VHDL.
- **Compilación/Síntesis:** Quartus II 64-Bit versión 13.0.1 (Build 232).

## 📁 Estructura del Proyecto
El repositorio está organizado por unidades temáticas y recursos de apoyo:

- **`Tema X/`**: Carpetas organizadas por temas del curso (ej. `Tema 1/` para lógica combinacional).
- **`PLANTILLAS/`**: Contiene esqueletos de código (`.vhd`) para agilizar la creación de nuevos módulos y bancos de pruebas (testbenches).
- **`Asignacion de pines.md`**: Guía para la configuración de pines en la FPGA.
- **`Mapeo de placa.vhd`**: Archivo de referencia para la infraestructura física de la placa de desarrollo.
- **`GEMINI.md`**: Archivo de contexto para Gemini CLI (ubicado en la raíz del repositorio).
- **`.github/copilot-instructions.md`**: Instrucciones personalizadas para GitHub Copilot.
- **`.gemini/settings.json`**: Configuración general de Gemini CLI.

## 📝 Convenciones
- Los archivos de diseño usan nombres descriptivos en minúsculas.
- Los testbenches se identifican con el sufijo `_tb.vhd`.
- Toda la documentación y comentarios de código se mantienen en español.

## 💻 Entorno de Desarrollo (Local)
Para garantizar la compatibilidad y facilitar la automatización de la compilación, se ha identificado el siguiente entorno en el equipo del autor:

- **Sistema Operativo:** Windows 11 Home / Pro (64-bit).
- **Software de Síntesis:** Altera Quartus II 64-Bit versión 13.0.1 Build 232 Service Pack 1 SJ Web Edition.
- **Ruta del Compilador (Estándar):** `C:\altera\13.0sp1\quartus\bin64\`
- **Ejecutables principales:**
    - `quartus_map.exe` (Análisis y Síntesis)
    - `quartus_fit.exe` (Fitter)
    - `quartus_asm.exe` (Assembler)
    - `quartus_sh.exe` (Shell de comandos)
