set terminal pdf font 'Inconsolata,8'

set output 'forcast-ENERGIES.pdf'
set multiplot layout 3,28
unset xtics
unset ytics
set lmargin 0.2
set rmargin 0.2
set bmargin 0.2
set tmargin 0.2
do for [pos=12:96:1] {
pos2=pos
plot [][18:26]'ENERGIES-TEST.log' u pos2 w lp ps 0.4 notitle, \
     'ENERGIES.log' u pos w lp ps 0.4 notitle
}
unset multiplot

set output 'forcast-plot.pdf'
set multiplot layout 3,28
unset xtics
unset ytics
set lmargin 0.2
set rmargin 0.2
set bmargin 0.2
set tmargin 0.2
do for [pos=384:468:1] {
plot [][17:24.2]'BEST/BEST-TARGETS-LINEAR.transposed.txt' u pos w lp ps 0.4 notitle, \
     'BEST/BEST-OUTPUTS-LINEAR.transposed.txt' u pos w lp ps 0.4 notitle
}
unset multiplot

set output 'forcast-plot2.pdf'
set multiplot layout 3,28
unset xtics
unset ytics
set lmargin 0.2
set rmargin 0.2
set bmargin 0.2
set tmargin 0.2
do for [pos=3360:3444:1] {
plot [][19:28]'BEST/BEST-TARGETS-LINEAR.transposed.txt' u pos w lp ps 0.4 notitle, \
     'BEST/BEST-OUTPUTS-LINEAR.transposed.txt' u pos w lp ps 0.4 notitle
}
unset multiplot

# set output "jarl.pdf"
# set pointsize 0.3
# plot for [pos=1:4000:12] 'BEST/BEST-OUTPUTS-LINEAR.transposed.txt' u ($0+pos):pos lt 2 w lp notitle

# set output "jarl.pdf"
# replot for [pos=1:4000:12] 'BEST/BEST-TARGETS-LINEAR.transposed.txt' u ($0+pos):pos lw 3 lt 1 w l notitle
