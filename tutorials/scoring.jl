### A Pluto.jl notebook ###
# v0.18.1

using Markdown
using InteractiveUtils

# ╔═╡ 49a44e94-29c0-4004-8d0b-e37008eafc1c
using BenchmarkTools, PlutoUI,  Wordlegames

# ╔═╡ 4eabf46e-f75c-4b15-8583-6abe17c0fd85
md"""
# Scoring guesses in Wordle

[Wordle](https://en.wikipedia.org/wiki/Wordle) is a recently developed, extremely popular word game that has already spawned many imitators such as [Primel](https://converged.yt/primel/).

These tutorials illustrate some [Julia](https://julialang.org) programming concepts using functions in the [Wordlegames](https://github.com/dmbates/Wordlegames.jl) package for illustration.
Part of the purpose is to illustrate the unique nature of Julia as a dynamically-typed language with a just-in-time (JIT) compiler.
It allows you to write "generic", both in the common meaning of "general purpose" and in the technical meaning of generic functions, and performative code.

This posting originated from a conversation on the Julia [discourse channel](https://discourse.julialang.org/t/rust-julia-comparison-post/75403) referring to a case where Julia code to perform a certain Wordle-related task - determine the "best" initial guess in a Wordle game - was horribly slow.
Julia code described in a [Hacker News](https://news.ycombinator.com/) posting took several hours to do this.

In situations like this the Julia community inevitably responds with suggested modifications to make the code run faster.
Someone joked that we wouldn't be satisfied until we could do that task in less than 1 second, and we did.

The code in this posting can be used to solve a Wordle game very rapidly, as well as related games like Primel.

> **WARNING** The code in this notebook has the potential to make playing Wordle quite boring. If you are enjoying playing Wordle you may want to stop reading now.

Before beginning we attach several packages that we will use in this notebook.
"""

# ╔═╡ 03b41118-5756-447b-9900-15af37667529
md"""
## Target pools

If you are not familiar with the rules of Wordle, please check the [Wikipedia page](https://en.wikipedia.org/wiki/Wordle).
It is a word game with the objective of guessing a 5-letter English word, which we will call the "target".
The target word is changed every day but it is always chosen from a set of 2315 words, which we will call the "target pool".

The original target pool is available with the `Wordlegames` package.  (Apparently the New York Times removed a few of these words after they purchased the rights to Wordle.)
"""

# ╔═╡ 73e3e38b-0935-4ef9-97b1-8a8cdfa2feb7
datadir = joinpath(dirname(dirname(pathof(Wordlegames))), "data");

# ╔═╡ 4c5e781c-fd10-425f-95d2-1fec5bf1015f
wordlestrings = collect(readlines(joinpath(datadir, "Wordletargets.txt")))

# ╔═╡ 2046a4ca-c4d3-4804-9373-930d9cbb58fd
md"We call this pool `wordlestrings` because it is stored as a vector of `String`s"

# ╔═╡ 560ad4d4-945c-4d21-8947-cac68c1880a1
typeof(wordlestrings)

# ╔═╡ ddd7f90c-7cad-4279-a275-b1800b4ae83b
md"""
The `Wordlegames` package defines a `GamePool` struct for playing Wordle or related games.
In that `struct` the `String`s are converted to a more efficient storage mode as a vector of `NTuple{5,Char}`, which takes advantage of the fact that each string is exactly 5 characters long.

Speaking of which, it would be a good idea to check that this collection has the properties we were told it had.
It should be a vector of 2315 strings, each of which is 5 characters.
"""

# ╔═╡ 49500976-7ab8-43cc-9902-b25ad73ff42e
length(wordlestrings)

# ╔═╡ f6681018-f729-48de-9342-a5bcb151aca2
all(w -> length(w) == 5, wordlestrings)

# ╔═╡ 22f7e1ad-3a2b-4a88-8f81-91feada88621
md"""
That last expression may look, well, "interesting".
It is a way of checking that a function, in this case an anonymous function expressed using the "stabby lambda" syntax, returns `true` for each element of an iterator, in this case the vector `wordlestrings`.
You can read the whole expression as "is `length(w)` equal to `5` for each word `w` in `wordlestrings`".

These words are supposed to be exactly 5 letters long but it never hurts to check.
I've been a data scientist for several decades and one of the first lessons in the field is to [trust, but verify](https://en.wikipedia.org/wiki/Trust%2C_but_verify) any claims about the data you are provided.

It turns out this check is redundant because the property is checked when creating a `GamePool`.
"""

# ╔═╡ 5787eef2-7a2c-46ad-8fa0-7313c07be84b
wordle = GamePool(wordlestrings);

# ╔═╡ 8df0e0c0-cdae-450c-abc1-5cea1d520ec9
propertynames(wordle)

# ╔═╡ 8580bdcf-24ce-4eb6-ac5a-4c77b729b38b
typeof(wordle.guesspool)

# ╔═╡ 9ed9e8ab-3ebc-4c6e-b2c3-46ad1987561e
first(wordle.guesspool, 3)

# ╔═╡ fdd6631e-8b3a-4b4f-b8a7-11135f13cc23
md"""
## Game play

A Wordle game is a dialog between the player and an "oracle", which, for the official game, is the web site.
The player submits a question to the oracle and the oracle responds, using information to which the player does not have access.
In this case the information is the target word.
The question is the player's guess - a 5-letter word - and the response is a score for that word.
The score indicates, for each character, whether it matches the character in the same position in the target or it is in the target in another position or it is not in the target at all.

Using the sample game for Wordle #196 from the Wikipedia page for illustration
"""

# ╔═╡ 9b911b3c-17d5-42d5-b7e5-a4187ce5787c
PlutoUI.Resource("https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Wordle_196_example.svg/440px-Wordle_196_example.svg.png")

# ╔═╡ 4d5681f9-56a5-4f83-9b31-810bdef26d98
md"""
The target is "rebus".

The player's first guess is "arise" and the response, or score, from the oracle is coded as 🟫🟨🟫🟨🟨 where 🟫 indicates that the letter is not in the target (neither `a` nor `i` occur in "rebus") and 🟨 indicates that the letter is in the target but not at that position.
(I'm using 🟫 instead of a gray square because I can't find a gray square Unicode character.)

The second guess is "route" for which the response is 🟩🟫🟨🟫🟨 indicating that the first letter in the guess occurs as the first letter in the target.

Of course, the colors are just one way of summarizing the response to a guess.
Within a computer program it is easier to use an integer to represent each of the 243 = 3⁵ possible scores.
An obvious way of mapping the result to an integer in the (decimal) range 0:242 is by mapping the response for each character to 2 (in target at that position), 1 (in target not at that position), or 0 (not in target) and regarding the pattern as a base-3 number.

In this coding the response for the first guess, "arise", is 01011 in base-3 or 31 in decimal.
The response for the second guess, "route", is 20101 in base-3 or 172 in decimal.

A function to evaluate this score can be written as
"""

# ╔═╡ db787d98-d2a4-4d4a-8e13-8b61e80e48dd
function score(guess, target)
	s = 0
	for (g, t) in zip(guess, target)
		s *= 3
		s += (g == t ? 2 : (g ∈ target))
	end
	return s
end

# ╔═╡ e9e23c37-e4d8-4b77-ab6f-264bcba4ebec
md"""
These numeric scores are not on a scale where "smaller is better" or "larger is better".
(It happens that the best score is 242, corresponding to a perfect match, or five green tiles, but that's incidental.)

The score is just a way of representing each of the 243 patterns that can be produced.

We can convert back to colored squares if desired using the `tiles` function from the `Wordlegames` package, defined as 
```jl
function tiles(sc, ntiles)
    result = Char[]       # initialize to an empty array of Char
    for _ in 1:ntiles     # _ indicates the value of the iterator is not used
        sc, r = divrem(sc, 3)
        push!(result, iszero(r) ? '🟫' : (isone(r) ? '🟨' : '🟩'))
    end
    return String(reverse(result))
end
```

## Examining the `score` function

In the Sherlock Holmes story [The Adventure of Silver Blaze](thttps://en.wikipedia.org/wiki/The_Adventure_of_Silver_Blaze) there is a famous exchange where Holmes remarks on "the curious incident of the dog in the night-time" (see the link).
The critical clue in the case is not what happened but what didn't happen - the dog didn't bark.

Just as Holmes found it interesting that the dog didn't bark, we should find the functions in this notebook interesting for what they don't include.
For the most part the arguments aren't given explicit types.

Knowing the concrete types of arguments is very important when compiling functions, as is done in Julia, but these functions are written without explicit types.

Consider the `score` function which we reproduce here

```jl
function score(guess, target)
    s = 0
    for (g, t) in zip(guess, target)
        s *= 3
        s += (g == t ? 2 : (g ∈ target))
    end
    return s
end
```

The arguments to `score` can be any type.
In fact, formally they are of an abstract type called `Any`.

So how do we make sure that the actual arguments make sense for this function?
Well, the first thing that is done with the arguments is to pass them to `zip(guess, target)` to produce pairs of values, `g` and `t`, that can be compared for equality, `g == t`.
In a sense `score` delegates the task of checking that the arguments are sensible to the `zip` function.

For those unfamiliar with zipping two or more iterators, we can check what the result is.
"""

# ╔═╡ 8a1cc31b-f747-49b4-9860-a2c381d98c44
collect(zip("arise", "rebus"))

# ╔═╡ 6830dbd6-edc9-4193-8d73-becf3be3855a
md"""
One of the great advantages of dynamically-typed languages with a REPL (read-eval-print-loop) like Julia is that we can easily check what `zip` produces in a couple of examples (or even read the documentation returned by `?zip`, if we are desperate).

The rest of the function is a common pattern - initialize `s`, which will be the result, modify `s` in a loop, and return it.
The Julia expression
```jl
s *= 3
```
indicates, as in several other languages, that `s` is to be multiplied by 3 in-place.

An expression like
```jl
g == t ? 2 : (g  ∈ target)
```
is a *ternary operator* expression (the name comes from the operator taking three arguments).
It evaluates the condition, `g == t`, and returns `2` if the condition is `true`.
If the `g == t` is `false` the operator returns the value of the Boolean expression `g  ∈ target`, converted to an `Int`.
The Boolean expression will return `false` or `true`, which become `0` or `1` when converted to an `Int`.
This is one of the few times that we explicitly convert a result to a particular type.
We do so because `2` is an `Int` and we don't want the type of the value of the ternary operator expression to change depending on the value of its arguments.

The operation of multiplying by 3 and adding 2 or 1 or 0 is an implementation of [Horner's method](https://en.wikipedia.org/wiki/Horner%27s_method) for evaluating a polynomial.

The function is remarkable because it is both general and compact.
Even more remarkable is that it will be very, very fast after its first usage triggers compilation.
That's important because this function will be in a "hot loop".
It will be called many, many times when evaluating the next guess.

(Unfortunately, this version doesn't properly account for cases where a character is repeated in the guess - an example of Kernighan and Plauger's aphorism, "Efficiency often means getting the wrong answer quickly." from their book [The Elements of Programming Style](https://en.wikipedia.org/wiki/The_Elements_of_Programming_Style).
We will return to this issue later.)

We won't go into detail about the Julia compiler except to note that compilation is performed for specific *method signatures* not for general method definitions.

There are several functions and macros in Julia that allow for inspection at different stages of compilation.
One of the most useful is the macro `@code_warntype` which is used to check for situations where type inference has not been successful.
Applying it as
```jl
@code_warntype score("arise", "rebus")
```
will show the type inference is based on concrete types (`String`) for the arguments.

Some argument types are handled more efficiently than others.
Without going in to details we note that we can take advantage of the fact that we have exactly 5 characters and convert the elements of `words` from `String` to `NTuple{5,Char}`, which is an ordered, fixed-length homogeneous collection.

Using the `@benchmark` macro from the `BenchmarkTools` package gives run times of a few tens of nanoseconds for these arguments, and shows that the function applied to the fixed-length collections is faster.
"""

# ╔═╡ a69f62bd-ed6d-42e7-8405-9321d13a52d1
@benchmark score(guess, target) setup = (guess = "arise"; target = "rebus")

# ╔═╡ e4410d39-6680-4eac-9f70-a425df352998
md"""
New methods can be defined for a generic function like `score`.
Typically the reason for this is if, for example, the method can more effectively use information from the type.

For example, the `NTuple{N,Char}` type has exactly `N` characters - information that can be used in a loop where we can turn off bounds checking.
"""

# ╔═╡ a031c3db-6630-4deb-a90d-d2b13202dec6
function score(guess::NTuple{N,Char}, target::NTuple{N,Char}) where {N}
	s = 0
	@inbounds for i in 1:N
		s *= 3
		gi = guess[i]
		s += (gi == target[i] ? 2 : (gi ∈ target))
	end
	return s
end

# ╔═╡ 9e1d6017-f79e-49b5-916e-8e3a9e49ab1d
score("arise", "rebus")

# ╔═╡ 1b9261b3-c90c-4db1-9e70-51bf364072b8
md"""
This method returns the same result as the other method, only faster.
"""

# ╔═╡ 1887c091-46a0-4e8c-9a66-2ab17968729c
score(('a','r','i','s','e'), ('r','e','b','u','s'))

# ╔═╡ 39202f1a-e7d6-4961-9776-ec67c3fd9743
@benchmark score(guess, target) setup=(
	guess = ('a','r','i','s','e');
	target = ('r','e','b','u','s'),
)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Wordlegames = "1cb69566-e1cf-455f-a587-fd79a2e00f5a"

[compat]
BenchmarkTools = "~1.3.1"
PlutoUI = "~0.7.35"
Wordlegames = "~0.2.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0-beta1"
manifest_format = "2.0"
project_hash = "045a6e2c86e27f8d763b85c40450eb9e85eed07e"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.AbstractTrees]]
git-tree-sha1 = "03e0550477d86222521d254b741d470ba17ea0b5"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.3.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "4c10eee4af024676200bc7752e536f858c6b8f93"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.3.1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "44c37b4636bc54afac5c574d2d02b625349d6582"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.41.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.0+0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "Future", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrettyTables", "Printf", "REPL", "Reexport", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "ae02104e835f219b8930c7664b8012c93475c340"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.3.2"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.81.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.17+2"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "13468f237353112a01b2d6b32f3d0f80219944aa"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.2.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "85bf3e4bd279e405f91489ce518dedb1e32119cb"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.35"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "db3a23166af8aebf4db5ef87ac5b00d36eb771e2"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.0"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "bb1064c9a84c52e277f1096cf41434b675cd368b"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.6.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Wordlegames]]
deps = ["AbstractTrees", "DataFrames", "Random", "Tables"]
git-tree-sha1 = "2da18538a6107ec5ee5ac09a21da031c61582bb4"
uuid = "1cb69566-e1cf-455f-a587-fd79a2e00f5a"
version = "0.2.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.0.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.41.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "16.2.1+1"
"""

# ╔═╡ Cell order:
# ╟─4eabf46e-f75c-4b15-8583-6abe17c0fd85
# ╠═49a44e94-29c0-4004-8d0b-e37008eafc1c
# ╟─03b41118-5756-447b-9900-15af37667529
# ╠═73e3e38b-0935-4ef9-97b1-8a8cdfa2feb7
# ╠═4c5e781c-fd10-425f-95d2-1fec5bf1015f
# ╟─2046a4ca-c4d3-4804-9373-930d9cbb58fd
# ╠═560ad4d4-945c-4d21-8947-cac68c1880a1
# ╟─ddd7f90c-7cad-4279-a275-b1800b4ae83b
# ╠═49500976-7ab8-43cc-9902-b25ad73ff42e
# ╠═f6681018-f729-48de-9342-a5bcb151aca2
# ╟─22f7e1ad-3a2b-4a88-8f81-91feada88621
# ╠═5787eef2-7a2c-46ad-8fa0-7313c07be84b
# ╠═8df0e0c0-cdae-450c-abc1-5cea1d520ec9
# ╠═8580bdcf-24ce-4eb6-ac5a-4c77b729b38b
# ╠═9ed9e8ab-3ebc-4c6e-b2c3-46ad1987561e
# ╟─fdd6631e-8b3a-4b4f-b8a7-11135f13cc23
# ╟─9b911b3c-17d5-42d5-b7e5-a4187ce5787c
# ╟─4d5681f9-56a5-4f83-9b31-810bdef26d98
# ╠═db787d98-d2a4-4d4a-8e13-8b61e80e48dd
# ╠═9e1d6017-f79e-49b5-916e-8e3a9e49ab1d
# ╟─e9e23c37-e4d8-4b77-ab6f-264bcba4ebec
# ╠═8a1cc31b-f747-49b4-9860-a2c381d98c44
# ╟─6830dbd6-edc9-4193-8d73-becf3be3855a
# ╠═a69f62bd-ed6d-42e7-8405-9321d13a52d1
# ╟─e4410d39-6680-4eac-9f70-a425df352998
# ╠═a031c3db-6630-4deb-a90d-d2b13202dec6
# ╟─1b9261b3-c90c-4db1-9e70-51bf364072b8
# ╠═1887c091-46a0-4e8c-9a66-2ab17968729c
# ╠═39202f1a-e7d6-4961-9776-ec67c3fd9743
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
