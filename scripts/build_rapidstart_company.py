"""Genera el paquete RapidStart (.rapidstart) de los centros Revo de una empresa de BC distinta de Grupo Olé.

Mismo formato que build_rapidstart_centers.py (XML UTF-16 con raíz <DataList>, comprimido en GZip; booleanos y
opciones como entero). Datos de cada centro comprobados por MCP en la empresa de destino (secciones COBROS,
formas de pago, productos, series, cliente genérico y dimensiones) y en el Excel de mapeos del cliente.

Los centros se crean DESHABILITADOS y SIN tokens: los tokens se teclean en la ficha del centro.
La Configuración Revo (50400) no va en el paquete: se crea sola al abrirla, con los valores por defecto; solo hay
que cambiar «Grupo IVA 0 %» a IVA0. La «Forma de pago sin cobros» tampoco: BC no la importa; se teclea en la ficha.

Uso:  python3 build_rapidstart_company.py <EMPRESA> <carpeta_salida>      (EMPRESA: DUFFY, ...)
"""
import gzip
import os
import sys
from xml.sax.saxutils import escape

COMPANIES = {
    # Duffy Pubs SL (empresa BC «Duffy»): centro Bull. Comprobado por MCP el 09/11/2026.
    "DUFFY": {
        "package_name": "Revo - Duffy: centro DBU (Bull)",
        "centers": {
            "DBU": {
                "name": "Bull", "tenant": "bull", "generic": "X92000000", "dim3c": "092", "dim1s": "SRE3",
                "series": ("DBUS", "DBUN", "DBUR"), "items": "BU",
                "batch": {
                    "EFECTIVO": "BLEFECTIVO", "TARJETA": "BLTARJETA", "GLOVO": "BLGLOVO", "GLOVOEF": "BLGLOVOEFE",
                    "GOURMET": "BLGOURMET", "RESTAUR": "BLRESTAUR", "SODEXO": "BLSODOXEO", "COVER": "BLCOVER",
                    "UBER": "BLUBER", "IMPA": "BLIMPA", "MARCHAN": "BLMARCHAND", "VOLVER": "BLVOLVEREM",
                    "BIZUM": "BLBIZUM", "CREDITO": "BLCREDITO", "TRANSFE": "BLTRANSFER", "PROPINAS": "BLPROPINAS",
                },
            },
        },
    },
    # La Candelaria SL (empresa BC «La Candelaria»): centro Cebrian San Francisco. Comprobado por MCP el 09/11/2026.
    "LACANDELARIA": {
        "package_name": "Revo - La Candelaria: centro CCF (Cebrian San Francisco)",
        "centers": {
            "CCF": {
                "name": "Cebrian San Francisco", "tenant": "cebriansanfrancisco", "generic": "X96000000",
                "dim3c": "096", "dim1s": "SRE5", "series": ("CCFS", "CCFN", "CCFR"), "items": "CF",
                "batch": {
                    "EFECTIVO": "CSFEFECTIV", "TARJETA": "CSFTARJETA", "GLOVO": "CSFGLOVO", "GLOVOEF": "CSFGLOVOEF",
                    "GOURMET": "CSFGOURMET", "RESTAUR": "CSFRESTAUR", "SODEXO": "CSFSODEXO", "COVER": "CSFCOVER",
                    "UBER": "CSFUBER", "IMPA": "CSFIMPA", "MARCHAN": "CSFMARCHAN", "VOLVER": "CSFVOLVERE",
                    "BIZUM": "CSFBIZUM", "CREDITO": "CSFCREDITO", "TRANSFE": "CSFTRANSFE",
                },
            },
        },
    },
    # Cebrian Actur SL (empresa BC «Cebrian»): centro Cebrian Actur. Comprobado por MCP el 09/11/2026.
    "CEBRIAN": {
        "package_name": "Revo - Cebrian: centro CCA (Cebrian Actur)",
        "centers": {
            "CCA": {
                "name": "Cebrian Actur", "tenant": "cebrianactur", "generic": "X95000000",
                "dim3c": "095", "dim1s": "SRE5", "series": ("CCAS", "CCAN", "CCAR"), "items": "CA",
                "batch": {
                    "EFECTIVO": "CAEFECTIVO", "TARJETA": "CATARJETA", "GLOVO": "CAGLOVO", "GLOVOEF": "CAGLOVOEFE",
                    "GOURMET": "CAGOURMET", "RESTAUR": "CARESTAUR", "SODEXO": "CASODEXO", "COVER": "CACOVER",
                    "UBER": "CAUBER", "IMPA": "CAIMPA", "MARCHAN": "CAMARCHAND", "VOLVER": "CAVOLVEREM",
                    "BIZUM": "CABIZUM", "CREDITO": "CACREDITO", "TRANSFE": "CATRANSFER",
                },
            },
        },
    },
    # Iberica Stadium Restauración SL (empresa BC «Ibérica Stadium»): centro Stadium Casablanca. MCP 09/11/2026.
    "IBERICA": {
        "package_name": "Revo - Iberica Stadium: centro SCA (Stadium Casablanca)",
        "centers": {
            "SCA": {
                "name": "Stadium Casablanca", "tenant": "stadiumcasablanca", "generic": "X98000000",
                "dim3c": "098", "dim1s": "SRE6", "series": ("SCAS", "SCAN", "SCAR"), "items": "SCA",
                "batch": {
                    "EFECTIVO": "STCEFECTIV", "TARJETA": "STCTARJETA", "GLOVO": "STCGLOVO", "GLOVOEF": "STCGLOVOEF",
                    "GOURMET": "STCGOURMET", "RESTAUR": "STCRESTAUR", "SODEXO": "STCSODEXO", "COVER": "STCCOVER",
                    "UBER": "STCUBER", "IMPA": "STCIMPA", "MARCHAN": "STCMARCHAN", "VOLVER": "STCVOLVERE",
                    "BIZUM": "STCBIZUM", "CREDITO": "STCCREDITO", "TRANSFE": "STCTRANSFE",
                },
            },
        },
    },
    # Zurole SL (empresa BC «Zurolé»): centros Carnivoro y Smooth (Frida no se configura). MCP 10/11/2026.
    "ZUROLE": {
        "package_name": "Revo - Zurole: centros ZCA (Carnivoro) y ZSM (Smooth)",
        "centers": {
            "ZCA": {
                "name": "Carnivoro", "tenant": "carnivoro", "generic": "X85000000",
                "dim3c": "085", "dim1s": "SRE1", "series": ("ZCAS", "ZCAN", "ZCAR"), "items": "CA",
                "batch": {
                    "EFECTIVO": "CAEFECTIVO", "TARJETA": "CATARJETA", "GLOVO": "CAGLOVO", "GLOVOEF": "CAGLOVOEFE",
                    "GOURMET": "CAGOURMET", "RESTAUR": "CARESTAUR", "SODEXO": "CASODEXO", "COVER": "CACOVER",
                    "UBER": "CAUBER", "IMPA": "CAIMPA", "MARCHAN": "CAMARCHAND", "VOLVER": "CAVOLVEREM",
                    "BIZUM": "CABIZUM", "CREDITO": "CACREDITO", "TRANSFE": "CATRANSFER", "PROPINAS": "CAPROPINAS",
                },
            },
            "ZSM": {
                "name": "Smooth", "tenant": "smooth", "generic": "X86000000",
                "dim3c": "086", "dim1s": "SRE1", "series": ("ZSMS", "ZSMN", "ZSMR"), "items": "SM",
                "batch": {
                    "EFECTIVO": "SMEFECTIVO", "TARJETA": "SMTARJETA", "GLOVO": "SMGLOVO", "GLOVOEF": "SMGLOVOEFE",
                    "GOURMET": "SMGOURMET", "RESTAUR": "SMRESTAURA", "SODEXO": "SMSODEXO", "COVER": "SMCOVER",
                    "UBER": "SMUBER", "IMPA": "SMIMPA", "MARCHAN": "SMMARCHAND", "VOLVER": "SMVOLVEREM",
                    "BIZUM": "SMBIZUM", "CREDITO": "SMCREDITO", "TRANSFE": "SMTRANSFER", "PROPINAS": "SMPROPINAS",
                },
            },
        },
    },
    # Rosviple SL (empresa BC «Rosviple»): Lagoness, Ole San Sebastian y Ole Zurita. MCP 10/11/2026.
    # Ole San Sebastian usa los productos _OL («PONE OL EN REVO» en el Excel).
    "ROSVIPLE": {
        "package_name": "Revo - Rosviple: centros RLA (Lagoness), ROL (Ole San Sebastian) y ROZ (Ole Zurita)",
        "centers": {
            "RLA": {
                "name": "Lagoness", "tenant": "lagoness", "generic": "X80000000",
                "dim3c": "080", "dim1s": "SRE3", "series": ("RLAS", "RLAN", "RLAR"), "items": "LA",
                "batch": {
                    "EFECTIVO": "LAEFECTIVO", "TARJETA": "LATARJETA", "GLOVO": "LAGLOVO", "GLOVOEF": "LAGLOVOEFE",
                    "GOURMET": "LAGOURMET", "RESTAUR": "LARESTAUR", "SODEXO": "LASODEXO", "COVER": "LACOVER",
                    "UBER": "LAUBER", "IMPA": "LAIMPA", "MARCHAN": "LAMARCHAND", "VOLVER": "LAVOLVEREM",
                    "BIZUM": "LABIZUM", "CREDITO": "LACREDITO", "TRANSFE": "LATRANSFER",
                },
            },
            "ROL": {
                "name": "Ole San Sebastian", "tenant": "olesansebastian", "generic": "X81000000",
                "dim3c": "081", "dim1s": "SRE4", "series": ("ROLS", "ROLN", "ROLR"), "items": "OL",
                "batch": {
                    "EFECTIVO": "OSSEFECTIV", "TARJETA": "OSSTARJETA", "GLOVO": "OSSGLOVO", "GLOVOEF": "OSSGLOVOEF",
                    "GOURMET": "OSSGOURMET", "RESTAUR": "OSSRESTAUR", "SODEXO": "OSSSODEXO", "COVER": "OSSCOVER",
                    "UBER": "OSSUBER", "IMPA": "OSSIMPA", "MARCHAN": "OSSMARCHAN", "VOLVER": "OSSVOLVERE",
                    "BIZUM": "OSSBIZUM", "CREDITO": "OSSCREDITO", "TRANSFE": "OSSTRANSFE",
                },
            },
            "ROZ": {
                "name": "Ole Zurita", "tenant": "olezurita", "generic": "X87000000",
                "dim3c": "087", "dim1s": "SRE4", "series": ("ROZS", "ROZN", "ROZR"), "items": "OZ",
                "batch": {
                    "EFECTIVO": "OZEFECTIVO", "TARJETA": "OZTARJETA", "GLOVO": "OZGLOVO", "GLOVOEF": "OZGLOVOEFE",
                    "GOURMET": "OZGOURMET", "RESTAUR": "OZRESTAUR", "SODEXO": "OZSODEXO", "COVER": "OZCOVER",
                    "UBER": "OZUBER", "IMPA": "OZIMPA", "MARCHAN": "OZMARCHAND", "VOLVER": "OZVOLVEREM",
                    "BIZUM": "OZBIZUM", "CREDITO": "OZCREDITO", "TRANSFE": "OZTRANSFER",
                },
            },
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

# Método tal como llega de Revo (los 25 de GAL + Propinas + Tarjeta Manual), acción (0 crear, 1 omitir), clave de sección
# (None = sin sección), y si la forma de pago es la misma que la sección. Las claves que el centro no tenga se omiten.
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
    ("Cover", 0, "COVER", True),
    ("Crédito", 1, "CREDITO", False),
    ("Efectivo", 0, "EFECTIVO", True),
    ("Efectivo Incidencia", 0, "EFECTIVO", True),
    ("Glovo", 0, "GLOVO", True),
    ("Glovo (Efectivo)", 0, "GLOVOEF", True),
    ("Glovo Efectivo", 0, "GLOVOEF", True),
    ("Impagado", 0, "IMPA", True),
    ("Invitación", 1, None, False),
    ("Marchando", 0, "MARCHAN", True),
    ("Propinas", 0, "PROPINAS", True),
    ("Tarjeta", 0, "TARJETA", True),
    ("Tarjeta Manual", 0, "TARJETA", True),  # visto en Cebrian Actur el 07/11/2026 (CCAS-000097339)
    ("Transferencia", 1, "TRANSFE", True),
    ("Transferencia Bancaria", 1, None, False),
    ("Uber", 0, "UBER", True),
    ("Uber Eats", 0, "UBER", True),
    ("Volveremos", 0, "VOLVER", True),
]


def center_rows(centers):
    rows = []
    for code, c in centers.items():
        s, n, r = c["series"]
        rows.append([
            ("Code", code, True), ("Name", c["name"], False), ("Enabled", "0", False),
            ("RevoTenant", c["tenant"], False), ("GenericCustomerNo", c["generic"], False),
            ("PaymentTermsCode", "CON", False), ("PricesIncludingVAT", "1", False),
            ("DimensionCode", "3C", False), ("DimensionValueCode", c["dim3c"], False),
            ("Dimension2Code", "1S", False), ("Dimension2ValueCode", c["dim1s"], False),
            ("SimplifiedNos", s, False), ("NominalNos", n, False), ("RectifyingNos", r, False),
            ("DefaultSuperGroupID", "8", False),
        ])
    return rows


def letter_rows(centers):
    return [[("CenterCode", code, True), ("Letter", l, True), ("DocumentKind", str(k), False),
             ("SeriesType", str(s), False), ("RequireNIFCustomer", str(n), False), ("Description", d, False)]
            for code in centers for l, k, s, n, d in LETTERS]


def super_group_rows(centers):
    rows = []
    for code, c in centers.items():
        for sg, vat, item, desc, keep in SUPER_GROUPS:
            rows.append([("CenterCode", code, True), ("SuperGroupID", str(sg), True),
                         ("SpecificVAT", "1" if vat is not None else "0", True), ("VAT", str(vat or 0), True),
                         ("ItemNo", f"{item}_{c['items']}", False), ("Description", desc, False),
                         ("KeepPriceSign", str(keep), False)])
    return rows


def pay_method_rows(centers):
    rows = []
    for code, c in centers.items():
        for method, action, key, same_pm in PAY_METHODS:
            if key and key not in c["batch"]:
                continue
            batch = c["batch"][key] if key else ""
            rows.append([("CenterCode", code, True), ("RevoPaymentMethod", method, True),
                         ("MappingAction", str(action), False),
                         ("JournalTemplateName", "COBROS", False), ("JournalBatchName", batch, False),
                         ("PaymentMethodCode", batch if same_pm else "", False)])
    return rows


def build_xml(company_code, company):
    centers = company["centers"]
    tables = [
        # (id tabla, elemento, page id, orden, filas)
        (50401, "RevoCenter", 50401, 1, center_rows(centers)),
        (50402, "RevoDocLetterSetup", 50403, 2, letter_rows(centers)),
        (50403, "RevoSuperGroupMapping", 50404, 3, super_group_rows(centers)),
        (50404, "RevoPayMethodMapping", 50405, 4, pay_method_rows(centers)),
    ]
    out = ['<?xml version="1.0" encoding="UTF-16" standalone="yes"?>',
           f'<DataList MinCountForAsyncImport="100000" ExcludeConfigTables="1" ProductVersion="" '
           f'PackageName="{escape(company["package_name"])}" Code="REVO-{company_code}">']
    for table_id, element, page_id, order, rows in tables:
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
    return "".join(out), tables


def main():
    if len(sys.argv) < 2 or sys.argv[1].upper() not in COMPANIES:
        sys.exit(f"Uso: build_rapidstart_company.py <{'|'.join(COMPANIES)}> [carpeta_salida]")
    code = sys.argv[1].upper()
    out_dir = sys.argv[2] if len(sys.argv) > 2 else "."
    os.makedirs(out_dir, exist_ok=True)
    xml, tables = build_xml(code, COMPANIES[code])
    with gzip.open(os.path.join(out_dir, f"REVO-{code}.rapidstart"), "wb") as f:
        f.write(xml.encode("utf-16"))  # con BOM, como lo exporta BC
    print(f"OK REVO-{code}: " + " / ".join(f"{t[1]} {len(t[4])}" for t in tables) + f" -> {out_dir}")


if __name__ == "__main__":
    main()
