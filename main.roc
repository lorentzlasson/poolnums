app [Model, init!, respond!] {
    pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.13.1/7P4PF5rntQVkys5JbIHqkMpZIXo-pxa5lVqOdh7z8fE.tar.br",
    rand: "https://github.com/lukewilliamboswell/roc-random/releases/download/0.5.0/yDUoWipuyNeJ-euaij4w_ozQCWtxCsywj68H0PlJAdE.tar.br",
    html: "https://github.com/Hasnep/roc-html/releases/download/v0.8.0/GCTX3ckGRXs29XkLh0rhp0a6l0IrUe5RgAFj83hwN3Q.tar.br",
    pg: "https://github.com/agu-z/roc-pg/releases/download/0.1.1/PjwASOJalDKErbHkj3bXskhGbgqGzVSbki4Nv7xOEe0.tar.br",
}

import pf.Stderr
import pf.Utc
import pf.Url
import rand.Random
import html.Html
import html.Attribute
import pg.Pg.Client exposing [Client]
import pg.Pg.Cmd
import pg.Pg.Result

Model : { client : Client }

db_config = {
    host: "localhost",
    port: 5432,
    user: "postgres",
    auth: None,
    database: "postgres",
}

default_target_count = 3

all_balls = [
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

all_ball_numbers = List.map(all_balls, |ball| ball.number)

init! = |_|
    client = Pg.Client.connect!(db_config)?
    Ok({ client })

respond! = |request, model|
    url = Url.from_str(request.uri)

    when (request.method, url_segments(url)) is
        (GET, [""]) ->
            generate_pool_balls!(url, model.client)

        _ ->
            Ok({ status: 404, headers: [], body: [] })

url_segments = |url|
    url
    |> Url.path
    |> Str.split_on("/")
    |> List.drop_first(1)

generate_pool_balls! = |url, client|
    seed_value = Num.to_u32(Utc.to_millis_since_epoch(Utc.now!({})))

    target_count = get_target_count(url)

    selection =
        Random.seed(seed_value)
        |> remove_random_from_list(all_ball_numbers, Num.to_u64(target_count))
        |> get_selected(all_ball_numbers)
        |> List.sort_asc

    _ = store_selection!(selection, client)

    Ok(response(selection))

get_target_count = |url|
    url
    |> Url.query_params
    |> Dict.get("balls")
    |> Result.try(Str.to_u32)
    |> Result.with_default(default_target_count)

remove_random_from_list = |state, remaining, target_count|
    remaining_count = List.len(remaining)
    selected_count = List.len(all_ball_numbers) - remaining_count

    target_reached = selected_count == target_count
    out_of_balls = remaining_count == 0

    if target_reached or out_of_balls then
        remaining
    else
        upper = Num.to_u32(remaining_count) - 1
        generator = Random.bounded_u32(0, upper)
        generation = generator(state)
        index = generation.value

        when List.get(remaining, Num.to_u64(index)) is
            Ok(ball) ->
                new_remaining = List.drop_if(remaining, |x| x == ball)

                remove_random_from_list(generation.state, new_remaining, target_count)

            Err(_) ->
                crash("should never happen - out_of_balls guards")

get_selected = |remaining, original|
    List.drop_if(original, |x| List.contains(remaining, x))

store_selection! = |selection, client|
    result =
        when selection is
            [a, b, c] ->
                """
                insert into selection (a, b, c)
                values ($1, $2, $3)
                returning time
                """
                |> Pg.Cmd.new
                |> Pg.Cmd.bind([Pg.Cmd.u8(a), Pg.Cmd.u8(b), Pg.Cmd.u8(c)])
                |> Pg.Cmd.expect1(Pg.Result.str("time"))
                |> Pg.Client.command!(client)
                |> Result.map_ok(|_time| {})

            _ ->
                Ok({})

    when result is
        Ok(_) ->
            Ok({})

        Err(_) ->
            Stderr.line!("failed to store selection")

response = |ball_numbers| {
    status: 200,
    headers: [{ name: "Content-Type", value: "text/html; charset=utf-8" }],
    body: get_response_body(ball_numbers),
}

get_response_body = |ball_numbers|
    ball_imgs = List.map(ball_numbers, render_ball)

    style =
        """
        background: #117f38;
        display: flex;
        flex-direction: column;
        align-items: center;
        """

    Html.html([], [Html.body([Attribute.style(style)], ball_imgs)])
    |> Html.render
    |> Str.to_utf8

render_ball = |ball_number|
    maybe_image =
        all_balls
        |> List.find_first(|ball| ball.number == ball_number)
        |> Result.map_ok(|ball| ball.image)

    style =
        """
        max-height: 25vh;
        padding: 10px;
        """

    when maybe_image is
        Ok(image) ->
            Html.img([Attribute.src(image), Attribute.style(style)])

        Err(_) ->
            crash("should never happen")
