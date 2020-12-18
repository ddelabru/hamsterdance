from datetime import datetime
from html import unescape
import logging
import secrets
from django.contrib.syndication.views import Feed
from django.http import Http404, HttpResponseNotAllowed, HttpResponseRedirect
from django.shortcuts import get_object_or_404, render
from django.urls import reverse
from django.utils.feedgenerator import Rss201rev2Feed
from django.utils.html import strip_tags
from markdown import markdown
from .models import Article, Comment, Tag
from hamsterdance import settings


def index(request, page_number=1):
    articles = Article.objects.filter(published__lte=datetime.now()).order_by(
        "-published"
    )
    valid_number = page_number > 0 and ((page_number - 1) * 20) < len(articles)
    if valid_number:
        return render(
            request,
            "blog/index.html",
            {
                "articles": articles[20 * (page_number - 1) : 20 * page_number],
                "last_page": (20 * page_number) >= len(articles),
                "next_page": page_number + 1,
                "page_number": page_number,
                "previous_page": page_number - 1,
            },
        )
    else:
        raise Http404("Invalid page number")


def article_view(request, slug=""):
    article = get_object_or_404(Article, slug=slug, published__lte=datetime.now())
    comments = Comment.objects.filter(approved=True, article=article)
    comments_total = len(comments)
    tags = article.tags.all()
    return render(
        request,
        "blog/article.html",
        {
            "article": article,
            "comments": comments,
            "comments_total": comments_total,
            "tags": tags,
        },
    )


def comment_compose(request, slug=""):
    article = get_object_or_404(Article, slug=slug, published__lte=datetime.now())
    return render(request, "blog/compose-comment.html", {"article": article})


def comment_submit(request, slug=""):
    article = get_object_or_404(Article, slug=slug, published__lte=datetime.now())
    if request.method != "POST":
        return render(
            request, "blog/comment-failed.html", {"article": article}, status=405
        )
    if request.POST.get("spam", "1") == "0" and request.POST.get("body"):
        Comment.objects.create(
            article=article,
            body=request.POST["body"],
            name=request.POST.get("name", ""),
            approved=False,
        )
        return render(request, "blog/comment-submitted.html", {"article": article})
    return render(request, "blog/comment-failed.html", {"article": article}, status=400)


def comment_approve(request, id):
    comment = get_object_or_404(Comment, id=id)
    if request.method == "GET" and secrets.compare_digest(
        request.GET.get("token", ""), comment.token
    ):
        comment.approved = True
        comment.save()
        return HttpResponseRedirect(
            reverse("blog:article", args=[comment.article.slug])
        )
    return Http403()


def tag_view(request, tag_name="", page_number=1):
    tag = get_object_or_404(Tag, name=tag_name)
    articles = Article.objects.filter(
        tags__name=tag_name, published__lte=datetime.now()
    ).order_by("-published")
    valid_number = page_number > 0 and ((page_number - 1) * 20) < len(articles)
    if valid_number:
        return render(
            request,
            "blog/tag.html",
            {
                "tag": tag,
                "articles": articles[20 * (page_number - 1) : 20 * page_number],
                "last_page": (20 * page_number) >= len(articles),
                "next_page": page_number + 1,
                "page_number": page_number,
                "previous_page": page_number - 1,
            },
        )
    else:
        raise Http404("Invalid page number")


def gmi_index(request):
    articles = Article.objects.filter(published__lte=datetime.now()).order_by(
        "-published"
    )
    return render(request, "blog/index.gmi", {"articles": articles})


def gmi_article_view(request, slug=""):
    article = get_object_or_404(Article, slug=slug, published__lte=datetime.now())
    return render(request, "blog/article.gmi", {"article": article})


class ArticlesFeed(Feed):
    title = "hamster.dance blog articles"
    link = f"https://{settings.HOST_DOMAIN}/blog/"
    description = "Articles from the hamster.dance blog."
    feed_url = f"https://{settings.HOST_DOMAIN}/blog/rss/"
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
        return item.description

    def item_link(self, item):
        return f"https://{settings.HOST_DOMAIN}/blog/article/{item.slug}/"

    def item_pubdate(self, item):
        return item.published

    def item_updateddate(self, item):
        return item.modified

    def item_categories(self, item):
        return [tag.name for tag in item.tags.all()]
