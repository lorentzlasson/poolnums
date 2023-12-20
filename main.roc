app "poolnums"
    packages {
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

ballNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

main = \req ->
    time <- Task.await getSeed

    targetCount = getTargetCount req.url

    time
    |> Random.seed
    |> removeRandomFromList ballNumbers targetCount
    |> getSelected ballNumbers
    |> List.sortAsc
    |> format
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
    selectedCount = List.len ballNumbers - remainingCount

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

format = \list ->
    list
    |> List.map \x -> Num.toStr x
    |> Str.joinWith "\n"

respond = \body ->
    Task.ok {
        status: 200,
        headers: [
            {
                name: "Content-Type",
                value: Str.toUtf8 "text/html; charset=utf-8",
            },
        ],
        body: Str.toUtf8 body,
    }
