"""Convierte el Markdown exportado del registro en un HTML autocontenido (estados en color).
Uso: python md_to_html.py <md.b64> <salida.html> "<texto fecha export>"
"""
import base64
import html
import re
import sys

STATUS = {"Pendiente": "st0", "En curso": "st1", "Hecho": "st2", "No aplica": "st3"}


def inline(text):
    text = html.escape(text, quote=False)
    text = re.sub(r"`([^`]+)`", r"<code>\1</code>", text)
    text = re.sub(r"\*\*([^*]+)\*\*", r"<strong>\1</strong>", text)
    text = re.sub(r"(?<![\w*])\*([^*]+)\*(?![\w*])", r"<em>\1</em>", text)
    text = re.sub(r"\[([^\]]+)\]\(([^)]+)\)", r'<a href="\2">\1</a>', text)
    return text.replace("\\_", "_")


def cell(text):
    text = text.strip()
    if text in STATUS:
        return '<span class="st %s">%s</span>' % (STATUS[text], text)
    return inline(text)


def split_row(line):
    return [c for c in line.strip().strip("|").split("|")]


def convert(md):
    out, lines, i = [], md.splitlines(), 0
    while i < len(lines):
        line = lines[i]
        if line.startswith("|"):
            header = split_row(line)
            i += 2  # cabecera + separador
            rows = []
            while i < len(lines) and lines[i].startswith("|"):
                rows.append(split_row(lines[i]))
                i += 1
            out.append('<div class="scroll"><table><thead><tr>' +
                       "".join("<th>%s</th>" % inline(h.strip()) for h in header) + "</tr></thead><tbody>")
            for r in rows:
                out.append("<tr>" + "".join("<td>%s</td>" % cell(c) for c in r) + "</tr>")
            out.append("</tbody></table></div>")
            continue
        m = re.match(r"(#{1,3}) (.*)", line)
        if m:
            lvl = len(m.group(1))
            out.append("<h%d>%s</h%d>" % (lvl, inline(m.group(2)), lvl))
        elif line.strip():
            out.append("<p>%s</p>" % inline(line))
        i += 1
    return "\n".join(out)


CSS = """
:root { --fg:#1f2328; --muted:#59636e; --line:#d1d9e0; --head:#f6f8fa; --accent:#0b6e75; --bg:#ffffff; }
@media (prefers-color-scheme: dark) { :root { --fg:#e6edf3; --muted:#9198a1; --line:#3d444d; --head:#151b23; --accent:#4fb3bb; --bg:#0d1117; } }
* { box-sizing: border-box; }
body { margin:0; background:var(--bg); color:var(--fg); font:14px/1.5 "Segoe UI", system-ui, sans-serif; }
main { max-width:1200px; margin:0 auto; padding:24px 16px 48px; }
h1 { font-size:24px; margin:0 0 4px; color:var(--accent); }
h2 { font-size:18px; margin:32px 0 8px; border-bottom:2px solid var(--accent); padding-bottom:4px; }
h3 { font-size:15px; margin:20px 0 6px; }
p { margin:6px 0 10px; }
.scroll { overflow-x:auto; margin:8px 0 16px; }
table { border-collapse:collapse; width:100%; }
th, td { border:1px solid var(--line); padding:6px 8px; text-align:left; vertical-align:top; }
th { background:var(--head); font-weight:600; }
code { font-family:Consolas, monospace; font-size:13px; }
a { color:var(--accent); }
.st { display:inline-block; padding:1px 8px; border-radius:10px; font-size:12px; font-weight:600; white-space:nowrap; }
.st0 { background:#eaeef2; color:#424a53; }
.st1 { background:#fff1c2; color:#7a5500; }
.st2 { background:#d6f5dc; color:#1a6b30; }
.st3 { background:#e7e7ef; color:#55556a; }
footer { margin-top:32px; color:var(--muted); font-size:12px; }
"""

src = sys.argv[1]
md = open(src, encoding="utf-8").read() if src.endswith(".md") else base64.b64decode(open(src, encoding="ascii").read().strip()).decode("utf-8")
md = re.sub(r"^Nov 5, 2026 · @Omar Carreño$", "05/11/2026 · Omar Carreño", md, flags=re.M)
page = ("<!doctype html>\n<html lang=\"es\">\n<head>\n<meta charset=\"utf-8\">\n"
        "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
        "<title>Registro paso a producción</title>\n<style>" + CSS + "</style>\n</head>\n<body>\n<main>\n"
        + convert(md) + "\n<footer>Actualizado el " + sys.argv[3] + ".</footer>\n</main>\n</body>\n</html>\n")
open(sys.argv[2], "w", encoding="utf-8").write(page)
print(len(page))
