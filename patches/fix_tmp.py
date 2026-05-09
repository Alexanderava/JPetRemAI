import os
import glob

extract_dir = "/tmp/decompile_test"

replacements = {
    b"com/gfinity/JButton": b"javax/swing/JButton",
    b"com/gfinity/JLabel": b"javax/swing/JLabel",
    b"com/gfinity/JCheckBox": b"javax/swing/JCheckBox",
    b"com/gfinity/JToggleButton": b"javax/swing/JToggleButton",
    b"com/gfinity/JOptionPane": b"javax/swing/JOptionPane",
    b"com/gfinity/JFrame": b"javax/swing/JFrame",
    b"com/gfinity/JTabbedPane": b"javax/swing/JTabbedPane",
    b"com/gfinity/JComboBox": b"javax/swing/JComboBox",
    b"com/gfinity/JDialog": b"javax/swing/JDialog",
    b"com/gfinity/JPanel": b"javax/swing/JPanel",
    b"com/gfinity/JScrollPane": b"javax/swing/JScrollPane",
    b"com/gfinity/JTextArea": b"javax/swing/JTextArea",
}

patched_count = 0
for filepath in glob.glob(f"{extract_dir}/com/group_finity/mascot/plugin/MultiSelectPlugin*.class"):
    with open(filepath, "rb") as f:
        data = f.read()

    new_data = data
    for old_str, new_str in replacements.items():
        new_data = new_data.replace(old_str, new_str)

    if new_data != data:
        with open(filepath, "wb") as f:
            f.write(new_data)
        patched_count += 1
        print(f"Reverted: {os.path.basename(filepath)}")

if patched_count > 0:
    os.system(f"cd {extract_dir} && zip -u /Applications/JPetRemAI.app/Contents/Resources/ShimejiEE.jar com/group_finity/mascot/plugin/MultiSelectPlugin*.class")
    print("All reverted classes zipped back to ShimejiEE.jar")
else:
    print("No changes made.")
