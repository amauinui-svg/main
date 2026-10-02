# Builds build/IC_Code.rbxmx: a Folder "IC_Code" holding one script per FILES.txt line.
# Each script is named "<parent>|<name>" so the Studio installer knows where it goes.
import os, html
root = os.path.dirname(os.path.abspath(__file__))
items = []
ref = 0
for line in open(os.path.join(root, "FILES.txt")):
    line = line.strip()
    if not line: continue
    path, parent, name, cls = line.split("|")
    src = open(os.path.join(root, path), encoding="utf-8").read()
    ref += 1
    # scripts inside a model are disabled-safe: store everything as ModuleScript to avoid running on insert
    items.append(f'''<Item class="ModuleScript" referent="RBX{ref}"><Properties><string name="Name">{html.escape(parent + "|" + name + "|" + cls)}</string><ProtectedString name="Source"><![CDATA[{src.replace("]]>", "]]]]><![CDATA[>")}]]></ProtectedString></Properties></Item>''')
xml = '<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" version="4"><Item class="Folder" referent="RBX0"><Properties><string name="Name">IC_Code</string></Properties>' + "".join(items) + "</Item></roblox>"
os.makedirs(os.path.join(root, "build"), exist_ok=True)
open(os.path.join(root, "build", "IC_Code.rbxmx"), "w", encoding="utf-8").write(xml)
print(len(items), "scripts", len(xml), "bytes")
