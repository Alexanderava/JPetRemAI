import os
import glob

extract_dir = "/Applications/JPetRemAI.app/Contents/Resources/extracted_classes"
os.makedirs(extract_dir, exist_ok=True)

os.system(f"cd /Applications/JPetRemAI.app/Contents/Resources && unzip -o ShimejiEE.jar com/group_finity/mascot/plugin/MultiSelectPlugin*.class -d {extract_dir}")

replacements = {
    b"javax/swing/JButton": b"com/gfinity/JButton",
    b"javax/swing/JLabel": b"com/gfinity/JLabel",
    b"javax/swing/JCheckBox": b"com/gfinity/JCheckBox",
    b"javax/swing/JToggleButton": b"com/gfinity/JToggleButton",
    b"javax/swing/JOptionPane": b"com/gfinity/JOptionPane",
    b"javax/swing/JFrame": b"com/gfinity/JFrame",
    b"javax/swing/JTabbedPane": b"com/gfinity/JTabbedPane",
    b"javax/swing/JComboBox": b"com/gfinity/JComboBox",
    b"javax/swing/JDialog": b"com/gfinity/JDialog",
    b"javax/swing/JFrame": b"com/gfinity/JFrame"
}

patched_count = 0
for filepath in glob.glob(f"{extract_dir}/com/group_finity/mascot/plugin/MultiSelectPlugin*.class"):
    with open(filepath, "rb") as f:
        data = f.read()

    new_data = data
    for old_str, new_str in replacements.items():
        if len(old_str) != len(new_str):
            print(f"ERROR: Length mismatch for {old_str} -> {new_str}")
            exit(1)
        new_data = new_data.replace(old_str, new_str)

    if new_data != data:
        with open(filepath, "wb") as f:
            f.write(new_data)
        patched_count += 1
        print(f"Patched: {os.path.basename(filepath)}")

if patched_count > 0:
    os.system(f"cd {extract_dir} && zip -u ../ShimejiEE.jar com/group_finity/mascot/plugin/MultiSelectPlugin*.class")
    print("All patched classes zipped back to ShimejiEE.jar")
else:
    print("No changes made.")
