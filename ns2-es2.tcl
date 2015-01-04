#istanzio lo scheduler
set ns [new Simulator]

#definisco colori differenti per flussi dati (per NAM)
$ns color 1 Blue
$ns color 2 Red
$ns color 3 Green

#Apro il file trace di NAM
set nf [open out.nam w]
$ns namtrace-all $nf

#Procedura finish 
proc finish {} {
	global ns nf
	$ns flush-trace
	#Chiudo il file trace di nam
	close $nf
	#avvio NAM sul trace file
	exec nam out.nam &
	exit 0
}



#creo nuovi nodi (4)
set n0 [$ns node]
set n1 [$ns node]
set n2 [$ns node]
set n3 [$ns node]

#creo link tra nodi
$ns duplex-link $n0 $n2 2Mb 10ms DropTail
$ns duplex-link $n1 $n2 2Mb 10ms DropTail
$ns duplex-link $n2 $n3 1.7Mb 20ms DropTail

 #limito la size della coda del link n2-n3 a 10
$ns queue-limit $n2 $n3 10




#Setto la connessione TCP
set tcp [new Agent/TCP]
$ns attach-agent $n0 $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $n3 $sink
$ns connect $tcp $sink
$tcp set fid_ 1


#creo connessione FTP sulla tcp
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ftp set type_ FTP


#setto connessione UDP
set udp [new Agent/UDP]
$ns attach-agent $n1 $udp
set null [new Agent/Null]
$ns attach-agent $n3 $null
$ns connect $udp $null
$udp set fid_ 2

#creo connessione cbr su udp
set cbr [new Application/Traffic/CBR]
$cbr attach-agent $udp
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set rate_ 1mb
$cbr set random_ false


#Scheduler di eventi
$ns at 0.1 "$cbr start"
$ns at 0.5 "$ftp start"
$ns at 2 "$ftp stop"
$ns at 3 "$cbr stop"

#chiamo la procedura finishs
$ns at 3.5  "finish"


#avvio la simulazione
$ns run


