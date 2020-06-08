from datetime import datetime
from django.contrib.syndication.views import Feed
from django.http import Http404
from django.shortcuts import get_object_or_404, render
from django.urls import reverse
from django.utils.feedgenerator import Rss201rev2Feed
from .models import Article, Tag


def index(request, page_number=1):
    articles = Article.objects.filter(published__lte=datetime.now()).order_by(
        "-published"
    )
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
    article = get_object_or_404(Article, slug=slug, published__lte=datetime.now())
    tags = article.tags.all()
    return render(request, "blog/article.html", {"article": article, "tags": tags})


def tag_view(request, tag_name="", page_number=1):
    tag = get_object_or_404(Tag, name=tag_name)
    articles = Article.objects.filter(
        tags__name=tag_name, published__lte=datetime.now()
    ).order_by("-published")
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


class ArticlesFeed(Feed):
    title = "hamster.dance blog articles"
    link = "/blog/"
    description = "Articles from the hamster.dance blog."
    feed_url = "/blog/rss/"
    author_name = "Dominique Cyprès"
    author_email = "lunasspecto@hamster.dance"
    feed_type = Rss201rev2Feed

    def items(self):
        return Article.objects.filter(published__lte=datetime.now()).order_by(
            "-published"
        )

    def item_title(self, item):
        return item.title

    def item_description(self, item):
        published_date_string = item.published.strftime("%d %b %Y")
        return f"Blog article published {published_date_string}."

    def item_link(self, item):
        return reverse("blog:article", args=[item.slug])

    def item_pubdate(self, item):
        return item.published

    def item_updateddate(self, item):
        return item.modified

    def item_categories(self, item):
        return [tag.name for tag in item.tags.all()]
