[![Actions Status](https://github.com/Raku-MUGS/MUGS-UI-WebSimple/workflows/test/badge.svg)](https://github.com/Raku-MUGS/MUGS-UI-WebSimple/actions)

NAME
====

MUGS-UI-WebSimple - WebSimple UI for MUGS, including HTTP gateway and game UIs

SYNOPSIS
========

    # Set up a full-stack MUGS-UI-WebSimple development environment
    mkdir MUGS
    cd MUGS
    git clone git@github.com:Raku-MUGS/MUGS-Core.git
    git clone git@github.com:Raku-MUGS/MUGS-Games.git
    git clone git@github.com:Raku-MUGS/MUGS-UI-WebSimple.git

    cd MUGS-Core
    zef install --exclude="pq:ver<5>:from<native>" .
    mugs-admin create-universe

    cd ../MUGS-Games
    zef install .

    cd ../MUGS-UI-WebSimple
    zef install --deps-only .  # Or skip --deps-only if you prefer


    ### GAME SERVER (handles actual gameplay; used by the web UI gateway)

    # Start a TLS WebSocket game server on localhost:10000 using fake certs
    mugs-ws-server

    # Specify a different MUGS identity universe (defaults to "default")
    mugs-ws-server --universe=other-universe

    # Start a TLS WebSocket game server on different host:port
    mugs-ws-server --host=<hostname> --port=<portnumber>

    # Start a TLS WebSocket game server using custom certs
    mugs-ws-server --private-key-file=<path> --certificate-file=<path>

    # Write a Log::Timeline JSON log for the WebSocket server
    LOG_TIMELINE_JSON_LINES=log/mugs-ws-server mugs-ws-server


    ### WEB UI GATEWAY (frontend for a MUGS backend game server)

    # Start a web UI gateway on localhost:20000 to play games in a web browser
    mugs-web-simple --server-host=<websocket-host> --server-port=<websocket-port>
    mugs-web-simple --server=<websocket-host>:<websocket-port>

    # Start a web UI gateway on a different host:port
    mugs-web-simple --host=<hostname> --port=<portnumber>

    # Use a different CA to authenticate the WebSocket server's certificates
    mugs-web-simple --server-ca-file=<path>

    # Use custom certs for the web UI gateway itself
    mugs-web-simple --private-key-file=<path> --certificate-file=<path>

    # Turn off TLS to the web browser (serving only unencrypted HTTP)
    mugs-web-simple --/secure

DESCRIPTION
===========

**NOTE: See the [top-level MUGS repo](https://github.com/Raku-MUGS/MUGS) for more info.**

MUGS::UI::WebSimple is a Cro-based web gateway for MUGS, including templates and UI plugins to play games from [MUGS-Core](https://github.com/Raku-MUGS/MUGS-Core) and [MUGS-Games](https://github.com/Raku-MUGS/MUGS-Games) via a web browser. The WebSimple UI focuses on low-bandwidth, resource-friendly HTML.

This Proof-of-Concept release only contains very simple turn-based games, plus a simple front door for creating identities and choosing games to play. Future releases will include many more games and genres, plus better handling of asynchronous events such as inter-player messaging.

GOTCHAS
=======

In this early release, there are a couple rough edges (aside from the very simple UI and trivial game selection):

  * Templates only work in checkout dir; must run mugs-web-simple from checkout root

  * Each mugs-web-simple instance can only serve *either* HTTP or HTTPS (not both at once)

  * Session cookies do not have a SameSite setting; some browsers will complain if not using HTTPS

ROADMAP
=======

MUGS is still in its infancy, at the beginning of a long and hopefully very enjoyable journey. There is a [draft roadmap for the first few major releases](https://github.com/Raku-MUGS/MUGS/tree/main/docs/todo/release-roadmap.md) but I don't plan to do it all myself -- I'm looking for contributions of all sorts to help make it a reality.

CONTRIBUTING
============

Please do! :-)

In all seriousness, check out [the CONTRIBUTING doc](docs/CONTRIBUTING.md) (identical in each repo) for details on how to contribute, as well as [the Coding Standards doc](https://github.com/Raku-MUGS/MUGS/tree/main/docs/design/coding-standards.md) for guidelines/standards/rules that apply to code contributions in particular.

The MUGS project has a matching GitHub org, [Raku-MUGS](https://github.com/Raku-MUGS), where you will find all related repositories and issue trackers, as well as formal meta-discussion.

More informal discussion can be found on IRC in [Libera.Chat #mugs](ircs://irc.libera.chat:6697/mugs).

AUTHOR
======

Geoffrey Broadwell <gjb@sonic.net> (japhb on GitHub and Libera.Chat)

COPYRIGHT AND LICENSE
=====================

Copyright 2021 Geoffrey Broadwell

MUGS is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

