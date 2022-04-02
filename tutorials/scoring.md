~~~
<!-- PlutoStaticHTML.Begin -->
<!--
    # This information is used for caching.
    [PlutoStaticHTML.State]
    input_sha = "620cbc9c0e231d991b4c7b4b1a814876770687d02fdb55b46579a6ed1d2483c9"
    julia_version = "1.7.2"
-->




~~~
+++
title = "Scoring guesses in Wordle"
+++

~~~


<div class="markdown"><h1>Scoring guesses in Wordle</h1>
<p><a href="https://en.wikipedia.org/wiki/Wordle">Wordle</a> is a recently developed, extremely popular word game that has already spawned many imitators such as <a href="https://converged.yt/primel/">Primel</a>.</p>
<p>These tutorials illustrate some <a href="https://julialang.org">Julia</a> programming concepts using functions in the <a href="https://github.com/dmbates/Wordlegames.jl">Wordlegames</a> package for illustration. Part of the purpose is to illustrate the unique nature of Julia as a dynamically-typed language with a just-in-time &#40;JIT&#41; compiler. It allows you to write &quot;generic&quot;, both in the common meaning of &quot;general purpose&quot; and in the technical meaning of generic functions, and performative code.</p>
<p>This posting originated from a conversation on the Julia <a href="https://discourse.julialang.org/t/rust-julia-comparison-post/75403">discourse channel</a> referring to a case where Julia code to perform a certain Wordle-related task - determine the &quot;best&quot; initial guess in a Wordle game - was horribly slow. Julia code described in a <a href="https://news.ycombinator.com/">Hacker News</a> posting took several hours to do this.</p>
<p>In situations like this the Julia community inevitably responds with suggested modifications to make the code run faster. Someone joked that we wouldn&#39;t be satisfied until we could do that task in less than 1 second, and we did.</p>
<p>The code in these postings can be used to solve a Wordle game very rapidly, as well as related games like Primel.</p>
<p>Before beginning we attach some packages that will be used in this notebook.</p>
</div>

<pre class='language-julia'><code class='language-julia'>using BenchmarkTools, PlutoUI, Wordlegames</code></pre>



<div class="markdown"><h2>Target pools</h2>
<p>If you are not familiar with the rules of Wordle, please check the <a href="https://en.wikipedia.org/wiki/Wordle">Wikipedia page</a>. It is a word game with the objective of guessing a 5-letter English word, which we will call the &quot;target&quot;. The target word is changed every day but it is always chosen from a set of 2315 words, which we will call the &quot;target pool&quot;.</p>
<p>The original target pool is available with the <code>Wordlegames</code> package.  &#40;Apparently the New York Times removed a few of these words after they purchased the rights to Wordle.&#41;</p>
</div>

<pre class='language-julia'><code class='language-julia'>datadir = joinpath(pkgdir(Wordlegames), "data");</code></pre>


<pre class='language-julia'><code class='language-julia'>wordlestrings = collect(readlines(joinpath(datadir, "Wordletargets.txt")))</code></pre>
<pre id='var-wordlestrings' class='documenter-example-output'><code class='code-output'>2315-element Vector{String}:
 "aback"
 "abase"
 "abate"
 "abbey"
 "abbot"
 "abhor"
 "abide"
 ⋮
 "yield"
 "young"
 "youth"
 "zebra"
 "zesty"
 "zonal"</code></pre>


<div class="markdown"><p>We call this pool <code>wordlestrings</code> because it is stored as a vector of <code>String</code>s</p>
</div>

<pre class='language-julia'><code class='language-julia'>typeof(wordlestrings)</code></pre>
<pre id='var-hash114335' class='documenter-example-output'><code class='code-output'>Vector{String} (alias for Array{String, 1})</code></pre>


<div class="markdown"><p>The <code>Wordlegames</code> package defines a <code>GamePool</code> struct for playing Wordle or related games. In that <code>struct</code> the <code>String</code>s are converted to a more efficient storage mode as a vector of <code>NTuple&#123;5,Char&#125;</code>, which takes advantage of the fact that each string is exactly 5 characters long.</p>
<p>Speaking of which, it would be a good idea to check that this collection has the properties we were told it had. It should be a vector of 2315 strings, each of which is 5 characters.</p>
</div>

<pre class='language-julia'><code class='language-julia'>length(wordlestrings)</code></pre>
<pre id='var-hash491243' class='documenter-example-output'><code class='code-output'>2315</code></pre>

<pre class='language-julia'><code class='language-julia'>all(w -&gt; length(w) == 5, wordlestrings)</code></pre>
<pre id='var-anon12368871130772838989' class='documenter-example-output'><code class='code-output'>true</code></pre>


<div class="markdown"><p>That last expression may look, well, &quot;interesting&quot;. It is a way of checking that a function, in this case an anonymous function expressed using the <a href="https://dev.to/keithrbennett/why-i-prefer-stabby-lambda-notation-5gcj">stabby lambda</a> notation, returns <code>true</code> for each element of an iterator, in this case the vector <code>wordlestrings</code>. You can read the whole expression as &quot;is <code>length&#40;w&#41;</code> equal to <code>5</code> for each word <code>w</code> in <code>wordlestrings</code>&quot;.</p>
<p>These words are supposed to be exactly 5 letters long but it never hurts to check. I&#39;ve been a data scientist for several decades and one of the first lessons in the field is to <a href="https://en.wikipedia.org/wiki/Trust&#37;2C_but_verify">trust, but verify</a> any claims about the data you are provided.</p>
<p>It turns out this check is redundant because the property is checked when creating a <code>GamePool</code>.</p>
</div>

<pre class='language-julia'><code class='language-julia'>wordle = GamePool(wordlestrings);</code></pre>


<pre class='language-julia'><code class='language-julia'>propertynames(wordle)</code></pre>
<pre id='var-hash151241' class='documenter-example-output'><code class='code-output'>(:guesspool, :validtargets, :allscores, :active, :counts, :guesses, :hardmode, :summary, :targetpool, :activetargets)</code></pre>

<pre class='language-julia'><code class='language-julia'>typeof(wordle.guesspool)</code></pre>
<pre id='var-hash384361' class='documenter-example-output'><code class='code-output'>Vector{NTuple{5, Char}} (alias for Array{NTuple{5, Char}, 1})</code></pre>

<pre class='language-julia'><code class='language-julia'>first(wordle.guesspool, 3)</code></pre>
<pre id='var-hash396977' class='documenter-example-output'><code class='code-output'>3-element Vector{NTuple{5, Char}}:
 ('a', 'b', 'a', 'c', 'k')
 ('a', 'b', 'a', 's', 'e')
 ('a', 'b', 'a', 't', 'e')</code></pre>


<div class="markdown"><h2>Game play</h2>
<p>A Wordle game is a dialog between the player and an &quot;oracle&quot;, which, for the official game, is the web site. The player submits a question to the oracle and the oracle responds, using information to which the player does not have access. In this case the information is the target word. The question is the player&#39;s guess - a 5-letter word - and the response is a score for that word. The score indicates, for each character, whether it matches the character in the same position in the target or it is in the target in another position or it is not in the target at all.</p>
<p>Using the sample game for Wordle #196 from the Wikipedia page for illustration</p>
</div>

<pre class='language-julia'><code class='language-julia'>PlutoUI.Resource(
    "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Wordle_196_example.svg/440px-Wordle_196_example.svg.png",
)</code></pre>
<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Wordle_196_example.svg/440px-Wordle_196_example.svg.png" controls="" type="image/png"></img>


<div class="markdown"><p>The target is &quot;rebus&quot;.</p>
<p>The player&#39;s first guess is &quot;arise&quot; and the response, or score, from the oracle is coded as 🟫🟨🟫🟨🟨 where 🟫 indicates that the letter is not in the target &#40;neither <code>a</code> nor <code>i</code> occur in &quot;rebus&quot;&#41; and 🟨 indicates that the letter is in the target but not at that position. &#40;I&#39;m using 🟫 instead of a gray square because I can&#39;t find a gray square Unicode character.&#41;</p>
<p>The second guess is &quot;route&quot; for which the response is 🟩🟫🟨🟫🟨 indicating that the first letter in the guess occurs as the first letter in the target. Notice that this guess does not include an &quot;s&quot;, which is known from the score of the first guess to be one of the characters in the target. This guess would not be allowed if playing the game under the &quot;Hard Mode&quot; setting.</p>
<p>Of course, the colors are just one way of summarizing the response to a guess. Within a computer program it is easier to use an integer to represent each of the 243 &#61; 3⁵ possible scores. An obvious way of mapping the result to an integer in the &#40;decimal&#41; range 0:242 is by mapping the response for each character to 2 &#40;in target at that position&#41;, 1 &#40;in target not at that position&#41;, or 0 &#40;not in target&#41; and regarding the pattern as a base-3 number.</p>
<p>In this coding the response for the first guess, &quot;arise&quot;, is 01011 in base-3 or 31 in decimal. The response for the second guess, &quot;route&quot;, is 20101 in base-3 or 172 in decimal.</p>
<p>A function to evaluate this score can be written as</p>
</div>

<pre class='language-julia'><code class='language-julia'>function score(guess, target)
    s = 0
    for (g, t) in zip(guess, target)
        s *= 3
        s += (g == t) ? 2 : Int(g ∈ target)
    end
    return s
end</code></pre>
<pre id='var-score' class='documenter-example-output'><code class='code-output'>score (generic function with 1 method)</code></pre>

<pre class='language-julia'><code class='language-julia'>score("arise", "rebus")</code></pre>
<pre id='var-hash711106' class='documenter-example-output'><code class='code-output'>31</code></pre>


<div class="markdown"><p>These numeric scores are not on a scale where &quot;smaller is better&quot; or &quot;larger is better&quot;. &#40;It happens that the best score is 242, corresponding to a perfect match, or five green tiles, but that&#39;s incidental.&#41;</p>
<p>The score is just a way of representing each of the 243 patterns that can be produced.</p>
<p>We can convert back to colored tiles if desired using the <code>tiles</code> function from the <code>Wordlegames</code> package, defined as </p>
<pre><code class="language-julia">function tiles&#40;sc, ntiles&#41;
    result &#61; Char&#91;&#93;       # initialize to an empty array of Char
    for _ in 1:ntiles     # _ indicates the value of the iterator is not used
        sc, r &#61; divrem&#40;sc, 3&#41;
        push&#33;&#40;result, iszero&#40;r&#41; ? &#39;🟫&#39; : &#40;isone&#40;r&#41; ? &#39;🟨&#39; : &#39;🟩&#39;&#41;&#41;
    end
    return String&#40;reverse&#40;result&#41;&#41;
end</code></pre>
</div>

<pre class='language-julia'><code class='language-julia'>tiles(31, 5)</code></pre>
<pre id='var-hash651477' class='documenter-example-output'><code class='code-output'>"🟫🟨🟫🟨🟨"</code></pre>


<div class="markdown"><h2>Examining the score function</h2>
<p>In the Sherlock Holmes story <a href="thttps://en.wikipedia.org/wiki/The_Adventure_of_Silver_Blaze">The Adventure of Silver Blaze</a> there is a famous exchange where Holmes remarks on &quot;the curious incident of the dog in the night-time&quot; &#40;see the link&#41;. The critical clue in the case is not what happened but what didn&#39;t happen - the dog didn&#39;t bark.</p>
<p>Just as Holmes found it interesting that the dog didn&#39;t bark, we should find some of the functions in this notebook interesting for what they don&#39;t include. In many of the functions shown here the arguments aren&#39;t given explicit types.</p>
<p>Knowing the concrete types of arguments is very important when compiling functions, as is done in Julia, but these functions are written without explicit types.</p>
<p>Consider the <code>score</code> function which we reproduce here</p>
<pre><code class="language-julia">function score&#40;guess, target&#41;
    s &#61; 0
    for &#40;g, t&#41; in zip&#40;guess, target&#41;
        s *&#61; 3
        s &#43;&#61; &#40;g &#61;&#61; t&#41; ? 2 : Int&#40;g ∈ target&#41;
    end
    return s
end</code></pre>
<p>The arguments to <code>score</code> can be any type. In fact, formally they are of an abstract type called <code>Any</code>.</p>
<p>So how do we make sure that the actual arguments make sense for this function? Well, the first thing that is done with the arguments is to pass them to <code>zip&#40;guess, target&#41;</code> to produce pairs of values, <code>g</code> and <code>t</code>, that can be compared for equality, <code>g &#61;&#61; t</code>. In a sense <code>score</code> delegates the task of checking that the arguments are sensible to the <code>zip</code> function.</p>
<p>For those unfamiliar with zipping two or more iterators, we can check what the result is.</p>
</div>

<pre class='language-julia'><code class='language-julia'>collect(zip("arise", "rebus"))</code></pre>
<pre id='var-hash198416' class='documenter-example-output'><code class='code-output'>5-element Vector{Tuple{Char, Char}}:
 ('a', 'r')
 ('r', 'e')
 ('i', 'b')
 ('s', 'u')
 ('e', 's')</code></pre>


<div class="markdown"><p>One of the great advantages of dynamically-typed languages with a REPL &#40;read-eval-print-loop&#41; like Julia is that we can easily check what <code>zip</code> produces in a couple of examples &#40;or even read the documentation returned by <code>?zip</code>, if we are desperate&#41;.</p>
<p>The rest of the function is a common pattern - initialize <code>s</code>, which will be the result, modify <code>s</code> in a loop, and return it. The Julia expression</p>
<pre><code class="language-julia">s *&#61; 3</code></pre>
<p>indicates, as in several other languages, that <code>s</code> is to be multiplied by 3 in-place.</p>
<p>An expression like</p>
<pre><code class="language-julia">&#40;g &#61;&#61; t&#41; ? 2 : Int&#40;g  ∈ target&#41;</code></pre>
<p>is a <em>ternary operator</em> expression &#40;the name comes from the operator taking three operands&#41;. It evaluates the condition, <code>g &#61;&#61; t</code>, and returns <code>2</code> if the condition is <code>true</code>. If <code>g &#61;&#61; t</code> is <code>false</code> the operator returns the value of the Boolean expression <code>g  ∈ target</code>, converted to an <code>Int</code>. &#40;The expression could also be written <code>g in target</code>. In the Julia REPL the <code>∈</code> character is created by typing <code>\in&lt;tab&gt;</code>.&#41; The Boolean expression will return <code>false</code> or <code>true</code>, which is promoted to <code>0</code> or <code>1</code> for the <code>&#43;&#61;</code> operation.</p>
<p>The operation of multiplying by 3 and adding 2 or 1 or 0 is an implementation of <a href="https://en.wikipedia.org/wiki/Horner&#37;27s_method">Horner&#39;s method</a> for evaluating a polynomial.</p>
<p>The function is remarkable because it is both general and compact. Even more remarkable is that it will be very, very fast after its first usage triggers compilation. That&#39;s important because this function will be in a &quot;hot loop&quot;. It will be called many, many times when evaluating the next guess.</p>
<p>&#40;Unfortunately, this version doesn&#39;t properly account for cases where a character is repeated in the guess - an example of <a href="https://en.wikipedia.org/wiki/The_Elements_of_Programming_Style">Kernighan and Plauger&#39;s</a> aphorism, &quot;Efficiency often means getting the wrong answer quickly.&quot; We will return to this issue later.&#41;</p>
<p>We won&#39;t go into detail about the Julia compiler except to note that compilation is performed for specific <em>method signatures</em> &#40;or &quot;method instances&quot;&#41; not for general method definitions.</p>
<p>There are several functions and macros in Julia that allow for inspection at different stages of compilation. One of the most useful is the macro <code>@code_warntype</code> which is used to check for situations where type inference has not been successful. Applying it as</p>
<pre><code class="language-julia">julia&gt; @code_warntype score&#40;&quot;arise&quot;, &quot;rebus&quot;&#41;
MethodInstance for score&#40;::String, ::String&#41;
  from score&#40;guess, target&#41; in Main at REPL&#91;1&#93;:1
Arguments
  #self#::Core.Const&#40;score&#41;
  guess::String
  target::String
Locals
  @_4::Union&#123;Nothing, Tuple&#123;Tuple&#123;Char, Char&#125;, Tuple&#123;Int64, Int64&#125;&#125;&#125;
  s::Int64
  @_6::Int64
  t::Char
  g::Char
  @_9::Int64
Body::Int64
...</code></pre>
<p>shows that type inference is based on concrete types &#40;<code>String</code>&#41; for the arguments.</p>
<p>Some argument types are handled more efficiently than others. Without going in to details we note that we can take advantage of the fact that we have exactly 5 characters and convert the elements of <code>words</code> from <code>String</code> to <code>NTuple&#123;5,Char&#125;</code>, which is an ordered, fixed-length homogeneous collection.</p>
<p>Using the <code>@benchmark</code> macro from the <code>BenchmarkTools</code> package gives run times of a few tens of nanoseconds for these arguments, and shows that the function applied to the fixed-length collections is faster.</p>
</div>

<pre class='language-julia'><code class='language-julia'>@benchmark score(guess, target) setup = (guess = "arise"; target = "rebus")</code></pre>
<pre id='var-guess' class='documenter-example-output'><code class='code-output'>BenchmarkTools.Trial: 10000 samples with 964 evaluations.
 Range (min … max):   87.241 ns …  17.381 μs  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):      87.967 ns               ┊ GC (median):    0.00%
 Time  (mean ± σ):   158.179 ns ± 795.327 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

  ▅▇█▆▃▃▃                                                       ▂
  ███████▆█▆█▆▇█▇▅▄▁▅▅▆▆▃▅▄▅▅▆▇▆▆▄▄▄▁▄▄▃▃▅▄▁▁▁▄▁▄▁▁▃▁▃▃▁▁▄▅▆▅▆▅ █
  87.2 ns       Histogram: log(frequency) by time        105 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.</code></pre>


<div class="markdown"><p>New methods can be defined for a generic function like <code>score</code>. A reason for this could be, for example, that the method can more effectively use information from the type.</p>
<p>For example, the <code>NTuple&#123;N,Char&#125;</code> type has exactly <code>N</code> characters - information that can be used in a loop where we can turn off bounds checking.</p>
</div>

<pre class='language-julia'><code class='language-julia'>function score(guess::NTuple{N,Char}, target::NTuple{N,Char}) where {N}
    s = 0
    @inbounds for i = 1:N
        s *= 3
        gi = guess[i]
        s += (gi == target[i]) ? 2 : Int(gi ∈ target)
    end
    return s
end</code></pre>
<pre id='var-score' class='documenter-example-output'><code class='code-output'>score (generic function with 2 methods)</code></pre>


<div class="markdown"><p>This method returns the same result as the other method, only faster.</p>
</div>

<pre class='language-julia'><code class='language-julia'>score(('a', 'r', 'i', 's', 'e'), ('r', 'e', 'b', 'u', 's'))</code></pre>
<pre id='var-hash665656' class='documenter-example-output'><code class='code-output'>31</code></pre>

<pre class='language-julia'><code class='language-julia'>@benchmark score(guess1, target1) setup =
    (guess1 = ('a', 'r', 'i', 's', 'e'); target1 = ('r', 'e', 'b', 'u', 's'))</code></pre>
<pre id='var-guess1' class='documenter-example-output'><code class='code-output'>BenchmarkTools.Trial: 10000 samples with 999 evaluations.
 Range (min … max):  12.012 ns … 56.758 ns  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     13.013 ns              ┊ GC (median):    0.00%
 Time  (mean ± σ):   12.975 ns ±  0.710 ns  ┊ GC (mean ± σ):  0.00% ± 0.00%

               ▆         █                                     
  ▂▃▁▃▁▃▁█▁▂▁▂▁█▁█▁▂▁▆▁█▁█▁█▁▃▁▂▁▂▁▂▁▂▁▂▁▂▁▁▁▁▁▁▁▂▁▂▁▂▁▂▁▂▁▂▂ ▃
  12 ns           Histogram: frequency by time          15 ns <

 Memory estimate: 0 bytes, allocs estimate: 0.</code></pre>


<div class="markdown"><h2>Repeated characters in the guess</h2>
<p>The simple <code>score</code> methods shown above don&#39;t give the correct score &#40;meaning the score that would be returned on the web site&#41; when there are repeated characters in the guess. For example, a guess of <code>&quot;sheer&quot;</code> for the target <code>&quot;super&quot;</code> is scored as</p>
</div>

<pre class='language-julia'><code class='language-julia'>tiles(score("sheer", "super"), 5)</code></pre>
<pre id='var-hash498610' class='documenter-example-output'><code class='code-output'>"🟩🟫🟨🟩🟩"</code></pre>


<div class="markdown"><p>but the score should be <code>&quot;🟩🟫🟫🟩🟩&quot;</code> because there is only one <code>e</code> in the target <code>&quot;super&quot;</code>. In a case like this where a character occurs multiple times in a guess but only once in the target the rules about which position in the guess is marked are that &quot;correct position&quot; takes precedence over &quot;in the word&quot; and, if none of the guess positions are correct, then leftmost takes precedence.</p>
<p>This makes for a considerably more complex score evaluation. Essentially there have to be two passes over the score and target - the first to check for correct position and the second to check for &quot;in the target, not in the correct position&quot;.</p>
<p>However, the simple algorithm in the current <code>score</code> methods works if there are no duplicate characters in the guess. Thus it is probably worthwhile checking for duplicates, using the simple function</p>
<pre><code class="language-julia">function hasdups&#40;guess::NTuple&#123;N,Char&#125;&#41; where &#123;N&#125;
    @inbounds for i in 1:&#40;N - 1&#41;
        gi &#61; guess&#91;i&#93;
        for j in &#40;i &#43; 1&#41;:N
            gi &#61;&#61; guess&#91;j&#93; &amp;&amp; return true
        end
    end
    return false
end</code></pre>
<p>and choose the simple scoring algorithm when there are no duplicates.</p>
<p>In the <a href="https://github.com/dmbates/Wordlegames.jl">Wordlegames</a> package these operations are combined in a <code>scorecolumn&#33;</code> function that updates a vector of scores on a single guess against a vector of targets.</p>
<pre><code class="language-julia">function scorecolumn&#33;&#40;
    col::AbstractVector&#123;&lt;:Integer&#125;,
    guess::NTuple&#123;N,Char&#125;,
    targets::AbstractVector&#123;NTuple&#123;N,Char&#125;&#125;,
&#41; where &#123;N&#125;
    if axes&#40;col&#41; ≠ axes&#40;targets&#41;
        throw&#40;
            DimensionMismatch&#40;
                &quot;axes&#40;col&#41; &#61; &#36;&#40;axes&#40;col&#41;&#41; ≠ &#36;&#40;axes&#40;targets&#41;&#41; &#61; axes&#40;targets&#41;&quot;,
            &#41;
        &#41;
    end
    if hasdups&#40;guess&#41;
        onetoN &#61; &#40;1:N...,&#41;           # 1:N as a Tuple
        svec &#61; zeros&#40;Int, N&#41;         # scores for characters in guess
        unused &#61; trues&#40;N&#41;            # unused positions in targets&#91;i&#93;
        @inbounds for i in axes&#40;targets, 1&#41;
            targeti &#61; targets&#91;i&#93;
            fill&#33;&#40;unused, true&#41;      # reset to all unused
            fill&#33;&#40;svec, 0&#41;           # reset to all guess characters not in target
            for j &#61; 1:N              # first pass for target in same position
                if guess&#91;j&#93; &#61;&#61; targeti&#91;j&#93;
                    unused&#91;j&#93; &#61; false
                    svec&#91;j&#93; &#61; 2
                end
            end
            for j &#61; 1:N              # second pass for match in unused position
                if iszero&#40;svec&#91;j&#93;&#41;
                    for k in onetoN&#91;unused&#93;
                        if guess&#91;j&#93; &#61;&#61; targeti&#91;k&#93;
                            svec&#91;j&#93; &#61; 1
                            unused&#91;k&#93; &#61; false
                            break
                        end
                    end
                end
            end
            sc &#61; 0                   # Horner&#39;s method to evaluate the score
            for s in svec
                sc *&#61; 3
                sc &#43;&#61; s
            end
            col&#91;i&#93; &#61; sc
        end
    else                             # simplified alg. for guess w/o duplicates
        @inbounds for i in axes&#40;targets, 1&#41;
            sc &#61; 0
            targeti &#61; targets&#91;i&#93;
            for j &#61; 1:N
                sc *&#61; 3
                gj &#61; guess&#91;j&#93;
                sc &#43;&#61; &#40;gj &#61;&#61; targeti&#91;j&#93;&#41; ? 2 : Int&#40;gj ∈ targeti&#41;
            end
            col&#91;i&#93; &#61; sc
        end
    end
    return col
end</code></pre>
<p>This is &quot;production code&quot; which has gone through several refinement steps so it may seem a bit daunting at first. However, we can break it down.</p>
<p>First, does it give the desired result?</p>
</div>

<pre class='language-julia'><code class='language-julia'>scores1 = zeros(Int, 1)  # initialize a vector of 1 integer to zero </code></pre>
<pre id='var-scores1' class='documenter-example-output'><code class='code-output'>1-element Vector{Int64}:
 0</code></pre>

<pre class='language-julia'><code class='language-julia'>scorecolumn!(scores1, ('s', 'h', 'e', 'e', 'r'), [('s', 'u', 'p', 'e', 'r')])</code></pre>
<pre id='var-hash138218' class='documenter-example-output'><code class='code-output'>1-element Vector{Int64}:
 170</code></pre>

<pre class='language-julia'><code class='language-julia'>tiles(first(scores1), 5)</code></pre>
<pre id='var-hash148967' class='documenter-example-output'><code class='code-output'>"🟩🟫🟫🟩🟩"</code></pre>


<div class="markdown"><p>We see that the call to <code>scorecolumn&#33;</code> overwrites the contents of the <code>scores1</code> vector with the score for the guess on the first &#40;and only&#41; target.</p>
<p>Thus <code>scorecolumn&#33;</code> is a &quot;mutating function&quot;, meaning that it changes the contents of one or more of its arguments. By convention we give such functions names ending in <code>&quot;&#33;&quot;</code>, as a warning to the user that the function may mutate its arguments. &#40;This is merely a convention; the <code>&quot;&#33;&quot;</code> has no syntactic significance.&#41; Furthermore, the convention is to list any arguments that may be modified first.</p>
<p>The reason this function is called <code>scorecolumn&#33;</code> is because the scores for all possible guesses on all possible targets are evaluated and cached as a matrix in a <code>GamePool</code> object. This may seem extravagant but most methods for determining an initial guess algorithmically will end up evaluating all these scores so it makes sense to save them in an array. In this case the rows correspond to targets and the columns to guesses and evaluating the scores for a single guess against all possible targets updates a column of this matrix.</p>
<p>A section from the upper left corner of this matrix</p>
</div>

<pre class='language-julia'><code class='language-julia'>view(wordle.allscores, 1:7, 1:10)</code></pre>
<pre id='var-hash486941' class='documenter-example-output'><code class='code-output'>7×10 view(::Matrix{UInt8}, 1:7, 1:10) with eltype UInt8:
 0xf2  0xea  0xea  0xd8  0xd8  0xd8  0xd8  0xd8  0xd8  0xd8
 0xea  0xf2  0xec  0xdb  0xd8  0xd8  0xda  0xdb  0xda  0xd8
 0xea  0xec  0xf2  0xdb  0xd9  0xd8  0xda  0xdb  0xda  0xd9
 0xd8  0xd9  0xd9  0xf2  0xea  0xd8  0xd9  0xde  0xd9  0xd8
 0xd8  0xd8  0xdb  0xea  0xf2  0xde  0xd8  0xd8  0xe1  0xe3
 0xd8  0xd8  0xd8  0xd8  0xde  0xf2  0xd8  0xd8  0xe1  0xe4
 0xd8  0xda  0xda  0xdb  0xd8  0xd8  0xf2  0xdc  0xe0  0xd8</code></pre>


<div class="markdown"><p>shows that the scores, which are in the range <code>0:242</code>, are stored as unsigned, 8-bit integers to conserve storage. Even so, the storage required is &#40;2315&#41;² bytes, or over 5 megabytes.</p>
</div>

<pre class='language-julia'><code class='language-julia'>Base.summarysize(wordle.allscores)</code></pre>
<pre id='var-hash875788' class='documenter-example-output'><code class='code-output'>5359265</code></pre>


<div class="markdown"><p>Five megabytes is not a large amount of memory by today&#39;s standards, but for games with larger pools of guesses or targets the storage may start to mount up. In those cases there is provision for <a href="https://en.wikipedia.org/wiki/Memory-mapped_file">memory-mapping</a> the array. The evaluation of the array is multi-threaded when Julia is running with multiple threads.</p>
<p>The scores in the first column,</p>
</div>

<pre class='language-julia'><code class='language-julia'>tiles.(view(wordle.allscores, 1:7, 1), 5)</code></pre>
<pre id='var-hash117505' class='documenter-example-output'><code class='code-output'>7-element Vector{String}:
 "🟩🟩🟩🟩🟩"
 "🟩🟩🟩🟫🟫"
 "🟩🟩🟩🟫🟫"
 "🟩🟩🟫🟫🟫"
 "🟩🟩🟫🟫🟫"
 "🟩🟩🟫🟫🟫"
 "🟩🟩🟫🟫🟫"</code></pre>


<div class="markdown"><p>are for the first guess, &quot;aback&quot;, against the first 7 targets</p>
</div>

<pre class='language-julia'><code class='language-julia'>[String(collect(t)) for t in view(wordle.targetpool, 1:7)]</code></pre>
<pre id='var-hash108801' class='documenter-example-output'><code class='code-output'>7-element Vector{String}:
 "aback"
 "abase"
 "abate"
 "abbey"
 "abbot"
 "abhor"
 "abide"</code></pre>


<div class="markdown"><p>The <code>scorecolumn&#33;</code> function itself uses the <code>axes</code> function in several places. By default Julia uses 1-based indexing but other forms of indexing are allowed. &#40;I am obligated at this point to mention <a href="https://github.com/giordano/StarWarsArrays.jl">StarWarsArrays</a> which begins indexing at 4, 5, 6 then 1, 2, 3 then 7, 8, and 9.&#41;</p>
<p>The call to <code>axes&#40;targets, 1&#41;</code> returns the indices in the first &#40;and only&#41; axis of the <code>target</code> vector. The <code>col</code> and <code>targets</code> arguments are typed as <code>AbstractVector</code>, not <code>Vector</code>, because <code>Vector</code> is a concrete, specific type and we wish to allow for &quot;vector-like&quot; objects such as a one-dimensional view in a multi-dimensional array.</p>
<p>The call to <code>scorecolumn&#33;</code> in the constructor for a <code>GamePool</code> is in the code segment</p>
<pre><code class="language-julia">    S &#61; scoretype&#40;N&#41;
    vtargs &#61; view&#40;guesspool, validtargets&#41;
    allscores &#61; Array&#123;S&#125;&#40;undef, length&#40;vtargs&#41;, length&#40;guesspool&#41;&#41;
    Threads.@threads for j in axes&#40;allscores, 2&#41;
        scorecolumn&#33;&#40;view&#40;allscores, :, j&#41;, guesspool&#91;j&#93;, vtargs&#41;
    end</code></pre>
<p>There are two arrays, <code>svec</code> and <code>unused</code> allocated within the <code>scorecolumn&#33;</code> function when guesses have repeated characters. These are very small arrays but nonetheless we would want to minimize the number of allocations if feasible. This is why the check for duplicate characters is carried out and the allocation of these arrays is done only once per column of <code>allscores</code>. The allocation is done within the function so that it can be called from multiple threads simultaneously without the threads interfering with each other.</p>
<p>The branch for a guess without duplicates is still much faster than for a guess with duplicate characters but neither case is horribly slow.</p>
</div>

<pre class='language-julia'><code class='language-julia'>@benchmark scorecolumn!(col, ('a', 'r', 'i', 's', 'e'), $(wordle.guesspool)) setup =
    (col = zeros(UInt8, length(wordle.guesspool)))</code></pre>
<pre id='var-col' class='documenter-example-output'><code class='code-output'>BenchmarkTools.Trial: 10000 samples with 1 evaluation.
 Range (min … max):  57.600 μs …  4.637 ms  ┊ GC (min … max): 0.00% … 0.00%
 Time  (median):     58.901 μs              ┊ GC (median):    0.00%
 Time  (mean ± σ):   59.797 μs ± 47.045 μs  ┊ GC (mean ± σ):  0.00% ± 0.00%

             █▁                                                
  ▂▂▂▂▃▃▄▅▆▇████▇▆▅▄▃▃▃▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▂▁▁▂▂▁▂▁▂▂▂▂▂▂▂▂▂▂▂▂ ▃
  57.6 μs         Histogram: frequency by time          64 μs <

 Memory estimate: 0 bytes, allocs estimate: 0.</code></pre>


<div class="markdown"><p>Notice that there are no allocations of memory when there are no duplicated characters in the guess. There are allocations, and consequently some garbage collection &#40;GC&#41;, when the guess has duplicated characters.</p>
</div>

<pre class='language-julia'><code class='language-julia'>@benchmark scorecolumn!(col1, ('a', 'b', 'a', 'c', 'k'), $(wordle.guesspool)) setup =
    (col1 = zeros(UInt8, length(wordle.guesspool)))</code></pre>
<pre id='var-col1' class='documenter-example-output'><code class='code-output'>BenchmarkTools.Trial: 1343 samples with 1 evaluation.
 Range (min … max):  3.404 ms …   8.494 ms  ┊ GC (min … max): 0.00% … 48.89%
 Time  (median):     3.446 ms               ┊ GC (median):    0.00%
 Time  (mean ± σ):   3.716 ms ± 982.231 μs  ┊ GC (mean ± σ):  6.24% ± 12.43%

  █▄                                                        ▁  
  ██▇▆█▆▁▃▄▃▁▅▄▄▇▁▄▁▁▁▁▁▃▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▁▃▄██ ▇
  3.4 ms       Histogram: log(frequency) by time       7.7 ms <

 Memory estimate: 2.44 MiB, allocs estimate: 32541.</code></pre>


<div class="markdown"><h2>Conclusion</h2>
<p>These few examples have introduced, at least in passing, several advanced programming concepts - multi-threading, memory-mapping, control of storage allocation and garbage collection - that one typically would not associate with a dynamically-typed, REPL-based language like Julia.</p>
<p>Of course, all of these facilities are available in compiled languages like C/C&#43;&#43; or Rust but usually without the &quot;rapid development and testing&quot; capability of a language like Julia.</p>
<p>Julia provides a wide range of tools so that a programmer can start at a very simple level, like the original <code>score</code> method and refine as needed to reach speeds previously only achievable with compiled, statically-typed languages.</p>
</div>
<div class='manifest-versions'>
<p>Built with Julia 1.7.2 and</p>
BenchmarkTools 1.3.1<br>
PlutoUI 0.7.38<br>
Wordlegames 0.3.0
</div>

<!-- PlutoStaticHTML.End -->
~~~