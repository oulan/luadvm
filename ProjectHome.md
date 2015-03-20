LUADVM means - LUA Delphi Virtual Machine.
So it's LUA virtual Machine Implemented on Delphi.
Standard LUA compiler used for produce LUA P-code,
and LUA\_DVM able to execute it.

It let programmer build LUA scripting for manage internal Delphi Objects,Components,Forms.
Any Published properties of Delphi objects can be accessed without extentions. For using methods some wrappers needs.
There are a lot of Delphi objects wrappers already implemented, so scripts with very complex functionality can be build.

No garbage collector performed. All Delphi objects created and Free explicitly.