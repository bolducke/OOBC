# Overengineer/Overthink Breakout Clone (Odin)

## Motivation
As a hobby and with a desire to learn and explore programming design, I developed a small Breakout Game using Odin (C-like Language) and SDL in my free time. I intentionally over-engineered the project to more easily detect the pain points of my design.

My goal was to create a flexible product that is easy to refactor and add features to while not compromising too much on performance by using a cache-friendly approach. However, because I was more interested in the overall architecture, I didn’t focus much on performance. I deliberately avoided OOP to explore alternative modes of thought.

You can see a breakdown of the design at [blog](https://bolducke.github.io/blog/2023/design_takeaway_ecsarchetype/)

## Main Features

* ECS-like Architecture without any framework
* Hierarchy (Tree-Like) Relation between Entity
* True Separation between Geometry Intersection Algorithm and Physics Computation
    * Geometric Algorithm to Detect Collision, Intersection, Compute Centroid for a small set of "Geometry".
    * "Advanced" Physic Sim (Based on my old Physic Engine)
        * Multiples Integrators: RK4, Explicit Euler, Semi-Implicit Euler
        * Contact Resolution in two steps: Position Based Solver & Velocity Based Solver *(Inspired of Box2D)*
* Text/Font support
* Affine Transform Matrix

## Credits

The contact resolution solver was inspired by https://box2d.org/ works.
