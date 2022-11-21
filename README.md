# Breakout Architecture-Exploration (Odin)

This is a (bad) recreation of Breakout to experiment some design decision and test the language. This project is vastly overenginneer compare to normal Breakout, but it was mostly a playground to expriment with some architecture design. I only used SDL in this current project. It's missing some part, but it's grossly complete.

## Odin

Odin is a new language made by Gingerbil. The language is pretty new compare to other one. I find it truly enjoyable. I considered it a little bit hipster because it doesn't follow mainstream concept in this language. This isn't a bad thing! 

### Interesting feature of Odin

- Syntax is very close to mathematical terminology.
- Use of UTF-8 inside the language.
- Idioms like #optional_ok and #soa that enhance greatly the experience.
- Multiple returns supported as a first class citizen
- Named parameters and returns values!
- Swizzle support for arrays
- Matrix, Quaternion supported as first class citizen
- `using` which give access to internal values to the current context. This create a behavior similar to inheritance (in some way) but more broad
- Modern Generics
- Lambda function that match perfectly the procedure syntax declaration
- Explicit overload of function
- Ginger
- Type Assertion .? .(Type)
- Cast and Transmutation


### External Dependencies

This was a concern at first because Odin do not come with a package manager like many modern language. I am traumatized how it was hard to integrate existing library into project some time (I'm talking about you OpenCV). The main author of the language do not like package manager in general. He considered most of (or all of) them flawed. For this reason, it appear that package manager will never be supported. However, because of the current build process in Odin, with gitsubmodule, it is pretty easy to add external library!

### Build and Compilation

Odin is more modern than C and C++ and take advantages of modern features. The build process is simply a oneliner `odin run .` or `odin build .` and do not require external software or manual labor to link outside dependencies. At the same time, compilation time are really fast and much faster than cpp. Compilation can also give interesting feedback when obvious mistake has been done. More could probably been done, but the current team is pretty small as for now and it is already pretty impressive.

### Debugging

Debuggin can be done with lldb,gdb,remedybg,etc.

### Assertion, Error Handling

In the current version, Odin do not support exception. It doesn't seem that the author want to support this feature neither. To achieve similar result, one can use #ok_optional with a bool or an enum to return the current exception. 
In fact, as he see it, he thinks that exception were wrong. Those should be handle as fast as possible. I was dubious at first, but by experimenting with it and #ok_optional, I saw another way to handle mistake. More complex program should be done to experiment with the current process.

### Conclusion

As you can see, Odin is very opionated which have his benefits and issues. In the case of Odin, I would argue that he propose interesting solutions to common issues in programming. As a very strong to point for me, I'm really happy that someone give enough reflection on the actual syntax/semantics. Most of them are coherent. It's very neat that procedure inside a function or outside keep the same syntax.

I truly recommend one to test it and challenge his existing conception about programming.

## Architecture Design

My main focus was to be as flexible as possible while not creating bottleneck. I explore many ideas. I went from

```odin
package main

import "core:fmt"

Position :: struct{
    x,y: int,
}

Velocity :: struct {
    dx,dy: int,
}

//Preset
Entity :: struct {
    derived: union{^Ball,^Brick}
}

Ball :: struct {
    using entity: Entity,
    pos: Position,
    vel: Velocity,
}

Brick :: struct {
    using entity: Entity,
    pos: Position,
}

Scene :: struct {
    entities: [dynamic]Entity,
}

init_scene :: proc() -> (s: Scene) {
}

new_entity :: proc(T: typeid) -> Entity {
    t := new(T)
    t.derived = &t
    return t.entity
}

main :: proc() {
    scene := init_scene()

    append(&scene.entities,new_entity(Ball))
    append(&scene.entities,new_entity(Brick))

    for ent in scene.entities {
        switch e in &ent.derived {
            case Ball:
                fmt.println(e.position)
            case Brick:
                fmt.println(e.position)
        }
    }

    for ent in scene.entities {
        #partial switch e in &ent.derived {                
            case Ball:
                fmt.println(e.velocity)
        }
    }

    for ent in scene.entities {
        #partial switch e in &ent.derived {                
            case Ball:
                fmt.println("Ball", e.position,e.velocity)
        }
    }

}

```

to

```odin
package main

import "core:fmt"

Position :: struct{
    x,y: int,
}

Velocity :: struct {
    dx,dy: int,
}

//Preset
Ball :: struct {
    pos: Position,
    vel: Velocity,
}

Brick :: struct {
    pos: Position,
}

Archetype :: struct{
    //similar to add a bit_set because union in Odin keep tag
    pos: Maybe([dynamic]Position),
    vel: Maybe([dynamic]Velocity),
}

Scene :: struct {
    archetypes: [2]Archetype,
}

init_scene :: proc() -> (s: Scene) {
    s.archetypes[0].pos = make([dynamic]Position)
    s.archetypes[0].vel = make([dynamic]Velocity)

    s.archetypes[1].pos = make([dynamic]Position)
    s.archetypes[1].vel = nil

    return
}

add_entity_ball :: proc(scene: ^Scene, ball: Ball) {
    append(&scene.archetypes[0].pos.?,ball.pos)
    append(&scene.archetypes[0].vel.?,ball.vel)

}
add_entity_brick :: proc(scene: ^Scene, brick: Brick) {
    append(&scene.archetypes[1].pos.?,brick.pos)
}
add_entity :: proc{add_entity_ball,add_entity_brick}

main :: proc() {
    scene := init_scene()

    add_entity(&scene,Brick{{10,10}})
    add_entity(&scene,Ball{{2,2},{1,1}})

    for a in scene.archetypes {
        if ps, ok := a.pos.?; ok {
            for p in ps {
                fmt.println("Position", p)
            }
        }
    }

    for a in scene.archetypes {
        if vs, ok := a.vel.?; ok {
            for v in vs {
                fmt.println("Velocity", v)
            }
        }
    }

    {
        a := scene.archetypes[0]

        ps := a.pos.?
        vs := a.vel.?

        nb := len(ps)

        for i in 0..<nb {
            fmt.println("Ball", ps[i],vs[i])
        }
    }

    //Optional
    for a in scene.archetypes {
        ps, okp := a.pos.?
        vs, okv := a.vel.?

        if okp && okv {
            nb := len(ps)

            for i in 0..<nb {
                fmt.println("p+v", ps[i],vs[i])
            }
        }
    }
}
```
