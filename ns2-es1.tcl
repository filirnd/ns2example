set ns [new Simulator]
set fd [open out.nam w]
$ns namtrace-all $fd

#Define a 'finish' procedure
proc finish {} {
global ns fd
$ns flush-trace
close $fd; #Close the NAM trace file
exec nam out.nam &
exit 0
}

set n0 [$ns node]
set n1 [$ns node]

$ns duplex-link $n0 $n1 1.5Mb 10ms DropTail

set agent0 [new Agent/TCP]
set agent1 [new Agent/TCPSink]

$ns attach-agent $n0 $agent0
$ns attach-agent $n1 $agent1

$ns connect $agent0 $agent1

set ftp [new Application/FTP]
$ftp attach-agent $agent0

$ns at 0.2 "$ftp start"
$ns at 2.0 "$ftp stop"
$ns at 2.1 "finish"
$ns run
