set terminal pdf font 'Inconsolata,20'

dir="WORKDIR-COMPARATIVA-BAYES-SGD/"
names_mae="STATS-MAE-BEST-LINEAR.txt"
names_rmse="STATS-RMSE-BEST-LINEAR.txt"

###############################################################################

set output "plots/stats-mae-econference.pdf"
set xtics (0,10,20,30,40) font ",10"
set format x "%.0f"
set format y "%.2f"
set ylabel "MAE"
set xlabel "Days"
set nokey
set pointsize 0.15
set title "GD-Lin"
plot [0:45][0.008:2]dir.names_mae u ($0/96):1 w p lt rgb "#AAAAAA", '' u ($0/96):4 w l lw 6 lc 1

###############################################################################

set output "plots/stats-rmse-econference.pdf"
set format y "%.2f"
set xlabel "Days"
set ylabel "RMSE"
set title "GD-Lin"
plot [0:45][0.008:2]dir.names_rmse u ($0/96):1 w p lt rgb "#AAAAAA", '' u ($0/96):4 w l lw 6 lc 1
