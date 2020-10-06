from datetime import datetime
from django.shortcuts import get_object_or_404, render
from .models import Episode


def index(request, page_number=1):
    seasons = (
        Episode.objects.filter(published__lte=datetime.now())
        .distinct("season")
        .values_list("season", flat=2)
    )
    season_episodes = {
        season: Episode.objects.filter(published__lte=datetime.now(), season=season)
        for season in seasons
    }
    return render(
        request,
        "podcast/index.html",
        {"seasons": seasons, "season_episodes": season_episodes},
    )


def episode_view(request, slug=""):
    episode = get_object_or_404(Episode, slug=slug, published__lte=datetime.now())
    return render(request, "podcast/episode.html", {"episode": episode})
