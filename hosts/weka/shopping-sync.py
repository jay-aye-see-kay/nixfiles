"""Move reminders from each person's Radicale "Shopping" list onto Mealie's
shopping list, as that person, then delete them from Radicale.

A reminder is only deleted once Mealie has it, so anything that fails stays
put for the next run. Completed reminders are deleted without being added.
Configured by environment variables from radicale.nix.
"""

import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET

RADICALE_URL = os.environ["RADICALE_URL"]
MEALIE_URL = os.environ["MEALIE_URL"]
USERS = os.environ["SYNC_USERS"].split()
LIST_NAME = os.environ["LIST_NAME"]
with open(os.path.join(os.environ["CREDENTIALS_DIRECTORY"], "mealie-proxy-secret")) as f:
    MEALIE_SECRET = f.read().strip()

NS = {"d": "DAV:", "c": "urn:ietf:params:xml:ns:caldav"}

FIND_LISTS = b"""<?xml version="1.0"?>
<d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:prop><d:displayname/><c:supported-calendar-component-set/></d:prop>
</d:propfind>"""

GET_TODOS = b"""<?xml version="1.0"?>
<c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
  <d:prop><d:getetag/><c:calendar-data/></d:prop>
  <c:filter><c:comp-filter name="VCALENDAR"><c:comp-filter name="VTODO"/></c:comp-filter></c:filter>
</c:calendar-query>"""


def request(method, url, headers, body=None):
    req = urllib.request.Request(url, data=body, method=method, headers=headers)
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read()


def dav(user, method, path, body=None, extra=None):
    headers = {"X-Remote-User": user, "Content-Type": "application/xml; charset=utf-8"}
    headers.update(extra or {})
    return request(method, urllib.parse.urljoin(RADICALE_URL, path), headers, body)


def find_lists(user):
    """Hrefs of the user's to-do lists named LIST_NAME (any case)."""
    home = "/" + urllib.parse.quote(user) + "/"
    try:
        xml = dav(user, "PROPFIND", home, FIND_LISTS, {"Depth": "1"})
    except urllib.error.HTTPError as e:
        # No home until the account is first added on a phone
        if e.code == 404:
            return []
        raise
    hrefs = []
    for resp in ET.fromstring(xml).findall("d:response", NS):
        name = resp.findtext(".//d:displayname", "", NS)
        comps = {c.get("name") for c in resp.findall(".//c:comp", NS)}
        if name.strip().lower() == LIST_NAME.lower() and (not comps or "VTODO" in comps):
            hrefs.append(resp.findtext("d:href", "", NS))
    return hrefs


def parse_todo(ics):
    """(summary, completed) of the VTODO in an iCalendar text."""
    # Long lines are folded onto following lines that start with a space or tab
    lines = ics.replace("\r\n", "\n").replace("\n ", "").replace("\n\t", "").split("\n")
    summary, completed, in_todo = "", False, False
    for line in lines:
        if line == "BEGIN:VTODO":
            in_todo = True
        elif line == "END:VTODO":
            break
        elif in_todo and ":" in line:
            key, value = line.split(":", 1)
            name = key.split(";", 1)[0].upper()
            if name == "SUMMARY":
                summary = (value.replace("\\n", " ").replace("\\N", " ")
                           .replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\"))
            elif name == "STATUS" and value.upper() == "COMPLETED":
                completed = True
            elif name == "COMPLETED":
                completed = True
    return summary.strip(), completed


def get_todos(user, list_href):
    """(href, etag, summary, completed) for each reminder in a list."""
    xml = dav(user, "REPORT", list_href, GET_TODOS, {"Depth": "1"})
    todos = []
    for resp in ET.fromstring(xml).findall("d:response", NS):
        ics = resp.findtext(".//c:calendar-data", "", NS)
        if not ics:
            continue
        summary, completed = parse_todo(ics)
        todos.append((resp.findtext("d:href", "", NS), resp.findtext(".//d:getetag", "", NS), summary, completed))
    return todos


def delete_todo(user, href, etag):
    # If-Match: leave it alone if it was edited since it was read
    dav(user, "DELETE", href, extra={"If-Match": etag} if etag else None)


def mealie(token, method, path, body=None):
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    data = json.dumps(body).encode() if body is not None else None
    return json.loads(request(method, MEALIE_URL + path, headers, data) or b"null")


def mealie_login(user):
    """A session token for the user, through reverse proxy login."""
    headers = {"Tailscale-User-Login": user, "X-Mealie-Reverse-Proxy-Secret": MEALIE_SECRET}
    return json.loads(request("GET", MEALIE_URL + "/api/auth/reverse-proxy", headers))["access_token"]


def mealie_list_id(token):
    """The household's shopping list. There's meant to be exactly one."""
    lists = mealie(token, "GET", "/api/households/shopping/lists?perPage=-1")["items"]
    if len(lists) != 1:
        names = ", ".join(repr(l["name"]) for l in lists)
        raise RuntimeError(f"expected one Mealie shopping list, found {len(lists)}: {names}")
    return lists[0]["id"]


def sync_user(user):
    """Moves one user's reminders. Returns how many were deleted."""
    todos = [t for href in find_lists(user) for t in get_todos(user, href)]
    if not todos:
        return 0
    to_add = [t for t in todos if not t[3] and t[2]]
    if to_add:
        token = mealie_login(user)
        list_id = mealie_list_id(token)
        # Quantity 0, or Mealie shows "1 beans"
        items = [{"shoppingListId": list_id, "note": t[2], "quantity": 0} for t in to_add]
        mealie(token, "POST", "/api/households/shopping/items/create-bulk", items)
        for t in to_add:
            print(f"{user}: added {t[2]!r}")
    for href, etag, _, _ in todos:
        delete_todo(user, href, etag)
    return len(todos)


def main():
    failed = False
    # Keep going until a pass finds nothing: changes made while this runs
    # (including its own deletes) don't start it again.
    for _ in range(5):
        moved = 0
        for user in USERS:
            try:
                moved += sync_user(user)
            except Exception as e:
                print(f"{user}: {e}", file=sys.stderr)
                failed = True
        if failed or moved == 0:
            break
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
