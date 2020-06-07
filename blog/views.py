from django.http import Http404
from django.shortcuts import get_object_or_404, render
from .models import Article, Tag


def index(request, page_number=1):
    articles = Article.objects.order_by("-published")
    valid_number = page_number > 0 and ((page_number - 1) * 5) < len(articles)
    if valid_number:
        return render(
            request,
            "blog/index.html",
            {
                "articles": articles[5 * (page_number - 1) : 5 * page_number],
                "last_page": (5 * page_number) > len(articles),
                "next_page": page_number + 1,
                "page_number": page_number,
                "previous_page": page_number - 1,
            },
        )
    else:
        raise Http404("Invalid page number")


def article_view(request, slug=""):
    article = get_object_or_404(Article, slug=slug)
    tags = article.tags.all()
    return render(request, "blog/article.html", {"article": article, "tags": tags})


def tag_view(request, tag_name="", page_number=1):
    tag = get_object_or_404(Tag, name=tag_name)
    articles = Article.objects.filter(tags__name=tag_name).order_by("-published")
    valid_number = page_number > 0 and ((page_number - 1) * 5) < len(articles)
    if valid_number:
        return render(
            request,
            "blog/tag.html",
            {
                "tag": tag,
                "articles": articles[5 * (page_number - 1) : 5 * page_number],
                "last_page": (5 * page_number) > len(articles),
                "next_page": page_number + 1,
                "page_number": page_number,
                "previous_page": page_number - 1,
            },
        )
    else:
        raise Http404("Invalid page number")
