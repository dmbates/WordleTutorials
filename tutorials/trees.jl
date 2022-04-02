### A Pluto.jl notebook ###
# v0.18.4

using Markdown
using InteractiveUtils

# ╔═╡ 3e14817e-85f8-4d5b-8a8f-075d1799ed27
using AbstractTrees, PlutoUI, Random, Wordlegames

# ╔═╡ ed649770-a53a-11ec-0434-1bbbc561f8cb
# hideall
title = "Wordle games as a tree";

# ╔═╡ 021364a8-f40b-49fe-9a02-406c0044c9ed
"""
+++
title = "$title"
+++
""" |> Base.Text

# ╔═╡ c49e1040-67c8-4386-a6ce-bbbeace8bc90
md"""
# $title

As described in the previous tutorial, strategies such as maximizing the entropy or minimizing the expected pool size for the next stage can be used to select guesses automatically in Wordle or related games.

When doing so the possible games can be represented in a data structure called a [tree](https://en.wikipedia.org/wiki/Tree_(data_structure)).

Some of the terminology used with these structures is based on concepts of a family tree.

First attach some packages that will be used
"""

# ╔═╡ cec480d3-7348-4d14-9628-007893713a07
md"and create an instance of `wordle` where the guesses are chosen to maximize the entropy, which is the default criterion."

# ╔═╡ 9586bcbd-16aa-4598-8faa-8220755566e6
begin
	datadir = joinpath(pkgdir(Wordlegames), "data")
	wordle = GamePool(collect(readlines(joinpath(datadir, "Wordletargets.txt"))))
end;

# ╔═╡ ddc457c3-f207-4ed1-8a8a-7f1c4cfdaed7
md"Finally, we create a tree from the games for a random selection of 25 targets."

# ╔═╡ 52ed4682-a0d7-44cf-b878-27f1cf9cc91d
gametree25 = tree(wordle, Random.seed!(1234321), 25);

# ╔═╡ 86d0bb82-ed8f-4b03-b90c-31c55e556bae
md"""
## The AbstractTrees package

The [AbstractTrees](https://github.com/JuliaCollections/AbstractTrees.jl) package provides many methods for working with tree data structures.
One of the most useful is `print_tree` which, as the name suggests, prints the tree in a special format.
(Because the content for these tutorials is generated as [Pluto](https://github.com/fonsp/Pluto.jl.git) notebooks, we need to wrap the call to `print_tree` in `with_terminal() do ... end` to have the output displayed.
Outside of Pluto this is not necessary.
"""

# ╔═╡ 30ba17b1-9c0c-4fd6-9f40-3c3c1c986e93
with_terminal() do
	print_tree(gametree25; maxdepth=8)
end

# ╔═╡ 384abc84-3fda-4ba3-b52e-2d46052b8ce6
md"""
Each guess in a game constitutes a `"node"` in the tree.
The initial guess in any of the games is `"raise"`, which is the `"root"` node for the tree.
A node can have zero or more `"children"` which are its immediate descendents.

The nodes in this tree are each a `GameNode` struct with a `"children"` field.
"""

# ╔═╡ 0c24b1ca-b36a-46f6-9da7-e5c3e3670d29
typeof(gametree25)

# ╔═╡ 68f9375f-31af-4916-933f-fb41905819f8
fieldnames(GameNode)

# ╔═╡ e1735528-469e-4a17-8b8a-d95dca03f46c
length(gametree25.children)  # number of children of the root node

# ╔═╡ 112b0452-7ae4-49b4-bbdd-54fb00ff8bdb
md"""
The `score` field of a `GameNode` is similar to the elements of the `guesses` field of a `GamePool` object but with one important difference.
In a `GameNode` the `score` and `sc` fields are the score that will produce the guess, as opposed to the score for the guess,

That is, the first child of `"raise"` is `"pilot"` which is the next guess in a game in which `"raise"` returns a score of `"🟫🟫🟨🟫🟫"` as tiles or 9 as a decimal number.
"""

# ╔═╡ f8f1521c-fbbb-4648-af9c-0a15c7e787ff
first(gametree25.children).score

# ╔═╡ 1dd5c9fb-820f-41c6-b796-494d68479f1c
md"""
The 16 children of the root node from these 25 games are
"""

# ╔═╡ 8302e26a-53ae-4f9f-9579-26a1c839c865
[child.score.guess for child in gametree25.children]

# ╔═╡ 7f4a7f14-fe77-43fa-b2dd-37ba70cf9da3
md"""
Some of these children have many descendents.
When generating the tree the children of a node are ordered according to the size of the tree rooted at that node.

Because a subtree is exactly the same type of structure as a tree, we can print a subtree with `print_tree`.
"""

# ╔═╡ 088ca1f6-44c3-4d0d-a68b-c71881813410
with_terminal() do
	print_tree(first(gametree25.children))
end

# ╔═╡ 785fe89b-4008-437a-ac73-2bdaa26e7cf6
md"""
We see that the size of the tree rooted at `"pilot"` is 10.
"""

# ╔═╡ 8d83a193-aed2-4c1d-8bc5-614a81d16548
md"""
The "leaves" of a tree are the terminal nodes, i.e. the nodes that do not have children.
"""

# ╔═╡ 576d0904-3f3e-49e8-9ce7-ccdd8767bf1b
[leaf.score.guess for leaf in Leaves(gametree25)]

# ╔═╡ 144a9d04-f971-48d9-ace4-dd0156f591c2
md"""
It happens in this case that all of the targets that generated the tree are leaves in this tree, but that is not necessarily the case.
"""

# ╔═╡ 105a0522-729a-49ea-b0a5-62b868ba5e45
length(collect(Leaves(gametree25)))

# ╔═╡ efcb3473-6ea1-459c-9995-32b0a407a2f4
md"""
## Creating the tree structure

As a language Julia gets high marks for "composability" - the ability to adapt one package to use concepts from another package.
The use of generic functions and multiple dispatch is central to this enhanced compositibility.

All that is necessary to use many of the functions in `AbstractTrees.jl` on the trees created from a collection of games using a particular `GamePool` is to define the `GameNode` struct, the method of generating the tree, and methods for `AbstractTrees.children`, `AbstractTrees.nodetype` and `AbstractTrees.printnode`
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
AbstractTrees = "1520ce14-60c1-5f80-bbc7-55ef81b5835c"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
Wordlegames = "1cb69566-e1cf-455f-a587-fd79a2e00f5a"

[compat]
AbstractTrees = "~0.3.4"
PlutoUI = "~0.7.38"
Wordlegames = "~0.3.0"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0-beta3"
manifest_format = "2.0"
project_hash = "2c8800ff06b3096b67485eb059a224666198ba30"

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

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "96b0bc6c52df76506efc8a441c6cf1adcb1babc4"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.42.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

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
version = "0.3.20+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "621f4f3b4977325b9128d5fae7a8b4829a0c2222"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.2.4"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "670e559e5c8e191ded66fa9ea89c97f10376bb4c"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.38"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "28ef6c7ce353f0b35d0df0d5930e0d072c1f5b9b"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.1"

[[deps.PrettyTables]]
deps = ["Crayons", "Formatting", "Markdown", "Reexport", "Tables"]
git-tree-sha1 = "dfb54c4e414caa595a1f2ed759b160f5a3ddcba5"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "1.3.1"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

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
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

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
git-tree-sha1 = "4c463de78d2f3f9447b695e241eba43cc945f866"
uuid = "1cb69566-e1cf-455f-a587-fd79a2e00f5a"
version = "0.3.0"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+1"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.0+0"

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
# ╟─ed649770-a53a-11ec-0434-1bbbc561f8cb
# ╟─021364a8-f40b-49fe-9a02-406c0044c9ed
# ╟─c49e1040-67c8-4386-a6ce-bbbeace8bc90
# ╠═3e14817e-85f8-4d5b-8a8f-075d1799ed27
# ╟─cec480d3-7348-4d14-9628-007893713a07
# ╠═9586bcbd-16aa-4598-8faa-8220755566e6
# ╟─ddc457c3-f207-4ed1-8a8a-7f1c4cfdaed7
# ╠═52ed4682-a0d7-44cf-b878-27f1cf9cc91d
# ╟─86d0bb82-ed8f-4b03-b90c-31c55e556bae
# ╠═30ba17b1-9c0c-4fd6-9f40-3c3c1c986e93
# ╟─384abc84-3fda-4ba3-b52e-2d46052b8ce6
# ╠═0c24b1ca-b36a-46f6-9da7-e5c3e3670d29
# ╠═68f9375f-31af-4916-933f-fb41905819f8
# ╠═e1735528-469e-4a17-8b8a-d95dca03f46c
# ╟─112b0452-7ae4-49b4-bbdd-54fb00ff8bdb
# ╠═f8f1521c-fbbb-4648-af9c-0a15c7e787ff
# ╟─1dd5c9fb-820f-41c6-b796-494d68479f1c
# ╠═8302e26a-53ae-4f9f-9579-26a1c839c865
# ╟─7f4a7f14-fe77-43fa-b2dd-37ba70cf9da3
# ╠═088ca1f6-44c3-4d0d-a68b-c71881813410
# ╟─785fe89b-4008-437a-ac73-2bdaa26e7cf6
# ╟─8d83a193-aed2-4c1d-8bc5-614a81d16548
# ╠═576d0904-3f3e-49e8-9ce7-ccdd8767bf1b
# ╟─144a9d04-f971-48d9-ace4-dd0156f591c2
# ╠═105a0522-729a-49ea-b0a5-62b868ba5e45
# ╟─efcb3473-6ea1-459c-9995-32b0a407a2f4
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
