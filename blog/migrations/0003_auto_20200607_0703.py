# Generated by Django 3.0.7 on 2020-06-07 07:03

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("blog", "0002_auto_20200607_0051"),
    ]

    operations = [
        migrations.AlterField(
            model_name="article", name="published", field=models.DateTimeField(),
        ),
    ]
