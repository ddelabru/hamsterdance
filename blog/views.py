from django.shortcuts import render
from .models import Article


def index(request):
    return render(
        request,
        "blog/index.html",
        {"articles": Article.objects.order_by("-published")},
    )
