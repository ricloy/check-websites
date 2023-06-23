# check-websites

Check websistes contained in [OpenStreetMap](https://www.openstreetmap.org) elements and report those which have some problems.

This repository using GitHub actions, daily runs a script which is split in three different main stages:
1) Fetch a list of websites contained in the OSM database for the current area
2) Reduce the list to a set of unique URIs and check with Curl if those URIs are reacheable
3) Produce a report showing the OSM elements, the website URI and the problems encountered (if any)

Common problems are expected to be:
* website doesn't exist anymore
* website misspelt
* website redirects to another one or just a "variation" of the same website (e.g. https instead of http)

Please be very cautious whenb using this information: websites may contain malicious content that may harm your device or adults-only material.

## License

Creative Commons Zero v1.0 Universal
