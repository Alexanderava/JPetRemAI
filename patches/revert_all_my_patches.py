import os, glob

extract_dir = "/Applications/JPetRemAI.app/Contents/Resources/extracted_classes"
os.makedirs(extract_dir, exist_ok=True)

os.system(f"cd /Applications/JPetRemAI.app/Contents/Resources && unzip -o ShimejiEE.jar com/group_finity/mascot/plugin/MultiSelectPlugin*.class -d {extract_dir}")

patched_count = 0
for filepath in glob.glob(f"{extract_dir}/com/group_finity/mascot/plugin/MultiSelectPlugin*.class"):
    with open(filepath, "rb") as f:
        data = f.read()

    new_data = data.replace(b"com/gfinity/JPanel", b"javax/swing/JPanel")
    new_data = new_data.replace(b"com/gfinity/JScrollPane", b"javax/swing/JScrollPane")
    new_data = new_data.replace(b"com/gfinity/JTextArea", b"javax/swing/JTextArea")

    if new_data != data:
        with open(filepath, "wb") as f:
            f.write(new_data)
        patched_count += 1
        print(f"Reverted in: {os.path.basename(filepath)}")

if patched_count > 0:
    os.system(f"cd {extract_dir} && zip -u ../ShimejiEE.jar com/group_finity/mascot/plugin/MultiSelectPlugin*.class")
    print("Zipped back to ShimejiEE.jar")
