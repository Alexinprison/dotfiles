# Keep the existing confirmation and debug-info download preferences.
set confirm off
set debuginfod enabled off

# Locate the printer beside this file after resolving its Stow symlink.
python
from pathlib import Path
import runpy
_matrix_printer_path = Path("~/.gdbinit").expanduser().resolve().with_name("matrix_printer.py")
runpy.run_path(str(_matrix_printer_path))
end
