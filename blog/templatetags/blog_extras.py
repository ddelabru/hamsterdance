import re

import bleach
from bs4 import BeautifulSoup
from django import template
from django.template.defaultfilters import stringfilter
from markdown import markdown


def smartypants_markdown(text):
    return markdown(text, extensions=["smarty"])


def gemtext(input):
    html_doc = markdown(input, extensions=["smarty"])
    html_doc = bleach.clean(
        html_doc,
        tags=["a", "blockquote", "br", "h1", "h2", "h3", "li", "ol", "p", "pre", "ul"],
        protocols=bleach.ALLOWED_PROTOCOLS + ["gemini", "gopher"],
        strip=True,
    )
    soup = BeautifulSoup(html_doc, "html.parser")
    links = []
    for a_tag in soup.find_all("a"):
        links.append((a_tag.get("href"), "".join(a_tag.contents)))
        parent = a_tag.parent
        a_tag.unwrap()
        # parent.smooth()
    for i in range(1, 4):
        for h_tag in soup.find_all(f"h{i}"):
            # h_tag.smooth()
            h_tag.insert_before("#" * i + " ")
            h_tag.insert_after("\n")
            h_tag.unwrap()
    for p_tag in soup.find_all("p"):
        p_text = p_tag.decode(formatter=None).strip()
        p_text = re.sub(r"\n", " ", p_text)
        p_soup = BeautifulSoup(p_text, "html.parser")
        for br_tag in p_soup.find_all("br"):
            br_tag.replace_with("\n")
        p_soup.p.insert_after("\n")
        p_soup.p.unwrap()
        p_tag.replace_with(p_soup.decode(formatter=None))
    for ol_tag in soup.find_all("ol"):
        for i, li_tag in enumerate(ol_tag.find_all("li"), 1):
            # li_tag.smooth()
            li_tag.insert_before(f"{i}. ")
            li_tag.unwrap()
        ol_tag.unwrap()
    for ul_tag in soup.find_all("ul"):
        for li_tag in ul_tag.find_all("li"):
            # li_tag.smooth()
            li_tag.insert_before(f"* ")
            li_tag.unwrap()
        ul_tag.unwrap()
    for blockquote_tag in soup.find_all("blockquote"):
        quote_text = re.sub(
            r"\n*</?blockquote>\n?", "", blockquote_tag.decode(formatter=None)
        )
        quote_text = re.sub(r"\n", "\n>", quote_text)
        quote_text = "\n>" + quote_text + "\n"
        blockquote_tag.replace_with(quote_text)
    for pre_tag in soup.find_all("pre"):
        pre_tag.insert_before("```\n")
        pre_tag.insert_after("```\n")
        pre_tag.unwrap()
    output = soup.decode(formatter=None)
    output = re.sub(r"\n\n+", "\n\n", output)

    if len(links) > 0:
        output += "\n## Links\n\n"
    for link in links:
        output += f"=>{link[0]} {link[1]}\n"

    return output


register = template.Library()
register.filter("markdown", stringfilter(smartypants_markdown))
register.filter("gemtext", stringfilter(gemtext))
