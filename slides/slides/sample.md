---
title: Sample Slides
author: Jakob Beckmann
date: 28.02.2022
theme: moon
revealjs-url: "https://unpkg.com/reveal.js@5.1.0"
progress: false
controls: false
hash: true
highlightjs: true
animate: true
---

# Slide 1 {data-background="../assets/sample/tron_legacy5.jpg"}

<!-- can also use a URL for source -->

## Incremental lists

::: incremental
- Point 1
- Point 2
- Point 3
:::

## Pauses

This and ...

<!-- below is a pause -->
. . .

[link](https://google.com)!

## Quotes

> A quote!

## Tables

| header1 | header2 |
| ---     | ----    |
| data    | data    |
| data2   | other   |

## Inline Code

some `inline` code

## Columns

:::::::::::::: {.columns}
::: {.column width="40%"}
contents...
:::
::: {.column width="60%"}
more contents...
:::
::::::::::::::

# Examples

## Include Code

```{.python include="./assets/sample/app.py" dedent=4 start-line=12 end-line=13 .numberLines data-line-numbers="1|2"}
```

<!-- include for code is relative to base directory -->

## Sub-Slide Code {data-transition="zoom"}

```{.python data-line-numbers="1-3|2"}
def sample_function(name: str, arg: int):
    if arg > 0:
        # comment
        return 42
    return f"this is a {name}"
```

# annimations

## {data-auto-animate=true}

<pre data-id="code-animation"><code data-trim data-line-numbers>
  let planets = [
    { name: 'mars', diameter: 6779 },
  ]
</code></pre>

## {data-auto-animate=true}
<pre data-id="code-animation"><code data-trim data-line-numbers>
  let planets = [
    { name: 'mars', diameter: 6779 },
    { name: 'earth', diameter: 12742 },
    { name: 'jupiter', diameter: 139820 }
  ]
</code></pre>

## {data-auto-animate=true}
<pre data-id="code-animation"><code data-trim data-line-numbers>
  let circumferenceReducer = ( c, planet ) => {
    return c + planet.diameter * Math.PI;
  }

  let planets = [
    { name: 'mars', diameter: 6779 },
    { name: 'earth', diameter: 12742 },
    { name: 'jupiter', diameter: 139820 }
  ]

  let c = planets.reduce( circumferenceReducer, 0 )
</code></pre>

# svg annimations

## {data-auto-animate=true}

<span class="fragment"></span>
<span class="fragment"></span>
<span class="fragment"></span>
<span class="fragment"></span>
<span class="fragment"></span>
<span class="fragment"></span>
<span class="fragment"></span>
<span class="fragment"></span>

<div data-animate data-load="../assets/sample/decisiontree.svg">
<!--
{ "setup": [
{ "element": "#Price", "modifier": "attr", "parameters": [ {"class": "fragment", "data-fragment-index": "0"} ] },
{ "element": "#Host1", "modifier": "attr", "parameters": [ {"class": "fragment", "data-fragment-index": "1"} ] },
{ "element": "#Choice11", "modifier": "attr", "parameters": [ {"class": "fragment", "data-fragment-index": "2"} ] },
{ "element": "#Choice12", "modifier": "attr", "parameters": [ {"class": "fragment", "data-fragment-index": "3"} ] },
{ "element": "#Host2", "modifier": "attr", "parameters": [ {"class": "fragment", "data-fragment-index": "4"} ] },
{ "element": "#Choice2", "modifier": "attr", "parameters": [ {"class": "fragment", "data-fragment-index": "5"} ] },
{ "element": "#Host3", "modifier": "attr", "parameters": [ {"class": "fragment", "data-fragment-index": "6"} ] },
{ "element": "#Choice3", "modifier": "attr", "parameters": [ {"class": "fragment", "data-fragment-index": "7"} ] }
]}
-->
</div>

# plantuml

##

![](../diags/sample-c4-diagram.svg)
