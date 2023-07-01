# check-websites

Check websistes contained in [OpenStreetMap](https://www.openstreetmap.org) elements and report those which have some problems.

This repository, using GitHub actions, ~daily~ weekly runs a script which is split in three different main stages:
1) Fetch a list of websites contained in the OSM database for the current area;
2) Reduce the list to a set of unique URIs and check with Curl if those URIs are reacheable;
3) Produce a report showing the OSM elements, the website URI and the problems encountered (if any).

Common problems are expected to be:
* website doesn't exist anymore
* website misspelt
* website redirects to another one or just a "variation" of the same website (e.g. https instead of http)

Pleaseuse caution when using this information: the websites links listed in these files are automically gathered and are in no way verified; consequently,they may contain malicious content or illegal, adults-only, etc. material that may harm your device or traumatise you.

## License

Code is released under Creative Commons Zero v1.0 Universal
All data is derived from OpenStreetMap and as such is released under ODbL [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright). 
