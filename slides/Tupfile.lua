tup.export("D2_THEME")
tup.export("D2_LAYOUT")

local pandoc_flags = {
  "-s",
  "-t revealjs",
  "--slide-level 2",
  "-F pandoc-imagine",
  "-L ./filters/code-include.lua",
  "-L ./filters/revealjs-codeblocks.lua",
  "--template ./templates/main.html",
}

tup.foreach_rule({ "diags/*.puml" }, "plantuml -tsvg %f", { "diags/%B.svg" })
tup.foreach_rule({ "diags/*.d2" }, "d2 %f", { "diags/%B.svg" })

tup.foreach_rule(
  { "slides/*.md" },
  string.format("pandoc %s -o %%o %%f", table.concat(pandoc_flags, " ")),
  { "out/%B.html" }
)
