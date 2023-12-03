app "hello"
    packages {
        pf: "https://github.com/roc-lang/basic-cli/releases/download/0.5.0/Cufzl36_SnJ4QbOoEmiJ5dIpUxBvdB3NEySvuH82Wio.tar.br",
        rand: "https://github.com/lukewilliamboswell/roc-random/releases/download/0.0.1/x_XwrgehcQI4KukXligrAkWTavqDAdE5jGamURpaX-M.tar.br",
    }
    imports [
        pf.Stdout,
        pf.Utc,
        pf.Task.{ Task },
        rand.Random,
    ]
    provides [main] to pf

defaultBallNumMin = 1
defaultBallNumMax = 15

generator = Random.int defaultBallNumMin defaultBallNumMax

getRandomBall = \x ->
    x
    |> Random.seed
    |> generator
    |> .value
    |> Num.toStr

utcToU32 = \utc ->
    utc
    |> Utc.toMillisSinceEpoch
    |> Num.toU32

main =
    n <- Utc.now
        |> Task.map utcToU32
        |> Task.await
    x1 = n |> getRandomBall

    n2 <- Utc.now
        |> Task.map utcToU32
        |> Task.await
    x2 = n2 |> getRandomBall

    n3 <- Utc.now
        |> Task.map utcToU32
        |> Task.await
    x3 = n3 |> getRandomBall

    [x1, x2, x3]
    |> Str.joinWith "\n"
    |> Stdout.line
