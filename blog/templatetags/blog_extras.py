from django import template
from django.template.defaultfilters import stringfilter
from markdown import markdown

def smartypants_markdown(text):
    return markdown(text, extensions=["smarty"])

register = template.Library()
register.filter("markdown", stringfilter(smartypants_markdown))
