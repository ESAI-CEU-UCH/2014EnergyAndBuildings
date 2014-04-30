set terminal pdf font 'Inconsolata,20'

labels="B-Lin GD-Lin GD-D1 GD-D2"
dir="WORKDIR-COMPARATIVA-BAYES-SGD/"
names="ERRORS-PALOMA-LIN.txt ERRORS-BEST-LINEAR.txt ERRORS-BEST-ONELAYER.txt ERRORS-BEST-TWOLAYERS.txt"
names_mae="STATS-MAE-PALOMA-LIN.txt STATS-MAE-BEST-LINEAR.txt STATS-MAE-BEST-ONELAYER.txt STATS-MAE-BEST-TWOLAYERS.txt"
names_rmse="STATS-RMSE-PALOMA-LIN.txt STATS-RMSE-BEST-LINEAR.txt STATS-RMSE-BEST-ONELAYER.txt STATS-RMSE-BEST-TWOLAYERS.txt"

###############################################################################

set output "plots/pte-le-value.pdf"
set format x "%.1f"
set format y "%.1f"
set xlabel "MAE ºC < x"
set ylabel "Proportion"
set key bottom
set pointsize 0.8
plot [0.0:1.0]for[i=3:6]'ERRORS-PTE-LE-VALUE.txt' u 1:i lw 2.0 w lp title word(labels,i-2)

###############################################################################

margins="0.15 0.3425 0.5450 0.7475 0.95"
colors="1 2 3 4"

set output "plots/stats-mae.pdf"
set xtics (0,15,30)
set multiplot layout 1,5
set format x "%.0f"
set format y "%.2f"
unset xlabel
set ylabel "MAE"
set xlabel "Days" offset 15
set nokey
set pointsize 0.15
set logscale y
do for [i=1:4] {
if (i!=1) {
set format y ""
set xlabel " "
unset ylabel
}
set lmargin at screen word(margins,i)
set rmargin at screen word(margins,i+1)
set title word(labels,i)
plot [0:45][0.008:5]dir.word(names_mae,i) u ($0/96):1 w p lt rgb "#AAAAAA", '' u ($0/96):4 w l lw 6 lc word(colors,i)
}
unset multiplot

###############################################################################

set output "plots/stats-rmse.pdf"
set multiplot layout 1,5
set format y "%.2f"
set xlabel "Days" offset 15
set ylabel "RMSE"
do for [i=1:4] {
if (i!=1) {
set format y ""
set xlabel " "
unset ylabel
}
set lmargin at screen word(margins,i)
set rmargin at screen word(margins,i+1)
set title word(labels,i)
plot [0:45][0.008:5]dir.word(names_rmse,i) u ($0/96):1 w p lt rgb "#AAAAAA", '' u ($0/96):4 w l lw 6 lc word(colors,i)
}
unset multiplot
unset lmargin
unset rmargin
unset logscale y

###############################################################################

set output "plots/errors-comparison.pdf"
set multiplot layout 1,2
set style fill solid 0.25 border -1
set style boxplot sorted outliers pointtype 7
set style data boxplot
set boxwidth  0.6
set pointsize 0.2
set bars 0.8
unset key
set border 2
set xtics nomirror rotate by -45
set ytics nomirror
unset xlabel
set ylabel "MAE ºC"
set format x "%s"
set format y "%.1f"
set xtics (word(labels,1) 1, word(labels,2) 2, word(labels,3) 3, word(labels,4) 4, word(labels,5) 5) scale 0.0
plot [][0.001:]for[i=1:4] '< tail -n 3968 '.dir.word(names,i) u (i):1 title word(labels,i)
set title "Detail"
unset ylabel
plot [][0.001:1.2]for[i=1:4] '< tail -n 3968 '.dir.word(names,i) u (i):1 title word(labels,i)
unset multiplot
