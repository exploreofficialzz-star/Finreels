#!/usr/bin/env python3
"""
Parses FinReels' three source research docs into one structured JSON file
that becomes the app's `assets/data/resource_categories.json`.

Sources (all on disk, read mechanically — no hand-transcription):
  1. FinReels_20_Skills_Business_Questions.md   -> 20 skills, 5 questions each
  2. Finkeels_20_Businesses_Framework.md        -> 20 businesses, 10 Q&A each
  3. finreels-business-of-profession-curriculum.md
       Part 1  -> 10 curriculum modules (M1-M10)
       Part 2  -> the 2026 tax-reform fact bank
       Part 3  -> 20 professions: real problem / 4 questions / don't-know fact

The canonical id/section/number/name for all 60 categories is taken from the
verified table of contents inside FinReels_Complete_Resource_Directory PDF
(extracted separately to /tmp/complete_dir.txt), NOT re-typed by hand.
"""
import json
import re
import unicodedata

UPLOADS = "/mnt/user-data/uploads"


def slugify(name: str) -> str:
    name = name.split(" (Trade)")[0]
    name = unicodedata.normalize("NFKD", name)
    name = re.sub(r"[/&-]", " ", name)          # separators, not deletions
    name = re.sub(r"[^\w\s]", "", name).strip().lower()
    name = re.sub(r"\s+", "_", name)
    return name


# ---------------------------------------------------------------------------
# 1. Canonical 60-category list, taken verbatim from the verified PDF ToC
#    (grep output already confirmed against both source PDFs).
# ---------------------------------------------------------------------------
CANONICAL = {
    "skill": [
        "Tailoring & Fashion Design", "Hairdressing & Hairstyling", "Barbing",
        "Makeup Artistry", "Welding & Metal Fabrication",
        "Carpentry & Furniture Making", "Plumbing",
        "Electrical Installation & Wiring", "Auto Mechanics",
        "Phone & Electronics Repair", "Graphic Design", "Web/App Development",
        "Photography", "Videography & Video Editing", "Catering & Baking",
        "Event Decoration & Planning", "Shoemaking & Leatherwork",
        "POP/Tiling & Interior Decor", "Solar Installation & Renewable Energy",
        "AC & Refrigeration Repair",
    ],
    "business": [
        "POS/Agent Banking", "Provision Store/Mini-Mart",
        "Fashion Retail/Boutique", "Food Vending/Catering/Meal-Prep",
        "Real Estate Agency", "Logistics/Dispatch Rider",
        "Event Planning & Rentals", "Salon/Barbing/Beauty Spa",
        "Car Hire/Ride-Hailing Fleet", "Poultry Farming", "Fish Farming",
        "Laundry & Dry-Cleaning", "Bakery/Confectionery",
        "Cosmetics & Skincare", "Phone & Gadget Sales/Repair",
        "Private Tutorial/Online Tutoring", "Mini-Importation/E-commerce",
        "Cleaning Services", "Pure Water/Sachet & Bottled Water",
        "Social Media/Digital Marketing Agency",
    ],
    "profession": [
        "Medicine", "Law", "Pharmacy", "Nursing", "Accounting", "Engineering",
        "Architecture", "Estate Management/Surveying", "Banking & Finance",
        "Mass Communication/Media & PR", "Computer Science/Software Engineering",
        "Agriculture", "Education", "Dentistry", "Psychology/Counselling",
        "Fashion Design & Tailoring (Trade)", "Hairdressing/Cosmetology (Trade)",
        "Catering & Event Planning (Trade)", "Automobile Technology (Trade)",
        "Photography & Videography (Trade)",
    ],
}

categories = {}
for section, names in CANONICAL.items():
    for i, name in enumerate(names, start=1):
        cid = f"{section}_{i:02d}_{slugify(name)}"
        categories[cid] = {
            "id": cid,
            "section": section,
            "number": i,
            "name": name,
            "skillQuestions": None,
            "businessQA": None,
            "realProblem": None,
            "businessQuestions": None,
            "dontKnowFact": None,
            "dontKnowModule": None,
            "dontKnowModules": None,
        }


def find_category(section: str, number: int):
    return categories[f"{section}_{number:02d}_" + slugify(CANONICAL[section][number - 1])]


# ---------------------------------------------------------------------------
# 2. Skills doc -> 5 questions each
# ---------------------------------------------------------------------------
with open(f"{UPLOADS}/FinReels_20_Skills_Business_Questions.md", encoding="utf-8") as f:
    skills_txt = f.read()

skill_blocks = re.split(r"\n## (\d+)\. (.+?)\n", skills_txt)[1:]
# skill_blocks = [num, name, body, num, name, body, ...]
for i in range(0, len(skill_blocks), 3):
    num, name, body = int(skill_blocks[i]), skill_blocks[i + 1].strip(), skill_blocks[i + 2]
    questions = re.findall(r"^- (.+)$", body, flags=re.MULTILINE)
    cat = find_category("skill", num)
    cat["skillQuestions"] = [q.strip() for q in questions]
    assert len(cat["skillQuestions"]) == 5, f"skill {num} {name} got {len(questions)} q"

# ---------------------------------------------------------------------------
# 3. Businesses doc -> 10 universal questions + 10 answers per business
# ---------------------------------------------------------------------------
with open(f"{UPLOADS}/Finkeels_20_Businesses_Framework.md", encoding="utf-8") as f:
    biz_txt = f.read()

framework_block = re.search(r"## The Framework\n(.+?)\n---", biz_txt, flags=re.DOTALL).group(1)
template_questions = [q.strip() for q in re.findall(r"^\d+\.\s+(.+)$", framework_block, flags=re.MULTILINE)]
assert len(template_questions) == 10

biz_blocks = re.split(r"\n## (\d+)\. (.+?)\n", biz_txt)[1:]
for i in range(0, len(biz_blocks), 3):
    num, name, body = int(biz_blocks[i]), biz_blocks[i + 1].strip(), biz_blocks[i + 2]
    answers = [a.strip() for a in re.findall(r"^\d+\.\s+(.+)$", body, flags=re.MULTILINE)]
    assert len(answers) == 10, f"business {num} {name} got {len(answers)} a"
    cat = find_category("business", num)
    cat["businessQA"] = [{"question": q, "answer": a} for q, a in zip(template_questions, answers)]

# ---------------------------------------------------------------------------
# 4. Curriculum doc -> Part 1 modules, Part 2 tax reform, Part 3 professions
# ---------------------------------------------------------------------------
with open(f"{UPLOADS}/finreels-business-of-profession-curriculum.md", encoding="utf-8") as f:
    curriculum_txt = f.read()

part1 = re.search(r"## Part 1.+?\n(.+?)\n---", curriculum_txt, flags=re.DOTALL).group(1)
modules = []
for m in re.finditer(r"\|\s*(M\d+)\s*\|\s*(.+?)\s*\|\s*(.+?)\s*\|", part1):
    code, mname, desc = m.groups()
    if code == "#":
        continue
    modules.append({"code": code, "name": mname.strip(), "description": desc.strip()})
assert len(modules) == 10, f"got {len(modules)} modules"

part2 = re.search(r"## Part 2.+?\n(.+?)\n---", curriculum_txt, flags=re.DOTALL).group(1)
tax_facts = [f.strip() for f in re.findall(r"^- (.+)$", part2, flags=re.MULTILINE)]
why_match = re.search(r"\*\*Why this matters for FinReels:\*\*\s*(.+?)(?:\n\n|\Z)", part2, flags=re.DOTALL)
tax_reform = {
    "headline": "Nigeria's tax system was overhauled by four laws effective 1 January 2026.",
    "facts": [re.sub(r"\*\*(.+?)\*\*", r"\1", f) for f in tax_facts],
    "whyItMatters": re.sub(r"\s+", " ", why_match.group(1)).strip() if why_match else None,
}

part3 = re.search(r"## Part 3.+?\n(.+?)\n## Part 4", curriculum_txt, flags=re.DOTALL).group(1)
prof_blocks = re.split(r"\n\*\*(\d+)\. (.+?)\*\*\n", part3)[1:]
for i in range(0, len(prof_blocks), 3):
    num, name, body = int(prof_blocks[i]), prof_blocks[i + 1].strip(), prof_blocks[i + 2]
    real_problem = re.search(r"- Real problem:\s*(.+)", body).group(1).strip()
    bq_block = re.search(r"- Business questions:\n((?:\s+- .+\n?)+)", body).group(1)
    biz_questions = [q.strip() for q in re.findall(r"^\s+- (.+)$", bq_block, flags=re.MULTILINE)]
    # Some entries tag more than one module inside one backtick span, e.g.
    # `[M1] [M6]` -> capture all module codes present.
    dk = re.search(r"- Don't know:\s*(.+?)\s*`((?:\[M\d+\]\s*)+)`", body)
    dk_modules = re.findall(r"M\d+", dk.group(2))
    cat = find_category("profession", num)
    cat["realProblem"] = real_problem
    cat["businessQuestions"] = biz_questions
    cat["dontKnowFact"] = dk.group(1).strip()
    cat["dontKnowModule"] = dk_modules[0]
    cat["dontKnowModules"] = dk_modules
    assert len(biz_questions) == 4, f"profession {num} {name} got {len(biz_questions)} q"

# ---------------------------------------------------------------------------
# 5. Sanity: every category has its expected fields populated
# ---------------------------------------------------------------------------
missing = []
for cid, c in categories.items():
    if c["section"] == "skill" and not c["skillQuestions"]:
        missing.append(cid)
    if c["section"] == "business" and not c["businessQA"]:
        missing.append(cid)
    if c["section"] == "profession" and not c["realProblem"]:
        missing.append(cid)
if missing:
    print("WARNING - missing data for:", missing)
else:
    print("OK: all 60 categories fully populated.")

out = {
    "modules": modules,
    "taxReform": tax_reform,
    "categories": list(categories.values()),
}

with open("/home/claude/resource_categories.json", "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2, ensure_ascii=False)

print(f"Wrote {len(categories)} categories, {len(modules)} modules.")
print(f"Skills with questions: {sum(1 for c in categories.values() if c['skillQuestions'])}")
print(f"Businesses with Q&A:   {sum(1 for c in categories.values() if c['businessQA'])}")
print(f"Professions filled:    {sum(1 for c in categories.values() if c['realProblem'])}")
