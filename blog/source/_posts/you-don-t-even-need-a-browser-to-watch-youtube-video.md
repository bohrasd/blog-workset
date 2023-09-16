---
title: you don't even need a browser to watch youtube video
date: 2021-05-13 08:59:38
tags: terminal
---

bind this to your i3/sway configuration

```bash
srch=$(echo "" | wofi --show dmenu) && mpv
https://www.youtube.com/watch?v=$(curl -G
https://www.googleapis.com/youtube/v3/search?part=snippet\&type=video\&maxResults=30\&key=YOUR_YOUTUBE_API_KEY
\
--data-urlencode "q=$srch" \
| jq -r '.items[] | ([.id.videoId,.snippet.title] | join(":"))' \
| wofi --show dmenu \
| cut -d: -f1 -)
```

Well an API KEY still needed which is a bummer
