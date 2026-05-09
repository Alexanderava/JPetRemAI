import os
import zipfile

jar_path = "/Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar"
temp_dir = "/tmp/shimeji_chat_color"

os.system(f"rm -rf {temp_dir}")
os.system(f"mkdir -p {temp_dir}")
os.system(f"unzip -q {jar_path} -d {temp_dir}")

class_file = os.path.join(temp_dir, "com/group_finity/mascot/plugin/MultiSelectPlugin.class")
with open(class_file, "rb") as fp:
    content = fp.read()

search1 = b"\x01\x00\x41<html><div style='color:#ccc;text-align:right'>    \x01</div></html>"
search2 = b"\x01\x00\x41<html><div style='text-align: right; width: 100%;'>\x01</div></html>"
search3 = b"\x01\x00\x4c<html><div style='color:#000;font-size:10px;text-align:right'>\x01</div></html>"

new_str = b"<html><div style='color:#000;font-size:10px;text-align:right'>\x01</div></html>"
new_len = len(new_str)
new_bytes = b"\x01" + new_len.to_bytes(2, byteorder='big') + new_str

if search1 in content:
    content = content.replace(search1, new_bytes)
    print("Patched from previously patched string")
elif search2 in content:
    content = content.replace(search2, new_bytes)
    print("Patched from original string")
elif search3 in content:
    print("Already patched!")
else:
    print("Could not find string in constant pool!")

with open(class_file, "wb") as fp:
    fp.write(content)

os.system(f"cd {temp_dir} && zip -q -r /tmp/ShimejiEE_chat_color.jar .")
os.system(f"cp /tmp/ShimejiEE_chat_color.jar {jar_path}")
print("Done patching jar.")
