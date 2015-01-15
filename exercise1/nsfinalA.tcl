#exercise A
#caculate variance and confidence range transfer times of two packet (100MB and 20MB)  


#create simulator and node

set ns [new Simulator]


set A [$ns node]
set B [$ns node]
set C [$ns node]
set D [$ns node]




#AB and CD link
$ns duplex-link $A $B 100Mb 1ms DropTail
$ns duplex-link $C $D 100Mb 1ms DropTail

#BC and CB asimmetric
$ns simplex-link $B $C 7Mb 200ms DropTail
$ns simplex-link $C $B 480Kb 200ms DropTail



#set pkt lossrate for error models
set lossrate 0.005

#error models (error BC, error CB)
set error [new ErrorModel]
$error unit EU_PKT
$error set rate_ $lossrate
$error ranvar [new RandomVariable/Uniform]
$error drop-target [new Agent/Null]

set error2 [new ErrorModel]
$error2 unit EU_PKT
$error2 set rate_ $lossrate
$error2 ranvar [new RandomVariable/Uniform]
$error2 drop-target [new Agent/Null]

#attach error model to links
$ns lossmodel $error $B $C;
$ns lossmodel $error2 $C $B;


#agent tcp A
set agentAsend [new Agent/TCP]
set agentArec [new Agent/TCPSink]


#agent tcp D
set agentDsend [new Agent/TCP]
set agentDrec [new Agent/TCPSink]

#agents - nodes linking
$ns attach-agent $A $agentAsend
$ns attach-agent $A $agentArec
$ns attach-agent $D $agentDsend
$ns attach-agent $D $agentDrec

#connect agents
$ns connect $agentAsend $agentDrec
$ns connect $agentDsend $agentArec


#ftp app
set ftpAD [new Application/FTP]
set ftpDA [new Application/FTP]
$ftpAD attach-agent $agentAsend
$ftpDA attach-agent $agentDsend


#queue limit (BC)
$ns queue-limit $B $C 20
$ns queue-limit $C $B 20

#pkts to send
set bytesAD [expr 100 * 1024 * 1024]
set bytesDA [expr 20 * 1024 * 1024]


#timing var for test
set timePassed 0
set timeTest 0
set timeSlice 0.1

#max acks 
set maxackAD [expr $bytesAD / [$agentAsend set packetSize_]]
set maxackDA [expr $bytesDA / [$agentDsend set packetSize_]]


#number of tests
set countTest 0
set totTest 10

#array of tests times
set times(0) 0 



set sum 0
set variance 0


puts ""
puts "======================= Start script - Total Tests $totTest ======================="
puts ""
#procedure that start test (called for all test)
proc startTest {} { 
	
	global timeAD timeDA bytesAD bytesDA timePassed timeTest timeSlice agentAsend agentDsend maxackAD maxackDA ftpAD ftpDA countTest
	puts "Start test number $countTest"
	set ns [Simulator instance]	
	#puts "TIMETEST $timeTest"
	set maxackAD [expr $bytesAD / [$agentAsend set packetSize_]]
	set maxackDA [expr $bytesDA / [$agentDsend set packetSize_]]
	$ns at $timePassed "$ftpAD send $bytesAD"
	$ns at $timePassed "$ftpDA send $bytesDA"
	$ns at $timePassed "checker"
	$ns run

}


#procedure that check time for every test
proc checker {} {
	global timeAD timeDA bytesAD bytesDA timePassed timeSlice agentAsend agentDsend maxackAD maxackDA timeTest
	set ns [Simulator instance]
	
	#puts "Enter in checker with time $timePassed"
	#puts "agA ack $[$agentAsend set ack_] maxAD $maxackAD; agB ack $[$agentDsend set ack_] maxDA $maxackDA"
	
	
	
	#check if stream AD and stram DA at time $timePassed are finished
	#if are finished call finishTest 
	if { [$agentAsend set ack_] >= $maxackAD && [$agentDsend set ack_] >= $maxackDA  } { 
		#puts "Enter in if with time $timeTest"		
		$ns at $timePassed "finishTest"

	} else {
		#else call checker at timePassed + timeSlice time and set timeTest 
		#puts "Enter in else with time $timePassed"
		set timePassed [expr "$timePassed + $timeSlice"]
		set timeTest [expr "$timeTest + $timeSlice"]
		$ns at $timePassed "checker"
	}
}


#procedure that stamp time of test and run another test
proc finishTest {} {
	global timePassed totTest countTest timeTest times
	set ns [Simulator instance]
	puts "------- finish test n $countTest at time $timeTest -------"
	
	# save timeTest in array times
	set times($countTest) $timeTest
	
	set timeTest 0
	
	incr countTest
	# if tests are not finished
	if { $countTest < $totTest} { 
		$ns at $timePassed "startTest"
	} else {
		#tests are finished, then calculate variance and confidence range in finish procedure
		 
			$ns at $timePassed "finishProcedure"
		
	}

}



#procedure called when all tests are finished
proc finishProcedure {} {
 	global sum variance times totTest
	puts  ""
	puts "======================= Finish $totTest tests ======================="
	        
	set z 1.644854
	set sum 0
	for {set i 0} {$i<$totTest} {incr i} {
		set sum [expr $sum + $times($i)]
		   
	}
	set average [expr $sum / $totTest]
	        
	set variance 0
	for {set i 0} {$i<$totTest} {incr i} {
		#puts "Entro nel for con i $i"
		set temp [expr $times($i) - $average]
		set temp [expr $temp * $temp]
		set variance [expr $variance + $temp]
	}
	set variance [expr $variance / $totTest]
	set devStd [expr sqrt ($variance)]
	        
	puts "Times Average $average"
	puts "Times Variance $variance"
	puts "Time Standard Deviation $devStd"
	        
	set extreme1 [expr $average - [expr $z * [expr $devStd / [expr sqrt($totTest)]]]]
	        
	set extreme2 [expr $average + [expr $z * [expr $devStd / [expr sqrt($totTest)]]]]
	        
	puts "Range $extreme1 - $extreme2"
	        
	exit 0

}



startTest
