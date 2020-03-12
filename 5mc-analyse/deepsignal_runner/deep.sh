#!/bin/bash
# 功能：任务提交代码	
# 脚本名：gpu.sh	
# 作者：ysq	
# 版本：V 1

# 进入虚拟环境deep
source activate deep 
cd /home/chuanlex/ysq
# 传参 
pan=$1 
human_dir=$2 
tar_dir=$3
# 定义本地变量
ref=/home/chuanlex/ysq/GCF_000001405.39_GRCh38.p13_genomic.fna 
model_path=/home/chuanlex/ysq/model.CpG.R9.4_1D.human_hx1.bn17.sn360/bn_17.sn_360.epoch_7.ckpt 
human=${human_dir##*/}
LOG_FILE="/home/chuanlex/ysq/logs/gpu_${human}.log"
ERR_FILE="/home/chuanlex/ysq/logs/err_${human}.log"
if [ -f $LOG_FILE ];then
rm $LOG_FILE
fi
if [ -f $ERR_FILE ];then
rm $ERR_FILE
fi

# 增加日志功能函数
write_log(){
  DATE=$(date +%F)
  TIME=$(date +%T)
  buzhou="$1"
  echo "${DATE} ${TIME} $0 : ${buzhou} " >> "${LOG_FILE}"
}

write_errlog(){
  DATE=$(date +%F)
  TIME=$(date +%T)
  buzhou="$1"
  echo "${DATE} ${TIME} $0 : ${buzhou} " >> "${ERR_FILE}"
}



ls -r ${tar_dir}/*.tar|while read tar 
do  

	tar_n=${tar%.*} 
	tar_num=${tar_n##*/}
	#write_log "正在遍历${tar_num}文件****************************" 
	num=`echo "$tar_num % 4" | bc` 
	old_path=/data/malifei/${human}_${pan}/${tar_num}
	old_input=$old_path/${tar_num}
	old_fastq=${old_path}/${tar_num}.guppy.fq
	out_path=/home/chuanlex/ysq/${human}_${pan}/${tar_num}
	input_path=${out_path}/${tar_num} 
	old_result=/data/malifei/${human}_${pan}/${tar_num}/${tar_num}.guppy_deepsignal.txt 
	result_file=${out_path}/${tar_num}.guppy_deepsignal.txt 
	log_file=${out_path}/${tar_num}.guppy_deepsignal.log 
	fastq_path=${out_path}/${tar_num}.guppy.fq
	if [ -d $old_input ];then
		rm -rf $old_input
	fi
	if [ -d $old_fastq ];then
        	rm -rf $old_fastq
        fi
	if [ ! -s ${old_result} ]; then 
		write_log "${tar_num}文件无结果文件,开始运行${tar_num}###############################"
		func(){ 
			gpu=$1 
			 
			if [ ! -d ${out_path} ];then 
				#write_log "create outpath: ${out_path}====================================================" 
				mkdir -p ${out_path} 
			fi  

			
			if [ ! -d ${input_path} ];then 
				#write_log "create inputpath: ${input_path}====================================================" 
				#write_log "tar -xf ${tar}====================================================" 
				tar -xf ${tar} -C ${out_path}  
			fi  

			
			write_log "${human}/${tar_num}||GPU=cuda:${gpu} is running====================================================" 
			nohup python3 /data/malifei/guppy_deepsignal_runner_gpu.py --threads 20 --gpu ${gpu} --out_path ${out_path} --input_path ${input_path} --is_multi_reads no --ref_fp ${ref} --is_guppy yes --flowcell FLO-PRO002 --kit SQK-LSK109 --num_callers 10  --is_tombo yes --model_path ${model_path} --kmer_len 17 --cent_signals_len 360 --is_gpu yes --result_file ${result_file} > ${log_file} 2>&1 & 
			pid=`echo $!`
			wait $pid
			write_log "$pid进程结束================================================"
			if [ -s ${result_file} ];then
				write_log "${human}/${tar_num}||Running over===================================================="
				write_log "SUCCESS:remove fast5 rawdata====================================================" 
				rm -rf $input_path $fastq_path $old_path
				mv $out_path $old_path
			else
				write_log "${human}/${tar_num}||killed===================================================="
				write_errlog "${tar_num}:fail*********************"
				write_log "FAIL:remove fast5 rawdata====================================================" 
				rm -rf $input_path $fastq_path $old_path
			fi
	
		}  

		if [ $num -eq 0 ];then 
			write_log "gpu=0" 
			func 0  
		elif [ $num -eq 1 ];then 
			write_log "gpu=1" 
			func 1  
		elif [ $num -eq 2 ];then 
			write_log "gpu=2" 
			func 2  
		elif [ $num -eq 3 ];then
			write_log "gpu=3" 
			func 3 
		fi 
	else
		write_log "${tar_num}文件已存在结果文件****************************"	
	fi 
done
write_log "全部运行结束" 
