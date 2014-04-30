set terminal pdf font 'Inconsolata,14'

set style fill solid 0.25 border -1
set style boxplot sorted outliers pointtype 7
set style data boxplot
set boxwidth  0.6
set pointsize 0.1
set bars 0.4

unset key
set border 2

set xtics auto
set xtics nomirror
set ytics nomirror

#set xlabel "Input size"
#set ylabel "%"
#set tics rotate by 45
#set xtics out offset -2,-2.0

set format y "%3.1f"

labels="0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.5 2.0"

do for [name in "LINEAR ONELAYER TWOLAYERS"] {

set output "plots/box-plot-SIZE-".name.".pdf"
set multiplot layout 2,2 # title "% of points with MAE < alpha for different input sizes"
do for [i in "10 14 18 24"] {
inti = int(i)
if (inti==10 || inti==14) {
unset xtics;
}
else {
set xtics auto
set xtics nomirror
}
if (inti==10 || inti==18) {
set ytics format "%.1f";
}
else {
set ytics format "";
}
set title "MAE < ".word(labels,(int(i)-6)/2+1)."ºC"
plot [][0.0:1]'experiments-'.name.'/PTE-LE-VALUE.unsorted' u (1):int(i):(0):1
}
unset multiplot

}

do for [name in "LINEAR ONELAYER TWOLAYERS"] {

set xtics rotate by 45
set xtics auto offset -1,-1.0
set xtics scale 0 font ",8"
set output "plots/box-plot-LR-".name.".pdf"
set multiplot layout 2,2 # title "% of points with MAE < alpha for different learning rates"
do for [i in "10 14 18 24"] {
set title "MAE < ".word(labels,(int(i)-6)/2+1)."ºC"
inti = int(i)
if (inti==10 || inti==14) {
unset xtics;
}
else {
set xtics rotate by 45
set xtics auto offset -1,-1.0
set xtics scale 0 font ",10"
}
if (inti==10 || inti==18) {
set ytics format "%.1f";
}
else {
set ytics format "";
}
plot [][0.0:1]'experiments-'.name.'/PTE-LE-VALUE.unsorted' u (1):int(i):(0):2
}
unset multiplot

set output "plots/box-plot-MT-".name.".pdf"
set multiplot layout 2,2 # title "% of points with MAE < alpha for different momentums"
do for [i in "10 14 18 24"] {
set title "MAE < ".word(labels,(int(i)-6)/2+1)."ºC"
inti = int(i)
if (inti==10 || inti==14) {
unset xtics;
}
else {
set xtics rotate by 45
set xtics auto offset -1,-1.0
set xtics scale 0 font ",10"
}
if (inti==10 || inti==18) {
set ytics format "%.1f";
}
else {
set ytics format "";
}
plot [][0.0:1]'experiments-'.name.'/PTE-LE-VALUE.unsorted' u (1):int(i):(0):3
}
unset multiplot

}
