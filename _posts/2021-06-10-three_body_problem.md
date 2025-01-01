---
layout: post
title: The Three-Body Problem, Revisited Statistically
date: 2021-06-10
summary: Astrophysicists proposed a solution to the three-body problem inspired by statistical mechanics.
categories: blog
katex: True
---

Many things go by a rule of three. A trio of words often creates a satisfying 
flow in prose or speech; a triad of notes helps construct the feel-good harmonies 
in a tune; a triple deity (such as the Holy Trinity) prevails throughout various 
cultures and religions. Three is also a magical number in physics. There are 
three spatial dimensions, three generations of particles, and three identical 
bosons that comprise the exotic 
[Efimov state](https://www.quantamagazine.org/in-efimov-state-physicists-find-a-surprising-rule-of-threes-20140527/){%
    sidenote "sn-id-1" "A bound quantum state that manifests among three bosons
    (forming trimers) even if the two-particle interaction is insufficient to 
    form bound pairs."
%}.
Throw three massive objects together, and you now have the "three-body problem".

The problem is the following: given three point masses under the influence of 
only their mutual gravitational attraction, how will their trajectories evolve 
if we know their initial positions and velocities? Writing in his 1687 
masterpiece *Principia*, Isaac Newton formulated and solved the preceding two-body 
problem, where two masses are considered instead of three, with relative ease. 
The solutions are the familiar circular, elliptic, parabolic, or hyperbolic orbits 
that many physics students encounter in their first foray into celestial mechanics. 
Newton also took the first steps in tackling the three-body problem; little did 
he know, however, that it would remain unsolved today, over 300 years later.

To be precise, the question is unsolved in the sense that no general closed-form 
solution (*i.e.* exact formula for the orbits) is known to exist. Nevertheless, 
mathematicians and physicists have chipped away at the problem for centuries by 
providing explicit formulas for the orbits in special cases. The list of brave 
pioneers who have attacked the problem---Leonhard Euler, Joseph-Louis Lagrange, 
Henri Poincare, to name a few---hints at the problem's difficulty. A natural 
question arises: how is it that when we add an additional mass to the two-body 
case, governed under the simplicity of Newton's laws of motion, we face such 
notorious adversity in predicting the trajectories?

In the 1890s, Poincare discovered that the three-body problem exhibited chaotic 
dynamics. That is, the evolution of the system is random due to its extreme 
sensitivity to initial conditions. This leads to unpredictability in long-term, 
despite it being described by deterministic physical laws. Poincare thence showed 
that the general three-body problem is analytically unsolvable and provided an 
explanation for the difficulty even in finding exact solutions under restricted 
conditions.

Theorists have since branched into developing techniques to generate approximate 
solutions as ongoing efforts searched for explicit formulas under new families 
of conditions. Such approximate methods include perturbation theory, which 
produces solutions expressed in an infinite series; and numerical integration, 
whereby finite segments of orbits are calculated on a computer. A third 
approach---one inspired by statistical mechanics - has also been gaining traction.

## Probable solutions
In 2019, astrophysicists 
[Nicholas Stone](https://phys.huji.ac.il/people/nicholas-chamberlain-stone) 
and [Nathan Leigh](http://www.astro.udec.cl/e/people/profs/nl.html)
from the Hebrew University of Jerusalem's Racah Institute of Physics and 
Chile's La Universidad de Concepción, respectively, derived a 
[statistical solution](https://www.nature.com/articles/s41586-019-1833-8) 
to the chaotic, non-hierarchical three-body problem. While hierarchical regimes 
refer to situations where the masses or separations of the three bodies differ 
greatly, non-hierarchical regimes impose no such restrictions. This lack of a 
scale hierarchy has made analytical solutions describing a resulting orbit 
intractable in the latter regimes, compared to the former where analytic 
treatments exist. On the contrary, the statistical solution of Stone and Leigh 
takes the form of a probability distribution over a set of outcome trajectories.

The key to the duo's approach is to leverage the chaotic nature of the trinary 
system instead of being intimidated by it. In particular, chaos allows one to 
reasonably invoke the ergodic hypothesis, which states that the system will 
uniformly explore the phase space volume accessible to it over a sufficiently 
long time. The assumption draws parallels with the microcanonical ensemble in 
statistical physics---the three bodies being isolated from their environment is 
analogous to a particle system not interacting with a heat bath. "In this way, 
we may turn the chaotic nature of the three-body problem---which has so far 
frustrated general, deterministic, analytic mappings from one set of initial 
conditions to one set of outcomes - into a tool that simplifies the mapping from 
distributions of initial conditions to distributions of outcomes, " they explained 
in their paper, published in *Nature*.

Numerical integrations have shown that bound, non-hierarchical triple systems 
{% 
    marginfigure "mf-id-1" "assets/images/three_body_problem/fig1.jpeg" 
    "*(a)* Two-dimensional projection of the chaotic trajectories exhibited by three 
    interacting bodies. An interloper star (red) encounters a binary (blue and black), 
    forming an interacting trinary system before disintegrating in a partner swap. 
    *(b)* Schematic illustration of the metastable trinary system at the moment of 
    disintegration. *Source:* Stone and Leigh (2019)."
%}
almost always disintegrate into a single escaping mass (the "escaper") and a 
stable bound binary (the "surviving binary"). Considering this generic outcome, 
Stone and Leigh's results built upon prior work involving similar statistical 
strategies dating back to 1976. Such analyses, however, were limited in several 
aspects: they yielded poor predictive power when verified against detailed numerical 
approaches, involved such mathematical difficulty that prevented the calculation 
of closed-form outcome distributions, or were only adequate for highly constrained 
configurations. The shortcomings have been attributed to several reasons. For one, 
early attempts failed to include the conservation of angular momentum in their 
derivations, which was assumed to be appropriate for low angular momentum systems. 
Even when such a kinetic constraint was accounted for, theorists were able to 
present a fully analytical formalism only for the special case of planar motion. 
Thirdly, and perhaps where Stone and Leigh made the most improvement, is that the 
interaction energy between the escaper and surviving binary was neglected.

## A step forward
The researchers began with a general geometry and built into their formalism an 
interaction energy between the escaper and surviving binary, in addition to the 
conservation of angular momentum. Not shy to the rule of three themselves, they 
made three significant assumptions: (i) the ergodic hypothesis; (ii) that the 
disintegration in the triple system is instantaneous; and (iii) that the escaper 
sees the receding binary as a point particle. As explained earlier, assumption 
(i) underpins Stone and Leigh's results. Assumption (ii) is vital in calculating 
the probability distributions from the accessible phase space. Assumption (iii) 
factors into the interaction between the escaper and binary. Overall, their 
derivation bore out of fewer premises compared to their predecessors.

Working through pages of complex integrals and grueling algebra, the duo succeeded 
in producing a mathematically well-defined (that is, non-divergent) estimate of 
the phase space volume and ultimately a closed-form expression for the distribution 
of outcomes. Their distributions are also qualitatively different compared to those 
from past analyses.

## Comparing against numerical experiments
Thus, having established appropriate presumptions and powered through the math, 
here comes the third act---testing the results. The pair executed this stage by 
conducting a series of numerical experiments and comparing the outcomes with their 
probability distributions. They numerically integrated the equations of motion 
starting from initial conditions that described several ensembles of non-hierarchical 
three-body systems. This generated ensembles of orbits from which an empirical 
distribution was constructed. It is here that they ran into a worrying observation.

"Many of our [experiments] do not form resonant three-body systems, but instead 
resolve abruptly in a prompt exchange, where it is unlikely that the ergodic 
hypothesis can be applied," they noted in their paper. A resonant three-body system 
describes triples that exert regular, periodic gravitational forces on each other 
over a time interval, which can place the system in a metastable state. For the 
ergodic hypothesis to be valid, interactions will have to unfold over several 
dynamical times before the system disintegrates, allowing for chaotic evolution 
to arise.

But there must be a resolution to the conundrum. Indeed, Stone and Leigh found 
a key dynamical mechanism that helped them identify subsets of experiments 
exhibiting a high degree of ergodicity---the "scramble". As frisky as its name is, 
a scramble is defined as a period of time when no pairwise binaries exist in the 
trinary system. This occurs when all three bodies interact so strongly with each 
other that they enter a phase of intense chaos. The researchers kept track of the 
number of scrambles throughout each integration in each ensemble and used it to 
filter trajectories that are suitably "ergodicized". With this extra tool in hand, 
they returned to comparing their derived distributions against the numerical experiments.

"We...find good agreement, so long as we restrict ourselves to 'resonant' encounters," 
Stone and Leigh concluded in their paper. These "'resonant' encounters" are precisely 
the trajectories that include multiple scrambles and undergo chaotic evolution. 
Of course, as with any research endeavor, there are still aspects to improve upon. 
"In most cases we see data that match analytic predictions to leading order but 
also exhibit some level of higher-order structure, " they cautioned, "The nature 
of these superimposed, second-order structures is not altogether clear." The 
investigation of these features has been deferred to future work.

## Epilogue
The duo's findings are not only interesting from a mathematical point of view 
but also have substantial applications in the study of astrophysical processes. 
Three-body processes are ubiquitous in the universe and are responsible for 
phenomena, including planetary evolution in the solar system, binary–single star 
scattering in dense star clusters, and the formation of binary black holes. 
In particular, Stone and Leigh cite the study of leftover binaries produced in 
binary–single scattering events as a possible application of their formalism.

In the arena of celestial mechanics, it seems that one's lonely, two's company, 
and three's a chaotic crowd. As we've seen, chaos doesn't just spell trouble, 
though---it allowed one statistical inspiration to lead two to tackle the 
three-body problem, bringing to the fore intriguing new results. Moreover, one 
can't deny the beautiful connection the problem has threaded between brilliant 
thinkers through the fabric of time. Stone and Leigh now add their names to the 
ends of that thread, having helped chip away at the centuries-old problem's defenses.
