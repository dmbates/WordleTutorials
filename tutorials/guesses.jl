### A Pluto.jl notebook ###
# v0.18.1

using Markdown
using InteractiveUtils

# ╔═╡ e254cb71-9bb3-4cbc-80be-a8862f81fd9c
begin
    using CairoMakie      # graphics package
    using Chain           # sophisticated pipes
    using DataFrameMacros # convenient syntax for df operations
    using DataFrames
    using PlutoUI         # User Interface components
    using Primes          # prime numbers
    using Random          # random number generation
    using StatsBase       # basic statistical summaries
    using Wordlegames
end

# ╔═╡ b37908ca-9ef0-11ec-302b-6b280e5e08f5
# hideall
title = "Selection of guesses";

# ╔═╡ ea9f2405-b658-47c7-a8ac-540f379e9ac5
Base.Text.("""
           +++
           title = "$title"
           +++
           """)


# ╔═╡ 44913684-7099-401b-8dcd-e0e84c5c1384
md"""
# $title

The task described in the discourse discussion mentioned in the previous tutorial was to determine an optimal first guess in Wordle, using the criterion of minimizing the expected pool size after the guess is scored.

First attach the packages that will be used 
"""

# ╔═╡ a5d6acfe-77e2-4f14-a930-c1bdf6c0910c
md"""
In the Wordle game shown on the [Wikipedia page](https://en.wikipedia.org/wiki/Wordle) the first guess is "arise".
"""

# ╔═╡ 590847ab-ce78-4bb3-b15e-6d72d76e3fed
PlutoUI.Resource(
    "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Wordle_196_example.svg/440px-Wordle_196_example.svg.png",
)

# ╔═╡ 0e122051-0488-47e0-81ef-d8b3d1f973ef
md"""
Before the guess is scored the size of the target pool is 2315.
The score for this guess in this game is 01011 as a base-3 number or 31 as a decimal number.
Of all the targets in the target pool, only 20 will return this score.

To verify this, first create a `GamePool` from the wordle targets.
"""

# ╔═╡ b8e51a88-9fa0-476e-9e87-5d5e137a9720
begin
    datadir = joinpath(pkgdir(Wordlegames), "data")
    wordle = GamePool(collect(readlines(joinpath(datadir, "Wordletargets.txt"))))
end;

# ╔═╡ 40100de5-4543-47ad-a0bf-7d69630b15d0
md"""
Then determine the index of "arise" in the guess pool.
"""

# ╔═╡ 9e9ebaa5-47f4-4c44-ab59-ef2940555756
only(findall(x -> x == ('a', 'r', 'i', 's', 'e'), wordle.guesspool))

# ╔═╡ c9270bda-e8fa-44af-8863-5b245a352f48
md"""
Here, `findall` returns a vector of all positions in `wordle.guesspool` that return `true` from the anonymous function checking if the argument, `x`, is equal to `('a', 'r', 'i', 's', 'e')`.
The `only` function checks that there is only one such index and, if so, returns it.

The anonymous function to compare an element of `wordle.guesspool` to `('a','r','i','s','e')` can be written more compactly as `==(('a','r','i','s','e'))`.

The score for the guess `"arise"` on the target `"rebus"` is 31 as a decimal number.
"""

# ╔═╡ 56692b81-b1b2-4449-8274-9faa55e8db50
Int(wordle.allscores[only(findall(==(('r', 'e', 'b', 'u', 's')), wordle.guesspool)), 106])

# ╔═╡ d3480b1c-a472-4cdf-9d48-46507a17623e
md"""
Next, check how many of the pre-computed scores in the 106th column of `wordle.allscores` are equal to 31.
"""

# ╔═╡ 42b52872-38dd-4976-88c8-600e55a33c6a
sum(==(31), view(wordle.allscores, :, 106))

# ╔═╡ ed459468-f112-494f-bec1-26ba72895db8
md"""
A `view` provides access to a subarray of an array without copying the contents.
In this case the subarray is all the rows (the `:` argument in the rows position) and the 106th column.
"""

# ╔═╡ 526fa04e-4367-4736-8e30-96602b195af1
md"""
## The distribution of scores for a guess

In this case the first guess reduced the size of the target pool from 2315 to 20, after it was scored.
Ideally we want a guess to reduce the size of the target pool as much as possible but we don't know what the score is going to be.
However, we can evaluate the distribution of pool sizes that will result from a particular guess.

To do this we "bin" the scores for a guess on the active targets into the 243 possible values for an `NTuple{5,Char}`.
"""

# ╔═╡ 752b02ae-54be-408e-b527-0158f7d29ec1
bincounts!(wordle, 106).counts

# ╔═╡ d2162f9f-8d62-4f4a-b15a-b6d6b30dfe54
md"""
The `i`'th element of this vector is the number of targets that will give a score of `i - 1` for `guess = wordle.guesspool[106]`, which is `"arise"`

The most common score is `0` which is returned for 168 of the 2315 targets currently in the target pool.
"""

# ╔═╡ 6ff04850-d985-4796-a715-c83975e49b00
sum(iszero, view(wordle.allscores, :, 106))

# ╔═╡ 8a9d7db2-4cb4-4791-8997-5971656ebb23
md"""
Collecting the bin sizes and the corresponding scores in a data frame allows us to sort them by decreasing count size and eliminate the scores that give counts of zero.
"""

# ╔═╡ 29995b22-b4da-4d77-b806-d3fbb01d3b01
df106 = @chain DataFrame(score=tiles.(0:242, 5), counts=wordle.counts) begin
    @subset(:counts > 0)
    sort(:counts; rev=true)
end

# ╔═╡ b2a2d324-9cfb-48a3-9429-873ec93b36e3
md"""
A bar plot of the bin sizes, ordered from largest to smallest is
"""

# ╔═╡ fb634eb5-4eb1-44d0-9cd7-c7266ebbb1ab
barplot(df106.counts)

# ╔═╡ c6c9637f-32e4-4c3c-ac67-04260546a0e1
md"""
The `Wordlegames` package provides two algorithms of choosing a guess based on the distribution of the scores.

```julia
function optimalguess(gp::GamePool{N,S,MaximizeEntropy}) where {N,S}
    gind, xpctd, entrpy = 0, Inf, -Inf
    for (k, a) in enumerate(gp.active)
        if a
            thisentropy = entropy2(bincounts!(gp, k))
            if thisentropy > entrpy
                gind, xpctd, entrpy = k, expectedpoolsize(gp), thisentropy
            end
        end
    end
    return gind, xpctd, entrpy
end

function optimalguess(gp::GamePool{N,S,MinimizeExpected}) where {N,S}
    gind, xpctd, entrpy = 0, Inf, -Inf
    for (k, a) in enumerate(gp.active)
        if a
            thisexpected = expectedpoolsize(bincounts!(gp, k))
            if thisexpected < xpctd
                gind, xpctd, entrpy = k, thisexpected, entropy2(gp)
            end
        end
    end
    return gind, xpctd, entrpy
end
```

The first method is to maximize the [entropy](https://en.wikipedia.org/wiki/Entropy_(information_theory)) of the distribution, which is an information-theory concept that measures how "spread out" the distribution is.
It depends only on the probabilities of the scores, not on the scores themselves.
The base-2 entropy, measured in bits, of a discrete distribution with probabilities ``p_i, i=1,\dots,n`` is defined as

```math
H_2(X) = - \sum_{i=1}^n p_i\,\log_2(p_i)
```

The `Wordlegames` package exports the `entropy2` function that returns this quantity from the current `counts`.
```julia
function entropy2(counts::AbstractVector{<:Real})
    countsum = sum(counts)
    return -sum(counts) do k
        x = k / countsum
        xlogx = x * log(x)
        iszero(x) ? zero(xlogx) : xlogx
    end / log(2)
end

entropy2(gp::GamePool) = entropy2(gp.counts)
```
"""

# ╔═╡ 663ce631-3a5d-494f-b138-3b8a675775f5
entropy2(wordle.counts)

# ╔═╡ 24a2b4f3-5e28-4571-ab04-2555d53f3858
md"or, equivalently"

# ╔═╡ f2dc7727-96c5-4114-871b-f24fe7d8457e
entropy2(bincounts!(wordle, 106))

# ╔═╡ 93c5e3e5-9910-4d5e-914c-81a4c70071c5
md"""
The
```julia
... do k
   ...
end
```
block, called a "thunk", in this code - yet another way of writing an anonymous function - is described later.

Roughly, the numerical result means that the distribution of target pool sizes after an initial guess of `"arise"` is, according to this measure, about as spread out as a uniform distribution on 56.5 possible responses.
"""

# ╔═╡ bf1ac53f-81e1-4a00-a7ea-79cb7d47f4d9
2^(entropy2(wordle))

# ╔═╡ f7eadde6-7809-412b-925d-cc114490b948
md"""
The second method is to minimize the expected pool size after the guess is scored.

By definition this is the sum of the bin size (or count) for each of the bins multiplied by the probability of the target being in the bin.
But that probability is the bin size divided by the total number of active targets.
Thus the expected pool size after the guess can be evaluated from the bin sizes alone.
```julia
function expectedpoolsize(gp::GamePool)
    return sum(abs2, gp.counts) / sum(gp.counts)
end
```
"""

# ╔═╡ 3759d196-84e6-4dbb-9fed-e42b7e600bf3
sum(abs2, wordle.counts) / sum(wordle.counts)   # abs2(x) returns x * x 

# ╔═╡ 101b142c-9d1a-4cdb-ac76-621cefc49fec
md"""
which is available as `expectedpoolsize`
"""

# ╔═╡ 46732340-5fe1-4819-93ed-82700cb845f8
expectedpoolsize(bincounts!(wordle, 106))

# ╔═╡ 54fc5c6e-2ec5-4b5a-8f36-283bc77c6efc
md"""
This is a measure of how successful an initial guess of `"arise"` will be.
On average it will reduce the target pool size from 2315 to 63.73.
"""

# ╔═╡ 1072ccf6-3876-4a3e-b7c9-ab0e06d719f4
md"""
## The best initial guess?

We can choose an initial guess (and, also, subsequent guesses) to maximize the entropy of the distribution of scores or to minimize the expected pool size for the next guess.

For both of these criteria, a slight modification on `"arise"`, exchanging the first two letters to form `"raise"`, at index 1535, is a bit better than `"arise"`.
"""

# ╔═╡ ff1bd84f-8c1d-4625-adc3-a85c33dad8b3
string(wordle.guesspool[1535]...)

# ╔═╡ d8c154d4-8f66-41cd-97a8-799be984d46b
entropy2(bincounts!(wordle, 1535))

# ╔═╡ 2414b249-a872-4f58-9155-b700617f9a6d
expectedpoolsize(wordle)

# ╔═╡ 12b2d119-1b20-4480-bd03-1b8aae8b8414
md"""
It turns out that `"raise"` is the best initial guess for both of these criteria, if we restrict outselves to guesses from the initial target pool.

One of the parameters of the `GamePool` type is the method of choosing the next guess, either `MaximizeEntropy`, the default, or `MinimizeExpected`,
"""

# ╔═╡ 4cf4bc01-347f-49c3-bae0-8b236b5605e9
typeof(wordle)

# ╔═╡ 478191dd-0ea2-4d4c-aba0-56c5c9300704
md"allowing for automatic game play."

# ╔═╡ cf68b9d6-b9bc-44f4-8a65-3cc207651d4d
showgame!(wordle, "rebus")

# ╔═╡ 87935e14-aa00-4d1c-8af4-6660fc2e3f53
md"""
That game ended suspiciously quickly but notice that, after the first guess, `"raise"`, is scored as `🟩🟫🟫🟨🟨` in tiles or 166 in decimal, the target pool size is reduced to 2,
"""

# ╔═╡ 918da34d-c817-4f8c-b55f-08b1c972bb06
[string(wordle.targetpool[i]...) for i in findall(==(166), view(wordle.allscores, :, 1535))]

# ╔═╡ ff09999f-ba27-4303-a688-5ec56b270a1d
md"""
giving a 50% chance of a correct second guess.

In the case of ties like this the target with the lowest index in the targetpool is returned.
This strategy can result in long series of guesses trying to isolate a single letter if that letter is toward the end of the alphabet
"""

# ╔═╡ 6ef41b3c-322f-4dee-91d7-f844d935427a
showgame!(wordle, "watch")

# ╔═╡ 26c90826-f132-462c-9220-37477308777f
md"""
but it is not clear that any other strategy will be more successful across all possible targets.
(This target did occur on the official Wordle web site in March of 2022.)

To play by the `MinimizeExpected` strategy requires specifying this as the `guesstype` when creating the `GamePool`.
"""

# ╔═╡ e1015994-39a3-4aaa-84e0-b5c905b5c370
wordlexpct = GamePool(
    collect(readlines(joinpath(datadir, "Wordletargets.txt")));
    guesstype=MinimizeExpected,
);

# ╔═╡ 26031b16-b75d-44f3-b0d8-e3033d89abe9
showgame!(wordlexpct, "rebus")

# ╔═╡ a318c5dd-d901-4357-99f5-81a5dd80aa7e
showgame!(wordlexpct, "watch")

# ╔═╡ 28d83118-011e-4143-9737-cfaa53dd927a
md"""
There are no differences between the two strategies in these games.

However, if we play all possible games using each of the two strategies and count the number of guesses to solution we can see that the two strategies do not always give the same length of game.
"""

# ╔═╡ 1e7f6b4c-13cb-48b0-a5f9-c0dadaf40b6b
gamelen = let
    inds = axes(wordle.targetpool, 1)
    DataFrame(;
        index=inds,
        entropy=[length(playgame!(wordle, k).guesses) for k in inds],
        expected=[length(playgame!(wordlexpct, k).guesses) for k in inds],
    )
end

# ╔═╡ d26b2f13-17e5-4c3d-af76-80fc34d6eeb9
md"""
For example,
"""

# ╔═╡ e4e98888-e46d-4652-bdcb-f9bbcb218a0b
showgame!(wordle, 5)

# ╔═╡ f40c636f-b23a-49d5-b43a-b1df01a84a4a
md"is different from"

# ╔═╡ 82fb2edc-2cc5-4b70-94f6-f608a291b58b
showgame!(wordlexpct, 5)

# ╔═╡ 82f09418-48e6-442c-84ee-25c473dfae1f
md"The mean and standard deviation of the game lengths are smaller when maximizing the entropy than when minimizing the expected pool size"

# ╔═╡ a7b6737c-fe1d-4ac4-a48e-0ce28041b6b3
describe(gamelen[!, [:entropy, :expected]], :min, :max, :mean, :std)

# ╔═╡ 73cce00b-caf8-44d7-81ad-0047c9df767d
md"""
The counts of the game lengths under the two strategies and a comparative barplot show the shift toward shorter game lengths when maximizing the entropy.
"""

# ╔═╡ 6ba0f36f-3ce6-4c6c-a051-4ec82348715f
gamelengths = let
    entropy = countmap(gamelen.entropy)
    expected = countmap(gamelen.expected)
    allcounts = 1:maximum(union(keys(entropy), keys(expected)))
    DataFrame(;
        count=allcounts,
        entropy=[get!(entropy, k, 0) for k in allcounts],
        expected=[get!(expected, k, 0) for k in allcounts],
    )
end

# ╔═╡ 46d872d4-fed2-419f-9f48-4a506a4680ff
let
    stacked = stack(gamelengths, 2:3)
    typeint = [(v == "entropy" ? 1 : 2) for v in stacked.variable]
    barplot(
        stacked.count,
        stacked.value;
        dodge=typeint,
        color=typeint,
        axis=(yticks=1:8, ylabel="Game length"),
        direction=:x,
    )
end

# ╔═╡ 3290f3e7-c188-42e7-ab61-bc9a246c051f
md"""
## Wordle-like games

Wordle has spawned many similar games, one of which is [Primel](https://converged.yt/primel), for which the targets are 5-digit prime numbers.
Because leading zeros are not allowed in these primes, the targets are prime numbers between 10,000 and 99,999.
"""

# ╔═╡ c1add535-051a-4e01-8f11-a1f669222a41
primel = GamePool(primes(10_000, 99_999));  # underscores are ignored in numbers

# ╔═╡ 44a74cf2-2691-47ca-b8a7-c0ab642c6015
md"""
To play a game with a random, but reproducible, target, we initialize a random number generator and pass it as the second argument to `showgame!`.
"""

# ╔═╡ 5928ecb5-47de-4961-a227-5529a65b8d69
showgame!(primel, Random.seed!(1234321))

# ╔═╡ 7eaac2d9-ad3a-49aa-89a2-dcf3f1309781
md"The size of the target pool is larger than for Wordle"

# ╔═╡ b2cd9705-fe32-48de-bf25-61b3df7f0e6f
length(primel.targetpool)

# ╔═╡ d0c0f1c9-a095-4c01-a38f-c2d11b9485f2
md"""
but the number of possible characters at each position (9 for the first position, 10 for the others) is smaller than for Wordle, leading to a larger mean number of guesses but a smaller standard deviation in the number of guesses.

As for Wordle, the strategy of choosing guesses to minimize the expected pool size is less effective than maximizing the entropy.
"""

# ╔═╡ dc64865f-3950-4ccf-80c7-bd3c4c5a35ad
primelxpectd = GamePool(primes(10_000, 99_999); guesstype=MinimizeExpected);

# ╔═╡ 25d6cf22-d929-4ab1-bf89-07ee2162ae00
allprimel = let
    inds = 1:length(primel.targetpool)
    DataFrame(;
        index=inds,
        entropy=[length(playgame!(primel, k).guesses) for k in inds],
        expected=[length(playgame!(primelxpectd, k).guesses) for k in inds],
    )
end

# ╔═╡ 24c9265b-65b1-4936-8ae9-089a7de659a0
primelengths = let
    entropy = countmap(allprimel.entropy)
    expected = countmap(allprimel.expected)
    allcounts = 1:maximum(union(keys(entropy), keys(expected)))
    DataFrame(;
        count=allcounts,
        entropy=[get!(entropy, k, 0) for k in allcounts],
        expected=[get!(expected, k, 0) for k in allcounts],
    )
end

# ╔═╡ f614bb07-8369-4f23-a24d-3737ab840e7a
describe(allprimel[!, Not(1)], :min, :max, :mean, :std)

# ╔═╡ 57588d15-32f7-4d03-9ba0-42373246a3c4
let
    stacked = stack(primelengths, 2:3)
    typeint = [(v == "entropy" ? 1 : 2) for v in stacked.variable]
    barplot(
        stacked.count,
        stacked.value;
        dodge=typeint,
        color=typeint,
        axis=(yticks=1:8, ylabel="Game length"),
        direction=:x,
    )
end

# ╔═╡ 7f16af27-5e82-4238-a3c6-87085f008441
md"""
## Some Julia syntax used in this code

Several Julia syntax features have been used in the code for this tutorial.
For example, the code block defining `gamelengths` is a `let` block.
This is similar to a `begin/end` block in that it groups multiple expressions, including assignments, so that they function as a single expression evaluation.
The difference between `let` and `begin` is that assignments within a `let` block are local to the block.

For example, `allcounts` is given a value within that block because it is used in several places when creating the `DataFrame` but it is not needed outside that block.

Notice also the expressions like `get!(entropy, k, 0)`.
This is extraction by key from a collection, like `entropy[k]` or, equivalently, `getindex(entropy, k)` except that it provides a default, `0` in this case, if there is no key `k` in the collection.
Furthermore, it modifies the collection by inserting the default value for key `k`.

An ellipsis, `"..."`, is used with arguments as in `string(wordle.guesspool[1535]...)`.
This use is called a "splat" (and there is another use of an ellipsis called a "slurp" - the designers of this language are very serious-minded folk).
As a "splat" the ellipsis expands an argument such as a vector or, in this case, the tuple `('r','a','i','s','e')` to multiple arguments, in this case, 5 `Char` arguments.

Another fun name for a construct is a "thunk", which is a way of specifying an anonymous function.
For example there are two methods defined for the `entropy2` generic
```julia
function entropy2(counts::AbstractVector{<:Real})
    countsum = sum(counts)
    return -sum(counts) do k
        x = k / countsum
        xlogx = x * log(x)
        iszero(x) ? zero(xlogx) : xlogx
    end / log(2)
end

entropy2(gp::GamePool) = entropy2(gp.counts)
```

In the first method we wish to evaluate ``-\sum_{i}p_i\,\log_2(p_i)`` which is sometimes called an `xlogx` function.
There is a `sum(f, itr)` method where `f` is a function and `itr` is an iterator, such as an `AbstractVector`.
In this case we want a function that evaluates `x = k / countsum` then `xlogx(x)` but `xlogx` requires some care.
If `x` is zero, the result should be zero but of the same type as `x * log(x)` for non-zero `x`.
That's why `x * log(x)` is evaluated first - to get the value type.
It will return `NaN` for `x = 0`, which is then converted to a zero but of the type that is consistent with the other values of `xlogx`.

For example, to evaluate the base-2 entropy for the initial guess in the `BigFloat` extended precision type, we convert from
"""

# ╔═╡ 75eb4f51-1079-4645-88c4-6d4e84a5e240
bincounts!(reset!(wordle), 1535); # reset the game to the initial state

# ╔═╡ d0197836-458b-4cff-9b53-da2d61b0af13
entropy2(wordle.counts)

# ╔═╡ 50456b05-2f73-4a17-a2e4-8088c4363576
md"to"

# ╔═╡ e367b784-03a5-456b-9bbe-12afaf6613a7
entropy2(big.(wordle.counts))

# ╔═╡ 55b1fd61-4f07-44a9-9b5a-f7be8b55eada
md"""
The second method definition for `entropy2` shows the compact form for defining "one-liner" methods.
It is a common idiom to have one method for a generic function that "does the work" and others that simply re-arrange the arguments to the form required by this "collector" method.
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
CairoMakie = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
Chain = "8be319e6-bccf-4806-a6f7-6fae938471bc"
DataFrameMacros = "75880514-38bc-4a95-a458-c2aea5a3a702"
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Primes = "27ebfcd6-29c5-5fa9-bf4b-fb8fc14df3ae"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
StatsBase = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
Wordlegames = "1cb69566-e1cf-455f-a587-fd79a2e00f5a"

[compat]
CairoMakie = "~0.7.4"
Chain = "~0.4.10"
DataFrameMacros = "~0.2.1"
DataFrames = "~1.3.2"
PlutoUI = "~0.7.37"
Primes = "~0.5.1"
StatsBase = "~0.33.16"
Wordlegames = "~0.2.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0-beta1"
manifest_format = "2.0"
project_hash = "d369fc825d6f3a628b25a96e4c30bf57f2a3fcb5"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "6f1d9bc1c08f9f4a8fa92e3ea3cb50153a1b40d4"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.1.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.AbstractTrees]]
git-tree-sha1 = "03e0550477d86222521d254b741d470ba17ea0b5"
uuid = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
version = "0.3.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "af92965fb30777147966f58acb05da51c5616b5f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.3"

[[deps.Animations]]
deps = ["Colors"]
git-tree-sha1 = "e81c509d2c8e49592413bfb0bb3b08150056c79d"
uuid = "27a7e980-b3e6-11e9-2bcd-0b925532e340"
version = "0.4.1"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArrayInterface]]
deps = ["Compat", "IfElse", "LinearAlgebra", "Requires", "SparseArrays", "Static"]
git-tree-sha1 = "d49f55ff9c7ee06930b0f65b1df2bfa811418475"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "4.0.4"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Automa]]
deps = ["Printf", "ScanByte", "TranscodingStreams"]
git-tree-sha1 = "d50976f217489ce799e366d9561d56a98a30d7fe"
uuid = "67c07d97-cdcb-5c2c-af73-a7f9c32a568b"
version = "0.8.2"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CEnum]]
git-tree-sha1 = "215a9aa4a1f23fbd05b92769fdd62559488d70e9"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.1"

[[deps.Cairo]]
deps = ["Cairo_jll", "Colors", "Glib_jll", "Graphics", "Libdl", "Pango_jll"]
git-tree-sha1 = "d0b3f8b4ad16cb0a2988c6788646a5e6a17b6b1b"
uuid = "159f3aea-2a34-519c-b102-8c37f9878175"
version = "1.0.5"

[[deps.CairoMakie]]
deps = ["Base64", "Cairo", "Colors", "FFTW", "FileIO", "FreeType", "GeometryBasics", "LinearAlgebra", "Makie", "SHA", "StaticArrays"]
git-tree-sha1 = "aedc7c910713eb616391cf95218277b714a7913f"
uuid = "13f3f980-e62b-5c42-98c6-ff1f3baf88f0"
version = "0.7.4"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.Chain]]
git-tree-sha1 = "339237319ef4712e6e5df7758d0bccddf5c237d9"
uuid = "8be319e6-bccf-4806-a6f7-6fae938471bc"
version = "0.4.10"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "c9a6160317d1abe9c44b3beb367fd448117679ca"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.13.0"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "bf98fa45a0a4cee295de98d4c1462be26345b9a1"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.2"

[[deps.ColorBrewer]]
deps = ["Colors", "JSON", "Test"]
git-tree-sha1 = "61c5334f33d91e570e1d0c3eb5465835242582c4"
uuid = "a2cac450-b92f-5266-8821-25eda20663c8"
version = "0.4.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "12fc73e5e0af68ad3137b886e3f7c1eacfca2640"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.17.1"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "3f1f500312161f1ae067abe07d13b40f78f32e07"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.8"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "96b0bc6c52df76506efc8a441c6cf1adcb1babc4"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.42.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.0+0"

[[deps.Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[deps.DataFrameMacros]]
deps = ["DataFrames"]
git-tree-sha1 = "cff70817ef73acb9882b6c9b163914e19fad84a9"
uuid = "75880514-38bc-4a95-a458-c2aea5a3a702"
version = "0.2.1"

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

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "9d3c0c762d4666db9187f363a76b47f7346e673b"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.49"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "90b158083179a6ccbce2c7eb1446d5bf9d7ae571"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.7"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3f3a2501fa7236e9b911e0f7a588c657e822bb6d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.3+0"

[[deps.EllipsisNotation]]
deps = ["ArrayInterface"]
git-tree-sha1 = "d7ab55febfd0907b285fbf8dc0c73c0825d9d6aa"
uuid = "da5c29d0-fa7d-589e-88eb-ea29b0a81949"
version = "1.3.0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ae13fcbc7ab8f16b0856729b050ef0c446aa3492"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.4+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "d8a578692e3077ac998b50c0217dfd67f21d1e5f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.0+0"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "505876577b5481e50d089c1c68899dfb6faebc62"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.4.6"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "80ced645013a5dbdc52cf70329399c35ce007fae"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.13.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "0dbc5b9683245f905993b51d2814202d75b34f1a"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.13.1"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.FreeType]]
deps = ["CEnum", "FreeType2_jll"]
git-tree-sha1 = "cabd77ab6a6fdff49bfd24af2ebe76e6e018a2b4"
uuid = "b38be410-82b0-50bf-ab77-7b57e271db43"
version = "4.0.0"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FreeTypeAbstraction]]
deps = ["ColorVectorSpace", "Colors", "FreeType", "GeometryBasics", "StaticArrays"]
git-tree-sha1 = "770050893e7bc8a34915b4b9298604a3236de834"
uuid = "663a7486-cb36-511b-a19d-713bb74d65c9"
version = "0.9.5"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "83ea630384a13fc4f002b77690bc0afeb4255ac9"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.2"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "a32d672ac2c967f3deb8a81d828afc739c838a06"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+2"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "1c5a84319923bea76fa145d49e93aa4394c73fc2"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.1"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.GridLayoutBase]]
deps = ["GeometryBasics", "InteractiveUtils", "Observables"]
git-tree-sha1 = "169c3dc5acae08835a573a8a3e25c62f689f8b5c"
uuid = "3955a311-db13-416c-9275-1d80ed98e5e9"
version = "0.6.5"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "SpecialFunctions", "Test"]
git-tree-sha1 = "65e4589030ef3c44d3b90bdc5aac462b4bb05567"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.8"

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

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "9a5c62f231e5bba35695a20988fc7cd6de7eeb5a"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.3"

[[deps.ImageIO]]
deps = ["FileIO", "JpegTurbo", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs"]
git-tree-sha1 = "464bdef044df52e6436f8c018bea2d48c40bb27b"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.1"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "87f7662e03a649cffa2e05bf19c303e168732d3e"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.2+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "b15fc0a95c564ca2e0a7ae12c1f095ca848ceb31"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.5"

[[deps.IntervalSets]]
deps = ["Dates", "EllipsisNotation", "Statistics"]
git-tree-sha1 = "3cc368af3f110a767ac786560045dceddfc16758"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.5.3"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "91b5dcf362c5add98049e6c29ee756910b03051d"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.3"

[[deps.InvertedIndices]]
git-tree-sha1 = "bee5f1ef5bf65df56bdd2e40447590b272a5471f"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.1.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.Isoband]]
deps = ["isoband_jll"]
git-tree-sha1 = "f9b6d97355599074dc867318950adaa6f9946137"
uuid = "f1662d9f-8043-43de-a69a-05efc1cc6ff4"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "a77b273f1ddec645d1b7c4fd5fb98c8f90ad10a5"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.1"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b53380851c6e6664204efb2e62cd24fa5c47e4ba"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.2+0"

[[deps.KernelDensity]]
deps = ["Distributions", "DocStringExtensions", "FFTW", "Interpolations", "StatsBase"]
git-tree-sha1 = "591e8dc09ad18386189610acafb970032c519707"
uuid = "5ab0869b-81aa-558d-bb23-cbf5423bbe9b"
version = "0.6.3"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

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

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "3f7cb7157ef860c637f3f4929c8ed5d9716933c6"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.7"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "e595b205efd49508358f7dc670a940c790204629"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2022.0.0+0"

[[deps.Makie]]
deps = ["Animations", "Base64", "ColorBrewer", "ColorSchemes", "ColorTypes", "Colors", "Contour", "Distributions", "DocStringExtensions", "FFMPEG", "FileIO", "FixedPointNumbers", "Formatting", "FreeType", "FreeTypeAbstraction", "GeometryBasics", "GridLayoutBase", "ImageIO", "IntervalSets", "Isoband", "KernelDensity", "LaTeXStrings", "LinearAlgebra", "MakieCore", "Markdown", "Match", "MathTeXEngine", "Observables", "OffsetArrays", "Packing", "PlotUtils", "PolygonOps", "Printf", "Random", "RelocatableFolders", "Serialization", "Showoff", "SignedDistanceFields", "SparseArrays", "StaticArrays", "Statistics", "StatsBase", "StatsFuns", "StructArrays", "UnicodeFun"]
git-tree-sha1 = "cd0fd02ab0d129f03515b7b68ca77fb670ef2e61"
uuid = "ee78f7c6-11fb-53f2-987a-cfe4a2b5a57a"
version = "0.16.5"

[[deps.MakieCore]]
deps = ["Observables"]
git-tree-sha1 = "c5fb1bfac781db766f9e4aef96adc19a729bc9b2"
uuid = "20f20a25-4f0e-4fdf-b5d1-57303727442b"
version = "0.2.1"

[[deps.MappedArrays]]
git-tree-sha1 = "e8b359ef06ec72e8c030463fe02efe5527ee5142"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.1"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.Match]]
git-tree-sha1 = "1d9bc5c1a6e7ee24effb93f175c9342f9154d97f"
uuid = "7eb4fadd-790c-5f42-8a69-bfa0b872bfbf"
version = "1.2.0"

[[deps.MathTeXEngine]]
deps = ["AbstractTrees", "Automa", "DataStructures", "FreeTypeAbstraction", "GeometryBasics", "LaTeXStrings", "REPL", "RelocatableFolders", "Test"]
git-tree-sha1 = "70e733037bbf02d691e78f95171a1fa08cdc6332"
uuid = "0a4f8689-d25c-4efe-a92b-7142dfc1aa53"
version = "0.2.1"

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

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "b34e3bc3ca7c94914418637cb10cc4d1d80d877d"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.3"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NaNMath]]
git-tree-sha1 = "b086b7ea07f8e38cf122f5016af580881ac914fe"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.7"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore"]
git-tree-sha1 = "18efc06f6ec36a8b801b23f076e3c6ac7c3bf153"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.Observables]]
git-tree-sha1 = "fe29afdef3d0c4a8286128d4e45cc50621b1e43d"
uuid = "510215fc-4207-5dde-b226-833fc4488ee2"
version = "0.4.0"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "043017e0bdeff61cfbb7afeb558ab29536bbb5ed"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.10.8"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.17+2"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "923319661e9a22712f24596ce81c54fc0366f304"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.1.1+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "648107615c15d4e09f7eca16307bc821c1f718d8"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.13+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "7e2166042d1698b6072352c74cfd1fca2a968253"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.6"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "eb4dbb8139f6125471aa3da98fb70f02dc58e49c"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.3.14"

[[deps.Packing]]
deps = ["GeometryBasics"]
git-tree-sha1 = "1155f6f937fa2b94104162f01fa400e192e4272f"
uuid = "19eb6ba3-879d-56ad-ad62-d5c202156566"
version = "0.4.2"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "03a7a85b76381a3d04c7a1656039197e70eda03d"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.11"

[[deps.Pango_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "FriBidi_jll", "Glib_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a121dfbba67c94a5bec9dde613c3d0cbcf3a12b"
uuid = "36c8627f-9965-5494-a995-c6b170f724f3"
version = "1.50.3+0"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "85b5da0fa43588c75bb1ff986493443f821c70b7"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.2.3"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "a7a7e1a88853564e551e4eba8650f8c38df79b37"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.1.1"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "6f1b25e8ea06279b5689263cc538f51331d7ca17"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.1.3"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "bf0a1121af131d9974241ba53f601211e9303a9e"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.37"

[[deps.PolygonOps]]
git-tree-sha1 = "77b3d3605fc1cd0b42d95eba87dfcd2bf67d5ff6"
uuid = "647866c9-e3ac-4575-94e7-e3d426903924"
version = "0.1.2"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "db3a23166af8aebf4db5ef87ac5b00d36eb771e2"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "de893592a221142f3db370f48290e3a2ef39998f"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.4"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Primes]]
git-tree-sha1 = "984a3ee07d47d401e0b823b7d30546792439070a"
uuid = "27ebfcd6-29c5-5fa9-bf4b-fb8fc14df3ae"
version = "0.5.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "afadeba63d90ff223a6a48d2009434ecee2ec9e8"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.1"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "18e8f4d1426e965c7b532ddd260599e1510d26ce"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.0"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "78aadffb3efd2155af139781b8a8df1ef279ea39"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.2"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "dc84268fe0e3335a62e315a3a7cf2afa7178a734"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.3"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "cdbd3b1338c72ce29d9584fdbe9e9b70eeb5adca"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.1.3"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SIMD]]
git-tree-sha1 = "7dbc15af7ed5f751a82bf3ed37757adf76c32402"
uuid = "fdea26ae-647d-5447-a871-4b548cad5224"
version = "3.4.1"

[[deps.ScanByte]]
deps = ["Libdl", "SIMD"]
git-tree-sha1 = "9cc2955f2a254b18be655a4ee70bc4031b2b189e"
uuid = "7b38b023-a4d7-4c5e-8d43-3f3097f304eb"
version = "0.3.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SignedDistanceFields]]
deps = ["Random", "Statistics", "Test"]
git-tree-sha1 = "d263a08ec505853a5ff1c1ebde2070419e3f28e9"
uuid = "73760f76-fbc4-59ce-8f25-708e95d2df96"
version = "0.4.0"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "8fb59825be681d451c246a795117f317ecbcaa28"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.2"

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

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "5ba658aeecaaf96923dce0da9e703bd1fe7666f9"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.4"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "65068e4b4d10f3c31aaae2e6cb92b6c6cedca610"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.5.6"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "74fb527333e72ada2dd9ef77d98e4991fb185f04"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.4.1"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "c3d8ba7f3fa0625b062b82853a7d5229cb728b6b"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.2.1"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "8977b17906b0a1cc74ab2e3a05faa16cf08a8291"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.16"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "25405d7016a47cf2bd6cd91e66f4de437fd54a07"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "0.9.16"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "57617b34fa34f91d536eb265df67c2d4519b8b98"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.5"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

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
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "OffsetArrays", "PkgVersion", "ProgressMeter", "UUIDs"]
git-tree-sha1 = "991d34bbff0d9125d93ba15887d6594e8e84b305"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.5.3"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.Wordlegames]]
deps = ["AbstractTrees", "DataFrames", "Random", "Tables"]
git-tree-sha1 = "2da18538a6107ec5ee5ac09a21da031c61582bb4"
uuid = "1cb69566-e1cf-455f-a587-fd79a2e00f5a"
version = "0.2.0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+1"

[[deps.isoband_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51b5eeb3f98367157a7a12a1fb0aa5328946c03c"
uuid = "9a68df92-36a6-505f-a73e-abb412b6bfb4"
version = "0.2.3+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.0.1+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "78736dab31ae7a53540a6b752efc61f77b304c5b"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.8.6+1"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.41.0+1"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "16.2.1+1"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"
"""

# ╔═╡ Cell order:
# ╟─b37908ca-9ef0-11ec-302b-6b280e5e08f5
# ╟─ea9f2405-b658-47c7-a8ac-540f379e9ac5
# ╟─44913684-7099-401b-8dcd-e0e84c5c1384
# ╠═e254cb71-9bb3-4cbc-80be-a8862f81fd9c
# ╟─a5d6acfe-77e2-4f14-a930-c1bdf6c0910c
# ╟─590847ab-ce78-4bb3-b15e-6d72d76e3fed
# ╟─0e122051-0488-47e0-81ef-d8b3d1f973ef
# ╠═b8e51a88-9fa0-476e-9e87-5d5e137a9720
# ╟─40100de5-4543-47ad-a0bf-7d69630b15d0
# ╠═9e9ebaa5-47f4-4c44-ab59-ef2940555756
# ╟─c9270bda-e8fa-44af-8863-5b245a352f48
# ╠═56692b81-b1b2-4449-8274-9faa55e8db50
# ╟─d3480b1c-a472-4cdf-9d48-46507a17623e
# ╠═42b52872-38dd-4976-88c8-600e55a33c6a
# ╟─ed459468-f112-494f-bec1-26ba72895db8
# ╟─526fa04e-4367-4736-8e30-96602b195af1
# ╠═752b02ae-54be-408e-b527-0158f7d29ec1
# ╟─d2162f9f-8d62-4f4a-b15a-b6d6b30dfe54
# ╠═6ff04850-d985-4796-a715-c83975e49b00
# ╟─8a9d7db2-4cb4-4791-8997-5971656ebb23
# ╠═29995b22-b4da-4d77-b806-d3fbb01d3b01
# ╟─b2a2d324-9cfb-48a3-9429-873ec93b36e3
# ╠═fb634eb5-4eb1-44d0-9cd7-c7266ebbb1ab
# ╟─c6c9637f-32e4-4c3c-ac67-04260546a0e1
# ╠═663ce631-3a5d-494f-b138-3b8a675775f5
# ╟─24a2b4f3-5e28-4571-ab04-2555d53f3858
# ╠═f2dc7727-96c5-4114-871b-f24fe7d8457e
# ╟─93c5e3e5-9910-4d5e-914c-81a4c70071c5
# ╠═bf1ac53f-81e1-4a00-a7ea-79cb7d47f4d9
# ╟─f7eadde6-7809-412b-925d-cc114490b948
# ╠═3759d196-84e6-4dbb-9fed-e42b7e600bf3
# ╟─101b142c-9d1a-4cdb-ac76-621cefc49fec
# ╠═46732340-5fe1-4819-93ed-82700cb845f8
# ╟─54fc5c6e-2ec5-4b5a-8f36-283bc77c6efc
# ╟─1072ccf6-3876-4a3e-b7c9-ab0e06d719f4
# ╠═ff1bd84f-8c1d-4625-adc3-a85c33dad8b3
# ╠═d8c154d4-8f66-41cd-97a8-799be984d46b
# ╠═2414b249-a872-4f58-9155-b700617f9a6d
# ╟─12b2d119-1b20-4480-bd03-1b8aae8b8414
# ╠═4cf4bc01-347f-49c3-bae0-8b236b5605e9
# ╟─478191dd-0ea2-4d4c-aba0-56c5c9300704
# ╠═cf68b9d6-b9bc-44f4-8a65-3cc207651d4d
# ╟─87935e14-aa00-4d1c-8af4-6660fc2e3f53
# ╠═918da34d-c817-4f8c-b55f-08b1c972bb06
# ╟─ff09999f-ba27-4303-a688-5ec56b270a1d
# ╠═6ef41b3c-322f-4dee-91d7-f844d935427a
# ╟─26c90826-f132-462c-9220-37477308777f
# ╠═e1015994-39a3-4aaa-84e0-b5c905b5c370
# ╠═26031b16-b75d-44f3-b0d8-e3033d89abe9
# ╠═a318c5dd-d901-4357-99f5-81a5dd80aa7e
# ╟─28d83118-011e-4143-9737-cfaa53dd927a
# ╠═1e7f6b4c-13cb-48b0-a5f9-c0dadaf40b6b
# ╟─d26b2f13-17e5-4c3d-af76-80fc34d6eeb9
# ╠═e4e98888-e46d-4652-bdcb-f9bbcb218a0b
# ╟─f40c636f-b23a-49d5-b43a-b1df01a84a4a
# ╠═82fb2edc-2cc5-4b70-94f6-f608a291b58b
# ╟─82f09418-48e6-442c-84ee-25c473dfae1f
# ╠═a7b6737c-fe1d-4ac4-a48e-0ce28041b6b3
# ╟─73cce00b-caf8-44d7-81ad-0047c9df767d
# ╠═6ba0f36f-3ce6-4c6c-a051-4ec82348715f
# ╟─46d872d4-fed2-419f-9f48-4a506a4680ff
# ╟─3290f3e7-c188-42e7-ab61-bc9a246c051f
# ╠═c1add535-051a-4e01-8f11-a1f669222a41
# ╟─44a74cf2-2691-47ca-b8a7-c0ab642c6015
# ╠═5928ecb5-47de-4961-a227-5529a65b8d69
# ╟─7eaac2d9-ad3a-49aa-89a2-dcf3f1309781
# ╠═b2cd9705-fe32-48de-bf25-61b3df7f0e6f
# ╟─d0c0f1c9-a095-4c01-a38f-c2d11b9485f2
# ╠═dc64865f-3950-4ccf-80c7-bd3c4c5a35ad
# ╠═25d6cf22-d929-4ab1-bf89-07ee2162ae00
# ╠═24c9265b-65b1-4936-8ae9-089a7de659a0
# ╠═f614bb07-8369-4f23-a24d-3737ab840e7a
# ╟─57588d15-32f7-4d03-9ba0-42373246a3c4
# ╟─7f16af27-5e82-4238-a3c6-87085f008441
# ╠═75eb4f51-1079-4645-88c4-6d4e84a5e240
# ╠═d0197836-458b-4cff-9b53-da2d61b0af13
# ╟─50456b05-2f73-4a17-a2e4-8088c4363576
# ╠═e367b784-03a5-456b-9bbe-12afaf6613a7
# ╟─55b1fd61-4f07-44a9-9b5a-f7be8b55eada
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
