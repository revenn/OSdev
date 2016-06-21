#!/usr/bin/python
import os
import subprocess

def fix_stage1_size():
  stage2_size = os.stat("stage2").st_size
  kernel_size = os.stat("kernel64").st_size
  stage2_size = (stage2_size + kernel_size + 511) / 512 ; #wyrownanie, zaokroaglenie w gore

  if stage2_size >= 255:
    raise Exception("stage2 too large")
  
  with open("stage1", "rb+") as f:
    d = f.read()
    idx = d.index("\xb0\xcc\x90\x90")
    d = bytearray(d)
    d[idx+1] = stage2_size
    f.seek(0)
    f.write(d)

cmds_to_run = [
    "gcc kernel.c -std=c99 -nostdlib -o kernel64",
    "strip kernel64",   #usuwa symbole debugowania
    "nasm stage1.asm",
    "nasm stage2.asm",    
    fix_stage1_size   
]

files_to_img = [
    "stage1",
    "stage2",
    "kernel64"
]

for cmd in cmds_to_run:
  if type(cmd) is str:
    print "Running:", cmd
    print subprocess.check_output(cmd, shell=True)
  else:
    print "Calling:", cmd.func_name
    cmd()

buf = []
for fn in files_to_img:
  with open(fn, "rb") as f:
    d = f.read()
    buf.append(d)

    if len(d) % 512 == 0:
      continue

    padding_size = 512 - len(d) % 512        
    buf.append("\0" * padding_size);

with open("floppy.bin", "wb") as f:
  f.write(''.join(buf)) 
