"""Genera el paquete de configuración RapidStart (.rapidstart) del centro GAL (Almudévar).

Formato verificado contra Config. XML Exchange (BC 26): XML UTF-16 con raíz <DataList>, un nodo
<NombreTablaList> por tabla (primer hijo = TableID) y un nodo por registro; comprimido en GZip.
Booleanos y enums van como entero (0/1, ordinal). Atributos PrimaryKey/ValidateField solo en el primer
registro de cada tabla (de ahí lee BC la definición de campos del paquete).

Solo se incluyen los campos conocidos con certeza (fuente: MapeoRevoToBusinessCentral.xlsx). Lo que
depende del sandbox (series, dimensiones, plantilla/sección de diario, forma de pago) NO va en el paquete:
al aplicarlo, BC solo modifica los campos incluidos y respeta el resto de lo ya configurado.

Uso:  python build_rapidstart_gal.py <carpeta_salida>
"""
import gzip
import os
import sys
from xml.sax.saxutils import escape

PACKAGE_CODE = "REVO-GAL"
PACKAGE_NAME = "Revo - Centro GAL (Almudevar)"
CENTER = "GAL"

# (elemento XML, valor, es_clave, validar)
CENTER_ROWS = [
    [("Code", CENTER, True, False),
     ("Name", "Almudévar", False, False),
     ("RevoTenant", "almudevar", False, False),
     ("GenericCustomerNo", "X89000000", False, True),
     ("PaymentTermsCode", "CON", False, True),
     ("DefaultSuperGroupID", "8", False, False)],
]

# Letra, tipo (0 factura, 1 abono, 2 excluido), serie (0 S, 1 N, 2 R), exige NIF, descripción
LETTERS = [
    ("S", 0, 0, 0, "Factura simplificada"),
    ("A", 0, 0, 0, "Factura agrupada"),
    ("O", 0, 0, 0, "Offline"),
    ("N", 0, 1, 1, "Factura nominal"),
    ("R", 1, 2, 0, "Rectificativa simplificada / devolución"),
    ("X", 1, 2, 1, "Rectificativa nominal"),
    ("I", 2, 0, 0, "Invitaciones (excluido)"),
    ("L", 2, 0, 0, "Albaranes (excluido)"),
]

# Supergrupo Revo, % IVA específico (None = cualquiera), producto BC, descripción, mantener signo
SUPER_GROUPS = [
    (7, None, "7_AL", "OFF", 0),
    (8, None, "8_AL", "COMIDA", 0),
    (9, None, "9_AL", "BEBIDA", 0),
    (10, None, "10_AL", "DUCHAS", 0),
    (11, None, "11_AL", "TABACO", 0),
    (13, 4, "12_AL", "TIENDA 4%", 0),
    (13, 10, "13_AL", "TIENDA 10%", 0),
    (13, 21, "14_AL", "TIENDA 21%", 0),
    (14, None, "15_AL", "STAFF", 0),
    (15, None, "16_AL", "VENDING", 0),
    (16, None, "17_AL", "GIFT CARD", 1),
]

# Método de pago tal como llega de Revo, acción (0 crear línea diario, 1 omitir)
PAY_METHODS = [
    ("Tarjeta", 0), ("Efectivo", 0), ("Ch/ Restaurant", 0), ("Ch/ Sodexo", 0), ("Ch/ Gourmet", 0),
    ("Marchando", 0), ("Uber", 0), ("Glovo", 0), ("Volveremos", 0), ("Cover", 0),
    ("Glovo (Efectivo)", 0), ("Impagado", 0), ("Bizum", 0),
    ("Transferencia Bancaria", 1), ("Crédito", 1),
]


def letter_rows():
    return [[("CenterCode", CENTER, True, False), ("Letter", l, True, False), ("DocumentKind", str(k), False, False),
             ("SeriesType", str(s), False, False), ("RequireNIFCustomer", str(n), False, False),
             ("Description", d, False, False)] for l, k, s, n, d in LETTERS]


def super_group_rows():
    rows = []
    for sg, vat, item, desc, keep in SUPER_GROUPS:
        rows.append([("CenterCode", CENTER, True, False), ("SuperGroupID", str(sg), True, False),
                     ("SpecificVAT", "1" if vat is not None else "0", True, False),
                     ("VAT", str(vat or 0), True, False), ("ItemNo", item, False, True),
                     ("Description", desc, False, False), ("KeepPriceSign", str(keep), False, False)])
    return rows


def pay_method_rows():
    return [[("CenterCode", CENTER, True, False), ("RevoPaymentMethod", m, True, False),
             ("MappingAction", str(a), False, False)] for m, a in PAY_METHODS]


TABLES = [
    # (id tabla, elemento tabla, page id, orden, filas)
    (50401, "RevoCenter", 50401, 1, CENTER_ROWS),
    (50402, "RevoDocLetterSetup", 50403, 2, letter_rows()),
    (50403, "RevoSuperGroupMapping", 50404, 3, super_group_rows()),
    (50404, "RevoPayMethodMapping", 50405, 4, pay_method_rows()),
]


def build_xml():
    out = ['<?xml version="1.0" encoding="UTF-16" standalone="yes"?>',
           f'<DataList MinCountForAsyncImport="100000" ExcludeConfigTables="1" ProductVersion="" '
           f'PackageName="{escape(PACKAGE_NAME)}" Code="{PACKAGE_CODE}">']
    for table_id, element, page_id, order, rows in TABLES:
        out.append(f"<{element}List><TableID>{table_id}</TableID><PageID>{page_id}</PageID>"
                   f"<ProcessingOrder>{order}</ProcessingOrder>")
        for i, row in enumerate(rows):
            out.append(f"<{element}>")
            for name, value, is_key, validate in row:
                attrs = ""
                if i == 0:
                    if is_key:
                        attrs += ' PrimaryKey="1"'
                    if validate:
                        attrs += ' ValidateField="1"'
                out.append(f"<{name}{attrs}>{escape(value)}</{name}>")
            out.append(f"</{element}>")
        out.append(f"</{element}List>")
    out.append("</DataList>")
    return "".join(out)


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out_dir, exist_ok=True)
    xml = build_xml()
    data = xml.encode("utf-16")  # con BOM, como lo exporta BC
    # Sin copia .xml en la carpeta del proyecto: el compilador AL intenta interpretarla (AL1025).
    with gzip.open(os.path.join(out_dir, f"{PACKAGE_CODE}.rapidstart"), "wb") as f:
        f.write(data)
    print(f"OK: {sum(len(t[4]) for t in TABLES)} registros en {len(TABLES)} tablas -> {out_dir}")


if __name__ == "__main__":
    main()
