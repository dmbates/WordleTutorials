~~~
<!-- PlutoStaticHTML.Begin -->
<!--
    # This information is used for caching.
    [PlutoStaticHTML.State]
    input_sha = "bd62e5524114bfa5d6e34cf6b1331804f46ed41d67cd15b71a54a3142458747a"
    julia_version = "1.7.2"
-->




~~~
+++
title = "Wordle games as a tree"
+++

~~~


<div class="markdown"><h1>Wordle games as a tree</h1>
<p>As described in the previous tutorial, strategies such as maximizing the entropy or minimizing the expected pool size for the next stage can be used to select guesses automatically in Wordle or related games.</p>
<p>When doing so the possible games can be represented in a data structure called a <a href="https://en.wikipedia.org/wiki/Tree_&#40;data_structure&#41;">tree</a>.</p>
<p>Some of the terminology used with these structures is based on concepts of a family tree.</p>
<p>First attach some packages that will be used</p>
</div>

<pre class='language-julia'><code class='language-julia'>using AbstractTrees, PlutoUI, Random, Wordlegames</code></pre>



<div class="markdown"><p>and create an instance of <code>wordle</code> where the guesses are chosen to maximize the entropy, which is the default criterion.</p>
</div>

<pre class='language-julia'><code class='language-julia'>begin
    datadir = joinpath(pkgdir(Wordlegames), "data")
    wordle = GamePool(collect(readlines(joinpath(datadir, "Wordletargets.txt"))))
end;</code></pre>



<div class="markdown"><p>Finally, we create a tree from the games for a random selection of 25 targets.</p>
</div>

<pre class='language-julia'><code class='language-julia'>gametree25 = tree(wordle, Random.seed!(1234321), 25);</code></pre>



<div class="markdown"><h2>The AbstractTrees package</h2>
<p>The <a href="https://github.com/JuliaCollections/AbstractTrees.jl">AbstractTrees</a> package provides many methods for working with tree data structures. One of the most useful is <code>print_tree</code> which, as the name suggests, prints the tree in a special format. &#40;Because the content for these tutorials is generated as <a href="https://github.com/fonsp/Pluto.jl.git">Pluto</a> notebooks, we need to wrap the call to <code>print_tree</code> in <code>with_terminal&#40;&#41; do ... end</code> to have the output displayed. Outside of Pluto this is not necessary.</p>
</div>

<pre class='language-julia'><code class='language-julia'>with_terminal() do
    print_tree(gametree25; maxdepth=8)
end</code></pre>
<pre id="plutouiterminal">
missing, raise, 2315, 5.87791, 61.0009
├─ 🟫🟫🟨🟫🟫, pilot, 107, 4.69342, 6.38318
│  ├─ 🟫🟩🟫🟫🟨, width, 13, 2.93121, 2.07692
│  │  └─ 🟫🟩🟫🟩🟫, bitty, 4, 1.5, 1.5
│  │     └─ 🟫🟩🟫🟩🟩, fifty, 2, 1.0, 1.0
│  ├─ 🟫🟩🟫🟫🟫, windy, 16, 3.20282, 1.875
│  │  └─ 🟫🟩🟫🟫🟩, fizzy, 2, 1.0, 1.0
│  │     └─ 🟨🟩🟫🟫🟩, jiffy, 1, -0.0, 1.0
│  ├─ 🟫🟨🟫🟨🟫, comic, 4, 2.0, 1.0
│  │  └─ 🟩🟩🟫🟩🟩, conic, 1, -0.0, 1.0
│  └─ 🟫🟨🟫🟨🟩, vomit, 1, -0.0, 1.0
├─ 🟨🟫🟫🟫🟨, deter, 102, 4.37007, 9.23529
│  ├─ 🟫🟫🟫🟩🟩, cower, 26, 2.74682, 5.23077
│  │  └─ 🟫🟩🟫🟩🟩, hover, 9, 1.65774, 3.44444
│  │     └─ 🟫🟩🟩🟩🟩, lover, 2, 1.0, 1.0
│  │        └─ 🟫🟩🟩🟩🟩, mover, 1, -0.0, 1.0
│  ├─ 🟩🟩🟫🟫🟩, decor, 2, 1.0, 1.0
│  │  └─ 🟩🟩🟫🟫🟩, demur, 1, -0.0, 1.0
│  └─ 🟫🟩🟫🟫🟨, merry, 8, 2.25, 1.75
│     └─ 🟩🟩🟩🟫🟩, mercy, 1, -0.0, 1.0
├─ 🟨🟨🟫🟫🟫, adorn, 78, 4.16435, 6.35897
│  ├─ 🟨🟫🟫🟨🟫, tract, 16, 3.15564, 2.0
│  │  └─ 🟫🟩🟩🟫🟫, graph, 3, 1.58496, 1.0
│  │     └─ 🟫🟩🟩🟫🟫, brawl, 1, -0.0, 1.0
│  ├─ 🟨🟫🟫🟩🟫, chart, 7, 2.80735, 1.0
│  │  └─ 🟫🟫🟩🟩🟫, quark, 1, -0.0, 1.0
│  └─ 🟨🟫🟨🟨🟫, molar, 7, 2.52164, 1.28571
│     └─ 🟩🟩🟨🟩🟨, moral, 1, -0.0, 1.0
├─ 🟫🟫🟫🟫🟫, mulch, 168, 5.21165, 6.85714
│  ├─ 🟫🟩🟩🟫🟫, bully, 6, 1.79248, 2.0
│  │  └─ 🟫🟩🟩🟫🟩, pulpy, 1, -0.0, 1.0
│  ├─ 🟫🟨🟨🟨🟫, cloud, 4, 2.0, 1.0
│  │  └─ 🟩🟩🟩🟩🟫, clout, 1, -0.0, 1.0
│  └─ 🟫🟫🟫🟫🟨, whoop, 6, 2.58496, 1.0
│     └─ 🟫🟨🟨🟫🟫, hobby, 1, -0.0, 1.0
├─ 🟫🟫🟫🟫🟨, betel, 121, 5.06266, 4.95041
│  └─ 🟫🟩🟫🟫🟨, cello, 9, 2.9477, 1.22222
│     └─ 🟫🟩🟩🟫🟨, felon, 2, 1.0, 1.0
│        └─ 🟫🟩🟩🟩🟩, melon, 1, -0.0, 1.0
├─ 🟨🟫🟫🟫🟫, court, 103, 4.70622, 6.35922
│  └─ 🟫🟨🟫🟨🟫, droop, 19, 3.03112, 2.78947
│     └─ 🟫🟩🟩🟫🟨, prong, 3, 0.918296, 1.66667
│        └─ 🟩🟩🟩🟫🟫, prowl, 2, 1.0, 1.0
├─ 🟨🟩🟩🟫🟫, dairy, 4, 1.5, 1.5
│  └─ 🟫🟩🟩🟩🟩, fairy, 2, 1.0, 1.0
│     └─ 🟫🟩🟩🟩🟩, hairy, 1, -0.0, 1.0
├─ 🟨🟩🟫🟫🟫, party, 26, 3.12276, 3.84615
│  └─ 🟫🟩🟩🟫🟩, carry, 4, 1.5, 1.5
│     └─ 🟫🟩🟩🟩🟩, harry, 2, 1.0, 1.0
├─ 🟫🟫🟫🟨🟩, stone, 17, 3.0072, 2.64706
│  └─ 🟩🟫🟩🟫🟩, scope, 5, 1.92193, 1.4
│     └─ 🟩🟫🟩🟩🟩, slope, 1, -0.0, 1.0
├─ 🟫🟩🟫🟫🟩, cable, 26, 2.81123, 4.53846
│  └─ 🟫🟩🟫🟨🟩, halve, 5, 2.32193, 1.0
├─ 🟨🟫🟩🟫🟨, fried, 12, 2.75163, 2.16667
│  └─ 🟫🟨🟩🟨🟩, weird, 1, -0.0, 1.0
├─ 🟫🟫🟨🟫🟨, linen, 35, 3.98882, 2.88571
│  └─ 🟫🟨🟫🟨🟩, begin, 1, -0.0, 1.0
├─ 🟫🟩🟫🟨🟫, salon, 20, 3.34644, 2.3
│  └─ 🟨🟩🟫🟫🟫, hasty, 4, 1.5, 1.5
├─ 🟨🟫🟫🟨🟫, short, 24, 3.60539, 2.25
│  └─ 🟨🟫🟨🟨🟨, torus, 1, -0.0, 1.0
├─ 🟫🟫🟨🟨🟨, islet, 4, 2.0, 1.0
└─ 🟨🟩🟫🟨🟫, satyr, 2, 1.0, 1.0
</pre>



<div class="markdown"><p>Each guess in a game constitutes a <code>&quot;node&quot;</code> in the tree. The initial guess in any of the games is <code>&quot;raise&quot;</code>, which is the <code>&quot;root&quot;</code> node for the tree. A node can have zero or more <code>&quot;children&quot;</code> which are its immediate descendents.</p>
<p>The nodes in this tree are each a <code>GameNode</code> struct with a <code>&quot;children&quot;</code> field.</p>
</div>

<pre class='language-julia'><code class='language-julia'>typeof(gametree25)</code></pre>
<pre id='var-hash147827' class='documenter-example-output'><code class='code-output'>GameNode</code></pre>

<pre class='language-julia'><code class='language-julia'>fieldnames(GameNode)</code></pre>
<pre id='var-hash246742' class='documenter-example-output'><code class='code-output'>(:score, :children)</code></pre>

<pre class='language-julia'><code class='language-julia'>length(gametree25.children)  # number of children of the root node</code></pre>
<pre id='var-hash971548' class='documenter-example-output'><code class='code-output'>16</code></pre>


<div class="markdown"><p>The <code>score</code> field of a <code>GameNode</code> is similar to the elements of the <code>guesses</code> field of a <code>GamePool</code> object but with one important difference. In a <code>GameNode</code> the <code>score</code> and <code>sc</code> fields are the score that will produce the guess, as opposed to the score for the guess,</p>
<p>That is, the first child of <code>&quot;raise&quot;</code> is <code>&quot;pilot&quot;</code> which is the next guess in a game in which <code>&quot;raise&quot;</code> returns a score of <code>&quot;🟫🟫🟨🟫🟫&quot;</code> as tiles or 9 as a decimal number.</p>
</div>

<pre class='language-julia'><code class='language-julia'>first(gametree25.children).score</code></pre>
<pre id='var-hash611015' class='documenter-example-output'><code class='code-output'>NamedTuple{(:poolsz, :index, :guess, :expected, :entropy, :score, :sc), Tuple{Int64, Int64, String, Float64, Float64, Union{Missing, String}, Union{Missing, Int64}}}((107, 1413, "pilot", 6.383177570093458, 4.693417652050758, "🟫🟫🟨🟫🟫", 9))</code></pre>


<div class="markdown"><p>The 16 children of the root node from these 25 games are</p>
</div>

<pre class='language-julia'><code class='language-julia'>[child.score.guess for child in gametree25.children]</code></pre>
<pre id='var-hash458781' class='documenter-example-output'><code class='code-output'>16-element Vector{String}:
 "pilot"
 "deter"
 "adorn"
 "mulch"
 "betel"
 "court"
 "dairy"
 ⋮
 "fried"
 "linen"
 "salon"
 "short"
 "islet"
 "satyr"</code></pre>


<div class="markdown"><p>Some of these children have many descendents. When generating the tree the children of a node are ordered according to the size of the tree rooted at that node.</p>
<p>Because a subtree is exactly the same type of structure as a tree, we can print a subtree with <code>print_tree</code>.</p>
</div>

<pre class='language-julia'><code class='language-julia'>with_terminal() do
    print_tree(first(gametree25.children))
end</code></pre>
<pre id="plutouiterminal">
🟫🟫🟨🟫🟫, pilot, 107, 4.69342, 6.38318
├─ 🟫🟩🟫🟫🟨, width, 13, 2.93121, 2.07692
│  └─ 🟫🟩🟫🟩🟫, bitty, 4, 1.5, 1.5
│     └─ 🟫🟩🟫🟩🟩, fifty, 2, 1.0, 1.0
├─ 🟫🟩🟫🟫🟫, windy, 16, 3.20282, 1.875
│  └─ 🟫🟩🟫🟫🟩, fizzy, 2, 1.0, 1.0
│     └─ 🟨🟩🟫🟫🟩, jiffy, 1, -0.0, 1.0
├─ 🟫🟨🟫🟨🟫, comic, 4, 2.0, 1.0
│  └─ 🟩🟩🟫🟩🟩, conic, 1, -0.0, 1.0
└─ 🟫🟨🟫🟨🟩, vomit, 1, -0.0, 1.0
</pre>



<div class="markdown"><p>We see that the size of the tree rooted at <code>&quot;pilot&quot;</code> is 10.</p>
</div>


<div class="markdown"><p>The &quot;leaves&quot; of a tree are the terminal nodes, i.e. the nodes that do not have children.</p>
</div>

<pre class='language-julia'><code class='language-julia'>[leaf.score.guess for leaf in Leaves(gametree25)]</code></pre>
<pre id='var-hash124012' class='documenter-example-output'><code class='code-output'>25-element Vector{String}:
 "fifty"
 "jiffy"
 "conic"
 "vomit"
 "mover"
 "demur"
 "mercy"
 ⋮
 "weird"
 "begin"
 "hasty"
 "torus"
 "islet"
 "satyr"</code></pre>


<div class="markdown"><p>It happens in this case that all of the targets that generated the tree are leaves in this tree, but that is not necessarily the case.</p>
</div>

<pre class='language-julia'><code class='language-julia'>length(collect(Leaves(gametree25)))</code></pre>
<pre id='var-hash116393' class='documenter-example-output'><code class='code-output'>25</code></pre>


<div class="markdown"><h2>Creating the tree structure</h2>
<p>As a language Julia gets high marks for &quot;composability&quot; - the ability to adapt one package to use concepts from another package. The use of generic functions and multiple dispatch is central to this enhanced compositibility.</p>
<p>All that is necessary to use many of the functions in <code>AbstractTrees.jl</code> on the trees created from a collection of games using a particular <code>GamePool</code> is to define the <code>GameNode</code> struct, the method of generating the tree, and methods for <code>AbstractTrees.children</code>, <code>AbstractTrees.nodetype</code> and <code>AbstractTrees.printnode</code></p>
</div>
<div class='manifest-versions'>
<p>Built with Julia 1.7.2 and</p>
AbstractTrees 0.3.4<br>
PlutoUI 0.7.38<br>
Wordlegames 0.3.0
</div>

<!-- PlutoStaticHTML.End -->
~~~