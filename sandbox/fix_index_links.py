import os
import re

for fname in os.listdir("Teoria"):
    if fname.endswith(".md") and fname != "README.md":
        fpath = os.path.join("Teoria", fname)
        with open(fpath, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Replace return to index links
        new_content = re.sub(r'\[⬆ Volver al Índice\]\(#índice\)', r'[⬆ Volver al Índice](README.md)', content)
        new_content = re.sub(r'\[⬆ Volver al Índice\]\(#indice\)', r'[⬆ Volver al Índice](README.md)', new_content)
        
        if new_content != content:
            with open(fpath, "w", encoding="utf-8") as f:
                f.write(new_content)
            print(f"Fixed index link in: {fname}")

