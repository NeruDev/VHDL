import re
import os
import subprocess

files = sorted([f for f in os.listdir("Teoria") if f.endswith(".md") and f != "README.md"])

for fname in files:
    fpath = os.path.join("Teoria", fname)
    with open(fpath, "r", encoding="utf-8") as f:
        content = f.read()
    
    # Extract ```vhdl ... ``` blocks
    blocks = re.findall(r'```vhdl(.*?)```', content, re.DOTALL)
    print(f"File: {fname} has {len(blocks)} VHDL code blocks")

