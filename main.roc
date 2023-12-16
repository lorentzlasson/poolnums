app "hello"
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

defaultBallCount = 3
defaultBallNumMin = 1
defaultBallNumMax = 15

main =
    ballCount <- getBallCountFromArgs |> Task.await
    seed <- getSeed |> Task.await

    ballCount
    |> getBallNumbers seed
    |> Stdout.line

getBallCountFromArgs =
    Arg.list
    |> Task.map getBallCount

getBallCount = \args ->
    args
    |> List.get 1
    |> Result.try Str.toU32
    |> Result.withDefault defaultBallCount

getSeed =
    Utc.now
    |> Task.map Utc.toMillisSinceEpoch
    |> Task.map Num.toU32

getRandomBall = \num ->
    num
    |> Random.seed
    |> generator
    |> .value
    |> Num.toStr

generator =
    defaultBallNumMin
    |> Random.int defaultBallNumMax

getBallNumbers = \ballCount, seed ->
    List.range { start: At 0, end: Before ballCount }
    |> List.map \i -> getRandomBall (seed + i)
    |> Str.joinWith "\n"

