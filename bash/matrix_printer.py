import gdb
import gdb.printing


class MatrixPrinter:
    def __init__(self, val):
        self.val = val

    def _get_rows(self):
        """返回所有行，每一行都是 Python list[gdb.Value]"""
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

            # 计算最大列数
            col_count = max(len(row) for row in rows)

            if col_count == 0:
                return f"Matrix({row_count}x0)"

            # 转成字符串，方便计算每列宽度
            data = []

            for row in rows:
                data.append([
                    str(cell)
                    for cell in row
                ])

            # 每一列的最大宽度
            col_widths = []

            for j in range(col_count):
                width = max(
                    len(row[j]) if j < len(row) else 0
                    for row in data
                )

                # 至少留一点空间
                col_widths.append(max(width, 1))

            # 行号宽度
            row_label_width = max(
                len(str(i))
                for i in range(row_count)
            )

            lines = []

            # 第一行：Matrix 尺寸
            lines.append(f"Matrix({row_count}x{col_count})")

            # 列编号
            header = " " * (row_label_width + 2)

            for j in range(col_count):
                header += (
                    str(j).rjust(col_widths[j]) + " "
                )

            lines.append(header.rstrip())

            # 每一行
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

    # 不再提供 children()
    #
    # 这样 GDB 不会继续把 vector 当成 std::vector 展开，
    # 而是直接使用上面的二维表格字符串。
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


# 注册当前已经存在的 objfile
for objfile in gdb.objfiles():
    register_for_objfile(objfile)


# 以后新加载的 objfile 也自动注册
def on_new_objfile(event):
    register_for_objfile(event.new_objfile)


# 防止 source 多次导致重复注册事件
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