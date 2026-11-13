"""Genera, por empresa, el paquete RapidStart con los clientes pasarela (reuniones con Luis del 12/11/2026).

Por cada centro y cada cuenta de cobro 4412xxN / 4415xx1 de TESORERIAS se crea:
  - un grupo registro cliente PAS-<centro>-<clave> con Cta. clientes y Cta. efectos = esa cuenta (la de la contrapartida
    de su sección de COBROS, comprobado por MCP el 12/11/2026 en las 7 empresas);
  - un cliente pasarela con el mismo código, ese grupo, NAC/NAC, términos CON y forma de pago EFECTO (Crear efectos =
    Sí): desde 1.0.25.0 la línea de la pasarela es de tipo Efecto y queda en Cartera (reunión con Luis del 12/11/2026);
  - en Mapeo métodos de pago, ese cliente como Cliente pasarela en los métodos de esa cuenta.
Sin pasarela: Transferencia, Crédito y Bizum (la deuda queda en el cliente; Bizum pasa a Omitir), Efectivo y Glovo
(efectivo) (pendiente de confirmar con Luis) y Propinas (sin cuenta).

Mismo formato que build_rapidstart_company.py (XML UTF-16 con raíz <DataList>, comprimido en GZip).
Uso:  python3 build_rapidstart_gateways.py <carpeta_salida>     (genera REVO-PAS-<EMPRESA>.rapidstart para las 7)
"""
import gzip
import os
import sys
from xml.sax.saxutils import escape

# Empresa -> centros: (código, nombre, 2 cifras de la cuenta 4412xx / 4415xx, tiene «Tarjeta Manual» en el mapeo)
COMPANIES = {
    "GRUPOOLE": [("GAL", "Almudévar", "89", False), ("GOL", "Olivos", "88", False), ("GVI", "Viñas", "84", False)],
    "DUFFY": [("DBU", "Bull", "92", False)],
    "LACANDELARIA": [("CCF", "Cebrian San Francisco", "96", False)],
    "CEBRIAN": [("CCA", "Cebrian Actur", "95", True)],
    "IBERICA": [("SCA", "Stadium Casablanca", "98", True)],
    "ZUROLE": [("ZCA", "Carnivoro", "85", True), ("ZSM", "Smooth", "86", True)],
    "ROSVIPLE": [("RLA", "Lagoness", "80", True), ("ROL", "Ole San Sebastian", "81", True),
                 ("ROZ", "Ole Zurita", "87", True)],
}

# Clave, etiqueta, cuenta (plantilla: {dd} = 2 cifras del centro), métodos de Revo que van a esa pasarela
GATEWAYS = [
    ("VISA", "Visa", "4412{dd}0", ["Card America Express", "Card VISA / Mastercard", "Tarjeta"]),
    ("RESTAURANTE", "Ch/ Restaurante", "4412{dd}1", ["CH / Restaurant", "Ch/ Restaurant"]),
    ("SODEXO", "Ch/ Sodexo", "4412{dd}2", ["CH / Sodexo", "Ch/ Sodexo"]),
    ("GOURMET", "Ch/ Gourmet", "4412{dd}3", ["CH / Gourmet", "Ch/ Gourmet"]),
    ("MARCHANDO", "Marchando", "4412{dd}4", ["Marchando"]),
    ("UBER", "Uber", "4412{dd}5", ["Uber", "Uber Eats"]),
    ("GLOVO", "Glovo", "4412{dd}6", ["Glovo"]),
    ("VOLVEREMOS", "Volveremos", "4412{dd}7", ["Volveremos"]),
    ("COVER", "Cover", "4412{dd}8", ["Cover"]),
    ("IMPAGADO", "Impagado", "4415{dd}1", ["Impagado"]),
]
SKIP_METHODS = ["Bizum"]  # pasan a Omitir

# Forma de pago de los clientes pasarela: EFECTO (Crear efectos = Sí, sin contrapartida; existe en las 7 empresas,
# comprobado por MCP el 13/11/2026). La línea de la pasarela es de tipo Efecto y BC España exige una forma de pago que
# cree efectos. PAYMENT_METHODS (forma de pago de cada método, sin efectos) se deja como referencia: era la de 1.0.24.0.
GATEWAY_PAYMENT_METHOD = "EFECTO"
_KEYS = ["VISA", "RESTAURANTE", "SODEXO", "GOURMET", "MARCHANDO", "UBER", "GLOVO", "VOLVEREMOS", "COVER", "IMPAGADO"]
PAYMENT_METHODS = {c: dict(zip(_KEYS, pms.split())) for c, pms in {
    "GAL": "ALMTARJETA ALMRESTAUR ALMSODEXO ALMGOURMET ALMMARCHAN ALMUBER ALMGLOVO ALMVOLVERM ALMSTRIPE ALMIMPA",
    "GOL": "OLTARJETA OLRESTAUR OLSODEXO OLGOURMET OLMARCHAND OLUBER OLGLOVO OLVOLVEREM OLSTRIPE OLIMPA",
    "GVI": "VÑSTARJETA VÑSRESTAUR VÑSSODEXO VÑSGOURMET VÑSMARCHAN VÑSUBER VÑSGLOVO VÑSVOLVERE VÑSSTRIPE VÑSIMPA",
    "DBU": "BLTARJETA BLRESTAUR BLSODOXEO BLGOURMET BLMARCHAND BLUBER BLGLOVO BLVOLVEREM BLCOVER BLIMPA",
    "CCF": "CSFTARJETA CSFRESTAUR CSFSODEXO CSFGOURMET CSFMARCHAN CSFUBER CSFGLOVO CSFVOLVERE CSFCOVER CSFIMPA",
    "CCA": "CATARJETA CARESTAUR CASODEXO CAGOURMET CAMARCHAND CAUBER CAGLOVO CAVOLVEREM CACOVER CAIMPA",
    "SCA": "STCTARJETA STCRESTAUR STCSODEXO STCGOURMET STCMARCHAN STCUBER STCGLOVO STCVOLVERE STCCOVER STCIMPA",
    "ZCA": "CATARJETA CARESTAUR CASODEXO CAGOURMET CAMARCHAND CAUBER CAGLOVO CAVOLVEREM CACOVER CAIMPA",
    "ZSM": "SMTARJETA SMRESTAURA SMSODEXO SMGOURMET SMMARCHAND SMUBER SMGLOVO SMVOLVEREM SMCOVER SMIMPA",
    "RLA": "LATARJETA LARESTAUR LASODEXO LAGOURMET LAMARCHAND LAUBER LAGLOVO LAVOLVEREM LACOVER LAIMPA",
    "ROL": "OSSTARJETA OSSRESTAUR OSSSODEXO OSSGOURMET OSSMARCHAN OSSUBER OSSGLOVO OSSVOLVERE OSSCOVER OSSIMPA",
    "ROZ": "OZTARJETA OZRESTAUR OZSODEXO OZGOURMET OZMARCHAND OZUBER OZGLOVO OZVOLVEREM OZCOVER OZIMPA",
}.items()}


def gateway_code(center, key):
    return f"PAS-{center}-{key}"


def build_rows(centers):
    groups, customers, mappings = [], [], []
    for center, name, dd, has_manual in centers:
        for key, label, account, methods in GATEWAYS:
            code = gateway_code(center, key)
            desc = f"Pasarela {label} - {name}"
            # Cta. efectos = la misma cuenta: la línea de la pasarela es un Efecto y BC lo lleva a esta cuenta.
            groups.append([("Code", code, True), ("Description", desc, False),
                           ("ReceivablesAccount", account.format(dd=dd), False),
                           ("BillsAccount", account.format(dd=dd), False)])
            customers.append([("No", code, True), ("Name", desc, False), ("CustomerPostingGroup", code, False),
                              ("GenBusPostingGroup", "NAC", False), ("VATBusPostingGroup", "NAC", False),
                              ("PaymentTermsCode", "CON", False),
                              ("PaymentMethodCode", GATEWAY_PAYMENT_METHOD, False)])
            method_list = methods + (["Tarjeta Manual"] if key == "VISA" and has_manual else [])
            for method in method_list:
                mappings.append([("CenterCode", center, True), ("RevoPaymentMethod", method, True),
                                 ("MappingAction", "0", False), ("GatewayCustomerNo", code, False)])
        for method in SKIP_METHODS:
            mappings.append([("CenterCode", center, True), ("RevoPaymentMethod", method, True),
                             ("MappingAction", "1", False), ("GatewayCustomerNo", "", False)])
    return groups, customers, mappings


def build_xml(company):
    groups, customers, mappings = build_rows(COMPANIES[company])
    tables = [
        # (id tabla, elemento, page id, orden, filas): grupos antes que clientes y clientes antes que el mapeo
        (92, "CustomerPostingGroup", 110, 1, groups),
        (18, "Customer", 22, 2, customers),
        (50404, "RevoPayMethodMapping", 50405, 3, mappings),
    ]
    out = ['<?xml version="1.0" encoding="UTF-16" standalone="yes"?>',
           f'<DataList MinCountForAsyncImport="100000" ExcludeConfigTables="1" ProductVersion="" '
           f'PackageName="Revo - Clientes pasarela {escape(company)}" Code="REVO-PAS-{company}">']
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
    out_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    os.makedirs(out_dir, exist_ok=True)
    for company in COMPANIES:
        xml, tables = build_xml(company)
        with gzip.open(os.path.join(out_dir, f"REVO-PAS-{company}.rapidstart"), "wb") as f:
            f.write(xml.encode("utf-16"))
        print(f"REVO-PAS-{company}: " + " / ".join(f"{t[1]} {len(t[4])}" for t in tables))


if __name__ == "__main__":
    main()
