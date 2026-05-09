# Source Code Structure

## Java Sources
The main application is packaged in `ShimejiEE.jar` within the app bundle.

## Resources
Character sprites, configuration files, and i18n translations are located in:
`Contents/Resources/`

## Patch Scripts
Python scripts for hot-patching the JAR without recompilation:
- `patch_llama.py` - Model manager patches
- `chat_patch.py` - UI customizations
- `patch_all.py` - Batch patches
