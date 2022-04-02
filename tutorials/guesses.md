~~~
<!-- PlutoStaticHTML.Begin -->
<!--
    # This information is used for caching.
    [PlutoStaticHTML.State]
    input_sha = "061d3e2c18903b8cfa571a5bda8ab205c4e684a2fc8c6aaff3c5d670d5a4090c"
    julia_version = "1.7.2"
-->




~~~
+++
title = "Selection of guesses"
+++

~~~


<div class="markdown"><h1>Selection of guesses</h1>
<p>The task described in the discourse discussion mentioned in the previous tutorial was to determine an optimal first guess in Wordle, using the criterion of minimizing the expected pool size after the guess is scored.</p>
<p>First attach the packages that will be used </p>
</div>

<pre class='language-julia'><code class='language-julia'>begin
    using CairoMakie      # graphics package
    using Chain           # sophisticated pipes
    using DataFrameMacros # convenient syntax for df operations
    using DataFrames
    using PlutoUI         # User Interface components
    using Primes          # prime numbers
    using Random          # random number generation
    using StatsBase       # basic statistical summaries
    using Wordlegames
end</code></pre>



<div class="markdown"><p>In the Wordle game shown on the <a href="https://en.wikipedia.org/wiki/Wordle">Wikipedia page</a> the first guess is &quot;arise&quot;.</p>
</div>

<pre class='language-julia'><code class='language-julia'>PlutoUI.Resource(
    "https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Wordle_196_example.svg/440px-Wordle_196_example.svg.png",
)</code></pre>
<img src="https://upload.wikimedia.org/wikipedia/commons/thumb/e/ec/Wordle_196_example.svg/440px-Wordle_196_example.svg.png" controls="" type="image/png"></img>


<div class="markdown"><p>Before the guess is scored the size of the target pool is 2315. The score for this guess in this game is 01011 as a base-3 number or 31 as a decimal number. Of all the targets in the target pool, only 20 will return this score.</p>
<p>To verify this, first create a <code>GamePool</code> from the wordle targets.</p>
</div>

<pre class='language-julia'><code class='language-julia'>begin
    datadir = joinpath(pkgdir(Wordlegames), "data")
    wordle = GamePool(collect(readlines(joinpath(datadir, "Wordletargets.txt"))))
end;</code></pre>



<div class="markdown"><p>Then determine the index of &quot;arise&quot; in the guess pool.</p>
</div>

<pre class='language-julia'><code class='language-julia'>only(findall(x -&gt; x == ('a', 'r', 'i', 's', 'e'), wordle.guesspool))</code></pre>
<pre id='var-anon12316509576919843971' class='documenter-example-output'><code class='code-output'>106</code></pre>


<div class="markdown"><p>Here, <code>findall</code> returns a vector of all positions in <code>wordle.guesspool</code> that return <code>true</code> from the anonymous function checking if the argument, <code>x</code>, is equal to <code>&#40;&#39;a&#39;, &#39;r&#39;, &#39;i&#39;, &#39;s&#39;, &#39;e&#39;&#41;</code>. The <code>only</code> function checks that there is only one such index and, if so, returns it.</p>
<p>The anonymous function to compare an element of <code>wordle.guesspool</code> to <code>&#40;&#39;a&#39;,&#39;r&#39;,&#39;i&#39;,&#39;s&#39;,&#39;e&#39;&#41;</code> can be written more compactly as <code>&#61;&#61;&#40;&#40;&#39;a&#39;,&#39;r&#39;,&#39;i&#39;,&#39;s&#39;,&#39;e&#39;&#41;&#41;</code>.</p>
<p>The score for the guess <code>&quot;arise&quot;</code> on the target <code>&quot;rebus&quot;</code> is 31 as a decimal number.</p>
</div>

<pre class='language-julia'><code class='language-julia'>Int(wordle.allscores[only(findall(==(('r', 'e', 'b', 'u', 's')), wordle.guesspool)), 106])</code></pre>
<pre id='var-hash307308' class='documenter-example-output'><code class='code-output'>31</code></pre>


<div class="markdown"><p>Next, check how many of the pre-computed scores in the 106th column of <code>wordle.allscores</code> are equal to 31.</p>
</div>

<pre class='language-julia'><code class='language-julia'>sum(==(31), view(wordle.allscores, :, 106))</code></pre>
<pre id='var-hash334286' class='documenter-example-output'><code class='code-output'>20</code></pre>


<div class="markdown"><p>A <code>view</code> provides access to a subarray of an array without copying the contents. In this case the subarray is all the rows &#40;the <code>:</code> argument in the rows position&#41; and the 106th column. The comparison function <code>&#61;&#61;&#40;31&#41;</code> will return <code>true</code> or <code>false</code>, values that will be converted for <code>1</code> or <code>0</code> for the summation function <code>sum</code>. Thus <code>sum&#40;&#61;&#61;&#40;31&#41;, v&#41;</code> returns the number of elements of <code>v</code> that are equal to 31.</p>
</div>


<div class="markdown"><h2>The distribution of scores for a guess</h2>
<p>In this case the first guess reduced the size of the target pool from 2315 to 20, after this guess was scored. Ideally we want a guess to reduce the size of the target pool as much as possible but we don&#39;t know what the score is going to be. However, we can evaluate the distribution of pool sizes that will result from a particular guess.</p>
<p>To do this we &quot;bin&quot; the scores for a guess on the active targets into the 243 possible values for an <code>NTuple&#123;5,Char&#125;</code>.</p>
</div>

<pre class='language-julia'><code class='language-julia'>bincounts!(wordle, 106).counts</code></pre>
<pre id='var-hash151090' class='documenter-example-output'><code class='code-output'>243-element Vector{Int64}:
 168
 121
  61
  80
  41
  17
  17
   ⋮
   0
   0
   0
   0
   0
   1</code></pre>


<div class="markdown"><p>The <code>i</code>&#39;th element of this vector is the number of targets that will give a score of <code>i - 1</code> for <code>guess &#61; wordle.guesspool&#91;106&#93;</code>, which is <code>&quot;arise&quot;</code></p>
<p>The most common score is <code>0</code> which is returned for 168 of the 2315 targets currently in the target pool.</p>
</div>

<pre class='language-julia'><code class='language-julia'>sum(iszero, view(wordle.allscores, :, 106))</code></pre>
<pre id='var-hash103530' class='documenter-example-output'><code class='code-output'>168</code></pre>


<div class="markdown"><p>Collecting the bin sizes and the corresponding scores in a data frame allows us to sort them by decreasing count size and eliminate the scores that give counts of zero.</p>
</div>

<pre class='language-julia'><code class='language-julia'>df106 = @chain DataFrame(score=tiles.(0:242, 5), counts=wordle.counts) begin
    @subset(:counts &gt; 0)
    sort(:counts; rev=true)
end</code></pre>
<table>
<tr>
<th>score</th>
<th>counts</th>
</tr>
<tr>
<td>"🟫🟫🟫🟫🟫"</td>
<td>168</td>
</tr>
<tr>
<td>"🟨🟫🟫🟫🟫"</td>
<td>154</td>
</tr>
<tr>
<td>"🟫🟫🟫🟫🟨"</td>
<td>121</td>
</tr>
<tr>
<td>"🟫🟫🟨🟫🟫"</td>
<td>107</td>
</tr>
<tr>
<td>"🟫🟨🟫🟫🟨"</td>
<td>100</td>
</tr>
<tr>
<td>"🟫🟫🟫🟨🟫"</td>
<td>80</td>
</tr>
<tr>
<td>"🟨🟫🟫🟫🟨"</td>
<td>79</td>
</tr>
<tr>
<td>"🟫🟨🟫🟫🟫"</td>
<td>64</td>
</tr>
<tr>
<td>"🟨🟨🟫🟫🟫"</td>
<td>62</td>
</tr>
<tr>
<td>"🟫🟫🟫🟫🟩"</td>
<td>61</td>
</tr>
<tr>
<td>...</td>
</tr>
<tr>
<td>"🟩🟩🟩🟩🟩"</td>
<td>1</td>
</tr>
</table>



<div class="markdown"><p>A bar plot of the bin sizes, ordered from largest to smallest is</p>
</div>

<pre class='language-julia'><code class='language-julia'>barplot(df106.counts)</code></pre>
<img src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAyAAAAJYCAIAAAAVFBUnAAAABmJLR0QA/wD/AP+gvaeTAAAgAElEQVR4nO3dfXxV9YHg/3OTe/NAHghJeBYMBKEUKVA7VmuxwCja3ZbpTB9n1L6UcX3Nur92tPX3e/nq+tt1frN19jXOWndmOjvaGfqwLO30NXUL22oVYWh9qGhFURBRkERAJJKQkOfcm3t/f9zkEqUKON/khuT9fvnH+Z5zcvKNnoMfzrm5N5bJZCIAAMIpyPcEAADGGoEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgcXzPYHTuPfee59//vm6urp8TwQAGKcaGhqWLl16yy23nPmXjPY7WM8//3xDQ8NwHLmnp6evr284jgxjSTKZ7OrqyvcsYLRLp9Pt7e35ngXDpaGh4fnnnz+rLxntd7Dq6urq6uruvPPO4Ec+fvx4PB6vqKgIfmQYSzo7O7u7u2tra/M9ERjVUqlUU1PTjBkz8j0RhsX76JDRfgcLAOCcI7AAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgsHi+JzAqbHn1WGt3Mru8cGr5B6dW5Hc+AMA5TWBFURT9w/bGV9/qzC7f+NHZAgsA+NfwiBAAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwOL5nsBotL+569lDrdnlknjhmkVT8zsfAODcIrB+ix2HWv9y677scvWEIoEFAJwVjwgBAAITWAAAgQksAIDABBYAQGBnHVjpdHrLli033HBDZWVlLBZraGgYuvXRRx+NvV1tbe3QHZqamq677rrq6ury8vKrrrpq9+7d/8ofAABgtDnrwNq+fftdd921fPny22677d32efHFFzODjh07llufTCZXr169b9++HTt2NDY21tTUrFix4siRI+9z7gAAo9JZB9all166ZcuWtWvXVlZWnu3XbtiwYefOnevWraurq6upqbn//vv7+vruvvvusz0OAMBoNqKvwdq0aVN9ff3ChQuzw/Ly8lWrVm3cuHEk5wAAMNyGJbBWrlyZSCSmT59+ww03HD58OLd+9+7d8+fPH7rnggULDhw40N3dPRzTAADIi8Dv5F5cXHzHHXdce+21M2bMeOqpp26++eZLLrlkx44dkydPjqKopaVl2bJlQ/evqqrKZDKtra2lpaVRFB0+fPjQoUNDd2hvb58wYUJfX1/YeUZR1NfXl06ns0dOp9OZTCa7PpVKpVIFuWFuHxif+gbleyIwqqVSqWQy6UoZq/r7+wsLC8/qSwIH1vLly5cvX55dvvLKKx944IElS5bce++93/zmN6MoylVLzjvWPPTQQ9/5zneGrpk6der8+fNbWlrCzjOKora2tsLCwmQyGUVRX19fKpXKru/q6irOnBymUrHh+O5wrujq6urp6Sko8JYu8F5SqdTx48eLi4vzPRGGRXd3d3l5+Vl9yfB+FuHixYtnzZq1ffv27LC6urqtrW3oDm1tbbFYrKqqKju88cYbb7zxxqE73HnnnVEUTZs2LfjciouL4/F4RUVFFEUlJYcTif7s+srKyqqyokRi4Jcfi4qKhuO7w7mis7Ozu7v7He+3ArxDKpUqKCjw/4ux6mzrKhrhF7kvWrTolVdeGbpm7969c+bMyT4fBAAYG4Y3sHbt2nXw4MGLL744O1yzZs3+/fv37NmTHXZ0dGzdunXNmjXDOgcAgBEWOLBuvPHG9evXNzY2dnR0bNmy5bOf/eyMGTNuueWW7NZrrrlm8eLFa9eubWhoaG5uvummmxKJxHu8YSkAwLnorAMrlUplPwPn1ltvjaJozpw5sVjsU5/6VHbr7bff/thjj61cubK6uvr666+//PLLn3766SlTpmS3JhKJzZs319fXL1u2bPbs2ceOHdu2bdvMmTMD/jwAAHl31i9yj8fjp/4yYM68efPuu+++9/jyqVOnrl+//my/KQDAOcSvXgMABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAILB4vidwDkhnMtf8rx254dc/Uf+RWVV5nA8AMMoJrDMRe/Wtztygo68/j1MBAEY/jwgBAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACCye7wmck+5/qvHRV45ll5fOrPzG716Q3/kAAKOKwHo/mtp7X2vuzC5PrSjK72QAgNHGI0IAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAENhZB1Y6nd6yZcsNN9xQWVkZi8UaGhresUNTU9N1111XXV1dXl5+1VVX7d69+8y3AgCMAWcdWNu3b7/rrruWL19+2223nbo1mUyuXr163759O3bsaGxsrKmpWbFixZEjR85kKwDA2HDWgXXppZdu2bJl7dq1lZWVp27dsGHDzp07161bV1dXV1NTc//99/f19d19991nshUAYGwI/BqsTZs21dfXL1y4MDssLy9ftWrVxo0bz2QrAMDYEDiwdu/ePX/+/KFrFixYcODAge7u7tNuBQAYGwIHVktLy8SJE4euqaqqymQyra2tp90KADA2xMMeLpPJvMea994aRdG3v/3tv/3bvx26Zu7cuQsXLhyOF8K3tbUVFhZ2dHREUdTd3Z1MJnPrC/riuWFvb+bIkSO5YRRFzc3N7e3tuTWdnZ2vNBzccaQzt8MlsyqLC2PBJwx50dXV1dPTM/QSAE6VSqWam5tjMX/4j00dHR3l5eVn9SWBA6u6urqtrW3omra2tlgsVlVVddqtURR98YtfXLVq1dAdvvvd75aUlNTW1oadZxRFhYWF8Xi8oqIiiqLi4kPxeH92fXl5eWVZUTx+LDssKiqqra2Nx0/+i5o4ceKElv54vCM7LC0t7UmU3/3r13I7/O/5M2srS4JPGPKis7Ozu7t7OK5BGEtSqVQmk3GljFUTJkw42y8JHFiLFi164YUXhq7Zu3fvnDlzSktLT7s1iqLa2tp3nJ3ZHymRSISdZ/aY8Xg8e+SCgoLcXzsKCwsLCwtzw1gslkgkhv6lJB6PD92hoKAgHo8P3SGRSAzHhCEvEolEKpVySsN7i8Viuf+nMPYUFJz1S6oCvwZrzZo1+/fv37NnT3bY0dGxdevWNWvWnMlWAICxIXBgXXPNNYsXL167dm1DQ0Nzc/NNN92USCRyb0n63lsBAMaGsw6sVCoVi8Visditt94aRdGcOXNisdinPvWp7NZEIrF58+b6+vply5bNnj372LFj27Ztmzlz5plsBQAYG876NVjxePzUXwYcaurUqevXr39/WwEAxoDAjwgBABBYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYPF8T2BsuvPhva81d2aXP71o2ueXzMjvfACAkSSwhsX+5q49RzuyyxfP7s3vZACAEeYRIQBAYO5gjYRH9jZ9+4mG7HJFcXz9NR/O63QAgOElsEZCZ1//4bae7HJlSSK/kwEAhptHhAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDA4vmewDi14u+eTGcy2eU/u2rBynm1+Z0PABCQwMqPrr7+XGCl0pn8TgYACMsjQgCAwAQWAEBgAgsAIDCvwRoVOvv6e1L92eVEQayyJJHf+QAA/xoCa1T4m8cP/PPON7LLvzOr6n987kP5nQ8A8K/hESEAQGDuYI1Gfan0obae3HBWVclbnX09yXR2WFWaKCqMNXX0ZYcFsaiuekIeZgkAvAuBNRo1Hu/+w/XP5oYPXP87//nhvS8eOZEdXnvRefNqy+58eG92WJoofOz/uiwPswQA3oVHhAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQUOrEcffTT2drW1tUN3aGpquu6666qrq8vLy6+66qrdu3eHnQAAQN4Nyx2sF198MTPo2LFjufXJZHL16tX79u3bsWNHY2NjTU3NihUrjhw5MhxzAADIlxF9RLhhw4adO3euW7eurq6upqbm/vvv7+vru/vuu0dyDgAAwy0+kt9s06ZN9fX1CxcuzA7Ly8tXrVq1cePGe+65ZySnMSZ95rvP9KXS2eX/e2X9ynm1770/ADB8huUO1sqVKxOJxPTp02+44YbDhw/n1u/evXv+/PlD91ywYMGBAwe6u7uHYxrjSlNHb+6fnmQ639MBgHEt8B2s4uLiO+6449prr50xY8ZTTz118803X3LJJTt27Jg8eXIURS0tLcuWLRu6f1VVVSaTaW1tLS0tjaLoiSeeePzxx4fucPDgwSlTppw4cSLsPKMoam9vj8fjmUwmiqJkMtnf359d39PT013QnxumUqkTJ07k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z7UDpzrtdeHCGbfGXWDt3r17/vz5Q9csWLDgwIED3d3d+ZoSjB4rV65MJBLTp0+/4YYbDh8+PHSTawdOddrrwoUzbo27wGppaZk4ceLQNVVVVZlMprW1NV9TgtGguLj4jjvuePzxx1taWn7wgx88/vjjl1xyyVtvvZXbwbUDpzrtdeHCGbfGXWBlTvlooFPXwDi0fPnyP//zP1+wYEFFRcWVV175wAMPHD58+N57783t4NqBU532unDhjFvjLrCqq6vb2tqGrmlra4vFYj74GYZavHjxrFmztm/fnlvj2oFTnfa6cOGMW+MusBYtWvTKK68MXbN37945c+aUlpbma0pwTnDtwKlOe124cMatcRdYa9as2b9//549e7LDjo6OrVu3rlmzJr+zgtFm165dBw8evPjii3NrXDtwqtNeFy6ccSs23h4GJ5PJiy66qKys7Ic//GFFRcVXvvKVRx55ZOfOnTNnzsz31CCfbrzxxhUrVixfvrympmb79u0333xzZ2fnjh07pkyZkt3BtcM4d++99956660HDhyoq6vLrTztdeHCGbfG3R2sRCKxefPm+vr6ZcuWzZ49+9ixY9u2bXOiw+233/7YY4+tXLmyurr6+uuvv/zyy59++ulcXUWuHcarVCqV/fCoW2+9NYqiOXPmxGKxT33qU9mtp70uXDjj1ri7gwUAMNzG3R0sAIDhJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAL7/wGrPLP85htNYQAAAABJRU5ErkJggg==">


<div class="markdown"><p>The <code>Wordlegames</code> package provides two algorithms of choosing a guess based on the distribution of the scores.</p>
<pre><code class="language-julia">function optimalguess&#40;gp::GamePool&#123;N,S,MaximizeEntropy&#125;&#41; where &#123;N,S&#125;
    gind, xpctd, entrpy &#61; 0, Inf, -Inf
    for &#40;k, a&#41; in enumerate&#40;gp.active&#41;
        if a
            thisentropy &#61; entropy2&#40;bincounts&#33;&#40;gp, k&#41;&#41;
            if thisentropy &gt; entrpy
                gind, xpctd, entrpy &#61; k, expectedpoolsize&#40;gp&#41;, thisentropy
            end
        end
    end
    return gind, xpctd, entrpy
end

function optimalguess&#40;gp::GamePool&#123;N,S,MinimizeExpected&#125;&#41; where &#123;N,S&#125;
    gind, xpctd, entrpy &#61; 0, Inf, -Inf
    for &#40;k, a&#41; in enumerate&#40;gp.active&#41;
        if a
            thisexpected &#61; expectedpoolsize&#40;bincounts&#33;&#40;gp, k&#41;&#41;
            if thisexpected &lt; xpctd
                gind, xpctd, entrpy &#61; k, thisexpected, entropy2&#40;gp&#41;
            end
        end
    end
    return gind, xpctd, entrpy
end</code></pre>
<p>The first method is to maximize the <a href="https://en.wikipedia.org/wiki/Entropy_&#40;information_theory&#41;">entropy</a> of the distribution, which is an information-theory concept that measures how &quot;spread out&quot; the distribution is. It depends only on the probabilities of the scores, not on the scores themselves. The base-2 entropy, measured in bits, of a discrete distribution with probabilities <span class="tex">$p_i, i&#61;1,\dots,n$</span> is defined as</p>
<p class="tex">$$H_2&#40;X&#41; &#61; - \sum_&#123;i&#61;1&#125;^n p_i\,\log_2&#40;p_i&#41;$$</p>
<p>The <code>Wordlegames</code> package exports the <code>entropy2</code> function that returns this quantity from the current <code>counts</code>.</p>
<pre><code class="language-julia">function entropy2&#40;counts::AbstractVector&#123;&lt;:Real&#125;&#41;
    countsum &#61; sum&#40;counts&#41;
    return -sum&#40;counts&#41; do k
        x &#61; k / countsum
        xlogx &#61; x * log&#40;x&#41;
        iszero&#40;x&#41; ? zero&#40;xlogx&#41; : xlogx
    end / log&#40;2&#41;
end

entropy2&#40;gp::GamePool&#41; &#61; entropy2&#40;gp.counts&#41;</code></pre>
</div>

<pre class='language-julia'><code class='language-julia'>entropy2(wordle.counts)</code></pre>
<pre id='var-hash179091' class='documenter-example-output'><code class='code-output'>5.820939700886001</code></pre>


<div class="markdown"><p>or, equivalently</p>
</div>

<pre class='language-julia'><code class='language-julia'>entropy2(bincounts!(wordle, 106))</code></pre>
<pre id='var-hash170596' class='documenter-example-output'><code class='code-output'>5.820939700886001</code></pre>


<div class="markdown"><p>The</p>
<pre><code class="language-julia">... do k
   ...
end</code></pre>
<p>block, called a &quot;thunk&quot;, in this code - yet another way of writing an anonymous function - is described later.</p>
<p>Roughly, the numerical result means that the distribution of target pool sizes after an initial guess of <code>&quot;arise&quot;</code> is, according to this measure, about as spread out as a uniform distribution on 56.5 possible responses.</p>
</div>

<pre class='language-julia'><code class='language-julia'>2^(entropy2(wordle))</code></pre>
<pre id='var-hash112384' class='documenter-example-output'><code class='code-output'>56.529800516800876</code></pre>


<div class="markdown"><p>The second method is to minimize the expected pool size after the guess is scored.</p>
<p>By definition this is the sum of the bin size &#40;or count&#41; for each of the bins multiplied by the probability of the target being in the bin. But that probability is the bin size divided by the total number of active targets. Thus the expected pool size after the guess can be evaluated from the bin sizes alone.</p>
<pre><code class="language-julia">function expectedpoolsize&#40;gp::GamePool&#41;
    return sum&#40;abs2, gp.counts&#41; / sum&#40;gp.counts&#41;
end</code></pre>
</div>

<pre class='language-julia'><code class='language-julia'>sum(abs2, wordle.counts) / sum(wordle.counts)   # abs2(x) returns x * x </code></pre>
<pre id='var-hash215474' class='documenter-example-output'><code class='code-output'>63.72570194384449</code></pre>


<div class="markdown"><p>which is available as <code>expectedpoolsize</code></p>
</div>

<pre class='language-julia'><code class='language-julia'>expectedpoolsize(bincounts!(wordle, 106))</code></pre>
<pre id='var-hash119196' class='documenter-example-output'><code class='code-output'>63.72570194384449</code></pre>


<div class="markdown"><p>This is a measure of how successful an initial guess of <code>&quot;arise&quot;</code> will be. On average it will reduce the target pool size from 2315 to 63.73.</p>
</div>


<div class="markdown"><h2>The best initial guess?</h2>
<p>We can choose an initial guess &#40;and, also, subsequent guesses&#41; to maximize the entropy of the distribution of scores or to minimize the expected pool size for the next guess.</p>
<p>For both of these criteria, a slight modification on <code>&quot;arise&quot;</code>, exchanging the first two letters to form <code>&quot;raise&quot;</code>, at index 1535, is a bit better than <code>&quot;arise&quot;</code>.</p>
</div>

<pre class='language-julia'><code class='language-julia'>string(wordle.guesspool[1535]...)</code></pre>
<pre id='var-hash123092' class='documenter-example-output'><code class='code-output'>"raise"</code></pre>

<pre class='language-julia'><code class='language-julia'>entropy2(bincounts!(wordle, 1535))</code></pre>
<pre id='var-hash942919' class='documenter-example-output'><code class='code-output'>5.877909690821478</code></pre>

<pre class='language-julia'><code class='language-julia'>expectedpoolsize(wordle)</code></pre>
<pre id='var-hash127239' class='documenter-example-output'><code class='code-output'>61.00086393088553</code></pre>


<div class="markdown"><p>It turns out that <code>&quot;raise&quot;</code> is the best initial guess for both of these criteria, if we restrict outselves to guesses from the initial target pool.</p>
<p>One of the parameters of the <code>GamePool</code> type is the method of choosing the next guess, either <code>MaximizeEntropy</code>, the default, or <code>MinimizeExpected</code>,</p>
</div>

<pre class='language-julia'><code class='language-julia'>typeof(wordle)</code></pre>
<pre id='var-hash183740' class='documenter-example-output'><code class='code-output'>GamePool{5, UInt8, MaximizeEntropy}</code></pre>


<div class="markdown"><p>allowing for automatic game play.</p>
</div>

<pre class='language-julia'><code class='language-julia'>showgame!(wordle, "rebus")</code></pre>
<table>
<tr>
<th>poolsz</th>
<th>index</th>
<th>guess</th>
<th>expected</th>
<th>entropy</th>
<th>score</th>
<th>sc</th>
</tr>
<tr>
<td>2315</td>
<td>1535</td>
<td>"raise"</td>
<td>61.0009</td>
<td>5.87791</td>
<td>"🟩🟫🟫🟨🟨"</td>
<td>166</td>
</tr>
<tr>
<td>2</td>
<td>1558</td>
<td>"rebus"</td>
<td>1.0</td>
<td>1.0</td>
<td>"🟩🟩🟩🟩🟩"</td>
<td>242</td>
</tr>
</table>



<div class="markdown"><p>That game ended suspiciously quickly but notice that, after the first guess, <code>&quot;raise&quot;</code>, is scored as <code>🟩🟫🟫🟨🟨</code> in tiles or 166 in decimal, the target pool size is reduced to 2,</p>
</div>

<pre class='language-julia'><code class='language-julia'>[string(wordle.targetpool[i]...) for i in findall(==(166), view(wordle.allscores, :, 1535))]</code></pre>
<pre id='var-hash121522' class='documenter-example-output'><code class='code-output'>2-element Vector{String}:
 "rebus"
 "reset"</code></pre>


<div class="markdown"><p>giving a 50&#37; chance of a correct second guess.</p>
<p>In the case of ties like this the target with the lowest index in the targetpool is returned. This strategy can result in long series of guesses trying to isolate a single letter if that letter is toward the end of the alphabet</p>
</div>

<pre class='language-julia'><code class='language-julia'>showgame!(wordle, "watch")</code></pre>
<table>
<tr>
<th>poolsz</th>
<th>index</th>
<th>guess</th>
<th>expected</th>
<th>entropy</th>
<th>score</th>
<th>sc</th>
</tr>
<tr>
<td>2315</td>
<td>1535</td>
<td>"raise"</td>
<td>61.0009</td>
<td>5.87791</td>
<td>"🟫🟩🟫🟫🟫"</td>
<td>54</td>
</tr>
<tr>
<td>91</td>
<td>2012</td>
<td>"tangy"</td>
<td>7.48352</td>
<td>4.03061</td>
<td>"🟨🟩🟫🟫🟫"</td>
<td>135</td>
</tr>
<tr>
<td>13</td>
<td>334</td>
<td>"caput"</td>
<td>2.84615</td>
<td>2.4997</td>
<td>"🟨🟩🟫🟫🟨"</td>
<td>136</td>
</tr>
<tr>
<td>5</td>
<td>160</td>
<td>"batch"</td>
<td>3.4</td>
<td>0.721928</td>
<td>"🟫🟩🟩🟩🟩"</td>
<td>80</td>
</tr>
<tr>
<td>4</td>
<td>959</td>
<td>"hatch"</td>
<td>2.5</td>
<td>0.811278</td>
<td>"🟫🟩🟩🟩🟩"</td>
<td>80</td>
</tr>
<tr>
<td>3</td>
<td>1102</td>
<td>"latch"</td>
<td>1.66667</td>
<td>0.918296</td>
<td>"🟫🟩🟩🟩🟩"</td>
<td>80</td>
</tr>
<tr>
<td>2</td>
<td>1206</td>
<td>"match"</td>
<td>1.0</td>
<td>1.0</td>
<td>"🟫🟩🟩🟩🟩"</td>
<td>80</td>
</tr>
<tr>
<td>1</td>
<td>2233</td>
<td>"watch"</td>
<td>1.0</td>
<td>-0.0</td>
<td>"🟩🟩🟩🟩🟩"</td>
<td>242</td>
</tr>
</table>



<div class="markdown"><p>but it is not clear that any other strategy will be more successful across all possible targets. &#40;This target did occur on the official Wordle web site in March of 2022.&#41;</p>
<p>To play by the <code>MinimizeExpected</code> strategy requires specifying this as the <code>guesstype</code> when creating the <code>GamePool</code>.</p>
</div>

<pre class='language-julia'><code class='language-julia'>wordlexpct = GamePool(
    collect(readlines(joinpath(datadir, "Wordletargets.txt")));
    guesstype=MinimizeExpected,
);</code></pre>


<pre class='language-julia'><code class='language-julia'>showgame!(wordlexpct, "rebus")</code></pre>
<table>
<tr>
<th>poolsz</th>
<th>index</th>
<th>guess</th>
<th>expected</th>
<th>entropy</th>
<th>score</th>
<th>sc</th>
</tr>
<tr>
<td>2315</td>
<td>1535</td>
<td>"raise"</td>
<td>61.0009</td>
<td>5.87791</td>
<td>"🟩🟫🟫🟨🟨"</td>
<td>166</td>
</tr>
<tr>
<td>2</td>
<td>1558</td>
<td>"rebus"</td>
<td>1.0</td>
<td>1.0</td>
<td>"🟩🟩🟩🟩🟩"</td>
<td>242</td>
</tr>
</table>


<pre class='language-julia'><code class='language-julia'>showgame!(wordlexpct, "watch")</code></pre>
<table>
<tr>
<th>poolsz</th>
<th>index</th>
<th>guess</th>
<th>expected</th>
<th>entropy</th>
<th>score</th>
<th>sc</th>
</tr>
<tr>
<td>2315</td>
<td>1535</td>
<td>"raise"</td>
<td>61.0009</td>
<td>5.87791</td>
<td>"🟫🟩🟫🟫🟫"</td>
<td>54</td>
</tr>
<tr>
<td>91</td>
<td>2012</td>
<td>"tangy"</td>
<td>7.48352</td>
<td>4.03061</td>
<td>"🟨🟩🟫🟫🟫"</td>
<td>135</td>
</tr>
<tr>
<td>13</td>
<td>334</td>
<td>"caput"</td>
<td>2.84615</td>
<td>2.4997</td>
<td>"🟨🟩🟫🟫🟨"</td>
<td>136</td>
</tr>
<tr>
<td>5</td>
<td>160</td>
<td>"batch"</td>
<td>3.4</td>
<td>0.721928</td>
<td>"🟫🟩🟩🟩🟩"</td>
<td>80</td>
</tr>
<tr>
<td>4</td>
<td>959</td>
<td>"hatch"</td>
<td>2.5</td>
<td>0.811278</td>
<td>"🟫🟩🟩🟩🟩"</td>
<td>80</td>
</tr>
<tr>
<td>3</td>
<td>1102</td>
<td>"latch"</td>
<td>1.66667</td>
<td>0.918296</td>
<td>"🟫🟩🟩🟩🟩"</td>
<td>80</td>
</tr>
<tr>
<td>2</td>
<td>1206</td>
<td>"match"</td>
<td>1.0</td>
<td>1.0</td>
<td>"🟫🟩🟩🟩🟩"</td>
<td>80</td>
</tr>
<tr>
<td>1</td>
<td>2233</td>
<td>"watch"</td>
<td>1.0</td>
<td>-0.0</td>
<td>"🟩🟩🟩🟩🟩"</td>
<td>242</td>
</tr>
</table>



<div class="markdown"><p>There are no differences between the two strategies in these games.</p>
<p>However, if we play all possible games using each of the two strategies and count the number of guesses to solution we can see that the two strategies do not always give the same length of game.</p>
</div>

<pre class='language-julia'><code class='language-julia'>gamelen = let
    inds = axes(wordle.targetpool, 1)
    DataFrame(;
        index=inds,
        entropy=[length(playgame!(wordle, k).guesses) for k in inds],
        expected=[length(playgame!(wordlexpct, k).guesses) for k in inds],
    )
end</code></pre>
<table>
<tr>
<th>index</th>
<th>entropy</th>
<th>expected</th>
</tr>
<tr>
<td>1</td>
<td>3</td>
<td>3</td>
</tr>
<tr>
<td>2</td>
<td>3</td>
<td>3</td>
</tr>
<tr>
<td>3</td>
<td>3</td>
<td>3</td>
</tr>
<tr>
<td>4</td>
<td>4</td>
<td>4</td>
</tr>
<tr>
<td>5</td>
<td>3</td>
<td>4</td>
</tr>
<tr>
<td>6</td>
<td>4</td>
<td>3</td>
</tr>
<tr>
<td>7</td>
<td>3</td>
<td>3</td>
</tr>
<tr>
<td>8</td>
<td>4</td>
<td>4</td>
</tr>
<tr>
<td>9</td>
<td>3</td>
<td>3</td>
</tr>
<tr>
<td>10</td>
<td>3</td>
<td>3</td>
</tr>
<tr>
<td>...</td>
</tr>
<tr>
<td>2315</td>
<td>5</td>
<td>4</td>
</tr>
</table>



<div class="markdown"><p>For example,</p>
</div>

<pre class='language-julia'><code class='language-julia'>showgame!(wordle, 5)</code></pre>
<table>
<tr>
<th>poolsz</th>
<th>index</th>
<th>guess</th>
<th>expected</th>
<th>entropy</th>
<th>score</th>
<th>sc</th>
</tr>
<tr>
<td>2315</td>
<td>1535</td>
<td>"raise"</td>
<td>61.0009</td>
<td>5.87791</td>
<td>"🟫🟨🟫🟫🟫"</td>
<td>27</td>
</tr>
<tr>
<td>92</td>
<td>766</td>
<td>"float"</td>
<td>4.54348</td>
<td>4.86323</td>
<td>"🟫🟫🟨🟨🟩"</td>
<td>14</td>
</tr>
<tr>
<td>1</td>
<td>5</td>
<td>"abbot"</td>
<td>1.0</td>
<td>-0.0</td>
<td>"🟩🟩🟩🟩🟩"</td>
<td>242</td>
</tr>
</table>



<div class="markdown"><p>is different from</p>
</div>

<pre class='language-julia'><code class='language-julia'>showgame!(wordlexpct, 5)</code></pre>
<table>
<tr>
<th>poolsz</th>
<th>index</th>
<th>guess</th>
<th>expected</th>
<th>entropy</th>
<th>score</th>
<th>sc</th>
</tr>
<tr>
<td>2315</td>
<td>1535</td>
<td>"raise"</td>
<td>61.0009</td>
<td>5.87791</td>
<td>"🟫🟨🟫🟫🟫"</td>
<td>27</td>
</tr>
<tr>
<td>92</td>
<td>414</td>
<td>"cloak"</td>
<td>4.17391</td>
<td>4.64926</td>
<td>"🟫🟫🟨🟨🟫"</td>
<td>12</td>
</tr>
<tr>
<td>5</td>
<td>88</td>
<td>"annoy"</td>
<td>1.0</td>
<td>2.32193</td>
<td>"🟩🟫🟫🟩🟫"</td>
<td>168</td>
</tr>
<tr>
<td>1</td>
<td>5</td>
<td>"abbot"</td>
<td>1.0</td>
<td>-0.0</td>
<td>"🟩🟩🟩🟩🟩"</td>
<td>242</td>
</tr>
</table>



<div class="markdown"><p>The mean and standard deviation of the game lengths are smaller when maximizing the entropy than when minimizing the expected pool size.</p>
</div>

<pre class='language-julia'><code class='language-julia'>describe(gamelen[!, [:entropy, :expected]], :min, :max, :mean, :std)</code></pre>
<table>
<tr>
<th>variable</th>
<th>min</th>
<th>max</th>
<th>mean</th>
<th>std</th>
</tr>
<tr>
<td>:entropy</td>
<td>1</td>
<td>8</td>
<td>3.59914</td>
<td>0.849016</td>
</tr>
<tr>
<td>:expected</td>
<td>1</td>
<td>8</td>
<td>3.62462</td>
<td>0.857827</td>
</tr>
</table>



<div class="markdown"><p>The counts of the game lengths under the two strategies and a comparative barplot show the shift toward shorter game lengths when maximizing the entropy.</p>
</div>

<pre class='language-julia'><code class='language-julia'>gamelengths = let
    entropy = countmap(gamelen.entropy)
    expected = countmap(gamelen.expected)
    allcounts = 1:maximum(union(keys(entropy), keys(expected)))
    DataFrame(;
        count=allcounts,
        entropy=[get!(entropy, k, 0) for k in allcounts],
        expected=[get!(expected, k, 0) for k in allcounts],
    )
end</code></pre>
<table>
<tr>
<th>count</th>
<th>entropy</th>
<th>expected</th>
</tr>
<tr>
<td>1</td>
<td>1</td>
<td>1</td>
</tr>
<tr>
<td>2</td>
<td>131</td>
<td>131</td>
</tr>
<tr>
<td>3</td>
<td>999</td>
<td>957</td>
</tr>
<tr>
<td>4</td>
<td>919</td>
<td>946</td>
</tr>
<tr>
<td>5</td>
<td>207</td>
<td>224</td>
</tr>
<tr>
<td>6</td>
<td>47</td>
<td>42</td>
</tr>
<tr>
<td>7</td>
<td>9</td>
<td>11</td>
</tr>
<tr>
<td>8</td>
<td>2</td>
<td>3</td>
</tr>
</table>


<pre class='language-julia'><code class='language-julia'>let
    stacked = stack(gamelengths, 2:3)
    typeint = [(v == "entropy" ? 1 : 2) for v in stacked.variable]
    barplot(
        stacked.count,
        stacked.value;
        dodge=typeint,
        color=typeint,
        axis=(xticks=1:8, xlabel="Game length", ylabel="Number of targets"),
    )
end</code></pre>
<img src="data:image/png;base64,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IDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAQLr448/rjv9xz/+8ZZbblm4cGHyywIAZKhkA+vJJ5+89tpra0//13/911lnnTV9+vSTTz553rx5Sc8GAJCRkg2su+++e+LEibWnZ8+efc455+zevXvWrFnTp09PejYAgIyUbGCtXLly0KBBURSVlpa+/vrrP/zhD7Oysi644IKVK1eGGA8AIPMkG1gFBQWbN2+OouiFF17Iyck57rjjoiiqqqrKzs4OMB0AQAbKSfL6w4cPHzt27OjRo6dOnXrqqae2atUqiqI333zzqKOOCjEeAEDmSfYZrOnTp+/ateuSSy7Jycm56667ajfOmjXryiuvTHo2AICMlOwzWD179lyyZElVVVVubm7dxnvvvbd3795JrgwAkKGSfQarR48eURTVr6soinr37l27HQCgGUo2sDZt2vTpjfF4/KOPPkpyZQCADJWSr8pZtGhR+/btU7EyAMCBr+GvwWrXrt0+J2pVVlZWVFRccsklSc0FAJCxGh5Y48ePj6LojjvuqD1Rp1WrVoMGDRo1alSyowEAZKaGB9aUKVOiKCovL689AQBArWRfgzVz5swgcwAANBkBXuT++uuvjxo1qmPHjllZ/7PaxIkTa78/BwCgGUo2sBYsWHDccceVlpZeccUViUSidmOPHj08swUANFvJBtaNN9548803L1q0aPLkyXUbTz/99N/+9rdJrgwAkKGS/aqcf/zjH88+++w+G3v16rVx48YkVwYAyFDJPoOVn59fVla2z8Z169b5oFEAoNlKNrBOPPHEW265paampm5LTU3N5MmTTz755CRXBgDIUMkeIrz99tuPPfbYN95441vf+lYURZMnT543b96aNWtef/31EOMBAGSeZJ/BOuyww1577bWePXvec889URRNnjy5ffv2ixcvHjBgQIjxAAAyT7LPYEVRdPjhh7/44ouVlZU7duxo27Ztfn5+8msCAGSuAIFVq0WLFl26dAm1GgBA5ko2sEaOHPkvt+fn5w8YMODSSy89+OCDk7wJAIDMkuxrsPbs2fPxxx8///zza9euLSsrW7t27fPPP//xxx9v3rz5wQcfPOyww/7+978HGRQAIFMkG1gzZszo2bPnmjVr3n333VdfffXdd999//33u3fvfu+9927YsOHkk0++5ZZbggwKAJApkg2syy67bOrUqX379q3bcvDBB0+bNu3yyy9v3br1tGnTlixZkuRNAABklmQDa9myZZ06ddpnY6dOnZYtWxZFUZ8+faqqqpK8CQCAzJJsYPXp0+e+++7bZ+O9997bp0+fKIpWr1596KGHJnkTAACZJdl3Ed52223f+9735s+ff+qpp3bq1Gnbtm0vvPDCa6+99uSTT0ZRNGvWrHHjxoWYEwAgYyQbWOedd17nzp0nTZp0++237927Ny8v72tf+9r8+fOHDx8eRdHMmTPbtm0bYk4AgIwR4INGhw8fPnz48EQisX379qKiolgsVrdLXQEAzVCyr8EaP3587YlYLNahQ4f6dQUA0DwlG1iPPPJIdXV1kFEAAJqGZANr+PDhPukKAKC+ZAPr4YcfnjVr1rx58/bu3RtkIACATJfsi9yHDh0aj8d/97vfxWKx9u3b5+bm1u3asmVLkosDAGSiZAPr/PPPDzIHAECTkWxg3XnnnUHmAABoMgJ8DlZVVdVbb731z3/+c5+vHfTkFgDQPCUbWBs2bBg5cuTy5cs/vUtgAQDNU7LvIrzpppu6du26evXqKIo2btz42muvXXnlld/5znc2btwYYjwAgMyTbGAtXLhw5syZAwYMiKKoe/fuxx577KxZs84444ypU6eGGA8AIPMkG1ibNm065JBDoihq3br1zp07azeed955/+///b9kRwMAyEzJBlY8Hs/JyYmiqHfv3q+99lrtxlWrVsXj8WRHAwDITAHeRVhr9OjRF1xwwbhx4/Ly8h588MHTTjst1MoAAJkl2cD6+c9/Xnti4sSJmzdvvv/++3fv3n366afPmjUr6dkAADJSsoF16aWX1p7Iy8ubPXv27NmzE4lELBZLejAAgEyV7GuwPk1dAQDNXLKB1aNHj/3aDgDQ5AX4mIZPb4zH4x999FGSKwMAZKjwhwijKFq0aFH79u1TsTIAwIGv4S9yb9eu3T4nalVWVlZUVFxyySVJzQUAkLEaHljjx4+PouiOO+6oPVGnVatWgwYNGjVqVLKjAQBkpoYH1pQpU6IoKi8vrz0BAECtZF+DNXPmzCBzAAA0GSl5kTsAQHMmsAAAAhNYAACBNTCw6j6aYcKECeGGAQBoChoYWLt27aquro6i6Gc/+1nQeQAAMl4DP6ahd+/es2fPPumkk6Ioeuutt/7lZY444ogGjwUAkLkaGFg33njj2LFja2pqoigaOnTov7xMIpFo+FwAABmrgYE1ZsyYM8888/333x82bNiCBQvCzgQAkNEa/knuXbp06dKly0UXXVR7oDCsl19++ZRTTqm/pUOHDsXFxXVnt27dOnHixGeffbaysvK44467++67Bw8e/AX3AgCkVLIf0/DII4+EGONfe/vttxP/q35dVVVVnXrqqWvWrHnzzTc//PDDDh06nHTSSZs3b/4iewEAUi3A52B9+OGH48aNO/TQQw866KBDDz10/Pjx69evT37ZzzB37txly5b96le/6tOnT4cOHR5++OHKysoZM2Z8kb0AAKmWbGCtXLnyiCOOePTRR7t37/6Nb3yje/fujzzyyNChQ1etWhVkvn/p6aef7tev36BBg2rPFhQUjBgxYt68eV9kLwBAqiUbWD/60Y+OPvro9evXv/jii48//viLL764fv36r371q9dff33yww0fPjw3N/eggw66+OKLN23aVLf9nXfeGTBgQP1LDhw48IMPPqioqPjcvQAAqZZsYC1atOiBBx4oKiqq21JUVHT//fcvWrQomWXz8vJuvvnmxYsXb9++/bHHHlu8ePExxxyzbdu22r3bt29v27Zt/cu3a9cukUiUlpZ+7l4AgFRr+LsIa1VVVbVu3XqfjQUFBVVVVcksO2zYsGHDhtWePuWUU/7whz8cfvjhM2fOvOOOO6J/9Qlb9bd89t4oih577LFHH320/pbCwsL+/ftv3bo1mZnTqLy8vLq6uvaz9ZuJPXv27Nq164D6rLWSku0pXb+srKy4uLioc2WLlN1EVVVV6f78FCTiqf3zLy8vLy4uLsqtaJmym4jH4yUH2A9+cXFxTk5OVlYz+qLY4uLieDyem5ub7kEaT0lJSUVFRX5+froHaTylpaU5OTmZeyhp165dn66dz5ZsYB155JFTp07d5wtzfvrTnx555JFJrlzfkCFDevbsuXTp0tqzRUVFZWVl9S9QVlYWi8VqvyHxs/dGUTRs2LDu3bvXv8Af//jHvLy8wsLCgDM3plgsVl1dnbnzN0Bubm5WVtYBdZf3FFSmdP1WrVq1adMmJycnSuqXl8+SnZ1d2GY//khTHVj5+flt2rRp0aJFtDdVNxGLxQ6oR1EURZ988klhYWGzCqzdu3cXFhY2q8CqrKxs3bp1y5ap+93hgFNTU5OTk9OmTZt0D9JAeXl5+3uVZANr0qRJp59++sKFC0eOHNm5c+dt27Y9++yzb7/99osvvpjkyp9h8ODBy5cvr79l9erVffv2rX2wfvbeKIr69u3bt2/f+hd49dVXoyjK3F8mqqqqqqqqMnf+BkgkEtXV1QfUXW7Aj99+yc3NzcvLS+m/u1lZWfv1R5rqwMrJycnLy8vOzk7dTcRisQPqURRFUV5eXn5+frMKrNq73KwCq/YuH2iPvZTKy8vLzc3N3Luck7PfvZTsz/App5zy/PPPt2rV6qc//emECROmTZuWn5//4osvnnzyyUmuXN+KFSs2bNhw9NFH154966yz1q5d++6779aeLS8vf+WVV84666wvshcAINUC/JJ0yimnLFmyZNeuXZs3b961a9eSJUuSr6tLL710zpw5H374YXl5+fz5888555xu3bpNmDChdu/o0aOHDBkyZsyYdevWlZSUjB07Njc397rrrvsiewEAUi3Ys9D5+fldu3YN9ezfDTfc8Oqrrw4fPryoqOgHP/jBCSec8Le//a1z5861e3Nzc1966aV+/foNHTq0V69excXFCxcurHtZ1WfvBQBItWRfg5Ui/fv3f+ihhz7jAl26dJkzZ07D9gIApFQzeh0lAEDjEFgAAIEJLACAwJINrPHjxweZAwCgyUg2sB555JFm9Q0tAACfK9nAGj58+JIlS4KMAgDQNCQbWA8//PCsWbPmzZu3d2/Kvi0MACCjJPs5WEOHDo3H47/73e9isVj79u3rf5nUli1bklwcACATJRtY559/fpA5AACajGQD68477wwyBwBAk+FzsAAAAgsQWK+//vqoUaM6duyYlfU/q02cOHHz5s3JrwwAkImSDawFCxYcd9xxpaWlV1xxRSKRqN3Yo0ePmTNnJj0bAEBGSjawbrzxxptvvnnRokWTJ0+u23j66af/9re/TXJlAIAMleyL3P/xj388++yz+2zs1avXxo0bk1wZACBDJfsMVn5+fllZ2T4b161b1759+yRXBgDIUMkG1oknnnjLLbfU1NTUbampqZk8efLJJ5+c5MoAABkq2UOEt99++7HHHvvGG29861vfiqJo8uTJ8+bNW7Nmzeuvvx5iPACAzJPsM1iHHXbYa6+91rNnz3vuuSeKosmTJ7dv337x4sUDBgwIMR4AQOZJ9hmsKIoOP/zwF198sbKycseOHW3bts3Pz09+TQCAzBXmk9yrq6vXr1+/atWqjRs3VldXB1kTACBDBQishx56qFevXocccshJJ510yCGH9O7d++c//3nyywIAZKhkDxHeddddP/7xjy+66KIzzjijc+fOW7duffbZZ6+44ory8vJrrrkmyIgAAJkl2cCaOXPmAw88cMkll9RtOfvss7/2ta9NmTJFYAEAzVOyhwhLSkq+853v7LPx3HPPLS4uTnJlAIAMlWxgDRs2bMWKFftsXLFixQknnJDkygAAGSrZQ4S//OUvJ0yYUFJSctppp7Vo0aKysvL5559/7LHHfvnLXwaZDwAg4zQwsLp27Vp3Oh6P//73v4/FYm3bti0rK0skEp07dz7yyCO3bNkSaEgAgEzSwMA6//zzw84BANBkNDCw7rzzzrBzAAA0GQG+KieKorKysvXr15eVldXfePzxxwdZHAAgsyQbWBs2bBg/fvwzzzwTj8f32ZVIJJJcHAAgEyUbWBdeeOGmTZtmz549YMCAgoKCIDMBAGS0ZANryZIlK1as6N+/f5BpAACagGQ/aLRfv34tW7YMMgoAQNOQbGBNnz79lltuqaysDDINAEATkOwhwjPPPDM/P3/w4MFf+cpXunTpEovF6nbNnDkzycUBADJRsoG1cOHCc889t7S0dMeOHfu8yF1gAQDNU7KBdfnll5933nlTpkzp0KFDkIEAADJdsoG1fv36adOmtWvXLsg0AABNQLIvch8+fPh7770XZBQAgKYh2cD6xS9+MXv27JdffrmmpibIQAAAmS7ZQ4RHHHFEIpGYM2dOdnZ2hw4d6r+LcMuWLUkuDgCQiZINrPPPPz/IHAAATUaygXXnnXcGmQMAoMlI9jVYAADsQ2ABAASW7CHCb3/72/9u11NPPZXk4gAAmSjZwCotLa07nUgkNm/e/M9//vOII47Y52tzAACajwDfRbjPljVr1txwww1Tp05NcmUAgAwV/jVY/fv3v/XWW8eOHRt8ZQCAjJCSF7n36NFj6dKlqVgZAODAFz6wysvLf/KTn/To0SP4ygAAGSHZ12B99atfrX+2vLx8/fr1NTU1c+fOTXJlAIAMlWxgfelLX6p/trCwsG/fvt///ve7d++e5MoAABkq2cCaM2dOkDkAAJoMn+QOABBYA5/BevDBBz/3MpdddlnDFgcAyGgNDKzLL7/8cy8jsACA5qmBgfXBBx/8y+0bNmyYMmXKn/70pw4dOiQxFQBABmtgYPXp02efLR9//PHUqVMfeuih/Pz822677Zprrkl2NACAzJTsuwijKCopKZk+ffq9994bi8Wuvfba//zP/2zfvn3yywIAZKikAqusrOzuu+++5557qqqqLr/88h//+MedOnUKNRkAQIZqYGDt2rVr1qxZM2bM2LVr1yWXXHLzzTd369Yt7GQAABmqgYHVt2/fbdu2nXLKKbfeemvv3r3j8fjGjRv3uYyvIwQAmqcGBta2bduiKHrppZdeeumlf3eZRCLRwKEAADJZAwNr9uzZYecAAGgyGhhY48ePDzsHAECT4bsIAQACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABJaT7gEA+D9ilYsSe59L4fptZ6RucaCWwAI4wFSvjiqeSuH6badHUSyF6wMOEQIABCewAAACE1gAAIEJLACAwAQWAEBgAgsAIDAf0wCwH3518xOfbC9P0eKHnfDlQ47vnaLFgcYksAD2w8uPLdq2sSRFi8dikcCCpsEhQgCAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgOekegKZpw+qPnvzpf6du/XMmntmmS+tE+T1RzZYU3UQsd2jU6rspWhyApk1gkRI7tpT+6dGFqVv/5AuHtenSOtrzclT9XopuIpGojAksABrEIUIAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAASWk+4BADig3fadO9/7+9oULT705CGjp5ydosUhjQQWAJ9lx5bSreuLU7R46dayFK0M6SWwAEizWM17ib1/SuH6rS6JsgpTtz58msACIM1iNWui8vtTeAMt/yOKBBaNyovcAQACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgTTOwtm7desEFFxQVFRUUFHzzm99855130j0RANCM5KR7gPCqqqpOPfXUli1bvvnmm23atLnyyitPOumk5cuXH3TQQekeDQCiKIqyalYlin+UuvVjbe+Kcoekbn0+VxMMrLlz5y5btmzlypV9+vSJoujhhx/u3r37jBkz7r777nSPBkAGmH3lL1/776UpWrzXoB7/OffyKFERVX+QopuIoihK7Enh4nwBTTCwnn766X79+g0aNKj2bEFBwYgRI+bNmyewAPgiPtleXvLRjhQt3qaoTYpW5oDSBAPrnXfeGTBgQP0tAwcOnDdvXkVFRcuWLdM1FQA0b4koUZ7C5WP5B1TVHECjhLJ9+/ahQ4fW39KuXbtEIlFaWlobWDt27Ni+fXv9C53Nt6MAABLTSURBVOzZs6dFixbV1dUpGmnv7r07t6fwUdWiIKcmXlNd+VGUiKfqNrIKoljBF794TU1Nqib53/Wrq6sTOYlYym4ikUjU7M9DInWPn1r/c5cTB9BdTsQTKZsliqIoHo9XV1fH4/GUvhkn1X9x+6UR7/J+PI4SiRT+RScSierq6pqampTf5cT+PLYb5S6n7iaiKKqpqUnsz2N7ydN/f/Pl5SkapkXLFuf86IzsaFvi45EpuokoiuIFP03kj0rV4vF4Vtb+PUibYGB9+gdjny2PP/74z372s/pbBgwY8OUvf3nr1q0pGmnb+pL3/vbPFC0eRdGgE/tl5Wbl1rwZJapSdBPV0cFV0SFf/PItO7YYO/P8FA0TRVFeu5zi4uK8jpfEEjtTdBM1FQdVVuzHQ6IyqkzpXe58SIeSkpJWOWdnJY5L0U3EK9vv3c+fgpTe5V6Hdi8pKSnIG56dODhFN5GIt9yzn3f5u7eM2ru7MkXzHNS/S0lJScvcw1rEbkzRTURRVLF1235d/oxxI44/7+gUDVPUrV1JSUl21LNldgrv8p6SmkS0H3/Rx/3HVwcc0zdFw7Ru16q4uLiyoKAwL4V3ee+ONvH9ucs5BVndvtQlRcPktMgpLi7OzamOF6TwLlfu7FOzM1X/ju/atatNm/07thtLaaenxcCBA/v16/fcc8/VbbnhhhumT5++a9euf3eIcNKkSXX/zUSffPJJVVVVUVFRugdpPBUVFeXl5Z06dUr3II2nqqqquLi4Wb0ZNh6Pf/TRRz169Ej3II1q48aN3bp129/flTPa5s2bO3bsmJubm+5BGs+2bdsKCgqa1atWtm/fnpubu7+NcuBoQCc0wZ/hwYMHv/fee/W3rF69um/fvs3qoQwApFETDKyzzjpr7dq17777bu3Z8vLyV1555ayzzkrvVABA89EEA2v06NFDhgwZM2bMunXrSkpKxo4dm5ube91116V7LgCguWiCgZWbm/vSSy/169dv6NChvXr1Ki4uXrhwYffu3dM9FwDQXDTBdxFGUdSlS5c5c+akewoAoJlqgs9gAQCkl8ACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAIDCBBQAQmMACAAhMYAEABCawAAACE1gAAIEJLACAwAQWAEBgAgsAILCcdA9wQFi3bt26desmTZqU7kEaqLKysqampmXLlukepPFUV1dXVla2atUq3YM0nng8vnv37oKCgnQP0ngSicQnn3xSWFiY7kEa1c6dO9u0aROLxdI9SOMpLy9v1apVVlYz+oV/9+7dLVq0yMlpRv8EV1RUZGdnt2jRIt2DNNDChQv79OmzX1dpRg/oz3DEEUfs7x/cAaW4uHjjxo3pnqJRlZWVrV27Nt1TNKqKiopVq1ale4pGFY/Hly9fnu4pGtvy5cvj8Xi6p2hUq1atqqioSPcUjWrt2rVlZWXpnqJRbdy4sbi4ON1TNFyfPn2OOOKI/bpKLJFIpGgaGs199923cuXK++67L92DNJ5nnnnmwQcffOaZZ9I9SONZvnz5+eef36yCo6ysrFevXs3t36G2bduuX7++bdu26R6k8Rx22GFz5sw57LDD0j1I4xk5cuRll102cuTIdA/SeMaNG/flL3953Lhx6R6k8XgGCwAgMIEFABCYwAIACExgAQAElp25n01AnVgs1r1790MOOSTdgzSqDh06DBkyJN1TNKqCgoKjjjoq3VM0nlgslpOTc/zxx6d7kEYVi8WGDRvWrN7AH0XRUUcd1aw+giSKoiFDhnTo0CHdUzSeWCw2YMCA7t27p3uQxuNdhAAAgTlECAAQmMACAAhMYAEABCawAAACE1iZLR6Pz58//+KLLy4sLIzFYuvWrUv3RCm3fv36G2+8cciQIa1bt+7fv/9VV11VUlKS7qFSa/fu3Q888MAxxxzTpk2bgw466Fvf+tZf//rXdA/VeM4+++xYLPaDH/wg3YOk1ssvvxz7vzp27JjuoRrDc889d+KJJ7Zp06Znz57XX3/9J598ku6JUujb3/527FOa/FuDX3nllREjRnTs2LGwsPCoo46aM2dOuidqJAIrsy1dunTq1KnDhg277rrr0j1LI7nwwgufeuqpO++8c+vWrU888cQrr7xy7LHH7t69O91zpdBvfvObDz744L777tuyZcvixYvz8vJOOOGE119/Pd1zNYbf/OY3ixYtatGiRboHaSRvv/124n9l9DfjfkEPPfTQ9773vUsvvXTTpk3Lli3r2rXrf//3f6d7qBR66qmnEvW8/PLLURSdfvrp6Z4rhZYuXXraaaf16dNnxYoVGzZsOPvssy+44ILHHnss3XM1igRNwj333BNF0QcffJDuQVJuypQp5eXldWdfffXVKIoeffTRNI7UyHbu3JmVlXXVVVele5CUKy4u7ty58wMPPNC6deuLLroo3eOk1ksvvRT938Bq8j744IP8/Pw5c+ake5C0qX1eds2aNekeJIWuueaarKysXbt21W350pe+dOqpp6ZxpEbjGSwyzE033dS6deu6swcffHAURR9++GH6Jmps2dnZsVisVatW6R4k5SZMmNC7d++xY8emexBS4le/+lVeXt55552X7kHSo6Ki4ve///2wYcP69euX7llSKCcnJxaL1d+SSCSayefoCiwy2wsvvBD9b2Y1eYlEYv369T/84Q87dep02WWXpXuc1Hr++efnzp17//33Z2U1o/9NDR8+PDc396CDDrr44os3bdqU7nFSa/HixYceeuj06dP79OmTl5f3pS996f7770/3UI3nqaee+uSTT5r8iwsvv/zyjh07jh8//uOPPy4rK5s2bdr69euvv/76dM/VKNL9FBphNJ9DhPVt27atW7duPXv23L17d7pnSbnjjjuu9me2a9eur732WrrHSa2dO3f27NnziiuuqD3bHA4R/vnPf7755ptXrVq1c+fOP/3pT/379+/Ro8fWrVvTPVcKDRw4MDs7+5BDDvnb3/62Y8eOmTNnRlE0Y8aMdM/VSM4444xWrVrt3Lkz3YOk3F//+tdu3brV/u+rVatWTz75ZLonaiQCq4lohoFVWVk5YsSI3NzcBQsWpHuWRlJdXf3+++9///vfb9my5cKFC9M9TgpddtllnTt33rFjR+3Z5hBY+1i+fHksFrvxxhvTPUgK1X596gsvvFC3ZeTIkUVFRTU1NWmcqnF8/PHHOTk5F1xwQboHSbm//OUvBQUFl19++aZNm7Zv337XXXdlZ2c/8sgj6Z6rMTSj595pShKJxEUXXbRgwYJHHnnkpJNOSvc4jSQ7O7t///6PPvpo165db7311nSPkyqrV69+6KGH7rzzznbt2qV7lrQZMmRIz549ly5dmu5BUqj2q47rnpqtPb19+/bm8JLKJ554orq6+qKLLkr3ICl3yy23dOnS5d577+3WrVv79u2vvfbaM888s5m87V1gkZGuvfbaJ554Yvbs2d///vfTPUtjy8nJGThwYBP+zLPaJ64uvPDCug8K2rVr16OPPhqLxWpfckfTMHjw4H22JBKJtEzS+B5//PFevXqNGDEi3YOk3HvvvTdw4MD6r6QcPHhwcXFxaWlpGqdqHAKLzDNt2rSZM2dOmTJl3Lhx6Z4lDfbu3btixYoBAwake5BUOeaYY/Z5pr3uEOFpp52W7ukaSe2HBh199NHpHiSFzj777CiK/vKXv9RtWbJkSadOnXr37p2+oRrDqlWr3njjjdpfIdI9S8r17Nlz9erV8Xi8bss777xTWFhYWFiYxqkah8Aiw/z617++8cYbJ06ceNNNN6V7lkYyZsyYuXPnrl+/vqKiYvny5eedd962bdua8CHC5unSSy+dM2fOhx9+WF5ePn/+/HPOOadbt24TJkxI91wpdMYZZwwfPvzKK6984403ysrKZs+e/cwzz9x2221N/n2jjz/+eBRFzeH4YBRFV1999dq1a6+++uotW7bs2LHj7rvvfvrpp6+66qom/7ccRd5FmOGqqqo+/Xd65plnpnuuFPr0YYUoisaNG5fuuVLo/fff/+EPf3jwwQfn5+f369fv/PPPX7lyZbqHalTN4UXu77///tixY/v27Zubm9ujR4/aDzdP91ApV1ZWNm7cuC5durRo0eLQQw9tDp8YHI/He/fuffzxx6d7kMbz/PPPn3DCCR06dCgsLDzyyCN/8YtfNIf3MSQSiVii2RzzBgBoHM3gOToAgMYlsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABB4S///3vo0eP7tWrV15eXteuXY8++uhbb711/fr16Z4rmjJlSkFBQVpu+rrrruvatWtabhpIksAC0u/ee+895phj2rZt+8wzz5SVla1YseLaa6998skn/+M//iPdozWSm2++uV27dumeAghGYAFp9pe//OXqq6/+yU9+cv/99x922GH5+fkdO3b87ne/u2zZspEjR6Z7OoCGEFhAmk2fPr1t27Y33HDDPtvz8/Nvvvnm2tO/+MUvYrFYLBbLzs7u3bv3hRdeuGHDhrpL1h5K+/jjj0eOHFlQUDB48OBXX301iqJnn3320EMPbdmy5YgRIzZt2lR/8bfffnvUqFHt27dv2bLlscce++c///kLTvsZV6wdo7i4+Oyzzy4oKOjRo8esWbPqX/c3v/nNoEGDWrZsecwxx/zjH//4xje+UVuQEyZMuOOOO8rKymrvY48ePepf6zMWBA5YAgtIp0Qi8corrxx//PF5eXmfcbFLL7209gvq9+7d+9xzz23evHnkyJHV1dX117nuuutuueWWDRs2HH/88aNGjZo/f/4f/vCHF1988e233964ceP48ePrLrxs2bKvf/3rrVu3fuONNzZt2nTaaaedcsopb7zxxudO+7lXTCQSEyZMuPbaazdt2nTVVVddffXVS5Ysqd21YMGC7373u+edd96GDRt+/etf33bbbWVlZbW7Zs6cedNNN7Vt27b2Pm7cuPGLLAgc0BIA6VNaWhpF0WWXXbZf11q9enUURX/7299qz06cODGKopdeeqn27LZt22KxWP/+/ffu3Vu75b777svKyiotLa09e+qppw4aNKiqqqpuwRNOOGHUqFH/8rZuv/321q1bf5Er1o7x3HPP1e3t27fv2LFj6y55/PHH1+1au3ZtVlbWmWeeWXu2fmDV+ewFgQOZZ7CAdEokElEUxWKxui3l5eWxerZs2RJF0d69e6dNmzZ48OA2bdrEYrGBAwdGUfTPf/6z7lrZ2dnDhw+vPd2xY8eioqKvfOUrLVq0qN0yYMCAeDxe+57EysrKBQsWjBw5Micnp+7qJ5544uLFiz971C9yxezs7FNOOaXu7KBBg9atW1d7N5cuXXraaafV7Tr44IMHDBjwuX8+/25B4AAnsIB0atu2bZs2beofFCsoKKj9/W/atGl1G6+77rq77rprxowZGzdujMfjtZevqqqqu0CHDh2ys7PrL9KlS5f6Z6Moqj0kt2PHjqqqqhkzZtTPuNtvv3379u2fPeoXuWKHDh3q51ebNm1qb3T79u179+7t1KlT/QU7duz4uX8+/25B4AAnsIB0isViI0aMWLx48d69ez/jYk8++eS4cePOOOOMtm3bxmKxT38+Vv3nwP7dllpt27bNzs6+7bbb9nk+Px6Pf/aoX+SK/+5Gi4qK8vLytm3bVn9jcXHxZ9/iZywIHOAEFpBm119/fVlZ2YwZM/7dBRKJxO7du+u/Cv6JJ55o8M3l5+efdNJJ8+bNq6mpaZwrRlEUi8W+9rWv/elPf6rb8sEHH7z33nt1Z1u1alVZWbm/ywIHLIEFpNmxxx77s5/9bNKkSePHj1+xYsXevXtLS0sXL178wgsvRFFUeyTutNNOe+ihh956663S0tL7779/8+bNydziXXfd9d57740ePfrdd9+tqKhYvXr1zJkza19RnqIrRlE0adKkV199dfLkySUlJatWrZo4ceKRRx5Zt3fQoEEVFRULFiz43CfSgIwgsID0Gz9+/JIlS7Zv33766acXFhYecsgh48ePHzRo0NKlS2tfSvXggw9+/etfHz58eL9+/VasWDFz5sxkbu7www9//fXXoyg68cQTi4qKvv3tb2/cuPGLdFKDrxhF0fDhw5944om5c+d27979oosu+slPftKiRYv8/PzavaNGjRozZsw555yTnZ29z+dgAZkoVvsWHgAa065du3r27HnZZZdNnTo13bMA4XkGC6AxlJWVjRkzZvny5RUVFStXrhw9evTevXsvueSSdM8FpITAAmgMbdu2PfHEE8eMGdOxY8djjz12z549r7zySr9+/dI9F5ASDhECAATmGSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAvv/AemQIh5RRMmkAAAAAElFTkSuQmCC">


<div class="markdown"><h2>Wordle-like games</h2>
<p>Wordle has spawned many similar games, one of which is <a href="https://converged.yt/primel">Primel</a>, where the targets are 5-digit prime numbers. Because leading zeros are not allowed in these primes, the targets are prime numbers between 10,000 and 99,999.</p>
</div>

<pre class='language-julia'><code class='language-julia'>primel = GamePool(primes(10_000, 99_999));  # underscores are ignored in numbers</code></pre>



<div class="markdown"><p>To play a game with a random, but reproducible, target, we initialize a random number generator and pass it as the second argument to <code>showgame&#33;</code>.</p>
</div>

<pre class='language-julia'><code class='language-julia'>showgame!(primel, Random.seed!(1234321))</code></pre>
<table>
<tr>
<th>poolsz</th>
<th>index</th>
<th>guess</th>
<th>expected</th>
<th>entropy</th>
<th>score</th>
<th>sc</th>
</tr>
<tr>
<td>8363</td>
<td>313</td>
<td>"12953"</td>
<td>124.384</td>
<td>6.63227</td>
<td>"🟨🟨🟫🟫🟫"</td>
<td>108</td>
</tr>
<tr>
<td>201</td>
<td>1141</td>
<td>"21067"</td>
<td>5.92537</td>
<td>5.47937</td>
<td>"🟨🟨🟫🟨🟨"</td>
<td>112</td>
</tr>
<tr>
<td>10</td>
<td>3556</td>
<td>"46271"</td>
<td>1.2</td>
<td>3.12193</td>
<td>"🟩🟩🟩🟩🟩"</td>
<td>242</td>
</tr>
</table>



<div class="markdown"><p>The size of the target pool is larger than for Wordle</p>
</div>

<pre class='language-julia'><code class='language-julia'>length(primel.targetpool)</code></pre>
<pre id='var-hash748843' class='documenter-example-output'><code class='code-output'>8363</code></pre>


<div class="markdown"><p>but the number of possible characters at each position &#40;9 for the first position, 10 for the others&#41; is smaller than for Wordle, leading to a larger mean number of guesses but a smaller standard deviation in the number of guesses.</p>
<p>As for Wordle, the strategy of choosing guesses to minimize the expected pool size is less effective than maximizing the entropy.</p>
</div>

<pre class='language-julia'><code class='language-julia'>primelxpectd = GamePool(primes(10_000, 99_999); guesstype=MinimizeExpected);</code></pre>


<pre class='language-julia'><code class='language-julia'>allprimel = let
    inds = 1:length(primel.targetpool)
    DataFrame(;
        index=inds,
        entropy=[length(playgame!(primel, k).guesses) for k in inds],
        expected=[length(playgame!(primelxpectd, k).guesses) for k in inds],
    )
end</code></pre>
<table>
<tr>
<th>index</th>
<th>entropy</th>
<th>expected</th>
</tr>
<tr>
<td>1</td>
<td>4</td>
<td>4</td>
</tr>
<tr>
<td>2</td>
<td>4</td>
<td>4</td>
</tr>
<tr>
<td>3</td>
<td>3</td>
<td>4</td>
</tr>
<tr>
<td>4</td>
<td>3</td>
<td>4</td>
</tr>
<tr>
<td>5</td>
<td>3</td>
<td>4</td>
</tr>
<tr>
<td>6</td>
<td>3</td>
<td>3</td>
</tr>
<tr>
<td>7</td>
<td>4</td>
<td>4</td>
</tr>
<tr>
<td>8</td>
<td>4</td>
<td>4</td>
</tr>
<tr>
<td>9</td>
<td>4</td>
<td>4</td>
</tr>
<tr>
<td>10</td>
<td>3</td>
<td>4</td>
</tr>
<tr>
<td>...</td>
</tr>
<tr>
<td>8363</td>
<td>5</td>
<td>4</td>
</tr>
</table>


<pre class='language-julia'><code class='language-julia'>primelengths = let
    entropy = countmap(allprimel.entropy)
    expected = countmap(allprimel.expected)
    allcounts = 1:maximum(union(keys(entropy), keys(expected)))
    DataFrame(;
        count=allcounts,
        entropy=[get!(entropy, k, 0) for k in allcounts],
        expected=[get!(expected, k, 0) for k in allcounts],
    )
end</code></pre>
<table>
<tr>
<th>count</th>
<th>entropy</th>
<th>expected</th>
</tr>
<tr>
<td>1</td>
<td>1</td>
<td>1</td>
</tr>
<tr>
<td>2</td>
<td>215</td>
<td>209</td>
</tr>
<tr>
<td>3</td>
<td>3173</td>
<td>2743</td>
</tr>
<tr>
<td>4</td>
<td>4477</td>
<td>4797</td>
</tr>
<tr>
<td>5</td>
<td>482</td>
<td>589</td>
</tr>
<tr>
<td>6</td>
<td>15</td>
<td>24</td>
</tr>
</table>


<pre class='language-julia'><code class='language-julia'>describe(allprimel[!, Not(1)], :min, :max, :mean, :std)</code></pre>
<table>
<tr>
<th>variable</th>
<th>min</th>
<th>max</th>
<th>mean</th>
<th>std</th>
</tr>
<tr>
<td>:entropy</td>
<td>1</td>
<td>6</td>
<td>3.63004</td>
<td>0.641331</td>
</tr>
<tr>
<td>:expected</td>
<td>1</td>
<td>6</td>
<td>3.69784</td>
<td>0.647833</td>
</tr>
</table>


<pre class='language-julia'><code class='language-julia'>let
    stacked = stack(primelengths, 2:3)
    typeint = [(v == "entropy" ? 1 : 2) for v in stacked.variable]
    barplot(
        stacked.count,
        stacked.value;
        dodge=typeint,
        color=typeint,
        axis=(xticks=1:8, xlabel="Game length", ylabel="Number of targets"),
    )
end</code></pre>
<img src="data:image/png;base64,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/PLL468FAGhVO29g5eXlLVq0qF+/foMHD+7Vq1dZWdmSJUu6d+8efy0AQKtK7LcIt1NZWfnRhd26dZs/f/6/e0qctQAArWfnPYMFAJClBBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGDtkh4A+LytWrF6zcp3kzp6524lvQ7aO6mjA3w+BBbschb959L7Zj2Q1NG/PPygyb/9flJHB/h8eIsQACAwgQUAEFiAwNqwYUPT4//93/+99tprlyxZEn+3AABZKm5g3XvvvZdddlnj4//6r/86/fTTZ86cedxxxy1cuDD2bAAAWSluYP3oRz+aNGlS4+O5c+d+4xvfqKqqmjNnzsyZM2PPBgCQleIG1iuvvDJgwIAoisrLy5955plx48bl5OSce+65r7zySojxAACyT9zAKi4uXr9+fRRFDz/8cLt27Y444ogoiurq6nJzcwNMBwCQheLeB2vYsGFjx44dPXr09OnTTzjhhMLCwiiKnnvuua985SshxgMAyD5xz2DNnDlz69atF1xwQbt27W655ZbGhXPmzLnkkktizwYAkJXinsHq2bPnU089VVdXl5eX17Twtttu6927d8w9AwBkqbhnsHr06BFFUfO6iqKod+/ejcsBAHZBcQNr3bp1H12YTqfffTexPyULAJCsVvlTOUuXLu3cuXNr7BkAYOfX8muwSkpKtnvQqLa2trq6+oILLog1FwBA1mp5YE2YMCGKohtvvLHxQZPCwsIBAwaMHDky7mgAANmp5YE1bdq0KIoqKysbHwAA0CjuNVizZ88OMgcAQJsR4CL3Z555ZuTIkV27ds3J+cfeJk2a1Pj3cwAAdkFxA2vx4sVHHHFEeXn59773vUwm07iwR48ezmwBALusuIE1efLkq6++eunSpVOnTm1aePLJJ//2t7+NuWcAgCwV90/lPP/88w8++OB2C3v16rV27dqYewYAyFJxz2AVFBRUVFRst3DVqlVuNAoA7LLiBtYxxxxz7bXXNjQ0NC1paGiYOnXqcccdF3PPAABZKu5bhDfccMOQIUOeffbZ0047LYqiqVOnLly48M0333zmmWdCjAcAkH3insE66KCDnnzyyZ49e956661RFE2dOrVz587Lli3r379/iPEAALJP3DNYURR96UtfeuSRR2pra99///1OnToVFBTE3ycAQPYKEFiN8vPzu3XrFmpvAADZK25gjRgx4mOXFxQU9O/f/8ILL9xnn31iHgIAILvEvQZr27ZtGzZseOihh956662Kioq33nrroYce2rBhw/r16++4446DDjrob3/7W5BBAQCyRdzAmjVrVs+ePd98881XX331iSeeePXVV994443u3bvfdttta9asOe6446699toggwIAZIu4gXXRRRdNnz69b9++TUv22WefGTNmXHzxxUVFRTNmzHjqqadiHgIAILvEDazly5fvvvvu2y3cfffdly9fHkVRnz596urqYh4CACC7xA2sPn36/OQnP9lu4W233danT58oilauXHnAAQfEPAQAQHaJ+1uE119//be//e3HHnvshBNO2H333Tdt2vTwww8/+eST9957bxRFc+bMGT9+fIg5AQCyRtzAGjVq1B577DFlypQbbrihpqamffv2hx122GOPPTZs2LAoimbPnt2pU6cQcwIAZI0ANxodNmzYsGHDMpnMli1bSktLU6lU0yp1BQDsguJegzVhwoTGB6lUqkuXLs3rCgBg1xQ3sO666676+vogowAAtA1xA2vYsGHudAUA0FzcwLrzzjvnzJmzcOHCmpqaIAMBAGS7uBe5Dx48OJ1O33///alUqnPnznl5eU2r3nvvvZg7BwDIRnED65xzzgkyB7CryVT8R7Tt4cQO3+Ebqd38pVSgtcQNrJtvvjnIHMAuJ7MtylQld3RXNQCtKMB9sOrq6l544YW///3v2/3ZQSe3AIBdU9zAWrNmzYgRI1588cWPrhJYAMCuKe5vEV511VV77rnnypUroyhau3btk08+eckll5x55plr164NMR4AQPaJG1hLliyZPXt2//79oyjq3r37kCFD5syZc8opp0yfPj3EeAAA2SduYK1bt26//faLoqioqOiDDz5oXDhq1Kjf/OY3cUcDAMhOcQMrnU63a9cuiqLevXs/+eSTjQtfe+21dDoddzQAgOwU4LcIG40ePfrcc88dP358+/bt77jjjpNOOinUngEAskvcwPrZz37W+GDSpEnr16+//fbbq6qqTj755Dlz5sSeDQAgK8UNrAsvvLDxQfv27efOnTt37txMJpNKpWIPBgCQreJeg/VR6goA2MXFDawePXrs0HIAgDYvwG0aPrownU6/++67MfcMAJClwr9FGEXR0qVLO3fu3Bp7BgDY+bX8IveSkpLtHjSqra2trq6+4IILYs0FAJC1Wh5YEyZMiKLoxhtvbHzQpLCwcMCAASNHjow7GgBAdmp5YE2bNi2KosrKysYHAAA0insN1uzZs4PMAQDQZrTKRe4AALsygQUAEJjAAgAIrIWB1XRrhokTJ4YbBgCgLWhhYG3durW+vj6Koh//+MdB5wEAyHotvE1D7969586dO3To0CiKXnjhhY/dZtCgQS0eCwAge7UwsCZPnjx27NiGhoYoigYPHvyx22QymZbPBQCQtVoYWGPGjDn11FPfeOONo446avHixWFnAgDIai2/k3u3bt26det2/vnnN75RCABAo7i3abjrrrtCjAEA0HYEuA/WO++8M378+AMOOGCvvfY64IADJkyYsHr16vi7BQDIUnED65VXXhk0aNDdd9/dvXv3448/vnv37nfdddfgwYNfe+21IPMBAGSdll+D1eg//uM/Dj300Hvuuae0tLRxyZYtW7797W9fccUVDzzwQOzxAACyT9zAWrp06QsvvNBUV1EUlZaW3n777QcffHDMPQMAZKm4bxHW1dUVFRVtt7C4uLiuri7mngEAslTcwDr44IOnT5++3cKbbrrJGSwAYJcV9y3CKVOmnHzyyUuWLBkxYsQee+yxadOmBx988KWXXnrkkUeCzAcAkHXiBtbw4cMfeuiha6+99qabbkqn0zk5OYceeugjjzxy3HHHBZkPACDrxA2sKIqGDx8+fPjwbdu2lZeXl5SUFBQUxN8nAED2ChBYjQoKCvbcc89QewMAyF4B7uQOAEBzAgsAIDCBBQAQmMACAAgsbmBNmDAhyBwAAG1G3MC666676uvrg4wCANA2xA2sYcOGPfXUU0FGAQBoG+IG1p133jlnzpyFCxfW1NQEGQgAINvFvdHo4MGD0+n0/fffn0qlOnfunJeX17Tqvffei7lzAIBsFDewzjnnnCBzAAC0GXED6+abbw4yBwBAm+E+WAAAgQUIrGeeeWbkyJFdu3bNyfnH3iZNmrR+/fr4ewYAyEZxA2vx4sVHHHFEeXn59773vUwm07iwR48es2fPjj0bAEBWihtYkydPvvrqq5cuXTp16tSmhSeffPJvf/vbmHsGAMhScS9yf/755x988MHtFvbq1Wvt2rUx9wwAkKXinsEqKCioqKjYbuGqVas6d+4cc88AAFkqbmAdc8wx1157bUNDQ9OShoaGqVOnHnfccTH3DACQpeK+RXjDDTcMGTLk2WefPe2006Iomjp16sKFC998881nnnkmxHgAANkn7hmsgw466Mknn+zZs+ett94aRdHUqVM7d+68bNmy/v37hxgPACD7xD2DFUXRl770pUceeaS2tvb999/v1KlTQUFB/H0CAGSvMHdyr6+vX7169WuvvbZ27dr6+vog+wQAyFIBAmvevHm9evXab7/9hg4dut9++/Xu3ftnP/tZ/N0CAGSpuG8R3nLLLT/84Q/PP//8U045ZY899ti4ceODDz74ve99r7Ky8gc/+EGQEQEAskvcwJo9e/ZPf/rTCy64oGnJGWeccdhhh02bNk1gAQC7prhvEW7evPnMM8/cbuE3v/nNsrKymHsGAMhScQPrqKOOWrFixXYLV6xYcfTRR8fcMwBAlor7FuEvfvGLiRMnbt68+aSTTsrPz6+trX3ooYd+/etf/+IXvwgyHwBA1mnhGaw9/+mQQw7585//PHLkyIKCgs6dOxcUFHzta19btmzZwQcf/Ml7WL169eTJkw888MCioqJ999330ksv3bx583bbbNy48dxzzy0tLS0uLj7xxBNffvnlUGsBAFpPC89gnXPOOTEPfN55523cuPHWW2898sgjX3nlle9+97uPPPLI888/X1hY2LhBXV3dCSec0KFDh+eee65jx46XXHLJ0KFDX3zxxb322ivmWgCAVtXCwLr55ptjHnj48OETJ04sKiqKougrX/nKHXfccdRRR91///3nnXde4wYLFixYvnz5K6+80qdPnyiK7rzzzu7du8+aNetHP/pRzLUAAK0qzJ3cKyoqXnrppWX/6pOfctVVVzXWVaN99tkniqJ33nmnackDDzzQr1+/AQMGNH5YXFx87LHHLly4MP5aAIBWFfci9zVr1kyYMOEPf/hDOp3eblUmk/ns+3n44Yejf2ZWo5dffnm7vxi9//77L1y4sLq6ukOHDnHWfvapAABaIG5gnXfeeevWrZs7d27//v2Li4tbtpOysrJrrrmmZ8+eX//615sWbtmyZfDgwc03KykpyWQy5eXlHTp0iLM2iqI1a9asXr26+QYffPBBUVFRTU1Nyz6FnV9NTU1tbW0b/gQ/H23jZWxoaEjw6Ol0uqamJp1Op/PSYU6ht0hDQ0NDvH+PO8PLmJOTU5TK7pcxcTU1NZlMJi8vL+lBslttbW1ubm5ubm7Sg7SWhoaGHf3s4gbWU089tWLFin333bfFe6irqxs1atSmTZv+9Kc/NT+99NETYM2XxFkbRdGiRYu2u5FE165d+/fvX15evuOfQXaorq6urq5uw//1fz62bt1aV1eXk5PgT7QAtm3bluDR6+vrKyoq0un0brvVFiQ3Rm1t7Yd1sb7ea2trQw3TsqNXVFTk5OTsVlyfn9wY27Zt21qT3d82P/jgg7y8vPr6+qQHyW4VFRW1tbXJflG0qm3btjW/rumziBtY/fr1i/OmWyaTOf/88xcvXjx//vyhQ4c2X1VaWlpRUdF8SUVFRSqVKikpibk2iqIxY8aMGTOm+QZTpkyJoqhbt24t/lx2clVVVVVVVV27dk16kOxWWVlZW1tbWlqa9CCx7Oi3ibDy8/P32GOPdDpdEBVEyZVehw4dCjvF+npP9nqDgoKCPfbYIycnJ78+P0ruh1pRUVFxx+z+tpmXl5efn9/id2BolJubW1hY2HQfgLanBd824/6P+MyZM6+99toWR+tll112zz33zJ079+yzz95u1cCBA19//fXmS1auXNm3b9/Gb2px1gIAtKq4Z7BOPfXUgoKCgQMHfvnLX+7WrVsqlWpaNXv27E9+7owZM2bPnj1t2rTx48d/dO3pp5/++9///tVXX238ZcDKysrHH3+86bRTnLUAAK0q7hmsJUuWfPOb33zrrbceffTRhQsX/k8zn/zEX/3qV5MnT540adJVV131sRuMHj36wAMPHDNmzKpVqzZv3jx27Ni8vLzLL788/loAgFYVN7AuvvjixkvUy8rKVv2rT37iLbfc0vjPVDMTJkxo2iAvL2/RokX9+vUbPHhwr169ysrKlixZ0r179/hrAQBaVdy3CFevXj1jxoymi8c/uxUrVnzqNt26dZs/f35rrAUAaD1xz2ANGzZsu8vJAQB2cXED6+c///ncuXMfffTRZO+5BwCw84j7FuGgQYMymcz8+fNzc3O7dOnS/LcI33vvvZg7BwDIRnED65xzzgkyBwBAmxE3sG6++eYgcwAAtBnZ/SfVAAB2QgILACCwuG8Rfu1rX/t3qz71Zu4AAG1S3MAqLy9vepzJZNavX//3v/990KBB/jI5ALDLihtYS5Ys2W7Jm2++eeWVV06fPj3mngEAslT4a7D23Xff6667buzYscH3DACQFVrlIvcePXo8/fTTrbFnAICdX/jAqqysvOaaa3r06BF8zwAAWSHuNViHHHJI8w8rKytXr17d0NCwYMGCmHsGAMhScQPrC1/4QvMPd9ttt759+5599tndu3ePuWcAgCwVN7Dmz58fZA4AgDbDndwBAAJr4RmsO+6441O3ueiii1q2cwCArNbCwLr44os/dRuBBQDsmloYWG+//fbHLl+zZs20adP+9Kc/denSJcZUAABZrIWB1adPn+2WbNiwYfr06fPmzSsoKLj++ut/8IMfxB0NACA7xf0twiiKNm/ePHPmzNtuuy2VSl122WX/7//9v86dO8ffLQBAlooVWBUVFT/60Y9uvfXWurq6iy+++Ic//OHuu+8eajIAgCzVwsDaunXrnDlzZs2atXXr1gsuuODqq6/ee++9w04GAJClWhhYffv23bRp0/Dhw6+77rrevXun0+m1a9dut40/RwgA7JpaGFibNm2KomjRokWLFi36d9tkMpkWDgUAkM1aGFhz584NOwcAQJvRwsCaMGFC2DkAANoMf4sQACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNY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u9XU1GQymYKCgqQHyW7btm1LpVLt27dPepDsVl1dnZubm5+fn/Qg2a2qqiovLy8vLy/pQVrLkiVL+vTps0NPcQbrHwYNGrSjr112KS8vX7VqVdJTZL3NmzevWbMm6Smy3oYNG959992kp8h677777oYNG5KeIuutWbNm8+bNSU+R9VatWlVeXp70FK2oT58+gwYN2qGnpDKZTCtNw07lvvvuu//++++7776kB8lu8+bNe+655+bNm5f0INntpptuKi8vv+mmm5IeJLtdeeWVJSUlV155ZdKDZLdx48YdfPDB48aNS3qQ7HbWWWedeeaZZ511VtKD7EScwQIACExgAQAEJrAAAAITWAAAgblNw65i4MCBqVQq6Smy3iGHHNK9e/ekp8h6Rx555LZt25KeIusdf/zxbnUR32mnnbbXXnslPUXW++Y3v/nFL34x6Sl2Ln6LEAAgMG8RAgAEJrAAAAITWAAAgQksAIDABFbbl06nH3vsse9+97u77bZbKpXyFwlbZvXq1ZMnTz7wwAOLior23XffSy+91N8va4Gqqqqf/vSnhx9+eMeOHffaa6/TTjvtr3/9a9JDZbEzzjgjlUp95zvfSXqQrPToo4+m/lXXrl2THior/fGPfzzmmGM6duzYs2fPK6644sMPP0x6op2CwGr7nn766enTpx911FGXX3550rNksfPOO+9//ud/br755o0bN95zzz2PP/74kCFDqqqqkp4ry9x3331vv/32T37yk/fee2/ZsmXt27c/+uijn3nmmaTnykr33Xff0qVL8/Pzkx4ku7300kuZfyorK0t6nOwzb968b3/72xdeeOG6deuWL1++5557/v73v096qJ1Dhl3GrbfeGkXR22+/nfQgWWnatGmVlZVNHz7xxBNRFN19990JjtQGfPDBBzk5OZdeemnSg2SfsrKyPfbY46c//WlRUdH555+f9DhZadGiRdG/BhY76u233y4oKJg/f37Sg+yMnMGCz+Sqq64qKipq+nCfffaJouidd95JbqK2IDc3N5VKFRYWJj1I9pk4cWLv3r3Hjh2b9CDs0n75y1+2b99+1KhRSQ+yMxJY0BIPP/xw9M/MogUymczq1avHjRu3++67X3TRRUmPk2UeeuihBQsW3H777Tk5vofHNWzYsLy8vL322uu73/3uunXrkh4nyyxbtuyAAw6YOXNmnz592rdv/4UvfOH2229PeqidhS9O2GFlZWXXXHNNz549v/71ryc9S1Y68sgjc3Jyevfu/eijj/73f/937969k54om3z44Yfjxo276KKLDjnkkKRnyW7t27e/+uqrly1btmXLll//+tfLli07/PDDN23alPRc2eTdd9/961//etddd/32t7/dsGHDxRdfPH78+JtvvjnpuXYKAgt2TF1d3ahRozZt2vTrX/+6Q4cOSY+TlZYtW1ZfX//GG28ce+yxxx9//NKlS5OeKJtcccUVNTU1N954Y9KDZL2jjjrqhhtu2H///Tt27Dh8+PDf/e5369atmz17dtJzZZN0Ot3Q0DB37tyvfOUrJSUl3//+90eMGDFjxox0Op30aMkTWLADMpnM+eefv3jx4rvuumvo0KFJj5PFcnNz991337vvvnvPPfe87rrrkh4na6xcuXLevHk333xzSUlJ0rO0NQceeGDPnj2ffvrppAfJJl26dImi6IgjjmhacsQRR2zZssX1qZHAgh1y2WWX3XPPPXPnzj377LOTnqUtaNeu3f777+/ebJ/d+++/n8lkzjvvvKZbN23duvXuu+9OpVKN1wXC52ngwIHbLclkMolMshMSWPBZzZgxY/bs2dOmTRs/fnzSs7QRNTU1K1as6N+/f9KDZI3DDz98u18Fb7pNw0knnZT0dNltxYoVa9asOfTQQ5MeJJucccYZURT95S9/aVry1FNP7b777i6sjAQWfEa/+tWvJk+ePGnSpKuuuirpWbLYmDFjFixYsHr16urq6hdffLHxajZvEZKICy+8cP78+e+8805lZeVjjz32jW98Y++99544cWLSc2WTU045ZdiwYZdccsmzzz5bUVExd+7cP/zhD9dff73fb40iNxrdBdTV1X303/upp56a9FxZ5qNnwqMoGj9+fNJzZZk33nhj3Lhx++yzT0FBQb9+/c4555xXXnkl6aGymxuNttgbb7wxduzYvn375uXl9ejRo/Fe5EkPlX0qKirGjx/frVu3/Pz8Aw44wO2Xm6Qy3i4FAAjKSTwAgMAEFgBAYAILACAwgQUAEJjAAgAITGABAAQmsAAAAhNYAACBCSxgZ/G3v/1t9OjRvXr1at++/Z577nnooYded911q1evTnaqadOmFRcXJ3Loyy+/fM8990zk0EBMAgvYKdx2222HH354p06d/vCHP1RUVKxYseKyyy679957zzrrrKRH+5xcffXVJSUlSU8BhCGwgOT95S9/+f73v3/NNdfcfvvtBx10UEFBQdeuXb/1rW8tX758xIgRSU8HsMMEFpC8mTNndurU6corr9xueUFBwdVXX934+Oc//3kqlUqlUrm5ub179z7vvPPWrFnTtGXju2kbNmwYMWJEcXHxwIEDn3jiiSiKHnzwwQMOOKBDhw7HHnvsunXrmrZ/6aWXRo4c2blz5w4dOgwZMuTPf/7zZ5/2E57bOEZZWdkZZ5xRXFzco0ePOXPmNH/ufffdN2DAgA4dOhx++OHPP//88ccf31iQEydOvPHGGysqKho/xx49ejQ95RP2Buy0BBaQsEwm8/jjjx955JHt27f/hM0uvPDCxr9RX1NT88c//nH9+vUjRoyor69vvp/LL7/82muvXbNmzZFHHjly5MjHHnvsd7/73SOPPPLSSy+tXbt2woQJjVsuX778q1/9alFR0bPPPrtu3bqTTjpp+PDhzz777GeZ9lOfm8lkJk6ceNlll61bt+7SSy/9/ve//9RTTzWuWrx48be+9a1Ro0atWbPmV7/61fXXX19RUdG4avbs2VdddVWnTp0aP8e1a9d+6t6AnVoGIFHl5eVRFF100UU79KyVK1dGUfR///d/jR9OmjQpiqJFixY1frhp06ZUKrXvvvvW1NQ0LvnJT36Sk5NTXl6eyWROOOGEAQMG1NXVNe3t6KOPHjly5Mce6IYbbigqKmr68JOf2zjGH//4x6a1ffv2HTt2bNOWRx55ZNOqt956Kycn59RTT238sHlgfZa9ATszZ7CAhGUymSiKUqlU05LKyspUM++9914URTU1NTNmzBg4cGDHjh1TqdT+++8fRdHf//73pmfl5uYOGzas8XHXrl1LS0u//OUv5+fnNy7p379/Op1evXp1bW3t4sWLR4wY0a5du6bnHnPMMcuWLfvUUT/Lc3Nzc4cPH9704YABA1atWtX4aT799NMnnXRS06p99tmnf//+n3zEf7c3YCcnsICEderUqWPHjk1vikVRVFxc3Pi/gDNmzGhaePnll99yyy2zZs1au3ZtOp1u3L6urq5pgy5duuTm5jbfSbdu3Zp/GEVRRUXF+++/X1dXN2vWrOYNd8MNN2zZsuVTR/0sz+3SpUvz/OrYsWPj+4BbtmypqanZfffdm++wa9eun3zEf7c3YCcnsICEpVKpY489dtmyZTU1NZ+w2b333jt+/PhTTjmlU6dOqVTqo/fHan4O7N8tiaKoU6dOubm5119//Xbn89Pp9KeO+lme+7EHjaKotLS0ffv2mzZtar6wrKzsk4/47/YG7OQEFpC8K664oqKiYtasWf9ug0wmU1VV1fwq+HvuuadlxyooKBg6dOjChQsbGho+z+emUqnDDjvsT3/6U9OSt99++/XXX2/6sLCwsLa2dkd3C+ycBBaQvCFDhvz4xz+eMmXKhAkTVqxYUVNTU15evmzZsocffjiKosZ34k466aR58+a98MIL5eXlt99++/r161t8uFtuueX1118fPXr0q6++Wl1dvXLlytmzZzdeUd6qz50yZcoTTzwxderUzZs3v/baa5MmTTr44IOb1g4YMKC6unrx4sWf5VwasJMTWMBOYcKECU899dSWLVtOPvnk3Xbbbb/99pswYcKAAQOefvrpxkup7rjjjq9+9avDhg3r16/fihUrZs+e3eJjfelLX3rmmWeiKDrmmGNKS0u/9rWvrV279jNGUpznDhs27J577lmwYEH37t3PP//8a665Jj8/v6CgoHHtyJEjx4wZ841vfCM3N7f5fbCAbJRq/P0dAD5nW7du7dmz50UXXTR9+vSkZwECcwYL4HNSUVExZsyYF198sbq6+pVXXhk9enRNTc0FF1yQ9FxAeAIL4HPSqVOnY445ZsyYMV27dh0yZMi2bdsef/zxfv36JT0XEJ63CAEAAnMGCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDABBYAQGACCwAgMIEFABCYwAIACExgAQAEJrAAAAITWAAAgQksAIDA/j9unjlEtSjESwAAAABJRU5ErkJggg==">


<div class="markdown"><h2>Some Julia syntax used in this code</h2>
<p>Several Julia syntax features have been used in the code for this tutorial. For example, the code block defining <code>gamelengths</code> is a <code>let</code> block. This is similar to a <code>begin/end</code> block in that it groups multiple expressions, including assignments, so that they function as a single expression evaluation. The difference between <code>let</code> and <code>begin</code> is that assignments within a <code>let</code> block are local to the block.</p>
<p>For example, <code>allcounts</code> is given a value within that block because it is used in several places when creating the <code>DataFrame</code> but it is not needed outside that block.</p>
<p>Notice also the expressions like <code>get&#33;&#40;entropy, k, 0&#41;</code>. This is extraction by key from a collection, like <code>entropy&#91;k&#93;</code> or, equivalently, <code>getindex&#40;entropy, k&#41;</code> except that it provides a default, <code>0</code> in this case, if there is no key <code>k</code> in the collection. Furthermore, it modifies the collection by inserting the default value for key <code>k</code>.</p>
<p>An ellipsis, <code>&quot;...&quot;</code>, is used with arguments as in <code>string&#40;wordle.guesspool&#91;1535&#93;...&#41;</code>. This use is called a &quot;splat&quot; &#40;and there is another use of an ellipsis called a &quot;slurp&quot; - the designers of this language are very serious-minded folk&#41;. As a &quot;splat&quot; the ellipsis expands an argument such as a vector or, in this case, the tuple <code>&#40;&#39;r&#39;,&#39;a&#39;,&#39;i&#39;,&#39;s&#39;,&#39;e&#39;&#41;</code> to multiple arguments, in this case, 5 <code>Char</code> arguments.</p>
<p>Another fun name for a construct is a &quot;thunk&quot;, which is a way of specifying an anonymous function. For example there are two methods defined for the <code>entropy2</code> generic</p>
<pre><code class="language-julia">function entropy2&#40;counts::AbstractVector&#123;&lt;:Real&#125;&#41;
    countsum &#61; sum&#40;counts&#41;
    return -sum&#40;counts&#41; do k
        x &#61; k / countsum
        xlogx &#61; x * log&#40;x&#41;
        iszero&#40;x&#41; ? zero&#40;xlogx&#41; : xlogx
    end / log&#40;2&#41;
end

entropy2&#40;gp::GamePool&#41; &#61; entropy2&#40;gp.counts&#41;</code></pre>
<p>In the first method we wish to evaluate <span class="tex">$-\sum_&#123;i&#125;p_i\,\log_2&#40;p_i&#41;$</span> which is sometimes called an <code>xlogx</code> function. There is a <code>sum&#40;f, itr&#41;</code> method where <code>f</code> is a function and <code>itr</code> is an iterator, such as an <code>AbstractVector</code>. In this case we want a function that evaluates <code>x &#61; k / countsum</code> then <code>xlogx&#40;x&#41;</code> but <code>xlogx</code> requires some care. If <code>x</code> is zero, the result should be zero but of the same type as <code>x * log&#40;x&#41;</code> for non-zero <code>x</code>. That&#39;s why <code>x * log&#40;x&#41;</code> is evaluated first - to get the value type. It will return <code>NaN</code> for <code>x &#61; 0</code>, which is then converted to a zero but of the type that is consistent with the other values of <code>xlogx</code>.</p>
<p>For example, to evaluate the base-2 entropy for the initial guess in the <code>BigFloat</code> extended precision type, we convert from</p>
</div>

<pre class='language-julia'><code class='language-julia'>bincounts!(reset!(wordle), 1535); # reset the game to the initial state</code></pre>


<pre class='language-julia'><code class='language-julia'>entropy2(wordle.counts)</code></pre>
<pre id='var-hash179091' class='documenter-example-output'><code class='code-output'>5.877909690821478</code></pre>


<div class="markdown"><p>to</p>
</div>

<pre class='language-julia'><code class='language-julia'>entropy2(big.(wordle.counts))</code></pre>
<pre id='var-hash768185' class='documenter-example-output'><code class='code-output'>5.877909690821480658631076345837703704414854243834085634605204301304453462519103</code></pre>


<div class="markdown"><p>The second method definition for <code>entropy2</code> shows the compact form for defining &quot;one-liner&quot; methods. It is a common idiom to have one method for a generic function that &quot;does the work&quot; and others that simply re-arrange the arguments to the form required by this &quot;collector&quot; method.</p>
</div>
<div class='manifest-versions'>
<p>Built with Julia 1.7.2 and</p>
CairoMakie 0.7.5<br>
Chain 0.4.10<br>
DataFrameMacros 0.2.1<br>
DataFrames 1.3.2<br>
PlutoUI 0.7.38<br>
Primes 0.5.2<br>
StatsBase 0.33.16<br>
Wordlegames 0.3.0
</div>

<!-- PlutoStaticHTML.End -->
~~~