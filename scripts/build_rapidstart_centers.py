"""Genera el paquete RapidStart (.rapidstart) con los centros GOL (Olivos) y GVI (Viñas) de Grupo Olé.

Mismo formato que build_rapidstart_gal.py (XML UTF-16 con raíz <DataList>, comprimido en GZip; booleanos y
opciones como entero). Copia la configuración de GAL en producción (leída por MCP el 08/11/2026) cambiando
por centro: tenant, cliente genérico, series, dimensión 3C, productos y secciones/formas de pago.

Los centros se crean DESHABILITADOS y SIN tokens: los tokens se teclean en la ficha del centro.

Uso:  python3 build_rapidstart_centers.py <carpeta_salida>
"""
import gzip
import os
import sys
from xml.sax.saxutils import escape

PACKAGE_CODE = "REVO-GOL-GVI"
PACKAGE_NAME = "Revo - Centros GOL (Olivos) y GVI (Vinas)"

CENTERS = {
    "GOL": {
        "name": "Olivos", "tenant": "olivos", "generic": "X88000000", "dim3c": "088",
        "series": ("GOLS", "GOLN", "GOLR"), "items": "OL",
        "batch": {
            "EFECTIVO": "OLEFECTIVO", "TARJETA": "OLTARJETA", "GLOVO": "OLGLOVO", "GLOVOEF": "OLGLOVOEFE",
            "GOURMET": "OLGOURMET", "RESTAUR": "OLRESTAUR", "SODEXO": "OLSODEXO", "STRIPE": "OLSTRIPE",
            "UBER": "OLUBER", "IMPA": "OLIMPA", "MARCHAN": "OLMARCHAND", "VOLVER": "OLVOLVEREM",
            "BIZUM": "OLBIZUM", "CREDITO": "OLCREDITO", "TRANSFE": "OLTRANSFER",
        },
    },
    "GVI": {
        "name": "Viñas", "tenant": "vinas", "generic": "X84000000", "dim3c": "084",
        "series": ("GVIS", "GVIN", "GVIR"), "items": "VI",
        "batch": {
            "EFECTIVO": "VÑSEFECTIV", "TARJETA": "VÑSTARJETA", "GLOVO": "VÑSGLOVO", "GLOVOEF": "VÑSGLOVOEF",
            "GOURMET": "VÑSGOURMET", "RESTAUR": "VÑSRESTAUR", "SODEXO": "VÑSSODEXO", "STRIPE": "VÑSSTRIPE",
            "UBER": "VÑSUBER", "IMPA": "VÑSIMPA", "MARCHAN": "VÑSMARCHAN", "VOLVER": "VÑSVOLVERE",
            "BIZUM": "VÑSBIZUM", "CREDITO": "VÑSCREDITO", "TRANSFE": "VÑSTRANSFE",
        },
    },
}

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

# Supergrupo, % IVA específico (None = genérico), nº producto (sin sufijo), descripción, mantener signo
SUPER_GROUPS = [
    (7, None, "7", "OFF", 0),
    (8, None, "8", "COMIDA", 0),
    (9, None, "9", "BEBIDA", 0),
    (10, None, "10", "DUCHAS", 0),
    (11, None, "11", "TABACO", 0),
    (13, None, "13", "TIENDA", 0),
    (13, 4, "12", "TIENDA 4%", 0),
    (13, 10, "13", "TIENDA 10%", 0),
    (13, 21, "14", "TIENDA 21%", 0),
    (14, None, "15", "STAFF", 0),
    (15, None, "16", "VENDING", 0),
    (16, None, "17", "GIFT CARD", 1),
]

# Método tal como llega de Revo (los 25 de GAL), acción (0 crear, 1 omitir), clave de sección
# (None = sin sección), y si la forma de pago es la misma que la sección.
PAY_METHODS = [
    ("Bizum", 0, "BIZUM", True),
    ("Card America Express", 0, "TARJETA", True),
    ("Card VISA / Mastercard", 0, "TARJETA", True),
    ("CH / Gourmet", 0, "GOURMET", True),
    ("CH / Restaurant", 0, "RESTAUR", True),
    ("CH / Sodexo", 0, "SODEXO", True),
    ("Ch/ Gourmet", 0, "GOURMET", True),
    ("Ch/ Restaurant", 0, "RESTAUR", True),
    ("Ch/ Sodexo", 0, "SODEXO", True),
    ("Cover", 0, "STRIPE", True),
    ("Crédito", 1, "CREDITO", False),
    ("Efectivo", 0, "EFECTIVO", True),
    ("Efectivo Incidencia", 0, "EFECTIVO", True),
    ("Glovo", 0, "GLOVO", True),
    ("Glovo (Efectivo)", 0, "GLOVOEF", True),
    ("Glovo Efectivo", 0, "GLOVOEF", True),
    ("Impagado", 0, "IMPA", True),
    ("Invitación", 1, None, False),
    ("Marchando", 0, "MARCHAN", True),
    ("Tarjeta", 0, "TARJETA", True),
    ("Transferencia", 1, "TRANSFE", True),
    ("Transferencia Bancaria", 1, None, False),
    ("Uber", 0, "UBER", True),
    ("Uber Eats", 0, "UBER", True),
    ("Volveremos", 0, "VOLVER", True),
]


def center_rows():
    rows = []
    for code, c in CENTERS.items():
        s, n, r = c["series"]
        rows.append([
            ("Code", code, True), ("Name", c["name"], False), ("Enabled", "0", False),
            ("RevoTenant", c["tenant"], False), ("GenericCustomerNo", c["generic"], False),
            ("PaymentTermsCode", "CON", False), ("PricesIncludingVAT", "1", False),
            ("NoPaymentMethodCode", c["batch"]["EFECTIVO"], False),
            ("DimensionCode", "3C", False), ("DimensionValueCode", c["dim3c"], False),
            ("Dimension2Code", "1S", False), ("Dimension2ValueCode", "SRE2", False),
            ("SimplifiedNos", s, False), ("NominalNos", n, False), ("RectifyingNos", r, False),
            ("DefaultSuperGroupID", "8", False),
        ])
    return rows


def letter_rows():
    return [[("CenterCode", code, True), ("Letter", l, True), ("DocumentKind", str(k), False),
             ("SeriesType", str(s), False), ("RequireNIFCustomer", str(n), False), ("Description", d, False)]
            for code in CENTERS for l, k, s, n, d in LETTERS]


def super_group_rows():
    rows = []
    for code, c in CENTERS.items():
        for sg, vat, item, desc, keep in SUPER_GROUPS:
            rows.append([("CenterCode", code, True), ("SuperGroupID", str(sg), True),
                         ("SpecificVAT", "1" if vat is not None else "0", True), ("VAT", str(vat or 0), True),
                         ("ItemNo", f"{item}_{c['items']}", False), ("Description", desc, False),
                         ("KeepPriceSign", str(keep), False)])
    return rows


def pay_method_rows():
    rows = []
    for code, c in CENTERS.items():
        for method, action, key, same_pm in PAY_METHODS:
            batch = c["batch"][key] if key else ""
            rows.append([("CenterCode", code, True), ("RevoPaymentMethod", method, True),
                         ("MappingAction", str(action), False),
                         ("JournalTemplateName", "COBROS", False), ("JournalBatchName", batch, False),
                         ("PaymentMethodCode", batch if same_pm else "", False)])
    return rows


TABLES = [
    # (id tabla, elemento, page id, orden, filas)
    (50401, "RevoCenter", 50401, 1, center_rows()),
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
            for name, value, is_key in row:
                attrs = ' PrimaryKey="1"' if (i == 0 and is_key) else ""
                out.append(f"<{name}{attrs}>{escape(value)}</{name}>")
            out.append(f"</{element}>")
        out.append(f"</{element}List>")
    out.append("</DataList>")
    return "".join(out)


def main():
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out_dir, exist_ok=True)
    data = build_xml().encode("utf-16")  # con BOM, como lo exporta BC
    with gzip.open(os.path.join(out_dir, f"{PACKAGE_CODE}.rapidstart"), "wb") as f:
        f.write(data)
    print(f"OK: " + " / ".join(f"{t[1]} {len(t[4])}" for t in TABLES) + f" -> {out_dir}")


if __name__ == "__main__":
    main()
