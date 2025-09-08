#!/usr/bin/env python3

import os
import logging
from typing import Any

from glob import glob

import typer
import jinja2

TEMPLATE_FILE = "repos-index.html.j2"

DISTROS: dict[str, dict[str, Any]] = {
    "debian": {
        "codenames": {
            "bookworm": "12",
			"trixie": "13",
        },
    },
	"ubuntu": {
		"codenames": {
			"jammy": "22.04",
			"noble": "24.04",
			"plucky": "25.04",
		},
	},
	"fedora": {
	},
}


def find_sources(root_dir: str) -> list[str]:
	return (
		glob(f"{root_dir}/*.sources") +
		glob(f"{root_dir}/*.repo")
	)

def build_distro_info(root_dir: str) -> list[dict[str, str]]:
	distros = []
	for source_file in find_sources(root_dir):
		logging.info(f"Building distro info for {source_file}")
		name, version = os.path.basename(source_file).split(".", 1)[0].split("-", 1)
		suffix = ""
		distro_info = DISTROS[name]
		if version in distro_info.get("codenames", {}):
			suffix = f"({version})"
			version = distro_info["codenames"][version]
		info = {
			"source_file": os.path.basename(source_file),
			"name": name.capitalize(),
			"version": version,
			"suffix": suffix,
		}
		distros.append(info)
	return sorted(distros, key=lambda x: (x["name"], x["version"]))

def generate_index(root_dir: str) -> str:
    env = jinja2.Environment(loader=jinja2.FileSystemLoader("."))
    template = env.get_template(TEMPLATE_FILE)
    return template.render(distros=build_distro_info(root_dir))

def typer_main(
	root_dir: str = typer.Argument(help="The directory to read the sources from"),
    output_file: str = typer.Argument(help="The file to write the index to"),
):
    logging.basicConfig(level=logging.INFO)
    index = generate_index(root_dir)
    with open(output_file, "w") as f:
        f.write(index)

if __name__ == "__main__":
    typer.run(typer_main)
