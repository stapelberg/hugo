---
layout: post
title:  "Debian Code Search: OpenAPI now available"
date:   2021-03-06 11:15:11 +01:00
categories: Artikel
tweet_url: "https://twitter.com/zekjur/status/1368144954804043777"
tags:
- debian
---

[Debian Code Search](https://codesearch.debian.net/) now offers an OpenAPI-based API!

Various developers have created ad-hoc client libraries based on how the web
interface works.

The goal of offering an OpenAPI-based API is to provide developers with
automatically generated client libraries for a large number of programming
languages, that target a stable interface independent of the web interface’s
implementation details.

## Getting started

1. Visit https://codesearch.debian.net/apikeys/ to download your personal API
   key. Login via [Debian’s GitLab instance
   salsa.debian.org](https://salsa.debian.org/); register there if you have no
   account yet.

1. Find the Debian Code Search client library for your programming language. If
   none exists yet, [auto-generate a client library on editor.swagger.io: click
   “Generate
   Client”](https://editor.swagger.io/?url=https://codesearch.debian.net/openapi2.yaml).

1. Search all code in Debian from your own analysis tool, migration tracking
   dashboard, etc.

## curl example

```shell
curl \
  -H "x-dcs-apikey: $(cat dcs-apikey-stapelberg.txt)" \
  -X GET \
  "https://codesearch.debian.net/api/v1/search?query=i3Font&match_mode=regexp" 
```

## Web browser example

You can try out the API in your web browser in the [OpenAPI
documentation](https://codesearch.debian.net/apikeys/#openapi-doc-browser).

## Code example (Go)

Here’s an example program that demonstrates how to set up an auto-generated Go
client for the Debian Code Search OpenAPI, run a query, and aggregate the results:



```go
func burndown() error {
	cfg := openapiclient.NewConfiguration()
	cfg.AddDefaultHeader("x-dcs-apikey", apiKey)
	client := openapiclient.NewAPIClient(cfg)
	ctx := context.Background()

	// Search through the full Debian Code Search corpus, blocking until all
	// results are available:
	results, _, err := client.SearchApi.Search(ctx, "fmt.Sprint(err)", &openapiclient.SearchApiSearchOpts{
		// Literal searches are faster and do not require escaping special
		// characters, regular expression searches are more powerful.
		MatchMode: optional.NewString("literal"),
	})
	if err != nil {
		return err
	}

	// Print to stdout a CSV file with the path and number of occurrences:
	wr := csv.NewWriter(os.Stdout)
	header := []string{"path", "number of occurrences"}
	if err := wr.Write(header); err != nil {
		return err
	}
	occurrences := make(map[string]int)
	for _, result := range results {
		occurrences[result.Path]++
	}
	for _, result := range results {
		o, ok := occurrences[result.Path]
		if !ok {
			continue
		}
		// Print one CSV record per path:
		delete(occurrences, result.Path)
		record := []string{result.Path, strconv.Itoa(o)}
		if err := wr.Write(record); err != nil {
			return err
		}
	}
	wr.Flush()
	return wr.Error()
}
```

The full example can be found under
[`burndown.go`](https://github.com/Debian/dcs/blob/3d6a18f010e915f77b4833189286100308c539cb/_example/burndown.go).

## Feedback?

File a [GitHub issue on
`github.com/Debian/dcs`](https://github.com/Debian/dcs/issues) please!

## Migration status

I’m aware of the following [third-party projects using Debian Code
Search](https://codesearch.debian.net/thirdparty):

Tool | Migration status
-----|----------
[Debian Code Search CLI tool](https://salsa.debian.org/debian/codesearch-cli) | [Updated to OpenAPI](https://salsa.debian.org/debian/codesearch-cli/-/merge_requests/1)
[identify-incomplete-xs-go-import-path](https://salsa.debian.org/aviau/identify-incomplete-xs-go-import-path) | [Update pending](https://salsa.debian.org/aviau/identify-incomplete-xs-go-import-path/-/merge_requests/1)
[gnome-codesearch](https://gitlab.gnome.org/nbenitez/gnome-codesearch) | makes no API queries

If you find any others, please point them to this post in case they are not
using Debian Code Search’s OpenAPI yet.
