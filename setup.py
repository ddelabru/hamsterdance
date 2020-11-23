# /usr/bin/env python3
from setuptools import setup, find_packages
from pkg_resources import parse_requirements


def get_requirements(source):
    with open(source) as f:
        return sorted({str(req) for req in parse_requirements(f.read())})


setup(
    name="hamsterdance",
    version="0.1.1",
    description="hamster.dance custom Django web site",
    author="Dominique Cyprès",
    author_email="lunasspecto@hamster.dance",
    url="https://hamster.dance/",
    packages=find_packages(),
    include_package_data=True,
    package_data={"": ["templates/*/*.html"]},
    scripts = ["manage.py"],
    zip_safe=False,
    classifiers=[
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
    ],
    install_requires=get_requirements("requirements.txt"),
)
