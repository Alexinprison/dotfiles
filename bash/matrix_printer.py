import gdb
import gdb.printing


class MatrixPrinter:
    def __init__(self, val):
        self.val = val

    def _get_rows(self):
        """Return all rows as Python lists of gdb.Value objects."""
        impl = self.val['_M_impl']

        outer_start = impl['_M_start']
        outer_finish = impl['_M_finish']

        rows = []
        outer_size = int(outer_finish - outer_start)

        for i in range(outer_size):
            row = (outer_start + i).dereference()
            row_impl = row['_M_impl']

            row_start = row_impl['_M_start']
            row_finish = row_impl['_M_finish']
            row_size = int(row_finish - row_start)

            cells = [
                (row_start + j).dereference()
                for j in range(row_size)
            ]

            rows.append(cells)

        return rows

    def to_string(self):
        try:
            rows = self._get_rows()

            row_count = len(rows)

            if row_count == 0:
                return "Matrix(0x0)"

            # Find the maximum number of columns.
            col_count = max(len(row) for row in rows)

            if col_count == 0:
                return f"Matrix({row_count}x0)"

            # Convert values to strings before calculating column widths.
            data = []

            for row in rows:
                data.append([
                    str(cell)
                    for cell in row
                ])

            # Find the maximum width of each column.
            col_widths = []

            for j in range(col_count):
                width = max(
                    len(row[j]) if j < len(row) else 0
                    for row in data
                )

                # Reserve at least one character per column.
                col_widths.append(max(width, 1))

            # Determine the width of the row labels.
            row_label_width = max(
                len(str(i))
                for i in range(row_count)
            )

            lines = []

            # Display the matrix dimensions on the first line.
            lines.append(f"Matrix({row_count}x{col_count})")

            # Display column indexes.
            header = " " * (row_label_width + 2)

            for j in range(col_count):
                header += (
                    str(j).rjust(col_widths[j]) + " "
                )

            lines.append(header.rstrip())

            # Render each row.
            for i, row in enumerate(data):
                line = str(i).rjust(row_label_width) + "  "

                for j in range(col_count):
                    if j < len(row):
                        value = row[j]
                    else:
                        value = ""

                    line += value.rjust(col_widths[j]) + " "

                lines.append(line.rstrip())

            return "\n".join(lines)

        except gdb.error as e:
            return f"Matrix(<error: {e}>)"

        except Exception as e:
            return f"Matrix(<python error: {e}>)"

    # Omit children() so GDB uses the table instead of expanding the vector.
    def display_hint(self):
        return None


def build_pretty_printer():
    pp = gdb.printing.RegexpCollectionPrettyPrinter(
        "matrix-printer"
    )

    pp.add_printer(
        "Matrix",
        r"^std::vector<std::vector<",
        MatrixPrinter
    )

    return pp


def register_for_objfile(objfile):
    if objfile is None:
        return

    try:
        gdb.printing.register_pretty_printer(
            objfile,
            build_pretty_printer(),
            replace=True
        )
    except Exception as e:
        print(
            f"matrix-printer: failed to register for "
            f"{objfile.filename}: {e}"
        )


# Register the printer for object files that are already loaded.
for objfile in gdb.objfiles():
    register_for_objfile(objfile)


# Register the printer automatically for newly loaded object files.
def on_new_objfile(event):
    register_for_objfile(event.new_objfile)


# Avoid duplicate event handlers when this file is sourced repeatedly.
old_handler = getattr(
    gdb,
    "_matrix_printer_handler",
    None
)

if old_handler is not None:
    try:
        gdb.events.new_objfile.disconnect(old_handler)
    except Exception:
        pass

gdb._matrix_printer_handler = on_new_objfile
gdb.events.new_objfile.connect(on_new_objfile)

print("matrix-printer loaded")
