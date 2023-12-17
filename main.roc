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
    targetCount <- Task.await getTargetCountFromArgs
    time <- Task.await getSeed

    state = Random.seed time

    targetCount
    |> selectRandomFromList ballNumbers [] state
    |> format
    |> Stdout.line

getTargetCountFromArgs =
    Task.map Arg.list getTargetCount

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
    targetReached = List.len selected == Num.toNat targetCount
    availableCount = List.len available
    outOfBalls = availableCount == 0

    if targetReached || outOfBalls then
        selected
    else
        generator =
            availableCount
            |> Num.toI32
            |> Num.sub 1
            |> Random.int 0

        generation = state |> generator

        index =
            generation
            |> .value
            |> Num.toNat

        maybeBall = List.get available index

        when maybeBall is
            Ok ball ->
                newSelected = List.append selected ball
                newAvailable = List.dropIf available (\x -> x == ball)
                newState = generation.state

                selectRandomFromList
                    targetCount
                    newAvailable
                    newSelected
                    newState

            Err _ ->
                crash "should never happen - outOfBalls guards"

format = \list ->
    list
    |> List.map \x -> Num.toStr x
    |> Str.joinWith "\n"
