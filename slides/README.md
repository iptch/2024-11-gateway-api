# Slides

A repository containing all my presentations.

## Generating Slides

Slides can be generated using the Tupfile once in the Devbox shell:

```bash
tup
```

or directly with `devbox run build`.

## Animations

See https://github.com/rajgoel/reveal.js-demos/tree/master for demos on how to animate stuff.

## D2

> [!NOTE]
> Diagrams in the `diags` folder will be automatically generated with `tup`.

To render D2, run:

```bash
d2 input.d2
```

### Animations

Note that the IDs of the entities and relationships are always called:

- `<id>`: for entities
- `(<from> -&gt; <to>)[0]`: for relationships

These IDs can then easily be used by revealJS for animating the C4 diagrams.

## PlantUML

> [!NOTE]
> Diagrams in the `diags` folder will be automatically generated with `tup`.

To render PlantUML, run:

```bash
plantuml -tsvg input.puml
```

### Animations

Note that the IDs of the entities and relationships are always called:

- `elem_<id>`: for entities
- `link_<from>_<to>`: for relationships

These IDs can then easily be used by revealJS for animating the C4 diagrams.

## Presenting

In order to present stuff using animations, use `miniserve`.
