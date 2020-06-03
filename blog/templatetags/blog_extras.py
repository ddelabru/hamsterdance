from django import template
from django.template.defaultfilters import stringfilter
from markdown import markdown

register = template.Library()
register.filter("markdown", stringfilter(markdown))
