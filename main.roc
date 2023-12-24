app "poolnums"
    packages {
        # pf: "../basic-webserver/platform/main.roc",
        pf: "https://github.com/roc-lang/basic-webserver/releases/download/0.1/dCL3KsovvV-8A5D_W_0X_abynkcRcoAngsgF0xtvQsk.tar.br",
        rand: "https://github.com/lukewilliamboswell/roc-random/releases/download/0.0.1/x_XwrgehcQI4KukXligrAkWTavqDAdE5jGamURpaX-M.tar.br",
    }
    imports [
        pf.Utc,
        pf.Http, # Unused but needed?
        pf.Url,
        pf.Task.{ Task },
        rand.Random,
    ]
    provides [main] to pf

defaultTargetCount = 3

allBalls = [
    { number: 1, color: "yellow" },
    { number: 2, color: "blue" },
    { number: 3, color: "red" },
    { number: 4, color: "purple" },
    { number: 5, color: "orange" },
    { number: 6, color: "green" },
    { number: 7, color: "brown" },
    { number: 8, color: "black" },
    { number: 9, color: "yellow" },
    { number: 10, color: "blue" },
    { number: 11, color: "red" },
    { number: 12, color: "purple" },
    { number: 13, color: "orange" },
    { number: 14, color: "green" },
    { number: 15, color: "brown" },
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
            List.len remaining
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
    ballDivs =
        ballNumbers
        |> List.map renderBall
        |> Str.joinWith ""

    """
    <html>
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
      </head>
      <body style="
        background: #292929;
        font-size: 20vh;
      ">
        \(ballDivs)
      </body>
    </html>
    """
    |> Str.toUtf8

renderBall = \ballNumber ->
    s = Num.toStr ballNumber

    color =
        allBalls
        |> List.findFirst \x -> x.number == ballNumber
        |> Result.map \x -> x.color
        |> Result.withDefault "X"

    """
    <div style="color: \(color);">
      (\(s))
    </div>
    """
