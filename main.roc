app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.16.0/42jC1JT3auhHSmv2Ah8mW5F2MXiAakq1UQQ4NQceQjXw.tar.zst",
	http: "https://github.com/roc-lang/http/releases/download/1.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
	rand: "https://github.com/kili-ilo/roc-random/releases/download/0.9.2/2ZXLX8WRqrosGu1V3VL5aXqgtfTRvJmjFPx8a26ecVmc.tar.zst",
	roc: "nightly-2026-09-29-7f11a82",
}

import pf.Env
import pf.Server
import pf.UnixTime
import pf.Html
import pf.Attribute
import http.Response
import rand.Random

Context : {}

program = { init!, respond!, shutdown! }

default_target_count : U64
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

init! : () => Try({ config : Server.Config, context : Context }, [Exit(I64)])
init! = || {
	host =
		match Env.var_str!("HOST") {
			Ok(value) => value
			_ => "127.0.0.1"
		}
	port =
		match Env.var_str!("PORT") {
			Ok(value) => U16.from_str(value) ? |_| Exit(1)
			_ => 8000
		}
	Ok({ config: Server.default_config.with_listen({ host, port }), context: {} })
}

respond! : Server.Request, Context => Try(Server.Outcome, [ServerErr(Str)])
respond! = |request, _context|
	match (request.method(), request.target()) {
		(GET, Resource({ raw_path: "/", raw_query, .. })) => Ok(Server.respond(generate_pool_balls!(raw_query)))
		_ => Ok(Server.respond(Response.from_status(404)))
	}

shutdown! : Server.ShutdownReason, Context => Try({}, [Exit(I64)])
shutdown! = |_reason, _context| Ok({})

generate_pool_balls! = |raw_query| {
	seed = Random.seed(UnixTime.now!().subsecond_nanoseconds())

	remaining = remove_random_from_list(seed, all_balls, get_target_count(raw_query))
	selection = get_selected(remaining, all_balls)

	response(selection)
}

get_target_count = |raw_query|
	match raw_query {
		Present(query) =>
			match query.split_on("&").find_first(|param| param.starts_with("balls=")) {
				Ok(param) => U64.from_str(param.drop_prefix("balls=")).ok_or(default_target_count)
				Err(NotFound) => default_target_count
			}
		Absent => default_target_count
	}

remove_random_from_list = |state, remaining, target_count| {
	remaining_count = remaining.len()
	selected_count = all_balls.len() - remaining_count

	target_reached = selected_count == target_count
	out_of_balls = remaining_count == 0

	if target_reached or out_of_balls {
		remaining
	} else {
		generation = Random.step(state, Random.bounded_u32(0, remaining_count.to_u32_wrap() - 1))

		match remaining.get(generation.value.to_u64()) {
			Ok(ball) => {
				new_remaining = remaining.drop_if(|x| x == ball)

				remove_random_from_list(generation.state, new_remaining, target_count)
			}
			Err(_) => {
				crash "should never happen - out_of_balls guards"
			}
		}
	}
}

get_selected = |remaining, original|
	original.drop_if(|x| remaining.contains(x))

response = |balls|
	Response.from_status(200)
		.with_headers([{ name: "Content-Type", value: "text/html; charset=utf-8" }])
		.with_body(get_response_body(balls))

get_response_body = |balls| {
	ball_imgs = balls.map(render_ball)
	controls = render_controls(balls.len())

	style =
		\\background: #117f38;
		\\display: flex;
		\\flex-direction: column;
		\\align-items: center;

	Str.to_utf8(Html.render(Html.html([], [Html.body([Attribute.style(style)], controls.concat(ball_imgs))])))
}

render_controls = |count| {
	decrement = if count > 1 {
		Link(count - 1)
	} else {
		Disabled
	}
	increment = if count < all_balls.len() {
		Link(count + 1)
	} else {
		Disabled
	}

	[render_control("−", "left: 0;", decrement), render_control("+", "right: 0;", increment)]
}

render_control = |label, corner, target| {
	style =
		\\position: fixed;
		\\top: 0;
		\\padding: 8px 32px;
		\\font: bold 96px/1 sans-serif;
		\\color: white;
		\\text-decoration: none;

	match target {
		Link(count) => Html.a([Attribute.href("?balls=${count.to_str()}"), Attribute.style("${style}${corner}")], [Html.text(label)])
		Disabled => Html.span([Attribute.style("${style}${corner}opacity: 0.3;")], [Html.text(label)])
	}
}

render_ball = |ball| {
	style =
		\\max-height: 25vh;
		\\padding: 10px;

	Html.void_element("img", [Attribute.src(ball.image), Attribute.style(style)])
}
