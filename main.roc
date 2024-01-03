app "poolnums"
    packages {
        # pf: "../basic-webserver/platform/main.roc",
        pf: "https://github.com/roc-lang/basic-webserver/releases/download/0.1/dCL3KsovvV-8A5D_W_0X_abynkcRcoAngsgF0xtvQsk.tar.br",
        rand: "https://github.com/lukewilliamboswell/roc-random/releases/download/0.0.1/x_XwrgehcQI4KukXligrAkWTavqDAdE5jGamURpaX-M.tar.br",
        html: "https://github.com/Hasnep/roc-html/releases/download/v0.2.0/5fqQTpMYIZkigkDa2rfTc92wt-P_lsa76JVXb8Qb3ms.tar.br",
    }
    imports [
        pf.Utc,
        pf.Http, # Unused but needed?
        pf.Url,
        pf.Task.{ Task },
        rand.Random,
        html.Html,
        html.Attribute,
    ]
    provides [main] to pf

defaultTargetCount = 3

allBalls = [
    { number: 1, image: "https://static.vecteezy.com/system/resources/previews/009/305/112/large_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    { number: 2, image: "https://static.vecteezy.com/system/resources/previews/009/391/424/non_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    { number: 3, image: "https://static.vecteezy.com/system/resources/previews/009/380/190/non_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    { number: 4, image: "https://static.vecteezy.com/system/resources/previews/009/383/768/non_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    { number: 5, image: "https://static.vecteezy.com/system/resources/previews/009/380/189/non_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    { number: 6, image: "https://static.vecteezy.com/system/resources/previews/009/380/385/non_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    { number: 7, image: "https://static.vecteezy.com/system/resources/previews/009/398/873/large_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    { number: 8, image: "https://static.vecteezy.com/system/resources/previews/009/384/622/non_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    { number: 9, image: "https://static.vecteezy.com/system/resources/previews/009/381/024/non_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    { number: 10, image: "https://static.vecteezy.com/system/resources/previews/009/385/468/non_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    { number: 11, image: "https://static.vecteezy.com/system/resources/previews/009/383/774/non_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    # TODO: number 12 is not in same style
    { number: 12, image: "https://static.vecteezy.com/system/resources/previews/021/080/770/large_2x/pool-ball-design-illustration-isolated-on-transparent-background-free-png.png" },
    { number: 13, image: "https://static.vecteezy.com/system/resources/previews/009/385/377/non_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    { number: 14, image: "https://static.vecteezy.com/system/resources/previews/009/391/555/non_2x/billiard-balls-clipart-design-illustration-free-png.png" },
    { number: 15, image: "https://static.vecteezy.com/system/resources/previews/009/398/161/large_2x/billiard-balls-clipart-design-illustration-free-png.png" },
]

allBallNumbers = List.map allBalls .number

main = \req ->
    time <- Task.await getSeed

    targetCount = getTargetCount req.url

    time
    |> Random.seed
    |> removeRandomFromList allBallNumbers targetCount
    |> getSelected allBallNumbers
    |> List.sortAsc
    |> respond

getSeed =
    Utc.now
    |> Task.map Utc.toMillisSinceEpoch
    |> Task.map Num.toU32

getTargetCount = \urlStr ->
    urlStr
    |> Url.fromStr
    |> Url.queryParams
    |> Dict.get "balls"
    |> Result.try Str.toU32
    |> Result.withDefault defaultTargetCount

removeRandomFromList = \state, remaining, targetCount ->
    remainingCount = List.len remaining
    selectedCount = List.len allBallNumbers - remainingCount

    targetReached = selectedCount == Num.toNat targetCount
    outOfBalls = remainingCount == 0

    if targetReached || outOfBalls then
        remaining
    else
        generator =
            remaining
            |> List.len
            |> Num.toI32
            |> Num.sub 1
            |> Random.int 0

        generation = generator state

        index =
            generation
            |> .value
            |> Num.toNat

        ballResult = List.get remaining index

        when ballResult is
            Ok ball ->
                newRemaining = List.dropIf remaining (\x -> x == ball)
                newState = generation.state

                removeRandomFromList
                    newState
                    newRemaining
                    targetCount

            Err _ ->
                crash "should never happen - outOfBalls guards"

getSelected = \remaining, original ->
    List.dropIf
        original
        (\x -> List.contains remaining x)

respond = \ballNumbers ->
    Task.ok {
        status: 200,
        headers: [
            {
                name: "Content-Type",
                value: Str.toUtf8 "text/html; charset=utf-8",
            },
        ],
        body: getResponseBody ballNumbers,
    }

getResponseBody = \ballNumbers ->
    ballDivs = List.map ballNumbers renderBall

    style =
        """
        background: #117f38;
        display: flex;
        flex-direction: column;
        align-items: center;
        """

    Html.html [] [
        Html.body [Attribute.style style] ballDivs,
    ]
    |> Html.render
    |> Str.toUtf8

renderBall = \ballNumber ->
    maybeImage =
        allBalls
        |> List.findFirst \x -> x.number == ballNumber
        |> Result.map \x -> x.image

    style =
        """
        max-height: 25vh;
        padding: 10px;
        """

    when maybeImage is
        Ok image ->
            Html.img
                [
                    Attribute.src image,
                    Attribute.style style,
                ]
                []

        Err _ ->
            crash "should never happen"

