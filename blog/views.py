from django.shortcuts import get_object_or_404, render
from .models import Article, Tag


def index(request):
    return render(
        request,
        "blog/index.html",
        {"articles": Article.objects.order_by("-published")},
    )

def article_view(request, slug=""):
    article = get_object_or_404(Article, slug=slug)
    tags = article.tags.all()
    return render(
        request, "blog/article.html", {"article": article, "tags": tags}
    )

def tag_view(request, tag_name=""):
    tag = get_object_or_404(Tag, name=tag_name)
    return render(
        request,
        "blog/tag.html",
        {
            "tag": tag,
            "articles": Article.objects.filter(
                tags__name=tag_name
            ).order_by("-published"),
        },
    )