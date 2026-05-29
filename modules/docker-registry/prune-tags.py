import json
import os
import re
import sys
import urllib.error
import urllib.parse
import urllib.request

registry_url = os.environ["REGISTRY_URL"].rstrip("/")
storage_path = os.environ["REGISTRY_STORAGE_PATH"]
keep_newest_tags = int(os.environ["KEEP_NEWEST_TAGS"])
prunable_tag_pattern = re.compile(os.environ["PRUNABLE_TAG_PATTERN"])
protected_tag_pattern = re.compile(os.environ["PROTECTED_TAG_PATTERN"])

accept = ", ".join(
    [
        "application/vnd.oci.image.index.v1+json",
        "application/vnd.docker.distribution.manifest.list.v2+json",
        "application/vnd.oci.image.manifest.v1+json",
        "application/vnd.docker.distribution.manifest.v2+json",
        "application/vnd.docker.distribution.manifest.v1+json",
    ]
)


def request(path, method="GET"):
    req = urllib.request.Request(
        registry_url + path,
        method=method,
        headers={"Accept": accept},
    )
    with urllib.request.urlopen(req, timeout=30) as response:
        return response.read(), response.headers


def request_json(path):
    body, _headers = request(path)
    return json.loads(body)


def quote_path(value):
    return urllib.parse.quote(value, safe="/")


def quote_digest(value):
    return urllib.parse.quote(value, safe=":")


def tag_link_path(repo, tag):
    return os.path.join(
        storage_path,
        "docker/registry/v2/repositories",
        repo,
        "_manifests/tags",
        tag,
        "current/link",
    )


def tag_mtime(repo, tag):
    try:
        return os.stat(tag_link_path(repo, tag)).st_mtime
    except FileNotFoundError:
        return 0


def tag_digest(repo, tag):
    try:
        with open(tag_link_path(repo, tag)) as link:
            digest = link.read().strip()
            if digest:
                return digest
    except FileNotFoundError:
        pass

    path = f"/v2/{quote_path(repo)}/manifests/{quote_path(tag)}"
    try:
        _body, headers = request(path, method="HEAD")
    except urllib.error.HTTPError as error:
        print(
            f"Skipping {repo}:{tag}: failed to resolve digest: HTTP {error.code}",
            file=sys.stderr,
        )
        return None
    return headers.get("Docker-Content-Digest")


catalog = request_json("/v2/_catalog")
deleted = 0

for repo in sorted(catalog.get("repositories", [])):
    tags_response = request_json(f"/v2/{quote_path(repo)}/tags/list")
    tags = sorted(tags_response.get("tags") or [])
    candidates = [
        tag
        for tag in tags
        if prunable_tag_pattern.match(tag) and not protected_tag_pattern.match(tag)
    ]
    candidates.sort(key=lambda tag: tag_mtime(repo, tag), reverse=True)

    keep_tags = set(tags) - set(candidates[keep_newest_tags:])
    protected_digests = {
        digest for digest in (tag_digest(repo, tag) for tag in keep_tags) if digest
    }

    for tag in candidates[keep_newest_tags:]:
        digest = tag_digest(repo, tag)
        if not digest:
            continue
        if digest in protected_digests:
            print(f"Keeping {repo}:{tag}; digest is still referenced by a retained tag")
            continue

        path = f"/v2/{quote_path(repo)}/manifests/{quote_digest(digest)}"
        try:
            request(path, method="DELETE")
        except urllib.error.HTTPError as error:
            if error.code == 404:
                print(f"Already deleted {repo}:{tag} ({digest})")
                continue
            raise

        deleted += 1
        print(f"Deleted {repo}:{tag} ({digest})")

print(f"Deleted {deleted} prunable registry manifest(s)")
