# # Tutorial 🐧

# This is a gentle and lighthearted tutorial on how to use tools from AlgebraOfGraphics,
# using as example dataset a collection of measurements on penguins[^1]. See 
# the [Palmer penguins website](https://allisonhorst.github.io/palmerpenguins/index.html)
# for more information.
#
# [^1]: Gorman KB, Williams TD, Fraser WR (2014) Ecological Sexual Dimorphism and Environmental Variability within a Community of Antarctic Penguins (Genus Pygoscelis). PLoS ONE 9(3): e90081. [DOI](https://doi.org/10.1371/journal.pone.0090081)

using PalmerPenguins, DataFrames

penguins = dropmissing(DataFrame(PalmerPenguins.load()))
first(penguins, 6)

# ## Frequency plots
#
# Let us start by getting a rough idea of how the data is distributed

using AlgebraOfGraphics, CairoMakie
set_aog_theme!()

axis = (width = 225, height = 225)
penguin_frequency = data(penguins) * frequency() * mapping(:species)
draw(penguin_frequency; axis)

# Next, let us see whether the distribution is the same across islands.

plt = penguin_frequency * mapping(color = :island)
draw(plt; axis)

# Ups! The bars are in the same spot and are hiding each other. We need to specify
# how we want to fix this. Bars can either `dodge` each other, or be `stack`ed on top
# of each other.

plt = penguin_frequency * mapping(color = :island, dodge = :island)
draw(plt; axis)

# This is our first finding. `Adelie` is the only species of penguins that can be
# found on all three islands. To be able to see both which species is more numerous
# and how different species are distributed across islands in a unique plot, 
# we could have used `stack`.

plt = penguin_frequency * mapping(color = :island, stack = :island)
draw(plt; axis)

# ## Correlating two variables
#
# Now that we have understood the distribution of these three penguin species, we can
# start analyzing their features.

penguin_bill = data(penguins) * mapping(:bill_length_mm, :bill_depth_mm)
draw(penguin_bill; axis)

# We would actually prefer to visualize these measures in centimeters, and to have
# cleaner axes labels. As we want this setting to be preserved in all of our `bill`
# visualizations, let us save it in the variable `penguin_bill`, to be reused in
# subsequent plots.

penguin_bill = data(penguins) * mapping(
    :bill_length_mm => (t -> t / 10) => "bill length (cm)",
    :bill_depth_mm => (t -> t / 10) => "bill depth (cm)",
)
draw(penguin_bill; axis)

# Much better! Note the parentheses around the function `t -> t / 10`. They are
# necessary to specify that the function maps `t` to `t / 10`, and not to
# `t / 10 => "bill length (cm)"`.

# There does not seem to be a strong correlation between the two dimensions, which
# is odd. Maybe dividing the data by species will help.

plt = penguin_bill * mapping(color = :species)
draw(plt; axis)

# Ha! Within each species, penguins with a longer bill also have a deeper bill.
# We can confirm that with a linear regression

plt = penguin_bill * linear() * mapping(color = :species)
draw(plt; axis)

# This unfortunately no longer shows our data!
# We can use `+` to plot both things on top of each other:

plt = penguin_bill * linear() * mapping(color = :species) + penguin_bill * mapping(color = :species)
draw(plt; axis)

# Note that the above expression seems a bit redundant, as we wrote the same thing twice.
# We can "factor it out" as follows

plt = penguin_bill * (linear() + mapping()) * mapping(color = :species)
draw(plt; axis)

# where `mapping()` is a neutral multiplicative element.
# Of course, the above could be refactored as

layers = linear() + mapping()
plt = penguin_bill * layers * mapping(color = :species)
draw(plt; axis)

# We could actually take advantage of the spare `mapping()` and use it to pass some
# extra info to the scatter, while still using all the species members to compute
# the linear fit. 

layers = linear() + mapping(marker = :sex)
plt = penguin_bill * layers * mapping(color = :species)
draw(plt; axis)

# This plot is getting a little bit crowded. We could instead analyze female and
# male penguins in separate subplots.

layers = linear() + mapping(col = :sex)
plt = penguin_bill * layers * mapping(color = :species)
draw(plt; axis)

# ## Smooth density plots
#
# An alternative approach to understanding how two variables interact is to consider
# their joint probability density distribution (pdf).

using AlgebraOfGraphics: density
plt = penguin_bill * density(npoints=50) * mapping(col = :species)
draw(plt; axis)

# The default colormap is multi-hue, but it is possible to pass single-hue colormaps as well:

plt *= visual(colormap = :grayC)
draw(plt; axis)

# A `Heatmap` (the default visualization for a 2D density) is a bit unfortunate if
# we want to mark species by color. In that case, one can use `visual` to change
# the default visualization and, optionally, fine tune some arguments.
# In this case, a `Wireframe` with thin lines looks quite nice. (Note that, for the
# time being, we must specify explicitly that we require a 3D axis.)

axis = (type = Axis3, width = 300, height = 300)
layer = density() * visual(Wireframe, linewidth=0.05)
plt = penguin_bill * layer * mapping(color = :species)
draw(plt; axis)

# Of course, a more traditional approach would be to use a `Contour` plot instead:

axis = (width = 225, height = 225)
layer = density() * visual(Contour)
plt = penguin_bill * layer * mapping(color = :species)
draw(plt; axis)

# The data and the linear fit can also be added back to the plot:

layers = density() * visual(Contour) + linear() + mapping()
plt = penguin_bill * layers * mapping(color = :species)
draw(plt; axis)

# In the case of many layers (contour, density and scatter) it is important to think
# about balance. In the above plot, the markers are quite heavy and can obscure the linear
# fit and the contour lines.
# We can lighten the markers using alpha transparency.

layers = density() * visual(Contour) + linear() + visual(alpha = 0.5)
plt = penguin_bill * layers * mapping(color = :species)
draw(plt; axis)

# ## Correlating three variables
#
# We are now mostly up to speed with `bill` size, but we have not consider how
# it relates to other penguin features, such as their weight.
# For that, a possible approach is to use a continuous color
# on a gradient to denote weight and different marker shapes to denote species.
# Here we use `group` to split the data for the linear regression without adding
# any additional style.

body_mass = :body_mass_g => (t -> t / 1000) => "body mass (kg)"
layers = linear() * mapping(group = :species) + mapping(color = body_mass, marker = :species)
plt = penguin_bill * layers
draw(plt; axis)

# Naturally, within each species, heavier penguins have bigger bills, but perhaps
# counter-intuitively the species with the shallowest bills features the heaviest penguins.
# We could also try and see the interplay of these three variables in a 3D plot.

axis = (type = Axis3, width = 300, height = 300)
plt = penguin_bill * mapping(body_mass, color = :species)
draw(plt; axis)

#

plt = penguin_bill * mapping(body_mass, color = :species, layout = :sex)
draw(plt; axis)

# Note that static 3D plot can be misleading, as they only show one projection
# of 3D data. They are mostly useful when shown interactively.
