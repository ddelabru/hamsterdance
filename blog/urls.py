from django.urls import path
from . import views

app_name = "blog"
urlpatterns = [
    path("", views.index, name="index"),
    path("article/<slug:slug>/", views.article_view, name="article"),
    path("tag/<str:tag_name>/", views.tag_view, name="tag"),
]
