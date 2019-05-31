#!/usr/bin/env bash

# Copyright 2019 WSO2 Inc. (http://wso2.org)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ----------------------------------------------------------------------------
# Run Performance Tests
# ----------------------------------------------------------------------------

#concurrent_users=(1000 1)
#heap_sizes=(100m 4g)
#message_sizes=(1024 10240)
#garbage_collectors=(UseSerialGC UseParallelGC UseConcMarkSweepGC UseG1GC)
backend_program_jars=(blocking blocking.disruptor nio nio2.actor nio.actor nio.disruptor nio.netty blocking.actor nio2 nio2.disruptor nio.actor.seda nio.disruptor.seda nio.queue.seda)

backend_host_ip=192.168.32.12
backend_host_user=wso2
backend_host_password=javawso2 #wso2123

jmeter_jtl_location=/home/wso2/pasindu/jtls
jmeter_sar_path=/home/wso2/pasindu/sar_dir
jmeter_perf_path=/home/wso2/pasindu/perf_dir
jmeter_gc_path=/home/wso2/pasindu/gc_dir

backend_sar_path=/home/wso2/pasindu/sar_dir
backend_perf_path=/home/wso2/pasindu/perf_dir
backend_gc_path=/home/wso2/pasindu/gc_dir
backend_jar_files_root=/home/wso2/pasindu/server-architectures

backend_script=/home/wso2/pasindu/server-start.sh

jmeter_gc_logs_report_path=/home/wso2/pasindu/gc_reports

jmeter_jmx_file_root=/home/wso2/pasindu/jmx

jmeter_jtl_splitter_jar_file=/home/wso2/pasindu/jtl-splitter-0.3.1-SNAPSHOT.jar

jmeter_jmeter_path=/home/wso2/pasindu/apache-jmeter-4.0/bin

jmeter_performance_report_python_file=/home/wso2/pasindu/performance-report.py

jmeter_payload_generator_python_file=/home/wso2/pasindu/payload-generator.py

jmeter_performance_report_output_file=/home/wso2/pasindu/results.csv

jmeter_payloads_output_file_root=/home/wso2/pasindu/payloads

jmeter_payload_files_prefix=payload

jmeter_gc_viewer_jar_file=/home/wso2/pasindu/gcviewer-1.36-SNAPSHOT.jar

run_time_length_seconds=120
warm_up_time_seconds=60 # check for min vs sec


rm -r ${jmeter_jtl_location}/
rm -r ${jmeter_sar_path}/
rm -r ${jmeter_perf_path}/
rm -r ${jmeter_gc_path}/
rm -r ${jmeter_payloads_output_file_root}/
rm -r ${jmeter_gc_logs_report_path}/
rm  ${jmeter_performance_report_output_file}

mkdir -p ${jmeter_jtl_location}/
mkdir -p ${jmeter_sar_path}/
mkdir -p ${jmeter_perf_path}/
mkdir -p ${jmeter_gc_path}/
mkdir -p ${jmeter_payloads_output_file_root}/
mkdir -p ${jmeter_gc_logs_report_path}/

echo "IO Performance Tests"

echo "Generating Payloads for io use case"

python3 ${jmeter_payload_generator_python_file} ${jmeter_payloads_output_file_root}/${jmeter_payload_files_prefix}

echo "Finished generating payloads"

echo "Testing for impact of concurrency"

concurrent_users=(400 350 300 250 200 150 125 100 75 50 40 30 20 10 1)
heap_sizes=(100m 4g)
message_sizes=(1 102400)
garbage_collectors=(UseParallelGC)

for backend_program_jar in ${backend_program_jars[@]}
do
    for size in ${message_sizes[@]}
    do
        for heap in ${heap_sizes[@]}
        do
            for u in ${concurrent_users[@]}
            do
                for gc in ${garbage_collectors[@]}
                do
                    total_users=$(($u))

                    jtl_report_location=${jmeter_jtl_location}/${backend_program_jar}/io/${heap}_Heap_${total_users}_Users_${gc}_collector_${size}_size

                    echo "Report location is ${jtl_report_location}"

                    mkdir -p $jtl_report_location
                    #
                    sshpass -p 'javawso2' ssh -n -f ${backend_host_user}@${backend_host_ip} "/bin/bash $backend_script ${heap} ${u} ${backend_gc_path} ${backend_sar_path} ${backend_perf_path} ${gc} ${size} ${backend_jar_files_root}/${backend_program_jar}/target/${backend_program_jar}-1.0-SNAPSHOT.jar ${run_time_length_seconds} ${warm_up_time_seconds} ${backend_program_jar}-1.0-SNAPSHOT.jar 'io' "

                    while true
                    do
                        echo "Checking service"
                            response_code=$(curl -s -o /dev/null -w "%{http_code}" http://${backend_host_ip}:4333/io?message=m)

                            if [ $response_code -eq 200 ]; then

                                echo "Backend Server started"
                                break
                            else
                                sleep 10
                            fi
                    done



                    message=$(<${jmeter_payloads_output_file_root}/${jmeter_payload_files_prefix}${size})


                    # Start JMeter server

#                    ${jmeter_jmeter_path}/jmeter  -Jgroup1.host=${backend_host_ip}  -Jgroup1.port=4333 -Jgroup1.threads=$u -Jgroup1.seconds=${run_time_length_seconds} -Jgroup1.data=${message} -n -t ${jmeter_jmx_file_root/io.jmx} -l ${jtl_report_location}/results.jtl



                done


            done
        done
    done
done

#echo "Completed Generating JTL files"
#
#
#
#echo "Copying GC logs to Jmeter server machine"
#
#
#mkdir -p ${gc_logs_path}
#sshpass -p 'javawso2' scp -r $springboot_host_user:${target_gc_logs_path} ${gc_logs_path}
#
#echo "Finished Copying GC logs to server machine"
#
#echo "Copying uptime logs to Jmeter server machine"
#
#
#mkdir -p ${uptime_path}
#sshpass -p 'javawso2' scp -r $springboot_host_user:${target_uptime_path} ${uptime_path}
#
#echo "Finished Copying uptime logs to server machine"
#
#echo "Splitting JTL"
#
#for size in ${message_sizes[@]}
#do
#
#    for heap in ${heap_sizes[@]}
#    do
#        for u in ${concurrent_users[@]}
#        do
#            for gc in ${garbage_collectors[@]}
#    	    do
#        	    total_users=$(($u))
#        	    jtl_file=${jtl_location}/${total_users}_users/${heap}_heap/${gc}_collector/${size}_message/results.jtl
#		    java -jar ${jtl_splitter_path}/jtl-splitter-0.1.1-SNAPSHOT.jar -f $jtl_file -t $split_time -d
#            done
#        done
#    done
#done
#
#echo "Completed Splitting jtl files"
#
#echo "Generating Dash Boards"
#
#for size in ${message_sizes[@]}
#do
#    for heap in ${heap_sizes[@]}
#    do
#        for u in ${concurrent_users[@]}
#        do
#            for gc in ${garbage_collectors[@]}
#    	    do
#        	    total_users=$(($u))
#        	    report_location=${dashboards_path}/${total_users}_users/${heap}_heap/${gc}_collector/${size}_message
#        	    echo "Report location is ${report_location}"
#        	    mkdir -p $report_location
#
#                    ${jmeter_path}/jmeter -g  ${jtl_location}/${total_users}_users/${heap}_heap/${gc}_collector/${size}_message/results-measurement.jtl   -o $report_location
#            done
#
#        done
#    done
#done
#
#
#echo "Completed generating dashboards"
#
#echo "Generating GC reports"
#
#mkdir -p $gc_logs_report_path
#
#
#for size in ${message_sizes[@]}
#do
#    for heap in ${heap_sizes[@]}
#    do
#        for u in ${concurrent_users[@]}
#        do
#            for gc in ${garbage_collectors[@]}
#    	    do
#        	    total_users=$(($u))
#        	    gc_file=${gc_logs_path}/GCLogs/${heap}_Heap_${total_users}_Users_${gc}_collector_${size}_size_GCLog.txt
#                    gc_report_file=$gc_logs_report_path/${heap}_Heap_${total_users}_Users_${gc}_collector_${size}_size_GCReport.csv
#                    java -jar $gc_viewer_jar_file $gc_file $gc_report_file
#
#            done
#
#        done
#    done
#done
#
#
#echo "Completed generating GC reports"
#
#
#echo "Generating the CSV file"
#
#python3 $performance_report_python_file  $jtl_location $gc_logs_report_path $uptime_path $dashboards_path $performance_report_output_file
#
#echo "Finished generating CSV file"