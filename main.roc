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

getRandomBall = \num ->
    num
    |> Random.seed
    |> generator
    |> .value
    |> Num.toStr

main =
    n <- Utc.now
        |> Task.map Utc.toMillisSinceEpoch
        |> Task.map Num.toU32
        |> Task.await

    List.range { start: At 0, end: Before 3 }
    |> List.map \i -> getRandomBall (n + i)
    |> Str.joinWith "\n"
    |> Stdout.line
