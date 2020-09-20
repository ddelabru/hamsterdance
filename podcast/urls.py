from django.urls import path
from . import views

app_name = "podcast"
urlpatterns = [
    path("", views.index, name="index"),
    path("episode/<slug:slug>/", views.episode_view, name="episode"),
]
