from django.urls import path
from . import views

app_name = "blog"
urlpatterns = [
    path("", views.index, name="index"),
    path("page/<int:page_number>/", views.index, name="page"),
    path("article/<slug:slug>/", views.article_view, name="article"),
    path("tag/<str:tag_name>/", views.tag_view, name="tag"),
    path("tag/<str:tag_name>/page/<int:page_number>/", views.tag_view, name="tag_page"),
    path("rss/", views.ArticlesFeed(), name="rss"),
    path("gmi_index/", views.gmi_index, name="gmi_index"),
    path("gmiarticle/<slug:slug>/", views.gmi_article_view name="gmi_article"),
]
