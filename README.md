# PseudoGame
## About
A library reimplementing some game components on top of a custom rendering system based on custom walls.
## Documentation
The ldoc generated documentation is hosted using github pages [here](https://bauumm.github.io/lib_pseudogame/).

Here's an image showing the game components to go along with it.
![Image showing the game components](https://github.com/Bauumm/lib_pseudogame/blob/main/components.png)
## Contributing
Contributions in the form of issues, suggestions and any kind of feedback are welcome.

If you want to contribute to the source code, make sure to style your code with [stylua](https://github.com/JohnnyMorganz/StyLua) and put doc comments for [ldoc](https://github.com/lunarmodules/LDoc) on public functions or fields. Also make sure to run tests if you make any modifications to the core parts of the library.

So the after making a change you should execute
```
ldoc .
stylua Scripts
cd tests
luajit main.lua
```
This should update the documentation, style the code and run tests.
