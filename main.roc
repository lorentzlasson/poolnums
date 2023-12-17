app "poolnums"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.7.0/bkGby8jb0tmZYsy2hg1E_B2QrCgcSTxdUlHtETwm5m4.tar.br",
        rand: "https://github.com/lukewilliamboswell/roc-random/releases/download/0.0.1/x_XwrgehcQI4KukXligrAkWTavqDAdE5jGamURpaX-M.tar.br",
    }
    imports [
        pf.Stdout,
        pf.Utc,
        pf.Arg,
        pf.Task.{ Task },
        rand.Random,
    ]
    provides [main] to pf

defaultTargetCount = 3

ballNumbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]

main =
    targetCount <- getTargetCountFromArgs |> Task.await
    time <- getSeed |> Task.await

    state = time |> Random.seed

    targetCount
    |> selectRandomFromList ballNumbers [] state
    |> format
    |> Stdout.line

getTargetCountFromArgs =
    Arg.list
    |> Task.map getTargetCount

getTargetCount = \args ->
    args
    |> List.get 1
    |> Result.try Str.toU32
    |> Result.withDefault defaultTargetCount

getSeed =
    Utc.now
    |> Task.map Utc.toMillisSinceEpoch
    |> Task.map Num.toU32

selectRandomFromList = \targetCount, available, selected, state ->
    if List.len selected == Num.toNat targetCount then
        selected
    else
        availableCount =
            available
            |> List.len
            |> Num.toI32

        # TODO: why always 7 as first number if generator 1 to 16?
        # generator = Random.int 0 (availableCount)
        generator = Random.int 0 (availableCount - 1)

        generation = state |> generator

        index = Num.toNat generation.value

        ball =
            available
            |> List.get index
            |> Result.withDefault -999

        selected2 = selected |> List.append ball
        available2 = available |> List.dropIf (\x -> x == ball)
        state2 = generation.state

        targetCount |> selectRandomFromList available2 selected2 state2

format = \list ->
    list
    |> List.map \y -> Num.toStr y
    |> Str.joinWith "\n"
